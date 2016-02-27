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
# FILE: Help.tcl
# 
# DESCRIPTION:	
#   GUI objects and functions accessible from the Help menu.
#   The Update stuff is in here, too.
# 
# $Id: Help.tcl,v 1.26 2001/05/18 20:16:31 herb Exp $
# 
#==========================================================================

set mountPoint floppy


#---------------------------------------------------------------------------
# HelpInit
#
# Initialize the help system
#---------------------------------------------------------------------------

proc HelpInit {} \
{
  global platform Help HELP_ROOT


  # Initialize the globals
  #
  if {[info exists HELP_ROOT]} {
    set root $HELP_ROOT
  } else {
    set root "/usr/aos/wavescope/help"
  }
  if { $platform == "windows" } {
    set Help(path) "C:$root"
    set Help(reader) "/Program Files/Plus!/Microsoft Internet/iexplore.exe"
  } else {
    set Help(path) $root
    set Help(reader) "/usr/aos/wavescope/bin/help_reader"
  }
  set Help(rootFile) $Help(path)/default.html
  set Help(init) "Yes"
}


#---------------------------------------------------------------------------
# Help
#
# Display the top level "contents" file of the HTML-based help documents
#---------------------------------------------------------------------------

proc Help {} \
{
  global platform Help


  # Has help been initialized?
  #
  if { ! [info exists Help(init)] } { HelpInit }

  # Display the main help file
  #
  exec $Help(reader) $Help(rootFile) &
}


#---------------------------------------------------------------------------
# ShowHelp
#
# Display a specific help document.  This is just boilerplate that makes
# sure the platform-specific stuff has been initialized.
#---------------------------------------------------------------------------

proc ShowHelp { doc } \
{
  global platform Help


  # Has help been initialized?
  #
  if { ! [info exists Help(init)] } { HelpInit }

  # Display the desired help file
  #
  exec $Help(reader) $Help(path)/$doc &
}


#---------------------------------------------------------------------------
# proc ShowMiniHelp
#
# Puts up a dialog box with a help message in it.  The only parameter is
# a string variable containing the message to display.
#---------------------------------------------------------------------------

proc ShowMiniHelp { text } {

  global applicationName wlPanel wsCalHelpText cb_labels


  set cb_labels(miniHelp) "Help Text Panel"
  MakeTextPanel .miniHelp 400 400 60 20 MiniHelp help
  UpdateTextPanel $MiniHelp $text 1
  tkwait window .miniHelp
}


#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------

proc HelpAbout { } {

  global applicationName


  set msg "
Version 2.0p6

A Hartmann Wavefront Sensor

By
Adaptive Optics Associates

Copyright 1999, 2000, 2001
All Rights Reserved"

  if { [winfo exist .about] } { destroy .about }

  toplevel .about 
  wm geometry .about -20+80
  wm title .about "$applicationName"
    
  frame .about.frame1 -relief flat 
  pack .about.frame1 -side top
    
  message .about.frame1.mess -justify center -text $msg -width 9c
  pack .about.frame1.mess -side left

  frame .about.frame2 -relief flat 
  pack .about.frame2 -side top
    
  button .about.frame2.ybutton -text "  OK  " -command { destroy .about }
  pack .about.frame2.ybutton -side left -padx 2m -pady 2m

  bind .about <Destroy> { destroy .about }
  bind .about <Key-Return> { destroy .about }

  tkwait window .about
}


#---------------------------------------------------------------------------
# Update
#
# Provides selection mechanism for doing updates from floppy or CD-ROM.
#---------------------------------------------------------------------------

proc Update {} \
{
  global mountPoint

  if { [winfo exists .hu] } \
  {
    destroy .hu
  }
  set msg "Select the media containing\nthe update, then press OK"


  toplevel    .hu
  wm title    .hu "Update WaveScope"
  wm geometry .hu -50+80
  frame       .hu.f
  pack        .hu.f
  message     .hu.f.msg -text $msg -width 10c
  pack        .hu.f.msg
  frame       .hu.f.tframe -relief groove -bd 2
  frame       .hu.f.bframe
  pack        .hu.f.tframe .hu.f.bframe -padx 5 -pady 5

  message     .hu.f.tframe.msg -text "Update Media" -width 10c
  pack        .hu.f.tframe.msg -padx 5 -pady 5
  radiobutton .hu.f.tframe.floppy -text "Floppy" -variable mountPoint \
               -value floppy -highlightthickness 0
  pack        .hu.f.tframe.floppy
  radiobutton .hu.f.tframe.cdrom -text "CD-ROM" -variable mountPoint \
               -value cdrom -highlightthickness 0
  pack        .hu.f.tframe.cdrom

  button      .hu.f.bframe.ok -text "  OK  " -command { DoUpdate }
  button      .hu.f.bframe.cancel -text Cancel -command {destroy .hu}
  pack        .hu.f.bframe.ok .hu.f.bframe.cancel -side left -padx 5 -pady 5

  update
}


