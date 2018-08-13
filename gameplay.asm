
        PUSHS           
        SECTION "Gameplay WRAM",WRAM0
chunkMarkers: DS 4
lastSpawnTile: DS 1
lastRightmostTile: DS 1
currentChunk: DS 1
chunkBuffer: DS 256
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
        call    updateCrates
        call    updateWrench
        call    processCameraShake
        call    processChunkGeneration
        call    updateWarningIndicators
        call    updatePlayer ;note: player is last on purpose.
        ret

initGameplay:
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
        ; show chunk building progress visually with a bit of screen shake
        ld a, CAMERA_SHAKE_TURBULANT
        ld [cameraShakeIntensity], a
        ld a, 8
        ld [cameraShakeTimer], a
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