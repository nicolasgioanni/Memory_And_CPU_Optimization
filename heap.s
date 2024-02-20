		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
HEAP_TOP	EQU		0x20001000
HEAP_BOT	EQU		0x20004FE0
MAX_SIZE	EQU		0x00004000		; 16KB = 2^14
MIN_SIZE	EQU		0x00000020		; 32B  = 2^5
	
MCB_TOP		EQU		0x20006800      ; 2^10B = 1K Space
MCB_BOT		EQU		0x20006BFE
MCB_ENT_SZ	EQU		0x00000002		; 2B per entry
MCB_TOTAL	EQU		512				; 2^9 = 512 entries
	
INVALID		EQU		-1				; an invalid id
	
;
; Each MCB Entry
; FEDCBA9876543210
; 00SSSSSSSSS0000U					S bits are used for Heap size, U=1 Used U=0 Not Used

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Memory Control Block Initialization
; void _kinit( )
; this routine must be called from Reset_Handler in startup_TM4C129.s
; before you invoke main( ) in driver_keil
		EXPORT	_kinit
_kinit
		; you must correctly set the value of each MCB block
		; complete your code
		
		; Load values into registers
		LDR     r0, =MCB_TOP
        LDR     r1, =MCB_BOT
		MOV 	r2, #0
_kinit_loop
		; Loop through the MCB blocks and set their values to zero
		CMP		r0, r1
		BEQ 	_kinit_stop
		STRB 	r2, [r1]
		SUB 	r1, r1, #1
		B 		_kinit_loop
_kinit_stop
		; Set the MAX_SIZE value in the last MCB block
		LDR 	r2, =MAX_SIZE
		STRH 	r2, [r0]
		
		BX		lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory Allocation
; void* _k_alloc( int size )
		EXPORT	_kalloc
_kalloc
		; complete your code
		; return value should be saved into r0
		
		; Load registers
		LDR		r1, =MCB_TOP	
		LDR		r2, =MCB_BOT	
		LDR		r3, = _ralloc
		
		; Allocate memory with _ralloc
		PUSH 	{lr}
		BLX		r3
		POP		{lr}
		
		; Save return value into r0
		MOV		r0, r8 
		
		BX		lr
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Recursive Memory Allocation
; void* _ralloc( int size, left_mcb, right_mcb )

; Input Parameters:
;   r0: Size of memory to allocate
;   r1: Address of the left Memory Control Block (left_mcb)
;   r2: Address of the right Memory Control Block (right_mcb)

; Output:
;   r8: Address of the allocated memory block (if successful, 0 otherwise)

; Registers:
;   r3: MCB_ENT_SZ (Size of Memory Control Block entry)
;   r4: Difference between right_mcb and left_mcb
;   r5: Half of the size difference between right_mcb and left_mcb
;   r6: Midpoint address between left_mcb and right_mcb
;   r7: Temporary register
;   r8: Heap address (initialized to 0)
;   r9: Left space size (left_mcb entry)
;   r10: Temporary register (for comparison with the requested size)
;   r11: Temporary register (used for bitwise operations)
;   r12: Temporary register (used for address calculation)

		EXPORT	_ralloc        
_ralloc
		; Save the link register
		PUSH {lr}    
		
		; Load the size of a memory control block entry into register r3
		LDR	r3, =MCB_ENT_SZ   

		; Calculate parameters for memory allocation 
		SUBS	r4, r2, r1 
		ADDS	r4, r4, r3 
		ASRS	r5, r4, #1 
		ADDS	r6, r1, r5
		MOV		r8, #0 
		LSLS	r9, r4, #4 	
		LSLS	r10, r5, #4     	

		; Check if allocation is possible in the left partition
		CMP r0, r10
		BGT	_ralloc_continue 
		BLE _ralloc_left

_ralloc_resume		
		; Check if the heap address (r8) is non-zero
		CMP	r11, #0x0 
		BEQ	_ralloc_check 
	
_ralloc_zero
		; If heap address is zero, set r8 to zero and exit
		MOV	r8, #0    
		BL	_ralloc_done 

