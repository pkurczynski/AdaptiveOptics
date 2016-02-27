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
# FILE: Alignment.tcl
# 
# DESCRIPTION:	
#   Procedures to perform system alignment for WaveScope
# 
# $Id: Alignment.tcl,v 1.44 1999/09/29 17:02:11 stacy Exp $
# 
#--------------------------------------------------------------------------


#--------------------------------------------------------------------------
# proc manualAlignment
#
# Main procedure for manual alignment.  This brings up a window of buttons.
# The buttons invoke individual alignment procedures.
#--------------------------------------------------------------------------

proc manualAlignment { } {

  global alignState alignType platform animprogpid


  # Get rid of the window if it exists already
  #
  if { [info command .manual] != "" } { destroy .manual }

  set alignState 100
  set alignType Manual

  if { [doSelectMLM] == "Abort" } {
    return
  }

  toplevel .manual
  wm geometry .manual +50+260
  wm title .manual "Manual Alignment"

  frame  .manual.test -relief ridge -borderwidth 4
  pack   .manual.test -side top -fill x -padx 7 -pady 7
  label  .manual.test.label -text "Test Source" -font [alignInterface:getFont]
  button .manual.test.exposure -text "Set Exposure" -highlightthickness 0 \
          -command {doSetTestExposure}
  button .manual.test.pupil -text "Show Pupil Image" -highlightthickness 0 \
          -command {doCenterPupil}
  button .manual.test.spot -text "Show Spot Image" -highlightthickness 0 \
          -command {doShowTestSpots}
  button .manual.test.tiptilt -text "Show Tip Tilt" -highlightthickness 0 \
          -command {doShowTestTipTilt}
  pack   .manual.test.label .manual.test.exposure .manual.test.pupil \
           .manual.test.spot .manual.test.tiptilt -side top -fill x

  frame  .manual.ref -relief ridge -borderwidth 4
  pack   .manual.ref -side top -fill x -padx 7 -pady 7
  label  .manual.ref.label -text "Reference Source" \
           -font [alignInterface:getFont]
  button .manual.ref.exposure -text "Set Exposure" -highlightthickness 0 \
          -command {doSetRefExposure}
  button .manual.ref.pupil -text "Show Pupil Image" -highlightthickness 0 \
          -command {doCenterRef}
  button .manual.ref.spot -text "Show Spot Image" -highlightthickness 0 \
          -command {doShowRefSpots}
  button .manual.ref.tiptilt -text "Show Tip Tilt" -highlightthickness 0 \
          -command {doShowRefTipTilt}
  pack   .manual.ref.label .manual.ref.exposure .manual.ref.pupil \
           .manual.ref.spot .manual.ref.tiptilt -side top -fill x


  # Add the OK and Help buttons at the bottom
  #
  frame .manual.buttonframe
  pack  .manual.buttonframe -side top

  button .manual.buttonframe.ok -text " OK " -command {set alignState 0} \
           -font [alignInterface:getFont]
  button .manual.buttonframe.help -text Help \
           -command "ShowHelp Alignment.html" -font [alignInterface:getFont]
  pack   .manual.buttonframe.ok .manual.buttonframe.help -side left \
           -padx 5 -pady 5


  # Keep doing commands invoked from the buttons until the user hits OK
  #
  while { 1 } \
  {
    tkwait variable alignState
    if { $alignState == 0 } {
      if { $platform != "windows" } {
	catch {exec kill -9 $animprogpid}
	catch {unset animprogpid}
      }
      break
    }
  }

  # Get rid of the window
  #
  if { [info command .manual] != "" } { destroy .manual }
    
  alignInterface:cleanup
}


#--------------------------------------------------------------------------
# proc assistedAlignment
#
# This routine walks the user through the individual alignment steps.  The
# global variable `alignState' holds the step that is will be executed.
# The individual steps do not know about any of the other steps.  The
# windows for each individual step have four buttons along their bottom.
# The default behavior for the four buttons are:
#
# The `Next>' button goes on to the next step, (increments alignState)
# The `Cancel' button terminates assisted alignment (sets alignState to zero)
# The `<Back' button goes to the previous step (decrements alignState)
# The `Help' button brings up help on a relevant topic
#--------------------------------------------------------------------------

