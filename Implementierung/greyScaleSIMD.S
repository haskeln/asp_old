.intel_syntax noprefix
.global denoise_SIMD
.text


denoise_SIMD:

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

#temps           : xmm0 - xmm13
#mask            : xmm14
#temp masks      : xmm15

#int x           : r10w
#int y           : r11w
#iCounter        : r12d
#oCounter        : r13d

    push r8                                        #save r8 and r9 to stack
    push r9

    call greyScaleConvert_SIMD

    pop r9                                         #restore r8 and r9
    pop r8

    mov rdi, rcx                                   #rdi (raw data) isn't needed anymore, move greyscaled image to first parameter for next functions
    mov rcx, [rsp + 0x8]                           #move array pointer from stack to register rcx for ease of access

    push rcx                                       #save rcx and r9
    push r9

    mov rcx, r8                                    #move temp2 as output for laplace filter
    call laplaceFilter_SIMD
    mov r8, rcx                                    #move temp2 back

    pop r9                                         #restore r9 and rcx
    pop rcx

    push rcx                                       #restore rcx and r8
    push r8

    mov rcx, r9                                    #move temp3 as output for soft focus
    call softFocus_SIMD
    mov r9, rcx                                    #move temp3 back

    pop r8                                         #restore rcx and r8
    pop rcx

    push r12                                       #store r12 and r13 to stack
    push r13

    mov rax, 0xffffffff0c080400                    #pre-compute mask
    movq xmm14, rax
    mov rax, 0xffffffffffffffff
    pinsrq xmm14, rax, 1

    lea r12, [rsi + 2]                             #r12 == width + 2
    xor r13, r13

    xor r11, r11
.LloopDenY:                                        #outer loop
    cmp r11w, dx
    jge .LloopDenYend

    mov r10, rsi
.LloopDenX:                                        #inner loop. Use regular register until r10 is divisible by 16
    test r10w, 15
    jz .LloopDenSimdX

    movzx rax, byte ptr [rdi + r12]                #load values from temp1, temp2, temp3
    cvtsi2ss xmm0, rax
    movzx rax, byte ptr [r8 + r12]
    cvtsi2ss xmm1, rax
    movzx rax, byte ptr [r9 + r12]
    cvtsi2ss xmm2, rax
    mov rax, 1020
    cvtsi2ss xmm3, rax
    subss xmm0, xmm2                               #do calculations
    mulss xmm0, xmm1
    divss xmm0, xmm3
    addss xmm0, xmm2
    cvtss2si rax, xmm0

    mov byte ptr [rcx + r13], al                   #store in result array

    inc r12d                                       #increase pointers to input and output
    inc r13d
    dec r10w                                       #decrease pointer to loop
    jmp .LloopDenX
