

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
3 import: SetWindowLongA 
2 import: GetWindowLongA

code hiword   
	shr eax #16      
	and eax $FFFF
next; inline

code lowword      
	and eax $FFFF
next; inline
				
				
4444 constant forth_handled 
0000 constant windows_handles 

4 callback: MyWndProc  {: hwnd uMsg wParam lParam | hdc _ps _rect -- exit :}
	
	." hwnd " hwnd . ."  msg " uMsg . ."  wParam " wParam . ."  lParam " lParam . cr
	
	uMsg WM_NCCREATE = IF
		 windows_handles  EXIT
	THEN
	
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
		windows_handles  EXIT
	THEN	
				
	uMsg WM_KEYDOWN = IF
		wParam VK_CONTROL = IF
	 	." hwnd " hwnd . ." msg " uMsg . ." wParam" wParam . ." lParam" lParam . cr
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
 			
	windows_handles EXIT ;
 
variable tid
variable thread-param

 
: poll-loop   {: | window-handle _MSG -- :}

	8 cells malloc to _MSG
	400 600 10 10 ['] MyWndProc make_window to window-handle

	z" Moon-Bugs " window-handle SetWindowTextA drop
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
		init-sub-thread 
		poll-loop   
	;
	
	
: start 
	tid 0 thread-param ['] poll-loop-thread  0 0 call CreateThread drop 
;

 
