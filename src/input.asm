INCLUDE "hardware.inc"
INCLUDE "game.inc"
SECTION "Input", rom0
CheckKeys::
    call UpdateKeys
    CheckB:
        ld a, [wNewKeys]
        and a, PADF_B
        jp z, CheckA
    ExecuteB:        
    CheckA:
        ld a, [wNewKeys]
        and a, PADF_A
        jp z, CheckLeft   
    ExecuteA:
        
    CheckLeft:
        ld a, [wNewKeys]
        and a, PADF_LEFT
        jp z, CheckUp
    ExecuteLeft:
        ;rotate facing left: 0->3 1->0 2->1 3->2
        ld a, [wPlayerData]
        and 3 ;isolate last 2 bits for facing        
        jp nz, .oneToThree ;if facing is 0, set it to 4
        ld a, 4
        .oneToThree       
        dec a 
        ld [wPlayerData], a
        call RefreshWindow

    
    CheckUp:    
        ld a, [wNewKeys]
        and a, PADF_UP
        jp z, CheckRight

    ExecuteUp:
        ;get facing
        ld a, [wPlayerData]
        and 3
        ld [wScratchC], a
        jp nz, .faceRight

        ;;UP
        ld a, [wPlayerPosY]
        ;check that the space the player is moving to isnt occupied
        inc a
        ld [wScratchB], a
        ld a, [wPlayerPosX]
        ld [wScratchA], a
        call CheckForSolid
        cp BASIC_SOLID_VALUE
        jp nc, CheckRight
        ld a, [wScratchB]
        ;;load new player pos
        ld [wPlayerPosY], a
        call RefreshWindow
        jp CheckRight
        .faceRight:

        ;;RIGHT
        ld a, [wScratchC]
        cp 1
        jp nz, .faceDown
        ld a, [wPlayerPosX]
        ;check that the space the player is moving to isnt occupied
        inc a        
        ld [wScratchA], a
        ld a, [wPlayerPosY]
        ld [wScratchB], a
        call CheckForSolid
        cp BASIC_SOLID_VALUE
        jp nc, CheckRight
        ld a, [wScratchA]
        ;;load new player pos
        ld [wPlayerPosX], a
        call RefreshWindow
        jp CheckRight
        .faceDown:

        ;;DOWN
        ld a, [wScratchC]
        cp 2
        jp nz, .faceLeft
        ld a, [wPlayerPosY]
        ;check that the space the player is moving to isnt occupied
        dec a
        ld [wScratchB], a
        ld a, [wPlayerPosX]
        ld [wScratchA], a
        call CheckForSolid
        cp BASIC_SOLID_VALUE
        jp nc, CheckRight
        ld a, [wScratchB]
        ;;load new player pos
        ld [wPlayerPosY], a
        call RefreshWindow
        jp CheckRight
        .faceLeft:

        ;;LEFT
        ld a, [wPlayerPosX]
        ;check that the space the player is moving to isnt occupied
        dec a
        ld [wScratchA], a
        ld a, [wPlayerPosY]
        ld [wScratchB], a
        call CheckForSolid
        cp BASIC_SOLID_VALUE
        jp nc, CheckRight
        ld a, [wScratchA]
        ;;load new player pos
        ld [wPlayerPosX], a
        call RefreshWindow
        
    CheckRight:
        ld a, [wNewKeys]
        and a, PADF_RIGHT
        jp z, CheckDown
    ExecuteRight:   
        ;rotate facing right: 0->1 1->2 2->3 3->0
        ld a, [wPlayerData]
        and 3 ;isolate last 2 bits for facing        
        inc a
        cp 4 ;if addine 1 to facing makes 4, set it to 0
        jp nz, .zeroToTwo
        ld a, 0
        .zeroToTwo:
        ld [wPlayerData], a
        call RefreshWindow 
    
    CheckDown:
        ld a, [wNewKeys]
        and a, PADF_DOWN
        ret z
    ExecuteDown:
    ret

UpdateKeys::
    ; Poll half the controller
    ld a, P1F_GET_BTN
    call .onenibble
    ld b, a ; B7-4 = 1; B3-0 = unpressed buttons

    ; Poll the other half
    ld a, P1F_GET_DPAD
    call .onenibble
    swap a ; A3-0 = unpressed directions; A7-4 = 1
    xor a, b ; A = pressed buttons + directions
    ld b, a ; B = pressed buttons + directions

    ; And release the controller
    ld a, P1F_GET_NONE
    ldh [rP1], a

    ; Combine with previous wCurKeys to make wNewKeys
    ld a, [wCurKeys]
    xor a, b ; A = keys that changed state
    and a, b ; A = keys that changed to pressed
    ld [wNewKeys], a
    ld a, b
    ld [wCurKeys], a
    ret

.onenibble
    ldh [rP1], a ; switch the key matrix
    call .knownret ; burn 10 cycles calling a known ret
    ldh a, [rP1] ; ignore value while waiting for the key matrix to settle
    ldh a, [rP1]
    ldh a, [rP1] ; this read counts
    or a, $F0 ; A7-4 = 1; A3-0 = unpressed keys
.knownret
    ret



