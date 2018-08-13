        PUSHS           
        SECTION "Explosion WRAM",WRAM0
EXPLOSION_BASE_SPRITE EQU 9
EXPLOSION_COUNT EQU 3

debugExplosions: DS 4

; explosion tracks its position the same way the player does, ie, 16bit "on-screen" and 8bit sub
explosionChunk: DS 1
explosionPos: DS 1
explosionPosSub: DS 1

; 8.8 fixed, so there's a "sub" component here too
explosionSpeed: DS 2

; How long before the next movement update?
explosionSpawnDelay: DS 1

; which logical explosion will we update next?
explosionNextParticle: DS 1

; Where are the 6 logical explosions visually?
explosionParticleX: DS 6
explosionParticleY: DS 6

offset: DS EXPLOSION_COUNT

        POPS

initExplosions:
        ld a, EXPLOSION_BASE_SPRITE + 0
        ld bc, Explosion
        call spawnSprite
        setFieldByte SPRITE_X_POS, 4
        setFieldByte SPRITE_Y_POS, 30
        setFieldByte SPRITE_TILE_BASE, 13
        setFieldByte SPRITE_HUD_SPACE, 1

        ld a, EXPLOSION_BASE_SPRITE + 1
        ld bc, Explosion
        call spawnSprite
        setFieldByte SPRITE_X_POS, 4
        setFieldByte SPRITE_Y_POS, 76
        setFieldByte SPRITE_TILE_BASE, 13
        setFieldByte SPRITE_HUD_SPACE, 1
        setFieldByte SPRITE_ANIMATION_DURATION, 8

        ld a, EXPLOSION_BASE_SPRITE + 2
        ld bc, Explosion
        call spawnSprite
        setFieldByte SPRITE_X_POS, 4
        setFieldByte SPRITE_Y_POS, 100
        setFieldByte SPRITE_TILE_BASE, 13
        setFieldByte SPRITE_HUD_SPACE, 1
        setFieldByte SPRITE_ANIMATION_DURATION, 16

        ld a, 0
        ld [explosionChunk], a
        ld [explosionPos], a
        ld [explosionPosSub], a

        ; note here: player speed starts at 2.0, so the explosion starts out
        ; going exactly as fast as the player.
        ld a, 2
        ld [explosionSpeed], a
        ld a, 0
        ld [explosionSpeed+1], a

        ld a, 0
        ld [explosionSpawnDelay], a
        ld [explosionNextParticle], a

        ld [explosionParticleX+0], a
        ld [explosionParticleX+1], a
        ld [explosionParticleX+2], a
        ld [explosionParticleX+3], a
        ld [explosionParticleX+4], a
        ld [explosionParticleX+5], a

        ld a, 60
        ld [explosionParticleY+0], a
        ld [explosionParticleY+1], a
        ld [explosionParticleY+2], a
        ld a, 30
        ld [explosionParticleY+3], a
        ld [explosionParticleY+4], a
        ld [explosionParticleY+5], a

        ld a, "E"
        ld [debugExplosions+0], a
        ld [debugExplosions+1], a
        ld [debugExplosions+2], a
        ld [debugExplosions+3], a

        ret

updateExplosions:
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

        ; If the explosion distance is negative, you died! Too bad.
        bit 7, d
        jp z, .notDead
        ; set animation state to "tumble" (this looks roughly like crouching)
        ld a, 0
        ld bc, StaticAnimation
        call setSpriteAnimation
        setFieldByte SPRITE_TILE_BASE, 6
        ; Tell the player that they're dead
        ld a, 1
        ld [playerDead], a
.notDead
        ; Calculate new explosion position based on current speed
        ld hl, explosionChunk
        ld d, [hl]
        ld hl, explosionPos
        ld e, [hl]
        ; de = chunk + x coord within chunk
        push de ; stash for now

        ; add the low bytes first
        ld a, [explosionSpeed+1] ; explosion low byte
        ld e, a
        ld a, [explosionPosSub]
        add a, e
        ld [explosionPosSub], a
        pop de ; restore full position from earlier
        ld a, [explosionSpeed] ; explosion high byte
        adc a, e ; add explosion high byte to speed high byte
        ld e, a ; result back in e
        ld a, 0
        adc a, d ; carry over into chunk byte
        ld d, a
        ; de now contains original position + explosion speed
        ld hl, explosionPos
        ld [hl], e
        ld hl, explosionChunk
        ld [hl], d
        ; done calculating new position

        ; Adjust the explosion's speed
        ld a, [explosionSpeed] ; high byte
        ; speed cap on the explosion is 4 (player is 5)
        sub a, 4
        bit 7, a
        jp z, .noSpeedIncrease
        ; explosion has the same rate of increase as the player: once per new tile
        ld a, [lastPlayerTile]
        ld b, a
        ld a, [lastRightmostTile]
        cp b
        jp z, .noSpeedIncrease
        ; actually, let's also only increase every OTHER tile
        bit 0, a
        jp z, .noSpeedIncrease
        ; increase explision at 1 unit (sub) per new tile. This is HALF the player's acceleration.
        ld a, [explosionSpeed+1] ; low byte
        add a, 1
        ld [explosionSpeed+1], a
        ld a, [explosionSpeed]
        adc a, 0
        ld [explosionSpeed], a

