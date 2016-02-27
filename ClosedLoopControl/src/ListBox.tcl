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
# FILE: ListBox.tcl
# 
# DESCRIPTION:	
#   MLM selection and generic list box procedures
# 
# $Id: ListBox.tcl,v 1.18 1999/02/18 18:38:09 herb Exp $
# 
#--------------------------------------------------------------------------


#--------------------------------------------------------------------------
# proc SelectMLM
#
# Puts up a list box that allows the user to select an MLM.
#--------------------------------------------------------------------------

proc SelectMLM { } {

  global MLM_list ws_stat


  # Put up a list box that allows the user to select one of the defined
  # MLMs.  As a side effect of the selection, the global variable
  # $ws_stat(mlm) will be set.
  #
  set oldMLM $ws_stat(mlm)
  set ws_stat(mlm) ""
  set ok [ListBox .select_MLM $MLM_list "MLM Selected:" mlm +185+30]

  if { $ok } {
    if { $ws_stat(mlm) != "" } {
      set current $ws_stat(mlm) 
      ws_GetMLMSpec
      Stage_Positions
    }
    return "ok"
  } else {
    set ws_stat(mlm) $oldMLM
    return "cancel"
  }
}


#--------------------------------------------------------------------------
# proc AddMLM
# 
# Puts up a box with instructions for inputting the name of an MLM.
# Checks that the input name is valid, and if so, adds it to the list
# of MLMs and saves it.  If not, an error dialog pops up.
#--------------------------------------------------------------------------

proc AddMLM { } {

  global MLM_list LISTS_DIR


  # Prompt the user to enter the name of the new MLM.
  #
  set msg "Enter New MLM Name:\n(mmmm_S_fff)"
  set newMLM [enter_val $msg newMLM 12 "Add MLM" +150+38]
  if {$newMLM == ""} {return}

  # Look over the name the user entered, and see if it's in a legal
  # format.  It needs to be a number (micrometers, up to 4 digits),
  # an underscore, a capital S or H, another underscore, and another
  # number (focal length, up to 3 digits).
  #
  set err 0
  set num [scan $newMLM {%d%3s%d} mm chr fl]
  if {$num !=3} {
    set err 1
  } else {
    if {$chr != "_S_" && $chr != "_H_"} {set err 1}
    if {[expr $mm < 1] || [expr $mm > 9999]} {set err 1}
    if {[expr $fl < 1] || [expr $fl > 999]} {set err 1}
  }

  if {$err == 0} {
    # Format looks OK, format the MLM name, update and save the list.
    #
    set newName [format {%04d%3s%03d} $mm $chr $fl]
    set MLM_list [concat $MLM_list $newName]
    set fileid [open $LISTS_DIR/MLM_list.tcl w]
    puts $fileid "set MLM_list {$MLM_list}"
    close $fileid
  } else {
    # Something's not quite right.  Pop up a dialog box.
    #
    set msg "The MLM name entered is not legal.
The name must be between
0001_S_001 and 9999_S_999."
    wl_PanelsWarn $msg +150+38 12c
    AddMLM
  }
}


# ****************************************************************************
#
#  proc delete_MLM {}
#  Puts up list box of MLM names from MLM_list.  User chooses an MLM
#  to delete and is queried - are they sure they want to delete -
#  If yes, MLM is removed from MLM_list.
#  
# ****************************************************************************
proc delete_MLM { } {

    global MLM_list ws_stat LISTS_DIR

    set ws_stat(delete_MLM) ""

    set User_MLM $MLM_list
    set ok [ListBox .delete_MLM $User_MLM "Delete MLM: " delete_MLM +100+30]

    if { $ok } {
	if { $ws_stat(delete_MLM) == "" } {
	    dialog "No test selected"
	} else {
	    set msg "Delete MLM '$ws_stat(delete_MLM)'?"
	    set ans [wl_PanelsYesNo $msg]
	    if { ![string compare $ans "Yes"] } {
		set MLM_list [ldelete $MLM_list $ws_stat(delete_MLM)]
		set fileid [open $LISTS_DIR/MLM_list.tcl w]
		puts $fileid "set MLM_list {$MLM_list}"
		close $fileid
	    } 
	}
    } 
}


#--------------------------------------------------------------------------
# proc VerifyMLM
#
# Displays the currently selected MLM and the choice to continue or cancel.
#--------------------------------------------------------------------------

proc VerifyMLM { } {

  global ws_stat

    
  if { $ws_stat(mlm) != "" } { 
    set msg "The current MLM is $ws_stat(mlm)"
    if { [ wl_PanelsContinueAbort $msg +200+32 ] == "Abort"} {
      return "Abort"
    }
  }
}