#---------------------------------------------------------------------------
# proc DoUpdate
#
# Performs update from floppy or CD-ROM, as selected by user.
#---------------------------------------------------------------------------

proc DoUpdate {} \
{
  global platform
  global mountPoint


  if { $platform == "windows" } {
    exec a:\setup.exe
  } else {
    if { $mountPoint == "floppy" } {
      if [ catch { exec mdir a:filelist.txt } result ] {
	dialog "There does not appear to be a diskette in the drive." -20+150
	return
      }
      if { [string first "not found" $result] != -1 } {
	dialog "The diskette in the drive does not appear to be a WaveScope Update disk." -20+150
	return
      }
      exec xterm -e /usr/aos/wavescope/bin/wsUpdate
      if { [winfo exists .hu] } {
	destroy .hu
      }
      dialog "Please log out of WaveScope and log back in to complete the Update." -20+150
    } else {
      if [ catch {exec ls /cdrom/ws_inst} ] {
        dialog "The CD-ROM does not appear to be mounted.  Check the instructions for mounting the CD that came with the upgrade." -20+150
        return
      } else {
        exec xterm -e /usr/aos/wavescope/bin/wsUpdateCD
        if { [winfo exists .hu] } {
	  destroy .hu
        }
        dialog "Please log out of WaveScope and log back in to complete the Update." -20+150
      }        
    }
  }
}


#---------------------------------------------------------------------------
# proc wsInitCalHelp
#
# Initializes the calibration help-text variable wsCalHelpText.
#---------------------------------------------------------------------------

proc wsInitCalHelp {} {

  global wsCalHelpText


  set wsCalHelpText(PupSub) \
"The Pupil Subaperture Spacing determined by WaveScope
does not agree with the nominal value for the MLM selected.
Check the following possible problems:

1) MLM selection does not match MLM installed
2) MLM not seated properly
3) Light level too low or high in pupil calibration"


  set wsCalHelpText(RefRects) \
"The number of Reference Subapertures found by WaveScope
is significantly less than the theoretical number possible
in the pupil. Possible sources of this problem are:

1) Large central obscuration. If active portion of
  pupil is filled with subapertures press Continue
2) Light level too low or high in
  reference spot calibration
3) Pupil illumination very non-uniform "


  set wsCalHelpText(TestRects) \
"The number of Test Subapertures found by WaveScope
is significantly less than the theoretical number possible
in the pupil. Possible sources of this problem are:

1) Large central obscuration. If active portion of
  pupil is filled with subapertures press Continue
2) Light level too low or high in test spot calibration
3) Pupil illumination very non-uniform
  For further information click on Help menu button" 

  set wsCalHelpText(RefMatches) \
"WaveScope has found fewer matches between the Reference
Subapertures and Pupil Subapertures than expected. There
are several possible explanations:

1) There is very large wavefront tilt.
  Check WaveScope alignment.
2) There is very severe aberration of the test beam
  making matching difficult. Review manual section on
  matching. Possibly use command alg.set.matchsize
  to increase matching tolerance
  (WARNING - setting matchsize too large may lead
  to erroneous matching and large wavefront errors).
3) Light level too low or high in reference exposure." 

  set wsCalHelpText(TestMatches) \
"WaveScope has found fewer matches between the Test
Subapertures and Pupil Subapertures than expected. There
are several possible explanations:

1) There is very large wavefront tilt.
  Check WaveScope alignment.
2) There is very severe aberration of the test beam
  making matching difficult. Review manual section on
  matching. Possibly use command alg.set.matchsize
  to increase matching tolerance
  (WARNING - setting matchsize too large may lead
  to erroneous matching and large wavefront errors).
3) Light level too low or high in test exposure." 

  return "OK"
}
