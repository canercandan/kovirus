.386
.model flat, stdcall ;; arguments order from right to left
option casemap:none ;; tells MASM to make labels case-sensitive

;; header including
include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
include \masm32\include\user32.inc

;; library including
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\user32.lib

.data
MsgBoxCaption   db  "The Caption", 0
MsgBoxText      db  "Hello World!, 0

.code

start:

    invoke MessageBox, NULL, addr MsgBoxText, addr MsgBoxCaption, MB_OK

    invoke ExitProcess, 0 ;; return to Windows in sending the 0 code

end start

