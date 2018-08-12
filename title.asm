titleMapData:
        INCLUDE "data/title.map"

initTitleScreen:
        call    initOAM
        call initSprites

        ; initialize the viewport with the map data
        di
        call    StopLCD
        setWordImm MapAddress, titleMapData

        ; set our scroll position
        setWordImm TargetCameraX, 0 
        setWordImm TargetCameraY, 0

        ; initialize the viewport
        call update_Camera
        call init_Viewport

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
        ld a, [keysUp]
        and a, KEY_START
        jp z, .startNotPressed
        ; it's showtime!
        call initGameplay
.startNotPressed
        ret