.model tiny
.386
.stack 100h
.data

snake dw 2000 dup (?)
speed dw 2
countSnake dw 2
last dw ?
posScore dw ?
route db 4Dh
head dw ?
x_map db 4
y_map db 2
rand_a dw 63621
rand_m dw 7fffh
seed dw -1
hard_score db 'D','R','A','H'
easy_score db 'Y','S','A','E'
medium_score db 'M','U','I','D','E','M'
exit_score db 'T', 'I', 'X', 'E'
score_score db ' ', ':', 'E', 'R', 'O', 'C', 'S'
food dw ?
score db 4 dup(?)

.code
JMP start
Show_menu:
  MOV countSnake, 2
  scroll_menu:
  MOV DH, 9  ; hard
  MOV DL, 37
  MOV AX, speed

  CMP AX, 2
  JNE not_hard
  MOV BH, 4
  JMP hard
  not_hard:
  MOV BH, 15
  hard:
  
  MOV SI, 4
  cycle_hard:

  SUB SI, 1
  MOV BL, hard_score[SI]
  CALL Draw_Pixel

  INC DL

  CMP SI, 0
  JNE cycle_hard

  MOV DH, 10   ; medium
  MOV DL, 36

  MOV AX, speed
  CMP AX, 3
  JNE not_medium
  MOV BH, 4
  JMP medium
  not_medium:
  MOV BH, 15
  medium:

  MOV SI, 6
  cycle_medium:

  SUB SI, 1
  MOV BL, medium_score[SI]
  CALL Draw_Pixel

  INC DL

  CMP SI, 0
  JNE cycle_medium

  MOV DH, 11 ;easy
  MOV DL, 37

  MOV AX, speed
  CMP AX, 4
  JNE not_easy
  MOV BH, 4
  JMP easy
  not_easy:
  MOV BH, 15
  easy:

  MOV SI, 4
  cycle_easy:

  SUB SI, 1
  MOV BL, easy_score[SI]
  CALL Draw_Pixel

  INC DL

  CMP SI, 0
  JNE cycle_easy

  MOV DH, 12  ;exit

  MOV DL, 37
  MOV AX, speed
  CMP AX, 5
  JNE not_exit
  MOV BH, 4
  JMP exit
  not_exit:
  MOV BH, 15

  exit:

  MOV SI, 4
  cycle_exit:

  SUB SI, 1
  MOV BL, exit_score[SI]
  CALL Draw_Pixel

  INC DL

  CMP SI, 0
  JNE cycle_exit
   
  CALL Delay 
  XOR AX, AX
  CALL Click
  MOV AH, route
  MOV route, 0

  CMP AH, 48h
  JNE next
  SUB speed, 1
  next:
  CMP AH, 50h
  JNE n_next
  ADD speed, 1

  n_next:

  CMP speed, 1
  JNE prev
  MOV speed, 5

  prev:

  CMP speed, 6
  JNE p_prev
  MOV speed, 2

  p_prev:

  CMP AH, 4Bh
  JNE scroll_menu

  CMP speed, 5
  JE game_over
  
  MOV route, 4Dh
  RET

Show_score:
  MOV AX, countSnake
  SUB AX, 2
  MOV BX, 10
  MOV SI, 0
  XOR CX, CX
  XOR DX, DX

  retry:

  DIV BX
  MOV score[SI], DL
  XOR DX, DX

  ADD SI, 2
  ADD CL, 2

  CMP AX, 0
  JNE retry

  mov dh, 1
  mov dl, 7
  MOV SI, CX
  MOV BH, 15

  jzloop:

  SUB SI, 2
  MOV BL, score[SI]
  ADD BL, 48

  CALL Draw_Pixel

  INC DL

  CMP SI, 0
  JNE jzloop
  RET

Add_score:
  PUSHA

  MOV SI, [countSnake]
  ADD SI, SI

  zloop:

  MOV DX, snake[SI-2]
  MOV snake[SI], DX

  SUB SI, 2

  CMP SI, 0
  JNE zloop

  DEC DX

  MOV snake[SI], 0
  MOV snake[SI], DX

  POPA
  ; CALL Spawn_food
  RET

Random:
  push cx dx
  mov ax,[seed] ;считать последнее случайное число
  test ax,ax ;проверить его, если это -1,
  js fetch_seed ;функция ещё ни разу не вызывалась
  ;и надо создать начальные значения
  randomize:
  mul [rand_a] ;умножить число на а
  xor dx,dx
  div [rand_m] ;взять остаток от деления 2^15-1
  mov ax,dx
  mov [seed],ax ;сохранить для следующих вызовов

  col: ;В регистре al рандомное число
  cmp al, 72 ;Проверяем границу числа
  jb row

  shr al,1 ;Если больше, делим на 2 логическим сдвигом
  jmp col

  row:
  cmp ah, 12
  jb ex

  shr ah, 1
  jmp row

  ex:
  add ah, x_map
  add al, y_map

  pop dx cx
  ret

  fetch_seed:
  mov ah, 2ch
  int 21h

  mov ax, cx
  add ax, dx

  jmp randomize

