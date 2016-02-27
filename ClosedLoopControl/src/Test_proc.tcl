#==========================================================================
# 
# 			Adaptive Optics Associates
# 			      10 Wilson Road
# 			    Cambridge, MA 02138
# 				    USA
# 			   (Phone) 617-864-0201
# 			    (Fax) 617-864-1348
# 
#                Copyright 2000 Adaptive Optics Associates
# 			    All Rights Reserved
# 
#==========================================================================
# 
# FILE: Test_proc.tcl
# 
# DESCRIPTION:	
#   
# 
# $Id: Test_proc.tcl,v 1.86 2000/09/01 17:55:46 herb Exp $
# 
#==========================================================================


#--------------------------------------------------------------------------
# proc new_test
#
# Takes down all panels related to an open test, then puts up the new
# test selection panel.
#--------------------------------------------------------------------------

proc new_test {} {

  global ws_stat Test_list RunInfo platform
  global Disp_types Spec_types Text_types
  global Test_Options SlSt wlPanel


  foreach id $Disp_types {
    global $id
  }

  # Take down control panels for Live Display and Replay
  #
  if {[winfo exists .dtl]} { destroy .dtl }
  if {[winfo exists .rp]} { destroy .rp }

  # Remove all windows related to an open test.
  #
  set ws_stat(new_test) True
  set ws_stat(current_test) ""
  foreach item $Disp_types {
    set dlist [get_dlist $item]
    set dtype [lindex $dlist 0]

    if { ![catch {$dtype.sync $item}] } {
      unset $item
    }
  }
    
  # Spec_type beam_profile
  #
  foreach type {id pd} {
    if { ![catch {${type}.sync SlSt($type)}] } {
      unset SlSt($type)
    }
  }

  foreach item $Text_types {
    if { [winfo exists .$item] } {
      destroy .$item
    }
  }

  # Put up the Test Display Selection box
  #
  if { [TestSelect] != "Abort" } { 
    if { $Test_Options(DC) == 0 } { 
      put_new_disps

      if { $platform != "windows" } { 
	foreach item $Disp_types {
	  if { $Test_Options($item) == 1 } {
	    set dlist [get_dlist $item]
	    set dtype [lindex $dlist 0]
	    set def_w [lindex $dlist 1]
	    set def_h [lindex $dlist 2]
	    while { 1 } { 
	      $dtype.get.wh $item = w h
	      if { $w == $def_w && $h == $def_h } { 
		break
	      }
	    }
	  }
	}
      }

      update

      wl_PanelsMsg "Use the mouse to place and resize the display\
windows as desired.  Save the Test before Executing." +252+32
    }
  }
}


#--------------------------------------------------------------------------
# proc get_testname
#
# Checks 'name' to see if a test by that name already exists.
# If so, the user is prompted to enter a different name.
# If 'name' doesn't exist, it is added to Test_list.
# Returns a 1 on success.  If there is whitespace in the name, curly
# brackets are placed around the name to retain the whitespace.
#--------------------------------------------------------------------------

proc get_testname { name } {

  global Test_list LISTS_DIR


  set ix  [lsearch -exact $Test_list $name]
  set res [string first " " $name]

  if {$res > -1} {
    set name "{$name}"
  }

  if {$ix >= 0} { 
    wl_PanelsWarn "Test name '$name' exists. Choose another name or delete the existing test."
    return "0"
  } else {
    set Test_list [concat $Test_list $name]
    return "1"
  }
}


#--------------------------------------------------------------------------
# proc save_test
#
# Modified to do nothing when called with "Auto" parameter.  For use in 
# auto_run_test_function.
# hdyson 24th Nov 03
#
# If a new test is open, the user is prompted for the name of the new
# test, and all relevant data and display options are saved, and
# ws_stat(new_test) is set to False.
# If $exec is True, then run_test is called.
# If $exec is Open, then open_test is called.
#
# If a new test is not open, then get_test is called to save the current
# state of the test.
#--------------------------------------------------------------------------

proc save_test { exec } {

  global ws_stat

  # Prompt the user for a new test name
  #    
  if { ![string compare $ws_stat(new_test) "True"] } {
    set aok 0
    while { $aok == 0 } {
      set new_testname [enter_val "Enter New Test Name:" new_test 20 "New Test"]
      if { ![string compare $new_testname ""] } {
	return {}
      }
      set aok [get_testname $new_testname]
    }

    set ws_stat(current_test) $new_testname
    set ws_stat(new_test) False
	
    # Save the test display information
    #
    get_test

    if { ![string compare $exec "True"] } {
      run_test
    }
    if { ![string compare $exec "Open"] } {
      open_test
    }
    if { ![string compare $exec "Auto"] } {
    }
    set_test_list

  } else {

    # If a new test is not open, then save the current test status.
    #
    get_test
  }
}


#--------------------------------------------------------------------------
# proc open_test
#
# Puts up a list box of test names from Test_list.  The user chooses a test
# and current_test is set to the users choice.
#--------------------------------------------------------------------------

proc open_test { } {

  global Test_list ws_stat wsRunInfo


  # Destroy the control panel for replay displays
  #
  if {[winfo exists .rp]} { destroy .rp }

  foreach item {user_name date run_name} {
    set wsRunInfo($item) ""
  }

  if { ![string compare $ws_stat(new_test) "True"] } {
    set msg "Would you like to save new test first?"
    set ans [wl_PanelsYesNo $msg]

    if { ![string compare $ans "Yes"] } {
      save_test Open
      return
    } else {
      set ws_stat(new_test) "False"
    }
  }

  set oldTest $ws_stat(current_test)
  set ws_stat(current_test) ""
  set ok [ListBox .open_test $Test_list "Test Selected: " current_test +10+55]

  if { $ok } {
    if { $ws_stat(current_test) == "" } {
      dialog "No test was selected"
    } else {
      if {[info exists ws_stat(current_run)]} {
	unset ws_stat(current_run)
      }
      put_test
    }
  } else {
    set ws_stat(current_test) $oldTest
  }
}


