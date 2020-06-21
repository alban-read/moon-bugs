include imports.f 
include utils.f 

create app-name ," !Moon-Bugs " 0 , 0 ,  
app-name 1+ value app-name
app-name 1+ value app-title
 
0 constant forth_handled 
0 value tracking
0 call GetModuleHandle value hmod  
 
: register-class
	call RegisterClassA ;

include graphics.f 
include message.f  
 
: start 
	start-message
	start-graphics
	;