proc assistedAlignment { } {

  global alignState alignType


  set alignState 1
  set alignType Assisted

  while { 1 } {
    switch $alignState {
      1 doSelectMLM 
      2 doUseTestBeam
      3 doSetTestExposure
      4 doCenterPupil
      5 doFocusPupil
      6 doShowTestTipTilt
      7 doUseRefBeam
      8 doSetRefExposure
      9 doCenterRef
      10 doShowRefTipTilt
      default break
    }
  }

  alignInterface:cleanup
}


#--------------------------------------------------------------------------
# proc doSelectMLM
#
# Checks if the user has already selected an MLM.  If not, prompts for
# MLM selection.  If so, displays the currently selected MLM.
#--------------------------------------------------------------------------

proc doSelectMLM { } {

  global alignState ws_stat

  if { [VerifyMLM] == "Abort" } {
    set alignState 0
    return "Abort"
  }
    
  while { $ws_stat(mlm) == "" } { 
    if { [SelectMLM] == "cancel" } {
      set alignState 0
      return "Abort"
    }
  }
 
  incr alignState
}


#--------------------------------------------------------------------------
#
# The following routines display the camera image at the best pupil plane
#
#--------------------------------------------------------------------------

proc doUseTestBeam { } {
  alignBestPupil [alignInterface:getTestPupilExposure] \
    "Light from the Test Source should appear in the Camera Image Display"
}

proc doUseRefBeam { } {
  alignBestPupil [alignInterface:getRefPupilExposure] \
    "Switch to the Reference Source.  Light from the Reference Source should appear in the Camera Image Display"
}

proc doFocusPupil { } {
  alignBestPupil [alignInterface:getTestPupilExposure] \
    "The Pupil should be focused in the Camera Image Display"
}


#--------------------------------------------------------------------------
# proc alignBestPupil
#
# Moves the stage to best pupil position, and puts up the camera display.
# Puts up message 'mess', offers appropriate controls for manual or
# assisted alignment procedure.  Uses the supplied exposure for the camera.
#--------------------------------------------------------------------------

proc alignBestPupil { exposure mess } {

  global animprogpid platform alignState


  set pos [alignInterface:getMLMBestPupilStagePosition]

  alignInterface:moveStage $pos 
  alignInterface:setCameraExposure $exposure

  if { $platform != "windows" } {
    alignInterface:showRealTimeDisplay
  }

  topMessage bestpupil $mess
  wm geometry .bestpupil +50+85

  AlignButtonFrame bestpupil PupilImage \
      { { "<Back" rel -1 } { "Next>" rel 1 } { Cancel abs 0 } }
  pack .bestpupil.message .bestpupil.buttonframe -side top -pady 5
  update

  if { $platform == "windows" } { 
    alignInterface:showRealTimeDisplay
    tkwait window .bestpupil
  } else {
    tkwait window .bestpupil
    if { $alignState == 0 } {
      catch {exec kill -9 $animprogpid}
      unset animprogpid
    }
  }
}


#--------------------------------------------------------------------------
#
# The following routines display the camera image at the spot plane
#
#--------------------------------------------------------------------------

proc doShowTestSpots { } {
  showSpots [alignInterface:getTestPupilExposure] \
    "The Spots from the Test Source should be bright on a dark background"
}

proc doShowRefSpots { } {
  showSpots [alignInterface:getRefPupilExposure] \
    "The Spots from the Reference Source should be bright on a dark background"
}


#--------------------------------------------------------------------------
# proc showSpots
#
# Moves the stage so the camera sees spots.
#--------------------------------------------------------------------------

proc showSpots { exposure mess } {

  global animprogpid platform alignType alignState


  set pos [alignInterface:getMLMBestSpotStagePosition]

  alignInterface:moveStage $pos
  alignInterface:setCameraExposure $exposure
  if { $platform != "windows" } { 
    alignInterface:showRealTimeDisplay
  }

  topMessage showspots $mess
  wm geometry .showspots +50+85
  set top .showspots

  if { $alignType == "Manual" } {
    frame  $top.buttonframe
    button $top.buttonframe.ok -text " OK " \
             -command {destroy .showspots} -font [alignInterface:getFont]
    pack   $top.buttonframe.ok -padx 5 -pady 10
  } else {
    AlignButtonFrame showspots ImagingSpots \
  	{ { "<Back" rel -1 } { "Next>" rel 1 } { Cancel abs 0 } }
  }
  pack .showspots.message .showspots.buttonframe -side top -pady 5

  update

  if { $platform == "windows" } {
    alignInterface:showRealTimeDisplay
  } else {
    tkwait window .showspots
    if { $alignState == 0 } {
      catch {exec kill -9 $animprogpid}
      unset animprogpid
    }
  }
}


