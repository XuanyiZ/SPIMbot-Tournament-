##v1.3 add requesting fire starters

##only plant (x+y)/2 = 0 tiles !!

##first goto 0,0

##TODO: 

##

##2.Decision function

##5.Watering function    !!!

##6.Putout fire function  !!!

##7.Firing function

##*Moving Path??

##*Seeding or watering or firing alone the path to harvest

##Done:

##1.Puzzle solver function     

##3.Move function

##4.Planting function

##8.harvesting function

##Information:

##solving a puzzle gives 3 seeds or 10 water or 1 fireStarter

##starts with 10 seeds & 100 water & 1 fireStarter

##





# syscall constants

PRINT_STRING = 4

PRINT_CHAR   = 11

PRINT_INT    = 1



# debug constants

PRINT_INT_ADDR   = 0xffff0080

PRINT_FLOAT_ADDR = 0xffff0084

PRINT_HEX_ADDR   = 0xffff0088



# spimbot constants

VELOCITY       = 0xffff0010

ANGLE          = 0xffff0014

ANGLE_CONTROL  = 0xffff0018

BOT_X          = 0xffff0020

BOT_Y          = 0xffff0024

OTHER_BOT_X    = 0xffff00a0

OTHER_BOT_Y    = 0xffff00a4

TIMER          = 0xffff001c

SCORES_REQUEST = 0xffff1018



TILE_SCAN       = 0xffff0024

SEED_TILE       = 0xffff0054

WATER_TILE      = 0xffff002c

MAX_GROWTH_TILE = 0xffff0030

HARVEST_TILE    = 0xffff0020

BURN_TILE       = 0xffff0058

GET_FIRE_LOC    = 0xffff0028

PUT_OUT_FIRE    = 0xffff0040



GET_NUM_WATER_DROPS   = 0xffff0044

GET_NUM_SEEDS         = 0xffff0048

GET_NUM_FIRE_STARTERS = 0xffff004c

SET_RESOURCE_TYPE     = 0xffff00dc

REQUEST_PUZZLE        = 0xffff00d0

SUBMIT_SOLUTION       = 0xffff00d4



# interrupt constants

BONK_MASK               = 0x1000

BONK_ACK                = 0xffff0060

TIMER_MASK              = 0x8000

TIMER_ACK               = 0xffff006c

ON_FIRE_MASK            = 0x400

ON_FIRE_ACK             = 0xffff0050

MAX_GROWTH_ACK          = 0xffff005c

MAX_GROWTH_INT_MASK     = 0x2000

REQUEST_PUZZLE_ACK      = 0xffff00d8

REQUEST_PUZZLE_INT_MASK = 0x800



.data

# data things go here

.align 2

tile_data: .space 1600

puzzle: .space 4096

solution: .space 328

hasPuzzle: .space 4

plantsToHarvest: .space 4

harvestPlatnTile: .space 4

myLocation: .space 4

currentTile: .space 4

currentTileX: .space 4

currentTileY: .space 4

direction: .space 4

requestedPuzzle: .space 4

destinationX: .space 4

destinationY: .space 4

destinationQueue: .space 3200 #400*8 

currentDestIndex: .space 4

queueLength: .space 4

addedTileQueue: .space 400 #100*4 to mark if a max_growth tile has been added to queue

.text

main:

	# go wild

	# the world is your oyster :)

  

  sw $0,VELOCITY



  



#initilization module

init:

##copied to clear out addedTileQueue

    li $t0,0

    la $t3,addedTileQueue

  first_loop2:

    bge $t0,100,first_out_of_loop2

    sw $0,0($t3)

    add $t3,$t3,4

  first_loop_inc2:

    add $t0,$t0,1

    j first_loop2

  first_out_of_loop2:





  li $t0, REQUEST_PUZZLE_INT_MASK  #initilaztion interruption

	or $t0, $t0,1

	li $t1,BONK_MASK

  or $t0, $t0,$t1

  li $t1, ON_FIRE_MASK

  or $t0, $t0,$t1

  li $t1, MAX_GROWTH_INT_MASK

  or $t0, $t0,$t1

  mtc0 $t0,$12

  #finish setting interruption

  sw $0,hasPuzzle

  sw $0,plantsToHarvest

  sw $0,direction

  sw $0,requestedPuzzle

  li $t0,0

  la $t1,destinationQueue

  sw $t0,0($t1)

  sw $t0,4($t1)

  li $t0,1

  sw $t0,queueLength

  sw $0,currentDestIndex



#finish initilization



#decision module

#first version: no water and fire; plant seed when avaliable, request puzzle when no seed 

#

  li $a0,1

  jal request_puzzle

  sw $0,SEED_TILE



decision:	

  lw $t0,plantsToHarvest

  beq $t0,0,afterLoop

#loop through all the tiles when have plantsToHarvest

	la $t0, tile_data

	sw $t0, TILE_SCAN

	 sub $sp,$sp,16

	li $t1,0  #t1 =i

for_loop:

	bge $t1,100,out_of_loop

	mul $t2, $t1,16

	add $t2,$t0,$t2

	lw $t3,4($t2)

	beq $t3,1,loop_inc #if other bot, continue

  lw $t3,8($t2)

  blt $t3,512,loop_inc#if not max growth, continue

#max_growth, add to destination queue

# first test if it is already added

  mul $t5,$t1,4

  la $t6,addedTileQueue

  add $t5,$t5,$t6

  lw $t6,0($t5)

  bne $t6,0,loop_inc #already added , continue

  add $t6,$t6,1

  sw $t6,0($t5) #not added, mark to 1

