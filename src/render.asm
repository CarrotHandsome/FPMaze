INCLUDE "game.inc"
INCLUDE "hardware.inc"
SECTION "Render", rom0

;render tiles to vram based on screen draft
RenderScreen::
    ld de, wTilemapBuffer ;source
    ld hl, _SCRN0 - 16 ;destination - 16. adds 16 at beginning of loop
    call WaitNextFrame
    ld a, 16 ;16 memcopies
    ;loop through rows
    .outerLoop:        
        ld [wScratchA], a
        ld a, 16
        call Add8BitTo16Bit ;wrap vram address back around to next row
        ld b, 16
        .innerLoop:            
            ld a, [de]
            ld [hli], a
            inc de
            dec b
            ld a, b
            cp 0
            jp nz, .innerLoop      
        ld a, [wScratchA]
        dec a
        ld c, a
        and 3 ;gives a % 4. renders 4 rows per frame
        jp nz, .noNewFrame
        call WaitNextFrame
        .noNewFrame:
        ld a, c
        cp 0
        jp nz, .outerLoop   

    ret
    