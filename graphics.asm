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
MapWidth:   DS 1
MapSize:    DS 1

CurrentCameraX:    DS 2 ; What is currently displayed on the hardware right now?
CurrentCameraY:    DS 2

TargetCameraX:    DS 2 ; What do we WANT to be displayed on the hardware?
TargetCameraY:    DS 2

CurrentTileX: DS 2
CurrentTileY: DS 2

OldTileX: DS 2
OldTileY: DS 2

FrameCounter: DS 2

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
        ld a, [MapSize]
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

        ld a, [FrameCounter+1]
        bit 0, a
        jp z, .updateRow

.updateColumn
        ; update entire perimiter (INEFFICIENT!!)
        getWordDE CurrentTileX
        ld hl, 10
        add hl, de
        ld d, h
        ld e, l
        call draw_Column
        ret

.updateRow 
        getWordBC CurrentTileY
        ld hl, 9
        add hl, bc
        ld b, h
        ld c, l
        call draw_Row

        ret

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

        REPT 9
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
        ld a, [MapWidth]
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