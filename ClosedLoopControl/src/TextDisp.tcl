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
# FILE: TextDisp.tcl
# 
# DESCRIPTION:	
#   Generic text-display window procedures
# 
# $Id: TextDisp.tcl,v 1.19 1999/06/09 18:22:00 stacy Exp $
# 
#--------------------------------------------------------------------------


#--------------------------------------------------------------------------
# proc MakeTextPanel
#
# Generates a generic text display widget
# win is the window name
# exs and why are the window location
# wid is the text widget name to be used to write to the widget
#--------------------------------------------------------------------------
 
proc MakeTextPanel { win exs why txtw txth wid ptype } {

  global wsParam cb_labels textPanelWin
  upvar $wid t 

    
  if { [winfo exist $win] } { destroy $win }

  set textPanelWin $win

  set title [ lindex [split $win .] 1 ]
  if { $title == "msquared" } {
    set title "M Squared"
  } else  {
    set title [ lindex [split $cb_labels($title)] 0 ]
  }

  toplevel $win
  wm title $win $title
  wm minsize $win 20 5
  wm geometry $win +$exs+$why

  frame $win.framef
  pack $win.framef -side top -anchor w

  menubutton $win.framef.file -text "File" -menu $win.framef.file.menu \
    -borderwidth 2 -relief flat
  pack $win.framef.file -side left
  
  set file_menu $win.framef.file.menu
  menu $file_menu -tearoff 0
  $file_menu add command -label "Save" \
	-command "dir_browser /usr/home/wavescope $win.frame.t"
  $file_menu add command -label "Print" -command "PrintText $win.frame.t"
  $file_menu add separator
  $file_menu add command -label "Close" -command { destroy $textPanelWin }
  
  if { $win == ".zernikes" } { 
    menubutton	$win.framef.type -text "Type"   \
	    -menu $win.framef.type.menu -borderwidth 2 -relief flat
    pack $win.framef.type -side left

    set type_menu $win.framef.type.menu
    menu $type_menu -tearoff 0
    $type_menu add command -label "Zygo" -command { zern.set.type z }
    $type_menu add command -label "CodeV" -command { zern.set.type c }
    $type_menu add command -label "CodeVFringes" -command { zern.set.type f }
    $type_menu add command -label "OTA" \
	    -command { zern.set.type o $wsParam(ZernRatio) }
  }	

  frame $win.frame 
  pack $win.frame -side top -fill both -expand true
	
  set t [text $win.frame.t -setgrid true -wrap word -width $txtw -height $txth\
         -font -adobe-courier-medium-r-normal--14-140-75-75-m-90-iso8859-1 \
	 -state disabled -yscrollcommand "$win.frame.sy set" \
         -highlightthickness 0]
	
  scrollbar $win.frame.sy -orient vert -command "$win.frame.t yview" \
            -highlightthickness 0
  pack $win.frame.sy -side right -fill y

  pack $win.frame.t -side bottom -fill both -expand true      
    
 
  $t insert end ""
}


###############################################################################
#
# Prints text in widget wid
#
###############################################################################

proc PrintText { wid } \
{
  global platform

  set wtext [$wid get 1.0 end]
  if ![string compare $platform "windows"] {
    set fileid [open /temp/printtemp w ]
    puts $fileid $wtext
    close $fileid
    exec /usr/aos/wavescope/bin/print /temp/printtemp
  } else {
    set fileid [open /tmp/printtemp w ]
    puts $fileid $wtext
    close $fileid
    exec print /tmp/printtemp
  }
	
}
###############################################################################
#
# Clears text widget and inserts new text
#
###############################################################################

proc UpdateTextPanel { wid string fnum } \
{
    global ws_stat

    $wid configure -state normal
    $wid delete 1.0 end
    if { $wid != ".miniHelp.frame.t" } {
	if { $ws_stat(save_data) } {
	    set finfo "$fnum/$ws_stat(num_frames)"
	    $wid insert end "# $ws_stat(current_run) Frame $finfo\n"
	    $wid insert end "# $ws_stat(display_date)\n"
	} else {
	    $wid insert end "# $ws_stat(current_run)\n"
	    $wid insert end "# $ws_stat(display_date)\n"
	}
    }
    $wid insert end $string
    $wid configure -state disabled
	
}

