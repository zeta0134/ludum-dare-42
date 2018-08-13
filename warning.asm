

initWarningIndicators:
        ld a, 7
        ld bc, Vanish
        call spawnSprite
        setFieldByte SPRITE_X_POS, 4
        setFieldByte SPRITE_Y_POS, 76
        setFieldByte SPRITE_TILE_BASE, 10
        setFieldByte SPRITE_HUD_SPACE, 1

        ld a, 8
        ld bc, Vanish
        call spawnSprite
        setFieldByte SPRITE_X_POS, 140
        setFieldByte SPRITE_Y_POS, 76
        setFieldByte SPRITE_TILE_BASE, 10
        setFieldByte SPRITE_HUD_SPACE, 1

        ret

updateWarningIndicators:
        ; Note: explosion isn't implemented yet, so we don't do anything with slot 7

        ; for slot 8, determine the distance between the player and the death chunk
        ld hl, SpriteList + SPRITE_CHUNK
        ld b, [hl]
        ld a, [deathChunk]
        sub a, b ; a = chunks to go until death
        ; now, using the remaining chunks, we can select an intensity for the animation
        ld de, Vanish
        cp 9
        jp nc, .checkAnimation
        ; a is at least less than 8
        ld de, FlashSlowly
        cp 5
        jp nc, .checkAnimation
        ; a is at least less than 4
        ld de, FlashQuickly
        cp 3
        jp nc, .checkAnimation
        ; a is at least less than 2
        ld de, FlashIntensely
        cp 1
        jp nc, .checkAnimation
        ;The player is dead, so _hide_ the animation
        ld de, Vanish
.checkAnimation
        ; check to see if our current animation is different from what we want to apply
        ld a, 8
        call getSpriteAddress ; sprite address in bc
        ld hl, SPRITE_ANIMATION_START
        add hl, bc
        push de ;stash new animation
        ld e, [hl]
        inc hl
        ld d, [hl] ; de contains current animation
        pop bc ; bc contains new animation
        ; subtract the high and low components, then OR the result
        ld a, d
        sub a, b
        ld d, a
        ld a, e
        sub a, c
        or d
        ; if the result is zero, the original values match, so no need to update animation
        jp z, .done
        ld a, 8
        call spawnSprite
.done
        ret


