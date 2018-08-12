KEY_START EQU $80
KEY_SELECT EQU $40
KEY_B EQU $20
KEY_A EQU $10
KEY_DOWN EQU $08
KEY_UP EQU $04
KEY_LEFT EQU $02
KEY_RIGHT EQU $01

        PUSHS           
        SECTION "Input WRAM",WRAM0
keysOld: DS 1
keysHeld: DS 1
keysDown: DS 1
keysUp: DS 1
        POPS

pollInput:
        ld a, %00010000
        ld [rP1], a ; select direction keys
        ; several dummy reads
        ld a, [rP1]
        ld a, [rP1]
        ld a, [rP1]
        ; real read
        ld a, [rP1]
        xor a, %11111111
        and a, %00001111
        swap a
        ld b, a
        ld a, %00100000
        ld [rP1], a ; select button keys
        ; several dummy reads
        ld a, [rP1]
        ld a, [rP1]
        ld a, [rP1]
        ; real read
        ld a, [rP1]
        xor a, %11111111
        and a, %00001111
        or a, b
        ld [keysHeld], a
        ld b, a
        ; b now contains current button presses
        ld a, [keysOld]
        xor %11111111 ; if not keysOld
        and b         ; and keysHeld
        ld [keysDown], a ; then the key was just pressed
        ld a, [keysOld]
        ld b, a
        ld a, [keysHeld]
        xor %11111111 ; if not keysHeld
        and b         ; ... but keysOld
        ld [keysUp], a ; then the key was just released
        ld a, [keysHeld]
        ld [keysOld], a
        ret