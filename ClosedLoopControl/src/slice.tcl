#
# This group of routines manages an image display and a plot display.  The
# Idea is to allow the user to specify one or more slices across the image
# display and have the data along the slices appear as plots in the plot
# display.
#
# In normal use, the user just wants to bring up the image display using a
# specific Array as the source of the data.  The user will interactively drag
# the pointer across the display area to specify line segments.  As the user
# releases the mouse button the data along the line segment will appear in
# the plot display.  The proc that allows the user to do this is
#
# sliceInit image
#
# Holding the shift key down while dragging will cause the previous line
# segment not to be deleted, so the user could specify multiple line segments
# and multiple slices to be plotted.  After the user is done, they would use
#
# sliceTerm
#
# to remove the windows and clean up.
#
# WaveScope would use these routines differently.  In a first step, the
# supervisor specifies the slices.  In the second step, the technician simply
# observes the data under the slices and possibly prints out a report.  The
# first step is interactive, the second step is not.  The first step uses
# a bogus 2-D Array, the second step displays data from the real 2-D Array.
#
# To initialize the system for the first step, use
#
# sliceInit image
#
# as before.  The `image' parameter should be a 2-D array of the same size the
# technician will observer in the second step.  After the supervisor has
# specified the slices, WaveScope should use
#
# sliceGet segments
#
# to retrieve the line segments the supervisor specified.  This proc will
# return an Array of line segments in the `segments' parameter.  The sliceTerm
# proc can still be used to get rid of the display windows.  Finally, when the
# time comes to display the data from the real Array, use
#
# sliceShow image segments
#
# where the `segments' parameter is the Array of line segments returned by
# sliceGet.  This simply brings up the image and plot displays, extracts
# the appropriate slices, and displays them.  There is no interaction with
# the user.  The sliceTerm proc can be used to get rid of these as well.
#

###############################################################################
#
# This is the main entry point.  It sets up the image and plot displays and
# initializes the callback proc for the image display window.  After that,
# it is up to the callback proc.
#
###############################################################################
proc sliceInit { image } \
{
#
# We will store all slice related state information in the array SlSt.
#
    global SlSt		
#
# First set up the displays.  We use a zero column 1-D segment Array to
# indicate that there are no segments.
#
    a.make "(<0 0 0 0>)" 0 = segments
    sliceShow $image $segments
#
# Set up the callback for mouse events in the image display window.
# This activates the interactive specification of slices.
#
    id.set.callback $SlSt(id) sliceCallback

#
# Clear the image display window of all current slices
#
    id.clr.over.array $SlSt(id)

    set SlSt(ColorIndex) 0

}

###############################################################################
#
# We bring up displays and initialize various internal structures here.  If
# the segments array has zero columns, no data will be extracted.
#
###############################################################################
proc sliceShow { image segments } \
{
#
# We will store all slice related state information in the array SlSt.
#
    global SlSt platform ws_results
#
# Generate the image display window, if necessary.
#
    if { [info exists SlSt(id)] == 0 } \
    {
	id.new SlSt(id)
	id.set.title $SlSt(id) "\"slices\" Display of Input Data"
	id.set.xy $SlSt(id) 650 300
	id.set.wh $SlSt(id) 500 500
    }
    
#
# Display the 2-D Array, and save it so we can extract stuff later.
#
    if { $platform == "windows" } { 
	id.set.array $SlSt(id) $image
    } else {
	set beam_min [a.minmask $image $ws_results(Mask)]
	set beam_max [a.maxmask $image $ws_results(Mask)]
	set beam_min [format %7.1f $beam_min]
	set beam_max [format %7.1f $beam_max]
	id.set.array $SlSt(id) $image $beam_min $beam_max
    }
    set SlSt(Image) $image
#
# Specify the colors we will use, and which color we are currently using.
#
    set SlSt(ColorList)  {   red   yellow   green   cyan   magenta  white }

    if { $platform == "windows" } { 
	id.set.over.width $SlSt(id) 0.5
	id.set.over.coords $SlSt(id) 1
    } else { 
	id.set.over.width $SlSt(id) 3
    }
#
# Generate the plot display window, if necessary.
#
    if { [info exists SlSt(pd)] == 0 } \
    {
       	pd.new SlSt(pd)
       	pd.set.title $SlSt(pd) "\"slices\" Display of Input Data Cuts"
       	pd.set.xy $SlSt(pd) 20 20
       	pd.set.wh $SlSt(pd) 500 300
    }
#
# Save the segments, then display the data.
#
    a.copy $segments = SlSt(Segments)
    sliceShowSlices
}