# ****************************************************************************
#
#  proc put_test { }
#  Gets test displays for current test set in ws_stat(current_test)
#  
# ****************************************************************************
proc put_test { } {

    global BASE_TEST_DIR ws_stat Test_list
    global All_types Disp_types Text_types Spec_types
    global text_geom text_id SlSt bp_arr
    global text_max_pix wsParam

    foreach item $Disp_types {
	global $item
	global ${item}_arr
    }
    foreach item $Text_types {
	global ${item}_id
    }

    # check for open window displays - destroy them if they exist
    # Disp_types
    foreach item $Disp_types {

	set dlist [get_dlist $item]
	
	set dtype [lindex $dlist 0]
	if { ![catch {$dtype.sync $item}] } {
	    # check that window still exists - if it does destroy.
	    unset $item
	}
    }
    # Spec_type beam_profile
    foreach type {id pd} {
	
	if { ![catch {${type}.sync SlSt($type)}] } {
	    # check that window still exists - if it does destroy.
	    unset SlSt($type)
	}
    }
    # Text_Types
    foreach item $Text_types {
	if { [winfo exists .$item] } {
	    # check that window still exists - if it does destroy.
	    destroy .$item
	}
    }

    # check for display arrays - unset them if they exist
    foreach item $Disp_types {
	if { [info exists ${item}_arr] } {
	    unset ${item}_arr
	}
    }
    # Spec_type beam_profile
    if { [info exists bp_arr] } {
	unset bp_arr
    }

    # check for ws_stat arrays and unset them if they exist
    foreach i { ave_frames frame_ave disp_list frminterval contfrm } { 
	if {[info exists ws_stat($i)]} {
	    unset ws_stat($i)
	}
    }
	
# First check that this file exists - if so then source it

    set dfile $BASE_TEST_DIR/$ws_stat(current_test)/Disp_Info.tcl

    if {[file isfile $dfile]} {
	source $dfile
	if { ![info exists ws_stat(ave_frames)]} {
	    set ws_stat(ave_frames) No
	    set ws_stat(frame_ave) 1
	    set file_out [open $dfile a]
	    puts $file_out "set ws_stat(ave_frames) $ws_stat(ave_frames)"
	    puts $file_out "set ws_stat(frame_ave) $ws_stat(frame_ave)"
	    close $file_out
	} elseif { ![info exists ws_stat(frame_ave)]} {
	    if { $ws_stat(ave_frames) == "Yes" } {
	   	set ws_stat(frame_ave) $wsParam(maxFrames)
	    	set file_out [open $dfile a]
	    	puts $file_out "set ws_stat(frame_ave) $ws_stat(frame_ave)"
	    	close $file_out
	    } else { 
	       	set ws_stat(frame_ave) 1
	   	set file_out [open $dfile a]
	   	puts $file_out "set ws_stat(frame_ave) $ws_stat(frame_ave)"
	   	close $file_out
	    }	
	}
    } 

    foreach item $ws_stat(disp_list) {
	foreach type $Disp_types {
	    if { ![string compare $item $type] } {
		put_${item}
	    }
	}

	# Spec_type beam_profile
	if { ![string compare $item "beam_profile"] } {
	    put_beam_profile
	}

	foreach type $Text_types {
	    if { ![string compare $item $type] } {
		if { ![string compare $type "text_entry"] } {
		    if { [winfo exists .$item] } { destroy .$item }
		    toplevel .$item
		    wm title .$item "Text Entry"
		    RunInfo .text_entry dummy
		    wm geometry .$item $text_geom($item)
		    set grid_info [wm grid .$item]
		    set w_incr [lindex $grid_info 2]
		    set h_incr [lindex $grid_info 3]
		    set maxw_grid [expr $text_max_pix(entry_width) / $w_incr]
		    set maxh_grid [expr $text_max_pix(entry_height) / $h_incr]
		    wm maxsize .$item $maxw_grid $maxh_grid
		} else {
		  if { $item == "msquared" } {
		    MakeTextPanel .$item 100 100 36 5 text_id($item) txt
		    if { ($wsParam(focusRemFlag) == "No") } \
			{
			    set wsParam(focusRemFlag) "Yes"
			    wl_PanelsMsg "Focus Removal Enabled for M2 Calculation"
			}
		  } else { 
		    MakeTextPanel .$item 100 100 36 20 text_id($item) txt
		  }
		    wm geometry .$item $text_geom($item)
		    set grid_info [wm grid .$item]
		    set w_incr [lindex $grid_info 2]
		    set h_incr [lindex $grid_info 3]
		    set maxw_grid [expr $text_max_pix(panel_width) / $w_incr]
		    set maxh_grid [expr $text_max_pix(panel_height) / $h_incr]
		    wm maxsize .$item $maxw_grid $maxh_grid
		}
	    }
	}
    }
}

# ****************************************************************************
#
#  proc verify_test { }
#  
# ****************************************************************************
proc verify_test { } {

    global BASE_TEST_DIR ws_stat Test_list
    global Disp_types Spec_types Text_types All_types
    global Test_Options SlSt platform
    foreach id $Disp_types {
		global $id
    }

    update

    set dispinfo $BASE_TEST_DIR/$ws_stat(current_test)/Disp_Info.tcl
    if { [file exists $dispinfo] } { source $dispinfo }

    if { $ws_stat(re_reduce) == 1 } { 
        source $BASE_TEST_DIR/$ws_stat(rered)/Run_Info.tcl
    }
    
    foreach item $All_types {
	if { [ catch { if { $Test_Options($item) == 1 } { } } ] }  {
		set Test_Options($item) 0 
	}
    }


    set file_out [open $dispinfo a]
    set save_test_flag 0
    
    foreach item $Disp_types {
	
	if { $Test_Options($item) == 1 } {
	    
	    set dlist [get_dlist $item]
	    set dtype [lindex $dlist 0]
	    update
			
	    # Make sure window exists before grabbing info
	    if { [catch {$dtype.sync $item}] } {
		set msg "The $item display has been removed, \
		 do you wish to permanently remove it from the test?"

		if { [wl_PanelsYesNo $msg] == "Yes" } {
		    puts $file_out "set Test_Options($item) 0"
		    set ws_stat(disp_list) [ldelete $ws_stat(disp_list) $item]
		    set save_test_flag 1
		    continue
		} else {
		    recreate_disp $item
		    update
		    $dtype.get.xy $item = x y
		    $dtype.get.wh $item = w h
		    
		    # position adjustments for CDE
		    
		    if { $platform != "windows" } {
			set x [expr $x - 5]
			set y [expr $y - 24]
		    }
		    
		    puts $file_out "set ${item}_arr(xpos) $x"
		    puts $file_out "set ${item}_arr(ypos) $y"
		    puts $file_out "set ${item}_arr(width) $w"
		    puts $file_out "set ${item}_arr(height) $h"
		    update
		    
		    if { $dtype == "id" } {
			set color [$dtype.get.colormap $item]
			set interp [$dtype.get.interp $item]
			set ncolors [$dtype.get.ncolors $item]
			puts $file_out "set ${item}_arr(colormap) $color"
			puts $file_out "set ${item}_arr(interp) $interp"
			puts $file_out "set ${item}_arr(ncolors) $ncolors"
		    }
		    if { $dtype == "wd" } {
			$dtype.get.color $item = color
			$dtype.get.type $item = type
			$dtype.get.hide $item = hide
			$dtype.get.pers $item = pers
			puts $file_out "set ${item}_arr(color) $color"
			puts $file_out "set ${item}_arr(type) $type"
			puts $file_out "set ${item}_arr(hide) $hide"
			puts $file_out "set ${item}_arr(pers) $pers"
		    }
		    if { $dtype == "pd" } {
			$dtype.get.color $item = color
			$dtype.get.grid $item = grid
			$dtype.get.line $item = line
			$dtype.get.type $item = type
			puts $file_out "set ${item}_arr(color) $color"
			puts $file_out "set ${item}_arr(grid) $grid"
			puts $file_out "set ${item}_arr(line) $line"
			puts $file_out "set ${item}_arr(type) $type"
		    }
		    
		    update
		}
	    }
	    
	    update
	}
    }
    
# Special case of beam_profile

    foreach item $Test_Options(beam_profile) {
	
	if { $Test_Options(beam_profile) == 1 } {

	    set cont_flag 0
	    update
	    
	    # Verify image and plot display windows exists before grabbing info
	    if { [catch {id.sync SlSt(id)}] } {
		set msg "The beam profile display has been removed, \
	                do you wish to permanently remove it from the test?"
		set save_test_flag 1
		if { [wl_PanelsYesNo $msg] == "Yes" } {
		    unset SlSt(pd) 
		    puts $file_out "set Test_Options(beam_profile) 0"
		    set ws_stat(disp_list) [ldelete $ws_stat(disp_list) beam_profile]
		    set save_test_flag 1
		    break
		} else {
		    unset SlSt(pd)
		    recreate_disp beam_profile 
		    set cont_flag 1
		}
	    }
	    update
	    if { [catch {pd.sync $SlSt(pd)}] } {
		set msg "The beam profile display has been removed, \
			 do you wish to permanently remove it from the test?"
		set save_test_flag 1
		if { [wl_PanelsYesNo $msg] == "Yes" } {
		    unset SlSt(id) 
		    puts $file_out "set Test_Options(beam_profile) 0"
		    set ws_stat(disp_list) [ldelete $ws_stat(disp_list) beam_profile]
		    set save_test_flag 1
		    break
		} else {
		    unset SlSt(id)	
		    recreate_disp beam_profile
		    set cont_flag 1 
		}
	    }
	    
	    if { $cont_flag == 1 } { 
		foreach type {id pd} {
		    $type.get.xy $SlSt($type) = x y
		    $type.get.wh $SlSt($type) = w h
		    
		    # position adjustments for CDE
		    if { $platform != "windows" } { 
			set x [expr $x - 5]
			set y [expr $y - 24]
		    }
		    
		    puts $file_out "set bp_arr(${type}_xpos) $x"
		    puts $file_out "set bp_arr(${type}_ypos) $y"
		    puts $file_out "set bp_arr(${type}_width) $w"
		    puts $file_out "set bp_arr(${type}_height) $h"
		    update
		    
		    if { $type == "id" } {
			set color [$type.get.colormap $SlSt($type)]
			set interp [$type.get.interp $SlSt($type)]
			set ncolors [$type.get.ncolors $SlSt($type)]
			puts $file_out "set bp_arr(${type}_colormap) $color"
			puts $file_out "set bp_arr(${type}_interp) $interp"
			puts $file_out "set bp_arr(${type}_ncolors) $ncolors"
		    } else {
			pd.get.grid $SlSt(pd) = grid
			pd.get.line $SlSt(pd) = line
			pd.get.type $SlSt(pd) = type
			puts $file_out "set bp_arr(pd_grid) $grid"
			puts $file_out "set bp_arr(pd_line) $line"
			puts $file_out "set bp_arr(pd_type) $type"
		    }		       
		}
	    }
	}
	
    }
    
    foreach item $Text_types {
	if { $Test_Options($item) == 1 } {


	    if {[winfo exists .$item]} {
		puts $file_out "set text_geom($item) [wm geometry .$item]"
	    } else {
		set msg "The $item display has been removed, \
		do you wish to permanently remove it from the test?"
		set save_test_flag 1
		if { [wl_PanelsYesNo $msg] == "Yes" } {
		    puts $file_out "set Test_Options($item) 0"
		    set ws_stat(disp_list) [ldelete $ws_stat(disp_list) $item]
		    set save_test_flag 1
		    continue
		} else {
		    recreate_disp $item
		    puts $file_out "set text_geom($item) [wm geometry .$item]"
		}
	    }
	    
	}
    }

   # write out final display list
    if { $save_test_flag == 1 } { 
	puts $file_out "set ws_stat(disp_list)  {$ws_stat(disp_list)}"
    }
    close $file_out

 }

