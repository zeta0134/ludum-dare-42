
        PUSHS           
        SECTION "Gameplay WRAM",WRAM0
chunkMarkers: DS 4
lastRightmostTile: DS 1
currentChunk: DS 1
chunkBuffer: DS 256

materialMarkers: DS 4
materialSection:

MATERIAL_SPAWN_COOLDOWN_FRAMES_INIT EQU 27
MATERIAL_SPRITE_BASE EQU 12

materialSpawnCooldownFrames: DS 1
nextMaterialIndex: DS 1
remainingMaterials: DS 1

; needs a x/y position and velocity x5
buildingMaterials: DS 5 * 4

MATERIAL_BASE_X EQU 24
MATERIAL_BASE_VELOCITY EQU 4

MATERIAL_X EQU 0
MATERIAL_Y EQU 1
MATERIAL_VX EQU 2
MATERIAL_VY EQU 3

BUILDING_MATERIAL_ACCELERATION EQU 1
        POPS

updateGameplay:
        call    updateChunks
        call    update_Camera
        call    updateSprites
        call    displayScore
        call    updatePlayer
        call    updateMaterials
        ret

initGameplay:
        ld a, "@"
        ld [materialMarkers + 0], a
        ld [materialMarkers + 1], a
        ld [materialMarkers + 2], a
        ld [materialMarkers + 3], a

        ; turn off the screen while we copy in data
        di
        call    StopLCD

        ;* set our update function for the next game loop
        ld hl, updateGameplay
        setWordHL currentGameState

        ; clean slate for OAM and sprites
        call    initOAM
        call initSprites

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

        call initMaterial

        ; Set our starting tilemap to the test chunk
        setWordImm MapAddress, TestChambers
        ; set our scroll position
        setWordImm TargetCameraX, 0 
        setWordImm TargetCameraY, 16

        ; initialize the viewport
        call update_Camera
        call init_Viewport

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
        ld hl, chunkBuffer
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

        ; Finally, we turn on the LCD, and set LCD control parameters (same as gameplay)
        ld      a,LCDCF_ON|LCDCF_BG8800|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ16|LCDCF_OBJON
        ld      [rLCDC],a

        ei

        ret

initMaterial:
        ld a, 0
        ld hl, materialSection
        ld bc, 5 * 4 + 3
        call mem_Set

        ; Test the materials effect by manually setting the mateirals amount
        ; ld a, 200
        ; ld [remainingMaterials], a
.unused:
        ; ld a, MATERIAL_SPRITE_BASE + 1
        ; ld bc, StaticAnimation
        ; call spawnSprite
        ; setFieldByte SPRITE_X_POS, 20
        ; setFieldByte SPRITE_Y_POS, 40
        ; setFieldByte SPRITE_TILE_BASE, $1A ; $19-1C
        ; setFieldByte SPRITE_HUD_SPACE, 1
        ret

updateMaterials:
        ld a, [materialSpawnCooldownFrames]
        add a, 0
        jp z, .trySpawnMaterial
        sub a, 1
        ld [materialSpawnCooldownFrames], a
        jp .doneSpawning
.trySpawnMaterial
        ld a, [remainingMaterials]
        add a, 0
        jp nz, .spawnMaterial
        jp .doneSpawning
.spawnMaterial
        ; Remove one material from the list of things to spawn.
        sub a, 1
        ld [remainingMaterials], a

        ; Set the cooldown so we don't spawn a ton of materials all at once.
        ld hl, materialSpawnCooldownFrames
        ld [hl], MATERIAL_SPAWN_COOLDOWN_FRAMES_INIT

        ld a, [nextMaterialIndex]
        add a, MATERIAL_SPRITE_BASE
        ld bc, StaticAnimation
        call spawnSprite

        ; Pick a material... material (tile).
        ld a, [rDIV]
        and a, %11
        add a, $19
        setFieldByte SPRITE_TILE_BASE, a
        setFieldByte SPRITE_HUD_SPACE, 1
        ld a, [nextMaterialIndex]
        ld hl, buildingMaterials
        cp 0
        jp z, .atMaterialProperties
        ld de, 4
