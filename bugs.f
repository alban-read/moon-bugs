
include imports.f 

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
	WS_OVERLAPPED 
	WS_BORDER + WS_SYSMENU + WS_MINIMIZEBOX + WS_VISIBLE +
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
	tid 0 thread-param ['] poll-loop-thread  
	0 0 call CreateThread drop ;

 