.LloopDenSimdX:
    test r10w, r10w                                #loop until r10 is zero
    jz .LloopDenXend
    xorps xmm0, xmm0

    movdqu xmm1, [rdi + r12]                       #load temp1, copy to other 3 registers
    movdqa xmm2, xmm1
    movdqa xmm3, xmm1
    movdqa xmm4, xmm1            

    punpcklbw xmm1, xmm0                           #convert 16 byte values into 16 dword values across 4 registers
    punpcklbw xmm1, xmm0

    punpcklbw xmm2, xmm0
    punpckhbw xmm2, xmm0

    punpckhbw xmm3, xmm0
    punpcklbw xmm3, xmm0

    punpckhbw xmm4, xmm0
    punpckhbw xmm4, xmm0


    movdqu xmm5, [r8 + r12]                        #load temp2, copy to other 3 registers
    movdqa xmm6, xmm5
    movdqa xmm7, xmm5
    movdqa xmm8, xmm5                      

    punpcklbw xmm5, xmm0                           #convert 16 byte values into 16 dword values across 4 registers
    punpcklbw xmm5, xmm0

    punpcklbw xmm6, xmm0
    punpckhbw xmm6, xmm0

    punpckhbw xmm7, xmm0
    punpcklbw xmm7, xmm0

    punpckhbw xmm8, xmm0
    punpckhbw xmm8, xmm0


    movdqu xmm9, [r9 + r12]                        #load temp3, copy to other 3 registers
    movdqa xmm10, xmm9
    movdqa xmm11, xmm9
    movdqa xmm12, xmm9

    punpcklbw xmm9, xmm0                           #convert 16 byte values into 16 dword values across 4 registers
    punpcklbw xmm9, xmm0

    punpcklbw xmm10, xmm0
    punpckhbw xmm10, xmm0

    punpckhbw xmm11, xmm0
    punpcklbw xmm11, xmm0

    punpckhbw xmm12, xmm0
    punpckhbw xmm12, xmm0

    mov rax, 1020                                  #load 1020, convert to 4 floats
    movd xmm13, rax
    pshufd xmm13,xmm13, 0x00

    psubd xmm1, xmm9                               #do calculations
    psubd xmm2, xmm10
    psubd xmm3, xmm11
    psubd xmm4, xmm12

    cvtdq2ps xmm1, xmm1                            #convert to floats
    cvtdq2ps xmm2, xmm2
    cvtdq2ps xmm3, xmm3
    cvtdq2ps xmm4, xmm4
    cvtdq2ps xmm5, xmm5
    cvtdq2ps xmm6, xmm6
    cvtdq2ps xmm7, xmm7
    cvtdq2ps xmm8, xmm8
    cvtdq2ps xmm13, xmm13

    mulps xmm1, xmm5                               #continue calculations
    mulps xmm2, xmm6
    mulps xmm3, xmm7
    mulps xmm4, xmm8

    divps xmm1, xmm13
    divps xmm2, xmm13
    divps xmm3, xmm13
    divps xmm4, xmm13

    cvtps2dq xmm1, xmm1                            #convert back to packed integers
    cvtps2dq xmm2, xmm2
    cvtps2dq xmm3, xmm3
    cvtps2dq xmm4, xmm4

    paddd xmm1, xmm9                               #continue calculations
    paddd xmm2, xmm10
    paddd xmm3, xmm11
    paddd xmm4, xmm12

    pshufb xmm1, xmm14                             #convert back to bytes
    pshufd xmm15, xmm14, 0b11110011                #modify mask
    pshufb xmm2, xmm15                             #convert back to bytes
    pshufd xmm15, xmm14, 0b11001111                #modify mask
    pshufb xmm3, xmm15                             #convert back to bytes
    pshufd xmm15, xmm14, 0b00111111                #modify mask
    pshufb xmm4, xmm15                             #convert back to bytes

    paddb xmm1, xmm2                               #join the fragmented values back to xmm1
    paddb xmm3, xmm4
    paddb xmm1, xmm3

    movdqu [rcx + r13], xmm1                       #store values

    add r12d, 16                                   #increase pointers to input and output by 16
    add r13d, 16

    sub r10w, 16                                   #decrease pointers to loop by 16
    jmp .LloopDenSimdX
.LloopDenXend:

    inc r12d                                       #increase pointer to input
    inc r11w                                       #increase pointer to outer loop
    jmp .LloopDenY
.LloopDenYend:

    pop r13                                        #restore r13 and 12
    pop r12

    ret



greyScaleConvert_SIMD:

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
#float ftemp5    : xmm7
#float ftemp6    : xmm8

#mask1           : xmm9
#mask2           : xmm10

