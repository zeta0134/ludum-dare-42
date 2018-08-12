        INCLUDE "vendor/gbhw.inc"

        
        PUSHS           
        SECTION "Shadow OAM",WRAM0[$C000]
shadowOAM:
        DS 4*40
        POPS

MAP_SIZE_16x16   EQU  4
MAP_SIZE_32x32   EQU  5
MAP_SIZE_64x64   EQU  6
MAP_SIZE_128x128   EQU  7

        PUSHS           
        SECTION "Graphics WRAM",WRAM0
MapAddress: DS 2

CurrentCameraX:    DS 2 ; What is currently displayed on the hardware right now?
CurrentCameraY:    DS 2

TargetCameraX:    DS 2 ; What do we WANT to be displayed on the hardware?
TargetCameraY:    DS 2

CurrentTileX: DS 2
CurrentTileY: DS 2

OldTileX: DS 2
OldTileY: DS 2

FrameCounter: DS 2

SPRITE_CHUNK EQU 0
SPRITE_X_POS EQU 1
SPRITE_Y_POS EQU 3
SPRITE_TILE_BASE EQU 5
SPRITE_ANIMATION_START EQU 6
SPRITE_ANIMATION_CURRENT EQU 8
SPRITE_ANIMATION_DURATION EQU 10
SPRITE_ACTIVE EQU 11

SpriteList: DS 12*12

ANIMATION_DURATION EQU 0
ANIMATION_TILE_INDEX EQU 1
ANIMATION_X_OFFSET EQU 2
ANIMATION_Y_OFFSET EQU 3

; various temps
tPosX: DS 2
tPosY: DS 2

tDebugGraphics: DS 4
tDebugScrollX: DS 1
tDebugChunkLeft: DS 2
tDebugFinalX: DS 2

        POPS        

        PUSHS           
        SECTION "Graphics Code",ROM0

_oamDMA:
        ld      a,$C0
        ld      [$FF46],a
        ld      a,$28
.wait:
        dec     a
        jr      nz,.wait
        ret
_oamDMAEnd:

oamDMA:
        call    $FF80
        ret

initOAM:
        ; copy OAM DMA routine into high RAM
        ld      hl,_oamDMA
        ld      de,$FF80
        ld      bc,(_oamDMAEnd - _oamDMA)
        call    mem_Copy

        ; clear out shadow OAM
        ld      d,40
        ld      hl,shadowOAM
.loop:
        ld      a,$FF ; Y-coordinate
        ld      [hl+],a
        ld      a,$FF ; X-coordinate
        ld      [hl+],a
        ld      a,$00 ; tile-index
        ld      [hl+],a
        ld      a,$00 ; attributes
        ld      [hl+],a
        dec     d
        jr      nz, .loop

        ret



; ##########################################################################
; # 16x16 Sprites                                                          #
; ##########################################################################

; Note: These utility functions assume
; that the sprite mode is already 8x16

;***************************************************************************
;*
;* set_16x16_Tile - Sets an entire 16x16 sprite, assuming sequential tile
;*   numbers, and sequential OAM table entries.
;*
;* arguments:
;*   \1 - oam_index
;*   \2 - tile index
;* clobbers:
;*   a
;***************************************************************************
set_16x16_Tile: MACRO
        ld a,\2
        ld [shadowOAM + (\1       * 4) + 2],a
        ld a,\2 + 2
        ld [shadowOAM + ((\1 + 1) * 4) + 2],a
        ENDM

;***************************************************************************
;*
;* set_16x16_Pos - Sets an entire 16x16 sprite, assuming sequential tile
;*   numbers, and sequential OAM table entries.
;*
;* arguments:
;*   \1 - oam index
;*   \2 - x coordinate
;*   \3 - y coordinate
;* clobbers:
;*   a
;***************************************************************************
set_16x16_Pos: MACRO
        ld a,\2
        ld [shadowOAM + (\1       * 4) + 1], a
        ld a,\2 + 8
        ld [shadowOAM + ((\1 + 1) * 4) + 1], a
        ld a,\3
        ld [shadowOAM + (\1       * 4) + 0], a
        ld [shadowOAM + ((\1 + 1) * 4) + 0], a
        ENDM

