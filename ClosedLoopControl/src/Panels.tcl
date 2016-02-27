#==========================================================================
# 
# 			Adaptive Optics Associates
# 			  54 CambridgePark Drive
# 			 Cambridge, MA 02140-2308
# 				    USA
# 			   (Phone) 617-864-0201
# 			    (Fax) 617-864-1348
# 
#                Copyright 1999 Adaptive Optics Associates
# 			    All Rights Reserved
# 
#==========================================================================

#--------------------------------------------------------------------------
# 
# FILE: Panels.tcl
# 
# DESCRIPTION:	
#   Generic panels
# 
# $Id: Panels.tcl,v 1.33 2001/05/16 22:53:59 herb Exp $
# 
#---------------------------------------------------------------------------


#---------------------------------------------------------------------------
# proc dialog
#
# Makes a modal dialog box with a message which won't go away until the user
# hits OK.
#---------------------------------------------------------------------------

proc dialog { mess {geom 0} } {

  global applicationName wlPanel wsdb


  if { [winfo exist .dialog] } { destroy .dialog }

  toplevel .dialog
  if { $geom == 0 } {
    wm geometry .dialog +500+350
  } else {
    wm geometry .dialog $geom
  }
  wm title .dialog "$applicationName"

  message .dialog.message -width 10c -text $mess
  button .dialog.okbutton -text "  OK  " \
    	-command { destroy .dialog } -font $wsdb(font)
  pack .dialog.message .dialog.okbutton -side top -padx 5 -pady 5

  update
  grab .dialog

  tkwait window .dialog
}


#---------------------------------------------------------------------------
# proc PanelsInit
#
# Initialize the panel data structures
#---------------------------------------------------------------------------

proc PanelsInit {} \
{
    global wlPanel

    #
    # Structure fields for text/entry panels
    #
    set wlPanel(panelGeometry) +300+300

    set wlPanel(action)	""
    set wlPanel(entry)	""

    set hgt [winfo screenheight .]
    set wdt [winfo screenwidth .]

    set wlPanel(midWinGeometry) +230+230
    set wlPanel(smallWinGeometry) +200+32
}


#---------------------------------------------------------------------------
# proc wl_PanelsYesNo msg
#
# Show message and prompt the user to answer Yes or No.
# Returns Yes, No or Abort if the window is destroyed
#---------------------------------------------------------------------------

proc wl_PanelsYesNo { msg {geom 0} {width 7c} } {

  global applicationName wlPanel 


  if { [winfo exist .wyn] } { destroy .wyn }

  toplevel .wyn 
  if { $geom == 0 } {
    wm geometry .wyn +200+32
  } else {
    wm geometry .wyn $geom
  }

  wm title .wyn "$applicationName"
    
  frame .wyn.frame1 -relief flat 
  pack .wyn.frame1 -side top
    
  label .wyn.frame1.wyn -bitmap question
  pack .wyn.frame1.wyn -side left -pady 4m -padx 4m
    
  message .wyn.frame1.mess -text $msg -width $width
  pack .wyn.frame1.mess -side left

  frame .wyn.frame2 -relief flat 
  pack .wyn.frame2 -side top
    
  button .wyn.frame2.ybutton -text Yes -command { set wlPanel(action) Yes }
  pack .wyn.frame2.ybutton -side left -padx 2m -pady 2m

  button .wyn.frame2.nbutton -text No -command { set wlPanel(action) No }
  pack .wyn.frame2.nbutton -side right -padx 2m -pady 2m
    
  bind .wyn <Destroy> { set wlPanel(action) Abort }

  tkwait variable wlPanel(action)

  set answer $wlPanel(action)

  if { [winfo exist .wyn] } { destroy .wyn }
    
  set wlPanel(action) $answer

  return $answer
}


#---------------------------------------------------------------------------
# proc wl_PanelsContinueAbort
#
# Displays the message in msg and prompts the user to select OK or Cancel.
# Returns Continue or Abort when the window is closed.
#---------------------------------------------------------------------------

proc wl_PanelsContinueAbort { msg {geom 0} {width 7c} } {

    global applicationName wlPanel


    if { [winfo exist .wyn] } { destroy .wyn }

    toplevel .wyn
    if { $geom == 0 } {
      if {[info exist wlPanel(smallWinGeometry)]} {
	  wm geometry .wyn $wlPanel(smallWinGeometry)
      }
    } else {
      wm geometry .wyn $geom
    }
    wm title .wyn "$applicationName"
    
    frame .wyn.frame1 -relief flat 
    pack  .wyn.frame1 -side top
    
    label .wyn.frame1.wyn -bitmap question
    pack  .wyn.frame1.wyn -side left -pady 4m -padx 4m
    
    message .wyn.frame1.mess -text $msg -width $width
    pack    .wyn.frame1.mess -side left

    frame .wyn.frame2 -relief flat 
    pack  .wyn.frame2 -side top
    
    button .wyn.frame2.ybutton -text " OK " \
	    -command { set wlPanel(action) Continue }
    pack   .wyn.frame2.ybutton -side left -padx 2m -pady 2m

    button .wyn.frame2.nbutton -text Cancel \
	    -command { set wlPanel(action) Abort }
    pack   .wyn.frame2.nbutton -side right -padx 2m -pady 2m
    
    bind .wyn <Destroy> { set wlPanel(action) Abort }

    tkwait variable wlPanel(action)

    set answer $wlPanel(action)

    if { [winfo exist .wyn] } { destroy .wyn }
    update
    
    return $answer
}


#---------------------------------------------------------------------------
# proc verify_panel msg
#
# Show message and prompt the user to answer Continue or Abort.
# Returns Continue or Abort if the window is destroyed
#---------------------------------------------------------------------------

proc verify_panel {msg} {

    global applicationName wlPanel


    if { [winfo exist .vp] } { destroy .vp }

    toplevel .vp 

    if {[info exist wlPanel(smallWinGeometry)]} {
	wm geometry .vp $wlPanel(smallWinGeometry)
    } 

    wm title .vp "$applicationName"
    
    frame .vp.frame1 -relief flat 
    pack .vp.frame1 -side top
    
    label .vp.frame1.vp -bitmap question
    pack .vp.frame1.vp -side left -pady 4m -padx 4m
    
    message .vp.frame1.mess -text $msg -width 7c 
    pack .vp.frame1.mess -side left

    frame .vp.frame2 -relief flat 
    pack .vp.frame2 -side top
    
    button .vp.frame2.ybutton -text Continue \
	-command { set wlPanel(action) Continue }
    pack .vp.frame2.ybutton -side left -padx 2m -pady 2m

    button .vp.frame2.nbutton -text Abort \
	-command { set wlPanel(action) Abort }
    pack .vp.frame2.nbutton -side right -padx 2m -pady 2m

    bind .vp <Destroy> { set wlPanel(action) Abort }

    raise .vp .wsBar

    while { $wlPanel(action) == "Paused" } { 
	raise .vp .wsBar
	update
    } 	
 	
    set answer $wlPanel(action)

    if { [winfo exist .vp] } { destroy .vp }
    
    set wlPanel(action) $answer

    return $answer
}


#---------------------------------------------------------------------------
# proc wl_PanelsMsg msg
#
# Show message 
#---------------------------------------------------------------------------

