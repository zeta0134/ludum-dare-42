        PUSHS           
        SECTION "Explosion WRAM",WRAM0
EXPLOSION_BASE_SPRITE EQU 9
EXPLOSION_COUNT EQU 3

offset: DS EXPLOSION_COUNT

        POPS

initExplosions:
        ld a, EXPLOSION_BASE_SPRITE + 0
        ld bc, Explosion
        call spawnSprite
        setFieldByte SPRITE_X_POS, 4
        setFieldByte SPRITE_Y_POS, 30
        setFieldByte SPRITE_TILE_BASE, 16
        setFieldByte SPRITE_HUD_SPACE, 1

        ; ld a, EXPLOSION_BASE_SPRITE + 1
        ; ld bc, Explosion
        ; call spawnSprite
        ; setFieldByte SPRITE_X_POS, 4
        ; setFieldByte SPRITE_Y_POS, 76
        ; setFieldByte SPRITE_TILE_BASE, 16
        ; setFieldByte SPRITE_HUD_SPACE, 1

        ; ld a, EXPLOSION_BASE_SPRITE + 2
        ; ld bc, Explosion
        ; call spawnSprite
        ; setFieldByte SPRITE_X_POS, 4
        ; setFieldByte SPRITE_Y_POS, 100
        ; setFieldByte SPRITE_TILE_BASE, 16
        ; setFieldByte SPRITE_HUD_SPACE, 1
        ret

updateExplosions:
        ret