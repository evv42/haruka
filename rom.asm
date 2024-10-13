; defines

;output port on io bus (74161)
SDA = $40
SCL = $80
;scl at bit 7, sda at bit 6
BZ = $10
;beeper

P0 = $E000;lower byte must be zero
P1 = $F000

  .org $0000

  .macro outp
    out (0), a
  .endmacro
  
  .macro startiic
    ld a, SCL
    outp
    xor a
    outp ;port=0000
  .endmacro
    
  .macro stopiic
    ld a, SCL
    outp
    or SDA
    outp ;port=1100
  .endmacro

  .macro writeiic
  .inline
      ld l, a
      ld b, $09
      xor a;port=0000
    .loop:
      dec b
      jr z, .ack
      rlc l
      jr nc, .zero
    .one:
      or SDA ;set sda
      outp
      or SCL ;set scl
      outp
      xor SCL ;reset scl
      outp
      xor SDA ;reset SDA
      outp
      jr .loop
    .zero:
      or SCL ;set scl
      outp
      xor SCL ;reset scl
      outp
      jr .loop
    .ack:
      or SCL ;set scl
      outp
      xor SCL ;reset scl
      outp
  .einline
  .endmacro

  .macro ld_d_hl_andone 
    bit 0, (hl)
    jr z, .end
    exx
    inc d
    exx
    .end:
  .endmacro


  .macro writegameiic ;write 8 vertical pixels to the SSD1306
    .inline
    xor a
    .loop:
          ld de, $0400
          add hl, de
          ld de, $0080
          ld b, $09
          jr .loopii
          .loopiis:
              and a; clc
              sbc hl, de
          .loopii:
              dec b
              jr z, .ack
              bit 0,(hl)
              jr z, .zero
          .one:
              or SDA ;set sda
              outp
              or SCL ;set scl
              outp
              xor SCL ;reset scl
              outp
              xor SDA ;reset SDA
              outp
              jr .loopiis
          .zero:
              or SCL ;set scl
              outp
              xor SCL ;reset scl
              outp
              jr .loopiis
          .ack:
              or SCL ;set scl
              outp
              xor SCL ;reset scl
              outp
        inc hl
        dec c
        jr nz, .loop
    .einline
  .endmacro

reset:
  
  stopiic
wait_and_init_memory:; puts zeros in the whole memory address space
    ld c, $04
    .loop:
      dec de
      xor a
      ld (de), a
      ld a,d
      or e
      jr nz, .loop
    dec de
    dec c
    jr nz, .loop

init_screen:
  ld c, $15
  ld de, screeninit2
  startiic
  .loop:
    ld a, (de)
    writeiic
    inc de
    dec c
    jp nz, .loop

pc98_pipo:
  ;a and c are expected to be zero
  ld sp, note0_vec
  ld d, $02 ;duration = $200
  ld h, $36 ;~2000Hz
  jp beep
n0_done:

  ;sp points to note0_vec
  inc d ;duration = $100
  ld h, $6E ;~1000Hz
  jp beep

  .org $0066;102
nmi:
jump_ext_cart_if_pres:
  ld a, ($2000)
  cp $5A
  jp z, $2001
  
vmu_death:
  ld sp, note1_vec ;no need for another vector
  ld d, $08;duration
  ld c, d
  ld h, $27;pitch
  jp beep
  jp init_screen

n1_done: ;this way, the nmi routine is skipped for free

mainloop:
; d: neighbour count
; bc: first array pointer
; bc': second array pointer
; hl': generations before fillmem (ttl)

