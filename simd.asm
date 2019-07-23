;%include "io64.inc"

section .data
    img_size dd 1086
    headers_len dd 54
    dib_len dd 40
    width dd 10
    height dd 10
    bpp dw 9
    pixs_num dd 120
    msg1 db 'Please enter the operand:' ,0x0a,0xD 
    len1 equ $ - msg1
    msg2 db 'there is no pixel in image or ...' ,0x0a,0xD 
    len2 equ $ - msg2
    msg3 db 'Please enter the output address', 0x0a,0xD
    len3 equ $-msg3
     
    msg_done db 'Written to file', 0x0a,0xD
    len_done equ $-msg_done 
    
    op8 times 8 db 0
    op8_len equ $-op8
   
    
    zero equ byte'0'
    plus equ byte'+'
    minus equ byte'-'
    
        ;info all-registers  out_file db '/home/sobhan/Desktop/stone64.bmp'
    
            
    file db '/home/sobhan/Desktop/images/iran.bmp'
    
    
section .bss
    img resb 10000000 
    img_len equ $ - img

    op resw 100
    op_len equ $ - op
    
    time resb 100
    
    input resb 100
    input_len equ $-input
    
    fd_out resb 100
    fd_in  resb 100
    
    address resb 10000      
    address_len equ $-address
    
section .text
global _start
_start:
    mov rbp, rsp; for correct debugging
    

    ;print msg1
    mov eax, 4
    mov ebx, 1
    mov ecx, msg1
    mov edx, len1
    int 80h
    
    ;read the operand to add to the image
    mov eax, 3
    mov ebx, 1
    mov ecx, input
    mov edx, input_len
    int 80h

    xor rax, rax
    mov eax, 43
    mov ebx, time
    int 80h
       
    mov r13, rax
t1:
    xor rax, rax
    ;to in the operand
    xor rsi, rsi
    mov rsi, input
    call stoi
    mov [op], eax
cha:    ;call clear_input
    xor rsi, rsi
    
    ;make a 8 byte of the operand for add to xmm reg
    xor rax, rax
    xor rcx, rcx
    mov esi, op8
    mov ecx, 8
    mov al, [op]
lp8b:
    mov byte[esi], al
    inc esi
    loop lp8b
       ;open image from file
    mov ebx, file ; const char *filename
    mov eax, 5  
    mov ecx, 0  
    int 80h   
    
    mov  [fd_in], eax                                   ;ERROR Prone
     
    ;read image from file
    mov eax, 3  
    mov ebx, eax
    mov ecx, img 
    mov edx, img_len    
    int 80h     
    
    ;exract image derails from img header
    xor rsi, rsi
    mov esi, img
l0:
    xor eax, eax
    add esi, 2
    mov eax, dword[esi]
    mov [img_size], eax
l1:
    xor eax, eax    
    add esi, 8
    mov eax, dword[esi]
    mov [headers_len], eax
l2:
    xor eax, eax
    add esi, 4
    mov eax, dword[esi]
    mov [dib_len], eax
l3:
    xor eax, eax
    add esi, 4
    mov eax, dword[esi]
    mov [width], eax
l4:
    xor eax, eax
    add esi, 4
    mov eax, dword[esi]
    mov [height], eax    
l5:
    xor eax, eax    
    add esi, 6
    mov ax, word[esi]
    mov [bpp], ax
l6:
    xor eax, eax
    add esi, 6
    mov eax, dword[esi]
    mov [pixs_num], eax
l7:

    ;now esi point to the start of pixel values of image              
    xor rsi, rsi
    mov esi, img
    mov eax, [headers_len]
    add esi, eax            
    
    ;change the value of first pixel
    xor rdx, rdx
    xor rax, rax
    xor rbx, rbx
    xor rcx, rcx
    mov eax, [pixs_num]
    mov ebx, eax
    cmp eax, 8
    jl lp1 
    mov ecx, 8
    div ecx
    mov ecx, eax ;for sse loop
    mov ebx, edx ;for remain which is less than 8 will be taked care simple not sse
    
lpmmx:
    ;xor xmm0, xmm0
    mov r9, qword[esi]
    movq mm2, r9
    movq mm1, qword[op8]
    cmp r15b,0
    jnz subb
    paddusb mm2, mm1
    jmp after    
subb:
    psubusb mm2, mm1    
after:    
    movq qword[esi], mm2

    add esi, 8
    dec ecx
    cmp ecx, 0
    ja lpmmx
    cmp ebx, 0
r5:
    jle done
    mov ecx, ebx   
    ;less  last pixs
lp1:
    xor eax, eax
    mov al, byte[esi]
    add eax, [op]
    cmp eax, 0
    jl low
    cmp eax, 255
    ja above
    normal:
        mov byte[esi], al
        inc esi
        loop lp1
        jmp done
    low:
        xor eax, eax ;make it zero
        jmp normal
    above:
        xor eax, eax
        mov eax, 255
        jmp normal 
                    
    done:
        
        xor rax, rax
        mov eax, 43
        mov ebx, time
        int 80h
       
        mov r14, rax
        sub r14, r13
t2: 
        ;print msg3 for address
        mov eax, 4
        mov ebx, 1
        mov ecx, msg3
        mov edx, len3
        int 80h
        
        ;read address from user
        mov eax, 3
        mov ebx, 1
        mov ecx, address
        mov edx, address_len
        int 80h

    
        ;create the file
        mov  eax, 8
        mov  ebx, address
        mov  ecx, 0777        ;read, write and execute by all
        int  80h              ;call kernel
        
        mov [fd_out], eax
    
        ; write into the file
        mov  edx, img_size    ;number of bytes
        mov  ecx, img         ;message to write
        mov  ebx, [fd_out]    ;file descriptor 
        mov  eax, 4           ;system call number (sys_write)
        int  80h              ;call kernel
        	
        ; close the file
        mov eax, 6
        mov ebx, [fd_out]
        
        ; write the message indicating end of file write
        mov eax, 4
        mov ebx, 1
        mov ecx, msg_done
        mov edx, len_done
        int  0x80

    jmp exit        

;    mov eax, 4  
;    mov ebx, 1
;    mov ecx, img 
;    mov edx, img_len
;    int 80h     
;
    
sth_wrong:
    ;print there is no pixel in image or ...
    mov eax, 4
    mov ebx, 1
    mov ecx, msg2
    mov edx, len2
    int 80h
    

exit:
    mov eax, 6   
    mov ebx, [fd_in]
    int 80h     

 
    mov eax, 1  
    mov ebx, 0 
    int 80h

;functions=====================================================    
stoi:
        ;rsi is pointing to the start of "input" string
        ;eax has the output integer
        ;r15b is reserved for sign 
        ;r12 to keep the length
        xor rax, rax
        xor ecx, ecx
        xor r12, r12
        mov ecx, 10
        xor r15b, r15b
        cmp byte[rsi], plus
        je sign
        cmp byte[rsi], minus
        jne for
        sign:
            mov r10, 1
            mov r15b, [rsi]
            inc rsi
            inc r12
        for:
            xor edx, edx
            xor ebx, ebx
            mov bl, [rsi]
            sub bl, zero
            mul ecx
            add eax, ebx
            inc rsi
            inc r12
            cmp byte[rsi+1], 0     
            jnz for
        cmp r15b, minus
        jne end
        ;neg eax
        end:
        ret        

clear_input:
            mov rsi, input
            mov ecx, input_len
            lpc:
                mov [rsi], byte 0
                inc rsi
                loop lpc
            ret    