#--------------------------------------------------------------------------
#
# The following routines display tip/tilt
#
#--------------------------------------------------------------------------

proc doShowTestTipTilt { } {
  showTipTilt [alignInterface:getTestPupilExposure] \
    "The Test Spots should be stationary as they go in and out of focus"
}

proc doShowRefTipTilt { } {
  showTipTilt [alignInterface:getRefPupilExposure] \
    "The Reference Spots should be stationary as they go in and out of focus"
}


#--------------------------------------------------------------------------
# proc showTipTilt
#
# Saws the stage back and forth until the user hits a button.
#--------------------------------------------------------------------------

proc showTipTilt { exposure mess } {

  global animprogpid platform alignType alignState


  alignInterface:setCameraExposure $exposure
  if { $platform != "windows" } {
    alignInterface:showRealTimeDisplay
  }

  topMessage show $mess
  wm geometry .show +50+85
  set top .show

  if { $alignType == "Manual" } {
    frame  $top.buttonframe
    button $top.buttonframe.ok -text " OK " \
             -command {destroy .show} -font [alignInterface:getFont]
    pack   $top.buttonframe.ok -padx 5 -pady 10
  } else {
    AlignButtonFrame show ShowingTipTilt \
  	{ { "<Back" rel -1 } { "Next>" rel 1 } { Cancel abs 0 } }
  }
  pack .show.message .show.buttonframe -side top -pady 5

  update

  if { $platform == "windows" } {
    alignInterface:showRealTimeDisplay
  }
    
  set pupilPosition [alignInterface:getMLMBestPupilStagePosition]
  set spotPosition  [alignInterface:getMLMBestSpotStagePosition]

  while { 1 } {
    if { [info commands .show] == "" } break

    alignInterface:moveStage $spotPosition

    if { [info commands .show] == "" } break

    alignInterface:moveStage $pupilPosition

    update
  }

  if { $platform != "windows" } {
    if { $alignState == 0 } {
      catch {exec kill -9 $animprogpid}
      unset animprogpid
    }
  }
}


############################################################################
#
############################################################################
proc doSetTestExposure { } \
{
    setTestExposure "Select the Exposure time for the Test Source"
}


#--------------------------------------------------------------------------
# proc doCenterPupil
#--------------------------------------------------------------------------

proc doCenterPupil { } {

  global platform


  if { $platform == "windows" } { 
    centerPupil "The Pupil should be centered in the Camera Image Display  (Exit the Camera Image Display before continuing)"
  } else {
    centerPupil "The Pupil should be centered in the Camera Image Display"
  }
}


############################################################################
#
############################################################################
proc doSetRefExposure { } \
{
    setRefExposure "Select the Exposure time for the Reference Source"
}


############################################################################
#
############################################################################
proc doCenterRef { } \
{
    centerRef "Light from the Reference Source should cover the Test Pupil"
}


############################################################################
#
# Sets the exposure time for the test beam.  All of the work is actually
# done in `setTestPupilExposure'.  The `alignInterface:getExposureList'
# routine is expected to return a monotonically increasing list of strings
# representing exposure time.  The routines `alignInterface:setTestPupilExposure'
# `alignInterface:getTestPupilExposure' and `alignInterface:setExposure' are
# expected to use elements from the list.
#
############################################################################
proc setTestExposure { mess } \
{
  global animprogpid platform alignType alignState


  set exposure [alignInterface:getTestPupilExposure]

  alignInterface:setCameraExposure $exposure 
  if { $platform != "windows" } {
    alignInterface:showRealTimeDisplay
  }

  topMessage settestexposure $mess
  wm geometry .settestexposure +50+85
  set top .settestexposure

  if { $alignType == "Manual" } {
    frame  $top.buttonframe
    button $top.buttonframe.ok -text " OK " \
             -command {destroy .settestexposure} -font [alignInterface:getFont]
    pack   $top.buttonframe.ok -padx 5 -pady 10
  } else {
    AlignButtonFrame settestexposure SettingTestExposure \
  	{ { "<Back" rel -1 } { "Next>" rel 1 } { Cancel abs 0 } }
  }

  frame .settestexposure.control
  button .settestexposure.control.longer -text Longer \
           -command { setTestPupilExposure longer } -highlightthickness 0
  label  .settestexposure.control.time -text "$exposure sec" -width 11
  button .settestexposure.control.shorter -text Shorter \
           -command { setTestPupilExposure shorter } -highlightthickness 0

  pack .settestexposure.control.longer .settestexposure.control.time \
	 .settestexposure.control.shorter -side left -padx 5

  pack .settestexposure.message .settestexposure.control \
	 .settestexposure.buttonframe -side top -pady 5

  update

  if { $platform == "windows" } {
    alignInterface:showRealTimeDisplay
    tkwait window .settestexposure
  } else {
    tkwait window .settestexposure
    if { $alignState == 0 } {
      catch {exec kill -9 $animprogpid}
      unset animprogpid
    }
  }
}