#debug

  li $v0,PRINT_INT

  move $a0,$t1

  #syscall  



  lw $t5,queueLength

  mul $t4,$t5,8

  la $t6,destinationQueue

  add $t4,$t4,$t6 #t4 = address of the first entry after the queue

  li $t6,10

  div $t1,$t6

  mfhi $a0

  mflo $a1

  sw $a0,0($t4)

  sw $a1,4($t4)

  add $t5,$t5,1

  sw $t5,queueLength

#

#  sw $t0,0($sp)

#  sw $t1,4($sp)

#  sw $t2,8($sp)

#  sw $ra,12($sp)

#  li $t0,10

#  div $t1,$t0

#  mfhi $a0

#  mflo $a1

#  jal harvestPlant

#  sw $0,VELOCITY

#  lw $t0,0($sp)

#  lw $t1,4($sp)

#  lw $t2,8($sp)

#  lw $ra,12($sp)

loop_inc:

	add $t1,$t1,1

	j for_loop



out_of_loop:

	add $sp,$sp,16

  sw $0,plantsToHarvest

	sw $0,VELOCITY

#finish traversal all the tiles

afterLoop:

	lw $t0,hasPuzzle

  bne $t0,0,solvePuzzle  #if hasPuzzle then solvePuzzle()

label2:

  lw $t0,GET_NUM_SEEDS

  ble $t0,5,request_puzzle_1

  lw $t0,GET_NUM_WATER_DROPS

  ble $t0,50,request_puzzle_0

  lw $t0,GET_NUM_FIRE_STARTERS

  ble $t0,1,request_puzzle_2

#process this tile

label5:

  sub $sp,$sp,4

  sw $ra,0($sp)

  jal getCurrentTile 

  lw $ra,0($sp)

  add $sp,$sp,4

  lw $t0,currentTileX

  lw $t1,currentTileY

  la $t3,tile_data

  sw $t3,TILE_SCAN

  mul $t1,$t1,10

  add $t0,$t0,$t1

  mul $t0,$t0,16

  add $t3,$t3,$t0 #t3 is the address of currentTile

  lw $t0,0($t3)

  bne $t0,0,label3

# if is empty

  #if x+y %2 == 0

  lw $t0,currentTileX

  lw $t1,currentTileY

  add $t0,$t0,$t1

  and $t0,$t0,1

  bne $t0,0,getDirection

  sw $0,SEED_TILE

  li $a0,10  

  sw $a0,WATER_TILE



  j getDirection

label3:#not empty

  lw $t0,4($t3)

  beq $t0,1,enemyTile

#myTile not Empty:

  lw $t0,8($t3)

  blt $t0,512,getDirection #not max growth

  #maxGrowth

  sw $0,HARVEST_TILE

  lw $t0,currentTileX

  lw $t1,currentTileY

  mul $t1,$t1,10

  add $t0,$t0,$t1

  mul $t0,$t0,4

  la $t1,addedTileQueue

  add $t1,$t1,$t0

  sw $0,0($t1)

  #li $a0,10  

  #sw $a0,WATER_TILE

  j getDirection

enemyTile:

  sw $0,BURN_TILE

  j getDirection

#

label:

  #lw $t0,plantsToHarvest

  #bne $t0,0,harvest_plant  #if has plant to harvest then harvestPlant()

  j gotoNextTile #Go to next tile

#getDirection according to currentTile and destination

#not function, set up direction 

getDirection:

  lw $t4,currentDestIndex

  mul $t4,$t4,8

  la $t0,destinationQueue

  add $t4,$t4,$t0

  lw $t2,0($t4)

  lw $t3,4($t4)

  lw $t0,currentTileX

  lw $t1,currentTileY



  sub $t0,$t0,$t2

  sub $t1,$t1,$t3

  blt $t0,0,setDirection1

  bgt $t0,0,setDirection3

  blt $t1,0,setDirection2

  bgt $t1,0,setDirection0

  #arrived at destination,set next destination

  lw $t4,currentDestIndex

  add $t4,$t4,1

  sw $t4,currentDestIndex

  lw $t5,queueLength

#debug

  li $v0, PRINT_INT

  move $a0,$t5

  #syscall

#debug end  

  blt $t4,$t5,label #if still have avalaiable dest,just increase the currentDestIndex

#if at the end of the queue

  mul $t1,$t5,8

  la $t6,destinationQueue

  add $t1,$t1,$t6 #t1 = address of the first entry after the queue

  li $t0,9

  sub $t2,$t0,$t2

  sub $t3,$t0,$t3

  sw $t2,0($t1)

  sw $t3,4($t1)

  add $t5,$t5,1

  sw $t5,queueLength

  j getDirection  

setDirection0:

  li $t0,0

  sw $t0,direction

  j label

setDirection1:

  li $t0,1

  sw $t0,direction

  j label

setDirection2:

  li $t0,2

  sw $t0,direction

  j label

setDirection3:

  li $t0,3

  sw $t0,direction

  j label

request_puzzle_1:

  #debug

  li $a0,1

  jal request_puzzle

  j label5

request_puzzle_0:

  #debug

  li $a0,0

  jal request_puzzle

  j label5

request_puzzle_2:

  #debug

  li $a0,2

  jal request_puzzle

  j label5

solve_Puzzle:

	jal solvePuzzle

  j label2

harvest_plant:

    jal harvestPlant

    j decision

gotoNextTile:	

	lw $a0,direction



	jal moveDirection

	#busy wait for a while to ensure all interruptions got caught

	#li $t5,0

	#sleep:

   #	add $t5,$t5,1

   #	blt $t5,9999,sleep

	

	#sw $0,SEED_TILE	

	beq $v0,1,done4 #move successful

	#can't move, change direction clockwise

	lw $a0,direction

	add $a0,$a0,1 

	li $t0,4

	div $a0,$t0

	mfhi $a0

	sw $a0,direction

done4:

	j decision

