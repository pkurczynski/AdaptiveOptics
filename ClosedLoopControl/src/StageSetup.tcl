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
# FILE: StageSetup.tcl
# 
# DESCRIPTION:	
#   
# 
# $Id: StageSetup.tcl,v 1.34 2000/09/19 21:20:03 herb Exp $
#
#--------------------------------------------------------------------------


###########################################################################
#				  GLOBALS
###########################################################################
if { $platform == "windows" } {
    set aos_stageport "com1"
} else { 
    set aos_stageport "/dev/ttyS0"
}
set aos_stagepos 0
set aos_stagemoving 0
set aos_stageanimate 0

set aos_stagevelocity 2000
set aos_stagemaxvelocity 4000
set aos_stagetopspeed 5000


#--------------------------------------------------------------------------
# proc hardware_init
#
# Tries to initialize the stage and camera.  Returns 0 on success, and sets
# hw_flg to "TRUE".  Returns 1 on failure, but does not modify hw_flg.
#--------------------------------------------------------------------------

proc hardware_init { } {

  global aos_stageinit aos_camerainit
  global aos_stageport hw_flg


  if { $aos_stageinit == 0 }  {

    # Open connection to serial port
    #
    stage.init $aos_stageport
	
    # Verify the hardware connection
    #
    if { [verify_connection] == 1 } { 
      return 1
    }

    # Verify the stage variables
    #
    stage_verify

    # Set the origin
    #
    stage_set_limit_b_origin

    set aos_stageinit 1
  }

  if { $aos_camerainit == 0 } {
    set aos_camerainit 1
  } 
  set hw_flg "TRUE"
}


proc stage_window { } {
    global aos_stagepos
    global aos_stageanimate wlPanel

    set aos_stagepos [stage.get.position]

    toplevel .stagewin
    wm title .stagewin "Stage Control"
    if {[info exist wlPanel(midWinGeometry)]} {

	wm geometry .stagewin $wlPanel(midWinGeometry)

    } 

    frame .stagewin.top -relief flat 
    frame .stagewin.bot -relief ridge -bd 2

    # Initialization

    frame .stagewin.top.init -relief ridge -bd 2
    button .stagewin.top.init.init -text "Reinitialize Stage" \
	-command {stage.do " "}
    button .stagewin.top.init.recal -text "Recalibrate Stage" \
	-command stage_calibrate
    button .stagewin.top.init.zero -text "Set Zero Position" \
	-command stage_set_zero

    pack .stagewin.top.init.init .stagewin.top.init.recal \
	.stagewin.top.init.zero -side left -fill x

    # Move stage at velocity

    frame .stagewin.top.velocity -relief ridge -bd 2

    # cartoon

    if {$aos_stageanimate!=0} {
	canvas .stagewin.top.velocity.canvas -width 12c -height 4c -relief flat
	.stagewin.top.velocity.canvas create line 1c 3c 11c 3c
	drawcam .stagewin.top.velocity.canvas $aos_stagepos
    }

    # text

    frame .stagewin.top.velocity.pos
    label .stagewin.top.velocity.pos.lbl -text "Current position:"
    label .stagewin.top.velocity.pos.pos -textvariable aos_stagepos

    pack .stagewin.top.velocity.pos.lbl .stagewin.top.velocity.pos.pos \
	-side left

    # tape-deck control

    frame .stagewin.top.velocity.move -relief flat

    label .stagewin.top.velocity.move.left4 -text "Forward"
    button .stagewin.top.velocity.move.left1 -text "<" \
	-command {if {$aos_stagemoving == 0} {stage_move_at_velocity -3000} }
    button .stagewin.top.velocity.move.stop -text "Stop" \
	-command "stage_stop"
    button .stagewin.top.velocity.move.right1 -text ">" \
	-command {if {$aos_stagemoving == 0} {stage_move_at_velocity 3000} }
    
    label .stagewin.top.velocity.move.right4 -text "Back"

    pack .stagewin.top.velocity.move.left4  \
	.stagewin.top.velocity.move.left1 .stagewin.top.velocity.move.stop \
	.stagewin.top.velocity.move.right1 \
	.stagewin.top.velocity.move.right4 \
	-side left -pady 1m 

    if {$aos_stageanimate!=0} {
	pack .stagewin.top.velocity.canvas -side top
    }

    pack .stagewin.top.velocity.pos -side top
    pack .stagewin.top.velocity.move -side top

    # Move stage

    frame .stagewin.top.move -relief flat

    # Move stage absolute

    frame .stagewin.top.move.absolute -relief ridge -bd 2

    label .stagewin.top.move.absolute.head -text \
	"Move stage to absolute position"
    label .stagewin.top.move.absolute.label -text "Move to: "
    entry .stagewin.top.move.absolute.entry -width 10 -relief sunken -bd 2
    button .stagewin.top.move.absolute.go -text "Move" \
	-command "stage_do_move_absolute .stagewin.top.move.absolute.entry"

    pack .stagewin.top.move.absolute.head -side top
    pack .stagewin.top.move.absolute.label .stagewin.top.move.absolute.entry \
	.stagewin.top.move.absolute.go -side left -padx 2m -pady 1m

    # Move stage relative

    frame .stagewin.top.move.relative -relief ridge -bd 2

    label .stagewin.top.move.relative.head -text \
	"Move stage to relative position"
    label .stagewin.top.move.relative.label -text "Move to: "
    entry .stagewin.top.move.relative.entry -width 10 -relief sunken -bd 2
    button .stagewin.top.move.relative.go -text "Move" \
	-command "stage_do_move_relative .stagewin.top.move.relative.entry"

    pack .stagewin.top.move.relative.head -side top
    pack .stagewin.top.move.relative.label .stagewin.top.move.relative.entry \
	.stagewin.top.move.relative.go -side left -padx 2m -pady 1m

    pack .stagewin.top.move.absolute .stagewin.top.move.relative -side left

    pack .stagewin.top.init .stagewin.top.velocity .stagewin.top.move \
	-side top -fill x
    
    # Bottom buttons

    frame .stagewin.bot.frame -relief flat

    button .stagewin.bot.frame.close -text "Close Window" \
	-command "destroy .stagewin"
    
    pack .stagewin.bot.frame.close -side top -fill x
    pack .stagewin.bot.frame -side top -fill x

    pack .stagewin.top .stagewin.bot -side top -fill x
}

   
proc chkPos { delay } {
    global aos_stagemoving
    global aos_stagepos

    if {$aos_stagemoving!=0} {
	set aos_stagepos [stage.get.position]
	after $delay [list chkPos $delay]
    } else {
	set aos_stagepos [stage.get.position]
	if {[winfo exist .stagewin]} { 
	    .stagewin.top.velocity.move.left1 config -state normal
	    .stagewin.top.velocity.move.right1 config -state normal
	}
    }
}
    
