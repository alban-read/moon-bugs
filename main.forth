create app-name ," !Moon-Bugs " 0 , 0 ,  
app-name 1+ value app-name
app-name 1+ value app-title
0 value graphics-hwnd 
0 value app-mutex


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
	0 0 app-name CreateMutexA to app-mutex
	init-graphics
	init-images 
	start-message
	start-graphics
	;