##functions below are all helper function written by txu25

	



##function void request_puzzle(int resource_type; 

## resource_type: 0:water 1:seed 2:fireStarter

request_puzzle:

  lw $t0, requestedPuzzle

  bne $t0,0,done5

  add $t0,$t0,1

  sw $t0, requestedPuzzle

  sw $a0, SET_RESOURCE_TYPE

  la $t0,puzzle

  sw $t0,REQUEST_PUZZLE

done5:

  jr $ra



##function void solve_puzzle();

##called when a puzzle is ready to solve

solvePuzzle:

  la $a0,solution

  la $a1,puzzle

  sub $sp,$sp,4 

  sw $ra,0($sp)

  jal recursive_backtracking

  sw $0,hasPuzzle

  la $a0,solution

  sw $a0,SUBMIT_SOLUTION

  lw $ra,0($sp)

  add $sp,$sp,4

  sw $0,requestedPuzzle

#clear out solution

  li $t0,0

  la $t3,solution

loop2:

  bge $t0,82,out_of_loop2

  mul $t1,$t0,4

  add $t1,$t1,$t3

  sw $0,0($t1)

loop_inc2:

  add $t0,$t0,1

  j loop2

out_of_loop2:

  jr $ra



  li $t0,0

  la $t3,puzzle

loop3:

  bge $t0,1024,out_of_loop3

  mul $t1,$0,4

  add $t1,$t1,$t3

  sw $0,0($t3)

loop_inc3:

  add $t0,$t0,1

  j loop3

out_of_loop3:

  

  jr $ra



##function void harvestPlant(int x,int y); iterate over tiles and see harvest the plant 

## x,y are coordiantes of tile

harvestPlant:

  sub $sp,$sp,8 

  sw $ra,0($sp)

  #loop: find the plant to harvest and call move to that tile and harvest

  #and $a1,$a0,0xffff  #a1 = y

  #srl $a0,$a0,16      #a0 = x



  sw $a0,4($sp)

  jal moveTo

  sw $0, VELOCITY

  lw $a0,4($sp)

  lw $ra,0($sp)

  sw $0, HARVEST_TILE

  lw $a0,plantsToHarvest

  sub $a0,$a0,1

  sw $a0,plantsToHarvest

  add $sp,$sp,8

  jr $ra



##function void moveTo(int x,int y); 

##moving to a tile

##

##x,y is the tile coordiante

##



moveTo:

tile_to_xy: #TODO: can be extracted as a function

  mul $a1,$a1,30

  add $a1,$a1,15

  mul $a0,$a0,30

  add $a0,$a0,15





  move $t1, $a0

  move $t2, $a1

stupid_move: #move alone x axis first, then move alone y axis

  sw $zero, ANGLE

  li $t0,1

  sw $t0, ANGLE_CONTROL

first_while:

  lw $t3,BOT_X #t3 cur x

  sub $t5,$t1,$t3

  ble $t5,0,second_if

  li $t6,10

  sw $t6,VELOCITY

  j first_while 

second_if:

  bge $t5,0,out_first_while

  li $t6,-10

  sw $t6,VELOCITY

  j first_while



out_first_while:

  sw $0,VELOCITY

  li $t5,90

  sw $t5,ANGLE

  li $t5,1

  sw $t5, ANGLE_CONTROL



second_while:

  lw $t4,BOT_Y #t4 cur y

  sub $t5,$t2,$t4

  ble $t5,0,second_if2

  li $t6,10

  sw $t6,VELOCITY

  j second_while 

second_if2:

  bge $t5,0,done2

  li $t6,-10

  sw $t6,VELOCITY

  j second_while

done2:

  sw $zero, ANGLE

  li $t1,1

  sw $t1, ANGLE_CONTROL

  sw $0, VELOCITY

  jr $ra



## bool moveDirection(int dir) 

## @para dir 0 up ,1 right, 2 down, 3 left 

## @return canMove

## moves to the next tile according to the direction

## returns if can move

moveDirection:

    sub $sp,$sp,8

    sw $ra,0($sp)

    sw $a0,4($sp)

    jal getCurrentTile

    lw $t0,currentTileX

    lw $t1,currentTileY

    lw $a0,4($sp)

    beq $a0,0,move0

    beq $a0,1,move1

    beq $a0,2,move2

    beq $a0,3,move3

    j done3

move0:

    sub $t1,$t1,1

    blt $t1,0,noMove

    j done3

move1:

    add $t0,$t0,1

    bgt $t0,9,noMove

    j done3

move2:

    add $t1,$t1,1

    bgt $t1,9,noMove

    j done3

move3:

    sub $t0,$t0,1

    blt $t0,0,noMove

    j done3

noMove:

    li $v0,0

    j return1

done3:



    move $a0,$t0

    move $a1,$t1

    jal moveTo

    li $v0,1

return1:    

    lw $ra,0($sp) 

    add $sp,$sp,8

    jr $ra

## getCurrentTile()

## store the current tile x to currentTileX

## store the current tile y to currentTileY

getCurrentTile:

  lw $t0, BOT_X

  lw $t1, BOT_Y

  li $t3,30

  div $t0, $t3

  mflo $t0

  div $t1, $t3

  mflo $t1  

  sw $t0,currentTileX

  sw  $t1,currentTileY

  jr $ra





.kdata# interrupt handler data (separated just for readability)

chunkIH:	.space 40	# space for 10 registers

.ktext 0x80000180

interrupt_handler:   #7 registers can be used!! t0,t1,t2,t3,t4,t5,t6,k0,k1,a0,a1

.set noat 

	move	$k1, $at		# Save $at     