_ralloc_continue	
		; Load the halfword from the left memory control block (MCB) into r11
		LDRH	r11, [r1] 

		; Check the availability of the left space by examining the least significant bit
		AND	r11, r11, #0x01
		B	_ralloc_resume

_ralloc_check
		; Check if space is available for memory allocation
		LDR r11, [r1] 

		; Compare the left space size with the requested size
		CMP	r11, r9 
		BGE _ralloc_check_continue 
		BLT	_ralloc_zero

_ralloc_check_continue
		; Load registers
		LDR	r12, =MCB_TOP        
		LDR	r8, =HEAP_TOP 
		
		; Update the left memory control block (MCB) to mark the space as allocated
		ORRS r11, r9, #0x01 
		STR	 r11, [r1]        	
		SUBS r12, r1, r12 
		LSLS r12, r12, #4 
		ADDS r12, r12, r8 
		
		; Update the heap address
		MOV	 r8, r12 
		
		; Continue with the allocation process
		BL _ralloc_done          		

_ralloc_left
		; Allocate memory in the left partition
		PUSH {r1-r7, r9-r12}     		
		SUB	r2, r6, r3 ; Calculate the midpoint address and subtract MCB_ENT_SZ
		BL _ralloc              
		POP {r1-r7, r9-r12} 
		
		; Check if the allocation in the left partition was successful
		CMP	r8, #0x0  
		BNE _ralloc_left_continue ; If heap address is non-zero, continue with the left allocation
		BEQ _ralloc_overlap ; If heap address is zero, check for overlap with right allocation
	
_ralloc_left_continue
		; Load the word from the midpoint address into r11
		LDR	r11, [r6] ; Load the word from mcb midpoint address into r11

		; Perform bitwise AND to check the least significant bit
		AND	r11, r11, #1 
		
		; Check if the space in the left partition is already allocated
		CMP	r11, #0x0           	
		BEQ _ralloc_left_store 
		BNE _ralloc_left_not_store

_ralloc_left_store	
		; Store half the heap size at the midpoint address to mark it as allocated
		STRH	r10, [r6]
	
_ralloc_left_not_store	
		; Continue with the allocation process
		B _ralloc_done    
	
_ralloc_overlap	

_ralloc_right
		; Move the current midpoint address to r1 for right allocation
		MOV	r1, r6      

		; Allocate memory in the right partition
		PUSH {r1-r7, r9-r12}     		         		
		BL	_ralloc               		
		POP {r1-r7, r9-r12}      		          		         

_ralloc_done 
		; Restore the link register and return
		POP	{lr}
		BX lr  

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory De-allocation
; void *_kfree( void *ptr )	
		EXPORT	_kfree
_kfree
	; Load registers
	LDR 	r1, =HEAP_TOP
	LDR 	r2, =HEAP_BOT
	LDR		r3, =MCB_TOP
	LDR		r4, =_rfree 
	
	; Check if the address to free is within valid heap bounds
	; Perform memory deallocation if r0 is equal to or greater than HEAP_TOP
	CMP      r0, r1
	BEQ      _rfree_call
	CMP      r0, r1
	BGT      _rfree_call
	
	; Perform memory deallocation if r0 is equal to or less than HEAP_BOT
	CMP      r0, r2
	BEQ      _rfree_call   
	CMP      r0, r2
	BLT      _rfree_call 

	; If the address is within valid bounds, set r0 to null 
	MOV 	r0, #0
	B       _kfree_end
	
_rfree_call
	; Calculate new address for _rfree
	SUB 	r5, r0,r1
	ROR   	r5, r5, #4
	ADDS	r0,r5,r3  
	
	; Set return value to 0 for rfree
	MOV		r12, #0
	
	; Call recursive memory deallocation
	PUSH 	{lr}		
	BLX		r4			
	POP 	{lr}		
	
	; Return value in r0 for kfree
	MOV		r0, r12
	
_kfree_end
	; Deallocation complete
	BX		lr		

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Recursive Memory De-allocation
; void* _rfree( int mcb_addr)