proc wl_PanelsMsg {msg {geom 0} } {

    global applicationName wlPanel


    if { [winfo exist .wmsg] } { destroy .wmsg }

    toplevel .wmsg 

    if { $geom == 0 } {
      if {[info exist wlPanel(smallWinGeometry)]} {
	  wm geometry .wmsg $wlPanel(smallWinGeometry)
      }
    } else {
      wm geometry .wmsg $geom
    }

    wm title .wmsg "$applicationName"
    
    frame .wmsg.frame1 -relief flat 
    pack .wmsg.frame1 -side top
    
    label .wmsg.frame1.wmsg -bitmap warning
    pack .wmsg.frame1.wmsg -side left -pady 4m -padx 4m
    
    message .wmsg.frame1.mess -text $msg -width 7c 
    pack .wmsg.frame1.mess -side left

    frame .wmsg.frame2 -relief flat 
    pack .wmsg.frame2 -side top
    
    button .wmsg.frame2.ybutton -text "  OK  " \
	-command { destroy .wmsg }
    pack .wmsg.frame2.ybutton -side left -padx 2m -pady 2m

    bind .wmsg <Key-Return> { destroy .wmsg }
    bind .wmsg <Destroy> { destroy .wmsg }

    tkwait window .wmsg
}


#---------------------------------------------------------------------------
# proc wl_RadioPanel
#
# Get user selection from a list of radiobuttons.
# 	$title is the title for the window
#	$message is the instructional message to the user
#	$default is the default value (the button with this value will
#		be highlighted
#	{text1 value1} {text2 value2} {text3 value3} ...
#		One or more text-value pairs that are used to fill in the
#		radiobuttons.
#---------------------------------------------------------------------------

proc wl_RadioPanel { title message default args } \
{
    global applicationName wlPanel
    global  wlRadioVar

    
    #
    # Does this window exist?
    #
    if { [winfo exists .wlRadio] } { destroy .wlRadio }

    #
    # Create the panel
    #
    toplevel	.wlRadio
    wm title	.wlRadio $title
    wm geometry .wlRadio +908+31

    #
    # manager
    #
    frame	.wlRadio.frame -relief flat
    pack	.wlRadio.frame -padx 1m -pady 1m
    
    #
    # Work area
    #

    frame	.wlRadio.frame.work -relief groove -bd 3
    pack	.wlRadio.frame.work -side top -fill x -padx 1m -pady 1m

    label	.wlRadio.frame.work.label -text $message
    pack	.wlRadio.frame.work.label -side top -fill x -padx 1m -pady 1m

    set count 0
    foreach pair $args {
	set label [lindex $pair 0]
	set value [lindex $pair 1]

	radiobutton .wlRadio.frame.work.$count -text $label -value $value \
	    -variable wlRadioVar -anchor w
	pack .wlRadio.frame.work.$count -side top -fill x -padx 1m -pady 1m
	incr count
    }
    set wlRadioVar $default


    #
    # action area
    #
    frame	.wlRadio.frame.action -relief flat
    pack	.wlRadio.frame.action -padx 1m -pady 1m

    button	.wlRadio.frame.action.ok -text "OK" \
	-command { destroy .wlRadio; set wlPanel(action) "OK" }
    button	.wlRadio.frame.action.cancel -text "Cancel" \
	-command { destroy .wlRadio; set wlPanel(action) "Cancel" }
    pack	\
	.wlRadio.frame.action.ok \
	.wlRadio.frame.action.cancel \
	-side left -padx 1m -pady 1m -expand 1
    
    #
    # Wait for user input
    #
    tkwait window .wlRadio

    #
    # Return the selected value
    #
    if { $wlPanel(action) == "Cancel" } {
	return ""
    } else {
	return $wlRadioVar
    }
}


#------------------------------------------------------------------------------
# proc PanelsGetFile
#
# Displays a file/directory selector where the user can select a file.
# The initial directory is set to "idir".
# "msg" should be an instructional message.
# Returns the selected path including the file name, or an empty
# string if cancelled.
#------------------------------------------------------------------------------

proc PanelsGetFile { idir msg } {

  global applicationName wlPanel

  
  if { [winfo exist .wgetfile] } { destroy .wgetfile }

  set wlPanel(dirsel) $idir
  set blist "\"  OK  \""
  lappend blist "set wlPanel(action) \"O.k\""
  lappend blist "Cancel"
  lappend blist "set wlPanel(action) \"Cancel\""
  PanelsGenericFrame .wgetfile "Select File" PanelsCreateFs $msg $blist

  tkwait variable wlPanel(action)
  if { $wlPanel(action) != "Cancel" } {

    if {[winfo exist .wgetfile]} { destroy .wgetfile }
	
    # Remove any white space
    #
    set wlPanel(filesel) [string trim $wlPanel(filesel) ]
    return [format "%s/%s" $wlPanel(dirsel) $wlPanel(filesel)]
  } 

  if {[winfo exist .wgetfile]} { destroy .wgetfile }

  return ""
}



#--------------------------------------------------------------------------
# proc PanelsCreateFs
#
# Creates a file/directory selector inside window "win"
# and displays instructional message "msg" 
#--------------------------------------------------------------------------

proc PanelsCreateFs {win msg} {

  message $win.label -width 14c -text $msg
  pack $win.label -side top -fill x

  frame $win.lboxframe 
  pack $win.lboxframe -side top -padx 2m -pady 2m -fill both

  wl_panelsCreateFsListboxes $win.lboxframe

  frame $win.sels
  pack $win.sels -side top -padx 2m -pady 2m -fill both

  message $win.sels.label -width 12c -text "Single-click with the left mouse\
      button to change directories or select a file"
  pack $win.sels.label -side top -fill x

  frame $win.dir; pack $win.dir -side top -fill x
  wl_panelsEntry $win.dir "Dir:" "wlPanel(dirsel)"

  frame $win.file; pack $win.file -side top -fill x
  wl_panelsEntry $win.file "File:" "wlPanel(filesel)"
}


#---------------------------------------------------------------------------
# wl_panels_callProc mode numcols numrows
#
# Calls procedures in wl_rowproc with arguments in wl_rowdata
# To be used with wl_EntryPanel
#---------------------------------------------------------------------------
proc wl_panels_callProc {mode numcols numrows} {

    global applicationName wl_rowdata wl_rowproc


    # copy each row information into a list
    # copy object names
    #
    for {set j 1} {$j <= $numrows} {incr j} {
	lappend row($j) $wl_rowdata(0,$j)
    }
    for {set i 1} {$i <= $numcols} {incr i} {
	for {set j 1} {$j <= $numrows} {incr j} {
	    if {$mode == "OK"} {
		lappend row($j) $wl_rowdata($i,$j)
	    } else {
		lappend row($j) $wl_rowdata($i,1)
	    }
	}
    } 

    # call each procedure 
    #
    for {set j 1} {$j <= $numrows} {incr j} { 
	if { [$wl_rowproc($j) $row($j)] == "Error" } {
	    return "Error"
	}
    }
}


#---------------------------------------------------------------------------
# wl_panels_copyrowdata numcols numrows
#
# Copies wl_rowdata from the first row
# To be used with wl_EntryPanel
#---------------------------------------------------------------------------

