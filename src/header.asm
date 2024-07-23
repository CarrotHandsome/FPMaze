
INCLUDE "hardware.inc"	
INCLUDE "game.inc"

SECTION "Header", ROM0[$100]

	; This is your ROM's entry point
	; You have 4 bytes of code to do... something
	di
	jp EntryPoint

	; Make sure to allocate some space for the header, so no important
	; code gets put there and later overwritten by RGBFIX.
	; RGBFIX is designed to operate over a zero-filled header, so make
	; sure to put zeros regardless of the padding value. (This feature
	; was introduced in RGBDS 0.4.0, but the -MG etc flags were also
	; introduced in that version.)
	ds $150 - @, 0

SECTION "Entry point", ROM0

EntryPoint:
	;do not turn off LCD outside VBlank
call WaitVBlank



;turn LCD off
ld a, 0
ld [rLCDC], a

;copy tile data
ld de, Tiles
ld hl, $9000
ld bc, TilesEnd - Tiles
call Memcopy

; ;copy tilemap
; ld de, Tilemap
; ld hl, $9800
; ld bc, TilemapEnd - Tilemap
; call Memcopy

ld a, 0
ld b, 160
ld hl, _OAMRAM
ClearOam:
ld [hli], a
dec b
jp nz, ClearOam

;set object attributes
ld hl, _OAMRAM
ld a, 128 + 16
ld [hli], a
ld a, 16 + 8
ld [hli], a
ld a, 0
ld [hli], a
ld [hl], a

;turn lcd on
ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
ld [rLCDC], a

;during first blank frame, initialize display registers
ld a, %11100100
ld [rBGP], a
ld a, %11100100
ld [rOBP0], a

;initialize player
ld a, 4
ld [wPlayerPosY], a
ld a, 4
ld [wPlayerPosX], a
ld a, 0
ld [wPlayerData], a

call ClearScreen
call Frame
;call WaitNextFrame
call RefreshWindow

Main:
	call WaitNextFrame
	call CheckKeys
jp Main