.noSpeedIncrease
        ; Now that explosion position checks are done, let's get it on-screen!

        ; Is it time to spawn a new particle?
        ld a, [explosionSpawnDelay]
        cp 0
        jp z, .spawnNewParticle
        sub a, 1
        ld [explosionSpawnDelay], a
        jp .skipParticleSpawning

.spawnNewParticle
        ld a, 8
        ld [explosionSpawnDelay], a

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
        ;de = distance (positive is behind the player)

        ; First a visibility check: Is the explosion reasonably close to the player?
        ld a, d
        cp a, $00
        jp z, .behindChunk
        ld a, d
        cp a, $FF ; included here so the explosion shows up on either side of the player
        jp z, .aheadChunk
        jp .notVisible
.behindChunk
        ; only draw this if we're reasonably close to the edge
        ld a, e
        add a, 32
        bit 7, a
        jp nz, .notVisible
        jp .visible
.aheadChunk
        ; only display this if we're within 0 - 160
        ld a, e
        sub a, 160
        bit 7, a
        jp nz, .notVisible
.visible
        ; high byte is within one chunk. This MIGHT not be good enough. We'll see.
        ; Okay, now we start with the player's X coordinate in OAM
        ld a, [shadowOAM + 1] ; first entry, x index
        sub a, 8
        ; subtract the low byte of our distance calculation
        sub a, e
        ld b, a
        ; b = explosion event horizon
        ; now add a little extra randomness with rDIV
        ld a, [rDIV]
        and a, %00001111
        add a, b
        ld b, a ; b = final x coordinate

        ; the y-coordinate is just entirely random
        ld a, [rDIV]
        ; because this might be the same rDIV as above, add the frame counter here for good measure
        ld c, a
        ld a, [FrameCounter]
        add a, c
        and a, %01111111
        ld c, a ; c = final y coordinate

        ; Finally, spawn the particle by writing its coordinates into the proper slot
        ld hl, explosionParticleX
        ld d, 0
        ld a, [explosionNextParticle]
        ld e, a
        add hl, de
        ld [hl], b

        ld hl, explosionParticleY
        ld d, 0
        ld a, [explosionNextParticle]
        ld e, a
        add hl, de
        ld [hl], c

        ; Increase (and wrap around) our counter
        ld a, [explosionNextParticle]
        inc a
        ld [explosionNextParticle], a
        cp a, 6
        jp nz, .skipParticleSpawning
        ld a, 0 ; reset
        ld [explosionNextParticle], a
.skipParticleSpawning
        ; Loop through our list and display the 3 active explosion sprites
        ld de, explosionParticleX
        ld bc, explosionParticleY
        ; Are we on an even or an odd frame?
        ld a, [FrameCounter+1]
        bit 0, a
        jp z, .evenFrame
        inc de ; switch from 0, 2, 4 sequence to 1, 3, 5 sequence
        inc bc
.evenFrame
        push de ; stash X index
        push bc ; stash Y index
        ld a, EXPLOSION_BASE_SPRITE + 0
        call getSpriteAddress
        ld hl, SPRITE_X_POS
        add hl, bc ; hl = sprite address + x pos
        pop bc
        pop de
        ld a, [de] ; x pos
        ld [hl], a
        inc hl
        inc hl
        ld a, [bc] ; y pos
        ld [hl], a
        ; lather rinse repeat for particles 2 and 3
        inc de ; skip ahead to next cached coords
        inc de
        inc bc
        inc bc
        push de ; stash X index
        push bc ; stash Y index
        ld a, EXPLOSION_BASE_SPRITE + 1
        call getSpriteAddress
        ld hl, SPRITE_X_POS
        add hl, bc ; hl = sprite address + x pos
        pop bc
        pop de
        ld a, [de] ; x pos
        ld [hl], a
        inc hl
        inc hl
        ld a, [bc] ; y pos
        ld [hl], a

        inc de ; skip ahead to next cached coords
        inc de
        inc bc
        inc bc
        push de ; stash X index
        push bc ; stash Y index
        ld a, EXPLOSION_BASE_SPRITE + 2
        call getSpriteAddress
        ld hl, SPRITE_X_POS
        add hl, bc ; hl = sprite address + x pos
        pop bc
        pop de
        ld a, [de] ; x pos
        ld [hl], a
        inc hl
        inc hl
        ld a, [bc] ; y pos
        ld [hl], a

        ; Finally, we're done!
        ret

.notVisible
        ; Hide all the explosion sprites and stop.
        ld a, EXPLOSION_BASE_SPRITE + 0
        call getSpriteAddress
        setFieldByte SPRITE_Y_POS, 160
        ld a, EXPLOSION_BASE_SPRITE + 1
        call getSpriteAddress
        setFieldByte SPRITE_Y_POS, 160
        ld a, EXPLOSION_BASE_SPRITE + 2
        call getSpriteAddress
        setFieldByte SPRITE_Y_POS, 160

        ld a, 160
        ld [explosionParticleY+0], a
        ld [explosionParticleY+1], a
        ld [explosionParticleY+2], a
        ld [explosionParticleY+3], a
        ld [explosionParticleY+4], a
        ld [explosionParticleY+5], a

        ret
.done

        ret