proc wl_panels_copyrowdata {numcols numrows} {

    global applicationName wl_rowdata wl_rowproc

    for {set i 1} {$i <= $numcols} {incr i} {
	for {set j 2} {$j <= $numrows} {incr j} {
	    set wl_rowdata($i,$j) $wl_rowdata($i,1)
	}
    }
}


#---------------------------------------------------------------------------
# wl_PanelsEntry title message coltitle args
#
# Get numeric values from n columns of entry boxes.
#
# 	$title is the window's title
#
#	$message is an instructional message that will be shown near the 
#       top of the window
#
#       $coltitle is a list of column titles
#                {col1title col2title .. colntitle}
#
#       $args is a list of entries that define the panel. $args must be 
#       organized as follows: for each row you should include
#              rowname ivcol1 ivcol2 ... ivcoln procname 
#       where
#         rowname is the name to be used for the row
#         ivcoli is the initial value to be shown in column i
#         procname is the procedure name. This procedure will be called 
#         when the users presses the "O.k." or "Use first" buttons (see
#         description below).  The rowname and entry box values will be
#         passed in a list as a single argument to this procedure.
#
#       Three buttons, labeled "O.k.", "Use first" and "Cancel" will be
#       shown at the button of the panel. 
#       Selecting  "Cancel" will destroy the window without calling any 
#       procedures.
#       Selecting "O.k." destroys the window after calling the proc.for 
#       associated with each row. 
#       Selecting "Use first" works like "O.k.", but the values shown 
#       for the first row are used for all rows.
#
#       Example:
#         # set up lists before calling wl_PanelsEntry
#         set title WaveLab
#         set msg "Start and Stop frames panel"
#         set colnames "start stop"
#         set rarg "Image 1 10 proc1 Vectors 1 10 proc2 Forms 1 10 proc3"
#         # call wl_PanelsEntry 
#         wl_PanelsEntry $title $msg $colnames $rarg
#
#---------------------------------------------------------------------------

proc wl_PanelsEntry {title message coltitle rowargs} {

    # rawdata is global because entry widgets display global variables
    global applicationName wl_rowdata wl_rowproc wlPanel
    

    # Does this window exist?
    #
    if { [winfo exists .wlEntry] } { destroy .wlEntry }

    # Create the panel
    #
    toplevel	.wlEntry
    wm title	.wlEntry $title
    if {[info exist wlPanel(midWinGeometry)]} {
	wm geometry .wlEntry $wlPanel(midWinGeometry)
    } else {
	wm geometry .wlEntry +300+100
    }

    frame	.wlEntry.frame -relief flat
    pack	.wlEntry.frame -padx 1m -pady 1m
    
    # Message area
    #
    frame	.wlEntry.frame.msg -relief groove -bd 3
    pack	.wlEntry.frame.msg -side top -fill x -padx 1m -pady 1m
    label	.wlEntry.frame.msg.label -text $message
    pack	.wlEntry.frame.msg.label -side top -fill x -padx 1m -pady 1m

    # figure out the number of rows
    #
    set numcols [llength $coltitle]
    set numargs [llength $rowargs]
    set numrows [expr $numargs/($numcols + 2)]

    # Data area
    # Using "i" for column number, "j" for row number
    #
    # arrange first row strings
    #
    # add empty string to in the first row, first column 
    set wl_rowdata(0,0) "  "

    # store column titles
    #
    for {set i 1} {$i <= $numcols} {incr i} {
	set wl_rowdata($i,0) [lindex $coltitle [expr $i-1]]
    }

    # store the information on the other rows
    #
    for {set j 1} {$j <= $numrows} {incr j} {
	# store row name 
	# since row and procedure names are the first and last elements
	# of "rowargs", we must add 2 to $numcols.  
        #
	set wl_rowdata(0,$j) [lindex $rowargs [expr ($j-1)*($numcols+2)]]

	# now store data for each column
        #
	for {set i 1} {$i <= $numcols} {incr i} {
	    set wl_rowdata($i,$j) \
		[lindex $rowargs [expr ($j-1)*($numcols+2)+$i]]
	}
 
	# store procedure name.
        #
	set wl_rowproc($j) \
		[lindex $rowargs [expr ($j-1)*($numcols+2)+$i]]
    }
    
    # create one frame per column, plus one for row names
    #
    frame .wlEntry.frame.data 
    pack .wlEntry.frame.data -side top -padx 1m -pady 1m

    # write the row names in the first column
    #
    frame .wlEntry.frame.data.0
    pack .wlEntry.frame.data.0 -side left -fill y -padx 1m -pady 1m

    label .wlEntry.frame.data.0.0  -text " "   -padx 1m -pady 0.9m
    pack .wlEntry.frame.data.0.0 -side top -fill y 
   
    for {set j 1} {$j <= $numrows} {incr j} {
	set objname $wl_rowdata(0,$j)
	set procname "wl_${objname}Get"
	label .wlEntry.frame.data.0.$j \
	    -text [$procname name]  \
	    -padx 1m -pady 0.9m
 	pack .wlEntry.frame.data.0.$j -side top -fill y 
    }

    # now write into the other columns
    #
    for {set i 1} {$i <= $numcols} {incr i} {
	frame .wlEntry.frame.data.$i 
	pack .wlEntry.frame.data.$i -side left -padx 1m -pady 1m

	# pack labels on the top row 
        #
 	label .wlEntry.frame.data.$i.0 -text $wl_rowdata($i,0)
 	pack .wlEntry.frame.data.$i.0 -side top -fill x -padx 1m -pady 1m
	for {set j 1} {$j <= $numrows} {incr j} {
	    entry .wlEntry.frame.data.$i.$j -textvariable wl_rowdata($i,$j)
	    pack .wlEntry.frame.data.$i.$j -side top -fill x -padx 1m -pady 1m
	}
    }

    for {set i 0} {$i <= $numcols} {incr i} {
	for {set j 0} {$j <= $numrows} {incr j} {
	    pack .wlEntry.frame.data.$i.$j -side top -fill x -padx 1m -pady 1m
	}
    }

    # action area
    #
    # show row of buttons on the bottom of the windows
    #
    frame .wlEntry.frame.action -relief flat
    pack .wlEntry.frame.action -side top -expand 1 -fill both -padx 1m -pady 1m

    button .wlEntry.frame.action.ok -text "O.k." \
	-command {set wlPanel(action) "O.k."}
    button	.wlEntry.frame.action.copy -text "Copy" \
	-command { set wlPanel(action) "COPY" }
    button	.wlEntry.frame.action.cancel -text "Cancel" \
	-command { set wlPanel(action) "Cancel" }
    pack	\
	.wlEntry.frame.action.ok \
	.wlEntry.frame.action.copy \
	.wlEntry.frame.action.cancel \
	-side left -expand 1 -fill both -ipadx 1m -ipady 1m

    while { 1 } {
	tkwait variable wlPanel(action)

	if {$wlPanel(action) == "COPY"} {
	     wl_panels_copyrowdata $numcols $numrows 
	} 
 
	if {$wlPanel(action) == "Cancel"} { 
	    if {[winfo exist .wlEntry]} { destroy .wlEntry }
	    return "Abort" 
	}	 

	if {$wlPanel(action) == "O.k."} {
	    if {[wl_panels_callProc $wlPanel(action) $numcols $numrows] \
		    != "Error"} {
		if {[winfo exist .wlEntry]} { destroy .wlEntry }
		return $wlPanel(action)
	    }
	}
    }
}


