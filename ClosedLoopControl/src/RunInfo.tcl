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
# FILE: RunInfo.tcl
# 
# DESCRIPTION:	
#    Panel for entering and displaying text window file header values. 
# 
# $Id: RunInfo.tcl,v 1.9 1999/02/11 16:42:28 herb Exp $
# 
#--------------------------------------------------------------------------


#--------------------------------------------------------------------------
#
#--------------------------------------------------------------------------

proc RunInfo { win dummy } {
    global wsRunInfo platform

    set wsRunInfo(user_name) ""
    if { $platform == "windows" } {
	set ttt [clock seconds]
	set d [clock format $ttt -format %c]
    } else {
	set d [exec date]
    }
    set wsRunInfo(date) $d
    set wsRunInfo(run_name) ""

    frame $win.frame
    pack $win.frame -fill x -side top
    menubutton $win.frame.print -text "Print" -width 7 \
	-menu $win.frame.print.menu -borderwidth 2 -relief raised
    pack $win.frame.print -side left
    set pmenu $win.frame.print.menu
    menu $pmenu -tearoff 0 
    $pmenu add command -label "Print" \
	-command "PrintRunInfo $win.frm.txt"
    $pmenu add separator
    $pmenu add command -label "Cancel" \
	-command { return "Abort" } 

    foreach i { run_name user_name date } {
	lappend ivalues "wsRunInfo($i)" 
    }
    
    set msgs { " Run:" "User:" "Date:" }

    for {set i 0} {$i < [llength $ivalues]} {incr i} {

	HeaderEntry $win [lindex $msgs $i] [lindex $ivalues $i]

    }

    set f [frame $win.frm]
    pack $win.frm -side top -fill both -expand true
    set t [text $f.txt -setgrid true \
	       -width 44 -height 15 \
	       -background white -foreground black \
	       -yscrollcommand "$f.sy set"]
    scrollbar $f.sy -orient vert -command "$f.t yview"
    pack $f.sy -side right -fill y
    pack $t -side left -fill both -expand true
}


#--------------------------------------------------------------------------
# proc HeaderEntry
#
# Displays a text entry with label inside window $w.
# The subwindow shows message $title left of an entry box 
# associated with $gvar
#--------------------------------------------------------------------------

proc HeaderEntry {w title gvar} {

  frame $w.${gvar} -width 4c -height 1.7c
  pack  $w.${gvar} -side top -fill x -pady 3

  label $w.${gvar}.label -text $title -anchor w

  entry $w.${gvar}.entry -width 30 -relief sunken -highlightthickness 1 \
        -textvariable $gvar -insertbackground green

  pack $w.${gvar}.label $w.${gvar}.entry -side left 
}


#--------------------------------------------------------------------------
# proc prompt_user
#
# Popup dialog that prompts user for Run Information - 
# user_name and run_name.  Used when text_entry window not 
# chosen for test displays.
#--------------------------------------------------------------------------

proc prompt_user { msg } {

  global wsRunInfo wlPanel platform


  if { $platform == "windows" } {
    set ttt [clock seconds]
    set d [clock format $ttt -format %c]
  } else {
    set d [exec date]
  }
  set wsRunInfo(date) $d

  if { [winfo exist .user_prompt] } { destroy .user_prompt }
  toplevel .user_prompt
  wm geometry .user_prompt +350+32
  wm title .user_prompt "Run Information"
  set win .user_prompt
    
  frame $win.frame -bd 3
  pack $win.frame -fill x -side top

  label $win.frame.lbl -text $msg
  pack $win.frame.lbl -side left

  foreach i { run_name user_name date } {
    lappend ivalues "wsRunInfo($i)" 
  }
    
  set msgs { " Run:" "User:" "Date:" }

  for {set i 0} {$i < [llength $ivalues]} {incr i} {
    HeaderEntry $win [lindex $msgs $i] [lindex $ivalues $i]
  }

  frame $win.frame2 -relief flat 
  pack $win.frame2 -side top
    
  button $win.frame2.ybutton -text "  OK  " \
	-command { set wlPanel(action) Continue }
  button $win.frame2.nbutton -text Cancel \
	-command { set wlPanel(action) Abort }
  pack $win.frame2.ybutton $win.frame2.nbutton -side left -padx 20 -pady 10
    
  bind $win <Destroy> { set wlPanel(action) Abort }

  tkwait variable wlPanel(action)

  set answer $wlPanel(action)

  if { [winfo exist $win] } { destroy $win }
    
  set wlPanel(action) $answer
  return $answer
}


#----------------------------------------------------------------
# proc PrintRunInfo { test_wid }
#
# Prints header information and comment in text window
# 
# 
#----------------------------------------------------------------

proc PrintRunInfo { text_wid } {

    global wsRunInfo

    set msgs { " Run:" "User:" "Date:" }

    foreach i { run_name user_name date } {
	lappend ivalues "$wsRunInfo($i)" 
    }
    

    set fileid [open /tmp/printtemp w ]

    for {set i 0} {$i < [llength $ivalues]} {incr i} {

	puts $fileid "[lindex $msgs $i] [lindex $ivalues $i]"

    }

    puts $fileid "     "
    set wtext [$text_wid get 1.0 end]
    puts $fileid $wtext
    close $fileid
    exec print /tmp/printtemp
}




