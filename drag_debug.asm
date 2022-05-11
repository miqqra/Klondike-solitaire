asect 0x00
place:	
	#get "to" card address
		ldi r2, from_to
		ld 	r2, r2
		ldi r0, 0b00001111		#mask to get number of "to" column
		and r0, r2				#r2 = number of "to" column
		jsr getstart			#r3 -> first open card of "to" column
		push r3					#we will use this address in the end	
	#find first empty cell: it's address - cell where we will drag cards
	#the previous cell contains card on which we will drag
	#later we will compare this card with "from" card
		ldi r0, 0b01000000	#get "is end" bit
		while
			ld r3, r1		#load current card in r1
			and r0, r1		#r1 = 0 => it's empty or sentinel, r1 = 64 => just card -> proceed	
			stays nz
			inc r3			#check next cell
		wend
		push r3					#stack keeps address of where we should put "from" cards
		dec r3					#r3 = last not empty cell
		ld r3, r1				#r1 = last non-zero card = "to" card
	#check if it's possible to drag cards from column with number r2 on "to" card
	#(2 on 3, 3 on 4,..., 8 on 9, 9 on sentinel = empty column)
		ldi r2, from_to			#get "from" column number in r2
		ld	r2, r2
		shra r2
		shra r2
		shra r2
		shra r2
		jsr getstart			#r3 -> first open card of "from" column
		ldi r0, 0b00001111		#get card's 4 first bits - its value
		and r0, r1				#r1 = value of "to" card
		dec r1					#r1 = value of a card that can be placed on "to" card
		if
			dec r1				##if r1 = 1 (r1 - 1 = 0), the column is full, we cannot
			is z				#place anything on it
			halt
		fi
		inc r1					#return normal r1 value
	#find address of a card which can be placed on "to" card or exit if it's impossible,
	#place this address in r3
		while					#r3 -> current card
			ld r3, r2			#r2 = current card
			##if r2 is zero card - we didn't find a card to place to "to" card
			if
				and r0, r2			#r2 = value of current card
				is z			#it's enough to check for zero card because if sentinel
				halt			#was reached, we would have all cards 9-2			
			fi					#so a match with r1 should be found
			cmp r1, r2			#0 => r1 = r2 => r2 is a card to place
			stays ne
			inc r3				
		wend
	#make ancestor of "from" card visible +	
	#copy all the cards starting with "from" until the first empty cell
	#NOTE: we can't accidently get to next column if the "from" one is full
	#see explanation at part when we looked for "to" address
		ldi r0, 0b01111111
		dec r3					#r3 -> ancestor of "from" card
		ld r3, r2				#r2 = ancestor of "from" card
		and r0, r2				#r2 = the same, but now open
		st r3, r2				#mem[r3] = open ancestor of "from" card
		inc r3
		#moves cards from r3 to r1, clears them in r3 (stops when sees zero card)
		pop r1					#r1 -> where store
		ldi r0, 0b01000000		#get "is_end" bit
		while
			ld r3, r2			#r2 = current card
			and r0, r2			#r2 = 0 if we must stop (empty or sentinel), 1 otherwise
			stays nz			#while current cell is not the end
				ld r3, r2		#now restore r1 value
				st r1, r2		#mem[r1] = current card
				ldi r2, 0	
				st r3, r2		#clears mem[r3] from moved card
				inc r3			#r3 -> next card
				inc r1			#r1 = next empty cell
		wend
	#try to find full deck in "to" column
	pop r3						#in the beginning we pushed start of "to" column
	push r3						#to clear it after we are done
	ldi r0, 0b01001001			#r0 = what card we anticipate to complete deck
	while
		ld r3, r2				#r2 = current card
		cmp r2, r0				#r2 is what we anticipate to see
		stays eq
		inc r3					#r3 -> next card
		dec r0					#r0 is anticipated to be r0 - 1 next time
	wend
	ldi r1, 0b01000001			#r1 = what we should end up with
	if
		cmp r1, r0
		is ne
		halt					#deck is not full => don't do anything
	fi
	pop r3					#now clear it
	dec r3					#let's open previous card
	ldi r0, 0b01111111		
	ld r3, r2				#r2 = prev card
	and r0, r2				#r2 = prev card, but open
	st r3, r2				#mem[r3] is now openned
	ldi r0, 0b01000000		#get "is_end" bit
	while
		inc r3				#r3 -> next card
		ld r3, r2			#r2 = current card
		and r0, r2			#r2 = 0 if we must stop (empty or sentinel), 1 otherwise
		stays nz			#while current cell is not the end
			ldi r2, 0	
			st r3, r2		#clears mem[r3] from card of the completed deck
	wend
	ldi r3, count_win
	ld r3, r2
	inc r2
	st r3, r2
	halt
#---------REGISTERS-------------- 
#r0, r2 - undefined
#r3 = result
#---------Description------------
#recieves 4-bit number in r2 (big-endian) - number of a column 
#stores address of the first open card in the column under number r2 in r3
getstart:
		ldi r3, deck_offset		#r3 -> array of addresses of roots of columns	
		dec r2					#r2 = how many columns should we skip
		add r2, r3				#r3 -> address of root of r2 column 
		ld r3, r3				#r3 = address of root of r2 column 		
	#find first open card
		ldi r0, 0b10000000	#get opennes bit
		while
			inc r3
			ld r3, r2
			and r0, r2		#r2 = 0 if open, r2 = 128 if closed
			stays nz		##if it is closed (not 0) continue seeking
		wend				#now r3 = first open cell
		rts					

asect 0x90
deck: dc 0x0A, 0x49, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0A, 0x48, 0x47, 0x46, 0x45, 0x44, 0x43, 0x42, 0x00, 0x00, 0x0A, 0xc8, 0xc3, 0xc3, 0x47, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0A, 0xc5, 0xc6, 0xc3, 0x48, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0A, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0A, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0A, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
deck_offset: dc deck, deck + 9, deck + 19, deck + 30, deck + 42, deck + 55, deck + 69
INPUT>
from_to: dc 0x21
define count_win, 0xf4
end 