proc wl_PanelsBlink { w } {
    wl_panelsBlink $w -background green1 #d49 500
}


proc wl_panelsBlink {w option value1 value2 interval} \
{
    if { [winfo exists $w] } { $w config $option $value1 }
    if { [winfo exists $w] } \
    {
    after $interval [list wl_panelsBlink $w $option $value2 $value1 $interval]

    }
}


#---------------------------------------------------------------------------
# proc wl_CheckPanel title message args
#
# Get user selection from a list of checkbuttons.
# 	$title is the title for the window
#	$message is an instructional message to the user
#	$default is a default value (the button with this value will
#		be highlighted
#	{text1 value1} {text2 value2} {text3 value3} ...
#		One or more text-value pairs that are used to fill in the
#		checkbuttons.
#---------------------------------------------------------------------------

proc wl_CheckPanel { title message args } \
{
    global applicationName wlPanel
    global wlCheckVar
    

    #
    # Does this window exist?
    #
    if { [winfo exists .wlCheck] } { destroy .wlCheck }

    #
    # Create the panel
    #
    toplevel	.wlCheck
    wm title	.wlCheck $title

    #
    # manager
    #
    frame	.wlCheck.frame -relief flat
    pack	.wlCheck.frame -padx 1m -pady 1m
    
    #
    # Work area
    #
    frame	.wlCheck.frame.work -relief groove -bd 3
    pack	.wlCheck.frame.work -side top -fill x -padx 1m -pady 1m

    label	.wlCheck.frame.work.label -text $message
    pack	.wlCheck.frame.work.label -side top -fill x -padx 1m -pady 1m

    set count 0
    foreach pair $args {
	set label [lindex $pair 0]
	set wlCheckVar($count) [lindex $pair 1]

	checkbutton .wlCheck.frame.work.$count -text $label \
	    -variable wlCheckVar($count) -anchor w
	pack .wlCheck.frame.work.$count -side top -fill x -padx 1m -pady 1m
	incr count
    }
	
    #
    # action area
    #
    frame	.wlCheck.frame.action -relief flat
    pack	.wlCheck.frame.action -padx 1m -pady 1m

    button	.wlCheck.frame.action.ok -text "OK" \
	-command { destroy .wlCheck; set wlPanel(action) "OK" }
    button	.wlCheck.frame.action.cancel -text "Cancel" \
	-command { destroy .wlCheck; set wlPanel(action) "Cancel" }
    pack	\
	.wlCheck.frame.action.ok \
	.wlCheck.frame.action.cancel \
	-side left -padx 1m -pady 1m -expand 1
    
    #
    # Wait for user input
    #
    tkwait window .wlCheck

    #
    # Return the selected values in a list
    #
    for {set i 0} {$i < $count} {incr i} {
	lappend result $wlCheckVar($i)
    }
    if { $wlPanel(action) == "Cancel" } {
	return "Cancel"
    } else {
	return $result
    }
}


#-------------------------------------------------------------------------
# wl_panelsCheckRadio w swname bnames1 vnames1 bnames2 vnames2 mode
#
# Creates a subwindow inside frame $w.
# The subwindow contains an arbitrary number of check buttons arranged
# horizontally below a message that describes the subwindow's purpose.
# Each button shows a label indicating the choice associated with the 
# botton.
# The parameters are
# w          name of the frame in which the window will be embeded
# swname     subwindow's name or message
# bnames     list containing names used to label the check buttons 
#            and to index varray
# vnames     list of global variables where button selections are stored 
# mode       flag indicating if one or two columns should be shown
#-------------------------------------------------------------------------

proc wl_panelsCheckRadio {w swname bnames1 vnames1 bnames2 vnames2 mode} {

    # Do nothing if there are no check boxes
    #
    if { ($vnames1 == " ") && ($mode != "twocolumn") } { return "O.k." }
    if { ($vnames1 == "") && ($vnames2 != "") } { return "O.k." }

    set wname "$w.wl$swname"
    frame $wname -relief groove -bd 3 

    label $wname.name -text $swname -anchor w -width 16

    pack $wname.name -side left -fill both -padx 1m -pady 1m  

    frame $wname.center 	-relief raised -width 1.5c
    pack $wname.center -side left -fill both -padx 1m -pady 1m 

    for {set i 0} {$i < [llength $bnames1]} {incr i} {
	if { [lindex $bnames1 $i] != "Null" } {
	    checkbutton $wname.center.$i -text [lindex $bnames1 $i] \
		-variable [lindex $vnames1 $i] \
		-offvalue "No" -onvalue "Yes" -anchor w
	} else {
	    label $wname.center.$i -text "    " -anchor w
	}
	pack $wname.center.$i -side top -anchor w -padx 1m -pady 1m
    }

    if { $mode == "twocolumn" } {
	frame $wname.right 	-relief raised -width 1.5c
	pack $wname.right -side left -fill both -padx 1m -pady 1m 

	for {set i 0} {$i < [llength $bnames2]} {incr i} {
	    if { [lindex $bnames2 $i] != "Null" } {
		checkbutton $wname.right.$i -text [lindex $bnames2 $i] \
		    -variable [lindex $vnames2 $i] \
		    -offvalue "No" -onvalue "Yes" -anchor w
	    } else {
		label $wname.right.$i -text "       " -anchor w
	    }
	    pack $wname.right.$i -side right -expand 1 \
		-fill both -padx 1m -pady 1m -anchor w
	}
    }

    pack $wname -side top -padx 1m -pady 1m -expand 1 -fill both
}


#--------------------------------------------------------------------------
# wl_panelsShowShowSave w gname tmpname
#
# Wrap around wl_panelsCheckRadio
#--------------------------------------------------------------------------

proc wl_panelsShowShowSave {w gname tmpname mode} {

    global applicationName $tmpname


    set name  [ wl_${gname}Get name ]
    set nlist [ wl_${gname}Get displayTypes ]

    foreach i $nlist { lappend tlist "$tmpname\($i\)" }

    if {$nlist == ""} { set nlist "Null"; set tlist " " }

    # No sense in saving original data, so skip Images
    #
    if {$gname == "Image"} {
	wl_panelsCheckRadio $w $name $nlist $tlist \
	    "Null" "" $mode
    } else {
	wl_panelsCheckRadio $w $name $nlist $tlist \
	    "save" "$tmpname\(save\)" $mode
    }
}


#-------------------------------------------------------------------------
# wl_panelsEntry w msg vname 
#
# Creates a subwindow inside frame $w.
# The subwindow shows message $msg and an entry box. The entry box is
# associated with global variable $vname. 
#-------------------------------------------------------------------------
proc wl_panelsEntry { w msg vname } {

    set wname $w.${vname}

    frame $wname -relief groove -bd 3
    pack $wname -side top -fill x

    label $wname.label -text $msg 

    pack $wname.label  -side left -fill y   
    entry $wname.entry -width 8 -relief sunken -bd 2 \
        -textvariable $vname -insertbackground green
    pack $wname.entry -side right -fill both -expand 1
}


