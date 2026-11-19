;
; checksum.asm - the one's complement internet checksum.
;
; This is your starting point. It assembles and links as-is, so the build
; works before you write any code. Right now it always returns 0, which
; makes every header decode as VALID. The decode path sums the header as it
; stands and tests for zero, so a routine that returns 0 says "valid" for
; everything. Your job is to replace that with the sum described below.
;
; The contract, from driver.c:
;
;       int len                   [ebp+12]
;       unsigned char *hdr        [ebp+8]
;
; Sum len bytes of hdr as len/2 16-bit big-endian words into a 32-bit
; accumulator. Fold the carries until the result fits in 16 bits. Return
; the one's complement of that in ax. The manual's worked example is the
; test. Zero the checksum field, sum the sample header, and you must get
; 0x9CBC.
;
; The decode path calls this over the header as it stands, checksum field
; included. A valid header returns 0 and an invalid one does not. The
; encode path calls it over a header whose checksum field you wrote as zero.
; One routine serves both uses. You don't need to know which one called
; you.
;
; Do not clobber ebx, esi, edi, or ebp. C assumes they survive your call.
;

; Windows C puts a leading underscore on every exported name. Linux C does
; not. The Makefile passes -d ELF_TYPE on Linux. This block then respells
; the names below to match. asm_io.inc does the same for _asm_main in the
; bootcamp blocks. Leave this block alone.
%ifdef ELF_TYPE
  %define _ip_checksum ip_checksum
  section .note.GNU-stack noalloc noexec nowrite progbits
%endif

segment .text
        global  _ip_checksum
_ip_checksum:
        enter   0,0
        push    esi                     ; the only callee-saved register used
        mov     esi, [ebp+8]            ; hdr
        mov     ecx, [ebp+12]           ; len, always even
        xor     edx, edx                ; 32-bit sum, so carries out of bit 15 are kept

.sum:   jecxz   .done
        movzx   eax, byte [esi]         ; high byte first: network order, not x86 order
        shl     eax, 8
        mov     al, [esi+1]             ; low byte drops into the zeroed bottom 8 bits
        add     edx, eax
        add     esi, 2
        sub     ecx, 2
        jmp     .sum

.done:  mov     eax, edx
        shr     eax, 16                 ; carries above bit 15
        jz      .out
        movzx   edx, dx                 ; keep the low half
        add     edx, eax                ; end-around carry; can carry again, so loop
        jmp     .done

.out:   mov     eax, edx
        not     ax                      ; one's complement; driver reads ax
        pop     esi
        leave
        ret