.iterateForMaterialProperties
        add hl, de
        dec a
        jp nz, .iterateForMaterialProperties
.atMaterialProperties:
        push hl
        ; Set a random-ish horizontal starting position
        ld a, [rDIV]
        and a, %00011111

        add a, MATERIAL_BASE_X
        ld [hl+], a

        ; Pick the top or bottom of the screen
        and a, %1
        ; cp 0
        jp nz, .spawnOnBottom
.spawnOnTop
        ld a, 0
        ld [hl+], a  ; Start on top
        ld a, 0
        ld [hl+], a  ; No horizontal velocity
        ; Set random-ish vertical velocity
        ld a, [rDIV]
        and a, %00000111
        add a, MATERIAL_BASE_VELOCITY
        ld [hl], a
        jp .finishedSettingProperties
.spawnOnBottom
        ld a, 144 + 16
        ld [hl+], a  ; Start on bottom
        ld a, 0
        ld [hl+], a  ; No horizontal velocity
        ; Set random-ish vertical velocity
        ld a, [rDIV]
        and a, %00000111
        add a, MATERIAL_BASE_VELOCITY
        ; negate the velocity
        cpl
        inc a
        ld [hl], a
.finishedSettingProperties
        pop hl

        ; Increment and wrap nextMaterialIndex.
        ld a, [nextMaterialIndex]
        inc a
        ld [nextMaterialIndex], a
        sub a, 5
        jp nz, .doneSpawning
        ld [nextMaterialIndex], a
.doneSpawning
        ld e, MATERIAL_SPRITE_BASE  ; uint8_t spriteIndex[[e]] = MATERIAL_SPRITE_BASE
        ld hl, buildingMaterials    ; Material* currentMaterial[[hl]] = buildingMaterials

.updateLoop
        ld a, e
        push hl
        call getSpriteAddress       ; Sprite* currentSprite[[bc]] = &SpriteList[spriteIndex]
        pop hl

        ld a, [hl]                  ; if (160 <= currentSprite->x) {
        sub a, 160
        jp c, .stillAlive
        ld a, 0
        ld [hl+], a                 ;   currentMaterial->x = 0
        ld [hl+], a                 ;   currentMaterial->y = 0
        ld [hl+], a                 ;   currentMaterial->vx = 0
        ld [hl-], a                 ;   currentMaterial->vy = 0
        dec hl
        dec hl
        dec hl
.stillAlive                         ; }
        ld a, [hl]
        cp 0                        ; if (x == 0)  // I.e. material slot is empty
        jp nz, .draw                ;   skip the normal draw and physics update
        push hl
        setFieldByte SPRITE_Y_POS, 144 + 16  ; currentSprite->y = 144 + 16  // And put it offscreen
        pop hl
        jp .updateLoopPrepForNextIteration
.draw
        ld a, [hl]                    ; currentSprite->x = currentMaterial->x
        push hl
        setFieldByte SPRITE_X_POS, a
        pop hl
        inc hl                        ; currentSprite->y = currentMaterial->y
        ld a, [hl]
        push hl
        setFieldByte SPRITE_Y_POS, a
        pop hl
        dec hl
.runPhysics
        inc hl                        ; currentMaterial->vx += BUILDING_MATERIAL_ACCELERATION
        inc hl
        ld a, [hl]
        add a, BUILDING_MATERIAL_ACCELERATION
        ld [hl], a
        dec hl
        dec hl
        srl a                         ; currentMaterial->x += currentMaterial->vx >> 4
        srl a
        srl a
        srl a
        ld d, a
        ld a, [hl]
        add a, d
        ld [hl], a

        inc hl                        ; currentMaterial->y += currentMaterial->vy >> 2
        inc hl
        inc hl
        ld a, [hl]
        dec hl
        dec hl
        sra a
        sra a
        ld d, a
        ld a, [hl]
        add a, d
        ld [hl], a
        dec hl

