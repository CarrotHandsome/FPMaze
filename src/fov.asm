INCLUDE "game.inc"
INCLUDE "hardware.inc"

SECTION "FOV", rom0

;;;;read playerPos and facing variables and turn them into FOV readable by buffer generator
;;;;
GetFOV::
ld a, [wPlayerData]
and %00000011 ;isolate facing
jp nz, .right
ld hl, SequenceD
push hl
ld hl, SequenceA
push hl
ld hl, SequenceC
push hl
ld hl, SequenceA
push hl
ld hl, SequenceY
push hl
ld hl, SequenceX
push hl
;call SequenceToFOV
jp .endSequence
.right:
cp 1
jp nz, .down
ld hl, SequenceA
push hl
ld hl, SequenceC
push hl
ld hl, SequenceA
push hl
ld hl, SequenceD
push hl
ld hl, SequenceX
push hl
ld hl, SequenceY
push hl
;call SequenceToFOV
jp .endSequence
.down:
cp 2
jp nz, .left
ld hl, SequenceC
push hl
ld hl, SequenceB
push hl
ld hl, SequenceD
push hl
ld hl, SequenceB
push hl
ld hl, SequenceY
push hl
ld hl, SequenceZ
push hl
;call SequenceToFOV
jp .endSequence
.left:
ld hl, SequenceB
push hl
ld hl, SequenceD
push hl
ld hl, SequenceB
push hl
ld hl, SequenceC
push hl
ld hl, SequenceZ
push hl
ld hl, SequenceY
push hl
;call SequenceToFOV
.endSequence:
;pop the sequences to ram
ld hl, wSequences
pop de
ld [hl], d
inc hl
ld [hl], e
inc hl
pop de
ld [hl], d
inc hl
ld [hl], e
inc hl
pop de
ld [hl], d
inc hl
ld [hl], e
inc hl
pop de
ld [hl], d
inc hl
ld [hl], e
inc hl
pop de
ld [hl], d
inc hl
ld [hl], e
inc hl
pop de
ld [hl], d
inc hl
ld [hl], e
inc hl   
call SequencesToFOV
ret

;wSequences has the addresses of the sequences we want to do, starting with the first 4 
;being X Y or Z, the following 2 being A, B, C, or D, and the last 2 also being A B C or D
SequencesToFOV:
    
    ld a, 0
    ld [wScratchL], a ;which index of fov are we in
    ld hl, wSequences 
    .outerLoop:           
        ld a, [hli] ;load the first half of the next y sequence address
        ld d, a
        ld a, [hli] ;2nd half
        ld e, a
        call ScratchDE ;scratchDE points to address of sequence of adds to a base y value
        ld a, [hli] ;load the first half of the next x sequence address
        ld d, a
        ld a, [hli] ;2nd half
        ld e, a
        call ScratchDE2 ; scratchDE2 points to address of sequence of adds to a base x value

        ld c, SEQUENCE_LENGTH
        ; ld a, [wScratchL]
        ; inc a
        ; ld [wScratchL], a ;save fov index counter for AddValueToFOV
        ;if we have filled 24 FOV spaces then end the function
        
        .innerLoop:   
            call UnScratchDE      
            ld a, [de] ;next y add of sequence
            ld [wScratchB], a
            inc de
            call ScratchDE
            call UnScratchDE2
            ld a, [de] ;next x add
            ld [wScratchA], a
            inc de
            call ScratchDE2            
            ;if the next sequence add = 255 then end the sequence and return to the outer loop. this is padding for the first 4 sequences
            cp 255
            jp z, .outerLoop  
            push bc         
            push de
            push hl
            ;call WaitNextFrame
            call PositionToFOVValue
            call AddValueToFOV
            pop hl
            pop de
            pop bc
            ld a, [wScratchL]
            inc a
            cp FOV_LENGTH
            ret z
            ld [wScratchL], a            
            dec c ;sequence length counter, sequence is finished when 0
            jp z, .outerLoop
            inc de ;point to next add in sequence
            jp .innerLoop

;a=value, [wScratchL]=fov index
AddValueToFOV:
    ld hl, wFOV
    ld c, a
    ld a, [wScratchL]
    ;dec a ;account for this counter being shifted up by one
    call Add8BitTo16Bit
    ld a, c
    ld [hl], a
    ret    

;takes [wScratchA]=addx, [wScratchB]=addy, returns a=value of that space. returns $FF if out of bounds
;use "[wPlayerData] & 3" to get facing and XRelSeq/YRelSeq 
PositionToFOVValue:
    ;need addx + ([wPlayerPosX] - [XRelSeq + [wPlayerData] & 3])
    ;get [wPlayerData] & 3

    ld a, [wPlayerData]
    and 3
    ;a=[wPlayerData] & 3
    ;get [XRelSeq + ... ]
    ld hl, XRelSeq
    call Add8BitTo16Bit
    ld a, [hl] ;a=[XRelSeq + ... ] , the offset we are subtracting from playerposx
    ld b, a
    ld a, [wPlayerPosX]
    sub b
    ld b, a
    ld a, [wScratchA]
    add b ;a=addx + ([wPlayerPosX] - [XRelSeq + [wPlayerData] & 3])

    ld [wScratchA], a

    ;Version for Y    
    ld a, [wPlayerData]
    and 3
    ld hl, YRelSeq
    call Add8BitTo16Bit
    ld a, [hl] 
    ld b, a
    ld a, [wPlayerPosY]
    sub b
    ld b, a
    ld a, [wScratchB]
    add b 
    ld [wScratchB], a

    ;get the value of the map space at coordinates (scratchA, scratchB)
    call CheckForSolid
    ret

;[scratchA], [wscratchB]=x, y of space being checked
CheckForSolid::
    ld a, [wScratchB]
    ld e, a ;ypos
    ld a, [wScratchA]
    ld d, a ;xpos
    ;check if xpos is < 0 and OOB if so
    ;> 251? result of underflow (0 - 4 = 252)
    cp 251
    jp nc, .OOB
    ;check if xpos is < 0
    ld a, e
    cp 251
    jp nc, .OOB

    ;find the memory location of the space in the map
    ld hl, DungeonSize
    ld a, [hli] ;get dungeon height
    cp e ;compare to posy
    jp c, .OOB ;if posy > dungeon height then OOB
    ld b, a ;b holds height
    ld a, [hli] ;get dungeon width
    cp d ;compare to xpos
    jp c, .OOB
    ld c, a ;c holds width
    ld a, b ;load height
    sub e ;subtract ypos to get number of rows to traverse
    ;dec a ;traverse one fewer row than that. a will always be at least 1 here since ypos is 0-based. 
    ;ie a ypos of 09 is at the top of a 10 height dungeon, so a space at the top will see 10 - 9 = 1 
    ld b, a
    ld a, 0 ;current position in 1d map
    .loop:
        dec b
        jp z, .endLoop
        add c ;add width a number of times = to rows to traverse - 1
        jp .loop
    .endLoop:
        add d
        call Add8BitTo16Bit
        ld a, [hl]
        ret
    .OOB:
        ld a, OUT_OF_BOUNDS_FOV_VALUE
        ret