        PUSHS           
        SECTION "Player WRAM",WRAM0
playerDebugMarkers: DS 4
playerLastCollisionHead: DS 4
playerLastCollisionFeet: DS 4
playerLastCollisionWall: DS 4
playerLastCollisionMap: DS 2
playerSpeedX: DS 2
playerSubX: DS 1
playerSpeedY: DS 1
playerJumpTimer: DS 1
playerAccelTimer: DS 1
playerDeathTimer: DS 1
playerDead: DS 1
lastPlayerTile: DS 1
        POPS

initPlayer:
        ; setup the player's base sprite
        ld a, 0
        ld bc, PlayerRuns
        call spawnSprite
        setFieldByte SPRITE_X_POS, 40
        setFieldByte SPRITE_Y_POS, 86
        setFieldByte SPRITE_TILE_BASE, 0
        setFieldByte SPRITE_CHUNK, 0

        ; Initialize gameplay variables to sane values
        ld a, 2
        ld [playerSpeedX+0], a
        ld a, 0
        ld [playerSpeedX+1], a
        ld [playerSpeedY], a
        ld [playerSubX], a
        ld a, 1
        ld [playerAccelTimer], a
        ; don't let the player jump in mid-air if we start them there
        ; (the first floor tile they hit will refresh this)
        ld a, 0
        ld [playerJumpTimer], a
        ld [playerDead], a
        ; Amount of time we remain in "gameplay" mode upon death, before
        ; transitioning to a gameover screen
        ld a, 60
        ld [playerDeathTimer], a

        ; debug stuff
        ld a, 66
        ld [playerDebugMarkers+0], a
        ld [playerDebugMarkers+1], a
        ld [playerDebugMarkers+2], a
        ld [playerDebugMarkers+3], a
        ret

updatePlayer:
        ld a, [playerDead]
        cp 0
        jp z, .notDead
        ; how unfortunate
        ld hl, playerDeathTimer
        dec [hl]
        jp nz, .deathLimbo
        call initTitleScreen
.deathLimbo
        ret

.notDead
        ; calculate new player position based on current speed
        ld a, 0
        call getSpriteAddress ; player sprite address in bc
        ; grab the current position and chunk
        ld a, [bc]
        ld d, a ;chunk index
        inc bc
        ld a, [bc]
        ld e, a ;x coord within chunk
        push de ;stash for now

        ld a, [playerSpeedX+1] ;speed low byte
        ld e, a
        ld a, [playerSubX]
        add a, e
        ld [playerSubX], a ;add speed low byte to subX, maintain carry
        pop de ; restore full position from earlier
        ld a, [playerSpeedX]
        adc a, e ; add player speed high byte to coordinate x, w/ carry
        ld e, a ;result back in e
        ld a, 0
        adc a, d ; carry over to chunk byte
        ld d, a
        ; de now contains original position + player speed
        ld h, d
        ld l, e
        
        dec bc
        ld a, h
        ld [bc], a ;chunk index (high byte result)
        inc bc
        ld a, l
        ld [bc], a ;x coordinate (low byte result)
        push hl ; stash this for later

        ; similar for Y position, but less work because we don't care about chunk
        inc bc
        inc bc ; now pointing at y coord byte
        ld a, [bc]
        ld e, a ; y-coordinate
        ld a, [playerSpeedY]
        add e
        ld [bc], a

        ; grab the player's current coordinates
        pop bc  ; current chunk and x position
        ld d, a ; d contains original player Y
        ; for starters, the y coordinate is 16 too high for graphics reasons; subtract 16
        ld a, -16
        add a, d
        ld d, a
        ; adjust to the player's center
        ld hl, 8
        add hl, bc
        ld b, h
        ld c, l    ; bc contains playerX + 8
        ; coordinate is now centered at top of sprite
        push bc
        push de
        setWordBC playerLastCollisionHead
        setWordDE playerLastCollisionHead+2
        call collisionTileAt ;bc, d - result in a
        call .checkHeadCollision
        pop de
        pop bc
        ld a, d
        add a, 15
        ld d, a    ; d contains playerY + 15
        ; coordinate is now centered at player's feet
        push bc
        push de
        setWordBC playerLastCollisionFeet
        setWordDE playerLastCollisionFeet+2
        call collisionTileAt ;bc, d, result in a
        call .checkFeetCollision
        pop de
        pop bc
        ; adjust to player's front
        ld hl, 6
        add hl, bc
        ld b, h
        ld l, c ; bc = 6 pixels in front of player feet
        ld a, -4
        add a, d
        ld d, a ; d = 4 pixels above feet
        ; coordinate is now roughly ahead of player's knees
        push bc
        push de
        setWordBC playerLastCollisionWall
        setWordDE playerLastCollisionWall+2
        call collisionTileAt ;bc, d, result in a
        call .checkForwardCollision
        pop de
        pop bc

        ; adjust the player's speed. 
        ;Max speed is 6 (px per frame)
        ld a, [playerSpeedX]
        sub a, 5
        bit 7, a
        jp z, .noSpeedIncrease
        ; increase the sub-speed w/ carry once per column. (+4)
        ld a, [lastPlayerTile]
        ld b, a
        ld a, [lastRightmostTile]
        cp b
        jp z, .noSpeedIncrease
        ld a, [playerSpeedX+1]
        add a, 2
        ld [playerSpeedX+1], a
        ld a, [playerSpeedX]
        adc a, 0
        ld [playerSpeedX], a

