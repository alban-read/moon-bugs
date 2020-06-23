
library winshim.dll

 0 import: _gdiplus_init@0
 0 import: _QUALITYHIGH@0
 0 import: _QUALITYFAST@0
 0 import: _QUALITYANTIALIAS@0
 0 import: _MATRIXRESET@0
 0 import: _MATRIXINVERT@0
 2 import: _CLG@8
 2 import: _FLIP@8
 2 import: _MATRIXROTATE@8
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
 3 import: _DISPLAY@12
 3 import: _IMAGETOSURFACE@12
 3 import: _LOADTOSURFACE@12
 4 import: _COLR@16
 4 import: _MATRIXROTATEAT@16
 4 import: _MATRIXSHEAR@16
 4 import: _MATRIXSCALE@16
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
  
 : init-gdi-plus ()			
	call _gdiplus_init@0 ;
	
 : high-quality ()			
	call _QUALITYHIGH@0 ;
	
 : clg ( w h --)			
	call _CLG@8 drop ;
	
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
 
 
 : test 
	
	init-gdi-plus
	high-quality
	
	500 400 clg  


	250 10  100 $FF solid-brush   
	100 100 30 30 fill-rect
	20 pen-width  
	150 250 250 $FF colour  
	200 200 30 30 draw-rect drop
	
	24 font-size
	50 50 z" this is my text " draw-string
	
	z" test.png" save-as-png drop
 ;