# ****************************************************************************
#
#  proc get_test { }
#  gets all the relevant test display information and saves to Disp_Info.tcl
#  file in $BASE_TEST_DIR/$ws_stat(current_test) directory
#  
# ****************************************************************************
proc get_test { } {

  global BASE_TEST_DIR ws_stat Test_list
  global Disp_types Spec_types Text_types All_types
  global Test_Options SlSt platform
  foreach id $Disp_types {
    global $id
  }
  
  update
  if { $ws_stat(current_test) == "" } { 
    return 
  }
  
  set dispinfo $BASE_TEST_DIR/$ws_stat(current_test)/Disp_Info.tcl
  if { [file exists $dispinfo] } {
    source $dispinfo
  }
  
  set disp_list ""
  foreach item $All_types {
    if { [ catch { \
		     if { $Test_Options($item) == 1 } { 
		       set disp_list [concat $disp_list $item] 
		     } } ] }  {
      set Test_Options($item) 0 }
  }
  update
  set ws_stat(disp_list) $disp_list
  
  set dirsel $BASE_TEST_DIR/$ws_stat(current_test)
  
  if { ![file isdirectory $dirsel] } {
    if { $platform == "windows" } {
      file mkdir $dirsel
    } else {
      exec mkdir $dirsel
    }
  }
  
  set file_out [open $dirsel/Disp_Info.tcl w]
  
  foreach i $All_types {
    puts $file_out "set Test_Options($i) {$Test_Options($i)}"
  }
  if { [info exists Test_Options(DC)] } { 
    puts $file_out "set Test_Options(DC) {$Test_Options(DC)}"
  }
  update
  puts $file_out "set ws_stat(num_frames) $ws_stat(num_frames)"
  
  foreach item $Disp_types {
    
    if { $Test_Options($item) == 1 } {
      
      set dlist [get_dlist $item]
      set dtype [lindex $dlist 0]
      update
      
      $dtype.get.xy $item = x y
      $dtype.get.wh $item = w h
      
      # position adjustments for CDE
      
      if { $platform != "windows" } {
	set x [expr $x - 5]
	set y [expr $y - 24]
      }
      
      puts $file_out "set ${item}_arr(xpos) $x"
      puts $file_out "set ${item}_arr(ypos) $y"
      puts $file_out "set ${item}_arr(width) $w"
      puts $file_out "set ${item}_arr(height) $h"
      update
      
      if { $dtype == "id" } {
	set color [$dtype.get.colormap $item]
	set interp [$dtype.get.interp $item]
	set ncolors [$dtype.get.ncolors $item]
	puts $file_out "set ${item}_arr(colormap) $color"
	puts $file_out "set ${item}_arr(interp) $interp"
	puts $file_out "set ${item}_arr(ncolors) $ncolors"
      }
      if { $dtype == "wd" } {
	$dtype.get.color $item = color
	$dtype.get.type $item = type
	$dtype.get.hide $item = hide
	$dtype.get.pers $item = pers
	puts $file_out "set ${item}_arr(color) $color"
	puts $file_out "set ${item}_arr(type) $type"
	puts $file_out "set ${item}_arr(hide) $hide"
	puts $file_out "set ${item}_arr(pers) $pers"
      }
      if { $dtype == "pd" } {
	$dtype.get.color $item = color
	$dtype.get.grid $item = grid
	$dtype.get.line $item = line
	$dtype.get.type $item = type
	puts $file_out "set ${item}_arr(color) $color"
	puts $file_out "set ${item}_arr(grid) $grid"
	puts $file_out "set ${item}_arr(line) $line"
	puts $file_out "set ${item}_arr(type) $type"
      }
      
      update
    }
  }
  
# Special case of beam_profile

  foreach item $Test_Options(beam_profile) {
    
    if { $Test_Options(beam_profile) == 1 } {
      update
      
      foreach type {id pd} {
	$type.get.xy $SlSt($type) = x y
	$type.get.wh $SlSt($type) = w h
	
	# position adjustments for CDE
	if { $platform != "windows" } { 
	  set x [expr $x - 5]
	  set y [expr $y - 24]
	}
	
	puts $file_out "set bp_arr(${type}_xpos) $x"
	puts $file_out "set bp_arr(${type}_ypos) $y"
	puts $file_out "set bp_arr(${type}_width) $w"
	puts $file_out "set bp_arr(${type}_height) $h"
	update
	
	if { $type == "id" } {
	  set color [$type.get.colormap $SlSt($type)]
	  set interp [$type.get.interp $SlSt($type)]
	  set ncolors [$type.get.ncolors $SlSt($type)]
	  puts $file_out "set bp_arr(${type}_colormap) $color"
	  puts $file_out "set bp_arr(${type}_interp) $interp"
	  puts $file_out "set bp_arr(${type}_ncolors) $ncolors"
	} else {
	  pd.get.grid $SlSt(pd) = grid
	  pd.get.line $SlSt(pd) = line
	  pd.get.type $SlSt(pd) = type
	  puts $file_out "set bp_arr(pd_grid) $grid"
	  puts $file_out "set bp_arr(pd_line) $line"
	  puts $file_out "set bp_arr(pd_type) $type"
	}		       
      }
      
    }
    
  }
    
  foreach item $Text_types {
    if { $Test_Options($item) == 1 } {
      
      if {[winfo exists .$item]} {
	puts $file_out "set text_geom($item) [wm geometry .$item]"
      } 
    }
  }

  # write out final display list
  puts $file_out "set ws_stat(ave_frames) $ws_stat(ave_frames)"
  puts $file_out "set ws_stat(frame_ave) $ws_stat(frame_ave)"
  puts $file_out "set ws_stat(disp_list)  {$ws_stat(disp_list)}"
  puts $file_out "set ws_stat(frminterval) {$ws_stat(frminterval)}"
  puts $file_out "set ws_stat(contfrm) {$ws_stat(contfrm)}"
  close $file_out

}