###############################################################################
#
# Adds new text to end of text widget
#
###############################################################################

proc AddToTextPanel { wid c1 c2 string } \
{
    $wid configure -state normal
    $wid insert end "\n"
    $wid insert end "  $c1\t"
    $wid insert end "   $c2\t"
    $wid insert end "  $string\t"
    $wid configure -state disabled
}


##############################################################################
#
# String conversion for Monomial, Hermite, Chebychev, and Legendre
# coeficients to text widget format
#
##############################################################################

proc text_update  { wid coefile fnum } {
  global wlCalibrate ws_results

  set name [lindex [split $wid .] 1]

  if { $name == "zernikes" }  {
    zernikes_update $wid $coefile $fnum
  } elseif { $name == "seidels" } {
    seidels_update $wid $coefile $fnum
  } elseif { $name == "msquared" } { 
    set array_name [get_arrayname $name]
    UpdateTextPanel $wid "# $array_name" $fnum
    $wid configure -state normal
    $wid insert end "\n"
    $wid insert end "$ws_results($array_name)"
    $wid configure -state disabled    
  } else {
	set array_name [get_arrayname $name]
	if { $wlCalibrate(PupilShape) == "Rectangular" } {
	    # split the coefile into 4 sections so the indices can be integer
	    a.split $coefile = ind1 ind2 coefs
	    a.to ind1 i = ind1
	    a.to ind2 i = ind2
	    set clen [a.cols $coefs]
	    UpdateTextPanel $wid "# $array_name Coefficients\n\#\
            X-index  Y-index  Coefs.(microns)" $fnum
	    for { set i 0 } { $i < $clen } { incr i } \
		{
		    set coef [a.extele coefs $i]
		    set indx [a.extele ind1 $i]
		    set indy [a.extele ind2 $i]
		    AddToTextPanel $wid $indx $indy $coef 
		}
	} else { 
	    UpdateTextPanel $wid $coefile $fnum
	}
    }
}

###############################################################################
#
# Specific string conversion for Seidel coeficients to text widget format
#
###############################################################################

proc seidels_update { wid coefile fnum } \
{
    global wlCalibrate

    if { $wlCalibrate(PupilShape) == "Circular" } { 
	set seidelText\
	    "\# Seidel  Coefficients (microns)\n\n \
              [ format  "%f \t\# Tilt" [a.extele $coefile 0]] \n \
    	      [ format  "%f \t\# Tilt Angle" [a.extele $coefile 1]] \n \
	      [ format  "%f \t\# Focus" [a.extele $coefile 2]] \n \
	      [ format  "%f \t\# Astigmatism" [a.extele $coefile 3]] \n \
	      [ format  "%f \t\# Astigmatism Angle" [a.extele $coefile 4]] \n \
	      [ format  "%f \t\# Coma" [a.extele $coefile 5]] \n \
	      [ format  "%f \t\# Coma Angle" [a.extele $coefile 6]] \n \
	      [ format  "%f \t\# Spherical" [a.extele $coefile 7]] "
	UpdateTextPanel $wid $seidelText $fnum
    } else { 
	UpdateTextPanel $wid $coefile $fnum
    }
		
}

###############################################################################
#
# Specific string conversion for Zernikes coeficients to text widget format
#
###############################################################################

proc zernikes_update { wid coefile fnum } \
{
    global wlCalibrate
    global $coefile

    if { $wlCalibrate(PupilShape) == "Circular" } { 
        set zernstr [zern.conv.string $coefile]
        UpdateTextPanel $wid $zernstr $fnum
    } else { 
	UpdateTextPanel $wid $coefile $fnum
    }
 
}