############################################################################
#
# Bumps the exposure up or down, depending on `which'.
#
############################################################################
proc setTestPupilExposure { which } \
{
    set exposure [alignInterface:getTestPupilExposure]
    set exposureList [alignInterface:getExposureList]
    set exposureIndex [lsearch $exposureList $exposure]
    set maxExposureIndex [llength $exposureList]
    incr maxExposureIndex -1

    if { $which == "shorter" } \
    {
        if { $exposureIndex >= $maxExposureIndex } return

        incr exposureIndex
    } \
    else \
    {
        if { $exposureIndex == 0 } return

        incr exposureIndex -1
    }

    set exposure [lindex $exposureList $exposureIndex]
    alignInterface:setTestPupilExposure $exposure
    alignInterface:setCameraExposure $exposure
    .settestexposure.control.time configure -text "$exposure sec"
    update
}


#--------------------------------------------------------------------------
# proc centerPupil
#
# Asks the user to center the test pupil.  It also grabs an image of the
# pupil for later use in `centerRef'.
#--------------------------------------------------------------------------

proc centerPupil { mess } {

  global centerStatus animprogpid platform alignType alignState

    
  set pos [alignInterface:getMLMBestPupilStagePosition]
  set exposure [alignInterface:getTestPupilExposure]

  alignInterface:moveStage $pos
  alignInterface:setCameraExposure $exposure
  if { $platform != "windows" } {
    alignInterface:showRealTimeDisplay
  }

  topMessage center $mess
  wm geometry .center +50+85
  set top .center

  if { $alignType == "Manual" } {
    frame  $top.buttonframe
    button $top.buttonframe.ok -text " OK " -font [alignInterface:getFont] \
	     -command "buttonFrameCustomAction center OK rel 1"
    pack   $top.buttonframe.ok -padx 5 -pady 10
  } else {
    AlignButtonFrame center CenteringPupil \
  	{ { "<Back" rel -1 } { "Next>" rel 1 } { Cancel abs 0 } }
  }
  pack .center.message .center.buttonframe -side top -pady 5

  update

  if { $platform == "windows" } {
    alignInterface:showRealTimeDisplay
    tkwait window .center
  } else {
    tkwait window .center
      catch {exec kill -9 $animprogpid}
      unset animprogpid
  }
  if { $centerStatus == "OK" || $centerStatus == "Next>" } {
    alignInterface:grabImage
  }
}


############################################################################
#
# Sets the reference exposure time.  All of the work is actually
# done in `setRefPupilExposure'.  The `alignInterface:getExposureList'
# routine is expected to return a monotonically increasing list of strings
# representing exposure time.  The routines `alignInterface:setRefPupilExposure'
# `alignInterface:getRefPupilExposure' and `alignInterface:setExposure' are
# expected to use elements from the list.

############################################################################
proc setRefExposure { mess } \
{
  global animprogpid platform alignType alignState


  set exposure [alignInterface:getRefPupilExposure]

  alignInterface:setCameraExposure $exposure
  if { $platform != "windows" } {
    alignInterface:showRealTimeDisplay
  }

  topMessage setrefexposure $mess
  wm geometry .setrefexposure +50+85
  set top .setrefexposure

  if { $alignType == "Manual" } {
    frame  $top.buttonframe
    button $top.buttonframe.ok -text " OK " \
             -command {destroy .setrefexposure} -font [alignInterface:getFont]
    pack   $top.buttonframe.ok -padx 5 -pady 10
  } else {
    AlignButtonFrame setrefexposure SettingReferenceExposure \
  	{ { "<Back" rel -1 } { "Next>" rel 1 } { Cancel abs 0 } }
  }

  frame .setrefexposure.control
  button .setrefexposure.control.longer -text Longer \
         -command { setRefPupilExposure longer } -highlightthickness 0
  label  .setrefexposure.control.time -text "$exposure sec" -width 11
  button .setrefexposure.control.shorter -text Shorter \
         -command { setRefPupilExposure shorter } -highlightthickness 0

  pack .setrefexposure.control.longer .setrefexposure.control.time \
       .setrefexposure.control.shorter -side left -padx 5

  pack .setrefexposure.message .setrefexposure.control \
       .setrefexposure.buttonframe -side top -pady 5

  update

  if { $platform == "windows" } {
    alignInterface:showRealTimeDisplay
    tkwait window .setrefexposure
  } else {
    tkwait window .setrefexposure
    if { $alignState == 0 } {
      catch {exec kill -9 $animprogpid}
      unset animprogpid
    }
  }
}