#int x           : r8w
#int y           : r9w
#iCounter        : r10d
#oCounter        : r11d



    push r12                                       #store r12 to stack
    xor r10, r10
    xor r11, r11

    xorps xmm6, xmm6                               #precompute constA+constB+constC
    addss xmm6, xmm0
    addss xmm6, xmm1
    addss xmm6, xmm2
    
    pshufd xmm8, xmm6, 0x00                        #precompute packed float version

    pshufd xmm11, xmm0, 0x00                       #precompute packed constA, constB and constC
    pshufd xmm12, xmm1, 0x00
    pshufd xmm13, xmm2, 0x00
    
    mov rax, 0xffffff03ffffff00                    #precompute first mask. Takes first, fourth, seventh and tenth elements and convert into packed dwords
    movq xmm9, rax
    mov rax, 0xffffff09ffffff06
    pinsrq xmm9, rax, 1

    mov rax, 0xffffffff0c080400                    #precompute second mask. convert everything back to 4 bytes
    movq xmm10, rax
    mov rax, 0xffffffffffffffff
    pinsrq xmm10, rax, 1

    lea r8, [rsi + 1]
.LloopGreX1:                                       #fill in first padding
    test r8w, 15                                   #fill zero one by one until r8w divisible by 16
    jz .LloopGreSimdX1

    mov byte ptr [rcx + r11], 0
    inc r11d

    dec r8w
    jmp .LloopGreX1
.LloopGreSimdX1:
    test r8w, r8w                                  #fill zero 16 at a time until r8w == 0
    jz .LloopGreX1end

    xorps xmm7, xmm7
    movdqu [rcx + r11], xmm7
    add r11d, 16

    sub r8w, 16
    jmp .LloopGreSimdX1
.LloopGreX1end:

    xor r9, r9
.LloopGreY1:                                       #do greyscaling whilst padding
    cmp r9w, dx
    jge .LloopGreY1end

    mov byte ptr [rcx + r11], 0
    inc r11d

    mov r8, rsi
.LloopGreSimdX2:                                   #do calculations with simd registers until r8 is less than 4
    cmp r8w, 4
    jl .LloopGreX2

    movdqu xmm3, [rdi + r10]                       #load values with rd10 offset and shuffle with mask from xmm9 (1st,4th,7th,10th elements)
    pshufb xmm3, xmm9
    cvtdq2ps xmm3, xmm3
    movdqu xmm4, [rdi + r10 + 1]                   #load values with rd10 + 1 offset and shuffle with mask from xmm9 (1st,4th,7th,10th elements)
    pshufb xmm4, xmm9
    cvtdq2ps xmm4, xmm4
    movdqu xmm5, [rdi + r10 + 2]                   #load values with rd10 + 2 offset and shuffle with mask from xmm9 (1st,4th,7th,10th elements)
    pshufb xmm5, xmm9
    cvtdq2ps xmm5, xmm5                            #convert to packed floats
    mulps xmm3, xmm11                              #do calculations
    mulps xmm4, xmm12
    mulps xmm5, xmm13
    addps xmm3, xmm4
    addps xmm3, xmm5
    divps xmm3, xmm8
    cvtps2dq xmm3, xmm3                            #convert to packed integers
    pshufb xmm3, xmm10                             #convert back to 4 bytes with mask xmm10
    movdqu [rcx + r11], xmm3                       #store to rcx
    add r11d, 4                                    #output offset + 4, input offset + 12
    add r10d, 12

    sub r8w, 4                                     #loop counter - 4
    jmp .LloopGreSimdX2
.LloopGreX2:
    test r8w, r8w                                  #do calculations with normal register until counter == 0
    jz .LloopGreX2end

    movzx rax, byte ptr [rdi + r10]                #load values from offset r10
    cvtsi2ss xmm3, rax
    movzx rax, byte ptr [rdi + r10 + 1]            #load values from offset r10 + 1
    cvtsi2ss xmm4, rax
    movzx rax, byte ptr [rdi + r10 + 2]            #load values from offset r10 + 2
    cvtsi2ss xmm5, rax                             #convert to float
    mulss xmm3, xmm0                               #do calculations
    mulss xmm4, xmm1
    mulss xmm5, xmm2
    addss xmm3, xmm4
    addss xmm3, xmm5
    divss xmm3, xmm6
    cvtss2si rax, xmm3                             #convert to integers
    mov [rcx + r11], al                            #store values to rcx
    inc r11d                                       #increase pointer to output by 1
    add r10d, 3                                    #increase pointer to input by 3

    dec r8w                                        #decrease pointer to loop counter
    jmp .LloopGreX2