#--------------------------------------------------------------------------
# wl_PanelsGetVars w title ivalues msgs
#
# Display a panel with entry boxes to request values for n variables.
# Arguments:
#     w            parent window id
#     title        main title
#     ivalues      list containing initial values for the n variables
#     msgs         list of messages for each data
# Returns:
#     list with n updated values
#--------------------------------------------------------------------------

proc wl_PanelsGetVars {tmpw title ivalues msgs} {

    global applicationName wlPanel


    frame $tmpw.frame -relief flat
    pack  $tmpw.frame -side top -fill x

    label $tmpw.frame.label -text $title  
    pack  $tmpw.frame.label -side top -fill x

    for {set i 0} {$i < [llength $ivalues]} {incr i} {

	# create temporary global variables
	global wltmp$i
	# initialize
	set wltmp$i [lindex $ivalues $i]

	frame $tmpw.frame.$i -relief flat
	wl_panelsEntry $tmpw.frame.$i [lindex $msgs $i] wltmp$i
	pack $tmpw.frame.$i -side top -fill x
    }
      
    frame $tmpw.frame.buttons -relief flat
    pack $tmpw.frame.buttons -side top -fill x

    button $tmpw.frame.buttons.ok -text "O.k." \
	-command { set wlPanel(action) "O.k." }
    pack $tmpw.frame.buttons.ok -side left
    button $tmpw.frame.buttons.cancel -text "Cancel" \
    	-command {set wlPanel(action) "Cancel" }
    pack $tmpw.frame.buttons.cancel -side right

    bind $tmpw <Destroy> { set wlPanel(action) "Cancel" }
    
    tkwait variable wlPanel(action)

    if { $wlPanel(action) == "Cancel" } {
	return "Cancel"
    }
    
    # organize list of new values
    for {set i 0} {$i < [llength $ivalues]} {incr i} {
	lappend result [ set wltmp$i ]
	unset wltmp$i
    }	

    return $result
}


#-------------------------------------------------------------------------
# proc wl_PanelsBasic w title gvar
#
# Displays a subwindows inside window $w.
# The subwindow shows message $title above a global variable $gvar
#-------------------------------------------------------------------------

proc wl_PanelsBasic {w title gvar} {

    frame $w.${gvar} -width 4c -height 1.7c -width 1.7c -relief ridge\
	-borderwidth 3 
    pack $w.${gvar} -side left -fill y
    label $w.${gvar}.label -text $title 
    label $w.${gvar}.entry -width 7 -relief sunken -bd 2 \
        -textvariable $gvar 
    pack $w.${gvar}.label \
	$w.${gvar}.entry -side top -fill x
}


#-------------------------------------------------------------------------
# proc wl_PanelAnimatedFrame bwin title msg names vars
#
# Creates and displays a window named $bwin and the n global variables 
# specified in list $vars below the names given in list $names
#-------------------------------------------------------------------------

proc wl_PanelAnimatedFrame {bwin title msg names vars} \
{
    global applicationName wlPanel 

    global wl_tmpwin; set wl_tmpwin $bwin

    if {[ winfo exist $bwin ]} {destroy $bwin}

    # intitalize action
    set wlPanel(action) "Null"

    toplevel $bwin 

    if {[info exist wlPanel(smallWinGeometry)]} {

	wm geometry $bwin $wlPanel(smallWinGeometry)

    } else {

	wm geometry $bwin +910+700	

    }
    wm title $bwin $title
    frame $bwin.top -relief raised -bd 2 
    pack $bwin.top -side top -fill x
    
    message $bwin.top.m1 -text $msg \
	-width 7c 
    pack $bwin.top.m1 -side top
    

    frame $bwin.mid -relief sunken -bd 4 -height 1.7c -borderwidth 3 
    
    pack $bwin.mid -side top -fill y -padx 4 -pady 4
    
    # subpanels

    for {set cntr 0} {$cntr < [llength $names]} {incr cntr} {

	wl_PanelsBasic  $bwin.mid  \
	    [lindex $names $cntr] \
	    [lindex $vars $cntr]
    }

    # action area

    frame $bwin.bottom -relief sunken -bd 4 
    
    pack $bwin.bottom -side top -fill y -padx 4 -pady 4


    button $bwin.bottom.b2 -text "Abort" \
    	-command { set wlPanel(action) "Abort"; \
		       destroy $wl_tmpwin; unset wl_tmpwin}
    pack $bwin.bottom.b2 -side right
    
}

#-------------------------------------------------------------------------
# proc wl_PanelsUpdateAnimatedMsg win msg
#
# Utility to update the message shown in the animated window
#-------------------------------------------------------------------------

proc  wl_PanelsUpdateAnimatedMsg {win msg} {

    if {[winfo exist $win]} {

	$win.top.m1 configure -text $msg

    }

}

#-------------------------------------------------------------------------
# proc wl_PanelsChkWin {wname}
#
# Utility to update the screen, and if wlPanel(action) is "Abort",
# destroy window $wname
#-------------------------------------------------------------------------
proc wl_PanelsChkWin {wname} {

    global applicationName wlPanel

    update

    if { $wlPanel(action) == "Abort" } {
	if {[winfo exist $wname]} {destroy $wname}
	return "Abort"
    }
}


#----------------------------------------------------------------
# proc wl_PanelsBasicEntry w title gvar
#
# Displays a subwindows inside window $w.
# The subwindow shows message $title above an entry box 
# associated with $gvar
#----------------------------------------------------------------

proc wl_PanelsBasicEntry {w title gvar} {

    frame $w.${gvar} -width 4c -height 1.7c -relief ridge\
	-borderwidth 3 
    pack $w.${gvar} -side left -fill y
    label $w.${gvar}.label -text $title 
    entry $w.${gvar}.entry -width 7 -relief sunken -bd 2 \
        -textvariable $gvar -insertbackground green 
    pack $w.${gvar}.label \
	$w.${gvar}.entry -side top -fill x

}



#----------------------------------------------------------------
# proc PanelsBasicEntry2 w title gvar
#
# Displays a subwindows inside window $w.
# The subwindow shows message $title left of an entry box 
# associated with $gvar
#----------------------------------------------------------------

proc PanelsBasicEntry2 {w title gvar} {

  frame $w.${gvar} -width 4c -height 1.7c 
  pack  $w.${gvar} -side top -fill x

  label $w.${gvar}.label -text $title -anchor w
  entry $w.${gvar}.entry -width 12 -relief sunken -bd 2 \
        -textvariable $gvar -insertbackground green -highlightthickness 1
  pack $w.${gvar}.entry $w.${gvar}.label -side right
}


#-------------------------------------------------------------------------
# proc wl_PanelEntryFrame bwin title msg names vars
#
# Creates and displays a window named $bwin and entries for n global variables 
# specified in list $vars below the names given in list $names
#-------------------------------------------------------------------------