############################################################################
#
# Bumps the exposure up or down, depending on `which'.
#
############################################################################
proc setRefPupilExposure { which } \
{
    set exposure [alignInterface:getRefPupilExposure]
    set exposureList [alignInterface:getExposureList]
    set exposureIndex [lsearch $exposureList $exposure]
    set maxExposureIndex [llength $exposureList]
    incr maxExposureIndex -1

    if { $which == "shorter" } \
    {
	if { $exposureIndex >= $maxExposureIndex } return

	incr exposureIndex
    } \
    else \
    {
	if { $exposureIndex == 0 } return

	incr exposureIndex -1
    }

    set exposure [lindex $exposureList $exposureIndex]
    alignInterface:setRefPupilExposure $exposure
    alignInterface:setCameraExposure $exposure
    .setrefexposure.control.time configure -text "$exposure sec"
    update
}


############################################################################
#
# Asks if the light from the reference beam covers the test pupil.  It brings
# up the last test pupil image if it exists.
#
############################################################################
proc centerRef { mess } \
{
  global testPupilImage animprogpid id platform alignType alignState
    

  if { [info exists testPupilImage] } {
    set imd [alignInterface:showImage $testPupilImage "Test Pupil Image"]
  }

  set pos [alignInterface:getMLMBestPupilStagePosition]
  set exposure [alignInterface:getRefPupilExposure]

  alignInterface:moveStage $pos
  alignInterface:setCameraExposure $exposure
  if { $platform != "windows" } {
    alignInterface:showRealTimeDisplay
  }

  topMessage center $mess
  wm geometry .center +50+85
  set top .center

  if { $alignType == "Manual" } {
    frame  $top.buttonframe
    button $top.buttonframe.ok -text " OK " \
             -command {destroy .center} -font [alignInterface:getFont]
    pack   $top.buttonframe.ok -padx 5 -pady 10
  } else {
    AlignButtonFrame center CenteringReference \
  	{ { "<Back" rel -1 } { "Next>" rel 1 } { Cancel abs 0 } }
  }
  pack .center.message .center.buttonframe -side top -pady 5

  update
  if { $platform == "windows" } {
    alignInterface:showRealTimeDisplay
    tkwait window .center
  } else {
    tkwait window .center
    if { $alignState == 0 } {
      catch {exec kill -9 $animprogpid}
      unset animprogpid
    }
  }

  if { [info exists id] } { unset id }
}


############################################################################
#
# Generates a top level window with a message.  More stuff, like the
# row of buttons at the bottom, can be added later.
#
############################################################################
proc topMessage { top mess } \
{
    global alignType

    toplevel .$top
    wm title .$top "Alignment"
    wm geometry .$top +350+200
    grab .$top

    message .$top.message -width 8c -text $mess
}


