.intel_syntax noprefix
.global denoise_S



denoise_S:

#uint8_t* input  : rdi (immediately discarded after greyScaleConvert_S)
#size_t width    : si
#size_t height   : dx
#uint8_t* temp1  : rcx (moved to rdi for ease of access)
#uint8_t* temp2  : r8
#uint8_t* temp3  : r9
#uint8_t* output : [rsp + 0x8] (moved to rcx for ease of access)

#float constA    : xmm0
#float constB    : xmm1
#float constC    : xmm2

#int x           : r10w
#int y           : r11w
#iCounter        : r12d
#oCounter        : r13d

    push r8                                       #save r8 and r9 to stack
    push r9

    call greyScaleConvert_S

    pop r9                                        #restore r8 and r9
    pop r8

    mov rdi, rcx                                  #rdi (raw data) isn't needed anymore, move greyscaled image to first parameter for next functions
    mov rcx, [rsp + 0x8]                          #move array pointer from stack to register rcx for ease of access

    push rcx                                      #save rcx and r9
    push r9

    mov rcx, r8                                   #move temp2 as output for laplace filter
    call laplaceFilter_S
    mov r8, rcx                                   #move temp2 back

    pop r9                                        #restore r9 and rcx
    pop rcx

    push rcx                                      #restore rcx and r8
    push r8

    mov rcx, r9                                   #move temp3 as output for soft focus
    call softFocus_S
    mov r9, rcx                                   #move temp3 back

    pop r8                                        #restore rcx and r8
    pop rcx

    push r12                                      #store r12 and r13 to stack
    push r13

    lea r12, [rsi + 2]                            #r12 == width + 2
    xor r13, r13

    xor r11, r11
.LloopDenY:                                       #outer loop
    cmp r11w, dx
    jge .LloopDenYend

    xor r10, r10
.LloopDenX:                                       #inner loop until r10 is greater or equal width
    cmp r10w, si
    jge .LloopDenXend

    movzx rax, byte ptr [rdi + r12]               #load values from temp1, temp2, temp3
    cvtsi2ss xmm0, rax
    movzx rax, byte ptr [r8 + r12]
    cvtsi2ss xmm1, rax
    movzx rax, byte ptr [r9 + r12]
    cvtsi2ss xmm2, rax
    mov rax, 1020
    cvtsi2ss xmm3, rax
    subss xmm0, xmm2                              #do calculations
    mulss xmm0, xmm1
    divss xmm0, xmm3
    addss xmm0, xmm2
    cvtss2si rax, xmm0

    mov byte ptr [rcx + r13], al                  #store in result array

    inc r12d                                      #increase pointers to input and output
    inc r13d
    inc r10w                                      #increase pointer to loop
    jmp .LloopDenX
.LloopDenXend:

    inc r12d                                      #increase pointer to input
    inc r11w                                      #increase pointer to outer loop
    jmp .LloopDenY
.LloopDenYend:

    pop r13                                       #restore r13 and 12
    pop r12

    ret



greyScaleConvert_S:

#uint8_t* input  : rdi 
#size_t width    : si
#size_t height   : dx
#uint8_t* output : rcx

#float constA    : xmm0
#float constB    : xmm1
#float constC    : xmm2

#float ftemp1    : xmm3
#float ftemp2    : xmm4
#float ftemp3    : xmm5
#float ftemp4    : xmm6

#int x           : r8w
#int y           : r9w
#iCounter        : r10d
#oCounter        : r11d



    push r12                                      #store r12 to stack
    xor r10, r10
    xor r11, r11

    xorps xmm6, xmm6                              #precompute constA+constB+constC
    addss xmm6, xmm0
    addss xmm6, xmm1
    addss xmm6, xmm2

    xor r8, r8
.LloopGreX1:                                      #fill in first padding
    cmp r8w, si                                   #fill zero one by one
    jg .LloopGreX1end

    mov byte ptr [rcx + r11], 0
    inc r11d

    inc r8w
    jmp .LloopGreX1
.LloopGreX1end:

    xor r9, r9
.LloopGreY1:                                      #do greyscaling whilst padding
    cmp r9w, dx
    jge .LloopGreY1end

    mov byte ptr [rcx + r11], 0
    inc r11d

    xor r8, r8
.LloopGreX2:
    cmp r8w, si                                   #do calculations with normal register until counter == 0
    jge .LloopGreX2end

    movzx rax, byte ptr [rdi + r10]               #load values from offset r10
    cvtsi2ss xmm3, rax
    movzx rax, byte ptr [rdi + r10 + 1]           #load values from offset r10 + 1
    cvtsi2ss xmm4, rax
    movzx rax, byte ptr [rdi + r10 + 2]           #load values from offset r10 + 2
    cvtsi2ss xmm5, rax                            #convert to float
    mulss xmm3, xmm0                              #do calculations
    mulss xmm4, xmm1
    mulss xmm5, xmm2
    addss xmm3, xmm4
    addss xmm3, xmm5
    divss xmm3, xmm6
    cvtss2si rax, xmm3                            #convert to integers
    mov [rcx + r11], al                           #store values to rcx
    inc r11d                                      #increase pointer to output by 1
    add r10d, 3                                   #increase pointer to input by 3

    inc r8w                                       #increase pointer to loop counter
    jmp .LloopGreX2