#--------------------------------------------------------------------------
# proc run_test
#
# If ws_stat(caldir) is unset then user notified that system has to be
# calibrated before test can be run.
# If ws_stat(new_test) is True then procedure first calls save_test and
# if successful then ws_stat(new_test) has been set to False.
# If ws_stat(new_test) is False then procedure 
# Prompts user for name of both test and run and then executes test.
#--------------------------------------------------------------------------

proc run_test {} {

  global ws_stat wsRunInfo Test_list Disp_types BASE_TEST_DIR
  global platform


  # Destroy control panel for replay displays
  #
  if {[winfo exists .rp]} { destroy .rp }

  update

  # Check to see if a new test is open that needs to be saved
  # before we can run.
  #
  if { ![string compare $ws_stat(new_test) "True"] } {
    save_test True 
  } else {
    update

    # If .text_entry does not exist, put up a panel that has just
    # run, user, and data information.
    #
    if { ![winfo exists .text_entry] } {

      if { $wsRunInfo(user_name) != "" } { 
	set wsRunInfo(user_name) $wsRunInfo(user_name)
      }

      if { $platform == "windows" } {
	set ttt [clock seconds] 
	set d [clock format $ttt -format %c]
      } else {
	set d [exec date]
      }

      set wsRunInfo(date) $d
      if { $wsRunInfo(run_name) != "" } { 
	set wsRunInfo(run_name) $wsRunInfo(run_name)
      }

      set msg "Enter a unique Run name and a User name."
      set do_continue [prompt_user $msg]
      if { ![string compare $do_continue "Continue"] } {

	# Check that wsRunInfo(run_name) doesn't exist
	#
	if { ![check_aok] } {
	  return
	}

	save_params
	if { [doTest] == "Abort" } {
	  delete_data $wsRunInfo(run_name)
	  return "Abort"
	}
      } else {
	return "Abort"
      }
      
    } else {
      # If we got here, .text_entry exists
      #
      if { [string compare $wsRunInfo(user_name) ""] && \
	     [string compare $wsRunInfo(run_name) ""] } {
	
	# Check that wsRunInfo(run_name) doesn't already exist
	#
	if { ![check_aok] } {
	  return
	}	

	save_params
	if { [doTest] == "Abort" } {
	  delete_data $wsRunInfo(run_name)
	  return "Abort"
	}
      } elseif { ![string compare $wsRunInfo(user_name) ""] && \
		   ![string compare $wsRunInfo(run_name) ""] } {
	# .text_entry exists but User and Run name fields are empty
	#
	set msg "Run and User names cannot be left blank."
	set do_continue [prompt_user $msg]
	if { ![string compare $do_continue "Continue"] } {

	  # Check that wsRunInfo(run_name) doesn't already exist
	  #
	  if { ![check_aok] } {
	    return
	  }

	  save_params
	  if { [doTest] == "Abort" } {
	    delete_data $wsRunInfo(run_name)
	    return "Abort"
	  }
	} else {
	  return "Abort"
	}
      } elseif { ![string compare $wsRunInfo(user_name) ""] && \
		   [string compare $wsRunInfo(run_name) ""] } {
	# .text_entry exists but User name field is empty
        #
	set msg "User name cannot be left blank."
	set do_continue [prompt_user $msg]
	if { ![string compare $do_continue "Continue"] } {

	  # Check that wsRunInfo(run_name) doesn't exist
	  #
	  if { ![check_aok] } {
	    return
	  }

	  save_params
	  if { [doTest] == "Abort" } {
	    delete_data $wsRunInfo(run_name)
	    return "Abort"
	  }
	} else {
	   return "Abort"
        }
      } elseif { ![string compare $wsRunInfo(run_name) ""] && \
		   [string compare $wsRunInfo(user_name) ""] } {

	# .text_entry exists but Run name field is empty
        #
	set msg "Run name cannot be left blank."
	set do_continue [prompt_user $msg]
	if { ![string compare $do_continue "Continue"] } {

	  # Check that wsRunInfo(run_name) doesn't already exist
	  #
	  if { ![check_aok] } {
	    return
	  }

	  save_params
	  if { [doTest] == "Abort" } {
	    delete_data $wsRunInfo(run_name)
	    return "Abort"
	  }
	} else {
	  return "Abort"
	}
      }
    }
  }
}

#--------------------------------------------------------------------------
# proc auto_run_test
#
# Modified version of run_test (above) to be scriptable (ie no user prompting required)
# Uses parameter "run_name" to store results.  A suitable test must be open before calling
# this procedure.  
# hdyson, 24th Nov 03
#
# If ws_stat(caldir) is unset then user notified that system has to be
# calibrated before test can be run.
# If ws_stat(new_test) is True then procedure first calls save_test and
# if successful then ws_stat(new_test) has been set to False.
# If ws_stat(new_test) is False then procedure 
# Prompts user for name of both test and run and then executes test.
#--------------------------------------------------------------------------

proc auto_run_test {run_name} {

  global ws_stat wsRunInfo Test_list Disp_types BASE_TEST_DIR
  global platform


  # Destroy control panel for replay displays
  #
  if {[winfo exists .rp]} { destroy .rp }

  update

  # Check to see if a new test is open that needs to be saved
  # before we can run.
  #
  if { ![string compare $ws_stat(new_test) "True"] } {
    save_test Auto
  } 
  update

    # If .text_entry does not exist, put up a panel that has just
    # run, user, and data information.
    #

  set wsRunInfo(user_name) "Automatic Test"

  if { $platform == "windows" } {
      set ttt [clock seconds] 
      set d [clock format $ttt -format %c]
  } else {
      set d [exec date]
  }

#  set ws_stat(display_date) $d

  set wsRunInfo(date) $d
  
  set wsRunInfo(run_name) $run_name

  	# Check that wsRunInfo(run_name) doesn't exist
	#
  if { ![check_aok] } {
      return
  }

#  save_params
  if { [doTest] == "Abort" } {
      delete_data $wsRunInfo(run_name)
      return "Abort"
  }
}


proc save_params { } {
    global BASE_TEST_DIR ws_stat wsRunInfo wsParam wlCalibrate ws_results

    set file_name $BASE_TEST_DIR/$ws_stat(current_test)/$wsRunInfo(run_name)/Run_Info.tcl
    set file_out [open $file_name a]
    puts $file_out "set wsParam(tiltRemFlag) $wsParam(tiltRemFlag)"
    puts $file_out "set wsParam(focusRemFlag) $wsParam(focusRemFlag)"
    puts $file_out "set wsParam(Lambda) $wsParam(Lambda)"
    puts $file_out "set ws_stat(num_frames) $ws_stat(num_frames)"
    puts $file_out "set ws_stat(ave_frames) $ws_stat(ave_frames)"
    puts $file_out "set ws_stat(frame_ave) $ws_stat(frame_ave)"
    puts $file_out "set ws_stat(frminterval) {$ws_stat(frminterval)}"
    puts $file_out "set ws_stat(contfrm) {$ws_stat(contfrm)}"
    puts $file_out "set ws_stat(display_date) {$ws_stat(display_date)}"
    puts $file_out "set wlCalibrate(PupilShape) {$wlCalibrate(PupilShape)}"
    close $file_out

    # Check to see if parameters exist and display or replace
    if { [winfo exists .text_entry] } {
	set value1 [.text_entry.frm.txt search -back "Tilt is" end]
	set value2 [.text_entry.frm.txt search -back "Focus is" end]
	set value3 [.text_entry.frm.txt search -back "Lambda is" end]
	if { ($value1 != "") && ($value2 != "") && ($value3 != "") } {
	    scan [expr $value3 + 1] %d value4
	    .text_entry.frm.txt delete $value1 $value4.end
	    scan [expr $value1 - 1] %d value1
	    if { $wsParam(tiltRemFlag) == "Yes" } {
		.text_entry.frm.txt insert $value1.end "\nTilt is removed.\n"
	    } else {
		.text_entry.frm.txt insert $value1.end "\nTilt is not removed.\n"
	    }
	    if { $wsParam(focusRemFlag) == "Yes" } {
		.text_entry.frm.txt insert $value2 "Focus is removed.\n"
	    } else {
		.text_entry.frm.txt insert $value2 "Focus is not removed.\n"
	    }
	    .text_entry.frm.txt insert $value3 "Lambda is $wsParam(Lambda) microns."
	} else { 
    
	    if { $wsParam(tiltRemFlag) == "Yes" } {
		.text_entry.frm.txt insert end "\nTilt is removed.\n"
	    } else {
		.text_entry.frm.txt insert end "\nTilt is not removed.\n"
	    }
	    if { $wsParam(focusRemFlag) == "Yes" } {
		.text_entry.frm.txt insert end "Focus is removed.\n"
	    } else {
		.text_entry.frm.txt insert end "Focus is not removed.\n"
	    }
	    .text_entry.frm.txt insert end "Lambda is $wsParam(Lambda) microns."
	}
	set res [.text_entry.frm.txt index end]
	set last [expr $res - 0.09]
	set ws_results(Text) [.text_entry.frm.txt get 1.0 $last]	
    }
}


