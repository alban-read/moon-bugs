
library WinUser
4 import: MessageBoxA
0 import: GetModuleHandle
12 import: CreateWindowExA
1 import: RegisterClassA
0 import: GetLastError 
4 import: DefWindowProcA

create app-name ," MoonBugs" 0 ,
app-name 1+ value app-name

create app-title ," Moon Bugs" 0 ,
app-title 1+ value app-title

0 call GetModuleHandle value hmod  
 
: wm_created 
  ." WM created" ;

0 value win-calls


: test 
	1 +to win-calls ." !" 0 ;

4 callback: MyWndProc  
	test 
	0
;

 
	
align create wind-class
 CS_HREDRAW + CS_VREDRAW ,  
 ' MyWndProc , 	 
 0 , 			 
 0 , 			 
 hmod , 		 
 0 , 			 
 0 , 			 
 COLOR_BACKGROUND , 	 
 0 , 			 
 app-name , 		 
 0 ,
 0 ,
 

: register-class
	 wind-class call RegisterClassA ;




: make-window
 0 hmod 0 0  
 0 CW_USEDEFAULT		
 0 CW_USEDEFAULT 
 0 app-title app-name 0 call CreateWindowExA
;

 
register-class value class-atom
make-window value hwnd


 0 z" test message" z" This is a test message" MB_OK MessageBoxA