;***************************************************************************
;*
;* set_16x16_Pos - Sets an entire 16x16 tile. Assumes source tile is arranged
;*   in top-left to bottom-right order in VRAM.
;*
;* inputs:
;*   a - source tile top-left
;*   hl - destination address (within VRAM bank, ideally)
;* clobbers:
;*   a, hl, bc
;***************************************************************************
draw_16x16_tile: MACRO
        ld [hl+], a
        inc a
        ld [hl+], a
        ld bc, 30
        add hl, bc
        inc a
        ld [hl+], a
        inc a
        ld [hl], a
        ENDM

;***************************************************************************
;*
;* map_Tile_Address - Given tile coordinates, calculates the memory address
;*   of the given tile, based on the map size
;*
;* inputs:
;*   bc - tile y-coordinate
;*   de - tile x-coordinate
;* outputs:
;*   hl - map address of selected tile
;* clobbers:
;*   bc, a
;***************************************************************************
map_Tile_Address:
        ld a, 4
        ld h, b
        ld l, c
.mul_loop:
        add hl, hl
        dec a
        jr nz, .mul_loop
        ; at this point, hl represents y * map_width. First add it to the base
        ; address of the map
        getWordBC MapAddress
        add hl, bc
        ; and add the X coordinate
        ; CHEAT: restrict the X coordinate to map width
        ld a, e
        and %00001111
        ld e, a
        ld d, 0
        add hl, de
        ; that's it!
        ret

;***************************************************************************
;*
;* vram_Masked_Tile_Address - Given tile coordinates, calculates the VRAM
;*   address where the destination tile should START.
;*
;* inputs:
;*   bc - logical tile y-coordinate
;*   de - logical tile x-coordinate
;* outputs:
;*   hl - map address of selected tile
;* clobbers:
;*   de, a
;***************************************************************************
vram_Masked_Tile_Address:
        ld h, $98
        ; x coordinate; this only affects 'l' because it cannot overflow
        ld a, e
        and %00001111
        sla a
        ld l, a
        ; y coordinate: "multiply by 64" (32 h-tiles to skip, 2 rows)
        ld a, c
        and %00001111
        ld b, a
        ld c, 0
        REPT 2
        srl b
        rr c
        ENDR
        add hl, bc
        ret

;***************************************************************************
;*
;* update_Camera - Moves the camera towards its target location, and updates
;*   internal tile tracking registers for tile drawing routines to use
;* clobbers:
;*   TODO
;***************************************************************************
update_Camera:
        ; TODO: rate limit this
        getWordHL TargetCameraX
        setWordHL CurrentCameraX
        REPT 4
        sra h
        rr l
        ENDR
        setWordHL CurrentTileX
        getWordHL TargetCameraY
        setWordHL CurrentCameraY
        REPT 4
        sra h
        rr l
        ENDR
        setWordHL CurrentTileY
        call update_Bg_Scroll

        ;ld a, [FrameCounter+1]
        ;bit 0, a
        ;jp z, .updateRow

.updateColumn
        ; update entire perimiter (INEFFICIENT!!)
        getWordDE CurrentTileX
        ld hl, 10
        add hl, de
        ld d, h
        ld e, l
        call draw_Column
        ret

;.updateRow 
;        getWordBC CurrentTileY
;        ld hl, 9
;        add hl, bc
;        ld b, h
;        ld c, l
;        call draw_Row
;        ret

;***************************************************************************
;*
;* update_Bg_Scroll - Moves the hardware scrolling registers into position
;* clobbers:
;*   TODO
;***************************************************************************
update_Bg_Scroll:
        ld a, [CurrentCameraX + 1]
        ld [rSCX], a
        ld a, [CurrentCameraY + 1]
        ld [rSCY], a
        ret

;***************************************************************************
;*
;* draw_Column - Given a logical tile coordinate, draws all tiles in the
;*   column that would be visible (based on the current Y coordinate)
;* input:
;*   de: logical column
;***************************************************************************
draw_Column:
        ; calculate our starting coordinate in map space
        getWordBC CurrentTileY
        call map_Tile_Address ; result in hl, clobbers bc
        push hl
        ; calculate our destination coordinate in VRAM
        getWordBC CurrentTileY
        call vram_Masked_Tile_Address ; result in hl, clobbers de
        pop de ; de = source address

        REPT 16
        ld a, [de]
        ; multiply the logical tile by four
        sla a
        sla a
        draw_16x16_tile
        ; hl now points to bottom-right tile, we  need to adjust it to
        ; the top-left of the next tile vertically
        dec hl ; one left
        ld bc, 32 ; one down
        add hl, bc
        ; fix bank edge
        ld a, h
        and %00000011
        or $98
        ld h, a
        ; preserve hl
        push hl
        ; add map width to de, advancing to the next row
        push de
        pop hl
        ld a, 16
        ld c, a
        add hl, bc
        push hl
        pop de
        pop hl
        ENDR
        ret