.set at

	la	$k0, chunkIH

	sw	$t0, 0($k0)		# Get some free registers                  

	sw	$t1, 4($k0)		# by storing them to a global variable

	sw	$t2, 8($k0)	     

	sw	$k1, 12($k0)

	sw	$a0, 16($k0)

	sw	$a1, 20($k0)

	sw	$t3, 24($k0)	

	sw	$t4, 28($k0)	

	sw	$t5, 32($k0)	

	sw	$t6, 36($k0)	

dispatch:

  sw $0,VELOCITY

	mfc0	$k0, $13		# Get Cause register   

	and	$t0, $k0, REQUEST_PUZZLE_INT_MASK		# ExcCode field  

	bne $t0,0,puzzle_intrrupt

  and $t0, $k0, MAX_GROWTH_INT_MASK

  bne $t0,0,max_growth_interrupt

  and $t0, $k0, BONK_MASK

  bne $t0,0, bonk_interrupt

  j done

bonk_interrupt:

  #sw $0,BONK_ACK

  j dispatch

puzzle_intrrupt:

  li $t0,1

  sw $t0,hasPuzzle #hasPuzzle = 1

  sw $t0,REQUEST_PUZZLE_ACK #ack request_puzzle

  j dispatch

max_growth_interrupt: #decided to handle this in the interruption instead of in the main

  ###!!This interruption has weird behavior, decide to do nothing here!!

  #lw $t0, plantsToHarvest

  #add $t0,$t0,1

  #sw $t0,plantsToHarvest

getMaxGrowthTile:

  

  #lw $a0,MAX_GROWTH_TILE

  sw $t0,MAX_GROWTH_ACK

  li $a0,1

  sw $a0,plantsToHarvest

  j dispatch



  #sw $a0,harvestPlatnTile

  and $a1,$a0,0xffff  #a1 = y

  srl $a0,$a0,16      #a0 = x

  #moveTo:

#tile_to_xy: #TODO: can be extracted as a function



  mul $a1,$a1,30

  add $a1,$a1,15

  mul $a0,$a0,30

  add $a0,$a0,15





  move $t1, $a0

  move $t2, $a1

max_stupid_move: #move alone x axis first, then move alone y axis

  sw $zero, ANGLE

  li $t0,1

  sw $t0, ANGLE_CONTROL

max_first_while:

  lw $t3,BOT_X #t3 cur x

  sub $t5,$t1,$t3

  ble $t5,0,max_second_if

  li $t6,10

  sw $t6,VELOCITY

  j max_first_while 

max_second_if:

  bge $t5,0,max_out_first_while

  li $t6,-10

  sw $t6,VELOCITY

  j max_first_while



max_out_first_while:

  sw $0,VELOCITY

  li $t5,90

  sw $t5,ANGLE

  li $t5,1

  sw $t5, ANGLE_CONTROL



max_second_while:

  lw $t4,BOT_Y #t4 cur y

  sub $t5,$t2,$t4

  ble $t5,0,max_second_if2

  li $t6,10

  sw $t6,VELOCITY

  j max_second_while 

max_second_if2:

  bge $t5,0,max_done2

  li $t6,-10

  sw $t6,VELOCITY

  j max_second_while

max_done2:

  sw $0, VELOCITY

  sw $zero, ANGLE

  li $t1,1

  sw $t1, ANGLE_CONTROL

  #sw $t0,MAX_GROWTH_ACK

  sw $0,HARVEST_TILE

  j dispatch

  

done:

	la	$k0, chunkIH

	lw	$t0, 0($k0)		# Restore saved registers

	lw	$t1, 4($k0)

	lw	$t2, 8($k0)

	lw	$k1, 12($k0)

	lw	$a0, 16($k0)

	lw	$a1, 20($k0)

	lw	$t3, 24($k0)	

	lw	$t4, 28($k0)	

	lw	$t5, 32($k0)	

	lw	$t6, 36($k0)	

.set noat

	move	$at, $k1		# Restore $at

.set at 

	eret

##

##---------------------------------------------------------------------------

## Everything below are provided by the TAs in _shared/Lab7 and _shared/Lab8

##

##



## int convert_highest_bit_to_int(int domain) {

##   int result = 0;

##   for (; domain; domain >>= 1) {

##     result ++;

##   }

##   return result;

## }

.text

.globl convert_highest_bit_to_int

convert_highest_bit_to_int:

    move  $v0, $0   	      # result = 0



chbti_loop:

    beq   $a0, $0, chbti_end

    add   $v0, $v0, 1         # result ++

    sra   $a0, $a0, 1         # domain >>= 1

    j     chbti_loop



chbti_end:

    jr	  $ra





## int get_domain_for_addition(int target, int num_cell, int domain) {

##   int upper_bound = convert_highest_bit_to_int(domain);

##

##   // For an integer i, i & -i keeps only the lowest 1 in the integer.

##   int lower_bound = convert_highest_bit_to_int(domain & (-domain));

##

##   int high_bits = target - (num_cell - 1) * lower_bound;

##   if (high_bits < 0) {

##     high_bits = 0;

##   }

##   if (high_bits < upper_bound) {

##     domain = domain & ((1 << high_bits) - 1);

##   }

##

##   int low_bits = target - (num_cell - 1) * upper_bound;

##   if (low_bits > 0) {

##     domain = domain >> (low_bits - 1) << (low_bits - 1);

##   }

##

##   return domain;

## }



.globl get_domain_for_addition