.LloopGreX2end:

    inc r9w                                       #increase pointer to outer loop counter
    jmp .LloopGreY1
.LloopGreY1end:

    xor r8, r8
.LloopGreX3:                                      #fill in second paddings
    cmp r8w, si                                   #fill zero one by one
    jg .LloopGreX3end

    mov byte ptr [rcx + r11], 0
    inc r11d

    inc r8w
    jmp .LloopGreX3
.LloopGreX3end:

    mov byte ptr [rcx + r11], 0                   #last pad~

    pop r12                                       #restore r12
    ret


laplaceFilter_S:

#uint8_t* input  : rdi 
#size_t width    : si
#size_t height   : dx
#uint8_t* output : rcx

#int x           : r8w
#int y           : r9w
#counter         : r10d
#checkRight      : r11w
#checkLeft       : r12w
#temp            : r13w


    push r12                                      #store r12 and r13 in stack
    push r13

    lea r10, [rsi + 2]                            #r10 = width + 2

    xor r9, r9
.LloopLapY:                                       #start outer loop
    cmp r9w, dx
    jge .LloopLapYend

    xor r8, r8
.LloopLapX:                                       #do calculations with regular registers first until r8w is equal or greater than width
    cmp r8w, si
    jge .LloopLapXend
    
    lea rax, [r10 + rsi + 1]
    movzx r11, byte ptr [rdi + rax]               #load value from offset + width + 1

    mov rax, rsi
    neg rax
    lea rax, [r10 + rax - 1]
    movzx r13, byte ptr [rdi + rax]               #load value from offset - width - 1
    add r11w, r13w

    movzx r13, byte ptr [rdi + r10 + 1]           #load value from offset + 1
    add r11w, r13w

    movzx r13, byte ptr [rdi + r10 - 1]           #load value from offset - 1
    add r11w, r13w

    movzx r13, byte ptr [rdi + r10]               #load value from offset times 4
    lea r12, [r13 * 4]

    sub r11w, r12w                                #(up+left+right+down) - 4*center
    cmp r11w, 0                                   #if negative -> times -1
    jge .LcontLap
    neg r11w
.LcontLap:

    mov [rcx + r10], r11b                         #store values to result array

    inc r10d                                      #increase input output counter by 1
    inc r8w                                       #increase loop counter by 1
    jmp .LloopLapX
.LloopLapXend:

    inc r10d                                      #increase inpu output counter by 1
    inc r9w                                       #increase outer loop counter by 1
    jmp .LloopLapY
.LloopLapYend:

    pop r13                                       #restore r13 and r12
    pop r12
    ret



softFocus_S:

#uint8_t* input  : rdi 
#size_t width    : si
#size_t height   : dx
#uint8_t* output : rcx

#int x           : r8w
#int y           : r9w
#counter         : r10d
#accumulate      : r11w
#accumulate2     : r12w
#temp            : r13w

    push r12                                      #store r12 and r13 in stack
    push r13

    lea r10, [rsi + 2]                            #r10 = width + 2

    xor r9, r9
.LloopSofY:                                       #start outer loop
    cmp r9w, dx
    jge .LloopSofYend

    xor r8, r8
.LloopSofX:                                       #do calculations with regular registers first until r8w is equal or greater than width
    cmp r8w, si
    jge .LloopSofXend
    
    lea rax, [r10 + rsi + 1]                      #save offset + width + 1
    movzx r11, byte ptr [rdi + rax]               #load from offset + width + 1

    movzx r12, byte ptr [rdi + rax + 1]           #load from offset + width + 2

    movzx r13, byte ptr [rdi + rax - 1]           #load from offset + width
    add r12w, r13w                                #add the last 2

    mov rax, rsi
    neg rax
    lea rax, [r10 + rax - 1]                      #save offset - width - 1
    movzx r13, byte ptr [rdi + rax]               #load from offset - width - 1
    add r11w, r13w                                #add to r11

    movzx r13, byte ptr [rdi + rax + 1]           #load from offset - width
    add r12w, r13w                                #add to r12

    movzx r13, byte ptr [rdi + rax - 1]           #load from offset - width - 2
    add r12w, r13w                                #add to r12

    movzx r13, byte ptr [rdi + r10 + 1]           #load from offset + 1
    add r11w, r13w                                #add to r11

    movzx r13, byte ptr [rdi + r10 - 1]           #load from offset - 1
    add r11w, r13w                                #add to r11

    lea r11, [r12 + 2 * r11]                      #r12 + 2*r11

    movzx r13, byte ptr [rdi + r10]               #load from offset
    lea r11, [r11 + 4 * r13]                      #r12 + 2*r11 + 4*r13
    shr r11, 4                                    #divide by 16
    
    mov [rcx + r10], r11b                         #store at result array

    inc r10d                                      #increase input output counter by 1
    inc r8w                                       #increase loop counter by 1
    jmp .LloopSofX
.LloopSofXend:

    inc r10d                                      #increase input output counter by 1
    inc r9w                                       #increase outer loop counter by 1
    jmp .LloopSofY
.LloopSofYend:

    pop r13                                       #restore r12 and r13
    pop r12
    ret