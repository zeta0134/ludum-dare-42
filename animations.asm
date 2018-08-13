StaticAnimation:
       ;Duration  Index  X-Offset  Y-Offset  Attributes
        DB  60,       0,        0,        2,        $10
           ;Duration  Index  X-Offset  Y-Offset  Attributes
        DB   0,       0,        0,        0,        $00

TitleSpaceStation:
        ; Duration,  Index,  X,  Y,  Attributes
        DB 18, 2, 0, 0, $00
        DB 18, 1, 0, 0, $00
        DB 18, 0, 0, 0, $00
        DB 0, 0, 0, 0, $00

TitleBuildMaterials:
        ; Duration,  Index,  X,  Y,  Attributes
        DB 8, 1, 0, 0, $00
        DB 8, 0, 0, 0, $00
        DB 0, 0, 0, 0, $00

TitleExplosion:
        ; Duration,  Index,  X,  Y,  Attributes
        DB 8, 0, 0, 0, $00
        DB 8, 1, 0, 0, $00
        DB 14, 2, 0, 0, $00
        DB 0, 0, 0, 0, $00

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

CrateIdle:
           ;Duration  Index  X-Offset  Y-Offset  Attributes
        DB  60,       0,        0,        0-3,        $10
           ;Duration  Index  X-Offset  Y-Offset  Attributes
        DB   0,       0,        0,        0,        $00

CrateKicked:
           ;Duration  Index  X-Offset  Y-Offset  Attributes   
        DB   2,       0,        3,       -2-3,        $10
        DB   2,       0,        6,       -4-3,        $10
        DB   2,       0,        9,       -5-3,        $10
        DB   2,       0,       12,       -6-3,        $10
        DB   2,       0,       15,       -6-3,        $00
        DB   2,       0,       18,       -5-3,        $00
        DB   2,       0,       21,       -4-3,        $00
        DB   2,       0,       24,       -3-3,        $00
        DB   2,       0,       27,       -2-3,        $00
        DB   2,       0,       30,       -1-3,        $00
        DB   2,       0,       32,       -0-3,        $00
        DB   2,       0,       33,       -1-3,        $00
        DB   2,       0,       34,       -1-3,        $00
        DB   2,       0,       35,       -0-3,        $00
        DB 255,       0,       35,       -0-3,        $00 ;hold until despawn
           ;Duration  Index  X-Offset  Y-Offset  Attributes
        DB   0,       0,        0,        0,        $00    