get_domain_for_addition:

    sub    $sp, $sp, 20

    sw     $ra, 0($sp)

    sw     $s0, 4($sp)

    sw     $s1, 8($sp)

    sw     $s2, 12($sp)

    sw     $s3, 16($sp)

    move   $s0, $a0                     # s0 = target

    move   $s1, $a1                     # s1 = num_cell

    move   $s2, $a2                     # s2 = domain



    move   $a0, $a2

    jal    convert_highest_bit_to_int

    move   $s3, $v0                     # s3 = upper_bound



    sub    $a0, $0, $s2	                # -domain

    and    $a0, $a0, $s2                # domain & (-domain)

    jal    convert_highest_bit_to_int   # v0 = lower_bound

	   

    sub    $t0, $s1, 1                  # num_cell - 1

    mul    $t0, $t0, $v0                # (num_cell - 1) * lower_bound

    sub    $t0, $s0, $t0                # t0 = high_bits

    bge    $t0, 0, gdfa_skip0



    li     $t0, 0



gdfa_skip0:

    bge    $t0, $s3, gdfa_skip1



    li     $t1, 1          

    sll    $t0, $t1, $t0                # 1 << high_bits

    sub    $t0, $t0, 1                  # (1 << high_bits) - 1

    and    $s2, $s2, $t0                # domain & ((1 << high_bits) - 1)



gdfa_skip1:	   

    sub    $t0, $s1, 1                  # num_cell - 1

    mul    $t0, $t0, $s3                # (num_cell - 1) * upper_bound

    sub    $t0, $s0, $t0                # t0 = low_bits

    ble    $t0, $0, gdfa_skip2



    sub    $t0, $t0, 1                  # low_bits - 1

    sra    $s2, $s2, $t0                # domain >> (low_bits - 1)

    sll    $s2, $s2, $t0                # domain >> (low_bits - 1) << (low_bits - 1)



gdfa_skip2:	   

    move   $v0, $s2                     # return domain

    lw     $ra, 0($sp)

    lw     $s0, 4($sp)

    lw     $s1, 8($sp)

    lw     $s2, 12($sp)

    lw     $s3, 16($sp)

    add    $sp, $sp, 20

    jr     $ra



## int get_domain_for_subtraction(int target, int domain, int other_domain) {

##   int base_mask = 1 | (1 << (target * 2));

##   int mask = 0;

##   for (; other_domain; other_domain >>= 1) {

##     if (other_domain & 1) {

##       mask |= (base_mask >> target);

##     }

##     base_mask <<= 1;

##   }

##   return domain & mask;

## }



.globl get_domain_for_subtraction

get_domain_for_subtraction:

    li     $t0, 1              

    li     $t1, 2

    mul    $t1, $t1, $a0            # target * 2

    sll    $t1, $t0, $t1            # 1 << (target * 2)

    or     $t0, $t0, $t1            # t0 = base_mask

    li     $t1, 0                   # t1 = mask



gdfs_loop:

    beq    $a2, $0, gdfs_loop_end	

    and    $t2, $a2, 1              # other_domain & 1

    beq    $t2, $0, gdfs_if_end

	   

    sra    $t2, $t0, $a0            # base_mask >> target

    or     $t1, $t1, $t2            # mask |= (base_mask >> target)



gdfs_if_end:

    sll    $t0, $t0, 1              # base_mask <<= 1

    sra    $a2, $a2, 1              # other_domain >>= 1

    j      gdfs_loop



gdfs_loop_end:

    and    $v0, $a1, $t1            # domain & mask

    jr	   $ra





## int is_single_value_domain(int domain) {

##   if (domain != 0 && (domain & (domain - 1)) == 0) {

##     return 1;

##   }

##   return 0;

## }



.globl is_single_value_domain

is_single_value_domain:

    beq    $a0, $0, isvd_zero     # return 0 if domain == 0

    sub    $t0, $a0, 1	          # (domain - 1)

    and    $t0, $t0, $a0          # (domain & (domain - 1))

    bne    $t0, $0, isvd_zero     # return 0 if (domain & (domain - 1)) != 0

    li     $v0, 1

    jr	   $ra



isvd_zero:	   

    li	   $v0, 0

    jr	   $ra



## struct Cage {

##   char operation;

##   int target;

##   int num_cell;

##   int* positions;

## };

##

## struct Cell {

##   int domain;

##   Cage* cage;

## };

##

## struct Puzzle {

##   int size;

##   Cell* grid;

## };

##

## // Given the assignment at current position, removes all inconsistent values

## // for cells in the same row, column, and cage.

## int forward_checking(int position, Puzzle* puzzle) {

##   int size = puzzle->size;

##   // Removes inconsistent values in the row.

##   for (int col = 0; col < size; col++) {

##     if (col != position % size) {

##       puzzle->grid[position / size * size + col].domain &=

##           ~ puzzle->grid[position].domain;

##       if (!puzzle->grid[position / size * size + col].domain) {

##         return 0;

##       }

##     }

##   }

##   // Removes inconsistent values in the column.

##   for (int row = 0; row < size; row++) {

##     if (row != position / size) {

##       puzzle->grid[row * size + position % size].domain &=

##           ~ puzzle->grid[position].domain;

##       if (!puzzle->grid[row * size + position % size].domain) {

##         return 0;

##       }

##     }

##   }

##   // Removes inconsistent values in the cage.

##   for (int i = 0; i < puzzle->grid[position].cage->num_cell; i++) {

##     int pos = puzzle->grid[position].cage->positions[i];

##     puzzle->grid[pos].domain &= get_domain_for_cell(pos, puzzle);

##     if (!puzzle->grid[pos].domain) {

##       return 0;

##     }

##   }

##   return 1;

## }



.globl forward_checking

forward_checking:

  sub   $sp, $sp, 24

  sw    $ra, 0($sp)

  sw    $a0, 4($sp)

  sw    $a1, 8($sp)

  sw    $s0, 12($sp)

  sw    $s1, 16($sp)

  sw    $s2, 20($sp)

  lw    $t0, 0($a1)     # size

  li    $t1, 0          # col = 0

