
; get function address from given module

_GetApi		proc	_hModule,_lpszApi
		local	@dwReturn,@dwStringLength

		pushad
		mov	@dwReturn,0

; relocation

		call	@F
		@@:
		pop	ebx
		sub	ebx,offset @B

; create SEH structure

		assume	fs:nothing
		push	ebp
		lea	eax,[ebx + offset _Error]
		push	eax
		lea	eax,[ebx + offset _SEHHandler]
		push	eax
		push	fs:[0]
		mov	fs:[0],esp

; get the length of name of the api 

		mov	edi,_lpszApi
		mov	ecx,-1
		xor	al,al
		cld
		repnz	scasb
		mov	ecx,edi
		sub	ecx,_lpszApi
		mov	@dwStringLength,ecx

; get the api address from the export table of module

		mov	esi,_hModule
		add	esi,[esi + 3ch]			; add e_lfanew value
		assume	esi:ptr IMAGE_NT_HEADERS
		mov	esi,[esi].OptionalHeader.DataDirectory.VirtualAddress
		add	esi,_hModule
		assume	esi:ptr IMAGE_EXPORT_DIRECTORY

; search the api of the given name

		mov	ebx,[esi].AddressOfNames		
		add	ebx,_hModule				; add the base address of the module, point to the first func name
		xor	edx,edx
		.repeat
			push	esi					; save esi 
			mov	edi,[ebx]
			add	edi,_hModule			; point to the func name
			mov	esi,_lpszApi			; the func we needed
			mov	ecx,@dwStringLength
			cld
			repz	cmpsb				; compare two names, finish until there is different char
			.if	ZERO?					; find 
				pop	esi
				jmp	@F
			.endif
			pop	esi						; not find
			add	ebx,4					; point to next func name
			inc	edx						; increase edx
		.until	edx >=	[esi].NumberOfNames				; start from 0
		jmp	_Error						; failed
@@:

; AddressOfNames --> AddressOfNameOrdinals--> AddressOfFunctions

		sub	ebx,[esi].AddressOfNames	; pioint to the addr of next func because of repz cmpsb
		sub	ebx,_hModule
		shr	ebx,1						; because repz cmpsb
		add	ebx,[esi].AddressOfNameOrdinals
		add	ebx,_hModule
		movzx	eax,word ptr [ebx]		; now eax = api's ordinals
		shl	eax,2
		add	eax,[esi].AddressOfFunctions
		add	eax,_hModule

; get the address

		mov	eax,[eax]					; get RVA of needed func
		add	eax,_hModule
		mov	@dwReturn,eax
_Error:
		pop	fs:[0]
		add	esp,0ch
		assume	esi:nothing
		popad
		mov	eax,@dwReturn
		ret

_GetApi		endp