Click:
  mov ax, 0100h
  int 16h
  jz en           ;Без нажатия выходим
  xor ah, ah
  int 16h

  CMP AH, 48h ;up
  JNE ne_up
  CMP route, 50h
  JE en
  MOV route, 48h
  JMP en
  ne_up:

  CMP AH, 50h ; down
  JNE ne_down
  CMP route, 48h
  JE en
  MOV route, 50h
  JMP en
  ne_down:

  CMP AH, 4Dh ;right
  JNE ne_right
  CMP route, 4Bh
  JE en
  MOV route, 4Dh
  JMP en
  ne_right:
  CMP route, 4Dh
  JE en
  MOV route, 4Bh ;left

  en:
  RET
Clear_consol:
  mov ax, 0003h ;clear console
  int 10h

  mov ah,2 ;hide cursor
  mov bh,0
  mov dh,25
  mov dl,0
  int 10h
  RET
Draw_Pixel:
  mov ax,0B800h
  mov es,ax
  mov ch,bh
  mov cl,bl
  push ax bx dx di si

  shl dl,1
  mov al,dh ;в al — ряд,
  mov bl,160 ;который нужно умножить на 160
  mul bl ;умножаем: al (ряд) * 160; результат — в ax
  
  mov di, ax ;результат умножения — в di
  xor dh, dh ;аннулируем dh
  add di,dx ;теперь в di линейный адрес в видеобуфере.

  mov ah,ch
  mov al,cl
  mov es:[di],ax
  pop si di dx  bx ax

  RET

Draw_Borders:
  push ax bx cx dx di si

  mov dl,0

  mov bh, 15
  mov bl, 176

  top_border:

  MOV DH, 1
  CALL Draw_Pixel

  MOV DH, 23
  CALL  Draw_Pixel

  INC DL

  CMP dl, 80
  JNE top_border

  MOV DH, 1
  right_border:

  MOV BH, 15

  CMP DH, 8
  JL not_red
  CMP DH, 16
  JA not_red

  MOV BH, 4

  not_red:

  MOV DL, 0
  CALL Draw_Pixel

  MOV DL, 79
  CALL  Draw_Pixel

  INC DH

  CMP DH, 23
  JNE right_border

  MOV SI, 7
  MOV DH, 1
  MOV DL, 0
  cycle_score:

  SUB SI, 1
  MOV BL, score_score[SI]
  CALL Draw_Pixel

  INC DL

  CMP SI, 0
  JNE cycle_score

  pop si di dx cx bx ax
  RET

Spawn_snake:
  PUSH DI SI DX CX BX AX

  MOV DH, 12
  MOV DL, 38

  MOV SI, [countSnake]
  ADD SI, SI

  MOV BH, 2 ;color
  MOV BL, 207 ;ascii of head

  MOV snake[SI], DX
  CALL Draw_Pixel

  poop:

  dec DX
  SUB SI, 2
  MOV snake[SI], DX
  MOV BL, 9 ;ascii of body
  CALL Draw_Pixel

  CMP SI, 0 
  JA poop 

  POP DI SI DX CX BX AX
  RET

Delay:
  push cx
	mov ah,0
	int 1Ah 
	add dx, speed
	mov bx,dx
    repeat:   
	int 1Ah
	cmp dx,bx
	jl repeat
	pop cx
	RET
Game_rools:
  CALL Spawn_snake
  CALL Spawn_food

  PUSH AX BX CX DX SI DI
  cycle:

  MOV SI, [countSnake]
  ADD SI, SI

  MOV BH, 2
  MOV BL, 148

  MOV DX, snake[si]
  MOV last, DX

  CMP route, 4Dh
  JNE not_right
  ADD DL, 1
  JMP vector
  not_right:

  CMP route, 4Bh
  JNE not_left
  SUB DL, 1
  JMP vector
  not_left:

  CMP route, 48h
  JNE not_up
  SUB DH, 1
  JMP vector
  not_up:

  ADD DH, 1

  vector:

  CMP DL, 0    ;check borders
  JE menu
  CMP DH, 0
  JE menu
  CMP DL, 80
  JE menu
  CMP DH, 24
  JE menu
  MOV head, DX

  MOV snake[si], DX

  CALL Draw_Pixel

  recycle:

  MOV BL, 9
  MOV DX, last
  SUB SI, 2
  MOV AX, snake[SI]
  MOV last, AX

  CMP DX, head
  JE menu
  
  MOV snake[SI], DX

  CALL Draw_Pixel

  CMP SI, 0
  JNE recycle

  MOV BL, 32
  MOV DX, last
  CALL Draw_Pixel

  MOV DX, head
  CMP DX, food  ; check food
  JNE continue
  INC countSnake
  CALL Add_score
  CALL Spawn_food
  continue:

  CALL Delay
  CALL Show_score 
  CALL Click
  JMP cycle

  POP AX BX CX DX SI DI
  RET

Spawn_food:
  PUSH AX BX CX DX
  check:
  MOV SI, [countSnake]
  ADD SI, SI
  CALL Random
  check_snake_body:
  CMP snake[SI], AX
  JE check
  SUB SI, 2

  CMP SI, 0
  JNE check_snake_body

  MOV BH, 12
  MOV BL, 7
  MOV DX, AX
  MOV food, DX
  CALL Draw_Pixel

  POP AX BX CX DX
  RET
start:
mov AX,@data
mov DS,AX

menu:
CALL Clear_consol
CALL Draw_Borders
CALL Show_menu
CALL Clear_consol
CALL Draw_Borders
CALL Game_rools

game_over:
CALL Clear_consol
MOV AH, 4Ch
INT 21h
end start