.LloopGreX2end:

    inc r9w                                        #increase pointer to outer loop counter
    jmp .LloopGreY1
.LloopGreY1end:

    lea r8, [rsi + 1]
.LloopGreX3:                                       #fill in second paddings
    test r8w, 15                                   #fill zero one by one until r8w divisible by 16
    jz .LloopGreSimdX3

    mov byte ptr [rcx + r11], 0
    inc r11d

    dec r8w
    jmp .LloopGreX3
.LloopGreSimdX3:
    test r8w, r8w                                  #fill zero 16 at a time until r8w == 0
    jz .LloopGreX3end

    xorps xmm7, xmm7
    movdqu [rcx + r11], xmm7
    add r11d, 16

    sub r8w, 16
    jmp .LloopGreSimdX3
.LloopGreX3end:

    mov byte ptr [rcx + r11], 0                    #last pad~

    pop r12   #restore r12
    ret


laplaceFilter_SIMD:

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

#temps           : xmm0-xmm6
#mask1           : xmm7
#mask2           : xmm8


    push r12   #store r12 and r13 in stack
    push r13

    mov rax, 0x0e0c0a0806040200                    #first mask. Convert 8 words into bytes and move them all at the top
    movq xmm7, rax
    mov rax, 0xffffffffffffffff
    pinsrq xmm7, rax, 1

    mov rax, 0xffffffffffffffff                    #second mask. Convert 8 words into bytes and move them all at the bottom
    movq xmm8, rax
    mov rax, 0x0e0c0a0806040200
    pinsrq xmm8, rax, 1

    lea r10, [rsi + 2]                             #r10 = width + 2

    xor r9, r9
.LloopLapY:                                        #start outer loop
    cmp r9w, dx
    jge .LloopLapYend

    mov r8, rsi
.LloopLapX:                                        #do calculations with regular registers first until r8w is divisible by 16
    test r8w, 15
    jz .LloopLapXSimd
    
    lea rax, [r10 + rsi + 1]
    movzx r11, byte ptr [rdi + rax]                #load value from offset + width + 1

    mov rax, rsi
    neg rax
    lea rax, [r10 + rax - 1]
    movzx r13, byte ptr [rdi + rax]                #load value from offset - width - 1
    add r11w, r13w                                 #add them up

    movzx r13, byte ptr [rdi + r10 + 1]            #load value from offset + 1
    add r11w, r13w                                 #add them up

    movzx r13, byte ptr [rdi + r10 - 1]            #load value from offset - 1
    add r11w, r13w                                 #add them up

    movzx r13, byte ptr [rdi + r10]                #load value from offset times 4
    lea r12, [r13 * 4]

    sub r11w, r12w                                 #(up+left+right+down) - 4*center
    cmp r11w, 0                                    #if negative -> times -1
    jge .LcontLap
    neg r11w
.LcontLap:

    mov [rcx + r10], r11b                          #store values to result array

    inc r10d                                       #increase input output counter by 1
    dec r8w                                        #decrease loop counter by 1
    jmp .LloopLapX

