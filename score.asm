        PUSHS           
        SECTION "Scores WRAM",WRAM0
score: DS 3
        POPS

; a -> X position
initScore:
        ld b, a

        ld hl, score
        ld a, 0
        ld [hl+], a
        ld [hl+], a
        ld [hl], a
        ld hl, shadowOAM + 34 * 4
        ld d, 6
        ld a, b
.loop
        ld [hl], 20 ; y-coordinate 
        inc hl
        ld [hl+], a ; x-coordinate 
        ld [hl], $44 ; tile-index
        inc hl
        inc hl ; skip over attributes
        add a, 7
        dec d
        jp nz, .loop
        ret

increaseScore:
        ; If we're in the death chunk, don't increase the score. (Otherwise the cutscene)
        ; that plays gives us free points
        ld a, [SpriteList + SPRITE_CHUNK]
        ld b, a
        ld a, [deathChunk];
        cp b
        jp nz, .proceed
        ret
.proceed
        ld hl, score + 2
        ld a, [hl]
        add a, 1
        daa
        ld [hl-], a
        jp c, .hundreds
        ret
.hundreds
        ld a, [hl]
        add a, 1
        daa
        ld [hl-], a
        jp c, .tenThousands
        ret
.tenThousands
        ld a, [hl]
        add a, 1
        daa
        ld [hl], a
        ret

displayScore:
        ld hl, shadowOAM + 34 * 4 + 2
        ld a, [score]
        call displayScoreByte
        ld a, [score + 1]
        call displayScoreByte
        ld a, [score + 2]
        call displayScoreByte
        ret

; hl - address of first digit's tile attribute
; a - BCD value to display
; -> hl - address of third digit's tile attribute
; -> a, b, c - trashed
displayScoreByte:
        ; save left digit in a, right digit in b
        ld c, a
        and a, %00001111
        ld b, a
        ld a, c
        swap a
        and a, %00001111

        ; calculate and write tile
        sla a
        add a, $44
        ld [hl], a
        ; advance to next digit tile attribute
        inc hl
        inc hl
        inc hl
        inc hl
        ld a, b
        ; calculate and write tile
        sla a
        add a, $44
        ld [hl], a
        ; advance to next digit tile attribute
        inc hl
        inc hl
        inc hl
        inc hl
        ret

updateHighScore:
        ; ld a, [highScore + 0]
        ; ld b, a
        ; ld a, [score + 0]
        ; sub a, b
        ; jp nc, .setHighScore

        ; ld a, [highScore + 1]
        ; ld b, a
        ; ld a, [score + 1]
        ; sub a, b
        ; jp c, .setHighScore

        ; ld a, [highScore + 2]
        ; ld b, a
        ; ld a, [score + 2]
        ; sub a, b
        ; jp nc, .setHighScore

        ld a, [highScore + 2]
        ld b, a
        ld a, [score + 2]
        sub a, b
        ld a, [highScore + 1]
        ld b, a
        ld a, [score + 1]
        sbc a, b
        ld a, [highScore + 0]
        ld b, a
        ld a, [score + 0]
        sbc a, b
        jp nc, .setHighScore
        ret
.setHighScore
        ld a, [score + 0]
        ld [highScore + 0], a
        ld a, [score + 1]
        ld [highScore + 1], a
        ld a, [score + 2]
        ld [highScore + 2], a
        ret