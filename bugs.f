
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
		
 		
code hiword   
	shr eax #16      
	and eax $FFFF
next; inline

code lowword      
	and eax $FFFF
next; inline
				
\ message access
\ ( hwnd uMsg wParam lParam )
\    

code umsg@   
    0 1 in/out
	mov dword { $-4 ebp } eax
	mov eax dword { $4 ebp }
next; inline

code hwnd@   
    0 1 in/out
	mov dword { $-4 ebp } eax
	mov eax dword { $8 ebp }
next; inline

code wparam@ 
    0 1 in/out 
	mov dword { $-4 ebp } eax
	mov eax dword { ebp }
next; inline

code lparam@
     0 1 in/out
     mov dword { $-4 ebp } eax
next; inline	 

code discard       
    4 0 in/out
    mov     eax { 3 cells ebp }
next; inline

	
: .message
	 ." hwnd: "  
	 hwnd@ .
     ." uMsg "
     umsg@ .
	 ." wParam "
	 wparam@  .
	 ." lParam "
	 lparam@ .
	 cr ;
	
: test 
  1 2 3 4 
  .message ;  
	
	
create app-name ," MoonBugs" 0 ,
app-name 1+ value app-name

create app-title ," Moon Bugs" 0 ,
app-title 1+ value app-title

0 call GetModuleHandle value hmod  
8 cells allot
0 value win-calls
0 value hwnd 8 cells allot
0 value hdc 8 cells allot
align variable rect   8 cells allot
align variable brush 8 cells allot
align variable MSG 24 cells allot
align variable ps 24 cells allot
0 value lresult 8 cells allot

: for-us? MSG @ hwnd = ;


4 callback: MyWndProc  ( hwnd uMsg wParam lParam )
	 
	1 +to win-calls
    
	.message
	 
	umsg@ WM_NCCREATE = IF
		discard TRUE EXIT 
	THEN
	
	umsg@  WM_CREATE = IF
		discard  0 
		EXIT 
	THEN

	umsg@ WM_DESTROY = IF
		0 PostQuitMessage
		discard 0 EXIT 
	THEN
	
	umsg@ WM_PAINT = IF
	
		." paint begin "  
		hwnd@  ps swap call BeginPaint to hdc
	
		hwnd@ rect swap call GetClientRect drop 
		
		COLOR_WINDOWFRAME  1 +  rect hdc call FillRect drop
		
		hwnd@ ps swap call EndPaint drop
		
		." end "
		.s cr 
		discard 0 EXIT 
		
	THEN  
		
	umsg@ WM_SETCURSOR = IF
		discard 
		TRUE
		EXIT 
	THEN	
		
	umsg@ WM_NCHITTEST = IF
		." hit x y "
		lparam@ lowword .
		lparam@ hiword .
		.message
		cr
		call DefWindowProcA
		EXIT
	THEN	
	
	umsg@ WM_KEYDOWN = IF
		." keys "
		wparam@ VK_LEFT = IF
			." left"
		THEN
		wparam@ VK_RIGHT = IF
			." right"
		THEN
		wparam@ VK_SPACE = IF
			." fire"
		THEN
		wparam@ VK_ESCAPE = IF
			." end"
			hwnd@ CloseWindow
			discard
			0 EXIT
		THEN
		call DefWindowProcA 
		EXIT 
	THEN			
 	." defproc " .message
	call DefWindowProcA
 
	EXIT ;
 

	
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

 