proc wl_PanelEntryFrame {bwin title msg names vars} \
{
    global applicationName wlPanel 

    global wl_tmpwin; set wl_tmpwin $bwin

    if {[ winfo exist $bwin ]} {destroy $bwin}

    toplevel $bwin
    if {[info exist wlPanel(midWinGeometry)]} {

	wm geometry $bwin $wlPanel(midWinGeometry)

    } else {

	wm geometry $bwin +100+300

    }

    wm title $bwin $title
    
    frame $bwin.top -relief raised -bd 2 
    pack $bwin.top -side top -fill x
    
    message $bwin.top.m1 -text $msg \
	-width 7c 
    pack $bwin.top.m1 -side top
    

    frame $bwin.mid -relief sunken -bd 4 -height 1.7c -borderwidth 3 
    
    pack $bwin.mid -side top -fill y -padx 4 -pady 4
    
    # subpanels

    for {set cntr 0} {$cntr < [llength $names]} {incr cntr} {

	wl_PanelsBasicEntry  $bwin.mid  \
	    [lindex $names $cntr] \
	    [lindex $vars $cntr]
    }

    # action area

    frame $bwin.bottom -relief sunken -bd 4 
    
    pack $bwin.bottom -side top -fill y -padx 4 -pady 4

    button $bwin.bottom.b1 -text "Done" \
    	-command { set wlPanel(action) "Done"; \
		       destroy $wl_tmpwin; unset wl_tmpwin}
    pack $bwin.bottom.b1 -side left

    button $bwin.bottom.b2 -text "Abort" \
    	-command { set wlPanel(action) "Abort"; \
		       destroy $wl_tmpwin; unset wl_tmpwin}
    pack $bwin.bottom.b2 -side right

    tkwait variable wlPanel(action)

    return $wlPanel(action)
}




#------------------------------------------------------------------------------
# proc wl_PanelsWait topwin message
#
# Puts up wait panel with message using $topwin as the name of the top 
# window 
#------------------------------------------------------------------------------

proc wl_PanelsWait { topwin message {geom 0} {width 7c} } {

  global applicationName wlPanel


  if { [winfo exists $topwin] } { destroy $topwin }
    
  toplevel $topwin
 
  if { $geom == 0 } {
    if {[info exist wlPanel(smallWinGeometry)]} {
      wm geometry $topwin $wlPanel(smallWinGeometry)
    }
  } else {
    wm geometry $topwin $geom
  }

  wm title $topwin "$applicationName"
    
  frame $topwin.frame -relief flat 
  pack $topwin.frame -side top
    
  label $topwin.frame.info -bitmap hourglass
  pack $topwin.frame.info -side left -pady 4m -padx 4m
  wl_PanelsBlink $topwin.frame.info 
    
  message $topwin.frame.mess -text $message -width $width
  pack $topwin.frame.mess -side left
}


#------------------------------------------------------------------------------
# proc wl_PanelsWarn message
#
# Puts up a warning panel with message and a button.
#------------------------------------------------------------------------------

proc wl_PanelsWarn { message {geom 0} {width 7c} } {

  global wlPanel
  
  
  if { [winfo exist .warning] } { destroy .warning }

  toplevel .warning 
  if { $geom == 0 } {
    wm geometry .warning +252+32
  } else {
    wm geometry .warning $geom
  }
    
  frame .warning.frame -relief flat
  pack .warning.frame -side top
    
  label .warning.frame.info -bitmap warning
  pack .warning.frame.info -side left -pady 4m -padx 4m
    
  message .warning.frame.mess -text $message -width $width
  pack .warning.frame.mess -side left

  button .warning.button -text "  OK  " -command {destroy .warning}
  pack .warning.button -side bottom -pady 2m
  bind .warning <Key-Return> { destroy .warning }
    
  tkwait window .warning
}


#------------------------------------------------------------------------------
# proc wl_PanelsWarnNoWait message
#
# Puts up a warning panel with message and a button. Exits without
# waiting for the user to press the button.
#------------------------------------------------------------------------------

proc wl_PanelsWarnNoWait message \
{
    if { [winfo exist .warning] } { destroy .warning }

    toplevel .warning 
    if {[info exist wlPanel(smallWinGeometry)]} {

	wm geometry .warning $wlPanel(smallWinGeometry)

    } else {
	
	wm geometry .warning +810+550
    }
    
    frame .warning.frame -relief flat
    pack .warning.frame -side top
    
    label .warning.frame.info -bitmap warning
    pack .warning.frame.info -side left -pady 4m -padx 4m
    
    message .warning.frame.mess -text $message -width 7c 
    pack .warning.frame.mess -side left

    button .warning.button -text "  OK  " -command {destroy .warning}
    pack .warning.button -side bottom -pady 2m
    bind .warning <Key-Return> { destroy .warning }
}


#--------------------------------------------------------------------------
#
#  PanelsGenericFrame wname title prc args buts
#
#  Generic frame template. Creates a top window named "wname"
#  titled "title" with three frames.
#
#  Procedure "prc" specifies a procedure that will be called to fill
#  the top frame. The frame name will be passed as a first argument
#  to "prc". List "args" will be the second argument.
#
#  List "buts" contains any number of button names/commands pairs. One
#  button will be created for each pair. Buttons will be arranged
#  horizontally in the bottom frame.
#
#--------------------------------------------------------------------------

proc PanelsGenericFrame { wname title prc args buts } {

  global applicationName wl wlPanel


  if { [ winfo exist $wname ] } { destroy $wname }
  toplevel $wname 
  wm title $wname $title

  if {[info exist wlPanel(midWinGeometry)]} {
    wm geometry $wname $wlPanel(midWinGeometry)
  } 

  frame $wname.topf
  pack $wname.topf -side top -padx 2m -pady 5 -fill both
  $prc $wname.topf $args

  frame $wname.botf
  pack $wname.botf -side top -padx 2m -pady 5 -fill both

  for {set indx 0} {$indx < [llength $buts]} {incr indx 2} {
    button $wname.botf.b$indx -command [lindex $buts [expr $indx + 1]] \
	-text [lindex $buts $indx ]

    pack $wname.botf.b$indx -side left -padx 5m -pady 5 -expand 1
  }
}


#--------------------------------------------------------------------------
# proc wl_panelsCleanPath { ipath } {
#
# Remove trailing double-dots from path
#--------------------------------------------------------------------------

proc wl_panelsCleanPath { ipath } {

  global platform


  if {$platform == "windows"} {
    if {[string match "?://.." $ipath] || [string match "?:/.." $ipath]} {
      set ipath [string range $ipath 0 2]
      return
    }
    if {[string match "*.." $ipath]} {
      regsub -all "/" $ipath " " tmplist
      set newlist [lrange $tmplist 0 [expr [llength $tmplist] - 3]]
      regsub -all " " $newlist "/" ipath 
    }
    if {[string match "?:" $ipath]} {
      set ipath "$ipath/"
    }
  } else {
    if {[string match "*.." $ipath]} {

      # replace / with empty space
      regsub -all "/" $ipath " " tmplist
      set newlist [lrange $tmplist 0 [expr [llength $tmplist] - 3]]
      regsub -all " " $newlist "/" ipath 
      
      # deal properly with root dir
      if {$ipath == ""} { set ipath "/" }

      if {[string match "//*" $ipath]} {
	set ipath [string range $ipath 1 end]
      }
    }
  }
  return $ipath
}



#--------------------------------------------------------------------------
# proc wl_panelsFileListAppend
#
# Appends the current file selection to the existing one.
# Uses by FS when getting a list of file names. 
#--------------------------------------------------------------------------