fc_for_col:

  bge   $t1, $t0, fc_end_for_col  # col < size

  div   $a0, $t0

  mfhi  $t2             # position % size

  mflo  $t3             # position / size

  beq   $t1, $t2, fc_for_col_continue    # if (col != position % size)

  mul   $t4, $t3, $t0

  add   $t4, $t4, $t1   # position / size * size + col

  mul   $t4, $t4, 8

  lw    $t5, 4($a1) # puzzle->grid

  add   $t4, $t4, $t5   # &puzzle->grid[position / size * size + col].domain

  mul   $t2, $a0, 8   # position * 8

  add   $t2, $t5, $t2 # puzzle->grid[position]

  lw    $t2, 0($t2) # puzzle -> grid[position].domain

  not   $t2, $t2        # ~puzzle->grid[position].domain

  lw    $t3, 0($t4) #

  and   $t3, $t3, $t2

  sw    $t3, 0($t4)

  beq   $t3, $0, fc_return_zero # if (!puzzle->grid[position / size * size + col].domain)

fc_for_col_continue:

  add   $t1, $t1, 1     # col++

  j     fc_for_col

fc_end_for_col:

  li    $t1, 0          # row = 0

fc_for_row:

  bge   $t1, $t0, fc_end_for_row  # row < size

  div   $a0, $t0

  mflo  $t2             # position / size

  mfhi  $t3             # position % size

  beq   $t1, $t2, fc_for_row_continue

  lw    $t2, 4($a1)     # puzzle->grid

  mul   $t4, $t1, $t0

  add   $t4, $t4, $t3

  mul   $t4, $t4, 8

  add   $t4, $t2, $t4   # &puzzle->grid[row * size + position % size]

  lw    $t6, 0($t4)

  mul   $t5, $a0, 8

  add   $t5, $t2, $t5

  lw    $t5, 0($t5)     # puzzle->grid[position].domain

  not   $t5, $t5

  and   $t5, $t6, $t5

  sw    $t5, 0($t4)

  beq   $t5, $0, fc_return_zero

fc_for_row_continue:

  add   $t1, $t1, 1     # row++

  j     fc_for_row

fc_end_for_row:



  li    $s0, 0          # i = 0

fc_for_i:

  lw    $t2, 4($a1)

  mul   $t3, $a0, 8

  add   $t2, $t2, $t3

  lw    $t2, 4($t2)     # &puzzle->grid[position].cage

  lw    $t3, 8($t2)     # puzzle->grid[position].cage->num_cell

  bge   $s0, $t3, fc_return_one

  lw    $t3, 12($t2)    # puzzle->grid[position].cage->positions

  mul   $s1, $s0, 4

  add   $t3, $t3, $s1

  lw    $t3, 0($t3)     # pos

  lw    $s1, 4($a1)

  mul   $s2, $t3, 8

  add   $s2, $s1, $s2   # &puzzle->grid[pos].domain

  lw    $s1, 0($s2)

  move  $a0, $t3

  jal get_domain_for_cell

  lw    $a0, 4($sp)

  lw    $a1, 8($sp)

  and   $s1, $s1, $v0

  sw    $s1, 0($s2)     # puzzle->grid[pos].domain &= get_domain_for_cell(pos, puzzle)

  beq   $s1, $0, fc_return_zero

fc_for_i_continue:

  add   $s0, $s0, 1     # i++

  j     fc_for_i

fc_return_one:

  li    $v0, 1

  j     fc_return

fc_return_zero:

  li    $v0, 0

fc_return:

  lw    $ra, 0($sp)

  lw    $a0, 4($sp)

  lw    $a1, 8($sp)

  lw    $s0, 12($sp)

  lw    $s1, 16($sp)

  lw    $s2, 20($sp)

  add   $sp, $sp, 24

  jr    $ra



## struct Puzzle {

##   int size;

##   Cell* grid;

## };

##

## struct Solution {

##   int size;

##   int assignment[81];

## };

##

## // Returns next position for assignment.

## int get_unassigned_position(const Solution* solution, const Puzzle* puzzle) {

##   int unassigned_pos = 0;

##   for (; unassigned_pos < puzzle->size * puzzle->size; unassigned_pos++) {

##     if (solution->assignment[unassigned_pos] == 0) {

##       break;

##     }

##   }

##   return unassigned_pos;

## }



.globl get_unassigned_position

get_unassigned_position:

  li    $v0, 0            # unassigned_pos = 0

  lw    $t0, 0($a1)       # puzzle->size

  mul  $t0, $t0, $t0     # puzzle->size * puzzle->size

  add   $t1, $a0, 4       # &solution->assignment[0]

get_unassigned_position_for_begin:

  bge   $v0, $t0, get_unassigned_position_return  # if (unassigned_pos < puzzle->size * puzzle->size)

  mul  $t2, $v0, 4

  add   $t2, $t1, $t2     # &solution->assignment[unassigned_pos]

  lw    $t2, 0($t2)       # solution->assignment[unassigned_pos]

  beq   $t2, 0, get_unassigned_position_return  # if (solution->assignment[unassigned_pos] == 0)

  add   $v0, $v0, 1       # unassigned_pos++

  j   get_unassigned_position_for_begin

get_unassigned_position_return:

  jr    $ra



## struct Puzzle {

##   int size;

##   Cell* grid;

## };

##

## struct Solution {

##   int size;

##   int assignment[81];

## };

##

## // Checks if the solution is complete.

## int is_complete(const Solution* solution, const Puzzle* puzzle) {

##   return solution->size == puzzle->size * puzzle->size;

## }



.globl is_complete

is_complete:

  lw    $t0, 0($a0)       # solution->size

  lw    $t1, 0($a1)       # puzzle->size

  mul   $t1, $t1, $t1     # puzzle->size * puzzle->size

  move	$v0, $0

  seq   $v0, $t0, $t1

  j     $ra





