
library WinUser
4 import: MessageBoxA
0 import: GetModuleHandle
12 import: CreateWindowExA
1 import: RegisterClassA
0 import: GetLastError 
4 import: DefWindowProcA
4 import: GetMessageA
1 import: TranslateMessage
1 import: DispatchMessage
2 import: ShowWindow

create app-name ," MoonBugs" 0 ,
app-name 1+ value app-name

create app-title ," Moon Bugs" 0 ,
app-title 1+ value app-title

0 call GetModuleHandle value hmod  
 
: wm_created 
  ." WM created" ;

0 value win-calls


: test 
	1 +to win-calls ;

4 callback: MyWndProc  ( hwnd uMsg wParam lParam )
	 
	2 pick 
	CASE
	
	    WM_NCCREATE OF
			TRUE EXIT  
		ENDOF
		
		WM_CREATE OF
			0 EXIT 
		ENDOF
		
		WM_SHOWWINDOW OF
			0 EXIT 
		ENDOF
		
		WM_MOUSEACTIVATE OF
			MA_ACTIVATE EXIT 
		ENDOF
		
		WM_WINDOWPOSCHANGING OF
			0 EXIT 
		ENDOF
		
		WM_PAINT OF
			0 EXIT 
		ENDOF         
		
		WM_GETMINMAXINFO OF
			0 EXIT 
		ENDOF
		
	.s cr
	DefWindowProcA
	
	ENDCASE
	
	0 
;

0 value hwnd
0 variable MSG
 
: poll 
  BEGIN
  0 0 hwnd MSG Call GetMessageA 
  0 > WHILE 
   MSG call TranslateMessage drop
   MSG call DispatchMessage drop
  REPEAT ;
	
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
make-window to hwnd
SW_SHOW hwnd ShowWindow
 
 