proc stage_set_zero { } {
    global aos_stagepos

    stage.do O
    set aos_stagepos [stage.get.position]
}

#---------------------------------------------------------------------------
##TCLAPI
## 
## PROCEDURE:	
## 
## 	stage_verify
## 
## ARGUMENTS:	
## 
## 	NONE
## 
## 
## RETURN:	
## 
## 	NONE
## 
## DESCRIPTION:	
## 
## 	Grabs the current parameters and extracts the current and velocity.
## 	If the holding/run currents are incorrect, it resets the current
##  	and velocity and stores those values.  If the velocity is not at
##	the default value it set the velocity and stores that value.  The
## 	limit polarity is always switched.
## 
##---------------------------------------------------------------------------
proc stage_verify { } { 

    global stageParams
    #global aos_stagetopspeed aos_stagevelocity

    set aos_stagestore 0

    set parms [ stage.do X ]
    for { set i 0 } { $i < [llength [split $parms]] } { incr i } { 
	if { [lindex [ split $parms ] $i] == "Y=" } {
		set current [lindex [split $parms] [expr $i + 1]]
	}  
	if { [lindex [ split $parms ] $i] == "V=" } { 
		set velocity [lindex [split $parms]  [expr $i + 1]]
	}
    }

    if { [lindex [split $current /] 0 ] != 0 ||  [lindex [split $current /] 1 ] != 75 } {
	stage.do "Y 0 75"
	stage.do "V $stageParams(aveVelocity)"
	set aos_stagestore 1
    }
 
    if { $velocity > $stageParams(hiVelocityLimit) || \
	     $velocity < $stageParams(lowVelocityLimit) } { 
	stage.do "V $stageParams(aveVelocity)"
	set aos_stagestore 1
    }

    stage.do { l 1 }

    if { $aos_stagestore == 1 } {
	stage.do S
    }
    
   
}

