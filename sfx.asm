        INCLUDE "vendor/gbhw.inc"
        INCLUDE "sound_defines.inc"

        PUSHS           
        SECTION "SFX WRAM",WRAM0

Channel1SfxPlaying:    DS 1
Channel1RowsRemaining: DS 1
Channel1RowLength:     DS 1
Channel1RowDelayCounter: DS 1
Channel1RowsPointer:   DS 2

Channel4SfxPlaying:    DS 1
Channel4RowsRemaining: DS 1
Channel4RowLength:     DS 1
Channel4RowDelayCounter: DS 1
Channel4RowsPointer:   DS 2

        POPS

        PUSHS           
        SECTION "SFX Data",ROMX

        INCLUDE "pitch_table.asm"

JumpSfxData:
        ;  sweep, duty+length, volume, note
        DB $37,   $C0,         $F2,    D5

JumpSfx:
        ;  channel, row count, row length
        DB 1,       1,         20
        DW JumpSfxData

WrenchSfxData:
        ;  sweep, duty+length, volume, note
        DB $00,   $C0,         $F2,    D5
        DB $00,   $C0,         $F2,    G5
        DB $00,   $C0,         $F2,    D6
        DB $00,   $C0,         $F2,    G5
        DB $00,   $C0,         $F2,    D6
        DB $00,   $C0,         $F2,    G6
        DB $00,   $C0,         $F2,    D6
        DB $00,   $C0,         $F2,    G6
        DB $00,   $C0,         $F2,    D7

WrenchSfx:
        ;  channel, row count, row length
        DB 1,       9,         2
        DW WrenchSfxData

KathunkSfxData:
        ;  _____, length, volume, poly_params
        DB $00,   $00,    $F0,    $53
        DB $00,   $00,    $D0,    $53
        DB $00,   $00,    $B0,    $54
        DB $00,   $00,    $90,    $55
        DB $00,   $00,    $F0,    $44
        DB $00,   $00,    $E0,    $44
        DB $00,   $00,    $D0,    $45
        DB $00,   $00,    $C0,    $45
        DB $00,   $00,    $B0,    $46
        DB $00,   $00,    $A0,    $46
        DB $00,   $00,    $90,    $47
        DB $00,   $00,    $80,    $47

KathunkSfx:
        ;  channel, row count, row length
        DB 4,       12,         2
        DW KathunkSfxData

CeilingBonkSfxData:
        ;  sweep, duty+length, volume, note
        DB $2B,   $C0,         $F2,    D5

CeilingBonkSfx:
        ;  channel, row count, row length
        DB 1,       1,         8
        DW CeilingBonkSfxData

CrateKnockSfxData:
        ;  _____, length, volume, poly_params
        DB $00,   $00,    $F0,    $33
        DB $00,   $00,    $80,    $33
        DB $00,   $00,    $00,    $00
        DB $00,   $00,    $F0,    $44
        DB $00,   $00,    $80,    $44
        DB $00,   $00,    $00,    $00
        DB $00,   $00,    $F0,    $54
        DB $00,   $00,    $80,    $54
        DB $00,   $00,    $00,    $00
        DB $00,   $00,    $F0,    $64
        DB $00,   $00,    $80,    $64
        DB $00,   $00,    $00,    $00

CrateKnockSfx:
        ;  channel, row count, row length
        DB 4,       12,         2
        DW CrateKnockSfxData

ExplosionSfxData:
        ;  _____, length, volume, poly_params
        DB $00,   $00,    $80,    $54
        DB $00,   $00,    $70,    $64

ExplosionSfx:
        ;  channel, row count, row length
        DB 4,       2,         5
        DW ExplosionSfxData

        POPS

        PUSHS           
        SECTION "SFX Code",ROM0

UpdateChannel1:
        ld a, [Channel1SfxPlaying]      ; Make sure we're actually enabled before continuing
        cp a, 0
        jp z, .done
        ld a, [Channel1RowDelayCounter] ; Decrement the row counter
        dec a
        ld [Channel1RowDelayCounter], a
        jp nz, .done                    ; If we're not zero yet, skip any further action this round
        ld a, [Channel1RowLength]       ; reset the row counter
        ld [Channel1RowDelayCounter], a
        ld a, [Channel1RowsRemaining]
        cp a, 0                         ; If there aren't any more rows to play,
        jp z, .disableChannel           ; disable the channel
        dec a
        ld [Channel1RowsRemaining], a
