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
        INCLUDE "title.asm"
        INCLUDE "player.asm"
        INCLUDE "score.asm"
        INCLUDE "crate.asm"
        INCLUDE "wrench.asm"


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
        INCLUDE "data/end_of_the_road.map"
        INCLUDE "data/plain_aa.map"
        INCLUDE "data/path_narrows_ac.map"
        INCLUDE "data/path_widens_ca.map"
        INCLUDE "data/path_split_ab.map"
        INCLUDE "data/path_split_ba.map"

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

        ; Copy background tile data into VRAM at $8000.

        ld      hl,SpaceStationTiles
        ld      de,$8840
        ld      bc,16*256        ; length (8 bytes per tile) x (256 tiles)
        call    mem_Copy    ; Copy tile data to memory

        ; Copy sprite data into VRAM

        ld      hl,SpriteData
        ld      de,$8000
        ld      bc,$880
        call    mem_Copy

        ; Clear the background
        ld      a,$00
        ld      hl,$9800
        ld      bc,SCRN_VX_B * SCRN_VY_B
        call    mem_Set

        call initInput      

        ; we start in main gameplay mode for now, so initialize all of that
        call initTitleScreen

        ; Enable vblank, but nothing else for now
        ld      a,IEF_VBLANK
        ld      [rIE],a
        ei

        ; It's show time!

        PUSHS           
        SECTION "Main WRAM",WRAM0
currentGameState: DS 2
        POPS

gameLoop:
        ; halt until the next vBlank
        halt
        nop ; DMC bug workaround

        call    runGameState
        call    pollInput

        jp      gameLoop

runGameState:
    getWordHL currentGameState
    jp hl
    ; game state returns

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