proc wl_panelsFileListAppend { } {
    
  global applicationName wlPanel


  if {[ info exist wlPanel(FileListFlg) ]} {
    foreach i [selection get] {
      if { [string last ":/" $i] != -1 } {
	set wlPanel(filesel) $i
      } elseif { [lsearch -exact $wlPanel(filesel) $i] < 0 } {
	lappend wlPanel(filesel) $i
      }
    }
  } else {
    set wlPanel(filesel) [selection get]
  }

  wl_panelsUpdateFs
}


#--------------------------------------------------------------------------
# proc wl_panelsCreateFsListboxes
#
# Creates the list boxes for the file/directory selector.
#--------------------------------------------------------------------------

proc wl_panelsCreateFsListboxes { win } {

  global applicationName wlPanel


  # create left frame for directories
  frame $win.lframe 
  pack  $win.lframe -side left 

  # create right frame for files
  frame $win.rframe 
  pack  $win.rframe -side left 

  # label frames and create directory and file listboxes
  label $win.lframe.label -text "Directories"
  pack  $win.lframe.label -fill x

  label $win.rframe.label -text "Files"
  pack  $win.rframe.label -fill x

  listbox $win.lframe.lbox -yscrollcommand "$win.lframe.scroll set" 
  pack    $win.lframe.lbox -side left

  scrollbar $win.lframe.scroll -command "$win.lframe.lbox yview"
  pack      $win.lframe.scroll -side left -fill y

  $win.lframe.lbox configure -selectmode single
  bind $win.lframe.lbox <ButtonRelease-1> {
    set sel [selection get]
    if { [string match "?:/" $sel] } {
      set wlPanel(dirsel) $sel
    } else {
      if { [string match "?:/" $wlPanel(dirsel)] } {
	set wlPanel(dirsel) [ wl_panelsCleanPath $wlPanel(dirsel)$sel ]
      } else {
	set wlPanel(dirsel) [ wl_panelsCleanPath $wlPanel(dirsel)/$sel ]
      }
    }
    set wlPanel(filesel) " "
    wl_panelsUpdateFs
  }

  bind $win.lframe.lbox <Double-ButtonRelease-1> {
    set wlPanel(dirsel) \
	[ wl_panelsCleanPath $wlPanel(dirsel)/[selection get] ]
    set wlPanel(filesel) " "
    wl_panelsUpdateFs
    set wlPanel(action) "O.k."
  }

  listbox $win.rframe.lbox -yscrollcommand [list $win.rframe.scroll set]
  pack    $win.rframe.lbox -side left

  scrollbar $win.rframe.scroll -command [list $win.rframe.lbox yview] 
  pack      $win.rframe.scroll -side left -fill y

  if {[ info exist wlPanel(FileListFlg) ]} {
    $win.rframe.lbox configure -selectmode extended
  } 	

  bind $win.rframe.lbox <ButtonRelease-1> { wl_panelsFileListAppend }

  bind $win.rframe.lbox <Double-ButtonRelease-1> { 
    wl_panelsFileListAppend 
    set wlPanel(action) "O.k."
  }

  if { ![file isdirectory $wlPanel(dirsel)] } {
    wl_PanelsWarnNoWait "Invalid directory $wlPanel(dirsel)! \
	Using actual path instead."
    set wlPanel(dirsel) [exec pwd]
  }

  set wlPanel(filesel) ""
  set wlPanel(FsWinId) $win
  wl_panelsUpdateFs
}


#--------------------------------------------------------------------------
# proc wl_panelsUpdateFs 
#
# Updates an active file/directory selector.
#--------------------------------------------------------------------------

proc wl_panelsUpdateFs { } {

  global applicationName wlPanel platform


  set win $wlPanel(FsWinId)

  $win.lframe.lbox delete 0 end
  $win.rframe.lbox delete 0 end

  if {$platform == "windows"} {
    set here [pwd]
    if [catch {cd $wlPanel(dirsel)}] {
      set wlPanel(dirList) $wlPanel(volumes)
      foreach i $wlPanel(dirList) {
	$win.lframe.lbox insert end $i
      }
      return
    } else {
      set wlPanel(dirList) [glob *]
      set wlPanel(dirList) [concat $wlPanel(dirList) $wlPanel(volumes)]
    }
    cd $here
    if { ! [string match "?:/" $wlPanel(dirsel)] } {
      $win.lframe.lbox insert end ".."
    }
  } else {
    # Make sure path is correct - else use actual
    #
    if { ![file isdirectory $wlPanel(dirsel)] } {
      set wlPanel(dirsel) [exec pwd]
    } else {
      set wlPanel(fsbIDir) $wlPanel(dirsel)
    }
    set wlPanel(dirList) [exec ls -a $wlPanel(dirsel)]
  }

  foreach i $wlPanel(dirList) {
    set test [file isdirectory $wlPanel(dirsel)/$i]
    if { $test } {
      if {$i != "." } {
	$win.lframe.lbox insert end $i
      }
    } elseif { [string last ":/" $i] != -1 } {
      $win.lframe.lbox insert end $i
    }

    set test [file isfile $wlPanel(dirsel)/$i]
    if { $test } {
      $win.rframe.lbox insert end $i
    }
  }
}


proc SelectEnd { w y dst } {
   global source_list dest_list

    $w select set anchor [$w nearest $y]
    foreach i [$w curselection] {
        set item [$w get $i]
           if [info exists source_list] {
	      # avoid multiple selections of the same item
              if { [lsearch -exact $source_list $item] < 0 } {
                $dst insert end $item
                lappend source_list $item
              } else {
                dialog "$item is already selected"
		continue
              }
           } else {
		# initialize source_list
                $dst insert end $item
                set source_list $item
           }
    }
}

proc rm_info { type } {
    
    global source_list source_dir Test_list Run_list platform

    set len [llength $source_list]
    
    if {$len > 1} {
	if ![string compare $type "Test"] {
	    set msg "Delete Tests: $source_list?"
	} else {
	    set msg "Delete Data Runs: $source_list?"
	}
    } else {
	if ![string compare $type "Test"] {
	    set msg "Delete Test: $source_list?"
	} else {
	    set msg "Delete Data Run: $source_list?"
	}
    }

    if ![string compare [wl_PanelsYesNo "$msg"] Yes] {
	update

	if { $type == "Test" } { 
	    foreach x $source_list {
		set Test_list [ldelete $Test_list $x]
		if ![ string compare $platform "windows" ] {
		   catch {file delete -force $source_dir/$x}
		} else {
		   exec rm -r $source_dir/$x
		}
	    }
	} else {
	    foreach x $source_list {
		set Run_list [ldelete $Run_list $x]
		if ![ string compare $platform "windows" ] {
		   catch {file delete -force $source_dir/$x}
		} else {
		   exec rm -r $source_dir/$x
		}
	    }
	    set fileid [open $source_dir/Run_list.tcl w]
	    puts $fileid "set Run_list {$Run_list}"
	    close $fileid
	}
    }
}

