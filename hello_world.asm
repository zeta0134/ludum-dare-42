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
        INCBIN "data/sprites/blobby1.2bpp"
        INCBIN "data/sprites/blobby2.2bpp"
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
        INCBIN "data/tiles/space_station.2bpp"

TestMapData:
        INCLUDE "data/test_map.asm"

TestChambers:
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
        ld      de,$9000
        ld      bc,16*128        ; length (8 bytes per tile) x (256 tiles)
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
        ld bc, BlobbyBlobs
        call spawnSprite

        ld a, 0
        call getSpriteAddress
        ld b, h
        ld c, l

        ld hl, SPRITE_X_POS
        add hl, bc
        ld [hl], 40

        ld hl, SPRITE_Y_POS
        add hl, bc
        ld [hl], 66

        ld a, 1
        ld bc, BlobbyJumps
        call spawnSprite

        ld a, 1
        call getSpriteAddress
        ld b, h
        ld c, l

        ld hl, SPRITE_X_POS
        add hl, bc
        ld [hl], 60

        ld hl, SPRITE_Y_POS
        add hl, bc
        ld [hl], 66

        ld a, 2
        ld bc, BlobbyWiggles
        call spawnSprite

        ld a, 2
        call getSpriteAddress
        ld b, h
        ld c, l

        ld hl, SPRITE_X_POS
        add hl, bc
        ld [hl], 80

        ld hl, SPRITE_Y_POS
        add hl, bc
        ld [hl], 66

        ld a, 3
        ld bc, PlayerRuns
        call spawnSprite

        ld a, 3
        call getSpriteAddress
        ld b, h
        ld c, l

        ld hl, SPRITE_X_POS
        add hl, bc
        ld [hl], 40

        ld hl, SPRITE_Y_POS
        add hl, bc
        ld [hl], 86

        ld hl, SPRITE_TILE_BASE
        add hl, bc
        ld [hl], 2
        

        ; Now we turn on the LCD display to view the results!

        ld      a,LCDCF_ON|LCDCF_BG8800|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ16|LCDCF_OBJON
        ld      [rLCDC],a       ; Turn screen on

        ; Enable vblank, but nothing else for now
        ld      a,IEF_VBLANK
        ld      [rIE],a
        ei

        ; A game loop might go here. Since we don't have one yet, we just idle infinitely.

GameLoop:
        ; halt until the next vBlank
        halt
        nop ; DMC bug workaround

        ; scroll!
        ld hl, TargetCameraX+1
        inc [hl]

        ;getWordHL TargetCameraY
        ;inc hl
        ;setWordHL TargetCameraY

        call update_Camera
        call updateSprites

        jp      GameLoop

TitleText:
        DB      "Hello Blobby!"


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

