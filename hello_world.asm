        ;  Macros and compiler defines
        INCLUDE "vendor/gbhw.inc"
        INCLUDE "vendor/ibmpc1.inc"

        ; Standard gameboy header. Code execution after BIOS routine will
        ; always begin at $100

        SECTION "Org $100",ROM0[$100]

        nop
        jp      begin

        ;  This macro fills out the remaining required header info after our
        ;  jump code above. The checksum is calculated by an external tool.

        ROM_HEADER      ROM_NOMBC, ROM_SIZE_32KBYTE, RAM_SIZE_0KBYTE

        ; Everything from this point on is ROM data, beginning immediately
        ; after the header.

        INCLUDE "vendor/memory.asm"
        INCLUDE "util.asm"
        INCLUDE "graphics.asm"
        INCLUDE "animations.asm"

FontTileData:
        chr_IBMPC1      1,8

SpriteData:
        INCBIN "data/sprites/run_cycle.2bpp"
        INCBIN "data/sprites/tumble.2bpp"
        INCBIN "data/sprites/splat.2bpp"
        INCBIN "data/sprites/warning.2bpp"
        INCBIN "data/sprites/crate.2bpp"
        INCBIN "data/sprites/wrench.2bpp"
        INCBIN "data/sprites/double_wrench.2bpp"
        INCBIN "data/sprites/bolt_up.2bpp"
        INCBIN "data/sprites/bolt_down.2bpp"
        INCBIN "data/sprites/explosion.2bpp"
        INCBIN "data/sprites/numbers.2bpp"
        INCBIN "data/sprites/material1.2bpp"
        INCBIN "data/sprites/material2.2bpp"
        INCBIN "data/sprites/material3.2bpp"
        INCBIN "data/sprites/material4.2bpp"
        INCBIN "data/sprites/station.2bpp"
        INCBIN "data/sprites/station_building.2bpp"

SpaceStationTiles:
        INCBIN "data/tiles/title.2bpp"
        INCBIN "data/tiles/space_station.2bpp"

TestChambers:
        INCLUDE "data/test_chamber3.map"
        INCLUDE "data/test_chamber.map"
        INCLUDE "data/test_chamber2.map"

begin:
        di
        ld      sp,$ffff
        call    StopLCD

        ; Setup background and obj palettes
        ld      a,$e4      ; Standard gradient, white is transparent
        ld      [rBGP],a
        ld      a,$d0      ; "Light" sprite: black, light grey, white
        ld      [rOBP0],a
        ld      a,$e4      ; "Dark"  sprite: black, dark grey, light grey
        ld      [rOBP1],a

        ; Initialize background scroll to 0,0
        ld      a,0
        ld      [rSCX],a
        ld      [rSCY],a

        ; Copy font data into VRAM at $8000. CopyMono duplicates each byte,
        ; since the source data is 1bpp, and our source data is 2bpp

        ld      hl,SpaceStationTiles
        ld      de,$8840
        ld      bc,16*256        ; length (8 bytes per tile) x (256 tiles)
        call    mem_Copy    ; Copy tile data to memory

        ; Copy sprite data for Blobby into VRAM

        ld      hl,SpriteData
        ld      de,$8000
        ld      bc,$880
        call    mem_Copy

        call    initOAM

        ; Clear the background
        ld      a,$00          ; ASCII " "
        ld      hl,$9800
        ld      bc,SCRN_VX_B * SCRN_VY_B
        call    mem_Set

        ; Set our map to the test chunk
        setWordImm MapAddress, TestChambers
        ; Set our size accordingly

        ; set our scroll position
        setWordImm TargetCameraX, 0 
        setWordImm TargetCameraY, 16

        ; initialize the viewport
        call update_Camera
        call init_Viewport

        ; initialize some testing sprites
        call initSprites

        ld a, 0
        ld bc, PlayerRuns
        call spawnSprite
        setFieldByte SPRITE_X_POS, 40
        setFieldByte SPRITE_Y_POS, 86
        setFieldByte SPRITE_TILE_BASE, 0
        setFieldByte SPRITE_CHUNK, 0

        ld a, 1
        ld bc, ItemBobDarkPal
        call spawnSprite
        setFieldByte SPRITE_X_POS, 40
        setFieldByte SPRITE_Y_POS, 66
        setFieldByte SPRITE_TILE_BASE, 12
        setFieldByte SPRITE_CHUNK, 1

        ld a, 2
        ld bc, ItemBobDarkPal
        call spawnSprite
        setFieldByte SPRITE_X_POS, 60
        setFieldByte SPRITE_Y_POS, 66
        setFieldByte SPRITE_TILE_BASE, 13
        setFieldByte SPRITE_CHUNK, 2

        ld a, 3
        ld bc, Explosion
        call spawnSprite
        setFieldByte SPRITE_X_POS, 1
        setFieldByte SPRITE_Y_POS, 30
        setFieldByte SPRITE_TILE_BASE, 16
        setFieldByte SPRITE_HUD_SPACE, 1

        ld a, 4
        ld bc, Explosion
        call spawnSprite
        setFieldByte SPRITE_X_POS, 4
        setFieldByte SPRITE_Y_POS, 60
        setFieldByte SPRITE_TILE_BASE, 16
        setFieldByte SPRITE_HUD_SPACE, 1

        ld a, 5
        ld bc, Explosion
        call spawnSprite
        setFieldByte SPRITE_X_POS, 1
        setFieldByte SPRITE_Y_POS, 90
        setFieldByte SPRITE_TILE_BASE, 16
        setFieldByte SPRITE_HUD_SPACE, 1

        ld a, 6
        ld bc, Explosion
        call spawnSprite
        setFieldByte SPRITE_X_POS, 4
        setFieldByte SPRITE_Y_POS, 120
        setFieldByte SPRITE_TILE_BASE, 16
        setFieldByte SPRITE_HUD_SPACE, 1

        ; initialize some gameplay things
        ld a, 0
        ld [lastRightmostTile], a

        ld [currentChunk], a
        ld hl, chunkBuffer
        ld bc, 256
        call mem_Set

        ; write some test chunks
        ld b, 0
        ld a, 0
        ld hl, currentChunk