############################################################################
#
# Makes a row of buttons.  The buttonlist controls the name and behavior of
# the buttons.  Each element of buttonlist is itself a list describing a
# single button.  A button description list consists of
#
#	name	the label on the button
#	mod	either abs or rel, standing for absolute or relative.
#	val	a relative step increment or an absolute step number.
#
# We assume there is a global variable called `alignState' which we manipulate.
# An `abs' button sets `alignState' to a particular value.  A `rel'
# button adds the `val' to `alignState'.
#
# We also assume there is a global variable called ${top}Status.  We set this
# to the button name to indicate which button was hit.
#
# Some windows need special behavior when a particular button is hit.  In
# this case, the button handler looks for a proc whose name is
# ${top}${name}
# and executes it if it exists.
#
############################################################################
proc AlignButtonFrame { top helptopic buttonlist } \
{
    frame .$top.buttonframe

    for { set b 0 } { $b < [llength $buttonlist] } { incr b } \
    {
	set spec [lindex $buttonlist $b]
	set name [lindex $spec 0]
	set mod  [lindex $spec 1]
	set val  [lindex $spec 2]
	set lowname [string tolower $name]

	button .$top.buttonframe.$lowname -text $name \
	    -command "buttonFrameCustomAction $top $name $mod $val" \
	    -font [alignInterface:getFont]
	pack .$top.buttonframe.$lowname -side left -padx 5 -pady 5
    }

    button .$top.buttonframe.help -text Help \
	-command "ShowHelp Alignment.html" -font [alignInterface:getFont]
    pack .$top.buttonframe.help -side left -padx 5 -pady 5
}


############################################################################
#
# Sets the ${top}Status variable to indicate which button was hit.
# Executes `${top}${name}' if the proc exists.
# Manipulates the `alignState' variable as specified by `mod' and `val'.
#
############################################################################
proc buttonFrameCustomAction { top name mod val } \
{
    global ${top}Status alignState

    set ${top}Status $name

    if { [info commands ${top}${name}] != "" } { ${top}${name} }
    
    destroy .$top

    if { $mod == "abs" } \
    {
	set alignState $val
    } \
    else \
    {
	incr alignState $val
    }

    update
}


############################################################################
#
# Returns the stage position of best spot focus for the current MLM.
#
############################################################################
proc alignInterface:getMLMBestSpotStagePosition { } \
{
    global stagePos ws_stat

    set mlm $ws_stat(mlm)
    return $stagePos(BestRefSpots)
}

############################################################################
#
# Returns the stage position of best pupil focus for the current MLM.
#
############################################################################
proc alignInterface:getMLMBestPupilStagePosition { } \
{
    global stagePos ws_stat

    set mlm $ws_stat(mlm)
    return $stagePos(PupilImage)
}


############################################################################
#
# Moves the stage.
#
############################################################################
proc alignInterface:moveStage { position } \
{
    global wsdb hw_flg
    
    set cur_pos [stage.get.position]
    set wsdb(stagePosition) [lindex [split [lindex [split $cur_pos] 4] .] 0]

    if { $wsdb(stagePosition) == $position } return

    if { $hw_flg == "TRUE" } { 
	stage.calibrate.absolute $position
    }
}


############################################################################
#
# Returns a list of strings describing exposure time.  We assume the list
# of strings represent times which are monotonically increasing.
#
############################################################################
proc alignInterface:getExposureList { } \
{
    global wsdb

    return $wsdb(exposureList)
}


############################################################################
#
# Returns the recommended exposure time string for the test pupil.  Hopefully
# this is an element of the list returned by `alignInterface:getExposureList'.
#
############################################################################
proc alignInterface:getTestPupilExposure { } \
{
    global wsdb

    return $wsdb(testPupilExposure)
}


############################################################################
#
# Sets the recommended exposure time string for the test pupil.  Hopefully
# this is an element of the list returned by `alignInterface:getExposureList'.
#
############################################################################
proc alignInterface:setTestPupilExposure { exposure } \
{
    global wsdb

    set wsdb(testPupilExposure) $exposure
}

############################################################################
#
# Returns the recommended exposure time string for the ref pupil.  Hopefully
# this is an element of the list returned by `alignInterface:getExposureList'.
#
############################################################################
proc alignInterface:getRefPupilExposure { } \
{
    global wsdb

    return $wsdb(refPupilExposure)
}


############################################################################
#
# Sets the recommended exposure time string for the ref pupil.  Hopefully
# this is an element of the list returned by `alignInterface:getExposureList'.
#
############################################################################
proc alignInterface:setRefPupilExposure { exposure } \
{
    global wsdb

    set wsdb(refPupilExposure) $exposure
    set wsdb(refNonPupilExposure) $exposure
}


############################################################################
#
# Sets the camera exposure.  The `exposure' is a string from the list
# returned by `alignInterface:getExposureList'.
#
############################################################################
proc alignInterface:setCameraExposure { exposure } \
{
    global wsdb hw_flg

    set exposureList [alignInterface:getExposureList]
    set exposureIndex [lsearch $exposureList $exposure]

    if { $wsdb(cameraExposure) == $exposure } return

    if { $hw_flg == "TRUE" } { 
	send_camera_exposure $exposureIndex
    }

    set wsdb(cameraExposure) $exposure
}


