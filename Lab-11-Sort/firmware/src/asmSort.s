/*** asmSort.s   ***/
#include <xc.h>
.syntax unified

@ Declare the following to be in data memory
.data
.align       

@ Define the globals so that the C code can access them
/* define and initialize global variables that C can access */
/* create a string */
.global nameStr
.type nameStr,%gnu_unique_object
    
/*** STUDENTS: Change the next line to your name!  **/
nameStr: .asciz "Javier Ayala"  

.align   /* realign so that next mem allocations are on word boundaries */
 
/* initialize a global variable that C can access to print the nameStr */
.global nameStrPtr
.type nameStrPtr,%gnu_unique_object
nameStrPtr: .word nameStr   /* Assign the mem loc of nameStr to nameStrPtr */

.global const_0
const_0: .word 0

.global const_1
const_1: .word 1
 
.global const_2
const_2: .word 2 

.global const_4
const_4: .word 4 
 
@ Tell the assembler that what follows is in instruction memory    
.text
.align

/********************************************************************
function name: asmSwap(inpAddr,signed,elementSize)
function description:
    Checks magnitude of each of two input values 
    v1 and v2 that are stored in adjacent in 32bit memory words.
    v1 is located in memory location (inpAddr)
    v2 is located at mem location (inpAddr + M4 word size)
    
    If v1 or v2 is 0, this function immediately
    places -1 in r0 and returns to the caller.
    
    Else, if v1 <= v2, this function 
    does not modify memory, and returns 0 in r0. 

    Else, if v1 > v2, this function 
    swaps the values and returns 1 in r0

Inputs: r0: inpAddr: Address of v1 to be examined. 
	             Address of v2 is: inpAddr + M4 word size
	r1: signed: 1 indicates values are signed, 
	            0 indicates values are unsigned
	r2: size: number of bytes for each input value.
                  Valid values: 1, 2, 4
                  The values v1 and v2 are stored in
                  the least significant bits at locations
                  inpAddr and (inpAddr + M4 word size).
                  Any bits not used in the word may be
                  set to random values. They should be ignored
                  and must not be modified.
Outputs: r0 returns: -1 If either v1 or v2 is 0
                      0 If neither v1 or v2 is 0, 
                        and a swap WAS NOT made
                      1 If neither v1 or v2 is 0, 
                        and a swap WAS made             
             
         Memory: if v1>v2:
			swap v1 and v2.
                 Else, if v1 == 0 OR v2 == 0 OR if v1 <= v2:
			DO NOT swap values in memory.

NOTE: definitions: "greater than" means most positive number
********************************************************************/     
.global asmSwap
.type asmSwap,%function     
asmSwap:

    /* YOUR asmSwap CODE BELOW THIS LINE! VVVVVVVVVVVVVVVVVVVVV  */
    
    push {r4-r8, lr}                 @ Save working registers and the return address (standard function prologue)

    ldr r4, =const_0
    ldr r4, [r4]                     @ r4 = 0, will use this as our constant zero throughout
    ldr r5, =const_4
    ldr r5, [r5]                     @ r5 = 4, the word size ? we'll use it repeatedly for comparisons and pointer math

    @ Determine element size so we know how to load v1 and v2 properly
    cmp r2, r5                       @ Is the element size 4 bytes?
    beq load_word                   @ Yes ? word load
    ldr r6, =const_1
    ldr r6, [r6]                     @ r6 = 1
    cmp r2, r6                       @ Is the element size 1 byte?
    beq load_byte                   @ Yes ? byte load
    b load_half                     @ Otherwise, it must be 2 bytes ? halfword load

load_word:
    ldr r6, [r0]                     @ Load v1 (first element)
    add r7, r0, r5
    ldr r7, [r7]                     @ Load v2 (next element)
    b check_zero

load_half:
    ldrh r6, [r0]                    @ Load v1 as halfword
    add r7, r0, r5
    ldrh r7, [r7]                    @ Load v2 as halfword
    b check_zero

load_byte:
    ldrb r6, [r0]                    @ Load v1 as byte
    add r7, r0, r5
    ldrb r7, [r7]                    @ Load v2 as byte

check_zero:
    cmp r6, r4                       @ If v1 == 0, we shouldn't try swapping
    beq swap_exit_neg1              @ So bail out with error (-1)
    cmp r7, r4                       @ Same if v2 == 0
    beq swap_exit_neg1

    cmp r1, r4                       @ Check the signed flag
    beq unsigned_compare             @ If signed flag == 0 ? unsigned comparison

    @ Signed comparison
    cmp r6, r7
    bgt do_swap                      @ If v1 > v2 (signed), they?re out of order ? swap
    mov r0, r4                       @ Else no swap, return 0
    pop {r4-r8, pc}

unsigned_compare:
    cmp r6, r7
    bhi do_swap                      @ For unsigned, check if v1 > v2
    mov r0, r4                       @ No swap needed ? return 0
    pop {r4-r8, pc}

do_swap:
    @ Now we know we need to swap the values ? figure out how based on the size
    cmp r2, r5                       @ Check if word
    beq swap_word
    ldr r8, =const_1
    ldr r8, [r8]
    cmp r2, r8                       @ Check if byte
    beq swap_byte
    b swap_half                      @ If not word or byte, it must be half

