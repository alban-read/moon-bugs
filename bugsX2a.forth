create app-name ," !Moon-Bugs " 0 , 0 ,  
app-name 1+ value app-name
app-name 1+ value app-title
0 value graphics-hwnd 

include imports.f 



include utils.f 
include gdiplus.f

 

0 value tracking
0 call GetModuleHandle value hmod  
 
: register-class
	call RegisterClassA ;



0 constant forth_handled 
 
: redisplay 
	-1 0 graphics-hwnd InvalidateRect drop ; 

include graphics.f 
include message.f  

 
 
: start 
	init-graphics
	init-gun-ship 
	start-message
	start-graphics
	;


