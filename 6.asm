.model tiny
.386
.stack 100h
.data

snake dw 2000 dup (?)
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
food dw ?
score db 4 dup(?)

.code
JMP start

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

  mov dh, 0
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
  mov dh,1
  mov dl,0

  mov bh, 15
  mov bl, 201
  CALL Draw_Pixel

  mov dl,79
  mov bl,187
  CALL Draw_Pixel
  l1:
  CMP dh,23
  JZ l2
  mov dl,0
  ADD dh,1
  MOV BH, 15
  CMP DH, 9
  JL RR
  CMP DH, 16
  JA RR
  MOV BH, 4
  RR:
  mov bl,186
  CALL Draw_Pixel
  mov dl,79
  CALL Draw_Pixel

  jmp l1
  l2:
  ADD dh,1
  mov dl,0
  mov bl,200
  CALL Draw_Pixel
  mov dl,79
  mov bl,188
  CALL Draw_Pixel
  
  mov dl,0
  l3:
  CMP dl,78
  JZ l4
  mov dh,1
  ADD dl,1
  mov bl,205
  CALL Draw_Pixel
  mov dh,24
  CALL Draw_Pixel

  jmp l3
  l4:

  mov dh,0
  mov dl,0
  mov bl,83
  CALL  Draw_Pixel 
  INC dl
  mov bl,67
  CALL Draw_Pixel
  INC dl
  mov bl,79
  CALL Draw_Pixel
  INC dl
  mov bl,82
  CALL Draw_Pixel
  INC dl
  mov bl,69
  CALL Draw_Pixel
  INC dl
  mov bl,58
  CALL Draw_Pixel
  INC dl
  INC dl
  mov [posScore],dx

  pop si di dx cx bx ax
  RET

Spawn_snake:
  PUSH DI SI DX CX BX AX

  MOV DH, 12
  MOV DL, 38

  MOV SI, [countSnake]
  ADD SI, SI

  MOV BH, 2 ;color
  MOV BL, 1 ;ascii of head

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
	add dx, 2 ;score
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
  MOV BL, 1

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
  JE game_over
  CMP DH, 0
  JE game_over
  CMP DL, 80
  JE game_over
  CMP DH, 24
  JE game_over
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
  JE game_over
  
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
  MOV BL, 9
  MOV DX, AX
  MOV food, DX
  CALL Draw_Pixel

  POP AX BX CX DX
  RET
start:
mov AX,@data
mov DS,AX

CALL Clear_consol
CALL Draw_Borders
CALL Game_rools

game_over:
INT 21h
end start