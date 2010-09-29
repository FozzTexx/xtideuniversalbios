; File name		:	Sort.asm
; Project name	:	Assembly Library
; Created date	:	28.9.2010
; Last update	:	29.9.2010
; Author		:	Tomi Tilli
; Description	:	Sorting algorithms

; Algorith is from http://www.algolist.net/Algorithms/Sorting/Quicksort

struc QSORT_PARAMS
	.lpItems		resb	4
	.tempStruct:
endstruc

;--------------------------------------------------------------------
; Prototype for comparator callback function
;	Parameters:
;		DS:SI:	Offset to first item to compare
;		ES:DI:	Offset to second item to compare
;	Returns:
;		FLAGS:	Signed comparition between first and second item
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------


; Section containing code
SECTION .text

;--------------------------------------------------------------------
; DialogFile_GetFileNameWithIoInDSSI
;	Parameters:
;		DS:SI:	Ptr to FILE_DIALOG_IO
;		SS:BP:	Ptr to parent MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Sort_ItemsFromDSSIwithCountInDXsizeInCXandComparatorInBX:
	push	es
	push	di
	add		cx, BYTE QSORT_PARAMS_size
	eENTER_STRUCT cx

	cld
	sub		cx, BYTE QSORT_PARAMS_size	; Restore CX to item size
	xor		ax, ax						; Zero for starting index
	dec		dx							; Count to index of last item
	mov		[bp+QSORT_PARAMS.lpItems], si
	mov		[bp+QSORT_PARAMS.lpItems+2], ds
	call	QuicksortItemsInRangeFromAXtoDXwithQsortParamsInSSBP

	lds		si, [bp+QSORT_PARAMS.lpItems]
	add		cx, BYTE QSORT_PARAMS_size
	eLEAVE_STRUCT cx
	pop		di
	pop		es
	ret


;--------------------------------------------------------------------
; QuicksortItemsInRangeFromAXtoDXwithQsortParamsInSSBP
;	Parameters:
;		AX:		Index of first item in range
;		BX:		Comparator function
;		CX:		Size of struct in bytes
;		DX:		Index of last (included) item in range
;		SS:BP:	Ptr to QSORT_PARAMS
;	Returns:
;		Nothing
;	Corrupts registers:
;		DS, ES
;		AX, DX (not for recursion)
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
QuicksortItemsInRangeFromAXtoDXwithQsortParamsInSSBP:
	push	di
	push	si

	mov		si, ax			; First index to SI
	mov		di, dx			; Last index to DI
	call	ArrangeItemsInRangeAXtoDXusingMiddleItemAsPivot

	; Does left partition need more sorting
	cmp		si, dx			; if (first index < Index of rightmost unsorted item)
	jae		SHORT .CheckIfRightPartitionNeedsMoreSorting
	xchg	ax, si			; AX = first index, SI = Index of leftmost unsorted item
	call	QuicksortItemsInRangeFromAXtoDXwithQsortParamsInSSBP
	xchg	ax, si			; AX = Index of leftmost unsorted item

.CheckIfRightPartitionNeedsMoreSorting:
	cmp		ax, di			; if (Index of leftmost unsorted item < last index)
	jae		SHORT .SortCompleted
	mov		dx, di			; DI = Index of leftmost unsorted item
	call	QuicksortItemsInRangeFromAXtoDXwithQsortParamsInSSBP

ALIGN JUMP_ALIGN
.SortCompleted:
	pop		si
	pop		di
	ret


;--------------------------------------------------------------------
; ArrangeItemsInRangeAXtoDXusingMiddleItemAsPivot
;	Parameters:
;		AX:		Index of first item in range
;		BX:		Comparator function
;		CX:		Size of struct in bytes
;		DX:		Index of last (included) item in range
;		SS:BP:	Ptr to QSORT_PARAMS
;	Returns:
;		AX:		Index of first unsorted item
;		DX:		Index of last unsorted item
;	Corrupts registers:
;		DS, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ArrangeItemsInRangeAXtoDXusingMiddleItemAsPivot:
	push	di
	push	si

	call	.GetPivotPointerToESDI
	call	ArrangeItemsInRangeAXtoDXtoBothSidesOfPivotInESDI

	pop		si
	pop		di
	ret

ALIGN JUMP_ALIGN
.GetPivotPointerToESDI:
	push	ax
	add		ax, dx
	shr		ax, 1
	call	GetItemPointerToDSSIfromIndexInAX
	pop		ax
	jmp		Memory_ExchangeDSSIwithESDI