.updateRegisters:
        getWordHL Channel1RowsPointer
        ld a, [hl+]
        ld [rNR10], a
        ld a, [hl+]
        ld [rNR11], a
        ld a, [hl+]
        ld [rNR12], a
.updateFrequency:
        ld c, [hl]
        inc hl
        ; write out the row pointer, since we're done with it at this point
        setWordHL Channel1RowsPointer
        ld a, 0
        ld b, a
        ld hl, FrequencyTable
        add hl, bc
        ld a, [hl+]
        ld [rNR13], a ; Write the low part of the frequency
        ld a, [hl+]
        or a, $80 ; Trigger
        ld [rNR14], a
        jp .done
.disableChannel:
        ld a, 0
        ld [Channel1SfxPlaying], a
        ; play a silent note to turn off the channel
        ld a, 0
        ld [rNR12], a
        ld a, $80
        ld [rNR14], a
.done:
        ret

UpdateChannel4:
        ld a, [Channel4SfxPlaying]      ; Make sure we're actually enabled before continuing
        cp a, 0
        jp z, .done
        ld a, [Channel4RowDelayCounter] ; Decrement the row counter
        dec a
        ld [Channel4RowDelayCounter], a
        jp nz, .done                    ; If we're not zero yet, skip any further action this round
        ld a, [Channel4RowLength]       ; reset the row counter
        ld [Channel4RowDelayCounter], a
        ld a, [Channel4RowsRemaining]
        cp a, 0                         ; If there aren't any more rows to play,
        jp z, .disableChannel           ; disable the channel
        dec a
        ld [Channel4RowsRemaining], a
.updateRegisters:
        getWordHL Channel4RowsPointer
        ld a, [hl+]
        ld a, [hl+]
        ld [rAUD4LEN], a
        ld a, [hl+]
        ld [rAUD4ENV], a
.updateFrequency:
        ld c, [hl]
        inc hl
        ; write out the row pointer, since we're done with it at this point
        setWordHL Channel4RowsPointer
        ld a, c
        ld [rAUD4POLY], a ; Write the polynomial parameters
        ld a, [hl+]
        or a, $80 ; Trigger
        ld [rAUD4GO], a
        jp .done
.disableChannel:
        ld a, 0
        ld [Channel4SfxPlaying], a
        ; play a silent note to turn off the channel
        ld a, 0
        ld [rAUD4ENV], a
        ld a, $80
        ld [rAUD4GO], a
.done:
        ret

;***************************************************************************
;*
;* QueueSound - Queues up the provided sound effect for playing immediately.
;*   Replaces any currently playing sound on the channel.
;* input:
;*   hl: sound queue data
;* clobbers:
;*   bc
;***************************************************************************
queueSound:
        ld a, [hl+]
        cp 1
        jp z, .queueChannel1        
        cp 4
        jp z, .queueChannel4
        jp .done
.queueChannel1:
        ld a, [hl+]
        ld [Channel1RowsRemaining], a
        ld a, [hl+]
        ld [Channel1RowLength], a
        ld a, [hl+]
        ld c, a
        ld a, [hl+]
        ld b, a
        setWordBC Channel1RowsPointer
        ld a, 1
        ld [Channel1SfxPlaying], a
        ld [Channel1RowDelayCounter], a
        jp .done
.queueChannel4:
        ld a, [hl+]
        ld [Channel4RowsRemaining], a
        ld a, [hl+]
        ld [Channel4RowLength], a
        ld a, [hl+]
        ld c, a
        ld a, [hl+]
        ld b, a
        setWordBC Channel4RowsPointer
        ld a, 1
        ld [Channel4SfxPlaying], a
        ld [Channel4RowDelayCounter], a
.done:
        ret

initSfx:
        ld a, 0
        ld [Channel1SfxPlaying], a
        ld [Channel4SfxPlaying], a
        ret

updateBGMChannels:
        ld a, [Channel4SfxPlaying]
        ld b, a
        sla b
        sla b
        sla b
        ld a, [Channel1SfxPlaying]
        or a, b ; a now contains the following bitmask for playing SFX: 00004321
        xor a, $0F ; invert this mask to determine what BGM channels should be enabled
        call gbt_enable_channels
        ret

updateSfx:
        call UpdateChannel1
        call UpdateChannel4
        ret

        POPS