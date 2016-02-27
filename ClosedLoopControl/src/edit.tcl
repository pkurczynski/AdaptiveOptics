#
# These routines will bring up an image display window with rects drawn
# in it.  The user should be able to click on each rectangle to be able
# to turn it on/off ( green or red )
#
# To initialize the display, use
#
# editInit image rect title
#
# For example, we create a 100x100 image using
#
# editInit $Image $rects "title
#
# To get the final rects as modified by the user, use
#
# editGet final
#
# The `final' parameter will refer to a array of rectangles when
# it returns.  
#
# To get rid of the displays, use
#
# editTerm
#

###############################################################################
#
# This is the main entry point.  It sets up the image display and
# initializes the callback proc for the image display window.  After that,
# it is up to the callback proc.
#
###############################################################################
proc editInit { image rects title} \
{
    global ES
#
# Generate the image display window, if necessary.  fix
#
    if { [info exists ES(ID)] == 0 } \
    {
	id.new ES(ID)
    }
    id.set.title $ES(ID) $title
    id.set.xy $ES(ID) 290 170
 
#
# Display the array.
#
    id.set.array $ES(ID) $image
#
# Display the rectangles.
#
    id.set.rect.array ES(ID) rects
    a.copy rects = ES(RECTS)
#
# Determine the general info about the rectangles.
#
    a.extele $rects 0 = rrr
    a.split rrr = px py w h 
    set ES(W) [a.dump $w]
    set ES(H) [a.dump $h]
    set ES(NUM) [a.cols rects]
#
# Create a mask
#
    a.make 1 $ES(NUM) = ES(MASK)
    set ES(RED) 0
#
# Set up the callback for mouse events in the image display window.
#
    id.set.callback $ES(ID) editCallback
}

###############################################################################
# 
###############################################################################
proc editGet { out } \
{
    global ES
    
    upvar $out rects
    	
    set index 0

#   make an array of zeros with the number of rectangles - red rects
#   if the mask is 1 than the rectangle is valid

    a.make "<0. 0. 0. 0.>" [expr $ES(NUM) - $ES(RED)] = rects
    for { set i 0 } { $i < $ES(NUM) } { incr i } { 
	set result [a.extele ES(MASK) $i]
	if { $result == 1.0 } {
	    a.ins [a.ext ES(RECTS) $i 1] rects $index = rects
	    incr index
	}
    }
}

###############################################################################
# 
###############################################################################
proc editTerm { } \
{
    global ES

    if { [info exists ES(ID)] } \
    {
	unset ES(ID)
    }
    
}

###############################################################################
# fix
###############################################################################
proc editDraw { } \
{
    global ES 

    id.set.rect.array ES(ID) ES(RECTS)
    id.set.color.rect.array ES(ID) ES(RED_RECTS) 1.0 0.0 0.0
    return
}

###############################################################################
#
# Gets called back on mouse events in the image display window.  This just
# dispatches to the appropriate handler.
#
###############################################################################
proc editCallback { id type col row time state } \
{
    switch $type \
    {
	1 { editDoMouseMoved $id $col $row $state }
	2 { editDoMouseDown  $id $col $row $state }
	3 { editDoMouseUp    $id $col $row $state }
    }
}

###############################################################################
#
###############################################################################
proc editDoMouseDown { id col row state } \
{
    global ES
#
# If the user clicks well inside the edit, we want to drag its center.
# If the user clicks near the boundary of the edit, we want to resize it.
# If the user clicks outside the edit, we want to start a new edit.
#
    if { [editIsInside $col $row] } \
    {
	editDownInside $col $row
    } 
}

###############################################################################
#
# Returns 1 if the position x,y is inside the rectangle.
#
###############################################################################
proc editIsInside { x y } \
{
    global ES 
    
    set ES(INDEX) -1 

# go thru each rectangle to see if the click was within one of them
# identify that rectangle's array index
# looping from either the top or bottom

    if { $y < 240 } { 
	for { set i 0 } { $i < $ES(NUM) } { incr i } { 
	    a.extele ES(RECTS) $i = temp
	    a.split temp = a b c d
	    set px [a.dump a]
	    set py [a.dump b]
	    if { $y >= $py } {
		if { $y < [expr $py + $ES(H)] } {
		    if { ( $x >= $px ) && ( $x < [expr $px + $ES(W)] ) } { 
			set ES(INDEX) $i
			return 1
		    }
		}
	    } 
	} 
    } else { 
	for { set i [expr $ES(NUM) - 1] } { $i > -1 } { incr i -1 } { 
	    a.extele ES(RECTS) $i = temp
	    a.split temp = a b c d
	    set px [a.dump a]
	    set py [a.dump b]
	    if { $y < [expr $py + $ES(H)] } {
		if { $y >= $py } {
		    if { ( $x >= $px ) && ( $x < [expr $px + $ES(W)] ) } { 
			set ES(INDEX) $i
			return 1
		    }
		}
	    } 
	} 
    }
    if { $ES(INDEX) == -1 } {
	    return 0
    }
}

###############################################################################
#
# This is called if the user clicks inside a rectangle.
# It records where the user clicked and it makes a red rects array.
#
###############################################################################
proc editDownInside { x y } \
{
    global ES

# set the value of the mask
    set result [a.extele ES(MASK) $ES(INDEX)]
    if { $result == 0.0 } {
     	set temp 1 
    } else { 
      set temp 0  
    } 
    a.repele $temp ES(MASK) $ES(INDEX) = ES(MASK)

# need to make a red rect array
    if { $temp == 0 } { 
	incr ES(RED)
	if { $ES(RED) != 1 } { 
	    a.copy ES(RED_RECTS) = red_rects
	    a.ext ES(RECTS) $ES(INDEX) 1 = new 
	    a.make "<0. 0. 0. 0.>" $ES(RED) = ES(RED_RECTS)
	    a.ins red_rects ES(RED_RECTS) 0 = ES(RED_RECTS)
	    a.ins new ES(RED_RECTS) [expr $ES(RED)-1] = ES(RED_RECTS)
	} else { 
	    a.ext ES(RECTS) $ES(INDEX) $ES(RED) = ES(RED_RECTS)
	}
    } else { 
# need to remove item from red rect array 
	incr ES(RED) -1
	if { $ES(RED) != 0 } { 
	    set index 0
	    a.copy ES(RED_RECTS) = red_rects
	    set rect [a.ext ES(RECTS) $ES(INDEX) 1]
	    a.make "<0. 0. 0. 0.>" $ES(RED) = ES(RED_RECTS)
	    for { set i 0 } { $i <= $ES(RED) } { incr i } { 
		if { [a.ext red_rects $i 1] != $rect } { 
		    a.ins [a.ext red_rects $i 1] ES(RED_RECTS) $index \
			= ES(RED_RECTS)
		    incr index		
		}
	    }
	} else {
	    unset ES(RED_RECTS)
	}
    }	
    editDraw
}

###############################################################################
# 
###############################################################################
proc editDoMouseMoved { id col row state } \
{
    global ES

    update
}

###############################################################################
#
###############################################################################
proc editDoMouseUp { id col row state } \
{
    global ES
    
    update
}



