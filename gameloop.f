include gdipluslib.f
 
 
create gdi-text ," Moon-Bugs " 0 , 0 ,  
gdi-text 1+ value gdi-text


\ We have two surfaces (double buffering) which are bitmaps
\ the surface to display; and the surface to update
\ We draw on the surface to update; while the surface to
\ display is being shown in the window.
\ The surfaces are rotated; bringing the updated surface
\ into the surface to display
\ At any point we are showing one surface while updating
\ the other.



0 value surface-to-display
0 value surface-to-update

: swap-surfaces 
	INFINITE app-mutex call WaitForSingleObject drop
	
	surface-to-display
	surface-to-update
	to surface-to-display
	to surface-to-update  
	surface-to-update activate-surface
	
	app-mutex call ReleaseMutex drop
	;


\ Images are loaded from files
\ They are drawn onto the surface to update.
\

0 value hero-image 
0 value gun-ship-image 
0 value gun-ship-forward
0 value gun-ship-lean-left
0 value gun-ship-lean-right
  
200 value gun-x
200 value gun-y

0 value tile-image 
-1000 value tile-x
-400 value tile-y

0 value offset-x
0 value offset-y

0 value alienoid-1-image 
0 value rotation 


\ The images have positions on the surface
variable alienoid-xpos 256 cells allot
variable alienoid-ypos 256 cells allot
	
 : ax! ( x a -- )
	cells alienoid-xpos + ! ;
 
 : ax@ ( x a -- )
	cells alienoid-xpos + @ ; 

 : ay! ( x a -- )
	cells alienoid-ypos + ! ;
 
 : ay@ ( x a -- )
	cells alienoid-ypos + @ ; 

 : set-alien-start
   0  
   5 1 do
	12 1 do 
		dup i 64 * swap ax!
		dup j 64 * 800 - swap ay!
		1 +
	loop
   loop ;
   
 
 : init-images
	z" Hero.png" load-image to hero-image 
	64 64 hero-image resized-clone to gun-ship-forward
	gun-ship-forward 150 rotated-clone to gun-ship-lean-right
	gun-ship-forward -150 rotated-clone to gun-ship-lean-left
	gun-ship-forward to gun-ship-image 

	z" AlienOidOneSmall.png" load-image to alienoid-1-image 
	z" clays.jpg" load-image to tile-image		
	set-alien-start ;
 
 : lean-left 
	gun-ship-lean-left gun-ship-image = IF 
	 EXIT
	THEN
	gun-ship-image gun-ship-forward = IF
		gun-ship-lean-left to gun-ship-image
	ELSE
	   gun-ship-forward to gun-ship-image
	THEN
	;
		 
 : lean-right
	gun-ship-lean-right gun-ship-image = IF 
	 EXIT
	THEN
	gun-ship-image gun-ship-forward = IF
		gun-ship-lean-right to gun-ship-image
	ELSE
	   gun-ship-forward to gun-ship-image
	THEN
	;
	
 : lean-forward 
	gun-ship-forward to gun-ship-image ;
	 
: display-alien ( a -- )
	dup ax@ offset-x + 
	swap ay@ offset-y +
	alienoid-1-image draw-image ;

: alien-down ( a -- )
	dup ay@ 1 + swap ay! ;
	
: shift-aliens-down
	44 0 do 
		i alien-down 
	loop  ;

 
 
\ We update the display 
\ Runs in the message thread; called by a timer.
 
: update-the-display

	20 font-size
	150 250 250 $FF colour  
	150 250 250 $FF solid-brush  

	tile-x tile-y tile-image draw-image

	44 0 do 
		i display-alien 
	loop 
	
	gun-x gun-y gun-ship-image draw-image
	reset-matrix
	20 20 gdi-text draw-string 
	app-mutex call ReleaseMutex drop

	shift-aliens-down

	0 ay@ 800 > IF 
		set-alien-start
	THEN

   ;
 
 
 \ initialize the GDI+ library
 \ and create the first frame to display.

 : init-graphics
	init-gdi-plus
	high-quality
	reset-matrix
	800 600 new-surface to surface-to-display
	800 600 new-surface to surface-to-update
	surface-to-update activate-surface 
	update-the-display
	
	;


	
 