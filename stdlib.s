		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _bzero( void *s, int n )
; Parameters
;	s 		- pointer to the memory location to zero-initialize
;	n		- a number of bytes to zero-initialize
; Return value
;   none
		EXPORT	_bzero
_bzero
		; r0 = s
		; r1 = n
		PUSH {r1-r12,lr}		
		; you need to add some code here for part 1 implmentation
		
		MOV		r2, #0		
		CBZ		r1, _bzero_end
_bzero_loop							
		STRB	r2, [r0], #1		
		SUBS	r1, r1, #1				
		BNE		_bzero_loop	
_bzero_end
		POP		{r1-r12,lr}
		BX lr



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; char* _strncat( char* dest, char* src, int size )
; Parameters
;   dest 	- pointer to the destination array
;	src		- pointer to string to be appended
;	size	- Maximum number of characters to be appended
; Return value
;   dest
		EXPORT	_strncpy
_strncpy
		; r0 = dest
		; r1 = src
		; r2 = size
		PUSH {r1-r12,lr}		
		; you need to add some code here for part 1 implmentation
		
		MOV		r3, r0	
_strncpy_loop					
		CMP 	r2, #0
		BEQ		_strncpy_end		
		SUBS	r2, r2, #1		
		LDRB	r4, [r1], #1		
		STRB	r4, [r0], #1		
		B		_strncpy_loop		
_strncpy_end
		MOV		r0, r3		
		POP 	{r1-r12,lr}
		BX 		lr
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void* _malloc( int size )
; Parameters
;	size	- #bytes to allocate
; Return value
;   void*	a pointer to the allocated space
		EXPORT	_malloc
_malloc
		; r0 = size
		PUSH {r1-r12,lr}		
		; you need to add two lines of code here for part 2 implmentation
		MOV r7, #1                
		SVC #0x0                  ; Invoke the handler      
		POP {r1-r12,lr}	 
		BX		lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _free( void* addr )
; Parameters
;	size	- the address of a space to deallocate
; Return value
;   none
		EXPORT	_free
_free
		; r0 = addr
		PUSH {r1-r12,lr}		
		; you need to add two lines of code here for part 2 implmentation
		MOV r7, #2               
		SVC #0x0                 ; Invoke the handler
		POP {r1-r12,lr}	
		BX		lr
		
		END