#
# proc DeleteEnd
#
# This procedure removes items from the right listbox
#
proc DeleteEnd { w y } {
   global source_dir source_list dest_list total_size 

   $w select set anchor [$w nearest $y]
   foreach i [lsort -decreasing [$w curselection]] {
	set item [$w get $i]
        $w delete $i
        set source_list [lreplace $source_list $i $i]
	if [info exists dest_list] {
	   set dest_list [lreplace $dest_list $i $i]
	}
   } 
}

#
# Tcl/Tk Directory Viewer
#
proc dir_browser { im_dir win } { 

  global wlPanel cb_labels

  if { [winfo exists .m] } { destroy .m }
  
  set title [ lindex [split $win .] 1 ]
  set title [ lindex [split $cb_labels($title)] 0 ]

  set current_dir [pwd]
  cd $im_dir

  # File menu
  toplevel .m
  wm title .m "Directory"
  wm geometry .m +320+193

  frame .m.menubar -bd 1 -relief raised

  # Place a label here, too.
  label .m.menubar.curdir -text "Dir"
  label .m.menubar.label -text "Current Directory"
  pack .m.menubar.label -side left
  pack .m.menubar.curdir -side right


  # Frame for everything under menubar.
  frame .m.main -bd 0
  frame .m.main.dir -bd 1
  frame .m.main.dir.text -bd 0
  label .m.main.dir.text.label -text "Directories"
  button .m.main.dir.text.up -text "Up" \
    -command go_up
  pack .m.main.dir.text.label -side left 
  pack .m.main.dir.text.up -side right
  frame .m.main.dir.f -bd 0
  listbox .m.main.dir.f.list -height 10 \
    -selectmode single \
    -yscrollcommand ".m.main.dir.f.scrb set"
  scrollbar .m.main.dir.f.scrb \
    -command ".m.main.dir.f.list yview"
  pack .m.main.dir.f.list .m.main.dir.f.scrb \
    -side left -fill y
  pack .m.main.dir.text -anchor w \
    -side top -fill x 
  pack .m.main.dir.f -side top


  # Frame for file names.
  frame .m.main.files -bd 0
  label .m.main.files.file -text "Files"
  frame .m.main.files.f
  listbox .m.main.files.f.file_list -height 10 \
    -selectmode single \
    -yscrollcommand ".m.main.files.f.scrb set"
  scrollbar .m.main.files.f.scrb \
    -command ".m.main.files.f.file_list"
  pack .m.main.files.f.file_list -side left
  pack .m.main.files.f.scrb -side right -fill y
  pack .m.main.files.file -pady 4 \
    -side top -fill x 
  pack .m.main.files.f -side top
  pack .m.main.dir .m.main.files -side left

  frame .m.entry -relief flat 

  label .m.entry.label -text "Save As:" -anchor w
  entry .m.entry.entry -width 40 -relief sunken -bd 2 \
    -textvariable text_save -insertbackground green \
    -highlightthickness 1
  pack .m.entry.entry .m.entry.label -side right

  # Buttons
  frame	.m.action -relief flat
  pack	.m.action .m.entry -side bottom -padx 1m -pady 1m

  button	.m.action.ok -text "OK" \
    -command { set wlPanel(action) "O.k." }
  button	.m.action.cancel -text "Cancel" \
    -command { destroy .m; set wlPanel(action) "Cancel" }
  pack	\
    .m.action.ok \
    .m.action.cancel \
    -side left -padx 1m -pady 1m -expand 1

  bind .m <Destroy> { set wlPanel(action) "Abort" }

  # Pack top-level widgets.

  pack .m.menubar -side top -fill x -expand true
  pack .m.main -side left


  # Change dir on double-click.
  bind .m.main.dir.f.list <Double-Button-1> {

    # Get selected list item
    set diritem [.m.main.dir.f.list curselection]

    set dir [.m.main.dir.f.list get $diritem]

    # Change directories
    cd $dir

    # Fill lists
    read_dir .m.main.dir.f.list .m.main.files.f.file_list 
  }

  bind .m.main.files.f.file_list <ButtonRelease-1> {
      set fileitem [.m.main.files.f.file_list curselection]
      set text_save [.m.main.files.f.file_list get $fileitem]
  }
  read_dir .m.main.dir.f.list .m.main.files.f.file_list 

  tkwait variable wlPanel(action)

  if { $wlPanel(action) == "O.k." } { 
    set im_dir [pwd]
    cd $current_dir
    set text_save [.m.entry.entry get]
    if { [winfo exists .m] } { destroy .m }
    if { $text_save == "" } {
      return "Cancel"
    } else {
      set wtext [$win get 1.0 end]
      set fileid [open $im_dir/$text_save w ]
      puts $fileid $wtext
      close $fileid
    }
    return "O.k."
  } else {
    set im_dir $current_dir
    cd $current_dir
    return "Cancel"
  }

}

# Fill lists with filenames

proc read_dir { dirlist filelist } {

  # Clear listboxes
  $dirlist delete 0 end
  $filelist delete 0 end
  
  set unsorted [glob -nocomplain *]

  if {$unsorted != "" } {

    set files [lsort $unsorted]

    # Separate out directories

    foreach filename $files {

      if { [file isdirectory $filename] != 0 } {
	# Is a directory.

	$dirlist insert end "$filename"
      } else {
	# Is a file.
	$filelist insert end "$filename"


      }
    }

  }

  # Now, store current dir in label.
  .m.menubar.curdir configure -text [pwd]
}

# Go up one directory.
proc go_up { } {

  # Go up one.
  cd ..

  # Read directory.
  read_dir .m.main.dir.f.list .m.main.files.f.file_list 	
}


#---------------------------------------------------------------------------
# proc PanelsCalError
#
# Show calibration error message and prompt the user
# Returns Continue or Abort if the window is destroyed
#---------------------------------------------------------------------------

proc PanelsCalError { msg helpText } {

  global applicationName wlPanel calHelpText


  set calHelpText $helpText

  if { [winfo exist .wce] } { destroy .wce }

  toplevel .wce 
  if {[info exist wlPanel(smallWinGeometry)]} {
    wm geometry .wce $wlPanel(smallWinGeometry)
  } 
  wm title .wce "$applicationName"

  frame .wce.frame1 -relief flat 
  pack  .wce.frame1 -side top
    
  label .wce.frame1.wce -bitmap question -relief raised 
  pack  .wce.frame1.wce -side left -pady 4m -padx 4m
    
  message .wce.frame1.mess -text $msg -width 12c
  pack    .wce.frame1.mess -side left

  frame .wce.frame2 -relief flat 
  pack  .wce.frame2 -side top
    
  button .wce.frame2.ybutton -text "  OK  " \
	-command { set wlPanel(action) Continue }
  pack .wce.frame2.ybutton -side left -padx 2m -pady 2m

  button .wce.frame2.nbutton -text Cancel \
	-command { set wlPanel(action) Abort }
  pack .wce.frame2.nbutton -side left -padx 2m -pady 2m
  
  button .wce.frame2.hbutton -text Help \
	-command { ShowMiniHelp $calHelpText }
  pack .wce.frame2.hbutton -side left -padx 2m -pady 2m
    
  bind .wce <Destroy> { set wlPanel(action) Abort }

  tkwait variable wlPanel(action)

  set answer $wlPanel(action)
  if { [winfo exist .wce] } { destroy .wce }
  set wlPanel(action) $answer

  return $answer
}
