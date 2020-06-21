code hiword   
	shr eax #16      
	and eax $FFFF
next; inline

code lowword      
	and eax $FFFF
next; inline