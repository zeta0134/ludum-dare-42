        PUSHS           
        SECTION "Crate WRAM",WRAM0
debugCrateMarker: DS 4
debugFoundSlot: DS 1
        POPS

;* Attempts to spawn a crate in the right-most column (currently just offscreen)
;* Spawning conditions: same tile as either a floor or a floaty platform.
spawnCrate:
        ; random chance! Spawn crates about once per chunk
        ld a, [rDIV]
        and a, %00001111
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
        ;* Is the player colliding with us?
        ;* STUB

        ;* Are we offscreen to the left? If so, die an honorable death.
        ld e, 4
.loop
        ld a, e
        call getSpriteAddress ;bc = address to ourselves
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
        ; and we're done
        ret


;* finds and returns the pointer to the top most tile in the active map, in the
;* column that is presently being drawn on the right side of the screen.
activeMapActiveColumn:
        ld hl, chunkBuffer
        ld d, 0
        ld a, [currentChunk]
        ld e, a
        add hl, de
        ld a, [hl]
        ld b, a ; b now contains the map number
        ld a, [lastRightmostTile]
        ld c, a
        ; bc now contains chunk offset + column-offset
        ld hl, TestChambers
        add hl, bc
        ; we're done; Y = 0 here, so hl now points to the top of the active column
        ret

