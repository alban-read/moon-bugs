

library WinUser
 
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
2 import: SelectObject 
9 import: BitBlt 
1 import: DeleteObject 
1 import: DeleteDC 
3 import: CreateMutex 
1 import: CreatePalette 
1 import: IsGUIThread
0 import: DestroyCaret
1 import: ShowCaret
1 import: SetWindowTextA
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
				
 		
0 constant forth_handled 
0 value tracking
 

4 callback: MyWndProc  {: hwnd uMsg wParam lParam | hdc _ps _rect  -- exit :}
	
	uMsg WM_CREATE = IF
		forth_handled EXIT
	THEN
	
	uMsg WM_DESTROY = IF
		0 Call PostQuitMessage
		forth_handled EXIT
	THEN
	
	uMsg WM_PAINT = IF
		." paint" cr
		8 cells malloc to _ps 
		8 cells malloc to _rect 
		_ps hwnd call BeginPaint to hdc
		_rect hwnd call GetClientRect drop 
		-10 -10 _rect call InflateRect drop
		COLOR_MENUTEXT 1 +  _rect hdc call FillRect drop
		_ps hwnd call EndPaint drop
		_ps free
		_rect free
		 forth_handled EXIT
	THEN  
		
	uMsg WM_NCHITTEST = IF
		." x y " 
		lParam lowword .
		lParam hiword .
		cr
	THEN	
				
	uMsg WM_KEYDOWN = IF
	
		wParam VK_CONTROL = IF
	 	  tracking not to tracking
		THEN
		
		wParam VK_LEFT = IF
			." left"
		THEN
		wParam VK_RIGHT = IF
			." right"
		THEN
		wParam VK_SPACE = IF
			." fire"
		THEN
		wParam VK_ESCAPE = IF
			hwnd CloseWindow drop
			forth_handled EXIT
		THEN
	THEN	
    
	tracking -1 = IF
		." message - " ." hwnd: " hwnd . 
		." msg: " uMsg . 
		." wParam: " wParam . 
		." lParam: " lParam . cr	
	 THEN
	
	lParam wParam uMsg hwnd cr call DefWindowProcA  
 ;
 

create app-name ," !Moon-Bugs " 0 , 0 ,  
app-name 1+ value app-name
app-name 1+ value app-title

0 call GetModuleHandle value hmod  

align 
create wind-class
 0 , ' MyWndProc ,  0 ,  0 ,  hmod , 		 
 0 ,  0 , COLOR_WINDOW 1 + ,  0 ,  
 app-name , 0 , 0 ,
 
: register-class
	 wind-class call RegisterClassA ;

: make-window
 0 hmod 0 0  
 CW_USEDEFAULT CW_USEDEFAULT		
 CW_USEDEFAULT CW_USEDEFAULT 
 WS_OVERLAPPED WS_BORDER + WS_SYSMENU + WS_MINIMIZEBOX + WS_VISIBLE +
 app-title app-name 0 call CreateWindowExA 
;

variable tid
variable thread-param
	
: poll-loop   {: | window-handle _MSG -- :}

	." message loop " cr
	register-class drop
	8 cells malloc to _MSG
	make-window to window-handle
	." handle: "  window-handle . cr
	app-name window-handle SetWindowTextA drop
	SW_SHOW window-handle ShowWindow 
	
	BEGIN
		BEGIN
		0 0 window-handle _MSG Call GetMessageA 
		dup -1 = IF ." poll error!" cr THEN
		0 > WHILE 
			_MSG call DispatchMessage drop
		REPEAT 
	AGAIN ;
	
	
	: poll-loop-thread   
		init-thread 
		100 Sleep
		poll-loop   
	;
	
: start 
	tid 0 thread-param ['] poll-loop-thread  0 0 call CreateThread drop ;

 