# ****************************************************************************
#
#  proc get_runname { name }
#  Takes runname name and checks 1] to see if name directory already exists in
#  Test path/Run name and 2] if there are any whitespaces.
#  If name exists, user is prompted to try again.
#  If name doesn't exist yet new directory is made
#  and pops up message that name has been added to list.  
#  Returns a 1 if everything o.k.  If there are whitespaces in name, accounts
#  for this by putting curly brackets around name.
#  
# ****************************************************************************
proc get_runname { name } {

    global BASE_TEST_DIR ws_stat platform 
    
    if { ![string compare $name ""] } {
# 	wl_PanelsWarn "Run name cannot be empty - please enter name again"
	return 0
    } else {
	set dirsel $BASE_TEST_DIR/$ws_stat(current_test)/$name
    }

    if { [file isdirectory $dirsel] } {
 	wl_PanelsWarn "Run name '$name' for Test '$ws_stat(current_test)'\
already exists - please choose another."
	return 0
    } else {

	set res [string first " " $name]

	if {$res > -1} {
	    set name "{$name}"
	}

	set rlist $BASE_TEST_DIR/$ws_stat(current_test)/Run_list.tcl
	if { [file exists $rlist] } {
	    source $rlist
	    set Run_list [concat $Run_list $name]
	    set Run_list [lsort -ascii $Run_list]
	} else {
	    set Run_list $name
	}
	set fileid [open $rlist w]
	puts $fileid "set Run_list {$Run_list}"
	close $fileid

	if { $platform == "windows" } {
	    file mkdir $dirsel
	} else {
	    exec mkdir $dirsel
	}
	set ws_stat(rundir) $dirsel

	set fileid [open $dirsel/Run_Info.tcl w]
	puts $fileid "set ws_stat(mlm) $ws_stat(mlm)"
	close $fileid


	return 1
    }

}

# ****************************************************************************
#
#  proc check_aok { }
#  If everything aok - continue execute run
#  If not, cancel execute run
#
# ****************************************************************************

proc check_aok { } {

    global wsRunInfo
    set aok [get_runname $wsRunInfo(run_name)]
    while { $aok == 0 } {
		update
		set res \
			[enter_val "Enter New Run Name:" new_run 20 "Get New Run Name"]
		if { ![string compare $res ""] } {
			return 0 
		}
		set aok [get_runname $wsRunInfo(run_name)]
    }

    return 1
}


# ****************************************************************************
#
#  proc put_new_disps { }
#
#  
# ****************************************************************************
proc put_new_disps { } {

    global Disp_types Spec_types Text_types
    global Test_Options text_id platform
    global SlSt text_max_pix wsParam

    foreach id $Disp_types {
	global $id
    }

    foreach item $Disp_types {
	if { $Test_Options($item) == 1 } {
	    set dlist [get_dlist $item]
	    set dtype [lindex $dlist 0]
	    set def_w [lindex $dlist 1]
	    set def_h [lindex $dlist 2]
	    
	    $dtype.new $item
	    $dtype.set.title $item $item
	    $dtype.set.wh $item $def_w $def_h
	    
	    if { $item == "fringes_id" } {
		id.set.interp fringes_id on
	    } elseif { $dtype == "wd" } {
		wd.set.type $item 4
	    }
	}
    }	

# Special case of beam_profile

    if { $Test_Options(beam_profile) == 1 } {
	
	id.new SlSt(id)
	id.set.title $SlSt(id) "Beam Intensity"
	if { $platform == "windows" }  {
	    id.set.xy $SlSt(id) 615 85
	    id.set.wh $SlSt(id) 400 320
	} else {
	    id.set.xy $SlSt(id) 743 207 
	    id.set.wh $SlSt(id) 400 400
	}
	
	pd.new SlSt(pd)
	pd.set.title $SlSt(pd) "Beam Intensity Slices"
	if { $platform == "windows" } { 
	    pd.set.xy $SlSt(pd) 615 445
	    pd.set.wh $SlSt(pd) 400 250
	} else { 
	    pd.set.xy $SlSt(pd) 743 634
	    pd.set.wh $SlSt(pd) 400 250
	}
    }

    set txpos 0
    set typos 75

    foreach item $Text_types {

	if { $Test_Options($item) == 1 } {
	    
	    if { ![string compare $item "text_entry"] } {
		if { [winfo exists .$item] } { destroy .$item }
		toplevel .$item
		wm title .$item "Text Entry"
		if { $platform == "windows" } { 
		    wm geometry .$item 43x15+0+415
		} else {
		    wm geometry .$item 43x15+0+551
		}
		RunInfo .text_entry dummy
		set grid_info [wm grid .$item]
		set w_incr [lindex $grid_info 2]
		set h_incr [lindex $grid_info 3]
		set maxw_grid [expr $text_max_pix(entry_width) / $w_incr]
		set maxh_grid [expr $text_max_pix(entry_height) / $h_incr]
		wm maxsize .$item $maxw_grid $maxh_grid
	    } else {
	        if { $item == "msquared" } {
		MakeTextPanel .$item $txpos $typos 36 5 text_id($item) txt
		if { ($wsParam(focusRemFlag) == "No") } \
		    {
			set wsParam(focusRemFlag) "Yes"
			wl_PanelsMsg "Focus Removal Enabled for M2 Calculation"
		    }

		  } else { 
		MakeTextPanel .$item $txpos $typos 36 20 text_id($item) txt
		  }
		set grid_info [wm grid .$item]
		set w_incr [lindex $grid_info 2]
		set h_incr [lindex $grid_info 3]
		set maxw_grid [expr $text_max_pix(panel_width) / $w_incr]
		set maxh_grid [expr $text_max_pix(panel_height) / $h_incr]
		wm maxsize .$item $maxw_grid $maxh_grid
		set txpos [expr $txpos + 25]
		set typos [expr $typos + 25]
	    }
	}
    }
}

#--------------------------------------------------------------------------
# If a window disappeared that should still be in the test and the user would
# like to replace it this function is called.
#--------------------------------------------------------------------------

