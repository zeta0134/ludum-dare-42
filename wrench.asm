        PUSHS           
        SECTION "Wrench WRAM",WRAM0
debugWrench: DS 4
debugWrenchActive: DS 1
wrenchState: DS 1
        POPS

initWrench:
        ld a, 0
        ld [wrenchState], a
        ld a, "W"
        ld [debugWrench+0], a
        ld [debugWrench+1], a
        ld [debugWrench+2], a
        ld [debugWrench+3], a
        ret

;* Attempts to spawn a crate in the right-most column (currently just offscreen)
;* Spawning conditions: same tile as either a floor or a floaty platform.
spawnWrench:
        ; random chance! Spawn crates about once per chunk
        ld a, [rDIV]
        and a, %00001111
        jp z, .randomCheckPassed
        ;ret
.randomCheckPassed
        ;* The wrench is stored in sprite slot 1
        ld hl, (SpriteList + 13 + SPRITE_ACTIVE)
        ld a, [hl]
        ld [debugWrenchActive], a
        cp 0
        jp z, .wrenchNotActive
        ; there's already a wrench spawned! Bail.
        ret
.wrenchNotActive
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
        cp COLLISION_AIR
        jp nz, .notAir
        ; wrenches require an air space 2 tiles above a floor space.
        ; advance two tiles forward in memory
        pop hl  ; grab our current tile index again
        push hl
        add hl, bc
        add hl, bc ; skip ahead two tiles
        ld a, [hl] ; a contains a floor tile
        ld hl, collisionLUT
        add a, l
        ld l, a
        ld a, 0
        adc a, h
        ld h, a
        ld a, [hl] ; a now contains collision type
        cp COLLISION_FLOOR
        jp z, .foundSpawnPoint
.notAir
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
.foundSpawnPoint
        ; pop hl to clear the map column index
        pop hl
        ; pop again; a now contains sprite slot, pointing to ACTIVE
        pop af
        ; e now contains the row number of the spawn point, so convert that into a pixel count
        swap e ; e now contains the spawn height
        ; stash this (I don't remember if item spawning clobbers de; it probably does)
        push de

        ld a, 1
        ld bc, ItemBobDarkPal
        call spawnSprite
        setFieldByte SPRITE_TILE_BASE, 12
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

        ld a, 0
        ld [wrenchState], a

        ret

updateWrench:
        ld a, 1
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
        ld a, [wrenchState]
        cp 0
        jp z, .checkPlayerCollision
        ret 
.checkPlayerCollision
        ;* Is the player colliding with us?
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
        ; proceed to do something fancy!

        ld a, 1
        ld bc, ItemCollect
        call setSpriteAnimation

        ; mark ourselves as "active" so we don't collide again next frame
        ld a, 1
        ld [wrenchState], a

        ; generate 4 new chunks for the player
        ld a, [chunksToGenerate]
        add a, 4
        ld [chunksToGenerate], a
        ld a, 30
        ld [chunkCooldownTimer], a

        ; done!

.noCollision
        ret
.die
        ; bc still contains sprite index to de-spawn
        ld hl, SPRITE_ACTIVE
        add hl, bc
        ld a, 0
        ld [hl], a
        ; mark ourselves as inactive, so the next spawn can collide
        ld a, 0
        ld [wrenchState], a

        ; and we're done
        ret
