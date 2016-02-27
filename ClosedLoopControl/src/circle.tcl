#
# These routines will bring up an image display window with a circle drawn
# in it.  The user should be able to move and resize the circle.
# To move the circle, mouse button down near the center and drag.
# To resize the circle, mouse button down near the edge and drag.
# To start a new circle at a new center, mouse button down outside the circle
# on the new center you want.
#
# To initialize the display with a particular circle, use
#
# circleInit image circle
#
# For example, we create a 100x100 image and a 3-element circle using
#
# a.tilt 100 100 0 1 2 = Image
# a.copy "( 50 50 25 )" = Circ
# circleInit $Image $Circ
#
# The `circle' argument, as usual, is a 3-element floating point array
# with the col,row of the center and the radius.
#
# To get the final circle as modified by the user, use
#
# circleGet final
#
# The `final' parameter will refer to a 3-element floating point array when
# it returns.  If you don't believe me, do
#
# circleGet final
# a.info $final
# a.dump $final
#
# To get rid of the displays, use
#
# circleTerm
#

###############################################################################
#
# This is the main entry point.  It sets up the image display and
# initializes the callback proc for the image display window.  After that,
# it is up to the callback proc.
#
###############################################################################
proc circleInit { image circ title} \
{
    global CS
#
# Generate the image display window, if necessary.
#
    if { [info exists CS(ID)] == 0 } \
    {
	id.new CS(ID)
    }
    
    id.set.title $CS(ID) $title
    id.set.xy $CS(ID) 625 150
    id.set.wh $CS(ID) 500 500

#
# Display the array.
#
    id.set.array $CS(ID) $image
#
# Create the initial position and circle
#
    set CS(COL) 0.0
    set CS(ROW) 0.0
    set CS(X) [a.extele $circ 0]
    set CS(Y) [a.extele $circ 1]
    set CS(R) [a.extele $circ 2]
    
    circleDraw
#
# Set the state to NONE.  Other possibilites are DRAG and RESIZE.
#
    set CS(STATE) NONE
#
# Make the info panel, if necessary.
#
    if { [info commands .c] == "" } \
    {
    	circleMakePanel
    }
#
# Set up the callback for mouse events in the image display window.
#
    id.set.callback $CS(ID) circleCallback
}

###############################################################################
#
###############################################################################
proc circleGet { out } \
{
    global CS
    
    upvar $out circ
    
    a.copy "( $CS(X) $CS(Y) $CS(R) )" = circ
}

###############################################################################
#
###############################################################################
proc circleTerm { } \
{
    global CS

    if { [info exists CS(ID)] } \
    {
	unset CS(ID)
    }
    
    if { [winfo exists .c] } \
    {
    	destroy .c
    }
}

###############################################################################
#
###############################################################################
proc circleDraw { } \
{
    global CS 
    global platform

    if { $platform == "windows" } { 
	id.clr.over.array $CS(ID)
	id.set.over.coords $CS(ID) 1
	id.set.over.color $CS(ID) 1.0 1.0 0.0

	makecir $CS(X) $CS(Y) $CS(R) Cirover
	id.set.over.array $CS(ID) Cirover
    } else {
	id.clr.circ.array $CS(ID)
	id.set.circ.array $CS(ID) "( $CS(X) $CS(Y) $CS(R) )"
    }
    return
}

###############################################################################
#
# This makes a little panel that shows the current position and the current
# circle paramters, just for convienience (debugging).
#
###############################################################################
proc circleMakePanel { } \
{
    global  CS
    
    toplevel .c
	wm geometry .c +337+96
    
    label .c.col -text [format "current col %6.2f" $CS(COL)]
    label .c.row -text [format "current row %6.2f" $CS(ROW)]
    label .c.x   -text [format "center col  %6.2f" $CS(X)]
    label .c.y   -text [format "center row  %6.2f" $CS(Y)]
    label .c.r   -text [format "radius      %6.2f" $CS(R)]
    
    pack .c.col .c.row .c.x .c.y .c.r -side top
}

###############################################################################
#
###############################################################################
proc circleUpdatePanel { } \
{
    global CS

    .c.col configure -text [format "current col %6.2f" $CS(COL)]
    .c.row configure -text [format "current row %6.2f" $CS(ROW)]
    .c.x   configure -text [format "center col  %6.2f" $CS(X)]
    .c.y   configure -text [format "center row  %6.2f" $CS(Y)]
    .c.r   configure -text [format "radius      %6.2f" $CS(R)]
}