proc recreate_disp { item } {

    global Disp_types Text_types text_id SlSt text_max_pix
    global $item ws_results platform

    foreach i $Disp_types {
	
	if { $item == $i } {
	    
	    set dlist [get_dlist $item]
	    set dtype [lindex $dlist 0]
	    set def_w [lindex $dlist 1]
	    set def_h [lindex $dlist 2]
	    
	    $dtype.new $item
	    $dtype.set.title $item $item
	    $dtype.set.wh $item $def_w $def_h
	    
	    if { $item == "fringes_id" } {
		id.set.interp fringes_id on
	    } elseif { $dtype == "wd" } {
		wd.set.type $item 4
	    }
	}
    }

    if { $item == "beam_profile" } {

	id.new SlSt(id)
	id.set.title $SlSt(id) "Beam Intensity"
	if { $platform == "windows" }  {
	    id.set.xy $SlSt(id) 615 85
	    id.set.wh $SlSt(id) 400 320
	} else {
	    id.set.xy $SlSt(id) 743 207 
	    id.set.wh $SlSt(id) 400 400
	}
	
	pd.new SlSt(pd)
	pd.set.title $SlSt(pd) "Beam Intensity Slices"
	pd.set.wh $SlSt(pd) 400 250
	if { $platform == "windows" } { 
	    pd.set.xy $SlSt(pd) 615 445
	    pd.set.wh $SlSt(pd) 400 250
	} else { 
	    pd.set.xy $SlSt(pd) 743 634
	    pd.set.wh $SlSt(pd) 400 250
	}
	sliceInit $ws_results(BeamP)
	pd.clr.arrays $SlSt(pd)
    }

    set txpos 0
    set typos 75

    foreach i $Text_types {
	
	if { $item == $i } { 
	    
	    if { ![string compare $item "text_entry"] } {
		if { [winfo exists .$item] } { destroy .$item }
		toplevel .$item
		wm title .$item "Text Entry"
		wm geometry .$item 43x15+0+551
		RunInfo .text_entry dummy
		set grid_info [wm grid .$item]
		set w_incr [lindex $grid_info 2]
		set h_incr [lindex $grid_info 3]
		set maxw_grid [expr $text_max_pix(entry_width) / $w_incr]
		set maxh_grid [expr $text_max_pix(entry_height) / $h_incr]
		wm maxsize .$item $maxw_grid $maxh_grid
	    } else {
	      if { $item == "msquared" } { 
		MakeTextPanel .$item $txpos $typos 36 5 text_id($item) txt
	      } else { 
		MakeTextPanel .$item $txpos $typos 36 20 text_id($item) txt
	      }
		set grid_info [wm grid .$item]
		set w_incr [lindex $grid_info 2]
		set h_incr [lindex $grid_info 3]
		set maxw_grid [expr $text_max_pix(panel_width) / $w_incr]
		set maxh_grid [expr $text_max_pix(panel_height) / $h_incr]
		wm maxsize .$item $maxw_grid $maxh_grid
		set txpos [expr $txpos + 25]
		set typos [expr $typos + 25]
	    }
	}
    }
    wl_PanelsWarn "Please place the new window and select attributes before \
selecting continue."
}


#--------------------------------------------------------------------------
# proc TestSelect 
#
# Display a panel with check buttons to request the user's preference 
# regarding objects to show and save
#--------------------------------------------------------------------------

proc TestSelect { } {

  global wlPanel cb_labels
  global Test_list ws_stat RunInfo
  global Disp_types Spec_types Text_types All_types
  global Test_Options BASE_TEST_DIR
  foreach item $Test_list {
    global $item
  }

    
  set testname $ws_stat(current_test)

  # unset current Test_Options
  foreach item $All_types {
    if [info exists Test_Options($item)] {
      unset Test_Options($item)
    }
  }
  if [info exists Test_Options(DC)] { unset Test_Options(DC) } 

  # Destroy previous instances if any
  if { [winfo exists .wsTestSel] } { destroy .wsTestSel }

  # Create the panel
  #
  toplevel	.wsTestSel
  wm title	.wsTestSel "Test Display Selection"
  wm geometry .wsTestSel +10+84

  set tse [frame .wsTestSel.entry -relief flat -bd 3]
  pack $tse -side top -padx 3 -pady 3
	
  set ws_stat(num_frames) 1
  set ws_stat(frminterval) 0.0
  set ws_stat(contfrm) "No"
  set ws_stat(ave_frames) "No"
  set ws_stat(frame_ave) 1
  
  # Create the box for options for number of frames, 30Hz, interval, and ave
  #
  set tse_first [frame .wsTestSel.entry.first -relief flat]
  set tse_second [frame .wsTestSel.entry.second -relief flat]
  set tse_third [frame .wsTestSel.entry.third -relief flat]
    
  FrameCaptureEntry $tse_first "Number of Wavefront Measurements: " \
      ws_stat(num_frames) 4
  FrameCaptureEntry $tse_second \
      "Each Wavefront Measurement is an Average of " ws_stat(frame_ave) 3

  label $tse_third.label -text "Camera Frames"
  pack $tse_first -side top -pady 1m
  pack $tse_second -side left
  pack $tse_third.label -side right
  pack $tse_third -side right
  
  frame .wsTestSel.time -relief flat
  pack .wsTestSel.time -side top -padx 1m -pady 1m 

  set fi [frame .wsTestSel.time.delay -relief flat]

  FrameCaptureEntry $fi "Frame Interval (sec): " ws_stat(frminterval) 5
  pack $fi -side right -anchor w -expand 1

  set tf [frame .wsTestSel.time.opt -relief flat]

  radiobutton $tf.consec -variable ws_stat(contfrm) -value "Yes" -width 15 \
      -text "30Hz Collection" -relief flat -command "ws_ProcSetup30 $fi"
  radiobutton $tf.inter -variable ws_stat(contfrm) -value "No"  -width 15 \
      -text "Other Interval" -relief flat -command "ws_ProcSetup30 $fi"
  pack $tf.consec $tf.inter -side left -anchor w -padx 2
  pack $tf -side left -anchor w
  
  # Create a box for all the test options
  #
  frame .wsTestSel.frame -relief flat
  pack  .wsTestSel.frame -padx 1m -pady 1m

  set fleft [frame .wsTestSel.frame.left -relief groove -bd 3]
  set fright [frame .wsTestSel.frame.right -relief groove -bd 3]
  pack $fleft -padx 1m -pady 1m -side left
  pack $fright -padx 1m -pady 1m -side right
	   
  # Create each Display checkbutton
  #
  foreach item $Disp_types {
    checkbutton $fleft.$item -text $cb_labels($item) -width 30 -anchor w \
	-variable Test_Options($item) -highlightthickness 0
    pack $fleft.$item -side top -fill x -padx 1m -pady 1m
  }
    
  checkbutton $fright.$item -text "Data Collection (only)" \
      -variable Test_Options(DC) -width 30 -anchor w \
      -command dc_only -highlightthickness 0
  pack $fright.$item -side top -fill x -padx 1m -pady 1m

  # Create Special Display type checkbuttons
  #
  foreach item $Spec_types {
    checkbutton $fright.$item -text $cb_labels($item) -highlightthickness 0 \
	-variable Test_Options($item) -width 30 -anchor w
    pack $fright.$item -side top -fill x -padx 1m -pady 1m
  }
	
  # Create each Text Display checkbuttons
  #
  foreach item $Text_types {
    checkbutton $fright.$item -text $cb_labels($item) -highlightthickness 0 \
	-variable Test_Options($item) -width 30 -anchor w
    pack $fright.$item -side top -fill x -padx 1m -pady 1m
  }
    
  # Create the control buttons at the bottom of the window
  #
  frame   .wsTestSel.action -relief flat
  pack    .wsTestSel.action -side top -padx 1m -pady 1m

  button  .wsTestSel.action.ok -text "  OK  " \
	      -command { set wlPanel(action) "O.k." }
  button  .wsTestSel.action.cancel -text "Cancel" \
	      -command { destroy .wsTestSel; set wlPanel(action) "Cancel" }
  button  .wsTestSel.action.help -text "Help" \
	      -command {ShowHelp TestSetup.html}
  pack  .wsTestSel.action.ok .wsTestSel.action.cancel .wsTestSel.action.help \
	      -side left -padx 50 -pady 1m -expand 1

  bind .wsTestSel <Destroy> { set wlPanel(action) "Cancel" }

  while { 1 } {
      # wait for a selection to be made
      tkwait variable wlPanel(action)

      # if user does NOT want a new test created
      if { $wlPanel(action) == "Cancel"} {
	  set ws_stat(new_test) False
	  return "Abort"
      }

      # if continuing with new test 
      if { $wlPanel(action) == "O.k." } {
	  # check the frame capture parameters
	  if { $ws_stat(num_frames) > 9999 || $ws_stat(num_frames) < 1 } {
	      dialog "Number of Wavefront Measurements must be between 1 and 9999"
	      $tse_first.ws_stat(num_frames).entry configure -bg yellow\
		  -fg black
	  } elseif { $ws_stat(frame_ave) > 999 || $ws_stat(frame_ave) < 1 } {
	      dialog "To average wavefront measurements, the number of \
               camera frames must be between 2 and 999.  Set this number\
               to 1 for NO averaging."
	      $tse_second.ws_stat(frame_ave).entry configure -bg yellow\
		  -fg black
	  } elseif { $ws_stat(contfrm) == "Yes" && ($ws_stat(num_frames) == 1 \
		       || $ws_stat(frame_ave) == 1) } {
	      dialog "Cannot grab a single frame at 30 Hz.  The number of\
		      Wavefront Measurements  or Average Frames must be\
                      greater than 1."
	  } else {
	      destroy .wsTestSel
	      break	  
	  }
      }
  }
  return $wlPanel(action)
}


