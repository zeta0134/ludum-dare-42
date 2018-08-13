
        PUSHS           
        SECTION "Gameplay WRAM",WRAM0
chunkMarkers: DS 4
lastSpawnTile: DS 1
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

spawnCounter: DS 1
deathChunk: DS 1
lastChunkExitType: DS 1
cameraShakeTimer: DS 1
cameraShakeIntensity: DS 1
chunksToGenerate: DS 1
chunkCooldownTimer: DS 1
        POPS

CAMERA_SHAKE_DISABLED EQU %00000000
CAMERA_SHAKE_BUMPY EQU %00000001
CAMERA_SHAKE_TURBULANT EQU %00000011
CAMERA_SHAKE_INTENSE EQU %00000111
CAMERA_SHAKE_APOCALYPTIC EQU %00001111

updateGameplay:
        call    updateChunks
        call    update_Camera
        call    spawnObjects
        call    updateSprites
        call    displayScore
        call    updateMaterials
        call    updateCrates
        call    updateWrench
        call    processCameraShake
        call    processChunkGeneration
        call    updateWarningIndicators
        call    updatePlayer ;note: player is last on purpose.
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
        call initCrates
        call initWrench
        call initScore
        call initWarningIndicators

        call initMaterial

        ; Set our starting tilemap to the test chunk
        setWordImm MapAddress, TestChambers + 256
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

        ; initialize the chunk buffer with all death planes
        ld b, 0
        ld hl, chunkBuffer
.chunkInitLoop
        ld [hl], 0
        inc hl
        inc b
        jp nz, .chunkInitLoop

        ; starting area gets some lovely plains
        ld a, 1
        ld [chunkBuffer+0], a
        ld [chunkBuffer+1], a

        ; We only have two chunks to start with, so set the death barrier there:
        ld a, 2
        ld [deathChunk], a
        ; The exit type for the default chunk is important, as it determines what
        ; kinds of chunks we'll generate ahead of it
        ld a, "A"
        ld [lastChunkExitType], a
        ld a, 0
        ld [chunksToGenerate], a
        ld [chunkCooldownTimer], a

        ; sensible camera shake states, please
        ld a, 0
        ld [cameraShakeIntensity], a
        ld [cameraShakeTimer], a

        ; generate a few chunks to get the player started
        call generateNewChunk
        call generateNewChunk
        call generateNewChunk
        call generateNewChunk
        call generateNewChunk
        call generateNewChunk
        call generateNewChunk
        call generateNewChunk

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
        ld a, 144
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
        ; show chunk building progress visually with a bit of screen shake
        ld a, CAMERA_SHAKE_TURBULANT
        ld [cameraShakeIntensity], a
        ld a, 8
        ld [cameraShakeTimer], a
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

spawnTable:
        DW spawnCrate, spawnWrench

spawnObjects:
        ld a, [lastSpawnTile]
        ld b, a
        ld a, [lastRightmostTile]
        cp b
        jp nz, .tileChanged
        ret
.tileChanged
        ld [lastSpawnTile], a
        ld a, [rDIV]
        and a, %00000001
        sla a
        ld hl, spawnTable
        ld d, 0
        ld e, a
        add hl, de ;hl now contains pointer to selected spawning function in memory
        ld a, [hl+]
        ld b, [hl]
        ld h, b
        ld l, a
        jp hl
        ; implied ret

processChunkGeneration:
        ld a, [chunkCooldownTimer]
        cp 0
        jp z, .checkGeneration
        dec a
        ld [chunkCooldownTimer], a
        ret
.checkGeneration
        ld a, [chunksToGenerate]
        cp 0
        jp nz, .generateOneChunk
        ret
.generateOneChunk
        call generateNewChunk
        ; cooldown timer is primarily for artistic effect
        ld a, 30
        ld [chunkCooldownTimer], a
        ; throw some materials across the screen to show the building
        ld a, 1
        ld [remainingMaterials], a
        ; decrement the counter; we generated the chunk
        ld hl, chunksToGenerate
        dec [hl]
        ; that's enough of that
        ret

generateNewChunk:
        ; grab a random value
        ld a, [rDIV]
        ; mask it based on the length of the chunk attribute table
        and a, CHUNK_MASK
        ; starting with that item in the table...
        ld d, a
.loop
        ld bc, chunkAttributes
        ld a, d
        sla a
        sla a ; x4
        inc a ; skip to "entrance" field
        ld h, 0
        ld l, a
        add hl, bc ;now pointing to entrance field of this chunk type in chunkAttributes table
        ; if this entrance type matches our last exit
        ld b, [hl]
        ld a, [lastChunkExitType]
        cp b
        jp z, .foundValidChunk
        ; otherwise, iterate forward to the next item in the table,
        ; and continue until we find a valid exit.
        ld a, d
        inc a
        and a, CHUNK_MASK
        ld d, a
        jp .loop

.foundValidChunk
        ; hl is presently pointing at the valid chunk's entrance
        dec hl ; now pointing at chunk index
        ld d, [hl] ;d = next chunk
        inc hl
        inc hl
        ld e, [hl] ;e = next chunk exit type
        ld hl, chunkBuffer
        ld b, 0
        ld a, [deathChunk]
        ld c, a
        add hl, bc ; hl = chunkBuffer[deathChunk]
        ld [hl], d ; new chunk written
        inc a
        ld [deathChunk], a ; move the death chunk forward
        ; now we need to make sure the next chunk in sequence is a 0, so
        ; that we always have a death plane ahead of us
        ld hl, chunkBuffer
        ld c, a
        add hl, bc ;hl = chunkBuffer[new deathChunk]
        ld a, 0
        ld [hl], a
        ; finally, make sure the last exit type is updated to reflect the next chunk type we need
        ld a, e
        ld [lastChunkExitType], a
        ; and done!
        ret

processCameraShake:
        ld a, [cameraShakeTimer]
        cp 0
        jp nz, .getShaking
        ld hl, TargetCameraY + 1
        ld a, 16
        ld [hl], a
        ret
.getShaking
        ld a, [rDIV]
        ld b, a
        ld a, [cameraShakeIntensity]
        and a, b
        add a, 16 ; base + random
        ld b, a ;stash
        ld a, [cameraShakeIntensity]
        sra a ; half the intensity
        ld c, a
        ld a, b
        sub a, c ; a = base + random - (intensity / 2)
        ld hl, TargetCameraY + 1
        ld [hl], a
        ld hl, cameraShakeTimer
        dec [hl]
        ret