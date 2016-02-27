#
# These routines will bring up an image display window with a rectangle drawn
# in it.  The user should be able to move and resize the rectangle.
# To move the rectangle, mouse button down near the center and drag.
# To resize the rectangle, mouse button down near the edge and drag.
# To start a new rectangle at a new center, mouse button down outside
#   the rectangle on the new center you want.
#
# To initialize the display with a particular rectangle, use
#
# rectInit image rect title
#
# For example, we create a 100x100 image and a 3-element rect using
#
# a.tilt 100 100 0 1 2 = Image
# a.copy "( 50 50 25 25)" = Rect
# rectInit $Image $Rect Title
#
# The `rect' argument is a v4 array containing rectangle coordinates,
# with the col,row of bottom left corner, width and height of the rectangle.
# ( < col row width height > )
#
# To get the final rect as modified by the user, use
#
# rectGet final
#
# The `final' parameter will refer to a v4 array when
# it returns.  If you don't believe me, do
#
# rectGet final
# a.info $final
# a.dump $final
#
# To get rid of the displays, use
#
# rectTerm
#

###############################################################################
#
# This is the main entry point.  It sets up the image display and
# initializes the callback proc for the image display window.  After that,
# it is up to the callback proc.
#
###############################################################################
proc rectInit { image rect title} \
{
    global RECT
#
# Generate the image display window, if necessary.
#
    if { [info exists RECT(ID)] == 0 } \
    {
	id.new RECT(ID)
    }
    
    id.set.title $RECT(ID) $title
    id.set.xy $RECT(ID) 625 150
    id.set.wh $RECT(ID) 500 500

#
# Display the array.
#
    id.set.array $RECT(ID) $image
#
# Create the initial position and rect
#
    set RECT(COL) 0.0
    set RECT(ROW) 0.0

    a.v4tov2v2 $rect = pos size
    a.v2toxy $pos = x y
    a.v2toxy $size = w h
    set RECT(X) [a.extele $x 0]
    set RECT(Y) [a.extele $y 0]
    set RECT(W) [a.extele $w 0]
    set RECT(H) [a.extele $h 0]

    rectDraw
#
# Set the state to NONE.  Othe possibilites are DRAG and RESIZE.
#
    set RECT(STATE) NONE
#
# Make the info panel, if necessary.
#
    if { [info commands .rect] == "" } \
    {
    	rectMakePanel
    }
#
# Set up the callback for mouse events in the image display window.
#
    id.set.callback $RECT(ID) rectCallback
}

###############################################################################
#
###############################################################################
proc rectGet { out } \
{
    global RECT
    
    upvar $out rect
    
    a.copy "(< $RECT(X) $RECT(Y) $RECT(W) $RECT(H)>)" = rect
}

###############################################################################
#
###############################################################################
proc rectTerm { } \
{
    global RECT

    if { [info exists RECT(ID)] } \
    {
	unset RECT(ID)
    }
    
    if { [winfo exists .rect] } \
    {
    	destroy .rect
    }
}

###############################################################################
#
###############################################################################
proc rect_to_rect { col row width height} \
{    
    set rect_coords "( < $col $row $width $height > )"
    return $rect_coords
}

###############################################################################
#
###############################################################################
proc rectDraw { } \
{
    global RECT 
    global platform rect_coords

    if { $platform == "windows" } { 
	id.clr.over.array $RECT(ID)
	id.set.over.coords $RECT(ID) 1
	a.merge $RECT(X) $RECT(Y) $RECT(W) $RECT(H) = rect_coords
	id.set.color.rect.array RECT(ID) rect_coords 1.0 1.0 0.0
    } else { 
	id.clr.over.array $RECT(ID)
	a.merge $RECT(X) $RECT(Y) $RECT(W) $RECT(H) = rect_coords
	moverects rect_coords over
	id.set.over.color $RECT(ID) 1.0 1.0 0.0
	id.set.over.array $RECT(ID) over
    }
    return
}

