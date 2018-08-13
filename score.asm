        PUSHS           
        SECTION "Scores WRAM",WRAM0
score: DS 3
        POPS

initScore:
        ld hl, score
        ld a, 0
        ld [hl+], a
        ld [hl+], a
        ld [hl], a
        ld hl, shadowOAM + 34 * 4
        ld d, 6
        ld a, 63
.loop
        ld [hl], 20 ; y-coordinate 
        inc hl
        ld [hl+], a ; x-coordinate 
        ld [hl], $50 ; tile-index
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
        add a, $50
        ld [hl], a
        ; advance to next digit tile attribute
        inc hl
        inc hl
        inc hl
        inc hl
        ld a, b
        ; calculate and write tile
        sla a
        add a, $50
        ld [hl], a
        ; advance to next digit tile attribute
        inc hl
        inc hl
        inc hl
        inc hl
        ret