#--------------------------------------------------------------------------
#
# proc get_dlist { disp_name }  
#
# Parses disp_name to see if the display type is an image display (id),
# a wire display (wd), a plot display (pd) or a vector display (vd).
# Sets default width and height of displays for initial screen display.
#
#--------------------------------------------------------------------------

proc get_dlist { disp_name } {

    if { [string first "id" $disp_name] >= 0 } {
	set dlist {id 350 300}
    } elseif { [string first "wd" $disp_name] >= 0 } {
	set dlist {wd 300 300}
    } elseif { [string first "pd" $disp_name] >= 0 } {
	set dlist {pd 500 300}
    } elseif { [string first "vd" $disp_name] >= 0 } {
	set dlist {vd 300 300}
    }


    return $dlist
}


#--------------------------------------------------------------------------
# proc setup_test
#
# Executes a test (Live Display, Run/Save, Rereduce, Rereduce/Save) using
# the currently open test, and the latest Calibration data.
#--------------------------------------------------------------------------

proc setup_test { option } {

  global ws_stat wlCalibrate stagePos wsMLMParams wsdb dtlStatus
  global platform calFiles hw_flg
    

  # Check if a new test is unsaved, if so, let them save it now.
  #    
  if { ![string compare $ws_stat(new_test) "True"] } {
    save_test False
  }

  # Make sure a test is open before trying to execute
  #
  if { $ws_stat(current_test) == "" } {

    if { ($option == "Live") || ($option == "Save") || ($option == "Poke") } {
      dialog "A test must be open (or created) before you can run." +400+80
    } else {
      dialog "Open the test you wish to reduce the data with, then select Rereduce again." +500+80
    }
    return "Abort"
  }

  if { ($option == "Live") || ($option == "Save") || ($option == "Poke") || ($option == "Freq") } {

    # The system must be calibrated, or valid calibration data must be
    # saved on disk for this test or we can't run.
    #
    if { $wlCalibrate(doneInit) != "Yes" } {

      set calData $wlCalibrate(saveDir)/calData.tcl
      if { [file exists $calData] } {
	source $calData
	if { $ws_stat(mlm) != "" } { 
	  if { [ wl_PanelsContinueAbort  \
	      "The current MLM is $ws_stat(mlm)" +475+35] == "Abort" } {
	    return "Abort"
	  }
	} else {
          while { $ws_stat(mlm) == ""} {
            if { [SelectMLM] == "cancel" } { return "Abort" }
          }
        }
      } else {
	if { [Calibrate] == "Abort" } { return "Abort" }
      }
    }
    set ws_stat(replay) 0

    # Get the calibration data and determine pupil shape
    #
    CalLoadData $calFiles
    if { [a.cols wlCalibrate(Pupil)] == 1 }  {
      set wlCalibrate(PupilShape) "Rectangular"
    } else {
      set wlCalibrate(PupilShape) "Circular"
    }
    
    # Determine which functions must be computed dependent upon test
    # selection
    parse_displist
    update

    # If the hardware flag is on, make sure the stage is in the correct
    # place and the exposure is correct
    #
    if { $hw_flg == "TRUE" } {
      set pos [stage.get.position]
      set posv [split $pos]
      foreach x $posv {
	if { ($x != "Z") && ($x != "") } {
	  set res $x
	}
      }
      if { $res != $stagePos(BestRefSpots) } {
	stage.calibrate.absolute $stagePos(BestRefSpots)
      }
      update
      set exposure $wsdb(testSpotExposure)
      set exposureList [alignInterface:getExposureList]
      set exposureIndex [lsearch $exposureList $exposure]
      
      send_camera_exposure $exposureIndex
      set wsdb(cameraExposure) $exposure
    }
	
    # The test is run slightly differently depending on if it's Live, or 
    # a Run/Save.
    #
    if { $option == "Live" } {

      set ws_stat(save_data) 0
      set ws_stat(current_frame) 1
      set ws_stat(current_run) "Live Display";

      set_date
      fg.grabc_init
	    
      doTestLoop

    } else {

      # If we got here, we're doing a Run/Save
      #
#or auto... hdyson 24 Nov 03
      update
      set ws_stat(save_data) 1
      set run_flag 0
      if { [winfo exists .dtl] } {
	set run_flag 1
	if { $dtlStatus == "RUNNING" } {
	  dtl:doPause
	}
      }

      set_date
      if { $option == "Save" } { 
	  fg.grabc_init

	  set ws_stat(current_run) "Run/Save"
	  run_test
	  fg.grabc_term
	  
	  update
	  after 500
	  if { $run_flag == 1 } {
	      set ws_stat(save_data) 0
	      set ws_stat(current_run) "Live Display"
	  }
      } else {
	  #Must be Auto...
	  if { $option == "Poke" } { 
	      fg.grabc_init
	      
	      set ws_stat(current_run) "Auto"
	      #	  auto_run_test
	      poke_sequence
	      fg.grabc_term
	      
	      update
	      after 500
	  } else {
	      fg.grabc_init
	      
	      set ws_stat(current_run) "Auto"
	      #	  auto_run_test
	      spatial_sequence
	      fg.grabc_term
	      
	      update
	      after 500
	  }
      }
  }
} else {

    # If we got here, we're doing a Rereduce.
    #
    if { $option == "Reduce"} { 
      set ws_stat(reduce_custom) 0
    } else { 
      set ws_stat(reduce_custom) 1
    }

    set ws_stat(current_frame) 1
    set ws_stat(current_run) "Re-Reduce";

    if { [doReduce] == "Abort" } {
      return
    }
  }
}


#--------------------------------------------------------------------------
# Routine that just changes the exposure for test spots.  Accessed from the
# Test menu option, it doesn't move the stage.
#--------------------------------------------------------------------------

proc set_test_spot_exposure { } {

    global DisplayFlag wlCalibrate wsdb

    wl_PanelsWait .www "Checking the spot exposure.  Please wait."
    update 
    set DisplayFlag 0
    if { $wlCalibrate(doneInit) != "Yes" } \
    {
	set calData $wlCalibrate(saveDir)/calData.tcl
	update
	if { [file exists $calData] } {
	    source $calData
	}
    }
    update
    set current $wsdb(testSpotExposure)
	
    if { [SetProperExposure testSpotExposure] == "Abort" } {
	update
	return "Abort"
    }

    update

    if { [winfo exists .www] } { destroy .www } 
	
    if { $current != $wsdb(testSpotExposure) } { 
	wl_PanelsWarn "The exposure was changed from $current to $wsdb(testSpotExposure)"
    } else {
	if { [wl_PanelsYesNo "No change of exposure necessary.  Do you\
still wish to change the exposure?"] == "Yes" } {  
		
	    set msg "Please adjust the light intensity and exposure."
	    if { [CalAdjustExposure $msg testSpotExposure \
		"Test Spots"] == "Abort" }  {
		set wsdb(testSpotExposure) $current
		return "Abort"
	    }
	} 	
    }
}

