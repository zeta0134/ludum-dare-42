        PUSHS           
        SECTION "Crate WRAM",WRAM0
debugCrateMarker: DS 4
debugFoundSlot: DS 1
crateState: DS 3
        POPS

initCrates:
        ld hl, crateState
        ld a, 0
        ld [hl+], a
        ld [hl+], a
        ld [hl+], a
        ret

;* Attempts to spawn a crate in the right-most column (currently just offscreen)
;* Spawning conditions: same tile as either a floor or a floaty platform.
spawnCrate:
        ; random chance! Spawn crates about once per chunk
        ld a, [rDIV]
        and a, %00011111
        jp z, .randomCheckPassed
        ret
.randomCheckPassed
        ;* Crates are stored in sprite slots 4-6. Find an empty one, or bail.
        ld hl, SpriteList + (13 * 4) + SPRITE_ACTIVE
        ld b, 4
        ld a, [hl]
        cp 0
        jp z, .foundFreeSlot ; slot 4
        ld de, 13
        add hl, de
        inc b
        ld a, [hl]
        cp 0
        jp z, .foundFreeSlot ; slot 5
        add hl, de
        inc b
        ld a, [hl]
        cp 0
        jp z, .foundFreeSlot ; slot 6
        ; no free slots for crates! bail.
        ret
.foundFreeSlot
        ld a, b
        ld [debugFoundSlot], a
        push bc ; stash slot index
        ; figure out the starting tile 
        call activeMapActiveColumn ; hl = top of active column
        push hl
        ld bc, 16 ; row offset
        ld e, 1 ; height of map
.loop
        ld a, [hl]
        ld hl, collisionLUT
        add a, l
        ld l, a
        ld a, 0
        adc a, h
        ld h, a
        ld a, [hl] ; a now contains collision type
        cp COLLISION_FLOOR
        jp z, .foundFloor
        cp COLLISION_PLATFORM
        jp z, .foundFloor
        pop hl
        add hl, bc
        push hl
        inc e
        ld a, e
        cp 11
        jp nz, .loop
        ; no floor tiles found! bail.
        pop hl ;clear hl stash
        pop hl ;clear bc stash
        ret
.foundFloor
        ; pop hl to clear the map column index
        pop hl
        ; pop again; a now contains sprite slot, pointing to ACTIVE
        pop af
        ; e now contains the row number of the spawn point, so convert that into a pixel count
        swap e ; e now contains the spawn height
        ; stash this (I don't remember if item spawning clobbers de; it probably does)
        push de

        ld bc, CrateIdle
        call spawnSprite
        setFieldByte SPRITE_TILE_BASE, 11
        ; bc now points to start of sprite entry
        ld hl, SPRITE_Y_POS
        add hl, bc
        pop de
        ld [hl], e
        ld hl, SPRITE_X_POS
        add hl, bc
        ; x position should be right-most column * 16
        ld a, [lastRightmostTile]
        swap a
        ld [hl], a
        ; chunk is the current map chunk
        ld hl, SPRITE_CHUNK
        add hl, bc
        ld a, [currentChunk]
        ld [hl], a

        ;* STUB
        ret

updateCrates:
        ld e, 4
.loop
        ld a, e
        call getSpriteAddress ;bc = address to ourselves
        ;* Are we offscreen to the left? If so, die an honorable death.
        ld hl, SPRITE_CHUNK
        add hl, bc
        ld d, [hl]
        ld a, [currentChunk]
        sub a, d ; a = how many chunks behind active are we
        ; we tolerate a being 0 or 1, but no more. 
        sub a, 2
        ; if a is still positive, then die an honorable death
        bit 7, a
        jp z, .die
        ; are we in a state where we can collide with the player?
        ld hl, crateState - 4
        ld d, 0
        add hl, de
        ld a, [hl]
        cp 0
        jp z, .checkPlayerCollision
        push de
        jp .noCollision

.checkPlayerCollision
        ;* Is the player colliding with us?
        push de; stash counter
        ld hl, SPRITE_CHUNK
        add hl, bc
        ld a, [hl]
        ld d, a ; d = our chunk 
        inc hl
        ld a, [hl]
        and a, %11110000
        ld e, a ; e = our x tile
        inc hl
        inc hl
        ld a, [hl]
        and a, %11110000
        swap a
        ; decrement a = effective y - 16
        dec a
        or e
        ld e, a ; e = our coordinates
        push de ; stash!

        ; grab the player's coordinates
        ld bc, SpriteList
        ld hl, SPRITE_CHUNK
        add hl, bc
        ld a, [hl]
        ld d, a ; d = player's chunk 
        inc hl
        ld a, [hl]
        and a, %11110000
        ld e, a ; e = player's x tile
        inc hl
        inc hl
        ld a, [hl]
        and a, %11110000
        swap a
        or e
        ld e, a ; de = player's chunk + coordinates
        pop bc ; our chunk + coordinates
        
        ; compare!
        ld a, b
        cp a, d
        jp nz, .noCollision
        ld a, c
        cp a, e
        jp nz, .noCollision
        ; if we got here, the player's tile coordinates overlap ours.
        ; proceed to kick ourselves!

        pop de
        push de
        ld a, e
        ld bc, CrateKicked
        call setSpriteAnimation

        ; slow down the player
        ld a, [playerSpeedX+0]
        sub 3
        bit 7, a
        jp nz, .lowSpeedLimit
        ld a, [playerSpeedX+0]
        dec a
        ld [playerSpeedX+0], a
        jp .doneWithSpeed
.lowSpeedLimit
        ; we're already going close to the speed minimum (speed <= 2) so just
        ; clear out the sub speed. That way the player can't ever end up going
        ; backwards from hitting a bunch of crates in a row.
        ld a, 0
        ld [playerSpeedX+1], a
.doneWithSpeed

        ; set the player's animation to tumble, and set their tumble timer
        ld a, 0
        ld bc, PlayerTumble
        call spawnSprite
        setFieldByte SPRITE_TILE_BASE, 6
        ld a, 30
        ld [playerTumbleTimer], a

        ; mark ourselves as "active" so we don't collide again next frame
        pop de
        push de
        ld d, 0
        ld hl, crateState - 4
        add hl, de
        ld a, 1
        ld [hl], a

        ; done!

.noCollision
        pop de ; un-stash counter
        inc e
        ld a, e
        cp 7
        jp nz, .loop
        ret
.die
        ; bc still contains sprite index to de-spawn
        ld hl, SPRITE_ACTIVE
        add hl, bc
        ld a, 0
        ld [hl], a
        ; mark ourselves as inactive, so the next spawn can collide
        ld d, 0
        ld hl, crateState - 4
        add hl, de
        ld a, 0
        ld [hl], a

        ; and we're done
        inc e
        ld a, e
        cp 7
        jp nz, .loop
        ret