ttl_reinit:

  
fillmem:
  ld hl, $8740;rng seed
  exx ;np
  ld hl, P0
  ld d, l ;l must be zero from P0
  ld c, $10
  .loop:
    ;rng func
    exx ;p
      add hl, hl
      sbc a,a
      and %00101101
      xor l
      ld l, a
      ld a, r
      add a, h
    exx ;np
    
    
    ; a is a pseudo-random number
    
    ld e, $7F ;fill pattern
    ;  .
    ; ..
    ;  ..
    ld (hl), a
    add hl, de
    inc de
    ld (hl), a
    inc hl
    ld (hl), a
    add hl, de
    ld (hl), a
    inc hl
    ld (hl), a
    
    ld e, a; use a as new increment
    
    add hl, de
    dec c
    jr nz, .loop
    
    ld hl, $0800;load ttl, also exx's p and np will be reversed

reset_iic_dout:
  ld c, $02
  ld de, screeninit2
  stopiic
  startiic
  .loop:
    ld a, (de)
    writeiic
    dec de;see comment in screeninit3
    dec c
    jr nz, .loop
  

life_start:
  ld bc, P1
  exx ;p
  ld bc, P0

cell_routine:

count_neighbors:
  exx ;init d', np
  ld d,$00
  exx ;p

  ld sp, left_done_vec
  ld de, $0081
  ld a, c;load lower address
  and $7F
  jp nz, check_row ;is it nonzero
check_left_done:
  ld sp, right_done_vec
  ld de, $007F
  ld a, c;load lower address
  inc a
  and $7F
  jp nz, check_row ;is it non-127
check_right_done:

check_mid:
  ld sp, mid_done_vec
  ld de, $0080
  jp check_row
check_mid_done:

apply_rules:
  ld a, (bc)
  and $01 ;bus might be funny
  jp nz, cell_alive
dead_cell:
  ;a=$00
  exx ;p
  ld (bc), a
  ld a, d
  cp $03
  jr nz, end
  ;a=$03
  ld (bc), a
  
end:
  inc bc;next point
  exx ;np
  inc bc
  ld hl, P1;if first array pointer is P1, done
  ld a,l
  cp c
  jp nz, cell_routine
  ld a, h
  cp b
  jp nz, cell_routine


  ;display first array to screen
  ld hl, P0-$0380
  ld a, $04 ;four lines
  .loop:
    ld i, a
    ld de, $0380
    add hl, de
    ld c, $80
    writegameiic
    ld a, i
    dec a
    jp nz, .loop

  ;copy second array to first
  ld hl, P1
  ld de, P0
  ld bc, $1000
  ldir

  ;if ttl is zero, mess with the memory a bit
  exx ;p
  dec hl
  ld a, l
  or h
  jp z, ttl_reinit
  exx ;np

  jp life_start

cell_alive:
  ;a=$01
  exx ;p
  ld (bc), a
  ld a, d;alive cell is counted
  cp $03
  jp z, end
  cp $04
  jp z, end
dead:
  xor a
  ld (bc), a
  jp end
  
;subroutines

check_row:
  ld l, c
  ld h, b
  and a ;clc
  sbc hl, de
  
  ld de, $0080
  ld a, $03
  .loop:
    bit 0, (hl)
    jr z, .end
    exx
    inc d
    exx
  .end:
    add hl, de
    dec a
    jr nz, .loop
  ret
  
beep:
  xor a
  .loop:
    xor BZ
    outp
    ld l, h
    .smollp:
    dec l
    jr nz,.smollp
    dec c
    jr nz,.loop
    dec d
    jr nz,.loop
    ret

;vectors, since there's no ram we use those to have subroutines
note0_vec:
  .addr n0_done
note1_vec:
  .addr n1_done
  
  .ascii "evv42 :p"
  
left_done_vec:
  .addr check_left_done
right_done_vec:
  .addr check_right_done
mid_done_vec:
  .addr check_mid_done
  
;SSD1306 stuff

screeninit3:;load backward from init2 to have 78,40 (data)
  db $40
screeninit2:;i2c address and c/d included
  db $78,$00
screeninit:; init code for ssd1306
  db $A8,$3F
  db $20,$00
  db $A1
  db $C8
  db $DA,$02
  db $81,$40
  db $8D,$14
  db $22,$04,$07
  db $AF
screenreset:
  db $B4,$10,$00
  