.chunkInitLoop
        ld [hl], a
        inc a
        inc hl
        inc b
        jp z, .done
        cp a, 3
        jp nz, .chunkInitLoop
        ld a, 0
        jp .chunkInitLoop
.done

        ld a, 1
        ld [chunkBuffer+1], a
        ld a, 2
        ld [chunkBuffer+2], a
        ; debug
        ld a, 66
        ld [chunkMarkers+0], a
        ld [chunkMarkers+1], a
        ld [chunkMarkers+2], a
        ld [chunkMarkers+3], a

        call initScore
        ld a, 0
        ld [playerSpeedX], a
        ld [playerSpeedY], a

        ; Now we turn on the LCD display to view the results!

        ld      a,LCDCF_ON|LCDCF_BG8800|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ16|LCDCF_OBJON
        ld      [rLCDC],a       ; Turn screen on

        ; Enable vblank, but nothing else for now
        ld      a,IEF_VBLANK
        ld      [rIE],a
        ei

        ; It's show time!

gameLoop:
        ; halt until the next vBlank
        halt
        nop ; DMC bug workaround

        call    updateChunks
        call    update_Camera
        call    updateSprites
        call    displayScore
        call    pollInput
        call    updatePlayer

        jp      gameLoop


        PUSHS           
        SECTION "Main WRAM",WRAM0

chunkMarkers: DS 4
lastRightmostTile: DS 1
currentChunk: DS 1
keysOld: DS 1
keysHeld: DS 1
keysDown: DS 1
keysUp: DS 1
playerSpeedX: DS 1
playerSpeedY: DS 1
playerJumpTimer: DS 1
playerAccelTimer: DS 1
score: DS 3
chunkBuffer: DS 256

KEY_START EQU $80
KEY_SELECT EQU $40
KEY_B EQU $20
KEY_A EQU $10
KEY_DOWN EQU $08
KEY_UP EQU $04
KEY_LEFT EQU $02
KEY_RIGHT EQU $01

        POPS

updateChunks:
        ; determine right-most tile
        ld a, [TargetCameraX+1]
        swap a
        add a, 10
        and a, %00001111
        ld d, a ;d now contains right-most tile
        ; if this tile is different from last frame
        ld a, [lastRightmostTile]
        sub d
        jp z, .saveTile
        ; increase the score
        call increaseScore
        ; if this tile is 0
        ld a, d
        cp 0
        jp nz, .saveTile
        ; load the next chunk!
        ld a, [currentChunk]
        inc a
        ;and a, %00000011 ; for now, restrict to 4 chunks in the buffer
        ld [currentChunk], a
        ld b, 0
        ld c, a
        ld hl, chunkBuffer
        add hl, bc
        ld a, [hl] ;a now contains active chunk
        ld h, a
        ld l, 0
        ld bc, TestChambers
        add hl, bc
        setWordHL MapAddress
.saveTile
        ld a, d
        ld [lastRightmostTile], a
        ret

initScore:
        ld hl, score
        ld a, 0
        ld [hl+], a
        ld [hl+], a
        ld [hl], a
        ld hl, shadowOAM + 34 * 4
        ld d, 6
        ld a, 63
.loop
        ld [hl], 20 ; y-coordinate 
        inc hl
        ld [hl+], a ; x-coordinate 
        ld [hl], $50 ; tile-index
        inc hl
        inc hl ; skip over attributes
        add a, 7
        dec d
        jp nz, .loop
        ret

