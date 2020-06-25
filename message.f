


0 value ticks

4 callback: TimerProc  {: hwnd uMsg wParam lParam | hdc _ps _rect  -- exit :}
	
	uMsg CASE 
		
		WM_CREATE OF
			forth_handled EXIT
		ENDOF 
		
		WM_TIMER OF
			ticks 1 + to ticks 
		    swap-surfaces 
			redisplay   
			update-the-display
			
			forth_handled EXIT
		ENDOF 

	ENDCASE
	lParam wParam uMsg hwnd cr call DefWindowProcA  
 ;
 
 
create message-window-name ," !TimerForMoonBugs " 0 , 0 ,  

 
create wind-class-message
 0 , ' TimerProc ,  0 ,  0 ,  hmod , 		 
 0 ,  0 , COLOR_WINDOW 1 + ,  0 ,  
 message-window-name , 0 , 0 ,
 

: make-message-window
	0 hmod 0 HWND_MESSAGE 
	CW_USEDEFAULT CW_USEDEFAULT		
	CW_USEDEFAULT CW_USEDEFAULT 
	0
	app-title message-window-name 0 call CreateWindowExA 
	;

 
variable message-tid
variable message-thread-param
	
	
: message-poll-loop   {: | window-handle _MSG -- :}

	wind-class-message register-class drop
	8 cells malloc to _MSG
	make-message-window to window-handle
	0 30 1000 window-handle SetTimer
	BEGIN
		BEGIN
		0 0 window-handle _MSG Call GetMessageA 
		dup -1 = IF BYE THEN
		0 > WHILE 
			_MSG call DispatchMessage drop
		REPEAT 
	AGAIN ;	
	
	
 
: message-window-thread
	init-thread 
	100 Sleep
	message-poll-loop 
;

: start-message 
	message-tid 0 message-thread-param ['] message-window-thread
	0 0 call CreateThread drop ;

 


