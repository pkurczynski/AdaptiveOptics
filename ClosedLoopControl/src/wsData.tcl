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
# FILE: wsData.tcl
# 
# DESCRIPTION:	
#   Routines to redisplay a test from its saved data and to delete saved
#   data.
# 
# $Id: wsData.tcl,v 1.27 1999/06/03 14:54:14 stacy Exp $
# 
#--------------------------------------------------------------------------


#--------------------------------------------------------------------------
# proc retrieve_data
# 
# Puts up list box of run names for ws_stat(current_test).  
# User chooses a run to redisplay data from - for each frame saved
# arrays are loaded into ws_results array.
#--------------------------------------------------------------------------

proc retrieve_data { } {

  global BASE_TEST_DIR
  global ws_stat ws_results wsMLMParams ws_ReplayStat new_mode
  global wsRunInfo wsParam platform wlCalibrate


  set dLoc +500+80

  if {$ws_stat(current_test) == ""} {
    dialog "Open a Test, then select Redisplay again." $dLoc
    return
  }

  if {[info exists ws_stat(redisplay_data)]} {
    unset ws_stat(redisplay_data)
  }

  # Always start with frame 1
  #
  set ws_stat(current_frame) 1
  set fnum $ws_stat(current_frame)
  set frame_num [fix_fnum $fnum]

  set test_dir $BASE_TEST_DIR/$ws_stat(current_test)
  set rlist $test_dir/Run_list.tcl

  if { [file exists $rlist] } {
    source $rlist

    if { $Run_list == "" } {
      dialog "There is no saved data for Test '$ws_stat(current_test)'" $dLoc
      return
    }

    if { [winfo exists .rp] } { exit_replay }
    	
    set ok [ListBox .redisplay_data $Run_list "Redisplay Data: " redisplay_data]

    if { $ok } {
      if { $ws_stat(redisplay_data) == "" } {
	dialog "No run selected"
      } else {

	if { [array exists ws_results] } {
	  unset ws_results
	}

	set ws_stat(current_run) $ws_stat(redisplay_data)
	set rundir $test_dir/$ws_stat(redisplay_data)
	set flag 0

	set run_info $rundir/Run_Info.tcl

	if {[info exists ws_stat(mlm)]} {
	  set ws_stat(Hold_MLM) $ws_stat(mlm)
	} else {
	  set ws_stat(Hold_MLM) NULL
	}

	if {[info exists wlCalibrate(PupilShape)]} {
	  set wlCalibrate(Hold_Shape) $wlCalibrate(PupilShape)
	  set wlCalibrate(PupilShape) ""
	} else {
	  set wlCalibrate(PupilShape) ""
	  set wlCalibrate(Hold_Shape) NULL
	}

	set wsParam(Hold_tiltRemFlag) $wsParam(tiltRemFlag)
	set wsParam(Hold_focusRemFlag) $wsParam(focusRemFlag)
	set wsParam(Hold_Lambda) $wsParam(Lambda)
	
	if {[file exists $run_info]} {
	  source $run_info
	} else {
	  SelectMLM
	}
	ws_GetMLMSpec

	
	set wsParam(Hold_psfScale) $wlCalibrate(psfScale)
	set wlCalibrate(psfScale) [expr \
		 ( $wsParam(Lambda) / $wlCalibrate(wsAperture) )* 250000.0 ]
	
	# If the pupil shape is not saved in run_info, assume this is an
	# old test and set the pupil shape to circular
        #
	if { $wlCalibrate(PupilShape) == "" } { 
	  set wlCalibrate(PupilShape) "Circular"
	}
			
	if {![info exists ws_stat(display_date)]} {
	    set_date
	}

	if { [ file isdirectory $rundir/Calibration ]} {
	   CalLoadRunData $rundir/Calibration
	} else { 
	   CalLoadRunData $wlCalibrate(saveDir) 
	}
		

	if { $platform == "windows" } {
	  set pwd [pwd]
	  cd $rundir
	  set array_list [glob *]
	  cd $pwd
	} else { 
	  set array_list [exec ls $rundir]
	}

	set array_list [ldelete $array_list Run_Info.tcl]
	set array_list [ldelete $array_list Calibration]
	set ws_ReplayStat(array_list) $array_list
	set ws_ReplayStat(run_dir) $rundir

	foreach arr $array_list {
	  set len [string length $arr]
	  set nlen [expr $len - 2]
	  set arr_name [string range $arr 0 $nlen]
	  a.load $rundir/$arr/$frame_num = ws_results($arr_name)
	}

	set num_list [glob $rundir/Images/*]
	set ws_stat(num_frames) [llength $num_list]
	if { $ws_stat(num_frames) == 1 } {
	  put_arrays $ws_stat(redisplay_data) $ws_stat(current_frame)
	} else {
	  put_arrays $ws_stat(redisplay_data) $ws_stat(current_frame)
	  set flag 1
	  replay_data
	}

	if { $flag == 0 } {
	  data_cleanup
	}
      }
    }
  } else {
    dialog "There is no saved data for Test '$ws_stat(current_test)'" $dLoc
  }
}


#--------------------------------------------------------------------------
# proc data_cleanup
# 
# Called to clean up all the information put into Hold locations
#--------------------------------------------------------------------------
proc data_cleanup { }  {

  global ws_stat wsParam wlCalibrate new_mode wsMLMParams

  # NOW CALL PROC to put_arrays for retrieved data
  # But make sure ws_stat(disp_list) is set for 
  # for ws_stat(current_test)
  # and make sure calibration directory info set?
  # (Might need cal dir stuff for MTF calcs?)

  # RESET ws_stat(mlm) to current MLM selected
  # and then get wsMLMParams

    if { ![string compare $ws_stat(Hold_MLM) "NULL"] } {
      set ws_stat(mlm) ""
      unset ws_stat(Hold_MLM)
    } else {
      set ws_stat(mlm) $ws_stat(Hold_MLM)
      unset ws_stat(Hold_MLM)
      if { $ws_stat(mlm) != "" } { 
	ws_GetMLMSpec
      }
    }

  set wsParam(tiltRemFlag) $wsParam(Hold_tiltRemFlag)
  set wsParam(focusRemFlag) $wsParam(Hold_focusRemFlag)
  set wsParam(Lambda) $wsParam(Hold_Lambda)
  set wlCalibrate(psfScale) $wsParam(Hold_psfScale)
  set wlCalibrate(PupilShape) $wlCalibrate(Hold_Shape)
  unset wsParam(Hold_tiltRemFlag)
  unset wsParam(Hold_focusRemFlag)
  unset wsParam(Hold_Lambda)
  unset wsParam(Hold_psfScale)
  unset wlCalibrate(Hold_Shape)
}


# ****************************************************************************
#
#  proc delete_data
#  Puts up list box of test names from Test_list.  User chooses a test
#  to delete and is queried - are they sure they want to delete -
#  If yes, test is removed from Test_list and from BASE_TEST_DIR path.
#  
# ****************************************************************************
proc delete_data { name } {

    global Run_list BASE_TEST_DIR ws_stat platform

    set test_dir $BASE_TEST_DIR/$ws_stat(current_test)
    set rlist $test_dir/Run_list.tcl
    if { [file exists $rlist] } {
	source $rlist
	set Run_list [ldelete $Run_list $name ]
	if { $platform == "windows" } {
	    file delete -force $test_dir/$name
	} else {
	    exec rm -r $test_dir/$name
	}
	set fileid [open $rlist w]
	puts $fileid "set Run_list {$Run_list}"
	close $fileid
    }
}


#--------------------------------------------------------------------------
# proc ws_data_manager
# 
# Called from the main menu bar with one of two options: Test or Data.
# Puts up a box that allows the user to delete either entire Tests or
# just the Data within them, based on the input parameter.
#--------------------------------------------------------------------------

proc ws_data_manager { type } {
    
  global BASE_DATA_DIR mount_point source_dir option_list Test_list
  global ws_stat source_list Run_list


  set source_list ""
    
  if { $type == "Test"} { 
    set dLoc +10+80
    set source_dir $BASE_DATA_DIR/TESTS
    set option_list [ldelete $Test_list DEFAULT]
  } else {
    set dLoc +500+80
    if {$ws_stat(current_test) == ""} {
      dialog "Open the Test from which you want to delete data, then select Delete again." $dLoc
      return
    }

    set source_dir $BASE_DATA_DIR/TESTS/$ws_stat(current_test)
    set rlist $source_dir/Run_list.tcl
    if { [file exists $rlist] } {
      source $rlist
      set option_list $Run_list
    } else {
      dialog "There is no saved data to delete for Test '$ws_stat(current_test)'" $dLoc
      return
    }
  }

  toplevel .dm
  wm title .dm "Data Manager"
  wm geometry .dm $dLoc
  grab .dm
  set top .dm.top
  set bottom .dm.bottom

  frame $top 
  frame $bottom 
  pack $top -side top
  pack $bottom -side bottom
  label $top.label -text "Delete $type"
  pack $top.label -side top -padx 2m -pady 2m
  button $bottom.cancel -text Cancel -command { destroy .dm }
  button $bottom.ok -text OK -command "destroy .dm; rm_info $type"
  pack $bottom.ok $bottom.cancel -side left -padx 2m -pady 2m

  foreach side { left right } {
    frame $top.$side
    pack $top.$side -side $side

    listbox $top.$side.list -yscrollcommand [list $top.$side.scroll set]
    scrollbar $top.$side.scroll -orient vertical \
	    -command [list $top.$side.list yview]

    if ![string compare $side left] {
      label $top.$side.label -text "Data"
    } else {
      label $top.$side.label -text "Selected Data"
    }
	    
    pack $top.$side.label -fill x -side top 
    pack $top.$side.list -side left
    pack $top.$side.scroll -fill y -side right
  }

  bind $top.left.list <ButtonPress-1> {ListSelectStart %W %y}
  bind $top.left.list <B1-Motion> {ListSelectExtend %W %y}
  bind $top.left.list <ButtonRelease-1> \
	[list SelectEnd %W %y $top.right.list]

  bind $top.right.list <ButtonPress-1> {ListSelectStart %W %y}
  bind $top.right.list <B1-Motion> {ListSelectExtend %W %y}
  bind $top.right.list <ButtonRelease-1> {DeleteEnd %W %y}
    
  foreach item $option_list {
    $top.left.list insert end $item
  }
  tkwait window .dm
}


# ****************************************************************************
#
#  proc replay_data 
#  puts up replay data panel when test/run retrieved has more than one frame
#  
# ****************************************************************************
proc replay_data { } {

    global ws_stat wsReplay applicationName ws_ReplayStat

    if {[winfo exists .rp]} { exit_replay }
    toplevel .rp
    
    wm title .rp "$applicationName Replay Panel"
    wm geometry .rp +365+30

    bind .rp <Destroy> { if {"%W" == ".rp"} { kill_replay } }
    
    set ws_stat(replay) 1
    
    # Frame control 
    
    frame .rp.frame0 -relief flat -bd 2
    
    pack .rp.frame0 -side top
    
    message .rp.frame0.msg -width 12c -justify left -text "Select \
          \"Forwards\" or \"Backwards\" to show frames continuously."          
    pack .rp.frame0.msg
    
    frame .rp.frame1 -relief raised -bd 2
    
    pack .rp.frame1 -side top
    
    radiobutton .rp.frame1.back -text "Backwards" \
	-variable wsReplay(Direction) \
	-command {set wsReplay(animated) "True"; ws_replayRedisplay} \
	-value Backward 
    
    radiobutton .rp.frame1.prev -text "Prev"      \
	-variable wsReplay(Direction) \
	-command {set wsReplay(animated) "False"; ws_replayRedisplay} \
	-value Prev
    
    radiobutton .rp.frame1.stop -text "Stop"      \
	-variable wsReplay(Direction) \
	-command {set wsReplay(animated) "False" } \
	-value Stop
    
    radiobutton .rp.frame1.next -text "Next"      \
	-variable wsReplay(Direction) \
	-command {set wsReplay(animated) "False"; ws_replayRedisplay} \
	-value Next
    
    radiobutton .rp.frame1.fore -text "Forwards"  \
	-variable wsReplay(Direction) \
	-command {set wsReplay(animated) "True"; ws_replayRedisplay } \
	-value Forward
    
    pack .rp.frame1.back .rp.frame1.prev .rp.frame1.stop \
	.rp.frame1.next .rp.frame1.fore \
	-side left -padx 6 -pady 6
    
    frame .rp.frame2 -relief flat -bd 2
    pack .rp.frame2 -side top -fill x -expand true
    
    frame .rp.frame2.f1 
    pack .rp.frame2.f1 -side top -fill x -expand true
    
    label .rp.frame2.f1.dir -text "Current run:   " -anchor w
    label .rp.frame2.f1.name -textvariable ws_stat(current_run) -anchor w
    
    pack .rp.frame2.f1.dir .rp.frame2.f1.name -side left
    
    
    frame .rp.frame2.f2 
    pack .rp.frame2.f2 -side top -fill x -expand true
    label .rp.frame2.f2.current -text "Current frame: " -anchor w
    entry .rp.frame2.f2.frameno -textvariable ws_stat(current_frame) \
	-width 5 -state disabled
    label .rp.frame2.f2.numframes -text "out of $ws_stat(num_frames)"
    button .rp.frame2.f2.b -text "Exit" \
	-command { exit_replay }

    pack .rp.frame2.f2.current .rp.frame2.f2.frameno \
	.rp.frame2.f2.numframes -side left
    pack .rp.frame2.f2.b -side right
   
    tkwait window .rp
}

# ****************************************************************************
#
#  proc exit_replay { }
#  
# ****************************************************************************
proc exit_replay { } { 

   if {[winfo exists .rp]} {destroy .rp}
}

# ****************************************************************************
#
#  proc kill_replay { }
#  
# ****************************************************************************
proc kill_replay { } { 
    
    global wsReplay ws_stat
    
    set wsReplay(animated) "False"
    set ws_stat(replay) 0
    data_cleanup
}

# ****************************************************************************
#
#  proc ws_replayDisplay { }
#  
# ****************************************************************************
proc  ws_replayDisplay {} {

    global wsReplay ws_stat ws_ReplayStat ws_results

    set array_list $ws_ReplayStat(array_list)
    set rundir $ws_ReplayStat(run_dir)
 
    if {![winfo exists .rp]} { exit_replay }
   
    switch $wsReplay(Direction) {

	Backward -

	Prev {

	    ws_PrevFrame 

	}

	Forward -

	Next {

	    ws_NextFrame 

	}

    }

    # display the images


    if { $wsReplay(Direction) == "Stop" } {

	set wsReplay(frame) $ws_stat(current_frame)

    } else {

	update
    }

    set frame_num [fix_fnum $ws_stat(current_frame)]
    foreach arr $array_list {
	set len [string length $arr]
	set nlen [expr $len - 2]
	set arr_name [string range $arr 0 $nlen]
	a.load $rundir/$arr/$frame_num = ws_results($arr_name)
	
    }

    put_arrays $ws_stat(redisplay_data) $ws_stat(current_frame) 

    # Stop or wrap around if reached the last frame 

    set wsReplay(wrap) "No"
    set lastflg "Yes"

    if { $wsReplay(Direction) == "Forward" } {

	if {$ws_stat(current_frame) < $ws_stat(num_frames)} {
	    
	    set lastflg "No"
	    
	}
	
    } elseif { $wsReplay(Direction) == "Backward" } {
	
	if {$ws_stat(current_frame) > 1} {
	    
	    set lastflg "No"
	    
	}
	
    }
	
    if { ($lastflg == "Yes") && \
	     ( ($wsReplay(Direction) == "Backward") ||
	       ($wsReplay(Direction) == "Forward" ) ) } { 

	if { $wsReplay(wrap) == "Yes" } {
	    
	    set wsReplay(Direction) "Stop" 
	    
	    set wsReplay(animated) "False" 
	    
	}

    }

}


#---------------------------------------------------------------------------
#
# proc ws_replayRedisplay
#
#---------------------------------------------------------------------------
proc ws_replayRedisplay { } {

    global wsReplay ws_stat ws_ReplayStat ws_results

    ws_replayDisplay

    set wsReplay(wrap) "No"

    while { $wsReplay(animated) == "True" }  { 

    	if {![winfo exists .rp]} { exit_replay }

	if { $wsReplay(wrap) == "No" } {
 
	    set wrapFlg  "Yes"

	    if { $wsReplay(Direction) == "Forward" } {


		if {$ws_stat(current_frame) < \
			$ws_stat(num_frames)} {
		    
		    set wrapFlg "No"
		    
		}

		if { $wrapFlg == "Yes" } {

		    set $ws_stat(current_frame) \
			[expr $ws_stat(current_frame) - 1 ]
		    
		}


	    } elseif { $wsReplay(Direction) == "Backward" } {

		if {$ws_stat(current_frame) > 1} {
		    
		    set wrapFlg "No"
		    
		}
		
		if { $wrapFlg == "Yes" } {
		    
		    set $ws_stat(current_frame) \
			[expr $ws_stat(num_frames) + 1 ]
		    
		}
	    }
	
	}
	
	ws_replayDisplay 
    
    }
    
    update

}


#---------------------------------------------------------------------------
# proc ws_NextFrame
#
# Compute the next frame number by incrementing the frame count
#
#---------------------------------------------------------------------------

proc ws_NextFrame {} \
{
    global ws_stat ws_ReplayStat

    set new_value [expr $ws_stat(current_frame) + 1]

    if { $new_value > $ws_stat(num_frames) } {
	set ws_stat(current_frame) 1
    } else {
        set ws_stat(current_frame) $new_value 
    }

}

#---------------------------------------------------------------------------
# proc ws_PrevFrame
#
# Compute the previous frame number by decrementing the frame count
#
#---------------------------------------------------------------------------


proc ws_PrevFrame {} \
{
    global ws_stat ws_ReplayStat

    set new_value [expr $ws_stat(current_frame) - 1]

    if { $new_value < 1 } {
	set ws_stat(current_frame) $ws_stat(num_frames)
    } else {
        set ws_stat(current_frame) $new_value 
    }

}
