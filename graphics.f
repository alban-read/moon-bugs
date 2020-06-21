

4 callback: MyWndProc  {: hwnd uMsg wParam lParam | hdc _ps _rect  -- exit :}


	uMsg CASE 
		
		WM_CREATE OF
			forth_handled EXIT
		ENDOF 
		
		WM_DESTROY OF
			0 Call PostQuitMessage
			forth_handled EXIT
		ENDOF
		
		WM_PAINT OF
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
		ENDOF  
			
		WM_NCHITTEST OF
			." hit test"
			lParam lowword .
			lParam hiword . cr
		ENDOF	
					
					
					
		WM_KEYDOWN OF
		
			wParam CASE
		
				VK_CONTROL OF
				  tracking not to tracking
				ENDOF
				
				VK_LEFT OF
			 
				ENDOF
				
				VK_RIGHT OF
				 
				ENDOF
				
				VK_SPACE OF
				 
				ENDOF
				
				VK_ESCAPE OF
					hwnd CloseWindow drop
					forth_handled EXIT
				ENDOF
				
			ENDCASE

		ENDOF	

	ENDCASE

	tracking -1 = IF
		." graphics window - " ." hwnd: " hwnd . 
		." msg: " uMsg . 
		." wParam: " wParam . 
		." lParam: " lParam . cr	
	 THEN

	lParam wParam uMsg hwnd cr call DefWindowProcA  
 ;
  
 

 
create wind-class-graphics
 0 , ' MyWndProc ,  0 ,  0 ,  hmod , 		 
 0 ,  0 , COLOR_WINDOW 1 + ,  0 ,  
 app-name , 0 , 0 ,
  
 
: make-graphics-window
	0 hmod 0 0  
	CW_USEDEFAULT CW_USEDEFAULT		
	CW_USEDEFAULT CW_USEDEFAULT 
	WS_OVERLAPPED 
	WS_BORDER + WS_SYSMENU + WS_MINIMIZEBOX + WS_VISIBLE +
	app-title app-name 0 call CreateWindowExA 
	;

variable graphics-tid
variable graphics-thread-param

: graphics-poll-loop   {: | window-handle _MSG -- :}

	wind-class-graphics register-class drop
	8 cells malloc to _MSG
	make-graphics-window to window-handle
	app-name window-handle SetWindowTextA drop
	SW_SHOW window-handle ShowWindow 

	BEGIN
		BEGIN
		0 0 window-handle _MSG Call GetMessageA 
		dup -1 = IF ." graphics poll error!" cr THEN
		0 > WHILE 
			_MSG call DispatchMessage drop
		REPEAT 
	AGAIN ;
	
	
: graphics-window-thread
	init-thread 
	100 Sleep
	graphics-poll-loop 
;

: start-graphics 
	graphics-tid 0 graphics-thread-param ['] graphics-window-thread
	0 0 call CreateThread drop ;