## struct Cage {

##   char operation;

##   int target;

##   int num_cell;

##   int* positions;

## };

##

## struct Cell {

##   int domain;

##   Cage* cage;

## };

##

## struct Puzzle {

##   int size;

##   Cell* grid;

## };

##

## struct Solution {

##   int size;

##   int assignment[81];

## };

##

## int recursive_backtracking(Solution* solution, Puzzle* puzzle) {

##   if (is_complete(solution, puzzle)) {

##     return 1;

##   }

##   int position = get_unassigned_position(solution, puzzle);

##   for (int val = 1; val < puzzle->size + 1; val++) {

##     if (puzzle->grid[position].domain & (0x1 << (val - 1))) {

##       solution->assignment[position] = val;

##       solution->size += 1;

##       // Applies inference to reduce space of possible assignment.

##       Puzzle puzzle_copy;

##       Cell grid_copy [81]; // 81 is the maximum size of the grid.

##       puzzle_copy.grid = grid_copy;

##       clone(puzzle, &puzzle_copy);

##       puzzle_copy.grid[position].domain = 0x1 << (val - 1);

##       if (forward_checking(position, &puzzle_copy)) {

##         if (recursive_backtracking(solution, &puzzle_copy)) {

##           return 1;

##         }

##       }

##       solution->assignment[position] = 0;

##       solution->size -= 1;

##     }

##   }

##   return 0;

## }



.globl recursive_backtracking

recursive_backtracking:

  sub   $sp, $sp, 680

  sw    $ra, 0($sp)

  sw    $a0, 4($sp)     # solution

  sw    $a1, 8($sp)     # puzzle

  sw    $s0, 12($sp)    # position

  sw    $s1, 16($sp)    # val

  sw    $s2, 20($sp)    # 0x1 << (val - 1)

                        # sizeof(Puzzle) = 8

                        # sizeof(Cell [81]) = 648



  jal   is_complete

  bne   $v0, $0, recursive_backtracking_return_one

  lw    $a0, 4($sp)     # solution

  lw    $a1, 8($sp)     # puzzle

  jal   get_unassigned_position

  move  $s0, $v0        # position

  li    $s1, 1          # val = 1

recursive_backtracking_for_loop:

  lw    $a0, 4($sp)     # solution

  lw    $a1, 8($sp)     # puzzle

  lw    $t0, 0($a1)     # puzzle->size

  add   $t1, $t0, 1     # puzzle->size + 1

  bge   $s1, $t1, recursive_backtracking_return_zero  # val < puzzle->size + 1

  lw    $t1, 4($a1)     # puzzle->grid

  mul   $t4, $s0, 8     # sizeof(Cell) = 8

  add   $t1, $t1, $t4   # &puzzle->grid[position]

  lw    $t1, 0($t1)     # puzzle->grid[position].domain

  sub   $t4, $s1, 1     # val - 1

  li    $t5, 1

  sll   $s2, $t5, $t4   # 0x1 << (val - 1)

  and   $t1, $t1, $s2   # puzzle->grid[position].domain & (0x1 << (val - 1))

  beq   $t1, $0, recursive_backtracking_for_loop_continue # if (domain & (0x1 << (val - 1)))

  mul   $t0, $s0, 4     # position * 4

  add   $t0, $t0, $a0

  add   $t0, $t0, 4     # &solution->assignment[position]

  sw    $s1, 0($t0)     # solution->assignment[position] = val

  lw    $t0, 0($a0)     # solution->size

  add   $t0, $t0, 1

  sw    $t0, 0($a0)     # solution->size++

  add   $t0, $sp, 32    # &grid_copy

  sw    $t0, 28($sp)    # puzzle_copy.grid = grid_copy !!!

  move  $a0, $a1        # &puzzle

  add   $a1, $sp, 24    # &puzzle_copy

  jal   clone           # clone(puzzle, &puzzle_copy)

  mul   $t0, $s0, 8     # !!! grid size 8

  lw    $t1, 28($sp)

  

  add   $t1, $t1, $t0   # &puzzle_copy.grid[position]

  sw    $s2, 0($t1)     # puzzle_copy.grid[position].domain = 0x1 << (val - 1);

  move  $a0, $s0

  add   $a1, $sp, 24

  jal   forward_checking  # forward_checking(position, &puzzle_copy)

  beq   $v0, $0, recursive_backtracking_skip



  lw    $a0, 4($sp)     # solution

  add   $a1, $sp, 24    # &puzzle_copy

  jal   recursive_backtracking

  beq   $v0, $0, recursive_backtracking_skip

  j     recursive_backtracking_return_one # if (recursive_backtracking(solution, &puzzle_copy))

recursive_backtracking_skip:

  lw    $a0, 4($sp)     # solution

  mul   $t0, $s0, 4

  add   $t1, $a0, 4

  add   $t1, $t1, $t0

  sw    $0, 0($t1)      # solution->assignment[position] = 0

  lw    $t0, 0($a0)

  sub   $t0, $t0, 1

  sw    $t0, 0($a0)     # solution->size -= 1

recursive_backtracking_for_loop_continue:

  add   $s1, $s1, 1     # val++

  j     recursive_backtracking_for_loop

recursive_backtracking_return_zero:

  li    $v0, 0

  j     recursive_backtracking_return

recursive_backtracking_return_one:

  li    $v0, 1

recursive_backtracking_return:

  lw    $ra, 0($sp)

  lw    $a0, 4($sp)

  lw    $a1, 8($sp)

  lw    $s0, 12($sp)

  lw    $s1, 16($sp)

  lw    $s2, 20($sp)

  add   $sp, $sp, 680

  jr    $ra



.globl clone

