; lfsr_stream_unicode.asm
; Ћ–: потоковое шифрование, LFSR, m=29, P(x)=x^29+x^2+1

format PE GUI 4.0
entry start

include 'win32w.inc'

WM_COMMAND          equ 111h
IDC_EDIT_SEED       equ 1001
IDC_BTN_OPEN        equ 1002
IDC_BTN_ENC         equ 1003
IDC_BTN_DEC         equ 1004
IDC_EDIT_SRC        equ 2001
IDC_EDIT_KEY        equ 2002
IDC_EDIT_DST        equ 2003
IDC_BTN_SAVE        equ 1005
IDC_BTN_CLEAR       equ 1006
MAX_SEED_LEN        equ 32
MAX_SHOW_BYTES      equ 128

section '.data' data readable writeable

WC_STATIC           du 'STATIC',0
WC_EDIT             du 'EDIT',0
WC_BUTTON           du 'BUTTON',0

class_name          du 'LFSRWinClass',0
win_title           du 'LFSR stream cipher (deg=29)',0
txt_seed            du 'Seed (29 bits):',0
txt_open            du 'Open file',0
txt_encrypt         du 'Encrypt',0
txt_decrypt         du 'Decrypt',0
txt_clear           du 'Clear',0
txt_src             du 'Source (bin):',0
txt_key             du 'Key (bin):',0
txt_dst             du 'Cipher (bin):',0
txt_save            du 'Save result',0
save_dialog_title   du 'Save encrypted/decrypted file',0
filter_save         du 'Binary files',0,'*.bin',0,'All files',0,'*.*',0,0
defext              du 'bin',0
filter_str          du 'All files',0,'*.*',0,0
open_dialog_title   du 'Open file',0
msg_invalid_seed    du 'Seed must be 29 bits of 0/1',0
msg_file_err        du 'File error or no file',0
msg_ok              du 'Done',0
msg_invalid_bin     du 'Only 0 and 1 allowed in Source!',0
msg_not_mult8       du 'Bit count must be multiple of 8!',0

ofn                 OPENFILENAME
wc                  WNDCLASSEX
msg_struct          MSG

hInstance           dd ?
hwnd_main           dd ?
hEditSeed           dd ?
hBtnOpen            dd ?
hBtnEnc             dd ?
hBtnDec             dd ?
hEditSrc            dd ?
hEditKey            dd ?
hEditDst            dd ?
hFileIn             dd ?
hFileOut            dd ?
fileSize            dd ?
pSrcBuf             dd ?
pKeyBuf             dd ?
pDstBuf             dd ?
bytesRW             dd ?

seed_buffer         rw MAX_SEED_LEN
seed_len            dd ?
lfsr_state          dd ?

hEditSrcOldProc     dd ?
pTmpBuf             dd ?


bin_src_buf         rw (MAX_SHOW_BYTES*9+1)
bin_key_buf         rw (MAX_SHOW_BYTES*9+1)
bin_dst_buf         rw (MAX_SHOW_BYTES*9+1)

out_name_enc        du 'output_enc.bin',0
out_name_dec        du 'output_dec.bin',0
file_name           rw 260
file_title          rw 260
save_name           rw 260

section '.code' code readable executable

start:
    invoke GetModuleHandleW,0
    mov [hInstance],eax

    mov eax,sizeof.WNDCLASSEX
    mov [wc.cbSize],eax
    mov [wc.style],CS_HREDRAW or CS_VREDRAW
    mov [wc.lpfnWndProc],WindowProc
    mov [wc.cbClsExtra],0
    mov [wc.cbWndExtra],0
    mov eax,[hInstance]
    mov [wc.hInstance],eax
    invoke LoadIconW,0,IDI_APPLICATION
    mov [wc.hIcon],eax
    invoke LoadCursorW,0,IDC_ARROW
    mov [wc.hCursor],eax
    mov [wc.hbrBackground],COLOR_BTNFACE+1
    mov [wc.lpszMenuName],0
    mov [wc.lpszClassName],class_name
    mov [wc.hIconSm],0

    invoke RegisterClassExW,wc
    test eax,eax
    jz .exit

    invoke CreateWindowExW,0,class_name,win_title,\
           WS_OVERLAPPEDWINDOW or WS_VISIBLE,\
           CW_USEDEFAULT,CW_USEDEFAULT,820,640,\
           0,0,[hInstance],0
    mov [hwnd_main],eax