############################################################################
#
# Gets the font to use for text in the alignment windows.
#
############################################################################
proc alignInterface:getFont { } \
{
    global wsdb 
    
    return $wsdb(font)
}


#--------------------------------------------------------------------------
# proc alignInterface:showRealTimeDisplay
#
# Kicks off the camera image display appropriate for the platform, records
# the process id of the camera image display process.
#--------------------------------------------------------------------------

proc alignInterface:showRealTimeDisplay { } {

  global platform animprogpid hw_flg


  if { [info command .rtd] != "" } return
 
  if { $platform == "windows" } {
    if { $hw_flg == "TRUE" } { 
      set animprogpid [exec /usr/aos/wavescope/bin/livedisp.exe &]
    }
  } else {
    if { $hw_flg == "TRUE" } {
      if { ! [info exists animprogpid] } {
	set animprogpid [exec mvid > /dev/null 2>/dev/null &]
      }
    } else {
      set animprogpid x
    }
  }
}


#--------------------------------------------------------------------------
# proc alignInterface:cleanup
#
# Makes sure the Camera Image Display has been taken down, then pops up
# a dialog announcing that Alignment is complete.
#--------------------------------------------------------------------------

proc alignInterface:cleanup { } {

  global platform alignType alignState animprogpid

    
  if { $platform == "windows" } { 
    set animprogpid 0
    if { ($alignType == "Assisted") && ($alignState == 11) } {
      dialog "Basic Alignment completed successfully.\
	  If it is still open, please close the Camera Image Display." +50+85
    } else {			
      dialog "If it is still open, please close the Camera Image Display." +50+85
    }
  } else {

    # Linux
    #
    if { [info exists animprogpid] } {
      catch {exec kill -9 $animprogpid}
      unset animprogpid
    }
    if { [info command .rtd] != "" } { destroy .rtd }
    if { ($alignType == "Assisted") && ($alignState == 11) } {
      dialog "Basic Alignment completed successfully." +50+85
    }			
  }
}


#--------------------------------------------------------------------------
# proc alignInterface:grabImage
#
# Grabs an image and returns it.
#--------------------------------------------------------------------------

proc alignInterface:grabImage { } {

  global fg_im hw_flg platform testPupilImage ld_upStatus alignType

    
  if { $hw_flg == "TRUE" } {
    if { $platform == "windows" } {
      while [ catch { fg.grab 1 = fg_im } result ] {

	topMessage ld_up "Please exit the Camera Image Display"
	wm geometry .ld_up +50+85

        frame  .ld_up.buttonframe
	button .ld_up.buttonframe.ok -text " OK " -font [alignInterface:getFont] \
	    -command {destroy .ld_up}
	pack   .ld_up.buttonframe.ok -padx 5 -pady 10
	pack .ld_up.message .ld_up.buttonframe -side top -pady 5

	update
	tkwait window .ld_up
      }
    } else {
      fg.grab 1 = fg_im
    }
  }

  set testPupilImage $fg_im
}


############################################################################
#
# Shows an image.  It uses the data in `data' and gives the window the title
# `title'.  It returns an identification of the window in which the image
# is displayed.
#
############################################################################
proc alignInterface:showImage { data title } \
{ 
    global id fg_im hw_flg

    if { $hw_flg == "TRUE" } { 
	id.new id
	id.set.wh id 500 500
	id.set.xy id 630 280
	id.set.array id $fg_im
	id.set.title id "Test Image"
    } else {

	if { [info command .image] != "" } { destroy .image }
    
	toplevel .image
	wm geometry .image +750+500
	wm title .image $title
    
	set width 320
	set height 240
    
	set radius 100
    
	set x0 [expr $width/2.-$radius]
	set y0 [expr $height/2.-$radius]
	set x1 [expr $x0+$radius*2.]
	set y1 [expr $y0+$radius*2.]
    
	canvas .image.canvas -width $width -height $height \
	    -background black
	pack .image.canvas
    
	.image.canvas create arc $x0 $y0 $x1 $y1 \
	    -fill white -outline white -start 0 -extent 359.999

	return .image

    }
}


############################################################################
#
# Gets rid if the image display specified by `id'.
#
############################################################################
proc alignInterface:hideImage { id } \
{
    if { [info command $id] != "" } { destroy $id }
}