#--------------------------------------------------------------------------
# proc ListBox
#
# ListBox may be called with either two or four arguments.  Pass two
# arguments to simply display a list and return the selected string.  Pass
# four arguments when you need to set a variable in the ws_stat array, this
# also displays a list, but returns 1 or 0.
#
# The fifth argument is optional arbitrary geometry, and it obviously can't
# be used unless the optional 3rd and 4th arguments are used (which is
# usually the case anyway).
#--------------------------------------------------------------------------

proc ListBox { win ListSel {Lbl NO_LBL} {ind NO_IND} {geom 0} } {

  global ws_stat bprompt return_string


  if { [winfo exist $win] } { destroy $win }
  set f [toplevel $win]

  if { $geom == 0 } {
    wm geometry $win +200+80
  } else {
    wm geometry $win $geom
  }
  ListSelect $win.lbox $ListSel $ind 
  pack $win.lbox -expand true -fill both
    

  # Check to see if the 4th parameter is present.  Although we never
  # actually check the 3rd parameter, if the 4th isn't there, the 3rd
  # is simply ignored.
  #
  if [string compare $ind "NO_IND"] {
    set sfrm [frame $win.sfrm]
    pack $sfrm -side bottom -fill x -anchor w
    label $sfrm.lbl -text $Lbl
    label $sfrm.mlm -textvariable ws_stat($ind)
    pack $sfrm.lbl $sfrm.mlm -side left -anchor w
  }

  set bfrm [frame $win.bfrm -bd 10]

  pack $bfrm -side bottom -fill x
  button $bfrm.ok -text "  OK  " -command { set bprompt(ok) 1 }
  button $bfrm.cancel -text Cancel -command { set bprompt(ok) 0 }
  pack $bfrm.ok -side left
  pack $bfrm.cancel -side right

  bind $win <Return> {set bprompt(ok) 1} 
  bind $win <Control-c> {set bprompt(ok) 0}

  grab $f
  tkwait variable bprompt(ok)
  grab release $f
  destroy $f

  switch $ind {
    NO_IND { 
      if {$bprompt(ok)} {
	return $return_string
      } else {
	return ""
      }
    }
    default {
      return $bprompt(ok)
    }
  }
}


# ****************************************************************************
#
#  proc ScrolledListbox { parent args }
#
# ****************************************************************************

proc ScrolledListbox { parent args } {
    # Create listbox attached to scrollbars, pass thru $args
    frame $parent
    eval { listbox $parent.list \
	       -yscrollcommand [list $parent.sy set]} $args
    # Create scrollbars attached to the listbox
    scrollbar $parent.sy -orient vertical \
	-command [list $parent.list yview]
    # Arrange them in the parent frame
    pack $parent.sy -side right -fill y
    # Pack to allow for resizing
    pack $parent.list -side left -fill both -expand true
    return $parent.list
}

# ****************************************************************************
#
#  proc ListSelect { parent choices var }
#
# ****************************************************************************

proc ListSelect { parent choices ind } {

    # Create listbox
    frame $parent
    ScrolledListbox $parent.choices -width 20 -height 5 \
	-setgrid true

    # The setgrid allows interactive resizing, so the
    # pack parameters need expand and fill.
    pack $parent.choices -side left \
	-expand true -fill both

    # Selecting in choices moves items into picked
    bind $parent.choices.list <ButtonPress-1> \
	{ ListSelectStart %W %y }    
    bind $parent.choices.list <B1-Motion> \
	{ ListSelectExtend %W %y }
    bind $parent.choices.list <ButtonRelease-1> \
	[list ListSelectEnd %W %y $parent.picked.list $ind] 

    # Insert all the choices
    eval { $parent.choices.list insert 0 } $choices
}

proc ListSelectStart { w y } {
    $w select anchor [$w nearest $y]
}

proc ListSelectExtend { w y } {
    $w select set anchor [$w nearest $y]
}

proc ListSelectEnd { src y dst ind } {
    global ws_stat return_string

    $src select set anchor [$src nearest $y]
    set option [$src curselection]
    if { [llength $option] > 1 } {
	dialog "Please select only one option"
    } else {
	if ![string compare $ind "NO_IND"] {
	   set return_string [$src get [$src curselection]]
	} else {
	   set ws_stat($ind) [$src get [$src curselection]]
	}
    }
}

proc ldelete { list value } {
    set ix [lsearch -exact $list $value]
    if {$ix >=0} {
	return [lreplace $list $ix $ix]
    } else {
	return $list
    }
}