;***************************************************************************
;*
;* draw_Row - Given a logical tile coordinate, draws all tiles in the
;*   row that would be visible (based on the current X coordinate)
;* input:
;*   bc: logical row
;***************************************************************************
draw_Row:
        ; calculate our starting coordinate in map space
        getWordDE CurrentTileX
        push bc
        call map_Tile_Address ; result in hl, clobbers bc
        pop bc
        push hl
        call vram_Masked_Tile_Address ; result in hl, clobbers de
        pop de ; de = source address
        

        REPT 11
        ld a, [de]
        ; multiply the logical tile by four
        sla a
        sla a
        push hl
        draw_16x16_tile
        pop hl ; hl points to original tile
        ld a, l
        and a, %11100000
        ld c, a ; c = row bits to preserve
        ld a, l
        add a, 2
        and a, %00011111
        or a, c
        ld l, a
        inc de
        ENDR
        ret

;***************************************************************************
;*
;* init_Viewport - Draws every tile currently on-screen at the camera's
;*   coordinates. This is inefficient, and meant to be called when first
;*   starting the game.
;* 
;* clobbers:
;*   yes
;***************************************************************************
init_Viewport:
        getWordBC CurrentTileY
        getWordDE CurrentTileX
        ld h, 9
.loop
        push bc
        push de
        push hl
        call draw_Row
        pop hl
        pop de
        pop bc
        inc bc
        dec h
        jr nz, .loop
        ret

;***************************************************************************
;* updateSprites - Call this once per game update. Runs through all sprites
;*   and determines their current animation frame, position, and other
;*   attributes, before writing the values to shadow OAM
;***************************************************************************
updateSprites:
        ld de, SpriteList
        ld b, 0
.loop
        push bc
        ld hl, SPRITE_ACTIVE
        add hl, de
        ld a, [hl]
        cp 0
        jp nz, .active
.inactive
        inc hl  ; move to the start of the next entry (+1 byte from here)
        push hl ; replace de with hl contents using the stack
        pop de
        pop bc
        inc b
        ld a, 12
        cp b
        jp z, .end
        jp .loop
.active
        ld hl, shadowOAM
        ld a, b
        sla a ; x8 (two OAM entries per 16x16 tile)
        sla a
        sla a
        add a, l ;no overflow possible due to alignment
        ld b, h
        ld c, a
        ; bc now points to shadow OAM entry for this sprite
        ; de now points to the start of this sprite entry
        push de
        push bc
        call .updateAnimation
        pop bc
        pop de
        push de
        push bc
        call .updatePosition
        pop bc
        pop de
.finishUpdate        
        ld hl, 12
        add hl, de 
        ld d, h
        ld e, l ; de now points to the next sprite in sequence
        pop bc ; pop again here to restore bc as the counter
        inc b
        ld a, 12
        cp b
        jp nz, .loop
.end
        ret


;* inputs:
;*   SP+2 - OAM entry
;*   SP+4 - logical sprite entry

.updatePosition
        ; start with the left-most pixel of the active chunk
        ld a, [CurrentCameraX+1]
        ld [tDebugScrollX], a
        ld d, 0
        ld e, a
        ld hl, 0
        ; test to see if the camera coordinate is greater than 96
        ld a, 96
        sub e
        jp nc, .less
        ld hl, 256
