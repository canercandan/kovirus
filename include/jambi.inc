IFNDEF JAMBI_INC
JAMBI_INC equ <1>

_Inject proto :DWORD

SEH struct
PrevLink        dd ?    ; the address of the previous seh structure
CurrentHandler  dd ?    ; the address of the exception handler
SafeOffset      dd ?    ; The offset where it's safe to continue execution
PrevEsp         dd ?    ; the old value in esp
PrevEbp         dd ?    ; The old value in ebp
SEH ends


ELSE
echo -----------------------------------------
echo WARNING Duplicate include file jambi.inc
echo -----------------------------------------
ENDIF