#---------------------------------------------------------------------------
##TCLAPI
## 
## PROCEDURE:	
## 
## 	stage_init
## 
## ARGUMENTS:	
## 
## 	NONE
## 
## 
## RETURN:	
## 
## 	NONE
## 
## DESCRIPTION:	
##
##	Stage_init should be run the first time the IMS is used to:
## 	set hold/run current
##	invert limit switch polarity
## 	set slew speed
## 	store parameters
## 
##---------------------------------------------------------------------------

proc stage_init { } {
    global stageParams
    #global aos_stagevelocity

    stage.do "Y 0 75"
    stage.do "l 1"
    stage.do "V $stageParams(aveVelocity)"
    stage.do S 
}

#---------------------------------------------------------------------------
##TCLAPI
## 
## PROCEDURE:	
## 
## 	stage_set_limit_b_origin
## 
## ARGUMENTS:	
## 
## 	NONE
## 
## 
## RETURN:	
## 
## 	NONE
## 
## DESCRIPTION:	
## 
## 	Stage_set_limit_b_origin is used to set the origin to limit B
## 	which is on the motor side.
## 
## 
## 
##---------------------------------------------------------------------------

proc stage_set_limit_b_origin { } {
    
    global stageParams
    #global aos_stagevelocity aos_stagemaxvelocity

    # add in stage command to move stage +1000 before moving -12000
    # check to see if we need wait for stage to stop moving

    stage.do "V $stageParams(maxVelocity)"
    stage.do "+1000"
    set moving [stage.get.moving]
    while { $moving!=0 } {
        set moving [stage.get.moving]
    }
    stage.do "-12000"
    set moving [stage.get.moving]
    while { $moving!=0 } {
        set moving [stage.get.moving]
    }

    stage.do "+500"
    set moving [stage.get.moving]
    while { $moving!=0 } {
        set moving [stage.get.moving]
    }
    stage.do "V 200"
    stage.do "-550"
    set moving [stage.get.moving]
    while { $moving!=0 } {
        set moving [stage.get.moving]
    }
    stage.do "V $stageParams(aveVelocity)"
    stage.do O

  
}

proc stage_calibrate { } {
    stage_move_at_velocity -3000
    set moving [stage.get.moving]
    while { $moving!=0 } {
        set moving [stage.get.moving]
    }
    stage.do @
    stage.do f1
    stage.do O
}

proc stage_do_move_relative { textw } {
    global aos_stagepos

    set param [$textw get]
    stage.move.relative $param
    set moving [stage.get.moving]
    while { $moving==1 } {
    	set moving [stage.get.moving]
	set aos_stagepos [stage.get.position]
    }
    set aos_stagepos [stage.get.position]
}


# ****************************************************************************
#  stage_do_move_absolute
#
# ****************************************************************************

proc stage_do_move_absolute { textw } {
    global aos_stagepos

    set param [$textw get]
    stage.move.absolute $param
    set moving [stage.get.moving]
    while { $moving==1 } {
    	set moving [stage.get.moving]
	set aos_stagepos [stage.get.position]
    }
    set aos_stagepos [stage.get.position]
}


# ****************************************************************************
#  stage_move_at_velocity
#
# ****************************************************************************

proc stage_move_at_velocity { val } {
    global aos_stagemoving

    set reply [stage.move.velocity $val]
    set aos_stagemoving 1
    if {[winfo exist .stagewin]} {
	.stagewin.top.velocity.move.left1 config -state disabled
	.stagewin.top.velocity.move.right1 config -state disabled
    }
    chkPos 500
}


# ****************************************************************************
#  stage_stop
#
# ****************************************************************************

proc stage_stop { } {
    global aos_stagemoving
    global aos_stagepos

    stage.stop
    set aos_stagemoving 0
    set aos_stagepos [stage.get.position]
}

# ****************************************************************************
#  stageshell
#
# ****************************************************************************

proc stageshell {} {
    toplevel .stage
    wm title .stage "Stage Command Shell"
    frame .stage.top -relief ridge -bd 2 -width 15c -height 10c
    frame .stage.bot -relief ridge -bd 2

    pack .stage.top .stage.bot  -side top -fill x

    text .stage.top.text -relief flat -yscrollcommand ".stage.top.scroll set"
    scrollbar .stage.top.scroll -command ".stage.top.text yview"

    pack .stage.top.scroll -side right -fill y
    pack .stage.top.text -side left -fill x 

    bind .stage.top.text <KeyPress-Return> { send_shell_cmd .stage.top.text }
    button .stage.bot.close -text Close -command "close_stageshell .stage"
    button .stage.bot.iconify -text Iconify -command "wm iconify .stage"

    pack .stage.bot.close -side left -padx 20m -pady 2m
    pack .stage.bot.iconify -side right -padx 20m -pady 2m
}



