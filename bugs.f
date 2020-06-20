

library WINSHIM.dll
5 import: make_window

4 import: MessageBoxA
0 import: GetModuleHandle
12 import: CreateWindowExA
1 import: RegisterClassA
0 import: GetLastError 
4 import: DefWindowProcA
4 import: GetMessageA
5 import: PeekMessageA
1 import: TranslateMessage
1 import: DispatchMessage
2 import: ShowWindow
1 import: Sleep
6 import: CreateThread
1 import: UpdateWindow
1 import: PostQuitMessage
2 import: BeginPaint
2 import: EndPaint
2 import: LoadCursor
3 import: FillRect
3 import: InflateRect
1 import: SetActiveWindow
1 import: GetStockObject
1 import: DestroyWindow
1 import: CloseWindow
1 import: GetAsyncKeyState
1 import: CreateCompatibleDC 
1 import: CreateCompatibleBitmap 
2 import: SetWindowTextA   
2 import: SelectObject 
9 import: BitBlt 
1 import: DeleteObject 
1 import: DeleteDC 
3 import: CreateMutex 
1 import: CreatePalette 
1 import: IsGUIThread
0 import: DestroyCaret
1 import: ShowCaret
4 import: CreateCaret 
4 import: CreateDC 
2 import: GetDeviceCaps   
2 import: GetClientRect
2 import: SetCaretPos

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

 : .message hex
   ." hwnd: "  hwnd@ .
   ." uMsg " umsg@ .
   ." wParam "wparam@  .
   ." lParam "lparam@ .
    cr decimal	 ;
	
: return_handled  \ FORTH handled it
  discard 4444 
  postpone unnest  ; inline
  
: windows_default \ windows can handle
  discard 0
  postpone unnest  ; inline	
	

0 value win-calls
0 value hwnd 8 cells allot
0 value hdc 8 cells allot

align variable rect   	8 cells allot
align variable brush 	8 cells allot
align variable AMSG 	24 cells allot
align variable ps 	24 cells allot


4 callback: MyWndProc  ( hwnd uMsg wParam lParam )
	 
	1 +to win-calls
    
	.message
	
	umsg@ WM_PAINT = IF
		." paint" cr
		hwnd@ ps swap call BeginPaint to hdc
		hwnd@ rect swap call GetClientRect drop 
		-10 -10 rect call InflateRect drop
		COLOR_MENUTEXT 1 +  rect hdc call FillRect drop
		hwnd@ ps swap call EndPaint drop
		return_handled
	THEN  
		
	umsg@ WM_NCHITTEST = IF
		." x y " 
		lparam@ lowword .
		lparam@ hiword .
		cr
		windows_default
	THEN	
				
	umsg@ WM_KEYDOWN = IF
		wparam@ VK_LEFT = IF
			." left"
		THEN
		wparam@ VK_RIGHT = IF
			." right"
		THEN
		wparam@ VK_SPACE = IF
			.message
			." fire"
		THEN
		wparam@ VK_ESCAPE = IF
			hwnd@ CloseWindow drop
			return_handled
		THEN
	THEN	
 			
	0 ;
 
variable tid
variable thread-param

 
: poll-loop   
 
	400 600 10 10 ['] MyWndProc make_window to hwnd
	z" Moon-Bugs " hwnd SetWindowTextA drop
	SW_SHOW hwnd ShowWindow 
	
	BEGIN
		BEGIN
		0 0 0 AMSG Call GetMessageA 
		dup -1 = IF ." poll error" cr THEN
		0 >  WHILE 
			AMSG call DispatchMessage drop
		REPEAT 
	AGAIN ;
	
	: poll-loop-thread   
		init-sub-thread 
		poll-loop   
	;
	
: start 
	tid 0 thread-param ['] poll-loop-thread  0 0 call CreateThread drop 
;

 