clone:



    lw  $t0, 0($a0)

    sw  $t0, 0($a1)



    mul $t0, $t0, $t0

    mul $t0, $t0, 2 # two words in one grid



    lw  $t1, 4($a0) # &puzzle(ori).grid

    lw  $t2, 4($a1) # &puzzle(clone).grid



    li  $t3, 0 # i = 0;

clone_for_loop:

    bge  $t3, $t0, clone_for_loop_end

    sll $t4, $t3, 2 # i * 4

    add $t5, $t1, $t4 # puzzle(ori).grid ith word

    lw   $t6, 0($t5)



    add $t5, $t2, $t4 # puzzle(clone).grid ith word

    sw   $t6, 0($t5)

    

    addi $t3, $t3, 1 # i++

    

    j    clone_for_loop

clone_for_loop_end:



    jr  $ra



  

.globl get_domain_for_cell

get_domain_for_cell:

    # save registers    

    sub $sp, $sp, 36

    sw $ra, 0($sp)

    sw $s0, 4($sp)

    sw $s1, 8($sp)

    sw $s2, 12($sp)

    sw $s3, 16($sp)

    sw $s4, 20($sp)

    sw $s5, 24($sp)

    sw $s6, 28($sp)

    sw $s7, 32($sp)



    li $t0, 0 # valid_domain

    lw $t1, 4($a1) # puzzle->grid (t1 free)

    sll $t2, $a0, 3 # position*8 (actual offset) (t2 free)

    add $t3, $t1, $t2 # &puzzle->grid[position]

    lw  $t4, 4($t3) # &puzzle->grid[position].cage

    lw  $t5, 0($t4) # puzzle->grid[posiition].cage->operation



    lw $t2, 4($t4) # puzzle->grid[position].cage->target



    move $s0, $t2   # remain_target = $s0  *!*!

    lw $s1, 8($t4) # remain_cell = $s1 = puzzle->grid[position].cage->num_cell

    lw $s2, 0($t3) # domain_union = $s2 = puzzle->grid[position].domain

    move $s3, $t4 # puzzle->grid[position].cage

    li $s4, 0   # i = 0

    move $s5, $t1 # $s5 = puzzle->grid

    move $s6, $a0 # $s6 = position

    # move $s7, $s2 # $s7 = puzzle->grid[position].domain



    bne $t5, 0, gdfc_check_else_if



    li $t1, 1

    sub $t2, $t2, $t1 # (puzzle->grid[position].cage->target-1)

    sll $v0, $t1, $t2 # valid_domain = 0x1 << (prev line comment)

    j gdfc_end # somewhere!!!!!!!!



gdfc_check_else_if:

    bne $t5, '+', gdfc_check_else



gdfc_else_if_loop:

    lw $t5, 8($s3) # puzzle->grid[position].cage->num_cell

    bge $s4, $t5, gdfc_for_end # branch if i >= puzzle->grid[position].cage->num_cell

    sll $t1, $s4, 2 # i*4

    lw $t6, 12($s3) # puzzle->grid[position].cage->positions

    add $t1, $t6, $t1 # &puzzle->grid[position].cage->positions[i]

    lw $t1, 0($t1) # pos = puzzle->grid[position].cage->positions[i]

    add $s4, $s4, 1 # i++



    sll $t2, $t1, 3 # pos * 8

    add $s7, $s5, $t2 # &puzzle->grid[pos]

    lw  $s7, 0($s7) # puzzle->grid[pos].domain



    beq $t1, $s6 gdfc_else_if_else # branch if pos == position



    



    move $a0, $s7 # $a0 = puzzle->grid[pos].domain

    jal is_single_value_domain

    bne $v0, 1 gdfc_else_if_else # branch if !is_single_value_domain()

    move $a0, $s7

    jal convert_highest_bit_to_int

    sub $s0, $s0, $v0 # remain_target -= convert_highest_bit_to_int

    addi $s1, $s1, -1 # remain_cell -= 1

    j gdfc_else_if_loop

gdfc_else_if_else:

    or $s2, $s2, $s7 # domain_union |= puzzle->grid[pos].domain

    j gdfc_else_if_loop



gdfc_for_end:

    move $a0, $s0

    move $a1, $s1

    move $a2, $s2

    jal get_domain_for_addition # $v0 = valid_domain = get_domain_for_addition()

    j gdfc_end



gdfc_check_else:

    lw $t3, 12($s3) # puzzle->grid[position].cage->positions

    lw $t0, 0($t3) # puzzle->grid[position].cage->positions[0]

    lw $t1, 4($t3) # puzzle->grid[position].cage->positions[1]

    xor $t0, $t0, $t1

    xor $t0, $t0, $s6 # other_pos = $t0 = $t0 ^ position

    lw $a0, 4($s3) # puzzle->grid[position].cage->target



    sll $t2, $s6, 3 # position * 8

    add $a1, $s5, $t2 # &puzzle->grid[position]

    lw  $a1, 0($a1) # puzzle->grid[position].domain

    # move $a1, $s7 



    sll $t1, $t0, 3 # other_pos*8 (actual offset)

    add $t3, $s5, $t1 # &puzzle->grid[other_pos]

    lw $a2, 0($t3)  # puzzle->grid[other_pos].domian



    jal get_domain_for_subtraction # $v0 = valid_domain = get_domain_for_subtraction()

    # j gdfc_end

gdfc_end:

# restore registers

    

    lw $ra, 0($sp)

    lw $s0, 4($sp)

    lw $s1, 8($sp)

    lw $s2, 12($sp)

    lw $s3, 16($sp)

    lw $s4, 20($sp)

    lw $s5, 24($sp)

    lw $s6, 28($sp)

    lw $s7, 32($sp)

    add $sp, $sp, 36    

    jr $ra
