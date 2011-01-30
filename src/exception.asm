
; SEH handler (structured exception handling) 
; dealing the exception 

_SEHHandler	proc	_lpExceptionRecord,_lpSEH,_lpContext,_lpDispatcherContext

		pushad				; store orignal registers
		mov	esi,_lpExceptionRecord
		mov	edi,_lpContext
		assume	esi:ptr EXCEPTION_RECORD,edi:ptr CONTEXT
		mov	eax,_lpSEH
		push	[eax + 0ch]				;; eax + 0ch the stored ebp
		pop	[edi].regEbp				;; recovery the ebp
		push	[eax + 8]				;; eax + 8 the safe place 
		pop	[edi].regEip				;; recovery the eip, namely point to a safe place
		push	eax						;; point to prev
		pop	[edi].regEsp				
		assume	esi:nothing,edi:nothing
		popad				; registers recovery 
		mov	eax,ExceptionContinueExecution  ;; return the exception , make the program continue with registers in lpContext
		ret

_SEHHandler	endp