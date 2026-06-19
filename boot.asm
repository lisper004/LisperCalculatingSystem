org 0x7c00
bits 16

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    
    mov ah, 0x00
    mov al, 0x03
    int 0x10
    
    mov si, msg_welcome
    call print_string

main_loop:
    mov si, msg_ready
    call print_string
	
    call print_time
    call newline
    
    mov si, prompt
    call print_string
    
    mov di, input_buffer
    xor cx, cx
    
read_char:
    mov ah, 0x00
    int 0x16
    
    cmp al, 0x0D  ; Enter?
    je process_command
    
    cmp al, 0x08  ; Backspace?
    je backspace
    
    cmp cx, 63
    je read_char
    
    mov ah, 0x0E
    mov bh, 0x00
    int 0x10
    
    mov [di], al
    inc di
    inc cx
    jmp read_char

backspace:
    cmp cx, 0
    je read_char
    
    dec di
    dec cx
    mov ah, 0x0E
    mov al, 0x08
    mov bh, 0x00
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    jmp read_char

process_command:
    mov byte [di], 0
    
    call newline
    
    mov si, input_buffer
    mov di, cmd_sum
    call strcmp
    jc parse_sum
    
    mov si, msg_unknown
    call print_string
    call newline
    jmp main_loop

parse_sum:
    mov si, input_buffer
    add si, 4
    
.skip_spaces1:
    cmp byte [si], ' '
    jne .got_num1
    inc si
    jmp .skip_spaces1
    
.got_num1:
    call read_binary
    mov [num1], bl
    
.skip_spaces2:
    cmp byte [si], ' '
    jne .got_num2
    inc si
    jmp .skip_spaces2
    
.got_num2:
    call read_binary
    mov [num2], bl
    
    mov al, [num1]
    add al, [num2]
    
    mov si, msg_result
    call print_string
    
    mov bl, al
    call print_binary
    
    call newline
    jmp main_loop

read_binary:
    xor bl, bl
    xor ax, ax
    
.read_digit:
    mov al, [si]
    cmp al, 0
    je .done
    cmp al, ' '
    je .done
    cmp al, 0x0D
    je .done
    cmp al, 0x0A
    je .done
    
    cmp al, '0'
    je .is_zero
    cmp al, '1'
    je .is_one
    
    xor bl, bl
    ret
    
.is_zero:
    shl bl, 1
    jmp .next
    
.is_one:
    shl bl, 1
    or bl, 1
    
.next:
    inc si
    jmp .read_digit
    
.done:
    ret

print_binary:
    pusha
    mov cx, 8
    mov ah, 0x0E
    mov bh, 0x00
    
.print_bit:
    shl bl, 1
    jc .print_one
    mov al, '0'
    jmp .print_char
    
.print_one:
    mov al, '1'
    
.print_char:
    int 0x10
    loop .print_bit
    
    popa
    ret

print_time:
    pusha
    
    mov ah, 0x02
    int 0x1A
    
    mov al, ch
    call print_bcd_byte
    mov al, ':'
    call print_char
    mov al, cl
    call print_bcd_byte
    
    mov al, ' '
    call print_char
    
    popa
    ret

print_bcd_byte:
    pusha
    mov ah, 0x0E
    mov bh, 0x00
    
    push ax
    shr al, 4
    add al, '0'
    int 0x10
    pop ax
    
    and al, 0x0F
    add al, '0'
    int 0x10
    
    popa
    ret

print_char:
    pusha
    mov ah, 0x0E
    mov bh, 0x00
    int 0x10
    popa
    ret

strcmp:
    push si
    push di
.loop:
    mov al, [si]
    mov ah, [di]
    cmp al, ah
    jne .not_equal
    cmp al, 0
    je .equal
    inc si
    inc di
    jmp .loop
    
.equal:
    pop di
    pop si
    clc
    ret
    
.not_equal:
    pop di
    pop si
    stc
    ret

print_string:
    pusha
    mov ah, 0x0E
    mov bh, 0x00
    
.print_char:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .print_char
    
.done:
    popa
    ret

newline:
    pusha
    mov ah, 0x0E
    mov al, 0x0D
    mov bh, 0x00
    int 0x10
    mov al, 0x0A
    int 0x10
    popa
    ret

msg_welcome db 'WELCOME TO LCS', 0x0D, 0x0A, 0
msg_ready db 'R ', 0
prompt db '@', 0
msg_unknown db 'UNKNOWN', 0x0D, 0x0A, 0
msg_result db 'RSLT: ', 0
cmd_sum db 'SUM', 0

num1 db 0
num2 db 0
input_buffer times 64 db 0

times 510-($-$$) db 0
dw 0xAA55