.msg_loop:
    invoke GetMessageW,msg_struct,0,0,0
    test eax,eax
    jz .exit
    invoke TranslateMessage,msg_struct
    invoke DispatchMessageW,msg_struct
    jmp .msg_loop

.exit:
    invoke ExitProcess,0

; ---- GUI -------------------------------------------------------
proc WindowProc hwnd,wmsg,wparam,lparam
    locals
      command dw ?
    endl

    mov eax,[wmsg]
    cmp eax,WM_CREATE
    je .on_create
    cmp eax,WM_COMMAND
    je .on_command
    cmp eax,WM_DESTROY
    je .on_destroy
    cmp eax,IDC_BTN_CLEAR
    je .do_clear
.def:
    invoke DefWindowProcW,[hwnd],[wmsg],[wparam],[lparam]
    ret

.on_create:
    invoke CreateWindowExW,0,WC_STATIC,txt_seed,\
           WS_CHILD or WS_VISIBLE,\
           10,10,140,20,[hwnd],0,[hInstance],0

    invoke CreateWindowExW,WS_EX_CLIENTEDGE,WC_EDIT,0,\
           WS_CHILD or WS_VISIBLE or ES_AUTOHSCROLL,\
           160,10,250,20,[hwnd],IDC_EDIT_SEED,[hInstance],0
    mov [hEditSeed],eax


    invoke CreateWindowExW,0,WC_BUTTON,txt_open,\
           WS_CHILD or WS_VISIBLE,\
           10,40,100,25,[hwnd],IDC_BTN_OPEN,[hInstance],0
    invoke CreateWindowExW,0,WC_BUTTON,txt_encrypt,\
           WS_CHILD or WS_VISIBLE,\
           120,40,100,25,[hwnd],IDC_BTN_ENC,[hInstance],0
    invoke CreateWindowExW,0,WC_BUTTON,txt_decrypt,\
           WS_CHILD or WS_VISIBLE,\
           230,40,100,25,[hwnd],IDC_BTN_DEC,[hInstance],0

    invoke CreateWindowExW,0,WC_BUTTON,txt_save,\
           WS_CHILD or WS_VISIBLE,\
           340,40,110,25,[hwnd],IDC_BTN_SAVE,[hInstance],0
    invoke CreateWindowExW,0,WC_BUTTON,txt_clear,\
       WS_CHILD or WS_VISIBLE,\
       460,40,80,25,[hwnd],IDC_BTN_CLEAR,[hInstance],0

    invoke CreateWindowExW,0,WC_STATIC,txt_src,\
           WS_CHILD or WS_VISIBLE,10,80,150,20,[hwnd],0,[hInstance],0
    invoke CreateWindowExW,0,WC_STATIC,txt_key,\
           WS_CHILD or WS_VISIBLE,10,230,150,20,[hwnd],0,[hInstance],0
    invoke CreateWindowExW,0,WC_STATIC,txt_dst,\
           WS_CHILD or WS_VISIBLE,10,380,150,20,[hwnd],0,[hInstance],0

    ; Source: ????? ??????, ??????? ?????, ??? ??????? ?? ???????????
    invoke CreateWindowExW,WS_EX_CLIENTEDGE,WC_EDIT,0,\
       WS_CHILD or WS_VISIBLE or ES_MULTILINE or ES_AUTOVSCROLL or WS_VSCROLL,\
       10,100,780,120,[hwnd],IDC_EDIT_SRC,[hInstance],0
    mov [hEditSrc],eax

    invoke SetWindowLongW,[hEditSrc],GWL_WNDPROC,EditSrcProc
    mov [hEditSrcOldProc],eax

    ; Key: ?????? ??????
    invoke CreateWindowExW,WS_EX_CLIENTEDGE,WC_EDIT,0,\
           WS_CHILD or WS_VISIBLE or ES_MULTILINE or ES_AUTOVSCROLL or WS_VSCROLL or ES_READONLY,\
           10,250,780,120,[hwnd],IDC_EDIT_KEY,[hInstance],0
    mov [hEditKey],eax

    ; Cipher: ?????? ??????
    invoke CreateWindowExW,WS_EX_CLIENTEDGE,WC_EDIT,0,\
           WS_CHILD or WS_VISIBLE or ES_MULTILINE or ES_AUTOVSCROLL or WS_VSCROLL or ES_READONLY,\
           10,400,780,120,[hwnd],IDC_EDIT_DST,[hInstance],0
    mov [hEditDst],eax

    xor eax,eax
    ret

