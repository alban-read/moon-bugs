include gdipluslib.f
 
 
create gdi-text ," Moon-Bugs " 0 , 0 ,  
gdi-text 1+ value gdi-text

\ from rectange get radius
: get-radius ( w h -- r ) 
  dup 2 / swap 8 * rot dup * swap / + ;
  
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
64 value gun-width
64 value gun-height

0 value tile-image 
-1440 value tile-x
-900 value tile-y

0 value offset-x
0 value offset-y

1 constant aliens-moving 
2 constant aliens-paused
3 constant alien-destroyed

aliens-moving value aliens-active
  
: toggle-alien-movement
   aliens-active aliens-paused = 
   IF 
		aliens-moving to aliens-active 
   ELSE 
		aliens-paused to aliens-active
   ENDIF
 ;
  
0 value alienoid-1-image 
64 value alienoid-width
64 value alienoid-height

alienoid-width alienoid-height get-radius 
value alienoid-radius
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
 8 value missile-width
 8 value missile-height
 missile-width missile-height get-radius 
 value missile-radius
 
 variable mx missile-count 1+ cells allot
 variable my missile-count 1+ cells allot
 variable mh missile-count 1+ cells allot
 
 missile-radius alienoid-radius + value hitradius
 

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
 
: adjust-my 
	my@   missile-height 2 / + ;

 : adjust-mx 
	mx@   missile-width 2 / +  ;


: place-missile  
	
	ms@ lastshot - 250 < IF 
	 EXIT
	ENDIF
	
	missile-count 0 DO 
		i my@ 0= IF 
			gun-x gun-width 2 / + 8 - i mx!
			gun-y gun-height 2 / + i my!
			heading i mh!
			ms@ to lastshot
			LEAVE
		ENDIF
	LOOP		
;


: free-missile ( n -- )
	dup 0 my! 0 mx! ;
	

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
	
			$FF $FF $FF 40 solid-brush  
			i mx@ i my@ 8 - 16 16 fill-ellipse 
	
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
variable alienoid-active 256 cells allot
	
	
 : a?! ( x a -- )
	cells alienoid-active + ! ;
	inline
 
 : a?@ ( a -- n )
	cells alienoid-active + @ ; 
	inline	
	
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
 
   8 0 DO
    i 64 * i ax!
    80 i ay!
    aliens-moving i a?!
   LOOP
   
   ;
   
 
	
 : adjust-ax  
	ax@ offset-x + alienoid-width 2 / + ;
	
 : adjust-ay  
	ay@ offset-y + alienoid-height 2 / + ;
	 
 : ellipse-alien ( n -- ) 
	dup adjust-ax swap adjust-ay 64 64 draw-ellipse ;
	
 \ for each missile, check for aliens  
 : missile-alien-collisions
	\ missiles
	missile-count 0 DO 
		\ missiles
		i my@ 0= NOT IF
			\ aliens
			44 0 DO 
				  i a?@ aliens-moving = IF	
					\ check if circles collide
					j adjust-mx
					i adjust-ax - dup *
					j adjust-my
					i adjust-ay - dup *
					+ sqrt 
					hitradius < IF	
					\ we may have hit the alien
						j adjust-my
						i adjust-ay > IF
							j adjust-mx
							i adjust-ax > IF
								i ellipse-alien 
								0 j my!	0 j mx!
								alien-destroyed i a?! 	
							ENDIF	
						ENDIF	
					ENDIF				
			  ENDIF
			LOOP 
		ENDIF
	LOOP
 ; 
  
 
 : init-images
	z" Hero.png" load-image to hero-image 
	gun-width gun-height hero-image resized-clone to gun-ship-forward
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
	dup a?@ aliens-moving = IF 
		dup adjust-ax
		swap adjust-ay
		alienoid-1-image draw-image 
	ENDIF
	;

 : display-aliens 
	8 0 DO 
		i display-alien 
	LOOP 
	;

 : alien-down ( a -- )
	dup a?@ aliens-moving = IF 
		dup ay@ 1 + swap ay! 
	ENDIF	
  ;
	
 : shift-aliens-down
	
	aliens-moving aliens-active = IF 
	
		44 0 DO 
			i alien-down 
		LOOP  
		
	ENDIF
	;

 
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
	
 
25 value time-taken
 1 value ticks

: display-status 
	18 font-size
	150 250 250 $FF colour  
	150 250 250 $FF solid-brush  
	10 4 gdi-text draw-string 
	140 4 time-taken ticks / s>d <# #S 0 HOLD #> drop 1+ draw-string drop
	180 4 z" ms" draw-string 
	;
 
 
\ update the display 
\ called every N ms by the message LOOP; see message.
\ needs to be fast.

: update-the-display

	tile-x tile-y tile-image draw-image

	display-missiles

	display-aliens 
	
	
	gun-x gun-y gun-ship-image draw-image
	
	display-status	
	
	missile-alien-collisions

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


	
 