; Registers:
;   r0: mcb_addr
;   r1: MCB_TOP
;   r2: MCB_BOT
;   r3: Block size (MCB_ENT_SZ)
;   r4: Temporary register (difference between mcb_addr and MCB_TOP)
;   r5: Temporary register(calculated addresses)
;   r6: Temporary register(shifted block size)
;   r7: Temporary register(block size for division)
;   r8: Temporary register(calculated block size for division)
;   r9: Address of _rfree
;   r10: Result of division operations (recursion condition)
;   r11: Temporary register(loading and storing block information)
;   r12: Return value

	EXPORT _rfree			
_rfree		
	; Load registers
	LDR		r1, =MCB_TOP
	LDR		r2, =MCB_BOT
	LDRH    r3, [r0]  

	; Calculate the difference between mcb_addr and MCB_TOP
	SUB     r4, r0, r1        
	MOV     r6, #4        
	LSR     r3, r3, r6     
	MOV     r8, r3         
	MOV     r5, #4      
	LSL     r3, r3, r5        
	MOV     r7, r3          
	ADD     r11, r8, r7     
	MOV     r12, r0          

	; Update the halfword value at memory address r0 with the shifted value
	STRH	r3, [r0] 
	
	; Calculate division for recursion condition
	MOV		r5, #2
	SDIV 	r10, r4, r8
	SDIV	r9, r10, r5
	MLS		r10, r5, r9, r10	

	; Continue recursion if condition is met, otherwise move right in memory.
	CMP 	r10, #0
	BEQ		_rfree_continue
	B		_rfree_right

_rfree_continue
	; Check if the new address is at or beyond MCB_BOT
	ADD		r5, r0, r8 	

	; Check if the new address is at or beyond MCB_BOT
	CMP 	r5, r2
	BEQ		_rfree_end
	CMP 	r5, r2
	BGT		_rfree_end
	B 		_rfree_up
	
_rfree_up
	; Move up the memory block
	LDR		r11, [r5] 
	AND		r10, r11, #0001

	; Check if the block is not marked as free
	CMP 	r10, #0
	BEQ		_rfree_up_continue

_rfree_resume
	; Check if the block size matches the calculated size for recursion
	CMP		r11, r7
	BEQ		_rfree_up_continue_recursive
	
	B		_rfree_end
	
_rfree_up_continue
	; Adjust the block size for processing
	LSR		r11, r11, #5				
	LSL		r11, r11, #5
	B 		_rfree_resume
	
_rfree_up_continue_recursive
	; Mark the block as free
	MOV 	r9, #0
	STRH	r9, [r5]	
	LSL		r7, #1
	STRH	r7, [r0]
	
	; Loads address of rfree
	LDR		r9, =_rfree
	
	; Recursively call _rfree
	PUSH 	{r0-r9, lr}						
	BLX		r9			 
	POP 	{r0-r9, lr}	
	
	B		_rfree_end
	
_rfree_right
	; Calculate the new address to the right
	SUB		r5, r0, r8 	

	; Check if the new address is before MCB_TOP
	CMP		r5, r1
	BLT		_rfree_end
	
_rfree_down		
	; Move down the memory block
	; Load the block information at the new address
	LDR		r11, [r5] 
	
	; Extract the least significant bit to check if the block is free
	AND		r10, r11, #0001
	
	; Check if the block size matches the calculated size for recursion
	CMP		r11, r7
	BEQ		_rfree_down_continue_recursive
	
	; End the recursion if conditions are not met
	B 		_rfree_end	
	
_rfree_down_continue_recursive
	; Continue recursively in the downward direction
	LDR		r9, =_rfree
	
	; Adjust the address for the recursive call
	SUB		r0, r0, r8 
	
	; Recursive call to _rfree
	PUSH 	{r0-r9, lr}	 			
	BLX		r9			
	POP 	{r0-r9, lr}	
	
	; Set the return value
	MOV 	r12, r0	
	
_rfree_end
	; Set the return value
	MOV		r12, #0
	BX		lr
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; End of program
		END