.on_destroy:
    invoke PostQuitMessage,0
    xor eax,eax
    ret

.on_command:
    mov eax,[wparam]
    and eax,0FFFFh
    cmp eax,IDC_BTN_OPEN
    je .do_open
    cmp eax,IDC_BTN_ENC
    je .do_enc
    cmp eax,IDC_BTN_DEC
    je .do_dec
    cmp eax,IDC_BTN_SAVE
    je .do_save
    jmp .def

.do_open:
    call OpenInputFile
    call UpdateBinaryViewSrc
    xor eax,eax
    ret

.do_enc:
    call ProcessFileEncrypt
    xor eax,eax
    ret

.do_dec:
    call ProcessFileDecrypt
    xor eax,eax
    ret

.do_save:
    call SaveResultFile
    xor eax,eax
    ret

.do_clear:
    ; ???????? ???
    cmp [pSrcBuf],0
    je @f
    invoke GlobalFree,[pSrcBuf]
    mov [pSrcBuf],0
@@:
    cmp [pKeyBuf],0
    je @f
    invoke GlobalFree,[pKeyBuf]
    mov [pKeyBuf],0
@@:
    cmp [pDstBuf],0
    je @f
    invoke GlobalFree,[pDstBuf]
    mov [pDstBuf],0
@@:
    mov [fileSize],0
    invoke SetWindowTextW,[hEditSrc],0
    invoke SetWindowTextW,[hEditKey],0
    invoke SetWindowTextW,[hEditDst],0
    xor eax,eax
    ret
endp

; ---- Ћќ√» ј LFSR -----------------------------------------------

proc InitLFSR
    invoke GetWindowTextLengthW,[hEditSeed]
    mov [seed_len],eax
    cmp eax,29
    jne .bad

    invoke GetWindowTextW,[hEditSeed],seed_buffer,MAX_SEED_LEN

    xor ecx,ecx
    xor edx,edx
.next:
    cmp ecx,[seed_len]
    jge .ok
    movzx eax,word [seed_buffer+ecx*2]
    cmp eax,'0'
    jb .bad
    cmp eax,'1'
    ja .bad
    shl edx,1
    cmp eax,'1'
    jne .zero
    or edx,1
.zero:
    inc ecx
    jmp .next

.ok:
    ; запрещаем нулевое начальное состо€ние
    test edx,edx
    jz .bad
    mov [lfsr_state],edx
    xor eax,eax
    ret

.bad:
    invoke MessageBoxW,[hwnd_main],msg_invalid_seed,win_title,MB_ICONERROR or MB_OK
    mov eax,1
    ret
endp

