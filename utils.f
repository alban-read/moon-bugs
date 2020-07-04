code hiword   
	shr eax #16      
	and eax $FFFF
next; inline

code lowword      
	and eax $FFFF
next; inline

ms@ lowword value rng

: random ( - n)
	rng
	dup 0= or
	dup 6 lshift xor
	dup 21 rshift xor
	dup 7 lshift xor
	dup to rng  ;

: choose
  random um* nip ;
  
' THEN alias ENDIF

: sqrt 
  0 tuck
  ?do 1+ dup 2* 1+ +loop
;
  