###############################################################################
#
# Cleans up the windows.
#
###############################################################################
proc sliceTerm { } \
{
    global SlSt
    
    if { [info exists SlSt(id)] } { unset SlSt(id) }
    if { [info exists SlSt(pd)] } { unset SlSt(pd) }
}

###############################################################################
#
# Returns the current state of the segments Array.
#
###############################################################################
proc sliceGet { segments } \
{
    global SlSt
    
    upvar $segments segs
    a.copy $SlSt(Segments) = segs
}

###############################################################################
#
# Gets called back on mouse events in the image display window.  This just
# dispatches to the appropriate handler.
#
###############################################################################
proc sliceCallback { id type col row time state } \
{
    switch -exact -- $type \
    {
	1 { doMouseMoved $id $col $row $state }
	2 { doMouseDown  $id $col $row $state }
	3 { doMouseUp    $id $col $row }
    }
}

###############################################################################
#
###############################################################################
proc doMouseDown { id col row state } \
{
    global SlSt
#
# Save the initial position, or end point, of this segment.
#        
    set SlSt(col0) $col
    set SlSt(row0) $row
#
# If the SHIFT key was not held down, clear the overlay Array and the plot
# display window.
#
    if { ( $state & 4 ) == 0 } \
    {
	set SlSt(ColorIndex) 0
	a.make "(<0 0 0 0>)" 0 = SlSt(Segments)
	set SlSt(PlotFlag) SET
    } \
    else \
    {
    	set SlSt(PlotFlag) ADD
    }
#
# Add a new line segment to the overlays Array.  The doMouseMoved proc only
# modifies the last segment.
#
    a.catcol $SlSt(Segments) "(<$col $row $col $row>)" = SlSt(Segments)
}

###############################################################################
#
###############################################################################
proc doMouseMoved { id col row state } \
{
    global SlSt platform
#
# Make sure mouse button 1 is down.
#

    if { ($state & 1) == 0 } return ;
#
# Save the position as the endpoint of this segment.
#    
    set SlSt(col1) $col
    set SlSt(row1) $row

#
# Stick the line segment from col0,row0 to col1,row1 in place of the last
# element of the overlays array.
#
    a.copy "<$SlSt(col0) $SlSt(row0) $SlSt(col1) $SlSt(row1)>" = seg
    a.repele $seg $SlSt(Segments) $SlSt(ColorIndex) = SlSt(Segments)

#
# Clear the overlays, then overlay each segment with the correct color.
#
    id.clr.over.array $SlSt(id)

    if { $platform == "windows" } { 
	for { set i 0 } { $i <= $SlSt(ColorIndex) } { incr i } \
	    {
		sliceGetWinColor $i red green blue
		id.set.over.width $SlSt(id) 0.5
		id.set.over.color $SlSt(id) $red $green $blue
		a.ext $SlSt(Segments) $i 1 = seg
		id.set.over.array $SlSt(id) $seg
	    }
    } else {	    
    	for { set i 0 } { $i <= $SlSt(ColorIndex) } { incr i } \
    	{
	    set color [sliceGetColor $i]
	    id.set.over.color $SlSt(id) $color
	    a.ext $SlSt(Segments) $i 1 = seg
	    id.set.over.array $SlSt(id) $seg
	}
    }
}

###############################################################################
#
###############################################################################
proc doMouseUp { id col row } \
{
    global SlSt wsMLMParams platform
#
# Record the final position
#    
    set SlSt(col1) $col
    set SlSt(row1) $row
#
# Extract the appropriate slice
#    
    sliceExtract $SlSt(Image) sss \
    		 $SlSt(col0) $SlSt(row0) \
    		 $SlSt(col1) $SlSt(row1)

#
# Send the slice to the plot display and set the color
#

    set pscale [expr $wsMLMParams(spacing) / 1000.0 ]
    if { [info exist sss] } {
      set pcols  [a.cols sss]
    } else {
      return
    }
    a.tilt $pcols 0 $pscale = xarr
    
    
    if { $SlSt(PlotFlag) == "ADD" } \
    {
    	pd.add.xy.array $SlSt(pd) $xarr $sss
    } \
    else \
    {
    	pd.set.xy.array $SlSt(pd) $xarr $sss
		if { $platform == "windows" } {
			pd.label.xy $SlSt(pd) "Position (mm)" "Intensity(ADU) "
		} else { 
			pd.label.xy $SlSt(pd) "Position (mm)" "Int.(ADU) "
		}
    }


    pd.set.color $SlSt(pd) [sliceGetColor $SlSt(ColorIndex)]
#
# Bump the color index.
#
    incr SlSt(ColorIndex)

	if {([expr $SlSt(col0)-$SlSt(col1)]==0) && ([expr $SlSt(row0)-$SlSt(row1)]==0)} {
		id.clr.over.array $SlSt(id)
	}

}