; -------------------------------------------------------
; FIX 1,2,3: сдвиг ¬Ћ≈¬ќ + маска 29 бит + сохранение регистров
; P(x) = x^29 + x^2 + 1
; —хема (по методичке): сдвиг ¬Ћ≈¬ќ, выход = b_m = bit28 (ƒќ сдвига)
; feedback = b_29 XOR b_2 = bit28 XOR bit1
; новый bit0 = feedback
; -------------------------------------------------------
proc LFSR_Step
    push ebx
    push ecx
    push edx

    mov edx,[lfsr_state]

    ; выходной бит = b_29 = bit28 (ƒќ сдвига)
    mov eax,edx
    shr eax,28
    and eax,1

    ; b_2 = bit1
    mov ecx,edx
    shr ecx,1
    and ecx,1

    ; feedback = b_29 XOR b_2
    mov ebx,eax
    xor ebx,ecx

    ; FIX 1: сдвиг ¬Ћ≈¬ќ (shl, не shr!)
    shl edx,1
    ; FIX 2: маска 29 бит (убираем бит 29 и выше)
    and edx,1FFFFFFFh
    ; записываем feedback в bit0
    or edx,ebx

    mov [lfsr_state],edx

    pop edx
    pop ecx
    pop ebx
    ret
endp


proc LFSR_Byte
    push ecx
    push ebx
    xor ecx,ecx
    xor ebx,ebx
.next_bit:
    call LFSR_Step      ; возвращает бит в EAX; EBX/ECX/EDX сохран€ет сам
    shl ebx,1
    or ebx,eax
    inc ecx
    cmp ecx,8
    jl .next_bit
    mov eax,ebx
    pop ebx
    pop ecx
    ret
endp

; ---- ‘айлы -----------------------------------------------------

proc OpenInputFile
    mov eax,sizeof.OPENFILENAME
    mov [ofn.lStructSize],eax
    mov eax,[hwnd_main]
    mov [ofn.hwndOwner],eax
    mov [ofn.lpstrFilter],filter_str
    mov [ofn.lpstrFile],file_name
    mov word [file_name],0
    mov [ofn.nMaxFile],260
    mov [ofn.lpstrFileTitle],file_title
    mov [ofn.nMaxFileTitle],260
    mov [ofn.lpstrTitle],open_dialog_title
    mov [ofn.Flags],OFN_FILEMUSTEXIST or OFN_HIDEREADONLY

    invoke GetOpenFileNameW,ofn
    test eax,eax
    jz .ret

    invoke CreateFileW,file_name,GENERIC_READ,FILE_SHARE_READ,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
    cmp eax,INVALID_HANDLE_VALUE
    je .err
    mov [hFileIn],eax

    invoke GetFileSize,[hFileIn],0
    mov [fileSize],eax

    invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,[fileSize]
    mov [pSrcBuf],eax
    invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,[fileSize]
    mov [pKeyBuf],eax
    invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,[fileSize]
    mov [pDstBuf],eax

    ; FIX 6: bytesRW Ч глобальный DWORD, не локальна€ db
    invoke ReadFile,[hFileIn],[pSrcBuf],[fileSize],bytesRW,0

    invoke CloseHandle,[hFileIn]
    jmp .ret

.err:
    invoke MessageBoxW,[hwnd_main],msg_file_err,win_title,MB_ICONERROR or MB_OK
.ret:
    ret
endp

proc ProcessFileCore useEnc
    ; ???? ????? ?????? Ч ?????? ?? Source EDIT
    cmp [pSrcBuf],0
    jne .has_data
    call ReadSourceFromEdit
    cmp eax,1
    je .ret

.has_data:
    call InitLFSR
    cmp eax,1
    je .ret

    mov esi,[pSrcBuf]
    mov edi,[pKeyBuf]
    mov ebx,[pDstBuf]
    mov ecx,[fileSize]

.gen_loop:
    cmp ecx,0
    je .gen_done
    call LFSR_Byte
    mov dl,al
    mov [edi],dl
    mov al,[esi]
    xor al,dl
    mov [ebx],al
    inc esi
    inc edi
    inc ebx
    dec ecx
    jmp .gen_loop

.gen_done:
    call UpdateTripleBinaryViews
    jmp .ret

