
library winshim.dll

 0 import: _gdiplus_init@0
 0 import: _get_surface@0
 0 import: _QUALITYHIGH@0
 0 import: _QUALITYFAST@0
 0 import: _QUALITYANTIALIAS@0
 0 import: _MATRIXRESET@0
 0 import: _MATRIXINVERT@0
 2 import: _CLG@8
 2 import: _CLS@8
 2 import: _NEWSURFACE@8
 1 import: _FREESURFACE@4
 1 import: _ACTIVATESURFACE@4
 2 import: _FLIP@8
 1 import: _MATRIXROTATE@4
 2 import: _MATRIXTRANSLATE@8
 2 import: _MAKESURFACE@8
 1 import: _SAVEASPNG@4
 1 import: _SAVEASJPEG@4
 1 import: _PENWIDTH@4
 1 import: _SETFONTSIZE@4
 1 import: _LOADIMAGE@4
 1 import: _GRMODE@4
 3 import: _DRAWSTRING@12
 3 import: _DRAWGRADIENTSTRING@12
 3 import: _DISPLAYACTIVE@12
 3 import: _IMAGETOSURFACE@12
 3 import: _LOADTOSURFACE@12
 4 import: _DISPLAYSURFACE@16
 4 import: _COLR@16
 3 import: _MATRIXROTATEAT@12
 5 import: _SCALEDROTATEDIMAGETOSURFACE@20
 4 import: _SCALEDIMAGETOSURFACE@16
 4 import: _MATRIXSHEAR@16
 2 import: _MATRIXSCALE@8
 4 import: _COLR@16
 4 import: _PAPER@16
 4 import: _SOLIDBRUSH@16
 2 import: _SETPIXEL@8
 4 import: _FILLSOLIDRECT@16
 4 import: _FILLHATCHRECT@16
 4 import: _FILLGRADIENTRECT@16
 4 import: _FILLSOLIDELLIPSE@16
 4 import: _FILLGRADIENTELLIPSE@16
 4 import: _FILLHATCHELLIPSE@16
 6 import: _FILLSOLIDPIE@24
 6 import: _FILLGRADIENTPIE@24
 6 import: _FILLHATCHPIE@24
 6 import: _DRAWPIE@24
 6 import: _DRAWARC@24
10 import: _GRADIENTBRUSH@40
 9 import: _SETHATCHBRUSH@36
 4 import: _DRAWRECT@16
 4 import: _DRAWLINE@16
 4 import: _DRAWGRADIENTLINE@16
 4 import: _DRAWELLIPSE@16
 1 import: _SAVETOCLIPBOARD@4 
  
: init-gdi-plus  	
	call _gdiplus_init@0 ;

: get-gdi-surface 
	call _get_surface@0 ;

: reset-matrix
	call _MATRIXRESET@0 drop ;

: scale-matrix ( h v --- )
	 call _MATRIXSCALE@8 drop ;

: rotate-matrix ( a --- )	 
	 _MATRIXROTATE@4 drop ;
 
: rotate-matrix-at ( x y a --- )	 
	 _MATRIXROTATEAT@12 drop ; 
 
: display ( x y hdc ) 
		call _DISPLAYACTIVE@12 drop ;

\ display surface in window
: display-surface ( x y hdc surface ) 
		call _DISPLAYSURFACE@16 drop ;
		
\ activate surface for drawing commands
: activate-surface ( surface ) 
		call _ACTIVATESURFACE@4 drop ;

: new-surface ( x y -- surface ) 
		call _NEWSURFACE@8  ;
			
: load-image ( filename -- image ) 
		call  _LOADIMAGE@4  ;

: draw-image ( x y image -- ) 
		call _IMAGETOSURFACE@12 drop ; 

: draw-scaled-rotated-image (  x y image s a  -- ) 
		call _SCALEDROTATEDIMAGETOSURFACE@20 drop ; 
	
: draw-scaled-image (  x y image s  -- ) 
		call _SCALEDIMAGETOSURFACE@16 drop ; 	
		

: high-quality  		
	call _QUALITYHIGH@0 ;

: clg ( w h --)			
	call _CLG@8 drop ;

: clr ( w h --)			
	call _CLS@8 drop ;

: pen-width ( w -- )		
	call _PENWIDTH@4 drop ;

: font-size ( z -- )		
	call _SETFONTSIZE@4 drop ;

: colour ( r g b a -- )				
	call _COLR@16 drop ;

: solid-brush 	( r g b a -- )			
	call _SOLIDBRUSH@16 drop ;

: gradient-brush ( z angle r g b a r1 g1 b1 a1  -- )			
	call _GRADIENTBRUSH@40 drop ;

: hatch-brush 	( style r g b a r1 g1 b1 a1 ) 		
	call _SETHATCHBRUSH@36 drop ;

: fill-rect ( x y w h -- )				
	call _FILLSOLIDRECT@16 drop ;

: hatch-rect ( x y w h -- )			
	call _FILLHATCHRECT@16 drop ;

: draw-rect ( x y w h -- )				
	call _DRAWRECT@16 drop ;

: draw-ellipse ( x y w h -- )			
	call _DRAWELLIPSE@16 drop ;

: draw-arc ( x y w h i j -- )				
	call _DRAWARC@24 drop ;

: draw-pie ( x y w h i j -- )			
	call _DRAWPIE@24 drop ;

: draw-line  ( x y w h -- )				
	call _DRAWLINE@16 drop ;

: draw-string 	( x y ztext -- )			
	call _DRAWSTRING@12 drop ;

: save-as-png 	( zfilename -- )
	call _SAVEASPNG@4 drop ; 

: save-to-clipboard 	( zfilename -- )	
	call _SAVETOCLIPBOARD@4 drop ;

 
\ --------------------------------------------------
 
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

0 value gun-ship-image 
200 value gun-x
200 value gun-y

0 value tile-image 
-1400 value tile-x
-800 value tile-y

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
		z" HeroSmall.png" load-image to gun-ship-image	
		z" AlienOidOneSmall.png" load-image to alienoid-1-image 
		z" clays.jpg" load-image to tile-image		
		set-alien-start ;
 

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
   
 
   tile-x tile-y tile-image rotation 20 draw-scaled-rotated-image
 
   44 0 do 
	i display-alien 
   loop 
   gun-x gun-y gun-ship-image 24 draw-scaled-image 
  
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


	
 