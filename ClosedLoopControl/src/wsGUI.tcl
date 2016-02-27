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
# FILE: wsGUI.tcl
# 
# DESCRIPTION:	
#   The main WaveScope GUI - menu bar and command buttons
#   NOTE:  This is version 1.  Modified 9/17/2003 plk.
# $Id: wsGUI.tcl,v 1.82 2000/07/14 15:19:22 herb Exp $
# 
#--------------------------------------------------------------------------


set capType   screen
set capOutput printer
set capForm   jpg
set fileName  default.$capForm


#--------------------------------------------------------------------------
# proc WaveScope:popup
# 
# Display the WaveScope Production Mode graphical control panel. 
# If the panel is already being displayed then this should move 
# the window to the top of the stack.
#--------------------------------------------------------------------------

proc WaveScope:popup { {mode init} } {

  global ws_stat aos_stageinit aos_camerainit hw_flg new_mode platform


  # If a window exists with our window name, delete it.
  #
  if { [winfo exists .wsBar] } { destroy .wsBar }

  if { $mode == "init" } {
    # Initialize some parameters
    #
    ws_Init
    set ws_stat(mode) Production
    set ws_stat(current_test) ""
    set ws_stat(new_test) False
    set new_mode "no"
 
    # Chromerics setup
    #set_default
    #make_auto_panel

    if { $platform == "windows" } { 
      console hide
    }
  }
    
  # Build the GUI
  #
  toplevel .wsBar
  if { $platform == "windows" } {
    set width  [expr [winfo screenwidth .wsBar] - 100]
    set height 78
    set offset 50
    bind .wsBar <Destroy> { if {"%W" == ".wsBar"} { WaveScope:kill } }
  } else { 
    wm overrideredirect .wsBar 1
    set width  [winfo screenwidth .wsBar]
    set height [winfo screenheight .wsBar]
    set offset 0
  }

  wm geometry .wsBar  ${width}x${height}+${offset}+0

  frame .wsBar.frame
  frame .wsBar.logos -relief groove -bd 2 -background white

  pack  .wsBar.frame .wsBar.logos -fill x -side top -anchor n

  menubutton .wsBar.frame.file  -text " Test " -menu .wsBar.frame.file.menu
  menubutton .wsBar.frame.mode  -text " Mode " -menu .wsBar.frame.mode.menu
  menubutton .wsBar.frame.mlm   -text " MLM "  -menu .wsBar.frame.mlm.menu
  menubutton .wsBar.frame.align -text "Alignment" \
                 -menu .wsBar.frame.align.menu -state disabled
  menubutton .wsBar.frame.calibrate -text "Calibration" \
                 -menu .wsBar.frame.calibrate.menu -state disabled
  menubutton .wsBar.frame.execute -text "Execute" \
                 -menu .wsBar.frame.execute.menu
  menubutton .wsBar.frame.data  -text " Data " -menu .wsBar.frame.data.menu
  menubutton .wsBar.frame.print -text "Print"  -menu .wsBar.frame.print.menu
  menubutton .wsBar.frame.misc  -text "Misc"   -menu .wsBar.frame.misc.menu
  menubutton .wsBar.frame.help  -text "Help"   -menu .wsBar.frame.help.menu

  pack .wsBar.frame.file .wsBar.frame.mode .wsBar.frame.mlm \
         .wsBar.frame.align .wsBar.frame.calibrate .wsBar.frame.execute \
         .wsBar.frame.data -side left -padx 7

  pack .wsBar.frame.help .wsBar.frame.misc .wsBar.frame.print -side right \
         -padx 7
    
  set test_menu .wsBar.frame.file.menu
  menu $test_menu -tearoff 0
    
  $test_menu add command -label "New..." -state disabled  -command { new_test }
  $test_menu add command -label "Open..." -command { open_test }
  $test_menu add command -label "Reopen" -command { reset_displays }
  $test_menu add command -label "Save" \
      -state disabled -command { save_test False }
  $test_menu add command -label "Close" -command { remove_displays }
  $test_menu add command -label "Delete..." \
      -state disabled -command { ws_data_manager Test }
  $test_menu add separator

  if ![string compare $platform "windows" ] {
    $test_menu add command -label "Archive" -command {data_manager archive}
    $test_menu add command -label "Restore" -command {data_manager restore}
  } else {
    $test_menu add cascade -label "Archive to" -menu $test_menu.sub1
    set test_sub1 [menu $test_menu.sub1 -tearoff 0]
    $test_sub1 add command -label "Floppy..." \
	-command { data_manager archive floppy }
    $test_sub1 add command -label "Jaz..." -command {data_manager archive jaz}
    $test_sub1 add command -label "Zip..." -command {data_manager archive zip}

    $test_menu add cascade -label "Restore from" -menu $test_menu.sub2
    set test_sub2 [menu $test_menu.sub2 -tearoff 0]
    $test_sub2 add command -label "Floppy..." \
	-command { data_manager restore floppy }
    $test_sub2 add command -label "Jaz..." -command {data_manager restore jaz}
    $test_sub2 add command -label "Zip..." -command {data_manager restore zip}
  }

  $test_menu add separator
  #=========================================================================
  # these lines added for DM compatibility according to notes from Herb
  # Da Silva, AOA.  Dummy command used as template.
  # plk 9/17/2003
  # Extended to 1k devices hdyson@lucent.com; 25th May 04
  #=========================================================================
  $test_menu add command -label "BMC 140 DM Panel" -command { dm_panel }
  $test_menu add separator
  $test_menu add command -label "Membrane 256 DM Panel" -command { mdm_panel }
  $test_menu add separator
  $test_menu add command -label "BMC 1024 DM Panel" -command { dm1k_panel }
  $test_menu add separator
  $test_menu add command -label "Membrane 1024 DM Panel" -command { mdm1k_panel }
  $test_menu add separator
  
  if ![string compare $platform "windows" ] {
    $test_menu add command -label "Exit" -command { WaveScope:exit Exit }
  } else {
    $test_menu add cascade -label "Exit" -menu $test_menu.sub3
    set test_sub3 [menu $test_menu.sub3 -tearoff 0]
    $test_sub3 add command -label "Session Logout" \
	-command { WaveScope:exit Logout }
    $test_sub3 add command -label "System Shutdown" \
	-command { WaveScope:exit Shutdown }
  }

  set mode_menu .wsBar.frame.mode.menu
    
  menu .wsBar.frame.mode.menu -tearoff 0
    
  .wsBar.frame.mode.menu add command -label "Production" \
      -command { SwitchMenuBar Production }
  .wsBar.frame.mode.menu add cascade -label "Supervisor" \
      -menu $mode_menu.super
  .wsBar.frame.mode.menu add cascade -label "Expert" -menu $mode_menu.expert
  set sub1 [menu $mode_menu.super -tearoff 0]
  set sub2 [menu $mode_menu.expert -tearoff 0]
  $sub1 add command -label "Set Mode..."     -command {check_pw Supervisor No}
  $sub1 add command -label "Change Password" -command {check_pw Supervisor Yes}
  $sub2 add command -label "Set Mode..."     -command {check_pw Expert No}
  $sub2 add command -label "Change Password" -command {check_pw Expert Yes}
    
  set mlm_menu .wsBar.frame.mlm.menu
  menu $mlm_menu -tearoff 0
  $mlm_menu add command -label "Select" -command { SelectMLM }
  $mlm_menu add command -label "Add New..." -command { AddMLM }
  $mlm_menu add command -label "Delete..." -command { delete_MLM }
    
  set align_menu .wsBar.frame.align.menu
  menu $align_menu -tearoff 0
  $align_menu add command -label "Basic" -command { assistedAlignment }
  $align_menu add command -label "Manual..." -command { manualAlignment }
  $align_menu add separator
  $align_menu add command -label "Measured Tip/Tilt" -command { ActiveAl }
  $align_menu add command -label "Measured Pupil" -command { AsPup }
    
  set calibrate_menu .wsBar.frame.calibrate.menu
  menu $calibrate_menu -tearoff 0
  $calibrate_menu add command -label "Full..." -command { Calibrate full }
  $calibrate_menu add command -label "Custom..." -command { Calibrate custom }
  $calibrate_menu add separator
  $calibrate_menu add command -label "Change Parameters..." \
      -command { ParamsCalSetup }

  set test_menu1 .wsBar.frame.execute.menu
  menu $test_menu1 -tearoff 0
  $test_menu1 add command -label "Live Display" \
      -command { set ws_stat(re_reduce) 0; setup_test "Live" }
  $test_menu1 add command -label "Run/Save" \
      -command { set ws_stat(re_reduce) 0; setup_test "Save"  } 
  $test_menu1 add command -label "Poke Sequence" \
      -command { set ws_stat(re_reduce) 0; setup_test "Poke"  }
  $test_menu1 add command -label "Spatial Frequency Sequence" \
      -command { set ws_stat(re_reduce) 0; setup_test "Freq"  }
  $test_menu1 add separator
  $test_menu1 add command -label "Change Parameters..." \
      -command { ParametersSetup }
  $test_menu1 add command -label "Set Frame Capture..." \
      -command { ChangeFrames }
  $test_menu1 add command -label "Change Spot Exposure" \
      -command { set_test_spot_exposure }
    
  set data_menu .wsBar.frame.data.menu
  menu $data_menu -tearoff 0
  $data_menu add command -label "Redisplay" -command { retrieve_data }
  $data_menu add command -label "Re-reduce..." \
      -command { set ws_stat(re_reduce) 1; setup_test "Reduce" }
  $data_menu add command -label "Custom Re-reduce..." \
      -command { set ws_stat(re_reduce) 1; setup_test "Reduce Custom"}
  $data_menu add command -label "Delete..." -command { ws_data_manager Data }

  menu .wsBar.frame.print.menu -tearoff 0
  if { $platform == "windows" } {
    .wsBar.frame.print.menu add command -label "Screen Capture..." \
        -command { WinScreenCapture }
  } else {
    .wsBar.frame.print.menu add command -label "Screen Capture..." \
        -command { LinScreenCapture }
    .wsBar.frame.print.menu add command -label "View Status/Cancel Print" \
        -command { CancelPrint }
  }
    
  menu .wsBar.frame.misc.menu -tearoff 0
  .wsBar.frame.misc.menu add command -label "Initialize Hardware" \
      -command { hardware_init }
  .wsBar.frame.misc.menu add separator
  .wsBar.frame.misc.menu add command -label "Update..." -command { Update }
    
  menu .wsBar.frame.help.menu -tearoff 0
  .wsBar.frame.help.menu add command -label "Contents" -command { Help }
  .wsBar.frame.help.menu add command -label "About" -command { HelpAbout }
  # For in-house use only!
  #
#  .wsBar.frame.help.menu add separator
#  if { $platform == "windows" } {
#    .wsBar.frame.help.menu add command -label "Action Request" \
    -command { HelpInit; exec $Help(reader) http://sapphire/create.html & }
#  } else {
#    .wsBar.frame.help.menu add command -label "Action Request" \
    -command { exec /usr/local/netscape/netscape http://sapphire/create.html & }
#  }

  tk_menuBar .wsBar.frame .wsBar.frame.file .wsBar.frame.mode \
      .wsBar.frame.mlm .wsBar.frame.data .wsBar.frame.print \
      .wsBar.frame.misc .wsBar.frame.help
  

  # Create a frame to hold current status info
  #
  frame .wsBar.logos.stat -background white

  # Show current mode information
  #
  frame .wsBar.logos.stat.curr_mode -background white
  label .wsBar.logos.stat.curr_mode.label -text "Current Mode:  " \
      -background white -foreground black
  label .wsBar.logos.stat.curr_mode.name -textvariable ws_stat(mode) \
      -background white -foreground black
  pack .wsBar.logos.stat.curr_mode.label \
      .wsBar.logos.stat.curr_mode.name -side left -anchor w

  pack .wsBar.logos.stat.curr_mode -side top

  # Show current test information
  #
  frame .wsBar.logos.stat.curr_test -background white
  label .wsBar.logos.stat.curr_test.label -text "Current Test:  " \
      -background white -foreground black
  label .wsBar.logos.stat.curr_test.name -textvariable ws_stat(current_test) \
      -background white -foreground black -font [alignInterface:getFont]
  pack .wsBar.logos.stat.curr_test.label \
      .wsBar.logos.stat.curr_test.name -side left -anchor w

  pack .wsBar.logos.stat.curr_mode .wsBar.logos.stat.curr_test \
      -side top -anchor w
  pack .wsBar.logos.stat -side left

  # Show AOA and WaveScope Logos
  #
  frame .wsBar.logos.aoa -background white
  set ws_stat(AOAlogo) [wl_FindLibFile "AOA_Blue.gif"]
  set ws_stat(WSlogo) [wl_FindLibFile "WaveScope_Blue.gif"]
  set AOAlogo [image create photo -palette 3/3/3 -file $ws_stat(AOAlogo)]
  label .wsBar.logos.aoa.pic -image $AOAlogo -background white
  frame .wsBar.logos.ws -background white
  set WSlogo [image create photo -palette 3/3/3 -file $ws_stat(WSlogo)]
  label .wsBar.logos.ws.pic -image $WSlogo -background white
  pack .wsBar.logos.aoa.pic
  pack .wsBar.logos.ws.pic
  pack .wsBar.logos.ws .wsBar.logos.aoa -side right
 
  if {$mode == "init"} {
    # Check disk space for test storage
    #
    CheckDiskSpace

    # Initialize hardware
    #
    set aos_stageinit 0
    set aos_camerainit 0
    if { $hw_flg == "TRUE" } { 
      hardware_init
    }
  }
}


#--------------------------------------------------------------------------
# proc WaveScope:exit
#
# Kills pseudo desktop .wsBar and WaveScope session
#--------------------------------------------------------------------------

proc WaveScope:exit {exit_mode} {

  global platform 


  if ![string compare [wl_PanelsYesNo "Continue with $exit_mode" +10+150] Yes] {

    if { $platform == "windows" } {
      set os "windows"
    } else {
      set os [exec uname]
    }

    remove_displays

    switch $exit_mode {
      Logout {
	if [winfo exists .wsBar] { destroy .wsBar }	

	if  ![string compare $os "Linux"] {
	  if [file exists /usr/dt/bin/dtaction] {
	    exec /usr/dt/bin/dtaction ExitSession
	  } else {
	    exit
	  }
	} else { 
	  puts "Good Bye!"
	  exit 
	}
      }

      Exit {
	if [winfo exists .wsBar] { destroy .wsBar }
	exit
      }

      Shutdown {
	if ![string compare $os "Linux"] {
	  if [winfo exists .wsBar] { destroy .wsBar } 
	  exec /usr/local/bin/shutDown 
	} else {
	  dialog "Shutdown not available for $os"
	  return
	}
      }
    }
  } else { return }
}


#--------------------------------------------------------------------------
# proc WaveScope:kill
#
# We get here if the user destroys the WaveScope menu bar.
#--------------------------------------------------------------------------

proc WaveScope:kill {} {

  global platform 


  if { $platform == "windows" } {
    set os "windows"
  } else {
    set os [exec uname]
  }

  remove_displays

  if  ![string compare $os "Linux"] {
    if [file exists /usr/dt/bin/dtaction] {
      exec /usr/dt/bin/dtaction ExitSession
    } else {
      exit
    }
  } else { 
    puts "Good Bye!"
    exit 
  }
}


#--------------------------------------------------------------------------
# proc SwitchMenuBar
#
# Changes the look of the main window and/or menu bar based on the mode.
#--------------------------------------------------------------------------

proc SwitchMenuBar { mode } {

  global ws_stat new_mode platform


  if { $platform == "windows" } {
    set width  [expr [winfo screenwidth .wsBar] - 100]
    set height 78
    set offset 50
  } else { 
    set width  [winfo screenwidth .wsBar]
    set height [winfo screenheight .wsBar]
    set offset 0
  }
  set ws_stat(mode) $mode

  set m .wsBar.frame
  if { ![string compare $mode "Production"] } {

    $m.file.menu entryconfigure 0 -state disabled
    $m.file.menu entryconfigure 3 -state disabled
    $m.file.menu entryconfigure 5 -state disabled
    $m.file.menu entryconfigure 7 -state disabled
    $m.file.menu entryconfigure 8 -state disabled
    $m.align configure -state disabled
    $m.calibrate configure -state disabled
	
    if { [winfo exists .wsBar] } {
      wm geometry .wsBar  ${width}x${height}+${offset}+0
    }
	
    raise .wsBar
    set new_mode "yes"
    if { ![string compare $platform "windows" ] } {
      console hide
    }
    reset_displays
	
  } elseif { ![string compare $mode "Supervisor"] } {
	
    if { [winfo exists .wsBar] } {
      wm geometry .wsBar  ${width}x${height}+${offset}+0
    }

    $m.file.menu entryconfigure 0 -state normal
    $m.file.menu entryconfigure 3 -state normal
    $m.file.menu entryconfigure 5 -state normal
    $m.file.menu entryconfigure 7 -state normal
    $m.file.menu entryconfigure 8 -state normal
    $m.align configure -state normal
    $m.calibrate configure -state normal

    raise .wsBar
    set new_mode "yes"
    if { ![string compare $platform "windows" ] } {
      console hide
    }
    reset_displays
	
  } elseif { ![string compare $mode "Expert"] } {

    if { [winfo exists .wsBar] } {
      set height 78
      wm geometry .wsBar  ${width}x${height}+${offset}+0
    }

    $m.file.menu entryconfigure 0 -state normal
    $m.file.menu entryconfigure 3 -state normal
    $m.file.menu entryconfigure 5 -state normal
    $m.file.menu entryconfigure 7 -state normal
    $m.file.menu entryconfigure 8 -state normal
    $m.align configure -state normal
    $m.calibrate configure -state normal

    set new_mode "no"
    if { ![string compare $platform "windows" ] } {
      console show
    }
  }
}


# ****************************************************************************
#
#  proc enter_val { msg type w title }
#  Puts up a window with a Enter message and an entry widget of width w.
#  The msg prompts the user for a specific variable entry.
#  If type is pw then entry shows an asterix (*) for each 
#  character entered.  The password entry can then be used for
#  comparison with the supervisor or expert mode passwords.
#  If type is not pw then the true characters are displayed in entry widget.
#
# ****************************************************************************

proc enter_val { msg type w title {geom 0} } {
    
    global prompt wlPanel wsRunInfo
    
    set prompt(result) ""

    if {[winfo exist .prompt]} {destroy .prompt}
    set f [toplevel .prompt]
    wm title .prompt $title
    if { $geom == 0 } {
      wm geometry .prompt +252+38
    } else {
      wm geometry .prompt $geom
    }

    if {![string compare $type "pw"]} {
	set showit *false
    } else {
	set showit ""
    }

    frame .prompt.top -relief flat 

    # Initialization

    label .prompt.top.label -text $msg
    if { $msg == "Enter New Run Name:" } {
	entry .prompt.top.entry -width $w  -show $showit \
	    -textvariable wsRunInfo(run_name) -relief sunken -bd 2
	set prompt(result) "O.k."
    } else { 
	entry .prompt.top.entry -width $w  -show $showit \
	    -textvariable prompt(result) -relief sunken -bd 2
    }
    pack .prompt.top.label .prompt.top.entry \
	-side left -padx 2m -pady 1m
    pack .prompt.top -side top -fill x

    set b [frame $f.buttons -bd 10]
    pack $f.buttons -side top -fill x
    button $b.ok -text "  OK  " -command {set prompt(ok) 1}
    button $b.cancel -text Cancel -command { set prompt(ok) 0 }
    pack $b.ok -side left
    pack $b.cancel -side right

    # Set up bindings for shortcuts.
    foreach w [list $f.top.entry $b.ok $b.cancel] {
	bindtags $w [list .prompt [winfo class $w] $w all]
    }
    bind .prompt <Alt-o> "focus $b.ok ; break"
    bind .prompt <Alt-c> "focus $b.cancel ; break"
    bind .prompt <Alt-Key> break
    bind .prompt <Return> {set prompt(ok) 1}
    bind .prompt <Control-c> {set prompt(ok) 0}
    focus $f.top.entry
    grab $f
    tkwait variable prompt(ok)
    grab release $f
    destroy $f
    if {$prompt(ok)} {
	return $prompt(result)
    } else {
	return {}
    }

}

# ****************************************************************************
#
#  proc check_pw { mode change }
#  Calls pw to ask user for mode password and compares to stored value.
#  If password is correct, sets new mode.
#  If change is set to "Yes" - calls change_pw rather than setting new mode.
#
# ****************************************************************************

proc check_pw { new_mode change } {

    global ws_pw prompt platform 

    if { ![string compare "Yes" $change] } {
	if { ![string compare "Supervisor" $new_mode] } {
	    set msg "Enter Current Supervisor password:"
	} elseif { ![string compare "Expert" $new_mode] } {
	    set msg "Enter Current Expert password:"
	}
    } else {
	if { ![string compare "Supervisor" $new_mode] } {
	    set msg "Enter Supervisor password:"
	} elseif { ![string compare "Expert" $new_mode] } {
	    set msg "Enter Expert password:"
	}
    }

    enter_val $msg pw 10 "Password Entry"
    
    if { $prompt(ok) } {
	    a.encryptcmp $ws_pw($new_mode) $prompt(result) = test
	if { $test == "TRUE" } {
	    if { ![string compare "Yes" $change] } {
		change_pw $new_mode
	    } else {
		SwitchMenuBar $new_mode
	    }
	} else {
	    wl_PanelsWarn "Incorrect $new_mode password - Please try again"
	}
    } else {
	return "Abort"
    }
    
}

# ****************************************************************************
#
#  proc change_pw { mode }
#  Put up a window with two label and entry widget pairs.
#  First label-entry pair prompts user to enter New Password.
#  Second label-entry pair prompts user to verify New Password.
#  When user puts password entrys in, entry shows an asterix (*) for each 
#  character entered.  The entry go into global variables
#  which can then be used for comparisons.
#
# ****************************************************************************

proc change_pw { mode } {
    
    global ws_pw prompt
    
    set prompt(new) ""
    set prompt(verify) ""

    if {[winfo exist .prompt]} {destroy .prompt}
    set f [toplevel .prompt]
    wm title .prompt "Change Password"
    wm geometry .prompt +252+38
    
    set pt [frame .prompt.top -relief flat]

    # Initialization

    set pair1 [frame $pt.pair1 -relief ridge -bd 2]
    label $pair1.label -text "Enter New  $mode Password:"
    entry $pair1.entry -width 10  -show *false \
	    -textvariable prompt(new) -relief sunken -bd 2 
    pack $pair1.label $pair1.entry \
	    -side left -padx 2m -pady 1m

    set pair2 [frame $pt.pair2 -relief ridge -bd 2]
    label $pair2.label -text "Verify New $mode Password:"
    entry $pair2.entry -width 10  -show *false \
	    -textvariable prompt(verify) -relief sunken -bd 2 
    pack $pair2.label $pair2.entry \
	    -side left -padx 2m -pady 1m

    pack $pair1 $pair2 -side top
    pack $pt -side top -fill x
    
    set b [frame $f.buttons -bd 10]
    pack $f.buttons -side top -fill x
    button $b.ok -text OK -command {set prompt(ok) 1} \
	-underline 0
    button $b.cancel -text Cancel \
	-command { set prompt(ok) 0 } -underline 0
    pack $b.ok -side left
    pack $b.cancel -side right

    # Set up bindings for shortcuts.
    foreach w [list $pair2.entry $b.ok $b.cancel] {
	bindtags $w [list .prompt [winfo class $w] $w all]
    }
    bind .prompt <Alt-o> "focus $b.ok ; break"
    bind .prompt <Alt-c> "focus $b.cancel ; break"
    bind .prompt <Alt-Key> break
    bind .prompt <Return> {set prompt(ok) 1}
    bind .prompt <Control-c> {set prompt(ok) 0}
    focus $pair1.entry
    grab $f
    tkwait variable prompt(ok)
    grab release $f
    destroy $f
    if {$prompt(ok)} {
	if { ![string compare $prompt(new) $prompt(verify)] } {
	    set_new $mode $prompt(new)
	} else {
	    wl_PanelsWarn "Incorrect Verification:  $mode Password Unchanged"
	}
    } else {
	return {}
    }

}

# ****************************************************************************
#
#  proc set_new { mode val }
#  Sets new val for specified mode
#
# ****************************************************************************

proc set_new { mode val } {

    global ws_pw LISTS_DIR

    a.encrypt $val = enc
    set ws_pw($mode) $enc

    wl_PanelsWarn "$mode Password Changed"

    # Here I have to write new password to file so it is changed for new 
    # sessions
    set file_out [open $LISTS_DIR/ws_pw.tcl w]
    foreach mode { Supervisor Expert } { 
	puts $file_out "set ws_pw($mode) $ws_pw($mode)"
    }
    close $file_out
}


#--------------------------------------------------------------------------
# proc LinScreenCapture
#
# For Linux, puts up a dialog box that allows the user to select how they
# want to perform their screen capture.
#--------------------------------------------------------------------------

proc LinScreenCapture { } {

  global platform capType capOutput capForm


  if { $platform == "windows" } { return }
  if { [winfo exist .capture] } { destroy .capture }

  toplevel    .capture 
  wm geometry .capture -20+80
  wm title    .capture "Screen Capture Options"

  frame       .capture.fr1 -relief groove -bd 2
  pack        .capture.fr1 -side top -padx 5 -pady 5 -fill x
  label       .capture.fr1.lab -text "Capture type:"
  radiobutton .capture.fr1.r1 -text "Whole Screen" -variable capType \
                -value screen -highlightthickness 0
  radiobutton .capture.fr1.r2 -text "One Window" -variable capType \
                -value window -highlightthickness 0
  pack        .capture.fr1.lab .capture.fr1.r1 .capture.fr1.r2 -side left \
                -padx 5 -pady 5 -anchor w

  frame       .capture.fr2 -relief groove -bd 2
  pack        .capture.fr2 -side top -padx 5 -pady 5 -fill x
  label       .capture.fr2.lab -text "Output to:"
  radiobutton .capture.fr2.r1 -text "Printer" -variable capOutput \
                -value printer -highlightthickness 0 -command { SetFileState }
  radiobutton .capture.fr2.r2 -text "File" -variable capOutput -value file \
                -highlightthickness 0 -command { SetFileState }
  pack        .capture.fr2.lab .capture.fr2.r1 .capture.fr2.r2 \
                -side left -padx 5 -pady 2

  frame       .capture.ff -relief groove -bd 2
  pack        .capture.ff -padx 5 -pady 5 -fill x
  frame       .capture.ff.fr3
  pack        .capture.ff.fr3 -side top -anchor w
  label       .capture.ff.fr3.lab -text "Format:"
  radiobutton .capture.ff.fr3.r2 -text "JPG" -variable capForm -value jpg \
                -highlightthickness 0 -command { FileType }
  radiobutton .capture.ff.fr3.r3 -text "GIF" -variable capForm -value gif \
                -highlightthickness 0 -command { FileType }
  radiobutton .capture.ff.fr3.r4 -text "TIFF" -variable capForm -value tiff \
                -highlightthickness 0 -command { FileType }
  radiobutton .capture.ff.fr3.r5 -text "FITS" -variable capForm -value fits \
                -highlightthickness 0 -command { FileType }
  radiobutton .capture.ff.fr3.r1 -text "PS" -variable capForm -value ps \
                -highlightthickness 0 -command { FileType }
  pack        .capture.ff.fr3.lab .capture.ff.fr3.r2 .capture.ff.fr3.r3 \
                .capture.ff.fr3.r4 .capture.ff.fr3.r5 .capture.ff.fr3.r1 \
                -side left -padx 5 -pady 2
  frame       .capture.ff.fr4
  pack        .capture.ff.fr4 -side top -anchor w
  label       .capture.ff.fr4.lab -text "Filename:"
  entry       .capture.ff.fr4.ent -textvariable fileName
  pack        .capture.ff.fr4.lab .capture.ff.fr4.ent -side left -padx 5 -pady 5
  SetFileState

  frame  .capture.bframe -relief flat 
  pack   .capture.bframe -side top
  button .capture.bframe.ok -text "  OK  " \
           -command { destroy .capture; LinCapture }
  button .capture.bframe.close -text "Cancel" -command { destroy .capture }
  pack   .capture.bframe.ok .capture.bframe.close -side left -padx 2m -pady 2m
  
  bind .capture <Destroy> { destroy .capture }
  
  tkwait window .capture
}


#--------------------------------------------------------------------------
# proc SetFileState
#
# Sets the state of the file-only options to the supplied state 'st'.
#--------------------------------------------------------------------------

proc SetFileState { } {

  global capOutput platform


  if { $platform == "windows" } { return }

  if { $capOutput == "file" } {
    set st normal
    set conf [ .capture.ff.fr3.r1 configure -fg ]
  } else {
    set st disabled
    set conf [ .capture.ff.fr3.r1 configure -disabledforeground ]
  }
  set col [ lindex [split $conf] end ]

  .capture.ff.fr3.r1 configure -state $st
  .capture.ff.fr3.r2 configure -state $st
  .capture.ff.fr3.r3 configure -state $st
  .capture.ff.fr3.r4 configure -state $st
  .capture.ff.fr3.r5 configure -state $st
  .capture.ff.fr4.ent configure -state $st
  .capture.ff.fr4.ent configure -fg $col
  .capture.ff.fr3.lab configure -fg $col
  .capture.ff.fr4.lab configure -fg $col
}


#--------------------------------------------------------------------------
# proc FileType
#
# When a new file type is selected, try to put the correct extension on
# the file name.
#--------------------------------------------------------------------------

proc FileType { } {

  global capForm fileName platform


  if { $platform == "windows" } { return }

  # Put the correct extension on the file.
  #
  set pos [string last "." $fileName]
  if { $pos == "-1" } {
    set new "$fileName."
  } else {
    set new [string range $fileName 0 $pos]
  }
  set f2 "$new$capForm"
  set fileName $f2
}


#--------------------------------------------------------------------------
# proc LinCapture
#
# For Linux, checks global variables to determine how to do the capture,
# then puts up an appropriate prompt, and does the capture.
#--------------------------------------------------------------------------

proc LinCapture { } {

  global platform capType capOutput capForm fileName env


  if { $platform == "windows" } { return }

  if {$capOutput == "file"} {
    # Construct the home path.  If for some reason we can't get the
    # environment variable HOME, set homePath to the empty string,
    # and the user will just have go find the file.
    #
    set p ""
    catch { set p "$env(HOME)/" }
    set homeP $p
    
    # Make sure the filename has a proper extension, or the converter
    # will balk.
    #
    FileType
  }

  # This is a little ugly, but basically it works like this:
  # If the user wants a printout or a PostScript file, we use
  # xgrabsc, otherwise we use xwd and convert the dump.
  #
  if {$capOutput == "printer"} {
    set p1 "Make sure the printer is ready."
  } else {
    set p1 "Capturing to: $homeP$fileName\n"
  }

  if {$capOutput == "printer" || $capForm == "ps"} {

    if {$capType == "screen"} {
      set type -root
      set prompt "$p1 Continue?"
    } else {
      set type -click
      set prompt "$p1 When the cursor changes to a bullseye, click in the window you want to capture.  Continue?"
    }

    if ![string compare [wl_PanelsYesNo $prompt -50+80 10c] Yes] {
      update
      if {$capOutput == "printer"} {
	exec xgrabsc -page 8.5x11.0-0.75-0.75 -bdrs $type -l -cps | lpr -PFinal
      } else {
	exec xgrabsc -page 8.5x11.0-0.75-0.75 -bdrs $type -l -cps > $homeP$fileName
      }
    }
  } else {
    # If we got here, then capOutput is "file" and capForm is NOT "ps"
    #
    if {$capType == "screen"} {
      set prompt "$p1 Continue?"
    } else {
      set prompt "$p1 When the cursor changes to a crosshair, click in the window you want to capture.  Continue?"
    }
    
    if ![string compare [wl_PanelsYesNo $prompt -50+80 12c] Yes] {
      update
      if {$capType == "screen"} {
	exec xwd -root > $homeP/ws.xwd
      } else {
	exec xwd -frame > $homeP/ws.xwd
      }
      set msg "Writing $homeP$fileName..."
      wl_PanelsWait .wait $msg -50+80 12c
      update
      exec /usr/aos/wavescope/bin/convert $homeP/ws.xwd $homeP$fileName
      if { [winfo exist .wait] } { destroy .wait }
      update
      exec /bin/rm -f $homeP/ws.xwd
    }
  }
}


#--------------------------------------------------------------------------
# proc CancelPrint
#
# For Linux, fetches the list of jobs in the queue (if any)
# and puts up another box to allow the user to cancel the job(s).
#--------------------------------------------------------------------------

proc CancelPrint { } {

  global platform queueStat


  if { $platform != "windows" } {
    set queueStat [exec lpq -PFinal]
    
    if { [winfo exist .queue] } { destroy .queue }

    toplevel .queue 
    wm geometry .queue -50+80
    wm title .queue "Printer Queue Status"

    set msg "If the job has started printing, canceling the job will not immediately stop the printer.  You must also turn the printer off to flush the printer's buffer.\nThis window does not update unless you press the Update or Cancel Last buttons."
    message .queue.msg -text $msg -width 25c
    frame .queue.frame1 -relief ridge -borderwidth 2
    pack .queue.msg .queue.frame1 -side top -fill x -padx 5 -pady 5
    
    message .queue.frame1.queue -textvariable queueStat -width 25c
    pack .queue.frame1.queue -side left -fill x -pady 5

    frame .queue.frame2 -relief flat 
    pack .queue.frame2 -side top
    
    button .queue.frame2.up -text "Update" \
            -command { set queueStat [exec lpq -PFinal] }
    button .queue.frame2.cl -text "Cancel Last" -command { CancelLast }
    button .queue.frame2.close -text "Close" -command { destroy .queue }
    pack .queue.frame2.up .queue.frame2.cl .queue.frame2.close \
           -side left -padx 2m -pady 2m

    bind .queue <Destroy> { destroy .queue }

    tkwait window .queue
  }
}


#--------------------------------------------------------------------------
# proc CancelLast
#
# For Linux, fetches the list of jobs in the queue (if any) and parses out
# the job number of the last job, then issues a command to cancel the job.
# When that's done, it fetches the list again to update the dialog box.
#--------------------------------------------------------------------------

proc CancelLast { } {

  global platform queueStat


  if { $platform != "windows" } {
    set queue [exec lpq -PFinal | tail -n 1]
    if { [string compare $queue "no entries"] != 0 } {
      scan $queue {%s %s %s} s n job
      catch [exec lprm -PFinal $job] result
    }
    set queueStat [exec lpq -PFinal]
  }
}


#--------------------------------------------------------------------------
# proc WinScreenCapture
#
# For Windows, puts up a dialog box that allows the user to select how they
# want to perform their screen capture.
#--------------------------------------------------------------------------

proc WinScreenCapture { } {

  global platform capType capOutput


  if { $platform != "windows" } { return }
  if { [winfo exist .capture] } { destroy .capture }

  toplevel    .capture 
  wm geometry .capture -50+80
  wm title    .capture "Screen Capture Options"

  frame       .capture.fr1 -relief groove -bd 2
  pack        .capture.fr1 -side top -padx 5 -pady 5 -fill x
  label       .capture.fr1.lab -text "Capture type:"
  radiobutton .capture.fr1.r1 -text "Whole Screen" -variable capType \
                -value screen -highlightthickness 0
  radiobutton .capture.fr1.r2 -text "One Window" -variable capType \
                -value window -highlightthickness 0
  pack        .capture.fr1.lab .capture.fr1.r1 .capture.fr1.r2 -side left \
                -padx 5 -pady 5 -anchor w

  frame       .capture.fr2 -relief groove -bd 2
  pack        .capture.fr2 -side top -padx 5 -pady 5 -fill x
  label       .capture.fr2.lab -text "Output to:"
  radiobutton .capture.fr2.r1 -text "Printer" -variable capOutput \
                -value printer -highlightthickness 0
  radiobutton .capture.fr2.r2 -text "File" -variable capOutput -value file \
                -highlightthickness 0
  pack        .capture.fr2.lab .capture.fr2.r1 .capture.fr2.r2 \
                -side left -padx 5 -pady 2

  frame  .capture.bframe -relief flat 
  pack   .capture.bframe -side top
  button .capture.bframe.ok -text "  OK  " \
           -command { destroy .capture; WinCapture }
  button .capture.bframe.close -text "Cancel" -command { destroy .capture }
  pack   .capture.bframe.ok .capture.bframe.close -side left -padx 2m -pady 2m
  
  bind .capture <Destroy> { destroy .capture }
  
  tkwait window .capture
}


#--------------------------------------------------------------------------
# proc WinCapture
#
# For Windows, checks global variables to determine how to do the capture,
# then puts up an appropriate prompt, and does the capture.
#--------------------------------------------------------------------------

proc WinCapture { } {

  global platform capType capOutput


  if { $platform != "windows" } { return }

  if {$capOutput == "file"} {
    # Prompt for capture to a file.
    #
    if {$capType == "screen"} {
      set prompt "After the screen is captured, a dialog will appear to allow the selection of a filename and file output type.  Continue?"
      if ![string compare [wl_PanelsYesNo $prompt -50+80 7c] Yes] {
	update
	exec /usr/aos/wavescope/bin/wingrab -oGIF &
      }
    } else {
      set prompt "Click OK in this dialog, then within 5 seconds, click in the window you want to capture.  After the window is captured, a dialog will appear to allow the selection of a filename and file output format.  Continue?"
      if ![string compare [wl_PanelsYesNo $prompt -50+80 7c] Yes] {
	update
        after 5000
	exec /usr/aos/wavescope/bin/wingrab -iLST -oGIF &
      }
    }
  } else {
    # If we got in here, then output is going straight to the printer.
    #
    if {$capType == "screen"} {
      set prompt "Make sure the printer is ready.  Continue?"
      if ![string compare [wl_PanelsYesNo $prompt -50+80 7c] Yes] {
	update
	exec /usr/aos/wavescope/bin/wingrab &
      }
    } else {
      set prompt "Make sure the printer is ready.  Click OK in this dialog, then within 5 seconds, click in the window you want to print.  Continue?"
      if ![string compare [wl_PanelsYesNo $prompt -50+80 7c] Yes] {
	update
        after 5000
	exec /usr/aos/wavescope/bin/wingrab -iLST &
      }
    }
  }
}


#--------------------------------------------------------------------------
# proc CheckDiskSpace
#
# Check disk usage of the partition where tests are stored.  If the disk
# is getting full, annoy the user with a message to clean up.
#--------------------------------------------------------------------------

proc CheckDiskSpace { } {

  global platform BASE_DATA_DIR


  if { $platform == "windows" } {

    # Windows returns disk size in bytes, rather than KBytes.  Disks
    # have gotten so big that the size of the disk overflows integer
    # storage.  So for Windows, the user gets no warning.  I'm leaving
    # the code in below the return, just in case integers get larger,
    # or Windows gets smarter (or pigs fly, or ...)
    #
    return

    set stats [exec CMD /C "DIR /-C C:\\wishrc.tcl"]
    set lstats [split $stats]
    set free [lindex $lstats [expr [llength $lstats] - 3]]

    if { $free < 20000000 } {
      set msg "The disk partition that stores your tests and saved data is nearly full.  You should archive and/or delete some older tests to prevent difficulty in saving new data."
      dialog $msg +20+120
    }
  } else {
    set stats [exec df $BASE_DATA_DIR | tail -n 1]
    scan $stats {%s %d %d %d %s %s} dev tot usd rem percStr nm
    scan $percStr {%d} perc

    if { $perc > 90 || $rem < 20000 } {
      set msg "The disk partition that stores your tests and saved data ($nm) is $percStr full.  You should archive and/or delete some older tests to prevent difficulty in saving new data."
      dialog $msg +20+80
    }
  }
}