.LloopLapXSimd:
    test r8w, r8w                                  #do calculations with simd until r8w == 0
    jz .LloopLapXend

    xorps xmm0, xmm0

    movdqu xmm3, [rdi + r10]                       #load value from offset
    movdqa xmm4, xmm3
    punpcklbw xmm3, xmm0                           #convert 16 byte values to 16 words across 2 registers
    punpckhbw xmm4, xmm0
    psllw xmm3, 2                                  #times 4
    psllw xmm4, 2

    lea rax, [r10 + rsi + 1]
    movdqu xmm1, [rdi + rax]                       #load value from offset + width + 1
    movdqa xmm2, xmm1
    punpcklbw xmm1, xmm0                           #convert 16 byte values to 16 words across 2 registers
    punpckhbw xmm2, xmm0

    mov rax, rsi
    neg rax
    lea rax, [r10 + rax - 1]
    movdqu xmm5, [rdi + rax]                       #load value from offset - width - 1
    movdqa xmm6, xmm5
    punpcklbw xmm5, xmm0                           #convert 16 byte values to 16 words across 2 registers
    punpckhbw xmm6, xmm0

    paddw xmm1, xmm5                               #add them up
    paddw xmm2, xmm6
    
    movdqu xmm5, [rdi + r10 + 1]                   #load value from offset + 1
    movdqa xmm6, xmm5
    punpcklbw xmm5, xmm0                           #convert 16 byte values to 16 words across 2 registers
    punpckhbw xmm6, xmm0

    paddw xmm1, xmm5                               #add them up
    paddw xmm2, xmm6

    movdqu xmm5, [rdi + r10 - 1]                   #load value from offset - 1
    movdqa xmm6, xmm5
    punpcklbw xmm5, xmm0                           #convert 16 byte values to 16 words across 2 registers
    punpckhbw xmm6, xmm0

    paddw xmm1, xmm5                               #add them up
    paddw xmm2, xmm6

    psubw xmm1, xmm3                               #(up+left+right+down) - 4*center
    psubw xmm2, xmm4

    pabsw xmm3, xmm1                               #absoluted
    pabsw xmm4, xmm2


    pshufb xmm3, xmm7                              #convert back to bytes with mask xmm7 and xmm8
    pshufb xmm4, xmm8

    paddb xmm3,xmm4                                #join 2 registers back to 1

    movdqu [rcx + r10], xmm3                       #store the values to result array

    add r10d, 16                                   #increase input output counter by 16
    sub r8w, 16                                    #decrease loop counter by 16
    jmp .LloopLapXSimd

.LloopLapXend:

    inc r10d                                       #increase inpu output counter by 1
    inc r9w                                        #increase outer loop counter by 1
    jmp .LloopLapY
.LloopLapYend:

    pop r13                                        #restore r13 and r12
    pop r12
    ret



softFocus_SIMD:

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

    push r12                                       #store r12 and r13 in stack
    push r13

    mov rax, 0x0e0c0a0806040200                    #first mask. Convert 8 words into bytes and move them all at the top
    movq xmm7, rax
    mov rax, 0xffffffffffffffff
    pinsrq xmm7, rax, 1

    mov rax, 0xffffffffffffffff                    #second mask. Convert 8 words into bytes and move them all at the bottom
    movq xmm8, rax
    mov rax, 0x0e0c0a0806040200
    pinsrq xmm8, rax, 1

    lea r10, [rsi + 2]                             #r10 = width + 2

    xor r9, r9
.LloopSofY:                                        #start outer loop
    cmp r9w, dx
    jge .LloopSofYend

    mov r8, rsi
.LloopSofX:                                       #do calculations with regular registers first until r8w is divisible by 16
    test r8w, 15
    jz .LloopSofXSimd
    
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
    shr r11, 4   #divide by 16
    
    mov [rcx + r10], r11b                         #store at result array

    inc r10d                                      #increase input output counter by 1
    dec r8w                                       #decrease loop counter by 1
    jmp .LloopSofX