###############################################################################
#
###############################################################################
proc sliceExtract { in out col0 row0 col1 row1  } \
{

    upvar $out outdata 
#
# Figure out the length of the segment.
#
    set dx [expr $col1-$col0]
    set dy [expr $row1-$row0]

    set len [expr int(sqrt($dx*$dx+$dy*$dy))]
#
# If it is zero, (the user didn't move the mouse), just return the
# value under the cursor.
#
    if { $len <= 0 } \
    {
    	if { [catch { a.extele $in $col0 $row0 = outdata } result]} {
			return
	}
	a.shape $outdata 1 = outdata
	return
    }
#
# Prepare the output.
#
    a.flat [expr $len+1] 0 = outdata
    a.to $in f = fin
#
# Interpolate to get each sample for the output.
#    
    for { set i 0 } { $i <= $len } { incr i } \
    {
    	set x [expr $col0+$dx*$i/$len]
	set y [expr $row0+$dy*$i/$len]

	set z [a.interp $fin $x $y]

	if { [catch { a.repele $z $outdata $i = outdata } result] } { }
    }
}

###############################################################################
#
###############################################################################
proc sliceGetColor { i } \
{
    global SlSt
    
    set ci [expr $i % [llength $SlSt(ColorList)]]
    return [lindex $SlSt(ColorList) $ci]	
}

###############################################################################
#
###############################################################################
proc sliceGetWinColor { i red green blue } \
{ 
    global SlSt

    upvar $red r
    upvar $green g
    upvar $blue b

    set ci [expr $i % [llength $SlSt(ColorList)]]

    if { $ci == 0 } { 
	set r 1.0 ; set g 0.0 ; set b 0.0
    } elseif { $ci == 1 } { 
	set r 1.0 ; set g 1.0 ; set b 0.0
    } elseif { $ci == 2 } { 
	set r 0.0 ; set g 1.0 ; set b 0.0
    } elseif { $ci == 3 } { 
	set r 0.0 ; set g 1.0 ; set b 1.0
    } elseif { $ci == 4 } { 
	set r 1.0 ; set g 0.0 ; set b 1.0
    } elseif { $ci == 5 } { 
	set r 1.0 ; set g 1.0 ; set b 1.0
    } else { 
	set r 1.0 ; set g 0.0 ; set b 0.0
    }
}
	
###############################################################################
#
###############################################################################
proc sliceShowSlices { } \
{
  global SlSt wsMLMParams platform
  
  set nsegs [a.cols $SlSt(Segments)]
  
  for { set i 0 } { $i < $nsegs } { incr i } \
    {
      a.ext $SlSt(Segments) $i 1 = seg 
      a.to seg f = fseg
      set c0 [a.extele $fseg 0]
      set r0 [a.extele $fseg 1]
      set c1 [a.extele $fseg 2]
      set r1 [a.extele $fseg 3]
      sliceExtract $SlSt(Image)   sss   $c0 $r0   $c1 $r1
      #
      # Draw the segment in the image display window.
      #
      set color [sliceGetColor $i]
      if { $platform == "windows" } { 
	sliceGetWinColor $i red green blue
	id.set.over.color $SlSt(id) $red $green $blue
      } else { 
	id.set.over.color $SlSt(id) $color
      }
      id.set.over.array $SlSt(id) $seg
      #
      # Send the slice to the plot display and set the color
      #

      set pscale [expr $wsMLMParams(spacing) / 1000.0 ]
      if { [info exist sss] } {
	set pcols  [a.cols sss]
      } else {
	return
      }
      a.tilt $pcols 0 $pscale = xarr
      
      if { $i == 0 } \
	{
	  pd.set.xy.array $SlSt(pd) $xarr $sss
	} \
	else \
	{
	  pd.add.xy.array $SlSt(pd) $xarr $sss
	}
      
      pd.set.color $SlSt(pd) $color
    }
}
