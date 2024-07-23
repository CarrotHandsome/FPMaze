INCLUDE "game.inc"
INCLUDE "hardware.inc"
SECTION "Buffer", rom0
;;set up Buffer grid for processing/rendering
BufferScreen::
    ;call WaitNotVBlank
    ;get FOV values
    call GetFOV ;now wFOV tells us whether spaces 0-23 are solid

    ;point hl at ColumnToSpaces. this tells us which spaces can draw on which columns
    ld hl, ColumnToSpaces ;starts pointing at column 16 (columntospaces are in reverse order in ROM)
    ;call WaitVBlank
    ;loop through columns
    ld a, 15
    .loopColumns:
        ld [wScratchL], a
        push hl ;RenderColumn will need to use hl
        call BufferColumn
        pop hl
        ld a, SPACES_PER_COLUMN
        call Add8BitTo16Bit ;add # of spaces that could draw to a column to the address to get to the next column's address
        ld a, [wScratchL]
        sub 1        
        jp nc, .loopColumns    
        ret


;[wScratchL]=column number, hl=beginning of columnToSpaces address of the column we are drawing
BufferColumn:
    ld a, SPACES_PER_COLUMN
    ld [wScratchJ], a ;if we dont find a space that draws to this column, we draw a distant column
    .loopSpaces:
        ;get the next highest priority space that can draw to this column
        ld a, [hli]
        cp COLUMN_TO_SPACES_STOP_VALUE ;if the next space is the stop value, no spaces are drawing on this column, so draw distant
        jp z, .drawDistant
        ld d, a ;BufferSpace function will use this d
        ;get the solid status of that space
        push hl
        ld hl, wFOV
        call Add8BitTo16Bit ;add index to wFOV for specific space value
        ld a, [hl]
        pop hl
        cp 0
        jp z, .loopBack ; if the space isnt solid, go to the next space
        ;solid space - render its column. d=space index and [wScratchL]=window column
        call BufferSpace
        ret
    .loopBack:
        ld a, [wScratchJ]
        dec a
        jp z, .drawDistant
        ld [wScratchJ], a
        jp .loopSpaces
    .drawDistant:
        ;buffer a column of 7 blank tiles, with 2 dark tiles in the middle
        ld hl, wTilemapBuffer
        ld a, [wScratchL] ;column #
        call Add8BitTo16Bit
        ld a, 7 ;7 blank tiles
        .distantLoopA:
            ld b, a
            ld [hl], BLANK_TILE
            ld a, 16
            call Add8BitTo16Bit
            ld a, b
            dec a
            jp nz, .distantLoopA
        ;2 dark tiles
        ld [hl], DARK_TILE
        ld a, 16
        call Add8BitTo16Bit
        ld [hl], DARK_TILE
        ld a, 16
        call Add8BitTo16Bit
        ld a, 7 ;7 blank tiles
        .distantLoopB:
            ld b, a
            ld [hl], BLANK_TILE
            ld a, 16
            call Add8BitTo16Bit
            ld a, b
            dec a
            jp nz, .distantLoopB
        ret




;d=space index, [wScratchL]=window column. renders space column
BufferSpace:
    
    ;get the address of the space's tile definition
    ld hl, FOVSpaceOffsets ;addresses of addresses of space column tile definitions
    ld a, d ;retrieve space index
    sla a   ;and double it to iterate over 2 bytes per address
    call Add8BitTo16Bit ;hl now points to the address that stores the address we want
    ld a, [hli]
    ld e, a
    ld a, [hl]
    ld d, a
    call DEtoHL ;hl now points to the address of the start of the Space columns, 
    ;specifically the byte describing the leftmost column the space draws to
    
    ;finding the space column corresponding to the window column that we are drawing to
    ld a, [hli] ;hl now pointing at first byte of space's column data
    ld b, a
    ld a, [wScratchL]
    ;subtract space's column from window column to get a column numbered from the space's leftmost column=0
    sub b
    cp 0
    jp z, .skipPassingColumnsLoop ;if no space columns to traverse, skip the loop and 
                        ;render the first space column on the current window column
    ;traverse space's tile bytes till its "a"th column is reached
    ;hl currently pointing at first tile byte
    
    ;each loop of outer represents one column
    .passingColumnsOuterLoop:
        ld b, a ;b is number of columns left to pass
        ld d, 0 ;tiles "drawn" for the current column. compare to 16

        ;each loop represents one tile in the current column
        .passingColumnInnerLoop:
            ld a, [hli] ;a is one or more tiles, iiiiirrr index and repeats  
            and %00000111 ;isolate the repeats
            inc a ;add 1 to get total # of tiles represented by this byte
            add d ;add it back to the running sum
            ld d, a ;running sum goes in storage
            cp 16 ;has it summed to 16 yet?
            ;if we havent yet traversed a column's 16 tiles then reiterate loop
            jp nz, .passingColumnInnerLoop
        ;one fewer loop cycles to do
        ld a, b
        dec a
        jp nz, .passingColumnsOuterLoop
    .skipPassingColumnsLoop:
    ;draw this column at window column [wScratchL]
    call HLtoDE ;de now has address of first byte of space column
    ld hl, wTilemapBuffer
    ld a, [wScratchL]
    call Add8BitTo16Bit ;hl -> top of column in tile map Buffer
    ld b, 16 ;number of tiles to draw in column
    
    .byteLoop:        
        ld a, [de] ;get first byte of space column
        ld c, a
        srl c
        srl c
        srl c ;tile index
        and %00000111 ;repeats
               
        .repeatLoop: ;draws the tile at least once, repeats if repeat value is > 0
            ld [wScratchK], a ;save number of repeats 
            ld a, c ;reload tile index to draw
            ld [hl], a ;draw tile
            dec b
            ld a, 16
            call Add8BitTo16Bit ;get hl pointing at next tile down the column in vram
            ld a, [wScratchK]
            sub 1
            jp c, .loopBack ;if repeats remaining goes below 0 then go to next space tile in column
            jp .repeatLoop
        .loopBack:
            inc de
            ld a, b
            cp 0
            ret z ;finished drawing column when  b = 0
            jp .byteLoop

            

            
        

    
    
    



        