.less
        ; subtract the camera coordinates from hl
        ld a, l
        sub e
        ld l, a
        ld a, h
        sbc d
        ; al now contains the left-most coordinate of the active chunk
        ; stash this in de for later
        ld d, a
        ld e, l

        ; determine the difference between the active chunk and this object's chunk
        getStackBC 4
        ld hl, SPRITE_CHUNK ;high byte only
        add hl, bc
        ld b, [hl] 
        ld a, [currentChunk]
        sub b ; b now contains how far behind / ahead of the active chunk we are.
        ld b, a
        ; Translate this value into 256 * b
        ld c, 0

        ; bc contains chunk offset in pixels. Add it to de to obtain the left-most coordinate of the object's chunk
        ld h, d
        ld l, e
        add hl, bc
        ; stash this in de again
        ld d, h
        ld l, e

        ; Grab the object's X coordinate within its own chunk
        getStackBC 4
        ld hl, SPRITE_X_POS ;high byte only
        add hl, bc
        ld a, [hl]
        ; add it to our running total in de
        ld h, 0
        ld l, a
        add hl, de
        ; hl now contains the sprite's coordinate within its chunk. Stash this for now.
        ld a, l
        ld [tPosX], a
        ld a, h
        ld [tPosX+1], a

        ; Determine the Y coordinate of the active chunk. This is simpler because we don't care about wrapping,
        ; so the Y coordinate is effectively 0 - scrY
        ld a, [CurrentCameraY+1]
        ld b, a
        ld a, 0
        sub b
        ld e, a
        ; e now contains the Y coordinate of the active chunk

        getStackBC 4
        ld hl, SPRITE_Y_POS ;high byte only
        add hl, bc
        ld a, [hl] 
        ; add in the t coordinate of the chunk
        add e
        ; stash this for later
        ld [tPosY], a

        ; Here, calculate the animation offsets, and add those to our working set for X and Y

        getStackBC 4
        ld hl, SPRITE_ANIMATION_CURRENT
        add hl, bc
        ld a, [hl+]
        ld e, a
        ld d, [hl]
        ; de now points at animation data for current frame
        inc de ; skip duration
        inc de ; skip tile index
        ; de now points to the X offset

        ld a, [de]
        push de ; stash this, since we'll clobber it below with X offset calculations
        ld c, a
        ; extend sign bit into high byte
        ld b, 0 
        bit 7, c
        jp z, .positive
        ld b, $FF
.positive
        ; read working position into de
        ld hl, tPosX
        ld e, [hl]
        inc hl
        ld d, [hl]
        ; add our animation offset to it
        ld h, b
        ld l, c
        add hl, de
        ; hl now contains our final on-screen X coordinate
        ; RANGE CHECK: Is this sprite offscreen?
        ; stash original X coordinate in bc
        ld b, h
        ld c, l
        setWordBC tDebugFinalX

        ld hl, 16
        add hl, bc ; hl now contains original coordinate +16
        bit 7, h ; if hl is still negative, we are offscreen to the left. Bail!
        jp nz, .hideSprite
        ld hl, -160
        add hl, bc ; hl now contains original coordinate - 160
        bit 7, h ; if hl is still positive, we are offscreen to the right. Bail here too!
        jp z, .hideSprite

        ; if we got here, this sprite is on-screen! Grab the low byte of the coordinate, add 8 to it (OAM quirk), and
        ; stash it for later.
        ld a, 8
        add a, c
        ld [tPosX], a

        ; Calculate the animation offset for Y
        pop de
        inc de
        ld a, [de]   ; a now contains Y-offset for this animation
        ld hl, tPosY
        add a, [hl]  ; add it directly to tPosY on disk
        ld [hl], a

        ; finally, write these values to OAM
        getStackBC 2
        ld h, b
        ld l, c
        ld a, [tPosY]
        ld [hl+], a
        ld a, [tPosX]
        ld [hl+], a
        ; and again, for the second OAM entry
        inc hl
        inc hl
        ld a, [tPosY]
        ld [hl+], a
        ld a, [tPosX]
        add a, 8
        ld [hl+], a

        ret
.hideSprite
        ; Firstly, pop de off the stack from earlier, since otherwise we skipped doing that
        pop de
        ; now we need to hide the sprite in OAM. can do this by setting its Y coordinate offscreen (ie, to 0xFF)
        getStackBC 2
        ld h, b
        ld l, c
        ld a, $FF
        ld [hl], a
        ; and again for the second OAM entry
        REPT 4
        inc hl
        ENDR
        ld [hl], a
        ; done!
        ret


;* inputs:
;*   SP+2 - OAM entry
;*   SP+4 - logical sprite entry

.updateAnimation
        getStackBC 4
        ld hl, SPRITE_ANIMATION_DURATION
        add hl, bc
        dec [hl]
        jp z, .nextFrame
        ret
.nextFrame
        getStackBC 4
        ld hl, SPRITE_ANIMATION_CURRENT
        add hl, bc
        ld e, [hl]
        inc hl
        ld d, [hl]
        ; de now contains current animation pointer
        ld hl, 5
        add hl, de
        ld d, h
        ld e, l
        ; de now contains NEXT animation pointer
        ld a, [de]
        ; if duration is zero, this signals the end of the animation list
        cp 0
        jp nz, .applyNextFrame
