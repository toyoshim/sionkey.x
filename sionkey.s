	.include iocscall.mac
	.include doscall.mac


	.text
	.even

vect_bitsns:
	dc.l	0

magic_code:
	dc.l	'SioK'

iocs_bitsns:
	movem	d1-d2/a0, -(sp)

	lea	vect_bitsns, a0
	move.l	(a0), a0
	jsr	(a0)

	cmp.w	#8, d1
	beq	bitsns_8
	cmp.w	#9, d1
	beq	bitsns_9
	bra	bitsns_ret

bitsns_8:
	and.b	#$6f, d0
	move.b	d0, d2

	move.l	#_BITSNS, d0
	move.w	#7, d1
	lea	vect_bitsns, a0
	move.l	(a0), a0
	jsr	(a0)

	move.b	d0, d1
	and.b	#$10, d0
	lsl.b	#4, d1
	and.b	#$80, d1
	or.b	d1, d0
	or.b	d2, d0

	bra	bitsns_ret

bitsns_9:
	and.b	#$ed, d0
	move.b	d0, d2

	move.l	#_BITSNS, d0
	move.w	#7, d1
	lea	vect_bitsns, a0
	move.l	(a0), a0
	jsr	(a0)

	move.b	d0, d1
	lsr.b	#2, d0
	and.b	#$10, d0
	lsr.b	#4, d1
	and.b	#$02, d1
	or.b	d1, d0
	or.b	d2, d0

bitsns_ret:
	movem	(sp)+, d1-d2/a0
	rts

start:
	moveq.l #0, d7
	cmp.b	#0, (a2)
	beq	intvcs
	cmp.b	#2, (a2)+
	bne	invalid_args
	cmp.b	#'-', (a2)+
	bne	invalid_args
	cmp.b	#'r', (a2)
	bne	invalid_args
	moveq.l	#1, d7

intvcs:
	move.w	#$100+_BITSNS, d1
	lea	iocs_bitsns, a1
	IOCS	_B_INTVCS

	lea	vect_bitsns, a1
	move.l	d0, (a1)

	subq.l	#4, d0
	move.l	d0, a1
	IOCS	_B_LPEEK
	cmp.l	#'SioK', d0
	beq	already_installed

not_installed:
	cmp.l	#0, d7
	beq	install

	pea	msg_not_installed
	DOS	_PRINT
	addq.l	#4, sp
	bra	restore_exit

install:
	pea	msg_installed
	DOS	_PRINT
	addq.l	#4, sp

	move.w	#0, -(sp)
	move.l	#start-vect_bitsns, -(sp)
	DOS	_KEEPPR

already_installed:
	cmp.l	#0, d7
	bne	uninstall

	pea	msg_already_installed
	DOS	_PRINT
	addq.l	#4, sp

	bra	restore_exit

uninstall:
	lea	vect_bitsns, a0
	move.l	(a0), a0
	subq.l	#8, a0
	move.l	(a0), a1
	move.w	#$100+_BITSNS, d1
	IOCS	_B_INTVCS

	lea	vect_bitsns, a0
	move.l	(a0), a0
	sub.l	#$f8, a0
	move.l	a0, -(sp)
	DOS	_MFREE
	addq.l	#4, sp
	cmp.l	#0, d0
	bpl	uninstall_done
	pea	msg_mfree_fail
	DOS	_PRINT
	addq.l	#4, sp

uninstall_done:
	pea	msg_uninstalled
	DOS	_PRINT
	addq.l	#4, sp

	DOS	_EXIT

restore_exit
	move.w	#$100+_BITSNS, d1
	lea	vect_bitsns, a1
	move.l	(a1), a1
	IOCS	_B_INTVCS

	DOS	_EXIT

invalid_args:
	pea	msg_invalid_args
	DOS	_PRINT
	addq.l	#4, sp

	DOS	_EXIT

	.data
	.even

msg_installed:
	.dc.b	'sionkey is successfully installed', 13, 10, 0
msg_uninstalled:
	.dc.b	'sionkey is successfully uninstalled', 13, 10, 0
msg_already_installed:
	.dc.b	'sionkey is already installed', 13, 10, 0
msg_not_installed:
	.dc.b	'sionkey is not installed', 13, 10, 0
msg_invalid_args:
	.dc.b	'sionkey exits due to invalid command line parameters', 13, 10, 0
msg_mfree_fail:
	.dc.b	'sionkey fails to release installed memory', 13, 10, 0

	.end	start
