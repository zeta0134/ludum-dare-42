; tiny little helper functions for commonly repeated junk

;***************************************************************************
;*
;* setWord - Sets a 16-bit variable at some memory address
;*
;* arguments:
;*   \1 - address in memory
;*   \2 - data
;* clobbers:
;*   a, h, l
;***************************************************************************
setWordImm: MACRO
        ld hl, \2
        ld a, h
        ld [\1], a
        ld a, l
        ld [\1 + 1], a
        ENDM

setWordHL: MACRO
        ld a, h
        ld [\1], a
        ld a, l
        ld [\1 + 1], a
        ENDM

setWordBC: MACRO
        ld a, b
        ld [\1], a
        ld a, c
        ld [\1 + 1], a
        ENDM

setWordDE: MACRO
        ld a, d
        ld [\1], a
        ld a, e
        ld [\1 + 1], a
        ENDM

;***************************************************************************
;*
;* getWordNN - Retrieves a 16-bit variable at some memory address.
;*
;* arguments:
;*   \1 - address in memory
;* clobbers:
;*   a, h, l
;***************************************************************************
getWordHL: MACRO
        ld a, [\1]
        ld h, a
        ld a, [\1 + 1]
        ld l, a
        ENDM

getWordBC: MACRO
        ld a, [\1]
        ld b, a
        ld a, [\1 + 1]
        ld c, a
        ENDM

getWordDE: MACRO
        ld a, [\1]
        ld d, a
        ld a, [\1 + 1]
        ld e, a
        ENDM



getStackBC: MACRO
        ld hl, SP+\1
        ld a, [hl+]
        ld c, a
        ld a, [hl]
        ld b, a
        ENDM

getStackDE: MACRO
        ld hl, SP+\1
        ld a, [hl+]
        ld e, a
        ld a, [hl]
        ld d, a
        ENDM

setStackBC: MACRO
        ld hl, SP+\1
        ld a, c
        ld [hl+], a
        ld a, b
        ld [hl+], a
        ENDM

setStackDE: MACRO
        ld hl, SP+\1
        ld a, e
        ld [hl+], a
        ld a, d
        ld [hl+], a
        ENDM