.updateLoopPrepForNextIteration
        inc hl  ; ++currentMaterial
        inc hl
        inc hl
        inc hl

        ld a, e  ; ++spriteIndex
        inc a
        ld e, a

        sub a, MATERIAL_SPRITE_BASE + 5  ; if (spriteIndex == MATERIAL_SPRITE_BASE + 5)
        jp z, .done                      ;   end loop
        jp .updateLoop                   ; else repeat

;;;;;;;;;;;;;;;;;
;         ; Grab the X coordinate
;         ld a, [hl]
;         ; Check if it's off screen and kill it if it is
;         sub a, 160
;         jp c, .stillAlive
;         ld a, 0
;         ld [hl+], a
;         ld [hl+], a
;         ld [hl+], a
;         ld [hl+], a
; .stillAlive
;         ; If X is zero, it's not active, so skip it.
;         ld a, [hl]
;         cp 0
;         jp z, .advanceToNextMaterialPropertiesToUpdate
;         ; Set the sprite to match the X coordinate
;         push hl
;         setFieldByte SPRITE_X_POS, a
;         pop hl
;         inc hl
;         inc hl
;         ; Save the X coordinate in d.
;         ld d, a
;         ; Load the X velocity
;         ld a, [hl]
;         ; Apply acceleration and save the new velocity
;         add a, BUILDING_MATERIAL_ACCELERATION
;         ld [hl], a
;         srl a
;         srl a
;         srl a
;         srl a
;         ; Apply velocity and save the new X position
;         add a, d
;         dec hl
;         dec hl
;         ld [hl], a

;         inc hl
;         ; Grab the Y coordinate
;         ld a, [hl]
;         ; Set the sprite to match the Y coordinate
;         push hl
;         setFieldByte SPRITE_Y_POS, a
;         pop hl
;         inc hl
;         inc hl
;         ; Save the Y coordinate in d
;         ld d, a
;         ; Load the Y velocity
;         ld a, [hl]
;         sra a
;         sra a
;         ; Apply the velocity and save the new Y position
;         add a, d
;         dec hl
;         dec hl
;         ld [hl-], a

;         ; hl is now at the X material attribute
;         ld a, [hl]
;         ; If this material is off screen, empty out the values
;         sub a, 160
;         ; jp c, .updateLoopPrepForNextIteration
;         jp c, .advanceToNextMaterialPropertiesToUpdate
;         ld a, 0
;         ld [hl+], a
;         ld [hl+], a
;         ld [hl+], a
;         ld [hl+], a
;         jp .updateLoopPrepForNextIteration
; .advanceToNextMaterialPropertiesToUpdate
;         inc hl
;         inc hl
;         inc hl
;         inc hl
; .updateLoopPrepForNextIteration
;         ld a, e
;         sub a, MATERIAL_SPRITE_BASE + 4
;         jp z, .done

;         ld a, e
;         inc a
;         ld e, a
;         push hl
;         call getSpriteAddress
;         pop hl
;         jp .updateLoop

.done
        ret

updateChunks:
        ; determine right-most tile
        ld a, [TargetCameraX+1]
        swap a
        add a, 10
        and a, %00001111
        ld d, a ;d now contains right-most tile
        ; if this tile is different from last frame
        ld a, [lastRightmostTile]
        sub d
        jp z, .saveTile
        ; increase the score
        call increaseScore
        ; if this tile is 0
        ld a, d
        cp 0
        jp nz, .saveTile
        ; load the next chunk!
        ld a, [currentChunk]
        inc a
        ;and a, %00000011 ; for now, restrict to 4 chunks in the buffer
        ld [currentChunk], a
        ld b, 0
        ld c, a
        ld hl, chunkBuffer
        add hl, bc
        ld a, [hl] ;a now contains active chunk
        ld h, a
        ld l, 0
        ld bc, TestChambers
        add hl, bc
        setWordHL MapAddress
.saveTile
        ld a, d
        ld [lastRightmostTile], a
        ret