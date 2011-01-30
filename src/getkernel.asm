
; get base address of kernel32.dll in the memory 

_GetKernelBase	proc	_dwKernelRet
		local	@dwReturn

		pushad
		mov	@dwReturn,0

; relocation, get the offset value

		call	@F
		@@:
		pop	ebx
		sub	ebx,offset @B

; create new new ewception_registration structure, makes handler point to the callback function
; namely create SEH structure

		assume	fs:nothing	; declare to use fs register
		push	ebp
		lea	eax,[ebx + offset _PageError]
		push	eax
		lea	eax,[ebx + offset _SEHHandler]
		push	eax
		push	fs:[0]
		mov	fs:[0],esp

; get the base address of kernel32.dll

		mov	edi,_dwKernelRet
		and	edi,0ffff0000h			; alignment with section alignment	
		.while	TRUE
			.if	word ptr [edi] == IMAGE_DOS_SIGNATURE
				mov	esi,edi
				add	esi,[esi+003ch]		;; add the e_lfanew value
				.if word ptr [esi] == IMAGE_NT_SIGNATURE
					mov	@dwReturn,edi
					.break
				.endif
			.endif
			_PageError:
			sub	edi,010000h			; 010000h is the section alignment
			.break	.if edi < 070000000h				;; avoid the dead loop and 70000000h is fixed address when pe loader load .dll file
		.endw
;; recovery stack		
		pop	fs:[0]
		add	esp,0ch
		popad
		mov	eax,@dwReturn
		ret

_GetKernelBase	endp