# ****************************************************************************
#  send_shell_cmd
#
# ****************************************************************************

proc send_shell_cmd { textw } {
    scan [$textw index end] "%d" thisrow
    set last [expr $thisrow-1].0
    set cmd [$textw get $last "$last lineend"]
    set tmp [stage.do $cmd]
    set reply [string trim $tmp "\r"]
    $textw insert end "\n$reply"
}


# ****************************************************************************
#  close_stageshell
#
# ****************************************************************************

proc close_stageshell win {
#    rtmain_msg "Closed stage command shell...\n"
    destroy $win
}


#---------------------------------------------------------------------------
# proc camera_exposure
# 
# Determines the current exposure and increments of decrements on
# the users command
#---------------------------------------------------------------------------

proc camera_exposure { dir name } {

    global wsdb DisplayFlag
    
    #
    # Read the value on the port currently
    #
    set port [ stage.read.port ]

    #
    # Extract the level of the camera
    #
    for { set i 2 } { $i < [llength [split $port]] } { incr i } { 
	if { [lindex [split $port] $i] >= 0 } {
	    set level [lindex [split $port] $i]
	}
    }

    #
    # Mask out the input bits
    #
    set val [ expr 56 & $level]

    #
    # Increment or decrement the exposure but do not wrap around 
    #
    if { $dir == "shorter" } {
	if { $val == 56 } {
	    set expose 56
	} else {
	    set expose [ expr $val + 8 ]
	}
    } else {
	if { $val == 0 } {
	    set expose 0
	} else {
	    set expose [ expr $val - 8 ]
	}
    }

    #
    # Send new value to camera
    #
    stage.write.port $expose

    # set exposure and redisplay exposure rate
    set exposureList [alignInterface:getExposureList]
    set wsdb($name) [ lindex $exposureList [current_exposure] ]
    if { [winfo exists .adj] } {
	.adj.control.time configure -text "$wsdb($name) sec" 
    }
    update

    if { $DisplayFlag == 1 } { ttCalibrateDisplay }
}

proc current_exposure { } { 
    #
    # Read the value on the port currently
    #
    set port [ stage.read.port ]

    #
    # Extract the level of the camera
    #
    for { set i 2 } { $i < [llength [split $port]] } { incr i } { 
	if { [lindex [split $port] $i] >= 0 } {
	    set level [lindex [split $port] $i]
	}
    }

    #
    # Mask out the input bits
    #
    set val [ expr 56 & $level]

    set vvv [ expr $val >> 3]

    return $vvv

}

proc send_camera_exposure { index } {

    set exposure [ expr $index << 3 ]
    stage.write.port $exposure

}


#--------------------------------------------------------------------------
# proc verify_connection
# 
# Verifies if the connection between the power supply and the sensor
# head has been made.  Returns 0 on success, 1 on failure.
#--------------------------------------------------------------------------

proc verify_connection { } {

  global aos_stageport wlPanel platform
    

  # Read the value currently on the port
  #
  set port [ stage.read.port ]
    
  if { $port == "" } { 
    set msg "Hardware Initialization Failed\n\nVerify that the controller is on and connected to COM1.\n\nClick OK to try again or Cancel to run without hardware."
	
    if { [wl_PanelsContinueAbort $msg +300+85 10c] == "Continue" } {  
      stage.shut
      stage.init $aos_stageport
      set port [ stage.read.port ]
    } 
  }
 

  # Extract the status of the input ports
  #
  if { $port == "" } {
    return 1
  }
 
  for { set i 2 } { $i < [llength [split $port]] } { incr i } { 
    if { [lindex [split $port] $i] >= 0 } {
      set level [lindex [split $port] $i]
    }
  }


  # Mask out the output bits
  #
  set val [ expr 7 & $level]

  if { $val != 6 } {
    set msg "Sensor Head Not Connected\n\nTurn the controller off before making the connection.\n\nClick OK to try again or Cancel to run without hardware."

    if { [wl_PanelsContinueAbort $msg +300+85 10c] == "Continue" } {
      stage.shut
      stage.init $aos_stageport
      set port [ stage.read.port ]
     } else {
      return 1
    }
  }

  return 0	    
}