;--------------------------------------------------------------------
; ArrangeItemsInRangeAXtoDXtoBothSidesOfPivotInESDI
;	Parameters:
;		AX:		Index of first item in range
;		BX:		Comparator function
;		CX:		Size of struct in bytes
;		DX:		Index of last (included) item in range
;		ES:DI:	Ptr to Pivot item
;		SS:BP:	Ptr to QSORT_PARAMS
;	Returns:
;		AX:		Index of first unsorted item
;		DX:		Index of last unsorted item
;	Corrupts registers:
;		SI, DS
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ArrangeItemsInRangeAXtoDXtoBothSidesOfPivotInESDI:
	cmp		ax, dx	; while (left <= right)
	ja		SHORT .BreakLoopSinceAllItemsExamined

	call	GetItemPointerToDSSIfromIndexInAX
	call	.GetIndexOfLeftmostItemToAXforItemThatIsGreaterThanEqualToPivotInESDI

	call	GetItemPointerToDSSIfromIndexInDX
	call	.GetIndexOfRightmostItemToDXforItemThatIsGreaterThanPivotInESDI

	cmp		ax, dx	; If (left <= right)
	ja		SHORT ArrangeItemsInRangeAXtoDXtoBothSidesOfPivotInESDI
	call	SwapItemsFromIndexesAXandDX
	inc		ax
	dec		dx
	jmp		SHORT ArrangeItemsInRangeAXtoDXtoBothSidesOfPivotInESDI

ALIGN JUMP_ALIGN
.GetIndexOfLeftmostItemToAXforItemThatIsGreaterThanEqualToPivotInESDI:
	call	bx
	jge		SHORT .NoNeedToIncrementOrDecrementAnyMore
	inc		ax				; Increment item index
	add		si, cx			; Point to next struct
	jmp		SHORT .GetIndexOfLeftmostItemToAXforItemThatIsGreaterThanEqualToPivotInESDI

ALIGN JUMP_ALIGN
.GetIndexOfRightmostItemToDXforItemThatIsGreaterThanPivotInESDI:
	call	bx
	jle		SHORT .NoNeedToIncrementOrDecrementAnyMore
	dec		dx
	sub		si, cx
	jmp		SHORT .GetIndexOfRightmostItemToDXforItemThatIsGreaterThanPivotInESDI

ALIGN JUMP_ALIGN
.NoNeedToIncrementOrDecrementAnyMore:
.BreakLoopSinceAllItemsExamined:
	ret


;--------------------------------------------------------------------
; SwapItemsFromIndexesAXandDX
;	Parameters:
;		AX:		Index of item 1
;		CX:		Size of struct in bytes
;		DX:		Index of item 2
;		SS:BP:	Ptr to QSORT_PARAMS
;	Returns:
;		Nothing
;	Corrupts registers:
;		SI, DS
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
SwapItemsFromIndexesAXandDX:
	push	es
	push	di

	; Item AX to stack
	call	.GetPtrToTemporaryStructToESDI
	call	GetItemPointerToDSSIfromIndexInAX
	call	.CopyItemFromDSSItoESDI

	; Item DX to Item AX
	call	Memory_ExchangeDSSIwithESDI
	call	GetItemPointerToDSSIfromIndexInDX
	call	.CopyItemFromDSSItoESDI

	; Stack to Item DX
	call	.GetPtrToTemporaryStructToESDI
	call	Memory_ExchangeDSSIwithESDI
	call	.CopyItemFromDSSItoESDI

	pop		di
	pop		es
	ret

ALIGN JUMP_ALIGN
.GetPtrToTemporaryStructToESDI:
	lea		di, [bp+QSORT_PARAMS.tempStruct]
	push	ss
	pop		es
	ret

ALIGN JUMP_ALIGN
.CopyItemFromDSSItoESDI:
	push	si
	push	cx

	shr		cx, 1			; We want to copy WORDs for performance
	jcxz	.CopyLastByte
	rep		movsw
.CopyLastByte:
	jnc		SHORT .CopyComplete
	movsb
.CopyComplete:
	pop		cx
	pop		si
	ret


;--------------------------------------------------------------------
; GetItemPointerToDSSIfromIndexInDX
; GetItemPointerToDSSIfromIndexInAX
;	Parameters:
;		AX or DX:	Item index
;		CX:			Size of struct in bytes
;		SS:BP:		Ptr to QSORT_PARAMS
;	Returns:
;		DS:SI:		Ptr to item
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
GetItemPointerToDSSIfromIndexInDX:
	xchg	ax, dx
	call	GetItemPointerToDSSIfromIndexInAX
	xchg	dx, ax
	ret

ALIGN JUMP_ALIGN
GetItemPointerToDSSIfromIndexInAX:
	push	dx
	push	ax

	mul		cx		; DX:AX = index (AX) * size of struct (CX)
	lds		si, [bp+QSORT_PARAMS.lpItems]
	add		si, ax

	pop		ax
	pop		dx
	ret
