
library WinUser
4 import: MessageBoxA
0 import: GetModuleHandle
12 import: CreateWindowExA
1 import: RegisterClassA
0 import: GetLastError 
4 import: DefWindowProcA
4 import: GetMessageA
5 import: GetMessageA
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
1 import: SetActiveWindow
1 import: GetStockObject
2 import: GetClientRect


create app-name ," MoonBugs" 0 ,
app-name 1+ value app-name

create app-title ," Moon Bugs" 0 ,
app-title 1+ value app-title

0 call GetModuleHandle value hmod  
8 cells allot
0 value win-calls
0 value hwnd 8 cells allot
0 value hdc 8 cells allot
align variable rect 8 cells allot
align variable brush 8 cells allot
align variable MSG 24 cells allot
align variable ps 24 cells allot
0 value lresult 8 cells allot

: for-us? MSG @ hwnd = ;


4 callback: MyWndProc  ( hwnd uMsg wParam lParam )
	 
	1 +to win-calls
	0 to lresult 
	
	 ." in "  
	.s cr
	
	hwnd 0 > IF
		3 pick hwnd = not IF 
		." not my window " 
		THEN
	THEN
	cr
	
	2 pick ( uMsg )  WM_NCCREATE = IF
		4drop 
		TRUE
		EXIT 
	THEN
	
	2 pick ( uMsg )  WM_CREATE = IF
		4drop  0 
		EXIT 
	THEN

	2 pick ( uMsg ) WM_DESTROY = IF
		0 PostQuitMessage
		4drop 0 EXIT 
	THEN
	
	2 pick ( uMsg ) WM_PAINT = IF
		4drop 
		." paint begin "  
		ps hwnd call BeginPaint to hdc
	
		rect hwnd call GetClientRect drop 
		
		COLOR_WINDOWFRAME  1 +  rect hdc call FillRect drop
		
		
		ps hwnd call EndPaint drop
		0 
		." end "
		.s cr EXIT 
	THEN  
		
	2 pick ( uMsg )  WM_SETCURSOR = IF
		4drop 
		TRUE
		EXIT 
	THEN	
		
		
 
 	." defproc" .s
	call DefWindowProcA
	." -- " .s cr 
	EXIT
 

	
;
 

	
align 
create wind-class
 0 ,  
 ' MyWndProc , 	 
 0 , 			 
 0 , 			 
 hmod , 		 
 0 , 			 
 0 , 			 
 COLOR_WINDOW 1 + , 	 
 0 , 			 
 app-name , 		 
 0 ,
 0 ,
 

: register-class
	 wind-class call RegisterClassA ;


: make-window
 0 hmod 0 0  
 CW_USEDEFAULT CW_USEDEFAULT		
 CW_USEDEFAULT CW_USEDEFAULT 
 WS_OVERLAPPEDWINDOW  app-title app-name 0 call CreateWindowExA
;


 
hex
 
variable tid
variable thread-param

 
: poll-loop   

	init-thread 
	register-class drop
	make-window to hwnd
	SW_SHOWDEFAULT hwnd call ShowWindow drop
	BEGIN
		." poll loop" cr
		10 Sleep
		BEGIN
		0 0 hwnd MSG Call GetMessageA 
		dup -1 = IF ." poll error" cr THEN
		0 >  WHILE 
			MSG call DispatchMessage drop
		REPEAT 
	AGAIN ;
	
: start 
	tid 0 thread-param ['] poll-loop 0 0 call CreateThread drop ;

 