###############################################################################
#
# Gets called back on mouse events in the image display window.  This just
# dispatches to the appropriate handler.
#
###############################################################################
proc circleCallback { id type col row time state } \
{
    switch $type \
    {
	1 { circleDoMouseMoved $id $col $row $state }
	2 { circleDoMouseDown  $id $col $row $state }
	3 { circleDoMouseUp    $id $col $row $state }
    }
}

###############################################################################
#
###############################################################################
proc circleDoMouseDown { id col row state } \
{
    global CS
#
# If the user clicks well inside the circle, we want to drag its center.
# If the user clicks near the boundary of the circle, we want to resize it.
# If the user clicks outside the circle, we want to start a new circle.
#
    if { [circleIsInside $col $row] } \
    {
	circleDownInside $col $row
    } \
    else \
    {
	if { [circleIsOnEdge $col $row] } \
	{
	    circleDownOnEdge $col $row
	} \
	else \
	{
	    circleDownOutside $col $row
	}
    }
}

###############################################################################
#
# Returns 1 if the position x,y is well inside the current circle.
#
###############################################################################
proc circleIsInside { x y } \
{
    global CS
    
    if { [circleDistance $x $y] < [expr $CS(R) - 3.0] } \
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
# Returns 1 if the position x,y is near the edge of the current circle.
#
###############################################################################
proc circleIsOnEdge { x y } \
{
    global CS
    
    set d [circleDistance $x $y]
    if { ( $d >= [expr $CS(R) - 4.0] ) && \
	 ( $d <= [expr $CS(R) + 10.0] ) } \
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
# Returns the distance of the point x,y from the center of the current circle.
#
###############################################################################
proc circleDistance { x y } \
{
    global CS
    
    set dx [expr $x-$CS(X)]
    set dy [expr $y-$CS(Y)]
    
    return [ expr sqrt( $dx*$dx + $dy*$dy ) ]
}

###############################################################################
#
# This is called if the user clicks inside the circle.
# It just records where the user clicked relative to the center of the circle.
# The mouseMoved routine does all of the real work.
#
###############################################################################
proc circleDownInside { x y } \
{
    global CS
    
    set CS(STATE) DRAG
    set CS(DX) [expr $x-$CS(X)]
    set CS(DY) [expr $y-$CS(Y)]
}

###############################################################################
#
# This is called if the user clicks on the edge of the circle.
# It just records where the user clicked relative to the center of the circle.
# The mouseMoved routine does all of the real work.
#
###############################################################################
proc circleDownOnEdge { x y } \
{
    global CS
    
    set CS(STATE) RESIZE
    set r [circleDistance $x $y]
    set CS(DR) [expr $r-$CS(R)]
}

###############################################################################
#
# This is called if the user clicks outside the current circle.  We just
# create a new circle centered at the point the user clicked and pretend
# we were resizing it.
#
###############################################################################
proc circleDownOutside { x y } \
{
    global CS
    
    set CS(X) $x
    set CS(Y) $y
    set CS(R) 5.0
    
    circleUpdatePanel
    circleDraw
    update
    
    circleDownOnEdge $x $y
}

###############################################################################
#
# We do the correct thing, depending on whether or not we are resizing or
# dragging the circle.  If we are doing neither, we just display the current
# position in the convienience panel.
#
###############################################################################
proc circleDoMouseMoved { id col row state } \
{
    global CS
#
# Save the current position.
#
    set CS(COL) $col
    set CS(ROW) $row
#
# Always display the current column and row.
#
    circleUpdatePanel
#
# Depending on the STATE, we either DRAG or RESIZE.
#
    if { $CS(STATE) == "DRAG" } \
    {
	circleDoDrag $col $row
    } \
    else \
    {
	if { $CS(STATE) == "RESIZE" } \
	{
	    circleDoResize $col $row
	}
    }
}

###############################################################################
#
# We make sure we are neither dragging or resizing after the mouse button
# is released.
#
###############################################################################
proc circleDoMouseUp { id col row state } \
{
    global CS
    
    id.sync $id
    update
    set CS(STATE) NONE
}

###############################################################################
#
# Here we adjust the center of the circle based on the current mouse position.
#
###############################################################################
proc circleDoDrag { x y } \
{
    global CS
    
    set CS(X) [expr $x-$CS(DX)]
    set CS(Y) [expr $y-$CS(DY)]
    circleUpdatePanel
    circleDraw
    update
}

###############################################################################
#
# Here we adjust the radius of the circle based on the current mouse position.
#
###############################################################################
proc circleDoResize { x y } \
{
    global CS
    
    set r [circleDistance $x $y]
    set CS(R) [expr $r-$CS(DR)]
    
    if { $CS(R) < 3.0 } { set CS(R) 3.0 }
    
    circleUpdatePanel
    circleDraw
    update
}