.LloopSofXSimd:                                   #do calculation with simd registers until r8 == 0
    test r8w, r8w
    jz .LloopSofXend

    xorps xmm0, xmm0

    lea rax, [r10 + rsi + 1]                      #save offset + width + 1
    movdqu xmm1, [rdi + rax]                      #load from offset + width + 1
    movdqa xmm2, xmm1
    punpcklbw xmm1, xmm0                          #convert bytes to words across 2 registers
    punpckhbw xmm2, xmm0

    movdqu xmm3, [rdi + rax + 1]                  #load from offset + width + 2
    movdqa xmm4, xmm3
    punpcklbw xmm3, xmm0                          #convert bytes to words across 2 registers
    punpckhbw xmm4, xmm0

    movdqu xmm5, [rdi + rax - 1]                  #load from offset + width
    movdqa xmm6, xmm5
    punpcklbw xmm5, xmm0                          #convert bytes to words across 2 registers
    punpckhbw xmm6, xmm0

    paddw xmm3, xmm5                              #add the last 2
    paddw xmm4, xmm6

    mov rax, rsi
    neg rax
    lea rax, [r10 + rax - 1]                      #save offset - width - 1
    movdqu xmm5, [rdi + rax]                      #load from offset - width - 1
    movdqa xmm6, xmm5
    punpcklbw xmm5, xmm0                          #convert bytes to words across 2 registers
    punpckhbw xmm6, xmm0

    paddw xmm1, xmm5                              #add to xmm1 and xmm2
    paddw xmm2, xmm6

    movdqu xmm5, [rdi + rax + 1]                  #load from offset - width
    movdqa xmm6, xmm5
    punpcklbw xmm5, xmm0                          #convert bytes to words across 2 registers
    punpckhbw xmm6, xmm0

    paddw xmm3, xmm5                              #add to xmm3 and xmm4
    paddw xmm4, xmm6

    movdqu xmm5, [rdi + rax - 1]                  #load from offset - width - 2
    movdqa xmm6, xmm5
    punpcklbw xmm5, xmm0                          #convert bytes to words across 2 registers
    punpckhbw xmm6, xmm0

    paddw xmm3, xmm5                              #add to xmm3 and xmm4
    paddw xmm4, xmm6
    
    movdqu xmm5, [rdi + r10 + 1]                  #load from offset + 1
    movdqa xmm6, xmm5
    punpcklbw xmm5, xmm0                          #convert bytes to words across 2 registers
    punpckhbw xmm6, xmm0

    paddw xmm1, xmm5                              #add to xmm1 and xmm2
    paddw xmm2, xmm6

    movdqu xmm5, [rdi + r10 - 1]                  #load from offset - 1
    movdqa xmm6, xmm5
    punpcklbw xmm5, xmm0                          #convert bytes to words across 2 registers
    punpckhbw xmm6, xmm0

    paddw xmm1, xmm5                              #add to xmm1 and xmm2
    paddw xmm2, xmm6

    psllw xmm1, 1                                 #(xmm3_xmm4) + 2*(xmm1_xmm2)
    psllw xmm2, 1

    paddw xmm1, xmm3
    paddw xmm2, xmm4

    movdqu xmm5, [rdi + r10]                      #load from offset
    movdqa xmm6, xmm5
    punpcklbw xmm5, xmm0                          #convert bytes to words across 2 registers
    punpckhbw xmm6, xmm0

    psllw xmm5, 2                                 #(xmm3_xmm4) + 2*(xmm1_xmm2) + 4*(xmm5_xmm6)
    psllw xmm6, 2
    paddw xmm1, xmm5
    paddw xmm2, xmm6

    psrlw xmm1, 4                                 #divide by 16
    psrlw xmm2, 4

    pshufb xmm1, xmm7                             #convert words back to bytes and join both registers
    pshufb xmm2, xmm8
    paddb xmm1,xmm2

    movdqu [rcx + r10], xmm1                      #store at result array

    add r10d, 16                                  #increase input output counter by 16
    sub r8w, 16                                   #decrease loop counter by 16
    jmp .LloopSofXSimd

.LloopSofXend:

    inc r10d                                      #increase input output counter by 1
    inc r9w                                       #increase outer loop counter by 1
    jmp .LloopSofY
.LloopSofYend:

    pop r13                                       #restore r12 and r13
    pop r12
    ret