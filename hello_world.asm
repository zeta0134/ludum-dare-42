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
        ld      bc,2048
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
        setFieldByte SPRITE_X_POS, 80
        setFieldByte SPRITE_Y_POS, 66
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
        ld a, 1
        ld [chunkBuffer+1], a
        ld a, 2
        ld [chunkBuffer+2], a
        ; debug
        ld a, 66
        ld [tDebugGraphics+0], a
        ld [tDebugGraphics+1], a
        ld [tDebugGraphics+2], a
        ld [tDebugGraphics+3], a

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

        ; scroll!
        ;ld      hl, TargetCameraX+1
        ;inc     [hl]
        ;inc     [hl]

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
        and a, %00000011 ; for now, restrict to 4 chunks in the buffer
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
        ld hl, shadowOAM + 34 * 4;
        ld d, 5
        ld a, 60
.loop
        ld [hl], 20 ; y-coordinate 
        inc hl
        ld [hl+], a ; x-coordinate 
        ld [hl], $50 ; tile-index
        inc hl
        inc hl ; skip over attributes
        add a, 8
        dec d
        jp nz, .loop
        ret

increaseScore:
        ; TODO: this
        ret

displayScore:
        ; todo: this
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

        ; similar for Y position, but less work because we don't care about chunk
        inc bc
        inc bc ; now pointing at y coord byte
        ld a, [bc]
        ld e, a ; y-coordinate
        ld a, [playerSpeedY]
        add e
        ld [bc], a

        ; handle player input
        ld a, 0
        ld [playerSpeedX], a
        ld [playerSpeedY], a
.checkRight
        ld a, [keysHeld]
        and a, KEY_RIGHT
        jp z, .checkLeft
        ld a, 1
        ld [playerSpeedX], a
.checkLeft
        ld a, [keysHeld]
        and a, KEY_LEFT
        jp z, .checkUp
        ld a, -1
        ld [playerSpeedX], a
.checkUp
        ld a, [keysHeld]
        and a, KEY_UP
        jp z, .checkDown
        ld a, -1
        ld [playerSpeedY], a
.checkDown
        ld a, [keysHeld]
        and a, KEY_DOWN
        jp z, .done
        ld a, 1
        ld [playerSpeedY], a
.done
        ret

INCLUDE "collision.asm"

;* inputs:
;*   b - chunk index
;*   c - coordinate x (within chunk)
;*   d - coordinate y
collisionTileAt:
        push de
        ; fix x coordinate to count tiles and not pixels
        ld a, c
        swap a
        and a, %00001111
        ld c, a
        ld hl, TestChambers
        add hl, bc
        ; fix y coordinate to count rows, but not tiles within rows
        pop af
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