.err:
    invoke MessageBoxW,[hwnd_main],msg_file_err,win_title,MB_ICONERROR or MB_OK
    jmp .ret

.no_file:
    invoke MessageBoxW,[hwnd_main],msg_file_err,win_title,MB_ICONERROR or MB_OK
.ret:
    ret
endp

proc SaveResultFile
    ; ??? ?????? ??? ???????????
    cmp [pDstBuf],0
    je .no_data

    ; ?????????? OPENFILENAME ??? SaveAs
    mov eax,sizeof.OPENFILENAME
    mov [ofn.lStructSize],eax
    mov eax,[hwnd_main]
    mov [ofn.hwndOwner],eax
    mov [ofn.lpstrFilter],filter_save
    mov [ofn.nFilterIndex],1
    mov [ofn.lpstrFile],save_name
    mov word [save_name],0
    mov [ofn.nMaxFile],260
    mov [ofn.lpstrFileTitle],0
    mov [ofn.nMaxFileTitle],0
    mov [ofn.lpstrTitle],save_dialog_title
    ; OFN_OVERWRITEPROMPT Ч ???????? ??????????, OFN_EXPLORER Ч ??????????? ???
    mov [ofn.Flags],OFN_OVERWRITEPROMPT or OFN_EXPLORER or OFN_NOCHANGEDIR
    mov [ofn.lpstrDefExt],defext   ; ????????? ?????????? .bin
    mov [ofn.lpfnHook],0
    mov [ofn.lpTemplateName],0
    mov [ofn.lCustData],0

    invoke GetSaveFileNameW,ofn
    test eax,eax
    jz .ret                    ; ???????????? ????? Cancel

    invoke CreateFileW,save_name,GENERIC_WRITE,0,0,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
    cmp eax,INVALID_HANDLE_VALUE
    je .err
    mov [hFileOut],eax

    invoke WriteFile,[hFileOut],[pDstBuf],[fileSize],bytesRW,0

    invoke CloseHandle,[hFileOut]
    invoke MessageBoxW,[hwnd_main],msg_ok,win_title,MB_OK
    jmp .ret

.no_data:
    invoke MessageBoxW,[hwnd_main],msg_file_err,win_title,MB_ICONERROR or MB_OK
    jmp .ret

.err:
    invoke MessageBoxW,[hwnd_main],msg_file_err,win_title,MB_ICONERROR or MB_OK
.ret:
    ret
endp


proc ProcessFileEncrypt
    push 1
    call ProcessFileCore
    ret
endp

proc ProcessFileDecrypt
    push 0
    call ProcessFileCore
    ret
endp

; ---- Ѕинарный вывод --------------------------------------------

proc BytesToBinString
    push eax ebx edi
    mov edi,edx
    xor edx,edx
.next_byte:
    cmp edx,MAX_SHOW_BYTES
    jae .done
    cmp ecx,0
    je .done
    mov al,byte [esi+edx]
    mov bl,8
.bit_loop:
    shl al,1
    jc .bit1
    mov word [edi],'0'
    jmp .bit_next
.bit1:
    mov word [edi],'1'
.bit_next:
    add edi,2
    dec bl
    jnz .bit_loop
    mov word [edi],' '
    add edi,2
    inc edx
    dec ecx
    jmp .next_byte
.done:
    mov word [edi],0
    pop edi ebx eax
    ret
endp

proc UpdateBinaryViewSrc
    cmp [pSrcBuf],0
    je .ret
    mov esi,[pSrcBuf]
    mov ecx,[fileSize]
    mov edx,bin_src_buf
    call BytesToBinString
    invoke SetWindowTextW,[hEditSrc],bin_src_buf
.ret:
    ret
endp