increaseScore:
        ld hl, score + 2
        ld a, [hl]
        add a, 1
        daa
        ld [hl-], a
        jp c, .hundreds
        ret
.hundreds
        ld a, [hl]
        add a, 1
        daa
        ld [hl-], a
        jp c, .tenThousands
        ret
.tenThousands
        ld a, [hl]
        add a, 1
        daa
        ld [hl], a
        ret

displayScore:
        ld hl, shadowOAM + 34 * 4 + 2
        ld a, [score]
        call displayScoreByte
        ld a, [score + 1]
        call displayScoreByte
        ld a, [score + 2]
        call displayScoreByte
        ret

; hl - address of first digit's tile attribute
; a - BCD value to display
; -> hl - address of third digit's tile attribute
; -> a, b, c - trashed
displayScoreByte:
        ; save left digit in a, right digit in b
        ld c, a
        and a, %00001111
        ld b, a
        ld a, c
        swap a
        and a, %00001111

        ; calculate and write tile
        sla a
        add a, $50
        ld [hl], a
        ; advance to next digit tile attribute
        inc hl
        inc hl
        inc hl
        inc hl
        ld a, b
        ; calculate and write tile
        sla a
        add a, $50
        ld [hl], a
        ; advance to next digit tile attribute
        inc hl
        inc hl
        inc hl
        inc hl
        ret

updatePlayer:
        ; calculate new player position based on current speed
        ld a, 0
        call getSpriteAddress ; player sprite address in bc
        ; grab the current position and chunk
        ld a, [bc]
        ld d, a ;chunk index
        inc bc
        ld a, [bc]
        ld e, a ;x coord within chunk

        ld a, [playerSpeedX]
        ld l, a
        ld h, 0
        bit 7, a
        jp z, .positive
        ld h, $FF
.positive
        add hl, de ;combined player speed and chunk index
        dec bc
        ld a, h
        ld [bc], a ;chunk index (high byte result)
        inc bc
        ld a, l
        ld [bc], a ;x coordinate (low byte result)
        push hl ; stash this for later

        ; similar for Y position, but less work because we don't care about chunk
        inc bc
        inc bc ; now pointing at y coord byte
        ld a, [bc]
        ld e, a ; y-coordinate
        ld a, [playerSpeedY]
        add e
        ld [bc], a

        ; grab the player's current coordinates
        pop bc  ; current chunk and x position
        ld d, a ; d contains original player Y
        ; for starters, the y coordinate is 16 too high for graphics reasons; subtract 16
        ld a, -16
        add a, d
        ld d, a
        ; adjust to the player's center
        ld hl, 8
        add hl, bc
        ld b, h
        ld c, l    ; bc contains playerX + 8
        ; coordinate is now centered at top of sprite
        push bc
        push de
        call collisionTileAt ;bc, d - result in a
        call .checkHeadCollision
        pop de
        pop bc
        ld a, d
        add a, 15
        ld d, a    ; d contains playerY + 15
        ; coordinate is now centered at player's feet
        push bc
        push de
        call collisionTileAt ;bc, d, result in a
        call .checkFeetCollision
        pop de
        pop bc
        ; adjust to player's front
        ld hl, 6
        add hl, bc
        ld b, h
        ld l, c ; bc = 6 pixels in front of player feet
        ld a, -4
        add a, d
        ld d, a ; d = 4 pixels above feet
        ; coordinate is now roughly ahead of player's knees
        push bc
        push de
        call collisionTileAt ;bc, d, result in a
        call .checkForwardCollision
        pop de
        pop bc

        ; handle trivial matters like gravitational forces and space-time
        ld a, [playerAccelTimer]
        dec a
        ld [playerAccelTimer], a
        jp nz, .terminalVelocity
        ld a, 5
        ld [playerAccelTimer], a
        ld a, [playerSpeedY]
        sub a, 3
        bit 7, a
        jp z, .terminalVelocity
        add a, 4
        ld [playerSpeedY], a
.terminalVelocity:

        ; based on the player's position and their current speed, throw the camera out in front of them:
        ld a, c ; remember, c still contains fine X at this point
        add a, -30 ;behind the player = top-left corner of background
        ld [TargetCameraX+1], a


        ; handle player input
        ld a, 2
        ld [playerSpeedX], a
; Note: pretty much all the D-pad checks are for debug only
.checkRight:
        ld a, [keysHeld]
        and a, KEY_RIGHT
        jp z, .checkLeft
        ld a, 1
        ld [playerSpeedX], a
.checkLeft:
        ld a, [keysHeld]
        and a, KEY_LEFT
        jp z, .checkJump
        ld a, -1
        ld [playerSpeedX], a
