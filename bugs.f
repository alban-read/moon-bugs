
library WinUser
4 import: MessageBoxA
0 import: GetModuleHandle
12 import: CreateWindowExW
1 import: RegisterClassW
0 import: GetLastError 
4 import: DefWindowProcW
4 import: GetMessageW
5 import: PeekMessageW
1 import: TranslateMessage
1 import: DispatchMessage
2 import: ShowWindow
1 import: Sleep
6 import: CreateThread
1 import: UpdateWindow
1 import: PostQuitMessage
2 import: BeginPaint
2 import: EndPaint
3 import: FillRect

create app-name ," MoonBugs" 0 ,
app-name 1+ value app-name

create app-title ," Moon Bugs" 0 ,
app-title 1+ value app-title

0 call GetModuleHandle value hmod  
 
0 value win-calls

0 value hwnd

( hwnd; message; wParam; lParam; time; pt; lPrivate; )
  
align variable MSG 8 cells allot
align variable ps 16 cells allot
align variable hdc 


: for-us? MSG @ hwnd = ;


4 callback: MyWndProc  ( hwnd uMsg wParam lParam )
	 
	1 +to win-calls
	 
	2 pick ( uMsg ) CASE
	
		WM_NCCREATE OF
			TRUE EXIT  
		ENDOF
		
		WM_CREATE OF
		    ." create " cr
			0 EXIT 
		ENDOF
 
		WM_SIZE OF
		    ." size " cr
			0 EXIT 
		ENDOF
 
		WM_DESTROY OF
			0 PostQuitMessage
			0 EXIT 
		ENDOF
		
		
		WM_PAINT OF
		    ." paint " cr
			ps hwnd CALL BeginPaint
			COLOR_WINDOW 1 + ps 2 cells + hwnd CALL FillRect
			ps hwnd CALL EndPaint
			0 EXIT 
		ENDOF         
		
	ENDCASE

	DefWindowProcW
	 

	0 
;
 

	
align create wind-class
 0 ,  
 ' MyWndProc , 	 
 0 , 			 
 0 , 			 
 hmod , 		 
 0 , 			 
 0 , 			 
 0 , 	 
 0 , 			 
 app-name , 		 
 0 ,
 0 ,
 

: register-class
	 wind-class call RegisterClassW ;


: make-window
 0 hmod 0 0   
 500 500		
 500 500 
 0 app-title app-name WS_EX_OVERLAPPEDWINDOW call CreateWindowExW
;

 
hex
 
variable tid
variable thread-param


: poll-loop   

	init-thread 
	register-class 
	make-window to hwnd
	SW_SHOW hwnd ShowWindow
	hwnd UpdateWindow
	BEGIN
	." start"
	500 Sleep
	 BEGIN
	  0 0 hwnd MSG Call GetMessageW
	  0 >  WHILE 
		MSG call TranslateMessage drop
		MSG call DispatchMessage drop
		10 Sleep
	  REPEAT 
	 AGAIN ;
	
: start 
	tid 0 thread-param ['] poll-loop 0 0 call CreateThread ;

start  