proc UpdateTripleBinaryViews
    mov esi,[pSrcBuf]
    mov ecx,[fileSize]
    mov edx,bin_src_buf
    call BytesToBinString
    invoke SetWindowTextW,[hEditSrc],bin_src_buf

    mov esi,[pKeyBuf]
    mov ecx,[fileSize]
    mov edx,bin_key_buf
    call BytesToBinString
    invoke SetWindowTextW,[hEditKey],bin_key_buf

    mov esi,[pDstBuf]
    mov ecx,[fileSize]
    mov edx,bin_dst_buf
    call BytesToBinString
    invoke SetWindowTextW,[hEditDst],bin_dst_buf
    ret
endp

proc ReadSourceFromEdit
    ; освободить старые буферы
    cmp [pSrcBuf],0
    je @f
    invoke GlobalFree,[pSrcBuf]
    mov [pSrcBuf],0
@@:
    cmp [pKeyBuf],0
    je @f
    invoke GlobalFree,[pKeyBuf]
    mov [pKeyBuf],0
@@:
    cmp [pDstBuf],0
    je @f
    invoke GlobalFree,[pDstBuf]
    mov [pDstBuf],0
@@:
    cmp [pTmpBuf],0
    je @f
    invoke GlobalFree,[pTmpBuf]
    mov [pTmpBuf],0
@@:

    ; читаем текст из Source EDIT
    invoke GetWindowTextLengthW,[hEditSrc]
    test eax,eax
    jz .empty

    ; выдел€ем wchar буфер
    mov ecx,eax
    inc ecx
    shl ecx,1
    invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,ecx
    test eax,eax
    jz .err
    mov [pTmpBuf],eax

    invoke GetWindowTextLengthW,[hEditSrc]
    inc eax
    invoke GetWindowTextW,[hEditSrc],[pTmpBuf],eax

    ; --- ѕроход 1: считаем биты, провер€ем символы ---
    mov esi,[pTmpBuf]
    xor ecx,ecx         ; счЄтчик бит
.count_loop:
    movzx eax,word [esi]
    test eax,eax
    jz .count_done
    cmp eax,'0'
    je .count_bit
    cmp eax,'1'
    je .count_bit
    cmp eax,' '         ; пробел Ч разделитель, не считаем
    je .count_skip
    cmp eax,0Dh         ; \r
    je .count_skip
    cmp eax,0Ah         ; \n
    je .count_skip
    ; недопустимый символ
    jmp .bad_char
.count_bit:
    inc ecx
.count_skip:
    add esi,2
    jmp .count_loop
.count_done:

    test ecx,ecx
    jz .empty

    ; кратность 8?
    mov eax,ecx
    and eax,7
    test eax,eax
    jnz .not_mult8

    ; fileSize = кол-во байт
    shr ecx,3
    mov [fileSize],ecx

    ; выдел€ем буферы
    invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,[fileSize]
    test eax,eax
    jz .err
    mov [pSrcBuf],eax

    invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,[fileSize]
    test eax,eax
    jz .err
    mov [pKeyBuf],eax

    invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,[fileSize]
    test eax,eax
    jz .err
    mov [pDstBuf],eax

    ; --- ѕроход 2: парсим биты в байты ---
    mov esi,[pTmpBuf]
    mov edi,[pSrcBuf]
    xor ebx,ebx         ; текущий байт
    xor ecx,ecx         ; счЄтчик бит в байте (0..7)
.parse_loop:
    movzx eax,word [esi]
    test eax,eax
    jz .parse_done
    cmp eax,'0'
    je .parse_0
    cmp eax,'1'
    je .parse_1
    add esi,2           ; пробел/\r\n Ч пропускаем
    jmp .parse_loop
.parse_0:
    shl ebx,1           ; бит = 0
    add esi,2
    inc ecx
    cmp ecx,8
    je .flush_byte
    jmp .parse_loop
.parse_1:
    shl ebx,1
    or ebx,1            ; бит = 1
    add esi,2
    inc ecx
    cmp ecx,8
    je .flush_byte
    jmp .parse_loop
.flush_byte:
    mov [edi],bl
    inc edi
    xor ebx,ebx
    xor ecx,ecx
    jmp .parse_loop
