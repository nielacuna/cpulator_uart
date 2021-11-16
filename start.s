.equ JTAG_UART_BASE_ADDR, 			0xFF201000
.equ JTAG_UART_DATA_REG_OFFSET, 	0
.equ JTAG_UART_DATA_VALID,			(1<<7)

.equ JTAG_UART_CONTROL_REG_OFFSET, 	4
.equ JTAG_UART_CONTROL_WRITE_IRQ_PENDING,	(1<<9)
.equ JTAG_UART_CONTROL_READ_IRQ_PENDING,	(1<<8)

.global _start
_start:
		/* r0 is global defined to be the base jtag uart register from now on */
		ldr r0,=JTAG_UART_BASE_ADDR

		/* INITIALIZATION. we put the jtag uart peripheral into a known and stable state
		 * 1) disable both read and write interrupts by writing zero to bits 1, 0
		 * 2) clear all pending interrupts by writing writing 1 to bits 9, 8
		 */
		ldrb 	r1, =0
		orr		r1, r1, #(JTAG_UART_CONTROL_WRITE_IRQ_PENDING | JTAG_UART_CONTROL_READ_IRQ_PENDING)
		strb 	r1, [r0, #JTAG_UART_CONTROL_REG_OFFSET]
	
		/* POLL FOR CHARACTER INPUT. */
poll:	ldrb	r1, [r0, #(JTAG_UART_DATA_REG_OFFSET+1)]
		ands	r2, r1, #JTAG_UART_DATA_VALID
		beq		poll

		/* extract the number of characters to read, r2 will hold the max loop count */
		ldrh	r2, [r0, #(JTAG_UART_DATA_REG_OFFSET+2)]
loop:	
		ldrb	r1, [r0, #(JTAG_UART_DATA_REG_OFFSET)]	
		mov		r3, #('a' - 'A')	/* bias value for upper case to lower case */
		
		/* check input is a letter (only letters can have capital or small versions) */
		cmp 	r1, #'A'
		blt	print
		cmp	r1, #'Z'
		blt	change_case
		
		mov	r3, #('A' - 'a')	/* bias value for lower case to upper case */

		cmp 	r1, #'a'
		blt	print
		cmp	r1, #'z'
		bge	decrement

change_case:		
		add 	r1, r3
print:
		str	r1, [r0]
decrement:		
		adds	r2, #-1	/* decrement the loop counter */	
		bgt	loop
		nop
		b	.	/* stop processing here. */

	