#--------------------------------------------------------------------------
# proc ChangeFrames
#
# Ability to change the number of frames, 30Hz collection, frame interval,
# or averaging of frames for each run within a test.
#--------------------------------------------------------------------------

proc ChangeFrames { } {

  global BASE_TEST_DIR ws_stat wlPanel


  if { $ws_stat(current_test) == "" } {
    dialog "A test must be open to set frame capture settings." +350+80
    return
  }
    
  set dispinfo $BASE_TEST_DIR/$ws_stat(current_test)/Disp_Info.tcl
  if { [file exists $dispinfo] } {
    source $dispinfo
  }

  if { [winfo exist .testedit] } { destroy .testedit }

  toplevel    .testedit
  wm title    .testedit "Set Frame Capture Parameters"
  wm geometry .testedit +320+84
  raise .testedit

  frame .testedit.entry -relief flat
  pack .testedit.entry -side top -padx 1m -pady 1m

  set tse_first [frame .testedit.entry.first -relief flat]
  set tse_second [frame .testedit.entry.second -relief flat]
  set tse_third [frame .testedit.entry.third -relief flat]
 
  FrameCaptureEntry $tse_first "Number of Wavefront Measurements: " \
      ws_stat(num_frames) 4
  FrameCaptureEntry $tse_second \
      "Each Wavefront Measurement is an Average of " ws_stat(frame_ave) 3

  label $tse_third.label -text "Camera Frames"
  pack $tse_first -side top -pady 1m
  pack $tse_second -side left
  pack $tse_third.label -side right
  pack $tse_third -side right
  
  frame .testedit.time -relief flat
  pack .testedit.time -side top -padx 1m -pady 1m 

  set fi [frame .testedit.time.delay -relief flat]

  FrameCaptureEntry $fi "Frame Interval (sec): " ws_stat(frminterval) 5
  pack $fi -side right -anchor w -expand 1

  set tf [frame .testedit.time.opt -relief flat]

  radiobutton $tf.consec -variable ws_stat(contfrm) -value "Yes" -width 15 \
      -text "30Hz Collection" -relief flat -command "ws_ProcSetup30 $fi"
  radiobutton $tf.inter -variable ws_stat(contfrm) -value "No"  -width 15 \
      -text "Other Interval" -relief flat -command "ws_ProcSetup30 $fi"
  pack $tf.consec $tf.inter -side left -anchor w -padx 2
  pack $tf -side left -anchor w

  if { $ws_stat(contfrm) == "Yes" } { 
      ws_ProcSetup30 $fi
      }
      
  frame .testedit.frame2 -relief flat
  pack  .testedit.frame2 -side bottom -padx 1m -pady 1m

  button .testedit.frame2.ybutton -text "  OK  " \
      -command { set wlPanel(action) Continue }
  button .testedit.frame2.nbutton -text "Cancel" \
      -command { destroy .testedit; set wlPanel(action) Abort }
  button .testedit.frame2.hbutton -text "Help" \
      -command { ShowHelp FrameCapture.html }
  pack .testedit.frame2.ybutton .testedit.frame2.nbutton \
      .testedit.frame2.hbutton -side left -padx 20 -pady 5
    
  bind .testedit <Destroy> { set wlPanel(action) Abort }

  while { 1 } {
      # wait for a selection to be made
      tkwait variable wlPanel(action)

      if { $wlPanel(action) == "Continue" } {
	  # check the frame capture parameters
	  if { $ws_stat(num_frames) > 9999 || $ws_stat(num_frames) < 1 } {
	      dialog "Total Number of Frames must be between 1 and 9999"
	      $tse_first.ws_stat(num_frames).entry configure -bg yellow\
		  -fg black
	  } elseif { $ws_stat(frame_ave) > 999 || $ws_stat(frame_ave) < 1 } {
	      dialog "To average wavefront measurements, the number of \
               camera frames must be between 2 and 999.  Set this number\
               to 1 for NO averaging."
	      $tse_second.ws_stat(frame_ave).entry configure -bg yellow\
		  -fg black
	  } elseif { $ws_stat(contfrm) == "Yes" && $ws_stat(num_frames) == 1 } {
	      dialog "Cannot grab a single frame at 30 Hz.  The number of\
		      Wavefront Measurements must be greater than 1."
	      $tse_first.ws_stat(num_frames).entry configure -bg yellow\
		  -fg black
	  }  else {
	      if {[winfo exist .testedit]} { destroy .testedit }
	      set file_out [open $dispinfo a]
	      puts $file_out "set ws_stat(num_frames) $ws_stat(num_frames)"
	      puts $file_out "set ws_stat(ave_frames) $ws_stat(ave_frames)"
	      puts $file_out "set ws_stat(frame_ave) $ws_stat(frame_ave)"
	      puts $file_out "set ws_stat(frminterval) {$ws_stat(frminterval)}"
	      puts $file_out "set ws_stat(contfrm) {$ws_stat(contfrm)}"
	      close $file_out
	      break	  
	  }
      }
  }
}


#--------------------------------------------------------------------------
# Procedure to allow either averaging of frames or 30Hz collection.  If running
# with 30Hz the option to  set the frame interval is inactive. Called by
# TestSelect in this file
#--------------------------------------------------------------------------
proc ws_ProcSetup30 { w } {
 
    global ws_stat

    set win [lindex [split $w .] 1]
    if {$ws_stat(contfrm) == "Yes"} {
	set conf [ .$win.time.opt.consec configure -disabledforeground ]
	set color [lindex [split $conf] end ]
	$w.ws_stat(frminterval).entry configure -state disabled -fg $color
	$w.ws_stat(frminterval).label configure -fg $color
    } 
    update	
    if {$ws_stat(contfrm) == "No"} {
	set conf [ .$win.time.opt.consec configure -fg ]
	set color [lindex [split $conf] end ]
	$w.ws_stat(frminterval).entry configure -state normal -fg $color
	$w.ws_stat(frminterval).label configure -fg $color
   } 
    update

}


#--------------------------------------------------------------------------
# Procedure to allow the option Data Collection only which disabled the 
# other test options if selected.  Called by TestSelect in this file.
#--------------------------------------------------------------------------

proc dc_only { } { 

    global Test_Options 
    global Spec_types 
    global Disp_types 
    global Text_types

    if { $Test_Options(DC) == 1  } { 
	foreach item $Disp_types {
	    set Test_Options($item) 0
	    .wsTestSel.frame.left.$item configure -state disabled
	}
        foreach item $Spec_types {
	    set Test_Options($item) 0
	    .wsTestSel.frame.right.$item configure -state disabled
	}
 	foreach item $Text_types {
	    set Test_Options($item) 0
	    .wsTestSel.frame.right.$item configure -state disabled
	}
    }
    if { $Test_Options(DC) == 0  } { 
	foreach item $Disp_types {
	    .wsTestSel.frame.left.$item configure -state normal
	}
        foreach item $Spec_types {
	    .wsTestSel.frame.right.$item configure -state normal
	}
	foreach item $Text_types {
	    .wsTestSel.frame.right.$item configure -state normal
	}
    }
}

#--------------------------------------------------------------------------
# Procedure to create an entry box that allows the user to cahnge the width
# of the entry section
#--------------------------------------------------------------------------
proc FrameCaptureEntry { w title gvar width } {
    frame $w.${gvar} -width 4c -height 1.7c
    pack  $w.${gvar} -side top -fill x 

    label $w.${gvar}.label -text $title -anchor w
    entry $w.${gvar}.entry -width $width -relief sunken -bd 2 \
        -textvariable $gvar -insertbackground green -highlightthickness 1
    pack $w.${gvar}.entry $w.${gvar}.label -side right
}