.restartAnimation
        ; Grab the starting address for this animation
        getStackBC 4
        ld hl, SPRITE_ANIMATION_START
        add hl, bc
        ld e, [hl]
        inc hl
        ld d, [hl]
        ; de now contains the address of the starting frame. Write this
        ;   out to the current frame to reset the animation

.applyNextFrame
        getStackBC 4
        ld hl, SPRITE_ANIMATION_CURRENT
        add hl, bc
        ld [hl], e
        inc hl
        ld [hl], d
        ; de still contains the current animation pointer, so proceed to
        ;   update OAM with the new state

        ; Set our delay to the duration for the current frame
        getStackBC 4
        ld hl, SPRITE_ANIMATION_DURATION
        add hl, bc
        ld a, [de]
        ld [hl], a

        ; Determine the base tile index for this frame
        getStackBC 4
        ld hl, SPRITE_TILE_BASE
        add hl, bc
        ld a, [hl]
        ; Multiply the base index by 4
        sla a
        sla a
        ld b, a
        ; add it to the logical index for this animation
        inc de
        ld a, [de]
        sla a ; multiply that by 4 also
        sla a
        add a, b
        ld b, a
        ; b now contains the final tile index for this animation

        ; skip to the OAM attributes
        inc de
        inc de
        inc de
        ld a, [de]
        ld c, a
        ; c now contains the OAM attributes


        ; Update our OAM tile to the index for this frame
        getStackDE 2
        ld hl, 2
        add hl, de
        ld [hl], b ; write the tile index
        inc hl
        ld [hl], c ; write the OAM attributes
        inc b ; skip to the next 8x16 tile
        inc b
        ld de, 3
        add hl, de
        ld [hl], b ; write the next tile index
        inc hl
        ld [hl], c ; write the OAM attributes

        ; and we're done!
        ret

;***************************************************************************
;* initSprites - Just zeroes out sprite memory. That's all!
;***************************************************************************
initSprites:
        ld hl, SpriteList
        ld d, 12*12
.loop
        ld [hl], 0
        inc hl
        dec d
        jp nz, .loop
        ret

;***************************************************************************
;* spawnSprite - Creates a new sprite, at the specified index, with the
;*   provided animation data
;* inputs:
;*   a - desired index
;*   bc - animation address
;* outputs:
;*   bc - sprite address
;***************************************************************************
spawnSprite:
        ld hl, SpriteList
        cp 0
        jp z, .spawn
        ld de, 12
.loop
        add hl, de
        dec a
        jp nz, .loop
.spawn
        push hl
        ; hl now points to the start of the sprite entry
        ld de, SPRITE_ANIMATION_START
        add hl, de
        ld a, c
        ld [hl+], a
        ld a, b
        ld [hl+], a
        ; cheat here: decrement the animation start value by 5
        dec bc
        dec bc
        dec bc
        dec bc
        dec bc
        ; write this "pre-animation" pointer to the sprite "current" entry
        ld a, c
        ld [hl+], a
        ld a, b
        ld [hl+], a
        
        pop bc ; bc now points to the sprite entry
        ; now set a few variables to kick-start the sprite's animation state
        setFieldByte SPRITE_ACTIVE, 1
        ; this causes the animation to immediately skip to the first frame,
        ; because we seeded it with frame -1 earlier
        setFieldByte SPRITE_ANIMATION_DURATION, 1
        ; That's it!
        ret

;***************************************************************************
;* getSpriteAddress - Retrieve a sprite's memory address, by index
;* input:
;*   a - desired index
;* output:
;*   bc - address
;* clobbers:
;*   hl
;***************************************************************************
getSpriteAddress:
        ld hl, SpriteList
        cp 0
        jp z, .done
        ld bc, 12
.loop
        add hl, bc
        dec a
        jp nz, .loop
.done
        ld b, h
        ld c, l
        ret



;***************************************************************************
;* vblankRoutine - Called automatically by the hardware at the start of
;*   the vertical blanking period. Beware: time sensitive! Must complete
;*   all activities before vertical blanking ends.
;***************************************************************************

vblankRoutine:
        push af
        push bc
        push de
        push hl

        call oamDMA
        getWordBC FrameCounter
        inc bc
        setWordBC FrameCounter

        pop hl
        pop de
        pop bc
        pop af
        reti

        POPS

        PUSHS           
        SECTION "vBlank Jump Vector",ROM0[$40]
vblankJumpVector:
        jp vblankRoutine
        POPS