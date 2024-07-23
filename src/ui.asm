INCLUDE "game.inc"
INCLUDE "hardware.inc"

SECTION "UI", rom0
Frame::
    ld hl, _SCRN0
    ld a, 16
    call Add8BitTo16Bit
    call WaitNextFrame
    ld a, 16
    .sideLoop:
        ld b, a
        ld a, 0
        ld [hl], a
        ld a, 32
        call Add8BitTo16Bit
        ld a, b
        dec a
        jp nz, .sideLoop
    
    ld de, _SCRN0
    ld hl, 32
    call SL16Bit
    call SL16Bit
    call SL16Bit
    call SL16Bit
    call Add16BitTo16Bit
    ld a, 16
    .bottomLoop:
        ld b, a
        ld a, 1
        ld [hli], a
        ld a, b
        dec a
        jp nz, .bottomLoop
    ret

ClearScreen::
    ld hl, _SCRN0
    ld b, 18 ;# of rows to clear
    call WaitNextFrame
    .yLoop:        
        ld c, 20 ;# columns to clear
        call WaitNextFrame
        .xLoop:
            ld [hl], BLANK_TILE
            inc hl
            dec c
            ld a, c
            cp 0
            jp nz, .xLoop
        ld a, 12
        call Add8BitTo16Bit
        dec b
        ld a, b
        cp 0        
        jp nz, .yLoop
    ret
RefreshWindow::
    call BufferScreen
    call RenderScreen
    ret

        


