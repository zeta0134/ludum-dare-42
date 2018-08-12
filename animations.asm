StaticAnimation:
       ;Duration  Index  X-Offset  Y-Offset  Attributes
        DB  60,       0,        0,        2,        $10
           ;Duration  Index  X-Offset  Y-Offset  Attributes
        DB   0,       0,        0,        0,        $00

PlayerRuns:
           ;Duration  Index  X-Offset  Y-Offset  Attributes
        DB   5,       0,        0,        1,        $10
        DB  10,       0,        0,        0,        $10
        DB   5,       0,        0,        1,        $10
        DB   8,       1,        0,        2,        $10
        DB   8,       2,        0,        2,        $10
        DB   5,       3,        0,        1,        $10
        DB  15,       3,        0,        0,        $10
        DB   5,       3,        0,        1,        $10
        DB   8,       4,        0,        2,        $10
        DB   8,       5,        0,        2,        $10
        DB   0,       0,        0,        0,        $00

ItemBobLightPal:
           ;Duration  Index  X-Offset  Y-Offset
        DB  25,       0,        0,        -1,        $00
        DB  16,       0,        0,         0,        $00
        DB  25,       0,        0,         1,        $00
        DB  16,       0,        0,         0,        $00
        DB   0,       0,        0,         0,        $00

ItemBobDarkPal:
           ;Duration  Index  X-Offset  Y-Offset
        DB  25,       0,        0,        -1,        $10
        DB  16,       0,        0,         0,        $10
        DB  25,       0,        0,         1,        $10
        DB  16,       0,        0,         0,        $10
        DB   0,       0,        0,         0,        $00

Explosion:
           ;Duration  Index  X-Offset  Y-Offset
        DB   8,       0,        0,         0,        $00
        DB   8,       1,        0,         0,        $00
        DB   4,       2,        0,         0,        $00
        DB   4,       3,        0,         0,        $00
        DB   4,       3,        0,         0,        $10
        DB 255,       3,      160,         0,        $10   ; move offscreen to "vanish"
        DB   0,       0,        0,         0,        $00