###############################################################################
#
# This makes a little panel that shows the current position and the current
# rect paramters, just for convienience (debugging).
#
###############################################################################
proc rectMakePanel { } \
{
    global  RECT
    
    toplevel .rect
	wm geometry .rect +329+89
    
    label .rect.col -text [format "current col %6.2f" $RECT(COL)]
    label .rect.row -text [format "current row %6.2f" $RECT(ROW)]
    label .rect.x   -text [format "anchor col  %6.2f" $RECT(X)]
    label .rect.y   -text [format "anchor row  %6.2f" $RECT(Y)]
    label .rect.w   -text [format "width      %6.2f" $RECT(W)]
    label .rect.h   -text [format "height      %6.2f" $RECT(H)]
    
    pack .rect.col .rect.row .rect.x .rect.y \
	.rect.w .rect.h -side top
}

###############################################################################
#
###############################################################################
proc rectUpdatePanel { } \
{
    global RECT

    .rect.col configure -text [format "current col %6.2f" $RECT(COL)]
    .rect.row configure -text [format "current row %6.2f" $RECT(ROW)]
    .rect.x   configure -text [format "anchor col  %6.2f" $RECT(X)]
    .rect.y   configure -text [format "anchor row  %6.2f" $RECT(Y)]
    .rect.w   configure -text [format "width       %6.2f" $RECT(W)]
    .rect.h   configure -text [format "height      %6.2f" $RECT(H)]
}

###############################################################################
#
# Gets called back on mouse events in the image display window.  This just
# dispatches to the appropriate handler.
#
###############################################################################
proc rectCallback { id type col row time state } \
{
    switch $type \
    {
	1 { rectDoMouseMoved $id $col $row $state }
	2 { rectDoMouseDown  $id $col $row $state }
	3 { rectDoMouseUp    $id $col $row $state }
    }
}

###############################################################################
#
###############################################################################
proc rectDoMouseDown { id col row state } \
{
    global RECT
#
# If the user clicks well inside the rect, we want to drag its center.
# If the user clicks near the boundary of the rect, we want to resize it.
# If the user clicks outside the rect, we want to start a new rect.
#
    if { [rectIsInside $col $row] } \
    {
	rectDownInside $col $row
    } \
    else \
    {
	if { [rectIsOnEdge $col $row] } \
	{
	    rectDownOnEdge $col $row
	} \
	else \
	{
	    rectDownOutside $col $row
	}
    }
}

###############################################################################
#
# Returns 1 if the position x,y is well inside the current rect.
#
###############################################################################
proc rectIsInside { x y } \
{
    global RECT
    

#    puts "xdis is [expr $x - $RECT(X)]"
#    puts "ydis is [expr $y - $RECT(Y)]"
#    puts "width is [expr $RECT(W)]"
#    puts "heigth is [expr $RECT(H)]"

    if { ([expr ($x - $RECT(X))] < [expr $RECT(W)])  && \
	  ([expr ($x - $RECT(X))] > 0.0 ) && \
	  ([expr ($y - $RECT(Y))] > 0.0 ) && \
	  ([expr ($y - $RECT(Y))] < [expr $RECT(H)]) } \
    {
#	puts "is inside"
	return 1
    } \
    else \
    {
#	puts "not inside"
	return 0
    }
}

###############################################################################
#
# Returns 1 if the position x,y is near the edge of the current rect.
#
###############################################################################
proc rectIsOnEdge { x y } \
{
    global RECT
    
    set xdis [expr ($x - $RECT(X))]
    set ydis [expr ($y - $RECT(Y))]
    set xval [expr $RECT(W) + 3.0]
    set yval [expr $RECT(H) + 3.0]

    if { (($xdis <= $xval) && ($xdis >= -3.0)) && \
	 (($ydis <= $yval) && ($ydis >= -3.0))} \
    {
	return 1
    } \
    else \
    {
	return 0
    }
}

###############################################################################
#
# This is called if the user clicks inside the rect.
# It just records where the user clicked relative to the center of the rect.
# The mouseMoved routine does all of the real work.
#
###############################################################################
proc rectDownInside { x y } \
{
    global RECT
    
    set RECT(STATE) DRAG
    set RECT(DX) [expr $x-$RECT(X)]
    set RECT(DY) [expr $y-$RECT(Y)]
}

