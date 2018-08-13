

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
        ; EXPLOSION INDICATOR
        ; determine the distance between the player and the explosion horizon
        ; How far away is the explosion from the player? Ignore sub speed here
        ld hl, SpriteList + SPRITE_CHUNK
        ld b, [hl]
        ld hl, SpriteList + SPRITE_X_POS
        ld c, [hl]
        ; bc = player's chunk + x coordinate
        ld hl, explosionChunk
        ld d, [hl]
        ld hl, explosionPos
        ld e, [hl]
        ; de = explosion chunk + x coordinate
        ; 16-bit subtraction
        ld a, c
        sub a, e
        ld e, a
        ld a, b
        sbc a, d
        ld d, a
        ;de = distance (positive is behing the player)

        ld a, d ; a = chunks ahead of the explosion
        ld de, Vanish
        cp 3
        jp nc, .checkAnimationLeft
        ; we're at least 3 chunks out from blowing up.
        ld de, FlashSlowly
        cp 2
        jp nc, .checkAnimationLeft
        ; we're at least 2 chunks out from blowing up!
        ld de, FlashQuickly
        cp 1
        jp nc, .checkAnimationLeft
        ; we're just 1 chunks out from blowing up!!!!!
        ld de, FlashIntensely
        cp 0
        jp nc, .checkAnimationLeft
        ; we're ... well, we're dead. Oh well.
        ld de, Vanish
.checkAnimationLeft
        ; check to see if our current animation is different from what we want to apply
        ld a, 7
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
        ld a, 7
        call spawnSprite

        ; END OF LEVEL INDICATOR
        ; for slot 8, determine the distance between the player and the death chunk
        ld hl, SpriteList + SPRITE_CHUNK
        ld b, [hl]
        ld a, [deathChunk]
        sub a, b ; a = chunks to go until death
        ; now, using the remaining chunks, we can select an intensity for the animation
        ld de, Vanish
        cp 9
        jp nc, .checkAnimationRight
        ; a is at least less than 8
        ld de, FlashSlowly
        cp 5
        jp nc, .checkAnimationRight
        ; a is at least less than 4
        ld de, FlashQuickly
        cp 3
        jp nc, .checkAnimationRight
        ; a is at least less than 2
        ld de, FlashIntensely
        cp 1
        jp nc, .checkAnimationRight
        ;The player is dead, so _hide_ the animation
        ld de, Vanish
.checkAnimationRight
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


