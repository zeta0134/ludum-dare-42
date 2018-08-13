titleMapData:
        INCLUDE "data/title.map"

SHIP_Y EQU 118

initTitleScreen:
        call    initOAM
        call initSprites

        ; initialize the viewport with the map data
        di
        call    StopLCD
        setWordImm MapAddress, titleMapData

        ld      a,$e4      ; Standard gradient
        ld      [rBGP],a

        ; set blank tile to be black in this palette
        ld a, $ff
        ld hl, $9000
        ld bc, 16 * 4
        call  mem_Set

        ; set our scroll position
        setWordImm TargetCameraX, 0 
        setWordImm TargetCameraY, 16

        ; initialize the viewport
        call update_Camera
        call init_Viewport

        ld a, 0
        ld bc, TitleSpaceStation
        call spawnSprite
        setFieldByte SPRITE_X_POS, 48 + 8
        setFieldByte SPRITE_Y_POS, SHIP_Y
        setFieldByte SPRITE_TILE_BASE, 29
        setFieldByte SPRITE_HUD_SPACE, 1

        ld a, 1
        ld bc, TitleSpaceStation
        call spawnSprite
        setFieldByte SPRITE_X_POS, 48 + 16 + 8
        setFieldByte SPRITE_Y_POS, SHIP_Y
        setFieldByte SPRITE_TILE_BASE, 29
        setFieldByte SPRITE_HUD_SPACE, 1

        ld a, 2
        ld bc, TitleSpaceStation
        call spawnSprite
        setFieldByte SPRITE_X_POS, 48 + 32 + 8
        setFieldByte SPRITE_Y_POS, SHIP_Y
        setFieldByte SPRITE_TILE_BASE, 29
        setFieldByte SPRITE_HUD_SPACE, 1

        ld a, 3
        ld bc, TitleBuildMaterials
        call spawnSprite
        setFieldByte SPRITE_X_POS, 48 + 48 + 8
        setFieldByte SPRITE_Y_POS, SHIP_Y - 5
        setFieldByte SPRITE_TILE_BASE, 32
        setFieldByte SPRITE_HUD_SPACE, 1

        ld a, 4
        ld bc, TitleExplosion
        call spawnSprite
        setFieldByte SPRITE_X_POS, 48 - 1
        setFieldByte SPRITE_Y_POS, SHIP_Y - 4
        setFieldByte SPRITE_TILE_BASE, 16
        setFieldByte SPRITE_HUD_SPACE, 1

        ld a, 5
        ld bc, PlayerRuns
        call spawnSprite
        setFieldByte SPRITE_X_POS, 51
        setFieldByte SPRITE_Y_POS, 22
        setFieldByte SPRITE_TILE_BASE, 0
        setFieldByte SPRITE_HUD_SPACE, 1

        ;* set our update function for the next game loop
        ld hl, updateTitleScreen
        setWordHL currentGameState

        ; Now we turn on the LCD, and set LCD control parameters (same as gameplay)
        ld      a,LCDCF_ON|LCDCF_BG8800|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ16|LCDCF_OBJON
        ld      [rLCDC],a
        ei

        ; for the title screen, that's it!
        ret

updateTitleScreen:
        call updateSprites
        ld a, [keysUp]
        and a, KEY_START
        jp z, .startNotPressed
        ; it's showtime!
        call initGameplay
.startNotPressed
        ret