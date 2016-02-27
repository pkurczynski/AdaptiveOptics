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
# FILE: ContTest.tcl
# 
# DESCRIPTION:	
#   This file contains the Test Control Panel procedures.
# 
# $Id: ContTest.tcl,v 1.19 2000/07/13 21:50:03 herb Exp $
# 
#==========================================================================


#--------------------------------------------------------------------------
# proc doTestLoop
#
# `doTestLoop' is intended to be called from a menu.  It brings up
# a control panel and starts a mainLoop which calls dtl:interface:doTest
# repeatedly.  The panel allows the user to stop and start the loop or
# get out completely.
#
# The programer must supply 2 interface routines:
#
# 1) dtl:interface:getFont	returns the prefered font
# 2) dtl:interface:doTest	actually calls doTest
#--------------------------------------------------------------------------

proc doTestLoop { } {

  global dtlStatus ws_stat All_types Test_Options


  if { ![string compare $ws_stat(new_test) "True"] } {
    set disp_list ""
    foreach item $All_types {
      if { $Test_Options($item) == 1 } {
	set disp_list [concat $disp_list $item]
      }
    }
    set ws_stat(disp_list) $disp_list
  }

  if { [winfo exists .dtl] } return
    
  toplevel .dtl
  wm title .dtl "Live Display Control Panel"
  wm geometry .dtl +30+30
    
  message .dtl.m -width 10c -text \
"Executing Capture/Reduce/Display loop.
Click Run/Pause to start/stop the loop.
Click Exit to terminate execution."

  label .dtl.l -font [dtl:interface:getFont] -text "Status : PAUSED"

  frame  .dtl.f
  button .dtl.f.c -font [dtl:interface:getFont] \
    	-text "Run" -command dtl:doContinue
  button .dtl.f.p -font [dtl:interface:getFont] \
    	-text "Pause" -command dtl:doPause
  button .dtl.f.e -font [dtl:interface:getFont] \
    	-text "Exit" -command dtl:doExit
    
  pack .dtl.f.c .dtl.f.p .dtl.f.e -side left -padx 5 -pady 5
  pack .dtl.m .dtl.l .dtl.f -side top

  bind .dtl <Destroy> { if {"%W" == ".dtl"} { fg.grabc_term } }
    
  dtl:setShowStatus PAUSED
    
  dtl:doContinue
}


###############################################################################
#
# Set the status to RUNNING and call mainLoop.
#
###############################################################################
proc dtl:doContinue { } \
{
    global	dtlStatus
    
    if { $dtlStatus != "PAUSED" } return
    
    dtl:setShowStatus RUNNING
    update
    
    dtl:mainLoop
}

###############################################################################
#
# Set the status to WAITING, causing the mainLoop to break out.  The main
# loop will set the status to PAUSED.
#
###############################################################################
proc dtl:doPause { } \
{
    global	dtlStatus
    
    if { $dtlStatus != "RUNNING" } return
    
    dtl:setShowStatus "WAITING"
    update
}


#--------------------------------------------------------------------------
# proc dtl:doExit
#
# If we are already paused, kill the panel.  Otherwise, wait for the test
# to end, and the mainLoop routine will kill the panel.
#--------------------------------------------------------------------------

proc dtl:doExit { } {

  global dtlStatus
    

  if { $dtlStatus == "PAUSED" } {
    if { [winfo exists .winex] } { destroy .winex }
    destroy .dtl
  } else {
    dtl:setShowStatus "EXIT"
  }
}


###############################################################################
#
# This calls doTest until the `dtlStatus' is no longer RUNNING
# If the status is "EXIT" we bludgen the .dtl panel.
#
###############################################################################
proc dtl:mainLoop { } \
{
    global    dtlStatus
    
    while { $dtlStatus == "RUNNING" } \
    {
    	dtl:interface:doTest
	update
	raise .dtl
    }
    
    if { $dtlStatus == "EXIT" } \
    {
    	if { [winfo exists .winex] } { destroy .winex }
    	destroy .dtl
    } \
    else \
    {
    	if { [winfo exists .winex] } { destroy .winex }
    	dtl:setShowStatus "PAUSED"
    }
}

###############################################################################
#
# Sets the status to `st' and shows it in the little panel.
#
###############################################################################
proc dtl:setShowStatus { st } \
{
    global	dtlStatus
    
    set dtlStatus $st
    
    .dtl.l configure -text "Status : $st"
    update
}





###############################################################################
#
# Returns the font used in the panel.
#
###############################################################################
proc dtl:interface:getFont { } \
{
    return "-*-courier-bold-r-normal--14-*-*-*-*-*-*-*"
}

###############################################################################
#
# Actually does doTest.  
#
###############################################################################
proc dtl:interface:doTest { } \
{
    set status ""
    if [catch { set status [doTest] } result] {
		dialog $result
		puts "Error:"
		puts $result
    	dtl:setShowStatus "EXIT"
    } 
	if { $status == "Abort" } { 
		dtl:doExit
	}
    update
}