.parse_done:

    invoke GlobalFree,[pTmpBuf]
    mov [pTmpBuf],0

    xor eax,eax
    ret

.bad_char:
    invoke MessageBoxW,[hwnd_main],msg_invalid_bin,win_title,MB_ICONERROR or MB_OK
    jmp .cleanup_err

.not_mult8:
    invoke MessageBoxW,[hwnd_main],msg_not_mult8,win_title,MB_ICONERROR or MB_OK
    jmp .cleanup_err

.empty:
    invoke MessageBoxW,[hwnd_main],msg_file_err,win_title,MB_ICONERROR or MB_OK
    jmp .cleanup_err

.err:
    invoke MessageBoxW,[hwnd_main],msg_file_err,win_title,MB_ICONERROR or MB_OK

.cleanup_err:
    cmp [pTmpBuf],0
    je @f
    invoke GlobalFree,[pTmpBuf]
    mov [pTmpBuf],0
@@:
    mov eax,1
    ret
endp

proc CleanSourceEdit
    ; ?????? ???? ?????
    invoke GetWindowTextLengthW,[hEditSrc]
    test eax,eax
    jz .ret

    mov ecx,eax
    inc ecx
    shl ecx,1
    invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,ecx
    test eax,eax
    jz .ret
    mov [pTmpBuf],eax

    invoke GetWindowTextLengthW,[hEditSrc]
    inc eax
    invoke GetWindowTextW,[hEditSrc],[pTmpBuf],eax

    ; ????????? Ч ????????? ?????? 0, 1, ??????, \r, \n
    mov esi,[pTmpBuf]
    mov edi,[pTmpBuf]   ; ????? ??????
.loop:
    movzx eax,word [esi]
    test eax,eax
    jz .done
    cmp eax,'0'
    je .keep
    cmp eax,'1'
    je .keep
    cmp eax,' '
    je .keep
    cmp eax,0Dh
    je .keep
    cmp eax,0Ah
    je .keep
    ; ???????????? ?????? Ч ??????????
    add esi,2
    jmp .loop
.keep:
    mov word [edi],ax
    add esi,2
    add edi,2
    jmp .loop
.done:
    mov word [edi],0

    invoke SetWindowTextW,[hEditSrc],[pTmpBuf]

    invoke GlobalFree,[pTmpBuf]
    mov [pTmpBuf],0
.ret:
    ret
endp


proc EditSrcProc hwnd,wmsg,wparam,lparam
    mov eax,[wmsg]
    cmp eax,WM_CHAR
    jne .passthrough

    movzx eax,word[wparam]
    cmp eax,'0'
    je .allow
    cmp eax,'1'
    je .allow
    cmp eax,' '     ; пробел Ч визуальный разделитель, разрешЄн
    je .allow
    cmp eax,8       ; Backspace
    je .allow
    cmp eax,0Dh     ; Enter
    je .allow
    cmp eax,01h     ; Ctrl+A
    je .allow
    cmp eax,03h     ; Ctrl+C
    je .allow
    cmp eax,16h     ; Ctrl+V Ч пропускаем, обрабатываем ниже
    je .allow
    cmp eax,18h     ; Ctrl+X
    je .allow
    ; всЄ остальное блокируем
    xor eax,eax
    ret

.allow:
.passthrough:
    invoke CallWindowProcW,[hEditSrcOldProc],[hwnd],[wmsg],[wparam],[lparam]
    ; после вставки Ч чистим недопустимые символы
    cmp [wmsg],WM_CHAR
    jne .done
    movzx eax,word[wparam]
    cmp eax,16h     ; Ctrl+V
    jne .done
    call CleanSourceEdit
.done:
    ret
endp



; ---- »мпорт ----------------------------------------------------
section '.idata' import data readable writeable

library kernel32,'KERNEL32.DLL',\
        user32,'USER32.DLL',\
        comdlg32,'COMDLG32.DLL'

include 'api/kernel32.inc'
include 'api/user32.inc'
include 'api/comdlg32.inc'
