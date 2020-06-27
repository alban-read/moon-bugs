include gdipluslib.f
 
 
create gdi-text ," Moon-Bugs " 0 , 0 ,  
gdi-text 1+ value gdi-text


\ We have two surfaces (DOuble buffering) which are bitmaps
\ the surface to display; and the surface to update
\ We draw on the surface to update; while the surface to
\ display is being shown in the winDOw.
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

\ there are three directions for the gun-ship
\ to face.

0 value hero-image 
0 value gun-ship-image 
0 value gun-ship-forward
0 value gun-ship-lean-left
0 value gun-ship-lean-right
  
400 value gun-x
520 value gun-y

0 value tile-image 
-1440 value tile-x
-900 value tile-y

0 value offset-x
0 value offset-y

0 value alienoid-1-image 
0 value rotation 

\ where is the gun ship heading.

0 constant heading-stopped
1 constant heading-left
2 constant heading-right
3 constant heading-up
4 constant heading-down

heading-stopped value heading

\ gun-ship fires missiles

 16 constant missile-count
 0 value lastshot 
 variable mx missile-count 1+ cells allot
 variable my missile-count 1+ cells allot
 variable mh missile-count 1+ cells allot

 : mx@ ( n -- x )
	cells mx + @ ; 
	
 : mx! ( x n -- )
	cells mx + ! ;

 : my@ ( a -- n )
	cells my + @ ; 
	
 : my! ( x a -- )
	cells my + ! ;
 
 : mh@ ( a -- n )
	cells mh + @ ; 
	
 : mh! ( x a -- )
	cells mh + ! ;
 

: place-missile  
	
	ms@ lastshot - 250 < IF 
	 EXIT
	ENDIF
	
	missile-count 0 DO 
		i my@ 0= IF 
			gun-x 24 + i mx!
			gun-y  8 + i my!
			heading i mh!
			ms@ to lastshot
			LEAVE
		ENDIF
	LOOP		
;


: move-missiles 
 
	missile-count 0 DO 
	
		i my@ 0= NOT IF 

			i mh@ CASE
				
				heading-up OF
					i my@ 8 - i my!  
				ENDOF
				
				heading-down OF
					i my@ 9 - i my!  
				ENDOF
			
				heading-stopped OF
					i my@ 9 - i my!  
				ENDOF
			
				heading-left OF
					i my@ 9 - i my!  
					i mx@ 3 - i mx!
				ENDOF
				
				heading-right OF
					i my@ 9 - i my!  
					i mx@ 3 + i mx!
				ENDOF
				
			ENDCASE
			
			i my@ 0 < IF 
				0 i my!
				0 i mx!		
			ENDIF
			
		ENDIF
	LOOP
	;
		
: display-missiles  

	missile-count 0 DO 
	
		i my@ 0= NOT IF 
	
			$FF $FF $00 150 solid-brush
			i mx@ 4 + i my@ 4 - 8 8 fill-ellipse 
			
			253 195 2 $FF solid-brush  
			i mx@ 6 + i my@ 4 - 4 4 fill-ellipse 
			
		ENDIF
	LOOP
	;
	
\ The images have positions on the surface
variable alienoid-xpos 256 cells allot
variable alienoid-ypos 256 cells allot
	
 : ax! ( x a -- )
	cells alienoid-xpos + ! ;
	inline
 
 : ax@ ( a -- n )
	cells alienoid-xpos + @ ; 
	inline

 : ay! ( x a -- )
	cells alienoid-ypos + ! ;
	inline
 
 : ay@ ( a -- n )
	cells alienoid-ypos + @ ; 
	inline

 : set-alien-start
   0  
   5 1 DO
	12 1 DO 
		dup i 64 * swap ax!
		dup j 64 * 800 - swap ay!
		1 +
	LOOP
   LOOP ;
   
 
 : init-images
	z" Hero.png" load-image to hero-image 
	64 64 hero-image resized-clone to gun-ship-forward
	gun-ship-forward 150 rotated-clone to gun-ship-lean-right
	gun-ship-forward -150 rotated-clone to gun-ship-lean-left
	gun-ship-forward to gun-ship-image 

	z" AlienOiDOneSmall.png" load-image to alienoid-1-image 
	z" clays.jpg" load-image to tile-image		
	set-alien-start ;
 
 
	
	
 : lean-left
 
	gun-ship-image CASE
	
		gun-ship-forward OF 
			gun-ship-lean-left to gun-ship-image
		ENDOF
		
		gun-ship-lean-right OF 
			gun-ship-forward to gun-ship-image
		ENDOF
		
	ENDCASE
	
	;	
	
		 
 : lean-right
 
	gun-ship-image CASE
	
		gun-ship-forward OF 
			gun-ship-lean-right to gun-ship-image
		ENDOF
		
		gun-ship-lean-left OF 
			gun-ship-forward to gun-ship-image
		ENDOF
		
	ENDCASE
	
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
	44 0 DO 
		i alien-down 
	LOOP  ;

 
 \ the background is panned 
 \ opposite to the ships movement.
 
 : pan-right
	tile-x 8 < IF 
		tile-x 3 + to tile-x
		offset-x 2 + to offset-x 
	ENDIF	; 
 
 : pan-up 
	tile-y -1100 > IF 
		tile-y 3 - to tile-y
		offset-y 3 - to offset-y 
	ENDIF
	;
 
 : pan-down 
	tile-y 0 < IF 
		tile-y 3 + to tile-y
		offset-y 3 + to offset-y 
	ENDIF	
	;
	
 : pan-left
	tile-x -2040 > IF 
		tile-x 3 - to tile-x
		offset-x 2 - to offset-x 
	ENDIF
	;
		
	
 : move-down
 
	lean-forward 

	gun-y 510 < IF 
		gun-y 1 + to gun-y 
		pan-up 
		EXIT
	ENDIF 
	
	pan-up 
	;

		
 : move-up
 
	lean-forward 

	gun-y 8 > IF 
		gun-y 1 - to gun-y 
		pan-down
		EXIT
	ENDIF 
	
	pan-down 
	
	;
	
	
 : move-left 
 
	lean-left
	gun-x 8 > IF 
		gun-x 1 - to gun-x 
		pan-right	
		EXIT
	ENDIF 
	pan-right

	;
	

 : move-right 	
 
	lean-right
	gun-x 720 < IF 
		gun-x 1 + to gun-x 
		pan-left
		EXIT
	ENDIF 
	
	pan-left
	
	;
	

\ Move gun based on heading.
	
 : move-gun  
 
	heading CASE
	
		heading-down OF 
			move-down
		ENDOF
		
		heading-up OF 
			move-up
		ENDOF
	
		heading-left OF 
			move-left
		ENDOF
		
		heading-right OF 
			move-right
		ENDOF
	
	ENDCASE ;
	
 
: display-status 
	20 font-size
	150 250 250 $FF colour  
	150 250 250 $FF solid-brush  
	10 10 gdi-text draw-string 
	
	;
 
 
\ update the display 
\ called every N ms by the message LOOP; see message.
\ needs to be fast.

: update-the-display

	tile-x tile-y tile-image draw-image

	display-missiles

	44 0 DO 
		i display-alien 
	LOOP 
	
	gun-x gun-y gun-ship-image draw-image
	
	display-status	

	

	shift-aliens-down

	0 ay@ 620 > IF 
		set-alien-start
	ENDIF
	
	move-missiles 
	
	move-gun  

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


	
 