###############################################################################
#
# This is called if the user clicks on the edge of the rect.
# It just records where the user clicked relative to the center of the rect.
# The mouseMoved routine does all of the real work.
#
###############################################################################
proc rectDownOnEdge { x y } \
{
    global RECT
    
    set RECT(STATE) RESIZE
    set xdis [expr ($x - $RECT(X))]
    set ydis [expr ($y - $RECT(Y))]
    set RECT(DX) [expr $x-$RECT(W)]
    set RECT(DY) [expr $y-$RECT(H)]
}

###############################################################################
#
# This is called if the user clicks outside the current rect.  We just
# create a new rect centered at the point the user clicked and pretend
# we were resizing it.
#
###############################################################################
proc rectDownOutside { x y } \
{
    global RECT
    
    set RECT(X) $x
    set RECT(Y) $y
    set RECT(W) 10.0
    set RECT(H) 10.0
    
    rectUpdatePanel
    rectDraw
    update
    
    rectDownOnEdge $x $y
}

###############################################################################
#
# We do the correct thing, depending on whether or not we are resizing or
# dragging the rect.  If we are doing neither, we just display the current
# position in the convienience panel.
#
###############################################################################
proc rectDoMouseMoved { id col row state } \
{
    global RECT
#
# Save the current position.
#
    set RECT(COL) $col
    set RECT(ROW) $row
#
# Always display the current column and row.
#
    rectUpdatePanel
#
# Depending on the STATE, we either DRAG or RESIZE.
#
    if { $RECT(STATE) == "DRAG" } \
    {
	rectDoDrag $col $row
    } \
    else \
    {
	if { $RECT(STATE) == "RESIZE" } \
	{
	    rectDoResize $col $row
	}
    }
}

###############################################################################
#
# We make sure we are neither dragging or resizing after the mouse button
# is released.
#
###############################################################################
proc rectDoMouseUp { id col row state } \
{
    global RECT
    
    id.sync $id
    update
    set RECT(STATE) NONE
}

###############################################################################
#
# Here we adjust the center of the rect based on the current mouse position.
#
###############################################################################
proc rectDoDrag { x y } \
{
    global RECT
    
    set RECT(X) [expr $x-$RECT(DX)]
    set RECT(Y) [expr $y-$RECT(DY)]
    rectUpdatePanel
    rectDraw
    update
}

###############################################################################
#
# Here we adjust the width of the rect based on the current mouse position.
#
###############################################################################
proc rectDoResize { x y } \
{
    global RECT
    
    set xdis [expr ($x - $RECT(X))]
    set ydis [expr ($y - $RECT(Y))]
    set RECT(W) [expr $x - $RECT(DX)]
    set RECT(H) [expr $y - $RECT(DY)]
    
    if { $RECT(W) < 6.0 } { set RECT(W) 6.0 }
    if { $RECT(H) < 6.0 } { set RECT(H) 6.0 }
   
    rectUpdatePanel
    rectDraw
    update
}

##############################################################################
#
# moverects re-orients the rectangle values so they can be properly
# displayed using xd.set.over.array
#
##############################################################################
proc moverects { rects over } \
{
    upvar $rects rrr
    upvar $over ooo
	
    a.v4tov2v2 rrr = rxy rsz
    a.ave rsz = size
    a.v2toxy size = sx sy
    set szx [a.ave sx]
    set szy [a.ave sy]

    a.add rxy "< $szx 0 >" = r1
    a.add rxy "< 0 $szy >" = r2
    a.add r1 "< 0 $szy >" = r3
    a.add r2 "< $szx 0 >" = r4

    a.v2v2tov4 rxy r1 = rr1
    a.v2v2tov4 rxy r2 = rr2
    a.v2v2tov4 r1 r3 = rr3
    a.v2v2tov4 r2 r4 = rr4
    
    a.catcol rr1 rr2 rr3 rr4 = ooo
}