.noSpeedIncrease
        ld a, [lastRightmostTile]
        ld [lastPlayerTile], a

        ; handle trivial matters like gravitational forces and space-time
        ld a, [playerAccelTimer]
        dec a
        ld [playerAccelTimer], a
        jp nz, .terminalVelocity
        ld a, 5
        ld [playerAccelTimer], a
        ld a, [playerSpeedY]
        sub a, 3
        bit 7, a
        jp z, .terminalVelocity
        add a, 4
        ld [playerSpeedY], a
.terminalVelocity:

        ; based on the player's position and their current speed, throw the camera out in front of them:
        ld a, c ; remember, c still contains fine X at this point
        add a, -30 ;behind the player = top-left corner of background
        ld [TargetCameraX+1], a


        ; handle player input
        ;ld a, 2
        ;ld [playerSpeedX], a
; Note: pretty much all the D-pad checks are for debug only
.checkRight:
        ld a, [keysHeld]
        and a, KEY_RIGHT
        jp z, .checkLeft
        ld a, 1
        ld [playerSpeedX], a
.checkLeft:
        ld a, [keysHeld]
        and a, KEY_LEFT
        jp z, .checkJump
        ld a, -1
        ld [playerSpeedX], a
.checkJump:
        ; firstly, if A was just *released*, then zero out our jump timer. No double-jumping!
        ld a, [keysUp]
        and a, KEY_A | KEY_UP
        jp z, .checkJumpHeld
        ld a, 0
        ld [playerJumpTimer], a
.checkJumpHeld:
        ld a, [keysHeld]
        and a, KEY_A | KEY_UP
        jp z, .done
        ; Player's holding A! Do they have any jump juice left?
        ld a, [playerJumpTimer]
        cp 0
        jp z, .done
        ; Fling yourself into space
        ld a, -3
        ld [playerSpeedY], a
        ld hl, playerJumpTimer
        dec [hl]
        ld a, 5
        ld [playerAccelTimer], a
.done:
        ret

;* input: 
;*   a - collision type of tile at feet
;*   d - y coordinate of player's feet
;* 
.checkFeetCollision:
        ; stash af
        push af
        ; naive check: is it a floor?
        cp 1
        jp nz, .notFloor
        ; floor tiles only have solid floor in their bottom halves.
        ; this check detects whether the foot pixel is in the lower
        ; half of its respective tile, and bails if it is not.
