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

         ; note: order is important (I think)
        INCLUDE "vendor/memory.asm"
        INCLUDE "util.asm"

        INCLUDE "animations.asm"
        INCLUDE "graphics.asm"
        INCLUDE "input.asm"

        INCLUDE "gameplay.asm"
        INCLUDE "player.asm"


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

        ; Clear the background
        ld      a,$00          ; ASCII " "
        ld      hl,$9800
        ld      bc,SCRN_VX_B * SCRN_VY_B
        call    mem_Set

        ; Set our map to the test chunk
        setWordImm MapAddress, TestChambers

        ; set our scroll position
        setWordImm TargetCameraX, 0 
        setWordImm TargetCameraY, 16

        ; initialize the viewport
        call update_Camera
        call init_Viewport

        ; initialize some testing sprites
        call    initOAM
        call initSprites

        ; we start in main gameplay mode for now, so initialize all of that
        call initGameplay

        

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
score: DS 3
chunkBuffer: DS 256
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