.checkJump:
        ; firstly, if A was just *released*, then zero out our jump timer. No double-jumping!
        ld a, [keysUp]
        and a, KEY_A | KEY_UP
        jp z, .checkJumpHeld
        ld a, 0
        ld [playerJumpTimer], a
.checkJumpHeld:
        ld a, [keysHeld]
        and a, KEY_A | KEY_UP
        jp z, .done
        ; Player's holding A! Do they have any jump juice left?
        ld a, [playerJumpTimer]
        cp 0
        jp z, .done
        ; Fling yourself into space
        ld a, -3
        ld [playerSpeedY], a
        ld hl, playerJumpTimer
        dec [hl]
        ld a, 5
        ld [playerAccelTimer], a
.done:
        ret

;* input: 
;*   a - collision type of tile at feet
;*   d - y coordinate of player's feet
;* 
.checkFeetCollision:
        ; stash af
        push af
        ; naive check: is it a floor?
        cp 1
        jp nz, .notFloor
        ; floor tiles only have solid floor in their bottom halves.
        ; this check detects whether the foot pixel is in the lower
        ; half of its respective tile, and bails if it is not.
        bit 3, d
        jp z, .notFloor
        ; our foot is inside a floor tile, so we must snap our position
        ; upwards so that our foot rests on the floor tile.
        ld a, 0
        call getSpriteAddress ; player sprite address in bc
        inc bc
        inc bc
        inc bc
        ld a, [bc] ; y-coordinate of player
        and a, %11110000 ; erase tile index
        or a, %00001001 ; set tile index to 8
        ld [bc], a
        ; since we're touching floor, reset our speed to 0:
        ld a, 0
        ld [playerSpeedY], a
        ; if the player has released A here... 
        ld a, [keysHeld]
        and a, KEY_A | KEY_UP
        jp nz, .notFloor
        ; Also refill our jump timer to max (allowing us to jump again if it was empty)
        ld a, 15
        ld [playerJumpTimer], a
        ; done!
.notFloor
        ; un-stash af and bail
        pop af
        ret

.checkForwardCollision:
        ret

.checkHeadCollision:
        ret

INCLUDE "collision.asm"

;* inputs:
;*   b - chunk index
;*   c - coordinate x (within chunk)
;*   d - coordinate y
collisionTileAt:
        ; b is the chunk index into the ring buffer. We need to load the map number
        ; to be able to retrieve the collision tile
        push bc ;don't clobber this
        push de
        ld hl, chunkBuffer
        ld d, 0
        ld e, b
        add hl, de
        ld a, [hl]
        ld b, a ; b now contains the map number

        ; fix x coordinate to count tiles and not pixels
        ld a, c
        swap a
        and a, %00001111
        ld c, a
        ld hl, TestChambers
        add hl, bc
        ; fix y coordinate to count rows, but not tiles within rows
        pop af
        push af      
        and a, %11110000
        ld d, 0
        ld e, a
        add hl, de
        ; hl now points to tile
        ld a, [hl]
        ; use tile type as index into collision lookup table
        ld hl, collisionLUT
        ld c, a
        ld b, 0
        add hl, bc ; hl now points to collision tile type
        ld a, [hl]
        pop de
        pop bc
        ret

pollInput:
        ld a, %00010000
        ld [rP1], a ; select direction keys
        ; several dummy reads
        ld a, [rP1]
        ld a, [rP1]
        ld a, [rP1]
        ; real read
        ld a, [rP1]
        xor a, %11111111
        and a, %00001111
        swap a
        ld b, a
        ld a, %00100000
        ld [rP1], a ; select button keys
        ; several dummy reads
        ld a, [rP1]
        ld a, [rP1]
        ld a, [rP1]
        ; real read
        ld a, [rP1]
        xor a, %11111111
        and a, %00001111
        or a, b
        ld [keysHeld], a
        ld b, a
        ; b now contains current button presses
        ld a, [keysOld]
        xor %11111111 ; if not keysOld
        and b         ; and keysHeld
        ld [keysDown], a ; then the key was just pressed
        ld a, [keysOld]
        ld b, a
        ld a, [keysHeld]
        xor %11111111 ; if not keysHeld
        and b         ; ... but keysOld
        ld [keysUp], a ; then the key was just released
        ld a, [keysHeld]
        ld [keysOld], a
        ret

; *** Turn off the LCD display ***

StopLCD:
        ld      a,[rLCDC]
        rlca                    ; Put the high bit of LCDC into the Carry flag
        ret     nc              ; Screen is off already. Exit.

; Loop until we are in VBlank

.wait:
        ld      a,[rLY]
        cp      145             ; Is display on scan line 145 yet?
        jr      nz,.wait        ; no, keep waiting

; Turn off the LCD

        ld      a,[rLCDC]
        res     7,a             ; Reset bit 7 of LCDC
        ld      [rLCDC],a

        ret


;* End of File *