swap_word:
    add r9, r0, r5                   @ r9 = address of second value
    str r7, [r0]                     @ Store v2 in first position
    str r6, [r9]                     @ Store v1 in second position
    b swap_exit_1

swap_half:
    add r9, r0, r5
    strh r7, [r0]                    @ Same logic as word swap, just use halfword instructions
    strh r6, [r9]
    b swap_exit_1

swap_byte:
    add r9, r0, r5
    strb r7, [r0]                    @ Same as above, but for bytes
    strb r6, [r9]
    b swap_exit_1

swap_exit_neg1:
    ldr r0, =const_1
    ldr r0, [r0]
    rsb r0, r0, #0                   @ Return -1 to signal error (used rsb to negate 1)
    pop {r4-r8, pc}

swap_exit_1:
    ldr r0, =const_1
    ldr r0, [r0]                     @ Successful swap ? return 1
    pop {r4-r8, pc}

    /* YOUR asmSwap CODE ABOVE THIS LINE! ^^^^^^^^^^^^^^^^^^^^^  */
    
    
/********************************************************************
function name: asmSort(startAddr,signed,elementSize)
function description:
    Sorts value in an array from lowest to highest.
    The end of the input array is marked by a value
    of 0.
    The values are sorted "in-place" (i.e. upon returning
    to the caller, the first element of the sorted array 
    is located at the original startAddr)
    The function returns the total number of swaps that were
    required to put the array in order in r0. 
    
         
Inputs: r0: startAddr: address of first value in array.
		      Next element will be located at:
                          inpAddr + M4 word size
	r1: signed: 1 indicates values are signed, 
	            0 indicates values are unsigned
	r2: elementSize: number of bytes for each input value.
                          Valid values: 1, 2, 4
Outputs: r0: number of swaps required to sort the array
         Memory: The original input values will be
                 sorted and stored in memory starting
		 at mem location startAddr
NOTE: definitions: "greater than" means most positive number    
********************************************************************/     
.global asmSort
.type asmSort,%function
asmSort:   

    /* Note to Profs: 
     */

    /* YOUR asmSort CODE BELOW THIS LINE! VVVVVVVVVVVVVVVVVVVVV  */
    
   push {r4-r11, lr}           @ Save registers and link register

    mov r3, const_0             @ Initialize swap count to 0 (r3)
    mov r10, r1                 @ Store signed flag in r10 (r1 = signed flag)
    mov r11, r2                 @ Store element size in r11 (r2 = element size)

    mov r4, const_0             @ Initialize swapped flag (r4 = 0)
    mov r5, r0                  @ Store pointer to the start of the array in r5 (r0 = array pointer)

outer_loop:
    mov r4, const_0             @ Reset swapped flag at the start of each outer loop iteration

inner_loop:
    cmp r11, const_4            @ Check if element size is 4 bytes (word)
    beq load_v1_word
    cmp r11, const_2            @ Check if element size is 2 bytes (halfword)
    beq load_v1_half
    b load_v1_byte

load_v1_word:
    ldr r7, [r5]                @ Load 4-byte word from array
    b check_v1_zero

load_v1_half:
    ldrh r7, [r5]               @ Load 2-byte halfword from array
    b check_v1_zero

load_v1_byte:
    ldrb r7, [r5]               @ Load 1-byte byte from array

check_v1_zero:
    cmp r7, const_0             @ Check if v1 == 0 (end of array)
    beq check_swapped

    add r9, r5, r11             @ Calculate pointer to next element in array (v2)
    
    cmp r11, const_4            @ Check if element size is 4 bytes (word)
    beq load_v2_word
    cmp r11, const_2            @ Check if element size is 2 bytes (halfword)
    beq load_v2_half
    b load_v2_byte

load_v2_word:
    ldr r8, [r9]                @ Load 4-byte word from array
    b check_v2_zero

load_v2_half:
    ldrh r8, [r9]               @ Load 2-byte halfword from array
    b check_v2_zero

load_v2_byte:
    ldrb r8, [r9]               @ Load 1-byte byte from array

check_v2_zero:
    cmp r8, const_0             @ Check if v2 == 0 (end of array)
    beq check_swapped

    cmp r7, r8                  @ Compare v1 and v2
    bge no_swap                 @ If v1 >= v2, no swap needed

    @ Swap the values if they are in the wrong order
    mov r0, r5                  @ Pointer to v1
    mov r1, r10                 @ Signed flag
    mov r2, r11                 @ Element size
    bl asmSwap                  @ Call asmSwap to swap the values

    add r3, r3, const_1          @ Increment swap count
    mov r4, const_1             @ Set swapped flag to 1

no_swap:
    add r5, r5, r11             @ Move to the next element in the array
    cmp r8, const_0             @ Check if the second value is 0 (end of array)
    bne inner_loop

check_swapped:
    cmp r4, const_0             @ If no swaps occurred in this pass, exit the outer loop
    bne outer_loop

    mov r0, r3                  @ Return swap count in r0
    pop {r4-r11, pc}            @ Restore registers and return
    
    /* YOUR asmSort CODE ABOVE THIS LINE! ^^^^^^^^^^^^^^^^^^^^^  */

   

/**********************************************************************/   
.end  /* The assembler will not process anything after this directive!!! */
           