.standablePlatform
        bit 3, d
        jp z, .endFootCollision
        ; our foot is inside a floor tile, so we must snap our position
        ; upwards so that our foot rests on the floor tile.
        ld a, 0
        call getSpriteAddress ; player sprite address in bc
        inc bc
        inc bc
        inc bc
        ld a, [bc] ; y-coordinate of player
        and a, %11110000 ; erase tile index
        or a, %00001001 ; set tile index to 8
        ld [bc], a
        ; since we're touching floor, reset our speed to 0:
        ld a, 0
        ld [playerSpeedY], a
        ; if the player has released A here... 
        ld a, [keysHeld]
        and a, KEY_A | KEY_UP
        jp nz, .endFootCollision
        ; Also refill our jump timer to max (allowing us to jump again if it was empty)
        ld a, 15
        ld [playerJumpTimer], a
        ; done!
        ; un-stash af and bail
        pop af
        ret
.notFloor
        pop af
        push af
        ; af once again contains the collision tile
        ; is it a floaty platform?
        cp 4
        jp nz, .endFootCollision
        ; floaty platforms are like regular floors, but with an additional constraint:
        ; they are only collision targets when our Y speed is positive (ie, we're falling)
        ; This allows the player to jump up through the floaty platforms without getting
        ; snapped to their surface weirdly.
        ld a, [playerSpeedY]
        bit 7, a
        jp z, .standablePlatform
.endFootCollision
        ; un-stash af and bail
        pop af
        ret

.checkForwardCollision:
        ; we only really care about walls for now
        cp 2
        jp nz, .notWall
        ; oh no! you died.
        ; set animation state to "pancake"
        ld a, 0
        ld bc, StaticAnimation
        call setSpriteAnimation
        setFieldByte SPRITE_TILE_BASE, 9
        ; push the player out of the wall
        ld a, 0
        call getSpriteAddress ; player sprite address in bc
        inc bc     
        ld a, [bc] ; x-coordinate of player
        and a, %11110000 ;mask off the tile position
        or a, %00000110 ; replace it with a suitable wall-splat position
        ld [bc], a
        ; we have to tell the player they're dead :(
        ld a, 1
        ld [playerDead], a
.notWall
        ret

.checkHeadCollision:
        ; stash af
        push af
        ; is it a ceiling?
        cp 3
        jp nz, .notCeiling
        ; ceiling tiles are only solid in their top halves.
        ; this check detects whether the head pixel is in the top
        ; half of its respective tile, and bails if it is not.
        bit 3, d
        jp nz, .notCeiling
        ; our head is inside a ceiling tile, so we must snap our position
        ; downwards so that our head isn't inside the tile anymore
        ld a, 0
        call getSpriteAddress ; player sprite address in bc
        inc bc
        inc bc
        inc bc
        ld a, [bc] ; y-coordinate of player
        and a, %11110000 ; erase tile index
        or a, %00000111 ; set tile index to 8
        ld [bc], a
        ; also reset our vertical speed to 0:
        ld a, 1
        ld [playerSpeedY], a
        ; and kill the jump timer; no hugging the ceiling!
        ld a, 0
        ld [playerJumpTimer], a
        ; done!
.notCeiling
        ; un-stash af and bail
        pop af
        ret



INCLUDE "collision.asm"

;* inputs:
;*   b - chunk index
;*   c - coordinate x (within chunk)
;*   d - coordinate y
collisionTileAt:
        ; b is the chunk index into the ring buffer. We need to load the map number
        ; to be able to retrieve the collision tile
        push bc ;don't clobber this
        push de
        ld hl, chunkBuffer
        ld d, 0
        ld e, b
        add hl, de
        ld a, [hl]
        ld b, a ; b now contains the map number
        setWordBC playerLastCollisionMap

        ; fix x coordinate to count tiles and not pixels
        ld a, c
        swap a
        and a, %00001111
        ld c, a
        ld hl, TestChambers
        add hl, bc
        ; fix y coordinate to count rows, but not tiles within rows
        pop af
        push af      
        and a, %11110000
        ld d, 0
        ld e, a
        add hl, de
        ; hl now points to tile
        ld a, [hl]
        ; use tile type as index into collision lookup table
        ld hl, collisionLUT
        ld c, a
        ld b, 0
        add hl, bc ; hl now points to collision tile type
        ld a, [hl]
        pop de
        pop bc
        ret