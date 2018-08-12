initGameplay:
        call initPlayer
        call initScore

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

        ret
