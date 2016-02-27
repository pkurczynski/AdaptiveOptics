#--------------------------------------------------------------------------
# dm_panels_5dms.tcl                            tcl script
#
# Contains procedures for controlling deformable mirrors through the
# wavescope software, in particular for closed loop control of an
# adaptive optics system.
#
# Original version of this code was obtained from AOA (contact Herb
# da Silva), and was extensively modified by Harold Dyson and Peter
# Kurczynski
#
# version 10
# plk 09/14/2005
#--------------------------------------------------------------------------


#--------------------------------------------------------------------------
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
#--------------------------------------------------------------------------
# 
# FILE: dm_panels_5dms.tcl
# 
# DESCRIPTION: Wavescope control for 140 and 1024 actuator BMC
# devices, and 256 and 1024 actuator CfAO membrane devices
# 
# $Id: dm_panels_5dms.tcl,v 1.0 18 May 2004 hdyson@lucent.com Exp $
# 
# Based on code from Herb da Silva at AOA
# 
#--------------------------------------------------------------------------
#####
# Modified by allan 2001/04/26 to include refinements developed for
# control of DM with missing or unobserved actuators
#####

##Modified for transparent electrode device; July 02 2004.
##hdyson

#Modified to add support for membrane mirror, hdyson 16th Oct 03.
#Modified for 1024 actuator BMC and membrane mirrors, hdyson, 8th Jun 04.
#Additional functions added at end of file.
#To use bmc 140 mirror, call as 'dm_panel'
#To use membrane 256 mirror, call as 'mdm_panel'
#To use bmc 1024 mirror, call as 'dm1k_panel'
#To use membrane 1024 mirror, call as 'mdm1k_panel'
#To use membrane 1024 mirror with transparent electrode, call as 'tdm_panel'

###
#
#Desired changes:
#
# 1) Closed loop: using any loop checks boxes for all.  Why?
#    Need new variable for each checkbutton to implement.  Should be straightforward
#
# 2) Big one: upon changing panel, need to close current device, and
#    load DLL for desired device.  Also need to check if DLL is
#    already loaded, in which case, just need to change function
#    names, and re-run DM_Init() function.
# 
# 3) Panels other than mdm1k_panel: need to change ACT_LINE_LENGTH to
#    XACT_LINE_LENGTH and YACT_LINE_LENGTH
#
###

#
# GLOBALS
#

global volts CurDrv whichAct integGain ModFlg doneit selected
global closeLoopFlag pokeVar mode modew mods mod modn wgtVar nmodes

global device Varray deltaV Vm

set device NULL

set Varray 0
#Initial array voltage.  Used solely for the transparent electrode device.  
set deltaV 10
#Maximum single actuator change from Varray.  Similarly, only for transparent electrode device.
set Vm 0
#Initial membrane voltage; used for command line tools only.  Should be updated each time Varray is altered.

set closeLoopFlag Off
set integGain 30
#set MAX_ACT 144

#Added Sep 24th hdyson@lucent.com (used in ftov function)
global MAX_VOLT
set MAX_VOLT 0

# Define file with a default zero voltage array for DM
#set ZeroFile c:/usr/aos/wavescope/src/lists/Zeros_bmc

# new globals, part of improved reconstructor generation
#
# MaskFile is an ascii file consisting of $NMAK_ACT integer elements
# If file entry is = 1, actuator is used in generating recon, otherwise
# it is skpped. It is loaded as $maskArray.
#set MaskFile c:/usr/aos/wavescope/src/lists/Mask_bmc.txt
#
# Maskfiles also used for GUI actuaotr control; masked actuators are
# shown greyed-out, and can't be actuated.

# $thresh is the threshold value used in eliminating low gradient values
# gradients whose magnitude is less than $thresh/100 * $pokeFaction
# are set to zero before generating recon. Gradient mask is $gmm
set thresh 50
#
# $pthresh is the threshold value used in removing poorly observed
# actuators from the recon. Actuators whose maximum gradient response
# magnitude is less than $pthresh/100 * $pokeFaction have their coresponding
# recon row set to zero. Resulting mask is $mrat
set pthresh 100
#
# $condth is the limit on the condition number of the recon. Singular
# values that are less than 1/$condth of the maximum singular value
# are masked in the recon. Resulting mask is $Wmask
set condth 500
#
# $pokeFraction is the size of the poke used to generate the response matrix
# originally 0.5
# changed to 6.0   H. Dyson  12/17/2004
# changed to 10.0  (resulted in ~3V sent to array) plk 12/17/2004
set pokeFraction 1.0

#
set ModFlg "Poke"
set HW_Flag "True"
set LS_Dir [pwd]

set loopType NULL
set whichAct 1
set selected(1) 1
set pokeVar 0
set doneit 0
set mod 0
set modn 0

#---------------------------------------------------------------------------
# proc dm_panel
# 
# Initialization to be done before popping up the closeLoopPanel
#
### For DMs: BMC 140
#
#---------------------------------------------------------------------------

proc dm_panel {} {

    global device MAX_ACT MAX_VOLT ZeroFile MaskFile
    global CurDrv volts nmodes acts selected
    global MaskFile maskArray ACT_LINE_LENGTH

    if {$device == "bmc140"} {
    }
    elseif {$device == "membrane1024"} {
	rename dm.help mdm1k.help
	rename dm.send mdm1k.send
	rename dm.poke mdm1k.poke
	rename dm.pokeraw mdm1k.pokeraw
	rename dm.ping mdm1k.ping
	rename bmcdm.help dm.help
	rename bmcdm.send dm.send
	rename bmcdm.poke dm.poke
	rename bmcdm.pokeraw dm.pokeraw
	rename bmcdm.ping dm.ping
    } elseif { $device == "membrane256"} {
	#Reset mdm functions to generic device functions...
	rename dm.help mdm.help
	rename dm.send mdm.send
	rename dm.poke mdm.poke
	rename dm.pokeraw mdm.pokeraw
	rename dm.ping mdm.ping
	#...and then set generic functions to call membrane functions
	rename bmcdm.help dm.help
	rename bmcdm.send dm.send
	rename bmcdm.poke dm.poke
	rename bmcdm.pokeraw dm.pokeraw
	rename bmcdm.ping dm.ping
    } elseif { $device == "bmc1024"} {
	#Reset mdm functions to generic device functions...
	rename dm.help bmcdm1k.help
	rename dm.send bmcdm1k.send
	rename dm.poke bmcdm1k.poke
	rename dm.pokeraw bmcdm1k.pokeraw
	rename dm.ping bmcdm1k.ping
	#...and then set generic functions to call membrane functions
	rename bmcdm.help dm.help
	rename bmcdm.send dm.send
	rename bmcdm.poke dm.poke
	rename bmcdm.pokeraw dm.pokeraw
	rename bmcdm.ping dm.ping
    } elseif { $device == "tdm1024"} {
	#Reset mdm functions to generic device functions...
	rename dm.help tdm1k.help
	rename dm.send tdm1k.send
	rename dm.poke tdm1k.poke
	rename dm.pokeraw tdm1k.pokeraw
	rename dm.ping tdm1k.ping
	#...and then set generic functions to call membrane functions
	rename bmcdm.help dm.help
	rename bmcdm.send dm.send
	rename bmcdm.poke dm.poke
	rename bmcdm.pokeraw dm.pokeraw
	rename bmcdm.ping dm.ping
    } elseif { $device == "NULL" } {
	rename bmcdm.help dm.help
	rename bmcdm.send dm.send
	rename bmcdm.poke dm.poke
	rename bmcdm.pokeraw dm.pokeraw
	rename bmcdm.ping dm.ping
    }
    #if $device not one of above values, do nothing
    #At present, this situation cannot arise...

    set device "bmc140"

    set MAX_ACT 144
    set ACT_LINE_LENGTH 12
    set MAX_VOLT 120

    # Define file with a default zero voltage array for DM
    set ZeroFile c:/usr/aos/wavescope/src/lists/Zeros_bmc

    # MaskFile is an ascii file consisting of $NMAK_ACT integer elements
    # If file entry is = 1, actuator is used in generating recon, otherwise
    # it is skpped. It is loaded as $maskArray.
    set MaskFile c:/usr/aos/wavescope/src/lists/Mask_bmc.txt

    a.make 0 $MAX_ACT = CurDrv
    a.make 0 $MAX_ACT = volts

    for {set i 1} {$i <= $MAX_ACT} {incr i} {
	#To initalise to bias voltage:
	set acts($i) 0
	#To initalise to 0 Volts:
	#  set acts($i) -100
	#hdyson 8th Oct 03
	set selected($i) 0
    }

    set nmodes $MAX_ACT

    for { set i 0 } { $i < $nmodes } { incr i } {
	set mode($i) 0
	set modew($i) 1
	set mods($i) 0
    }

    a.loadasc $MaskFile i = maskArray
    closeLoopPanel
}

#---------------------------------------------------------------------------
# proc closeLoopPanel
# 
# Closed loop/mirror flattening control panel
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#---------------------------------------------------------------------------

proc closeLoopPanel {} {

    global closeLoopFlag integGain thresh wsdb
    global device

    if { [winfo exists .cl] } {
	destroy .cl
    }
    toplevel .cl
    wm title .cl "DM Controls"
    wm geometry .cl -30+90
    frame  .cl.f
    pack   .cl.f
    frame  .cl.f.clb -relief groove -bd 2
    button .cl.f.ok -text "  OK  " -font $wsdb(font) -command {endloop}
    pack   .cl.f.clb .cl.f.ok -padx 5 -pady 5

    set msg "$device DM Controls"
    set msgtwo "See file 'Before Using Wavescope' on Desktop"
    set msgthree "(In particular, before loading voltage file or using over-voltages)"
    message .cl.f.clb.msg -text $msg -aspect 1000 -font $wsdb(font)
    message .cl.f.clb.msgtwo -text $msgtwo -aspect 1000 -font $wsdb(font)
    message .cl.f.clb.msgthree -text $msgthree -aspect 1000 -font $wsdb(font)
    pack    .cl.f.clb.msg -padx 5 -pady 5
    pack    .cl.f.clb.msgtwo -padx 5 -pady 5
    pack    .cl.f.clb.msgthree -padx 5 -pady 5

    #  #button .cl.f.clb.poke -text "Poke DM..." -command { DM_GUI }

    if {$device == "membrane256"} {
	button .cl.f.clb.poke -text "Poke Membrane DM (single actuator)" -command { MDM_GUI }  
	button .cl.f.clb.pokeover -text "Over-voltage Poke Membrane DM" -command { MDM_OVER_GUI }  
	button .cl.f.clb.pokenine -text "Poke Membrane DM (9 acts)" -command { MDM_GUI_NINE }  
	button .cl.f.clb.poke25 -text "Poke Membrane DM (25 acts)" -command { MDM_GUI_25 }  
	button .cl.f.clb.loadar -text "Load Voltage file" -command { load_array_gui }  
	pack   .cl.f.clb.poke -side top -pady 5
	pack   .cl.f.clb.pokeover -side top -pady 5
	pack   .cl.f.clb.pokenine -side top -pady 5
	pack   .cl.f.clb.poke25 -side top -pady 5
	pack   .cl.f.clb.loadar -side top -pady 5
    } elseif {$device == "membrane1024"} {
	button .cl.f.clb.poke -text "Poke Membrane DM (single actuator)" -command { MDM1K_GUI }  
	button .cl.f.clb.pokeover -text "Over-voltage Poke Membrane DM" -command { MDM1K_OVER_GUI }  
	button .cl.f.clb.pokenine -text "Poke Membrane DM (9 acts)" -command { MDM1K_GUI_NINE }  
	button .cl.f.clb.poke25 -text "Poke Membrane DM (25 acts)" -command { MDM1K_GUI_25 }  
	button .cl.f.clb.loadar -text "Load Voltage file" -command { load_array_gui }  
	pack   .cl.f.clb.poke -side top -pady 5
	pack   .cl.f.clb.pokeover -side top -pady 5
	pack   .cl.f.clb.pokenine -side top -pady 5
	pack   .cl.f.clb.poke25 -side top -pady 5
	pack   .cl.f.clb.loadar -side top -pady 5
    } elseif {$device == "tdm1024"} {
	button .cl.f.clb.poke -text "Poke TDM (single actuator)" -command { T_GUI }  
	button .cl.f.clb.pokeover -text "Over-voltage Poke TDM" -command { T_OVER_GUI }  
	button .cl.f.clb.pokenine -text "Poke Membrane TDM (9 acts)" -command { T_GUI_NINE }  
	button .cl.f.clb.poke25 -text "Poke Membrane TDM (25 acts)" -command { T_GUI_25 }  
	#		button .cl.f.clb.loadar -text "Load Voltage file" -command { load_array_gui }  
	pack   .cl.f.clb.poke -side top -pady 5
	pack   .cl.f.clb.pokeover -side top -pady 5
	pack   .cl.f.clb.pokenine -side top -pady 5
	pack   .cl.f.clb.poke25 -side top -pady 5
	#		pack   .cl.f.clb.loadar -side top -pady 5
    } elseif {$device == "bmc1024"} {
	button .cl.f.clb.poke -text "Poke 1024 BMC DM (single actuator)" -command { BMCDM1K_GUI }  
	button .cl.f.clb.pokenine -text "Poke 1024 BMC DM (9 acts)" -command { BMCDM1K_GUI_NINE }  
	button .cl.f.clb.poke25 -text "Poke 1024 BMC DM (25 acts)" -command { BMCDM1K_GUI_25 }  
	button .cl.f.clb.loadar -text "Load Voltage file" -command { load_array_gui }  
	pack   .cl.f.clb.poke -side top -pady 5
	pack   .cl.f.clb.pokenine -side top -pady 5
	pack   .cl.f.clb.poke25 -side top -pady 5
	pack   .cl.f.clb.loadar -side top -pady 5
    } elseif { $device == "bmc140"} {
	button .cl.f.clb.poke -text "Poke BMC DM..." -command { DM_GUI }  
	button .cl.f.clb.loadar -text "Load Voltage file" -command { load_array_gui }  
	pack   .cl.f.clb.poke -side top -pady 5
    } else {
	#default to BMC device.  Change button for a warning
	button .cl.f.clb.poke -text "Poke Default DM..." -command { DM_GUI }  
	pack   .cl.f.clb.poke -side top -pady 5
    }

    frame .cl.f.clb.ctl
    pack  .cl.f.clb.ctl -anchor w -pady 5

#     if { $device == "tdm1024" } {
#     }
    if { $device == "impossible" } {
	update
    } else {

	button .cl.f.clb.ctl.mack -text "Make Recon..." -command { MakeReconPanel }  
	button .cl.f.clb.ctl.show -text "Display Modes..." -command { ShowModes }
	button .cl.f.clb.ctl.pick -text "Select Modes..." -command { PickModes }
	pack   .cl.f.clb.ctl.mack .cl.f.clb.ctl.show .cl.f.clb.ctl.pick \
	    -side left -padx 5

	frame .cl.f.clb.cll
	pack  .cl.f.clb.cll -anchor center -pady 5

	checkbutton .cl.f.clb.cll.colb -text "Close Loop Slow - with OPD display" \
	    -variable closeLoopFlag -command { clloop }

	frame .cl.f.clb.clp
	pack  .cl.f.clb.clp -anchor center -pady 5

	checkbutton .cl.f.clb.clp.cpsf -text "Close Loop Slow - with OPD and PSF" \
	    -variable closeLoopFlag -command { cllooppsf }

	frame .cl.f.clb.clo
	pack  .cl.f.clb.clo -anchor center -pady 5

	checkbutton .cl.f.clb.clo.cnod -text "Close Loop - with no display" \
	    -variable closeLoopFlag -command { clloopnodisplay }
	button      .cl.f.clb.cll.resp -text "Show Response" -command { ShowResp }
	pack        .cl.f.clb.cll.colb .cl.f.clb.cll.resp .cl.f.clb.clp.cpsf .cl.f.clb.clo.cnod

	frame .cl.f.clb.tt -relief groove -bd 2
	pack  .cl.f.clb.tt -pady 5
	frame .cl.f.clb.tt.ctl1
	pack  .cl.f.clb.tt.ctl1 -padx 26
	scale .cl.f.clb.tt.ctl1.scaleG -from 0 -to 100 -length 200 -orient horizontal\
	    -label "Gain" -variable integGain 
	pack  .cl.f.clb.tt.ctl1.scaleG -side left -padx 10

	update
    }
}

#---------------------------------------------------------------------------
# proc PickModes
# 
# Pick Modes GUI panel.  Allows user to select modes for use in closed
# loop operation, and select weights for each mode.  plk 12/21/2004.
#
# NOTE:  this procedure previously declared the global variable "modw,"
# which does not exist.  It is apparently a typo, referring to
# the variable "modew" which is initialized in the tdm_panel and
# similar procedures.  All references to "modw" in this file were
# changed to "modew." Modew is an array of weights for each mode.
# plk 12/21/2004
#
#
# called by: closelooppanel
#
# For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#---------------------------------------------------------------------------

proc PickModes {} {

       global nmodes modew wsdb loopType


    if { $loopType == "NULL" } {
	dialog "Please Make a Reconstructor first."
	return
    }

    if { [winfo exists .pm] } { destroy .pm }

    set nmodes [a.cols modew]
    a.ext modew 0 0 1 1 = mw
    set wgtVar [a.ave mw]

    toplevel    .pm
    wm title    .pm "Mode Selection Controls"
    wm geometry .pm +485+175
    frame       .pm.f
    pack        .pm.f
    message     .pm.f.msg -text "Choose the modes to correct with in closed loop.
Adjust their weights, if desired." -width 40c
    frame       .pm.f.pmb -relief groove -bd 2
    button      .pm.f.ok -text "  OK  " -font $wsdb(font) -command {destroy .pm}
    pack        .pm.f.msg .pm.f.pmb .pm.f.ok -padx 5 -pady 5

    frame       .pm.f.wgt
    pack 	      .pm.f.wgt
    scale       .pm.f.wgt.scale -from 0 -to 100 -resolution 0.01 \
	-length 250 -command {updateModew} -orient horizontal \
	-variable wgtVar
    pack        .pm.f.wgt.scale

    set ncols [expr int([expr $nmodes / 18.0])]

    set nrr [expr fmod($nmodes,18.0)]

    for {set j 0} { $j < $ncols} {incr j} {
	frame .pm.f.pmb$j
	pack  .pm.f.pmb$j -side left

	for {set i 0 } { $i < 18 } { incr i } {
	    set k [expr $i + $j * 18]
	    frame       .pm.f.pmb$j.m$i
	    pack        .pm.f.pmb$j.m$i -anchor w
	    checkbutton .pm.f.pmb$j.m$i.lt1 -text " $k " \
		-variable mode($k) -command "updateModes $k" -width 6
	    pack        .pm.f.pmb$j.m$i.lt1  -side left -padx 10
	}
    }
    frame  .pm.f.snb
    pack   .pm.f.snb -side left

    for { set i 0} { $i < $nrr } { incr i } {
	set k [expr 18 * $ncols + $i]
	frame       .pm.f.snb.n$i
	pack        .pm.f.snb.n$i -anchor w
	checkbutton .pm.f.snb.n$i.lt1 -text " $k " \
	    -variable mode($k) -command "updateModes $k" -width 6
	pack        .pm.f.snb.n$i.lt1  -side left -padx 10
    }

    update
}

#---------------------------------------------------------------------------
# proc updateModes
#
#
# filter each mode, selected by the user with the "Mode Selection
# Control" GUI.  If the user selects not to use a particular mode(s)
# then this procedure will set it to zero, so that it will not be
# used in closed loop operation.  plk 12/21/2004
#
# called by: pickModes
#
# For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#---------------------------------------------------------------------------

proc updateModes { mod } \
    {
	global modn nmodes mode wgtVar modew
	set modn $mod

	a.ext modew $mod 0 1 1 = mw
	set wgtVar [a.ave mw]
	for {set i 0} { $i < $nmodes } { incr i } \
	    {
		if { $i != $modn} { set mode($i) 0}
	    }
    }

#---------------------------------------------------------------------------
# proc updateModew
#
# modifies each mode with a weight factor, selected by the user
# with the "Mode Selection Control" GUI.  plk 12/21/2004
#
# NOTE:  this procedure previously declared the global variable "modw,"
# which does not exist.  It is apparently a typo, referring to
# the variable "modew" which is initialized in the tdm_panel and
# similar procedures.  All references to "modw" in this procedure were
# changed to "modew." Modew is an array of weights for each mode.
# plk 12/21/2004
#
# called by: pickModes
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#---------------------------------------------------------------------------

proc updateModew { weight } \
    {
	global modew modn doneit

	if { $doneit == 0 } \
	    {
		a.ext modew 0 0 1 1 = mw
		set weight [a.ave mw]
		set modn 0
		set doneit 1
	    }

	a.repele $weight modew $modn 0 = modew
    }

#---------------------------------------------------------------------------
# proc ShowModes
#
# Mode display control panel
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#---------------------------------------------------------------------------

proc ShowModes {} {

    global nmodes modew opd_idcl opd_wdcl lid movie wsdb loopType


    if { $loopType == "NULL" } {
	dialog "Please Make a Reconstructor first."
	return
    }

    if { [winfo exists .sm] } { destroy .sm }

    set movie 0
    set nmodes [a.cols modew]

    id.new opd_idcl
    id.set.title opd_idcl "Modal OPD"
    id.new lid
    id.set.title lid "Modal Curvature"
    id.set.xy opd_idcl 428 50
    id.set.wh opd_idcl 370 390
    id.set.xy lid 50 470
    id.set.wh lid 370 390
    wd.new opd_wdcl
    wd.set.title opd_wdcl "Modal OPD"
    wd.set.type opd_wdcl 4
    wd.set.pers opd_wdcl 2
    wd.set.color opd_wdcl cyan
    wd.set.hide opd_wdcl 2
    wd.set.xy opd_wdcl 50 50
    wd.set.wh opd_wdcl 370 390

    toplevel    .sm
    wm title    .sm "Mode Display Controls"
    #  wm geometry .sm -5-5
    wm geometry .sm +5+5
    #hdyson 27th Oct 03; will this open window on screen?
    frame       .sm.f
    pack        .sm.f
    message     .sm.f.msg -text "Choose the mode to display" -width 40c
    frame       .sm.f.smb -relief groove -bd 2
    pack        .sm.f.msg .sm.f.smb -padx 5 -pady 5 -side top

    set ncols [expr int([expr $nmodes / 13.0])]
    set nrr   [expr fmod($nmodes,13.0)]

    for {set j 0} { $j < $ncols} {incr j} {
	frame .sm.f.smb.f$j
	pack  .sm.f.smb.f$j -side left

	for {set i 0 } { $i < 13 } { incr i } {
	    set k [expr $i + $j * 13]
	    checkbutton .sm.f.smb.f$j.m$i -text " $k " -variable mods($k) \
		-command "showMode $k" -width 6
	    pack        .sm.f.smb.f$j.m$i -padx 5
	}
    }

    if {$nrr > 0} {
	frame  .sm.f.smb.lf
	pack   .sm.f.smb.lf -side left -anchor n
	for { set i 0} { $i < $nrr } { incr i } {
	    set k [expr 13 * $ncols + $i]
	    checkbutton .sm.f.smb.lf.n$i -text " $k " -variable mods($k) \
		-command "showMode $k" -width 6
	    pack        .sm.f.smb.lf.n$i -padx 5
	}
    }

    checkbutton .sm.f.movie -text MOVIE -variable movie -command {cycle}
    button      .sm.f.ok -text "   OK   " -command {destr} -font $wsdb(font)
    pack        .sm.f.movie .sm.f.ok -padx 25 -pady 5 -side left

    update
}

#---------------------------------------------------------------------------
# proc cycle
# 
# Puts up a movie of the selected mode as long as the movie button is checked.
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#---------------------------------------------------------------------------

proc cycle {} {

    global Drvs modenum movie

    set i 0	
    while {$movie == 1} {
	a.extrow Drvs $modenum = mod1
	a.extrow Drvs [expr $modenum + 1 ] = mod2
	set nnn [expr sin([expr $i * 0.2])]
	set ooo [expr cos([expr $i * 0.2])]
	a.mul mod1 $nnn = mod1
	a.mul mod2 $ooo = mod2
	a.add mod1 mod2 = mmm
	incr i
	if {$i > 3200} { set i 0 }

	set min [expr abs([a.min mmm])]
	set max [a.max mmm]
	if { $max > $min } { a.div mmm $max = CurDrv }
	if { $min > $max } { a.div mmm $min = CurDrv }

	SetGUIActs $CurDrv
	ftov $CurDrv  vvv
	dm.send vvv
	update
    }
}

#---------------------------------------------------------------------------
# proc destr
# 
# Cleans up from the ShowModes/movie capability.
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#---------------------------------------------------------------------------

proc destr {} {

    global opd_idcl opd_wdcl lid movie


    set movie 0
    set opd_idcl 0
    set opd_wdcl 0
    set lid 0
    destroy .sm
}

#---------------------------------------------------------------------------
# proc lap
# 
# Computes the DIVERGENCE of an input vector.  This procedure is named
# lap, reminiscient of laplacian, however my best understanding of the
# code below is that it takes only 1 derivative of the input data.
# Furthermore, the synatax of the calling procedure suggests that this
# procedure takes the divergence.  It is passed with a gradient, so
# the output of the implemented calling sequence is to produce a laplacian.
# plk 12/23/2004
#
#
# arguments:
#    vect     (input) a 2D array of Vector2 values to take the divergence of
#    lap      (output) the computed divergence, a 2D scalar array.
#
# called by:  calcLap
#
# For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#---------------------------------------------------------------------------

proc lap { vect lap } {

    upvar $lap lll

    a.v2toxy $vect = xg yg
    a.grad xg = dxg
    a.v2toxy dxg = dxx dxy
    a.grad yg = dyg
    a.v2toxy dyg = dyx dyy
    a.add dxx dyy = lll
}

#---------------------------------------------------------------------------
# proc conv
#
# Converts a list of positions and gradients to a regular 2D output
# gradient array and a weight mask.
#
# arguments:
#        vvvv    (input)  list of positions and gradients
#          vv    (output) 2D output gradient array
#
# see: alg.conv.pg.arrays documentation in Wavescope manual
# plk 12/23/2004
#
# called by:  calcLap
#
# For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#---------------------------------------------------------------------------

proc conv { vvvv vv } {

    global wlCalibrate
    upvar $vv vect

    alg.conv.pg.arrays $vvvv $wlCalibrate(Params) = vect mask
}

#---------------------------------------------------------------------------
# proc calcLap
#
# Calculate laplacian of the wavefront from its gradient.
#
# called by:  showMode, quiet1
#
# For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#---------------------------------------------------------------------------

proc calcLap {} {

    global Grad Lap


    conv $Grad gxgy
    lap $gxgy Lap
}


#---------------------------------------------------------------------------
# proc showMode
#
# Places a mode from the reconstructor creation onto the mirror.
#
# Performs actuator weighting. Must have setActuatorWeight(s) prior
# to executing this procedure.
# plk 01/10/2005
#---------------------------------------------------------------------------

proc showMode { mod } {

    global gActuatorWeight
    
    global opd_idcl modenum opd_wdcl wlCalibrate platform
    global Drvs nmodes mods Grad lid Lap CurDrv modew ZeroFile

    a.load $ZeroFile = Zoff
    set modenum $mod
    for { set i 0 } { $i < $nmodes } { incr i } {
	if { $i != $mod } { set mods($i) 0 }
    }

    a.extrow Drvs $mod = mmm

    set min [expr abs([a.min mmm])]
    set max [a.max mmm]
    if { $max > $min } { a.div mmm $max = CurDrv }
    if { $min > $max } { a.div mmm $min = CurDrv }
    a.add CurDrv Zoff = CurDrv

    # multiply drive signal by the ActuatorWeights in order to
    # have a weighted drive signal.  gActuatorWeight is a global
    # variable, and it is set in tdm_ClosedLoopProcedures::setActuatorWeight
    # plk 01/10/2005
    a.mul CurDrv gActuatorWeight = CurDrv

    SetGUIActs $CurDrv
    ftov $CurDrv vvv
    dm.send vvv

    puts [a.ext modew $mod 0 1 1 ])]
calcGrad 3
calcLap
id.set.array lid Lap
alg.conv.pg.arrays Grad wlCalibrate(Params) = gxgy mask
alg.recon.fast gxgy mask = opd
id.set.array opd_idcl opd
wd.set.array opd_wdcl opd
update
if { $platform == "windows" } {
    set min [a.min opd]
    set max [a.max opd]
    set pv [expr $max - $min]
    set pv [format %8.4f $pv]
    set rms [a.rms opd]
    set rms [format %8.4f $rms]
    id.clr.text opd_idcl
    id.set.text.coords opd_idcl 0
    id.set.text.align opd_idcl -1 1
    id.set.text.color opd_idcl 1.0 1.0 0.3
    id.set.text opd_idcl "PV  = $pv microns" 10 10
    id.set.text opd_idcl "RMS = $rms microns" 10 25  
} 
update
}

##---------------------------------------------------------------------------
##
## Clean up from closed loop
## 
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
##---------------------------------------------------------------------------

proc endloop { } \
    {
	global closeLoopFlag

	set closeLoopFlag 0

	destroy .cl
    }

#---------------------------------------------------------------------------
# proc ShowResp
# 
# Plot response from closed loop
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#---------------------------------------------------------------------------

proc ShowResp {} {

    global mds Drives rid rwd rpd wsdb loopType


    if { $loopType == "NULL" } {
	dialog "The loop must be Closed and Opened first."
	return
    }

    if { [winfo exists .sr] } { destroy .sr }

    id.new rid
    wd.new rwd
    wd.set.type rwd 4
    wd.set.pers rwd 2
    wd.set.color rwd yellow
    wd.set.hide rwd 2
    wd.set.title rwd "Loop Response"
    pd.new rpd
    id.set.title rid "Loop Response"
    id.set.colormap rid 2
    pd.set.title rpd "Loop Response"

    id.set.xy rid 50 50
    id.set.wh rid 370 390
    wd.set.xy rwd 50 470
    wd.set.wh rwd 370 390
    pd.set.xy rpd 428 50
    pd.set.wh rpd 600 300

    toplevel    .sr
    wm title    .sr "Loop Response Display Controls"
    wm geometry .sr +885+675 
    frame       .sr.f
    pack        .sr.f
    message     .sr.f.msg -text "Choose the data to display" -width 40c
    frame       .sr.f.srb -relief groove -bd 2

    radiobutton .sr.f.mod -variable dtype -text "modal error signals" \
	-value "modes" -command doit
    radiobutton .sr.f.drv -variable dtype -text "drive signals" \
	-value "drives" -command doit

    button      .sr.f.ok -text "  OK  " -font $wsdb(font) -command {destry}
    pack        .sr.f.msg .sr.f.srb .sr.f.mod .sr.f.drv .sr.f.ok -padx 5 -pady 5
}

#---------------------------------------------------------------------------
# proc doit
# 
# Wrapper to call appropriate plot function for closed loop response?
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#---------------------------------------------------------------------------

proc doit {} \
    {
	global rid rwd mds Drives dtype
	if { $dtype == "drives" } \
	    { 
		id.set.array rid Drives 
		wd.set.array rwd Drives
		plotit $Drives
	    }
	if { $dtype == "modes"  } \
	    { 
		id.set.array rid mds 
		wd.set.array rwd mds
		plotit $mds
	    }
    }

#---------------------------------------------------------------------------
# proc doit
# 
# Plot functions for closed loop response?
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#---------------------------------------------------------------------------

proc plotit { data } \
    {
	global rpd

	set colors { white red yellow green cyan blue magenta }
	set i 0
	foreach item $colors \
	    {
		a.extcol $data $i = tmp
		if { $i == 0 } { pd.set.y.array rpd tmp } \
		    else \
		    { pd.add.y.array rpd tmp }
		pd.set.color rpd $item
		incr i
	    }
    }

#---------------------------------------------------------------------------
# proc destry
# 
# Clean up after plot functions?
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#---------------------------------------------------------------------------

proc destry {} \
    {
	global rid rwd rpd
	set rid 0
	set rwd 0
	set rpd 0
	destroy .sr
    }

#---------------------------------------------------------------------------
# proc MakeReconPanel
# 
# Reconstructor control panel
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#---------------------------------------------------------------------------

proc MakeReconPanel {} { 

    global wsdb


    if { [winfo exists .mr] } { destroy .mr }

    toplevel .mr
    wm title .mr "Reconstructor Controls"
    wm geometry .mr +515+400 
    frame    .mr.f
    pack     .mr.f
    frame    .mr.f.mrb -relief groove -bd 2
    button   .mr.f.ok -text "  OK  " -font $wsdb(font) -command {destroy .mr}
    pack     .mr.f.mrb .mr.f.ok -padx 5 -pady 5

    set msg "Reconstructor Controls"
    message .mr.f.mrb.msg -text $msg -aspect 1000
    pack    .mr.f.mrb.msg -padx 5 -pady 5

    frame .mr.f.mrb.ctl
    pack  .mr.f.mrb.ctl -pady 5

    button .mr.f.mrb.ctl.poke -text " Make Poke Recon " -command { MPR }

    pack   .mr.f.mrb.ctl.poke  -side left -padx 10

    frame .mr.f.mrb.ctm
    pack  .mr.f.mrb.ctm -pady 5

    button .mr.f.mrb.ctm.madk -text "Make Modal Recon" -command { MMR }

    pack   .mr.f.mrb.ctm.madk  -side left -padx 10

    frame .mr.f.mrb.ctn
    pack  .mr.f.mrb.ctn -pady 5

    button .mr.f.mrb.ctn.madk -text "Make restricted Poke Recon" -command { MrPR }

    pack   .mr.f.mrb.ctn.madk  -side left -padx 10

}

#---------------------------------------------------------------------------
# procs MPR MMR MRR RMR
#
# These procedures are boilerplate to create the different reconstructors.
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#---------------------------------------------------------------------------

proc MPR {} {
    global loopType ModFlg wlCalibrate stagePos

    if { $wlCalibrate(doneInit) != "Yes" } {
	dialog "Please Calibrate WaveScope."
	return
    }
    stage.calibrate.absolute $stagePos(BestRefSpots)
    set ModFlg Poke
    quiet
    makerecon
    set loopType Mat
}

proc MMR {} {
    global loopType ModFlg wlCalibrate stagePos

    if { $wlCalibrate(doneInit) != "Yes" } {
	dialog "Please Calibrate WaveScope."
	return
    }
    stage.calibrate.absolute $stagePos(BestRefSpots)
    set ModFlg Mod
    quiet
    makerecon
    set loopType Mat
}

proc MRR { } {
    global NRP loopType ModFlg wlCalibrate stagePos

    if { $wlCalibrate(doneInit) != "Yes" } {
	dialog "Please Calibrate WaveScope."
	return
    }
    stage.calibrate.absolute $stagePos(BestRefSpots)
    set ModFlg Poke
    noisy $NRP
    makerecon
    set loopType Mat
}

proc RMR { } {
    global NRP loopType ModFlg wlCalibrate stagePos

    if { $wlCalibrate(doneInit) != "Yes" } {
	dialog "Please Calibrate WaveScope."
	return
    }
    stage.calibrate.absolute $stagePos(BestRefSpots)
    set ModFlg Mod
    noisy $NRP
    makerecon
    set loopType Mat
}

#---------------------------------------------------------------------------
# procs MrPR
#
# This procedure generates reconstructor over a subset of actuators.
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#---------------------------------------------------------------------------

proc MrPR {} {
    global loopType ModFlg wlCalibrate stagePos

    if { $wlCalibrate(doneInit) != "Yes" } {
	dialog "Please Calibrate WaveScope."
	return
    }
    stage.calibrate.absolute $stagePos(BestRefSpots)
    set ModFlg Poke

    # quiet_restricted
    # this procedure is located in tdm_ClosedLoopProcedures.tcl
    # it replaces quiet_restricted
    pokeBinnedActuators_quiet

    makerecon
    set loopType Mat
}

#---------------------------------------------------------------------------
# proc ftov
#
# Computes the voltages required to generate an array of desired deflections
# of the deformable mirror.
#
# This procedure uses empirically derived conversion factors based on
# data in the summary report "Preliminary Data from Transparent Electrode
# Membrane Device 11-17-2004-A" by P. Kurczynski (12/6/2004).  The following
# data were obtained from actuation of 2x2 binned actuators of the membrane
# device.  The predicted voltage for a given deflection is computed from
# a simple quadratic model based on this data:
#
#    2x2 electrode voltage, deflection data from device 11-17-2004-A
#
#     n_d      Deflection*, um   V_exp  V^2_exp   V^2_model   V_model
#   --------   --------------   -----  -------   ---------   -------
#     0              0            0 V       0          0          0
#                    1           20 V     400       1000         31
#                    3           40 V    1600       3000         54
#     1              7           80 V    6400       7000         83
#
# * these deflections are toward the electrode array.
#
#
# The model:  Voltage [V] = sqrt(  a[0] * Deflection [um] ); a[0] = 1000
# is based on linear approximation to the data in columns 2, 4 above.
#
# Deflection [um] data is *somewhat arbitrarily* related to normalized
# deflection values, n_d, as indicated in column 1-2.
#
# i.e.  Deflection [um] = a[1] * n_d; a[1] = 7.0                          [1]
#
# The normalized deflection values are in the range [-1,1] with +1 being
# interpreted as maximum deflection toward the electrode array, -1 being
# interpreted as maximum deflection toward the top electrode (away from
# the electrode array).
#
# Using these data and assumptions, the following model is obtained for
# converting Normalized deflection values to voltages:
#
#  V_relative [V] = sqrt( a[0]*a[1]*abs(n_d) ); a[0] = 1000; a[1] = 7.0   [2]
#
# This model is appropriate for the device being used in 2x2 binning
# mode.  The constants a[0], a[1] should in principle be modified for
# other binning schemes, based upon empirical voltage vs. deflection
# data. This adjustment may also be done by adjusting theTunableParameter
# discussed below.
#
# Because the electrode binning scheme may vary significantly, and because
# the actual response of the membrane may deviate from the model signif-
# icantly, a tunable parameter is incorporated into the procedure as
# follows:
#
# V_rel__tuned [V] = theTunableParameter * V_relative                    [3]
#
# where V_relative is given by Equation [2] above.  Some typical values of
# the tunable parameter, and the resulting correspondence between norm-
# alized deflection and output voltage are indicated below:
#
# THESE DATA WERE TAKEN WITH DEVICE 11-17-2004-A
#
# theTunableParameter     n_d       outV, V
# -------------------     ---       -------
#       0.100             0.5         5.9
#       0.500             0.5        29.0
#       1.000             0.5        59.0
#       0.250             1.0        20.0
#       0.500             1.0        41.0
#
# Values of theTunableParameter used in experiments:
#
# Binning        theTunableParameter    "Poke Voltage"      Date
# -------        -------------------    --------------    ----------
#  3x3                 0.375                              01/12/2005
#  2x2                 0.500                 41 V         01/14/2005
#
#
# "Poke Voltage" is the voltage that is reported in DEBUG statements
# during poke matrix construction.
#
#The final output voltage is set to the bias voltage +/- this relative
# voltage depending upon whether downward (n_d>0) or upward (n_d<0)
# deflections are indicated.  Accordingly, the final output voltage is
# given by:
#
# outVoltage [V] = BiasVoltage  +  Sign * V_rel__tuned                   [4]
#
# where Sign = -1 if n_d<0   deflection AWAY from electrode array
#            = +1 if n_d>0   deflection TOWARD electrode array.
#
# Nominally, a biased membrane mirror will be set so that outVoltage = 0
# corresponds to maximum upward deflection of the membrane.  Hence the
# bias voltage is set to be numerically equal to the value of V_rel_tuned
# that is obtained when n_d = -1.  In this software, the bias voltage is
# indicated by the global variable Varray, and it is set at the top of
# this file (dm_panels_5dms.tcl).
#
# parameters:
#
# inNormDeflection          input array of values in the range [-1,1]
#                           for conversion to scaled, adjusted voltages.
#
# outV            output array of voltages in the range [Varray - DeltaV,
#                 Varray + DeltaV]  where Varray is the (bias) voltage
#                 applied to the entire array.
#
# Note:  This version of ftov is only implemented for tdm1024 devices.
#
#
# plk 08/29/2005
#---------------------------------------------------------------------------
proc ftov { inNormDeflection outV } {

    global deltaV Varray
    global device

    upvar $outV theOutVdb

    #DEBUG
    #puts stdout "ftov:  Device = $device"
    #puts stdout "    inNormDeflection = [a.dump inNormDeflection]"
    #puts stdout "    outV = [a.dump theOutVdb]"
    #puts stdout "    Vbias  = $Varray"
    #puts stdout "    deltaV = $deltaV"


    #====================
    # Device 11-17-2004-A
    #====================
    # These parameters are appropriate for device 11-17-2004-A
    # ie. the 1st transparent electrode mdm, installed in the
    # AO system ~ 1/2005, and 1st replaced by the second device
    # in ~08/2005.
    # see notes above for setting theTunableParameter
    set theTunableParameter     0.500
    set theV2_2x2ToMicrons       1000
    set theNdToMicrons              7



    #====================
    # Device 10-11-2004-C
    #====================
    # These parameters are appropriate for device 10-11-2004-C
    # They were derived from data taken on 08/26/2005.  They
    # are appropriate for 5x5 (NOT 2x2) electrode binning.  See
    # notes:  ftov calibration, and Excel spreadsheet: kraken\
    # wavescope\kraken\device\10-11-2004-C\ftov calibration\
    # ftov_calibration_v1.xls
    #set theTunableParameter     0.8

    # Parameter tuned for 4x4 binning
    #set theTunableParameter     1.2
    #set theV2_2x2ToMicrons     70.0
    #set theNdToMicrons         20.0



    set theConvFactor [expr $theV2_2x2ToMicrons*$theNdToMicrons]
    set theSqrtConvFactor [expr $theTunableParameter*sqrt($theConvFactor)]

    if { $device == "tdm1024" } {

	a.abs $inNormDeflection = theAbsNormD
	a.div $inNormDeflection $theAbsNormD = theSign

        a.sqrt $theAbsNormD = theSqrtNormD
        a.mul $theSqrtNormD $theSqrtConvFactor = theVrelative
        a.mul $theVrelative $theSign = theVrelative
        a.add $theVrelative $Varray = theOutV

	a.limlow theOutV 0 = theOutV
	a.to theOutV d = theOutVdb

        #DEBUG
        #puts stdout "ftov:    outV = [a.dump theOutVdb]"

    } else {
	set theErrMsg "ftov not implemented for this device."
        error $theErrMsg
    }
}

#---------------------------------------------------------------------------
# proc noisy
#
# Pokes each actuator and records the gradients, uses uniform noise to
# introduce a random element.
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#---------------------------------------------------------------------------

proc noisy { n } {

    global Grad gvd CurDrv Drvs Grds MAX_ACT


    # Display gradients while we work.
    #
    vd.new gvd
    vd.set.title gvd "Measured (random influence) Gradient"
    vd.set.xy gvd 50 50
    vd.set.wh gvd 300 300


    # Poke each actuator from 0..1, and calculate the gradient.
    #
    a.make 0 $MAX_ACT = Zero
    for { set i 0 } { $i < $n } { incr i } {
	puts "Poking actuator: $i"
	a.uniformnoise Zero 2 = fracDrv 
	ftov $fracDrv CurDrv
	if { $i == 0 } { a.copy fracDrv = Drvs } \
	    else { a.catrow Drvs fracDrv = Drvs}

        # mistake here?  dm.send should have voltages as
        # an argument, NOT CurDrV!!   plk 12/18/2004
	dm.send CurDrv

	update
	calcGrad 10
	vd.set.array gvd Grad
	if { $i == 0 } { a.copy Grad = Grds } \
	    else { a.catrow Grds Grad = Grds }

	update
    } 
    a.make 0 $MAX_ACT = CurDrv


    # Uncomment these next two lines to save the
    # calculated drive signal and gradients to disk.
    #
    a.save Drvs Drvs
    a.save Grds Grds 

    set gvd 0  
}

#---------------------------------------------------------------------------
# proc quiet
# 
# Pokes each actuator and records the gradients (no noise)
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#---------------------------------------------------------------------------

proc quiet { } {

    global Grad gvd CurDrv Drvs Grds MAX_ACT maskArray pokeFraction
    global wlCalibrate

    # Display gradients while we work.
    #
    vd.new gvd
    vd.set.title gvd "Measured Gradient"
    vd.set.xy gvd 50 50
    vd.set.wh gvd 300 300

    # make some arrays of zeros to use to fill matrices
    # when we reach dead actuators
    set nsubs [a.cols wlCalibrate(FinalCenters)]
    a.make 0 $MAX_ACT = zeros
    a.make "< 0 0 >" $nsubs = gzeros

    # Poke each actuator from 0..1, and calculate the gradient.
    #
    FlatDM
    a.copy CurDrv = CurDrv0

    for { set i 0 } { $i < $MAX_ACT } { incr i } {
	if { [ a.extele maskArray $i ] == 1 } {
	    puts "Poking actuator: $i"
	    a.make 0 $MAX_ACT = CD

	    #	    a.make -1 $MAX_ACT = CD
	    #Changed above to make reconstructor from 0V rather than bias volt position
	    #hdyson 10th Oct 03
	    a.repele $pokeFraction CD $i = CD
	    a.add CD CurDrv0 = CurDrv
	    SetGUIActs $CurDrv
	    ftov $CurDrv uuu
	    dm.send uuu
	    update
	    calcGrad 10
	    vd.set.array gvd Grad
	} else {
	    #
	    #	
	    #	Added code to put zero gradients in as well as zero drives
	    #
	    #
	    puts "Skipping actuator: $i"
	    a.copy zeros = CD
	    a.v2v2tov4 wlCalibrate(FinalCenters) gzeros = Grad
	}
	if { $i == 0 } { a.copy CD = Drvs } \
	    else { a.catrow Drvs CD = Drvs}
	if { $i == 0 } { a.copy Grad = Grds } \
	    else { a.catrow Grds Grad = Grds }
	update
    } 
    a.make 0 $MAX_ACT = CurDrv

    # Uncomment these next two lines to save the
    # calculated drive signal and gradients to disk.
    #
    a.save Drvs Drvs
    a.save Grds Grds 

    set gvd 0  
}


#---------------------------------------------------------------------------
# proc quiet_restricted
# 
# Pokes each actuator and records the gradients (no noise)
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#---------------------------------------------------------------------------

proc quiet_restricted { } {

    global Grad gvd CurDrv Drvs Grds MAX_ACT maskArray pokeFraction
    global wlCalibrate YACT_LINE_LENGTH XACT_LINE_LENGTH 

#    a.make 0 MAX_ACT=uuu
#    a.to uuu uc = uuu

    # Display gradients while we work.
    #
    vd.new gvd
    vd.set.title gvd "Measured Gradient"
    vd.set.xy gvd 50 50
    vd.set.wh gvd 300 300

    # make some arrays of zeros to use to fill matrices
    # when we reach dead actuators
    set nsubs [a.cols wlCalibrate(FinalCenters)]
    a.make 0 $MAX_ACT = zeros
    a.make "< 0 0 >" $nsubs = gzeros

    # Poke each actuator from 0..1, and calculate the gradient.
    #
    FlatDM
    a.copy CurDrv = CurDrv0

    # To implement binning of actuators, change incr i to " incr i 2 "
    # (& similar for j), and put a for loop wrapper around the
    # a.repele line to replace a bin of actuators of the correct size
    # (note: need to map 2D i,j coord to $count)

    set count 0
    
    # define 
    for { set i 0 } { $i < $XACT_LINE_LENGTH } { incr i } {
	for { set j 0 } { $j < $YACT_LINE_LENGTH } { incr j } {
	    if { $i>7 && $i < 12 && $j>7 && $j<12} {
		if { [ a.extele maskArray $count ] == 1 } {
		    puts "Poking actuator: $j x $i"
		    a.make 0 $MAX_ACT = CD

		    #	    a.make -1 $MAX_ACT = CD
		    #Changed above to make reconstructor from 0V rather than bias volt position
		    #hdyson 10th Oct 03
		    a.repele $pokeFraction CD $count = CD
		    a.add CD CurDrv0 = CurDrv
		    SetGUIActs $CurDrv

		    ftov $CurDrv uuu

                    # make reconstructor attempts fail here.  uuu should
                    # be an unsigned char but it is apparently not.
		    # uuu should be type d for transparent electrode.
		    dm.send uuu
		    update
		    calcGrad 10
		    vd.set.array gvd Grad
		} else {
		    #
		    #	
		    #	Added code to put zero gradients in as well as zero drives
		    #
		    #
		    puts "Skipping actuator: $j x $i"
		    a.copy zeros = CD
		    a.v2v2tov4 wlCalibrate(FinalCenters) gzeros = Grad
		}
	    } else {
		puts "Actuator out of range: $j x $i"
		a.copy zeros = CD
		a.v2v2tov4 wlCalibrate(FinalCenters) gzeros = Grad
	    }
	    if { $count == 0 } { a.copy CD = Drvs } \
		else { a.catrow Drvs CD = Drvs}
	    if { $count == 0 } { a.copy Grad = Grds } \
		else { a.catrow Grds Grad = Grds }
	    incr count

	    update
	} 
    }
    a.make 0 $MAX_ACT = CurDrv

    # Uncomment these next two lines to save the
    # calculated drive signal and gradients to disk.
    #
    a.saveasc Drvs Drvs
    a.saveasc Grds Grds 

    set gvd 0  
}


#---------------------------------------------------------------------------
# proc quietl
# 
# Pokes each actuator and records the laplacian curvature (no noise)
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#---------------------------------------------------------------------------

proc quietl { } {

    global Grad gvd CurDrv Drvs Grds Lap MAX_ACT


    # Display laplacian while we work.
    #
    id.new gvd
    id.set.title gvd "Measured Laplacian"
    id.set.xy gvd 50 50
    id.set.wh gvd 500 500


    # Poke each actuator from 0..1, and calculate the laplacian curvature.
    #
    a.make 0 $MAX_ACT = CurDrv0
    for { set i 0 } { $i < $MAX_ACT } { incr i } \
	{
	    puts "Poking actuator: $i"
	    a.repele 1 CurDrv0 $i = CurDrv

	    if { $i == 0 } { a.copy CurDrv = Drvs } \
		else { a.catrow Drvs CurDrv = Drvs}

	    ftov $CurDrv uuu
	    dm.send uuu
	    update
	    calcGrad 10
	    calcLap
	    id.set.array gvd Lap

	    if { $i == 0 } { a.copy Lap = Grds } \
		else { a.catpln Grds Lap = Grds }

	    update
	} 
    a.make 0 $MAX_ACT = CurDrv


    # Uncomment these next two lines to save the
    # calculated drive signal and gradients to disk.
    #
    a.save Drvs Drvs
    a.save Grds Laps 

    set gvd 0  
}


##---------------------------------------------------------------------------
##
## Calculates gradients by grabbing 'n' images and averaging over the images
##
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
##---------------------------------------------------------------------------

proc calcGrad { n } \
    {
	global wlCalibrate Grad


	# Grab the image(s)
	#
	if [ catch { fg.grab $n = bigim } result ] {
	    catch { fg.grabc $n = bigim } 
	}
	set ncol [a.cols wlCalibrate(FinalTestRects)]


	# Depending on the number of images grabbed, do the average.
	#
	if { $n == 1 } \
	    {  
		alg.fit.spots bigim wlCalibrate(FinalTestRects) = pos
	    } \
	    else \
	    {
		for { set i 0 } { $i < $n } { incr i } \
		    {
			a.extpln bigim $i = tempim
			alg.fit.spots tempim wlCalibrate(FinalTestRects) = pos
			if { $i == 0 } { a.copy pos = sum } else { a.catrow sum pos = sum }
		    }
		a.rebin sum 1 $n = pos
		a.shape pos $ncol = pos
	    }

	a.sub pos wlCalibrate(RefPos) = diff
	a.sub diff [a.ave diff] = diff
	a.v2toxy diff = dxx dyy
	a.mul dxx $wlCalibrate(micronsPerPix) = dxx
	a.mul dyy $wlCalibrate(micronsPerPix) = dyy
	a.xytov2 dxx dyy = diff
	a.v2v2tov4 wlCalibrate(FinalCenters) diff = Grad

        #DEBUG
        #puts "Now in calcGrad:"
        #puts [a.ave Grad]


	update
    }

##---------------------------------------------------------------------------
##
## Makes the reconstructor matrix from Drvs and Grds
##
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
##---------------------------------------------------------------------------

proc makerecon {} \
    {
	global Drvs Grds Recon modew thresh
	global ModFlg 
	global thresh pthresh condth pokeFraction

	# for debug
	global gmm mrat Wmask

	a.saveasc $Drvs Drvs
	a.saveasc $Grds Grds
	#    a.saveasc $Recon Recon
	#    a.saveasc $modew modew
	a.saveasc $thresh thresh
	#    a.saveasc $ModFlg Modflg
	puts $ModFlg 
	a.saveasc $pthresh pthresh
	a.saveasc $condth condth

	puts "Beginning reconstructor calculations..."

	if { [a.rank Grds] == 3}\
	    {
		set nnn [expr [a.cols Grds] * [a.rows Grds]]
		set mmm [a.plns Grds]
		a.shape Grds $nnn $mmm = ggg
	    } else \
	    {
		# Strip off the unused position planes from Grds
		#
		a.split Grds = px py gx gy
		a.catcol gx gy = ggg

		# Eliminates gradients below the threshold.
		# This reduces the noise in the reconstructor calculation
		#
		a.to gx gy com = gcc
		a.amp gcc = gaa
		set fthresh [expr $thresh * $pokeFraction  / 100.0]
		a.cut gaa $fthresh = gmm
		a.catcol gmm gmm = gmm
		a.mul ggg gmm = ggg

		a.saveasc $gmm gmm

	    }

	#
	# Do some statistics on response matrix to determine which 
	# actuators have a noticeable effect on WFS measurements.
	# mrat is a mask to be used to eliminate ineffective actuators
	# by setting the coresponding reconstructor row to zero
	#

	a.statcol gaa = min max ave rms
	set fpthresh [expr $pthresh * $pokeFraction / 100.0]
	a.cut max $fpthresh = mrat

	a.saveasc $mrat mrat

	# After this, we should have a square autocorrelation array.
	#
	a.transpose ggg = gt
	a.matprod ggg gt = au

	a.saveasc $au au

	# Do singular value decomposition
	#
	a.matsvd au = U W Vt

	# Create a "poke" reconstructor
	#
	a.transpose U = Ut

	#
	#
	# Threshold singular values
	#
	#
	set minw [expr [a.max W] / $condth ]
	a.cut W $minw = Wmask
	a.mul W Wmask = W

	a.saveasc $Wmask Wmask

	a.inv W = Wi
	a.transpose Vt = V

	a.matprod V Wi = tmp
	a.matprod tmp Ut = Inv

	a.matprod Inv ggg = Recon
	a.matprod Vt Drvs = B
	set ncol [ a.rows Drvs ]

	if { $ModFlg == "Poke" } \
	    {
		a.make 1 $ncol 1 = modew

		#
		# Now use the mask mrat to remove all the offending rows of
		# the reconstructor
		#

		a.transpose Recon = noceR
		a.mul noceR mrat = noceR
		a.transpose noceR = Recon

	    }
	if { $ModFlg == "Mod" } \
	    {
		# Augment the poke reconstructor to a full mode-weighted reconstructor
		#
		makegs $Grds hhh	
		a.matprod Vt hhh = Mg
		a.matprod Wi Mg = Recon
		a.copy B = Drvs
		a.sqrt W = w
		a.rebin w 1 $ncol = modew
		a.mul modew $ncol = modew
	    }
	a.saveasc $gmm gmm
	a.saveasc $mrat mrat
	a.saveasc $Wmask Wmask

	puts "Reconstructor complete.  Ready for closed loop operation."
	puts "Number of modes found is $ncol (Well, maybe, this bit of code needs verification...)."
    }

##---------------------------------------------------------------------------
##
## Converts 1D V4 gradients array into 2D scalar array with Xs, then Ys
## 
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
##---------------------------------------------------------------------------

proc makeg { pgrad ggg } \
    {
	upvar $ggg tmp


	set nnn [expr 2 * [ a.cols $pgrad ]]
	a.split $pgrad = px py gx gy
	a.catcol gx gy = tmp
	a.shape tmp 1 $nnn = tmp
    }



##---------------------------------------------------------------------------
##
## Converts 2D V4 gradients array into 2D scalar array with Xs, then Ys
##
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
##---------------------------------------------------------------------------

proc makegs { pgrad ggg } {

    upvar $ggg tmp


    if { [a.rank $pgrad] == 3} {
	set nnn [expr [a.cols $pgrad] * [a.rows $pgrad]]
	set mmm [a.plns $pgrad]
	a.shape $pgrad $nnn $mmm = tmp
    } else {
	set nnn [expr 2 * [ a.cols $pgrad ]]
	set mmm [ a.rows $pgrad ]
	a.split $pgrad = px py gx gy
	a.catcol gx gy = tmp
	a.shape tmp $nnn $mmm = tmp
    }
}

##---------------------------------------------------------------------------
##
## closeloop - Actual flattening routine
## 
#  This is the procedure where the closed loop (with OPD) operation
#  takes place. plk 12/20/2004
#
#
# For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#
#---------------------------------------------------------------------------

proc closeloop {} {

    global Grad Drive Drives CurDrv ivd Recon Drvs Drerr
    global modew mds integGain closeLoopFlag wlCalibrate
    global MAX_ACT platform maskArray


    # Put up an image of the wavefront so the user can watch the
    # the loop perform its magic.
    #
    set ncol [ a.rows Drvs ]
    set i 0
    id.new opd_ivd
    id.set.title opd_ivd "Current Wavefront Shape"
    id.set.xy opd_ivd 5 360
    id.set.wh opd_ivd 300 300
    if {$platform != "windows"} {
	id.set.minmax opd_ivd -1 1
    }

    # As long as the 'closeLoop' button on the panel is set,
    # keep trying to flatten the mirror.
    #
    while { $closeLoopFlag == 1 } {
	# The calculations are basically standard adaptive optics fare.
	# Use the reconstructor to produce a set of voltages for the
	# mirror, tempering the aggressiveness of the correction by the
	# 'integGain' selected by the user.
	#
	calcGrad 3
	alg.conv.pg.arrays Grad wlCalibrate(Params) = gxgy mask
	alg.recon.fast gxgy mask = opd
	if { $opd_ivd != 0 } {
	    set rms [a.rmsmask opd mask]
	    id.set.array opd_ivd opd $rms
	    if { $platform == "windows" } {
		set min [a.min opd]
		set max [a.max opd]
		set pv [expr $max - $min]
		set pv [format %8.4f $pv]
		set rms [format %8.4f $rms]
		id.clr.text opd_ivd
		id.set.text.coords opd_ivd 0
		id.set.text.align opd_ivd -1 1
		id.set.text.color opd_ivd 1.0 1.0 0.3
		id.set.text opd_ivd "PV  = $pv microns" 10 10
		id.set.text opd_ivd "RMS = $rms microns" 10 25
	    }
	}
	update
	makeg $Grad ggg
	a.matprod Recon ggg = mod

	a.shape mod $ncol 1 = mod
	a.mul mod modew = mod
	if { $i == 0 } {
	    a.copy mod = mds
	} else {
	    a.catrow mds mod = mds
	}


	a.matprod mod Drvs = Drerr
	a.shape Drerr $MAX_ACT = Drerr
	set gain [expr $integGain / -100.]
	a.mul Drerr $gain = Drerr

	# This section addresses the fact that average piston is unobservable
	# We prevent the mean value of the active actuator drives from drifting
	# away from its initial value.
	#
	# subtract average drive to keep things in line



        # procedure dies with error here.
        # plk 12/20/2004
	#a.sub Drerr [a.avemask Drerr maskArray] = Drerr


        
	#    a.sub Drerr [a.minmask Drerr maskArray] = Drerr
	#    puts stdout [a.minmask Drerr maskArray]
	#    puts stdout [a.maxmask Drerr maskArray]
	#    puts stdout [a.avemask Drerr maskArray]
	#    a.sub Drerr 1 = Drerr
	#    a.sub Drerr [expr {1.0 + [a.minmask Drerr maskArray]}] = Drerr
	#hdyson 9th Oct

	a.add CurDrv Drerr = CurDrv

	# apply the mask to assure no unwanted drives
	#    a.mul CurDrv maskArray = CurDrv
	#hdyson 9th Oct

	# Limit the drive signals to the allowed range
	#    a.lim CurDrv 1 = CurDrv
	#Upper limiting now done in dm.send function
	a.limlow CurDrv -1 = CurDrv

	# Added another avg subtract to keep drives in line
	# after limiting


        # procedure dies with error here.
        # plk 12/20/2004
	#a.sub Drerr [a.avemask Drerr maskArray] = Drerr



	#    a.sub CurDrv [expr {0.5 + [a.avemask CurDrv maskArray]}] = CurDrv
	#    puts stdout [a.minmask CurDrv maskArray]
	#    puts stdout [a.maxmask CurDrv maskArray]
	#    puts stdout [a.avemask CurDrv maskArray]
	#    a.sub Drerr 1 = Drerr
	#hdyson, 9th Oct

	#Addition for setting drive voltage to immobile actuators to -1 (ie 0V)
	for { set index 0 } { $index < $MAX_ACT } { incr index } {
	    if { [ a.extele maskArray $index ] == 0 } {
		a.repele -1 CurDrv $index = CurDrv
	    }
	}
	#hdyson, 9th Oct




	SetGUIActs $CurDrv
	ftov $CurDrv Drive

	if { $i == 0 } {
	    a.copy Drive = Drives
	} else {
	    a.catrow Drives Drive = Drives
	}

        #DEBUG
        puts stdout "dm_panels_5dms.tcl::closeloop: Drive"
        a.dump Drive
        # end DEBUG plk 8/29/2005

	dm.send Drive

	puts "Closed loop iteration: $i"
	incr i
	update
    }
    set opd_ivd 0
}

#---------------------------------------------------------------------------
# proc clloop
#
# This function is called from the GUI to kick off the regular closed loop.
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#---------------------------------------------------------------------------

proc clloop {} {

    global closeLoopFlag loopType


    if { $loopType == "NULL" } {
	dialog "Please Make a Reconstructor first."
	set closeLoopFlag 0
	return
    }
    update

    if { [winfo exists .dtl] } { dtl:doExit }

    if { $closeLoopFlag == 1 } { closeloop }
}


#---------------------------------------------------------------------------
# proc SetGUIActs
#
# Convert float values in range -1..1 to GUI actuator values in the range
# -109..109, then place those values into the GUI actuator display.
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
# The description and usage of this procedure is inconsistent.  In the code,
# SetGUIActs is called with CurDrv as an argument NOT voltar.  It does not take
# a range of values from -1...1 as an argument.  CurDrv is an array that
# apparently has a range -109...109 (?).  plk 12/18/2004.
#
#---------------------------------------------------------------------------

proc SetGUIActs { voltar } {

    global acts MAX_ACT


    a.mul voltar 109 = temp
    a.to temp c = actVals

    # actVals is a character array indexed from 1...N where N=$MAX_ACT
    # actVals contains the input array values multiplied by 109.0
    # In the for loop, elements from the actVals array are placed, one by
    # one, into the acts() array.  acts() is a character array, indexed
    # from 0...N-1 where N=$MAX_ACT.
    # plk 12/18/2004

    for {set i 1} {$i <= $MAX_ACT} {incr i} {
	scan [a.extele actVals [expr $i-1]] "%d" acts($i)
    }
}


#---------------------------------------------------------------------------
# proc PokeAct
# 
# Updates the value of a particular actuator, sends that actuator value
# to the DM.
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#---------------------------------------------------------------------------

proc PokeAct { value } {

    global whichAct CurDrv acts volts


    set acts($whichAct) $value
    set wact [expr $whichAct - 1]
    set falue [expr $value / 109.]

    # CurDrv is being updated with a value that has been divided
    # by 109.  Is this correct?  In ftov it will be divided by
    # 109 AGAIN.  plk 12/18/2004
    a.repele $falue CurDrv $wact = CurDrv

    ftov $CurDrv volts
    #set pvalue [expr $value + 109]
    #dm.poke $wact $pvalue


    dm.send volts

}


#---------------------------------------------------------------------------
# proc SetAct
# 
# Sets variables when the user picks which actuator to poke
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#---------------------------------------------------------------------------

proc SetAct {} {

    global whichAct acts pokeVar selected MAX_ACT


    set selected($whichAct) 0
    for {set idx 1} {$idx <= $MAX_ACT} {incr idx} {
	if {$selected($idx) == 1} {
	    set whichAct $idx
	    set pokeVar $acts($whichAct)
	    break
	}
    }
}

#--------------------------------------------------------------------------
# proc ZeroDM
# 
# Sets all actuators to default zero voltages, then sends that frame to the DM
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#--------------------------------------------------------------------------

proc ZeroDM {} {

    global acts pokeVar CurDrv volts MAX_ACT


    for {set i 1} { $i <= $MAX_ACT } { incr i } {
	set acts($i) 0
    }
    a.make 0 $MAX_ACT = CurDrv
    a.repele 0 CurDrv 0 = CurDrv
    SetGUIActs $CurDrv
    ftov $CurDrv actv
    dm.send actv
    set pokeVar 0
}

#--------------------------------------------------------------------------
# proc FlatDM
# 
# Sets all actuators to zero, then sends that frame to the DM
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#--------------------------------------------------------------------------

proc FlatDM {} {

    global acts pokeVar CurDrv volts MAX_ACT ZeroFile

    a.load $ZeroFile = CurDrv
    #Use to create a zero voltage zeroes file:
    #a.make -1 $MAX_ACT = CurDrv
    #Use to create a bias voltage zeroes file:
    a.make 0 $MAX_ACT = CurDrv
    #hdyson 8th Oct 03
    SetGUIActs $CurDrv
    ftov $CurDrv actv
    dm.send actv
    set pokeVar 0
}


#--------------------------------------------------------------------------
# proc SaveDM
# 
# Prompt the user to save the current DM settings to a file.
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#--------------------------------------------------------------------------

proc SaveDM {} {

    global acts wlPanel LS_Dir MAX_ACT


    # Put up a file selection box.
    #
    set msg "Enter a file name into which the DM settings should be saved."
    set outfile [PanelsGetFile $LS_Dir $msg]
    if { ($outfile == "$LS_Dir/") || ($wlPanel(action) == "Abort") ||
	 ($wlPanel(action) == "Cancel") } { return }

    # Snap off the file name and save the directory for next time.
    #
    set pos [string last "/" $outfile]
    if { $pos != "-1" } {
	set LS_Dir [string range $outfile 0 [expr $pos - 1]]
    }

    # Open the selected file and write out the data.
    #
    set fp [ open $outfile { WRONLY CREAT TRUNC } ]

    for {set i 1} { $i <= $MAX_ACT } { incr i } {
	puts $fp $acts($i)
    }

    close $fp
}


#--------------------------------------------------------------------------
# proc LoadDM
# 
# Prompts the user to load a file of actuator values, then sends the frame
# of values to the DM.
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#--------------------------------------------------------------------------

proc LoadDM {} {

    global whichAct acts CurDrv LS_Dir
    global pokeVar tmp MAX_ACT wlPanel


    # Put up a file selection box.
    #
    set msg "Select the file with the DM settings you wish to load."
    set infile [PanelsGetFile $LS_Dir $msg]
    if { ($infile == "$LS_Dir/") || ($wlPanel(action) == "Abort") ||
	 ($wlPanel(action) == "Cancel") } { return }

    # Snap off the file name and save the directory for next time.
    #
    set pos [string last "/" $infile]
    if { $pos != "-1" } {
	set LS_Dir [string range $infile 0 [expr $pos - 1]]
    }

    # Read the file and set the mirror.  Watch the data to make sure
    # that it's all numbers.
    #
    a.make 0 $MAX_ACT = tmp

    set fp [ open $infile { RDONLY } ]

    for {set i 1} { $i <= $MAX_ACT } { incr i } {
	gets $fp acts($i)
	if { [catch {set aaa [expr $acts($i) / 109.0]} ] } {
	    FlatDM
	    wl_PanelsWarn "The selected file does not appear to contain DM data." \
		+50+300 10c
	    return
	}
	set j [expr $i - 1]
	a.repele $aaa tmp $j = tmp
    }
    close $fp

    set pokeVar $acts($whichAct)
    a.copy tmp CurDrv
    SetGUIActs $CurDrv
    ftov $CurDrv vvv
    dm.send vvv
}

#--------------------------------------------------------------------------
# proc ResetZDM
# 
# Saves the current dm drives as the default zero positions
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#--------------------------------------------------------------------------

proc ResetZDM {} {

    global CurDrv ZeroFile
    set msg "This will overwrite the default DM Zero voltage file!"
    if { [wl_PanelsContinueAbort $msg] == "Abort"} { return }
    a.save  CurDrv $ZeroFile

}



#--------------------------------------------------------------------------
# proc DM_GUI
# 
# Displays the Deformable Mirror control panel, which is a graphical
# representation of the mirror actuators, and controls to change the 
# values on each.
#
### For DMs: BMC 140
#
#--------------------------------------------------------------------------

proc DM_GUI {} {

    global acts pokeVar whichAct platform wsdb


    if { [winfo exists .dm] } {
	destroy .dm
    }
    toplevel    .dm
    wm title    .dm "BMC DM Controls"
    wm geometry .dm +5-35
    frame       .dm.f
    pack        .dm.f

    frame       .dm.f.labf
    pack        .dm.f.labf -anchor w
    message     .dm.f.labf.m1 -text "Actuator:" -width 3c
    message     .dm.f.labf.m2 -textvariable whichAct -width 2c
    pack        .dm.f.labf.m1 .dm.f.labf.m2 -side left

    if {$platform == "windows"} {
	set ht 1
	set bd 1
    } else {
	set ht 0
	set bd 1
    }

    for { set y 0 } { $y < 12 } { incr y } {
	frame .dm.f.acts$y
	pack  .dm.f.acts$y
	for { set x 0 } { $x < 12 } { incr x } {
	    set bnum [expr $y * 12 + $x + 1]
	    checkbutton .dm.f.acts$y.$bnum -textvariable acts($bnum) -width 3 \
		-height $ht -bd $bd -variable selected($bnum) -command SetAct
	    pack        .dm.f.acts$y.$bnum -side left
	}
    }
    .dm.f.acts0.1 configure -state disabled
    .dm.f.acts0.12 configure -state disabled
    .dm.f.acts11.133 configure -state disabled
    .dm.f.acts11.144 configure -state disabled

    frame .dm.f.poke
    scale .dm.f.poke.scale -from -109 -to 109 -length 350 \
	-orient horizontal -variable pokeVar -command PokeAct
    pack  .dm.f.poke.scale

    frame  .dm.f.buts
    frame	 .dm.f.stub
    button .dm.f.buts.flat -text "Zero DM" -command FlatDM
    button .dm.f.stub.save -text "Save Settings..." -command SaveDM
    button .dm.f.stub.load -text "Load Settings..." -command LoadDM
    button .dm.f.stub.zerl -text "Reset Zeros File ..." -command ResetZDM
    button .dm.f.buts.ok -text "  OK  " -command {destroy .dm} -font $wsdb(font)
    pack   .dm.f.stub.load .dm.f.stub.save .dm.f.stub.zerl -side left -padx 5
    pack   .dm.f.buts.flat .dm.f.buts.ok -side left -padx 5
    pack   .dm.f.poke .dm.f.buts .dm.f.stub -padx 5 -pady 5

    update
}

#Additional functions for membrane mirror:

#---------------------------------------------------------------------------
# proc mdm_panel
# 
# Initialization to be done before popping up the closeLoopPanel
#
### For DMs: Membrane 256
#
#---------------------------------------------------------------------------

proc mdm_panel {} {

    global device MAX_ACT MAX_VOLT ZeroFile MaskFile
    global CurDrv volts nmodes acts selected
    global MaskFile maskArray ACT_LINE_LENGTH

    if {$device == "membrane256"} {
    } elseif { $device == "bmc140"} {
	#Reset bmcdm functions to generic device functions...
	rename dm.help bmcdm.help
	rename dm.send bmcdm.send
	rename dm.poke bmcdm.poke
	rename dm.pokeraw bmcdm.pokeraw
	rename dm.ping bmcdm.ping
	#...and then set generic functions to call membrane functions
	rename mdm.help dm.help
	rename mdm.send dm.send
	rename mdm.poke dm.poke
	rename mdm.pokeraw dm.pokeraw
	rename mdm.ping dm.ping
    } elseif { $device == "membrane1024"} {
	#Reset mdm functions to generic device functions...
	rename dm.help mdm1k.help
	rename dm.send mdm1k.send
	rename dm.poke mdm1k.poke
	rename dm.pokeraw mdm1k.pokeraw
	rename dm.ping mdm1k.ping
	#...and then set generic functions to call membrane functions
	rename mdm.help dm.help
	rename mdm.send dm.send
	rename mdm.poke dm.poke
	rename mdm.pokeraw dm.pokeraw
	rename mdm.ping dm.ping
    } elseif { $device == "bmc1024"} {
	#Reset mdm functions to generic device functions...
	rename dm.help bmcdm1k.help
	rename dm.send bmcdm1k.send
	rename dm.poke bmcdm1k.poke
	rename dm.pokeraw bmcdm1k.pokeraw
	rename dm.ping bmcdm1k.ping
	#...and then set generic functions to call membrane functions
	rename mdmdm.help dm.help
	rename mdmdm.send dm.send
	rename mdmdm.poke dm.poke
	rename mdmdm.pokeraw dm.pokeraw
	rename mdmdm.ping dm.ping
    } elseif { $device == "tdm1024"} {
	#Reset mdm functions to generic device functions...
	rename dm.help tdm1k.help
	rename dm.send tdm1k.send
	rename dm.poke tdm1k.poke
	rename dm.pokeraw tdm1k.pokeraw
	rename dm.ping tdm1k.ping
	#...and then set generic functions to call membrane functions
	rename mdm.help dm.help
	rename mdm.send dm.send
	rename mdm.poke dm.poke
	rename mdm.pokeraw dm.pokeraw
	rename mdm.ping dm.ping
    } elseif { $device == "NULL" } {
	rename mdm.help dm.help
	rename mdm.send dm.send
	rename mdm.poke dm.poke
	rename mdm.pokeraw dm.pokeraw
	rename mdm.ping dm.ping
    }
    #if $device not one of above values, do nothing
    #At present, this situation cannot arise...

    set device "membrane256"

    set MAX_ACT 361
    set ACT_LINE_LENGTH 19
    set MAX_VOLT 21

    # Define file with a default zero voltage array for DM
    set ZeroFile c:/usr/aos/wavescope/src/lists/Zeros_membrane

    # MaskFile is an ascii file consisting of $NMAK_ACT integer elements
    # If file entry is = 1, actuator is used in generating recon, otherwise
    # it is skpped. It is loaded as $maskArray.
    set MaskFile c:/usr/aos/wavescope/src/lists/Mask_membrane.txt

    a.make 0 $MAX_ACT = CurDrv
    a.make 0 $MAX_ACT = volts

    for {set i 1} {$i <= $MAX_ACT} {incr i} {
	#To initalise to bias voltage:
	set acts($i) 0
	#To initalise to 0 Volts:
	#  set acts($i) -100
	#hdyson 8th Oct 03
	set selected($i) 0
    }

    set nmodes $MAX_ACT

    for { set i 0 } { $i < $nmodes } { incr i } {
	set mode($i) 0
	set modew($i) 1
	set mods($i) 0
    }


    a.loadasc $MaskFile i = maskArray
    #Hack to reduce number of actuators used:
    #hdyson 21 Oct 03

    #     a.loadasc $MaskFile i = maskArrayTemp
    #     a.make 1 $MAX_ACT = maskArray
    #     for { set y 0 } { $y < 19 } { incr y } {
    # 	for { set x 0 } { $x < 19 } { incr x } {
    # 	    set count [expr {$x+(19*$y)}]
    # 	    set index1 [expr {$count+1}]
    # 	    set index2 [expr {$count-1}]
    # 	    set index3 [expr {$count+19}]
    # 	    set index4 [expr {$count-19}]
    #  	    if { [ a.extele maskArrayTemp $count ] != 1 } {
    #  		a.repele 0 maskArray $count = maskArray

    #   	    } elseif {$index1<$MAX_ACT && [ a.extele maskArrayTemp $index1 ] != 1} {
    # 		    a.repele 0 maskArray $count = maskArray		  
    # 	    } elseif {$index2>0 && [ a.extele maskArrayTemp $index2 ] != 1} {
    # 		a.repele 0 maskArray $count = maskArray
    # 	    } elseif {$index3<$MAX_ACT && [ a.extele maskArrayTemp $index3 ] != 1} {
    # 		a.repele 0 maskArray $count = maskArray
    # 	    } elseif {$index4>0 && [ a.extele maskArrayTemp $index4 ] != 1} {
    # 		a.repele 0 maskArray $count = maskArray
    # 	    }
    # 	}
    #     }

    closeLoopPanel
}


#--------------------------------------------------------------------------
# proc MDM_GUI
# 
# Displays the Deformable Mirror control panel, which is a graphical
# representation of the mirror actuators, and controls to change the 
# values on each.
#
### For DMs: Membrane 256
#
#--------------------------------------------------------------------------

proc MDM_GUI {} {
    #Update from DM1K_GUI for MDM1K
    global acts pokeVar whichAct platform wsdb maskArray

    if { [winfo exists .dm] } {
	destroy .dm
    }
    toplevel    .dm
    wm title    .dm "Membrane DM Controls"
    wm geometry .dm +5-35
    frame       .dm.f
    pack        .dm.f

    frame       .dm.f.labf
    pack        .dm.f.labf -anchor w
    message     .dm.f.labf.m1 -text "Actuator:" -width 3c
    message     .dm.f.labf.m2 -textvariable whichAct -width 2c
    pack        .dm.f.labf.m1 .dm.f.labf.m2 -side left

    if {$platform == "windows"} {
	set ht 1
	set bd 1
    } else {
	set ht 0
	set bd 1
    }

    for { set y 0 } { $y < 19 } { incr y } {
	frame .dm.f.acts$y
	pack  .dm.f.acts$y
	for { set x 0 } { $x < 19 } { incr x } {
	    set bnum [expr $y * 19 + $x + 1]
	    checkbutton .dm.f.acts$y.$bnum -textvariable acts($bnum) -width 3 \
		-height $ht -bd $bd -variable selected($bnum) -command SetAct
	    pack        .dm.f.acts$y.$bnum -side left
	}
    }

    set i 0

    for { set y 0 } { $y < 19 } { incr y } {
	for { set x 0 } { $x < 19 } { incr x } {
	    if { [ a.extele maskArray $i ] != 1 } {
		set bnum [expr $y * 19 + $x + 1]
		.dm.f.acts$y.$bnum configure -state disabled
	    }
	    incr i
	}
    }

    frame .dm.f.poke
    scale .dm.f.poke.scale -from -109 -to 109 -length 350 \
	-orient horizontal -variable pokeVar -command PokeAct
    pack  .dm.f.poke.scale

    frame  .dm.f.buts
    frame	 .dm.f.stub
    button .dm.f.buts.flat -text "Bias DM" -command FlatDM
    button .dm.f.buts.zerovolt -text "Zero Volt DM" -command ZerovoltDM
    button .dm.f.stub.save -text "Save Settings..." -command SaveDM
    button .dm.f.stub.load -text "Load Settings..." -command LoadDM
    button .dm.f.stub.zerl -text "Reset Zeros File ..." -command ResetZDM
    button .dm.f.buts.ok -text "  OK  " -command {destroy .dm} -font $wsdb(font)
    pack   .dm.f.stub.load .dm.f.stub.save .dm.f.stub.zerl -side left -padx 5
    pack   .dm.f.buts.flat .dm.f.buts.zerovolt .dm.f.buts.ok -side left -padx 5
    pack   .dm.f.poke .dm.f.buts .dm.f.stub -padx 5 -pady 5

    update
}

#
#New Functions added below here
#

#--------------------------------------------------------------------------
# proc ZerovoltDM
# 
# Sets all actuators to zero volts, then sends that frame to the DM
# hdyson 21 Oct 03
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#--------------------------------------------------------------------------

proc ZerovoltDM {} {

    global acts pokeVar CurDrv volts MAX_ACT ZeroFile device

    if { $device == "tdm1024" } {
	a.make 0 $MAX_ACT = CurDrv
	SetGUIActs $CurDrv
	ftov $CurDrv actv
	dm.send actv
	set pokeVar 0
    } else {
	a.make -1 $MAX_ACT = CurDrv
	SetGUIActs $CurDrv
	ftov $CurDrv actv
	dm.send actv
	set pokeVar 0
    }
}

#--------------------------------------------------------------------------
# proc ZerovoltDM_VoltGUI
# 
# Sets all actuators to zero volts, then sends that frame to the DM
# hdyson 21 Oct 03
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
### Not good for 1024 Transparent electrode!
#
#--------------------------------------------------------------------------

proc ZerovoltDM_VoltGUI {} {

    global acts pokeVar CurDrv volts MAX_ACT ZeroFile

    a.make 0 $MAX_ACT = volts
    a.to volts uc = CurDrv
    SetGUIActs $CurDrv
    dm.send $CurDrv
    set pokeVar 0
}

#--------------------------------------------------------------------------
# proc MDM_GUI_NINE
# 
# Displays the Deformable Mirror control panel, which is a graphical
# representation of the mirror actuators, and controls to change the 
# values on each.  Changing one actuator also changes the 8 immediate neighbours
#
### For DMs: Membrane 256
#
#--------------------------------------------------------------------------

proc MDM_GUI_NINE {} {
    global acts pokeVar whichAct platform wsdb maskArray

    if { [winfo exists .dm] } {
	destroy .dm
    }
    toplevel    .dm
    wm title    .dm "Membrane DM Controls: Poking 9 Actuators at a time"
    wm geometry .dm +5-35
    frame       .dm.f
    pack        .dm.f

    frame       .dm.f.labf
    pack        .dm.f.labf -anchor w
    message     .dm.f.labf.m1 -text "Actuator:" -width 3c
    message     .dm.f.labf.m2 -textvariable whichAct -width 2c
    pack        .dm.f.labf.m1 .dm.f.labf.m2 -side left

    if {$platform == "windows"} {
	set ht 1
	set bd 1
    } else {
	set ht 0
	set bd 1
    }

    for { set y 0 } { $y < 19 } { incr y } {
	frame .dm.f.acts$y
	pack  .dm.f.acts$y
	for { set x 0 } { $x < 19 } { incr x } {
	    set bnum [expr $y * 19 + $x + 1]
	    checkbutton .dm.f.acts$y.$bnum -textvariable acts($bnum) -width 3 \
		-height $ht -bd $bd -variable selected($bnum) -command SetAct
	    pack        .dm.f.acts$y.$bnum -side left
	}
    }

    set i 0

    for { set y 0 } { $y < 19 } { incr y } {
	for { set x 0 } { $x < 19 } { incr x } {
	    if { [ a.extele maskArray $i ] != 1 } {
		set bnum [expr $y * 19 + $x + 1]
		.dm.f.acts$y.$bnum configure -state disabled
	    }
	    incr i
	}
    }

    frame .dm.f.poke
    scale .dm.f.poke.scale -from -109 -to 109 -length 350 \
	-orient horizontal -variable pokeVar -command PokeActNine
    pack  .dm.f.poke.scale

    frame  .dm.f.buts
    frame	 .dm.f.stub
    button .dm.f.buts.flat -text "Bias DM" -command FlatDM
    button .dm.f.buts.zerovolt -text "Zero Volt DM" -command ZerovoltDM
    button .dm.f.stub.save -text "Save Settings..." -command SaveDM
    button .dm.f.stub.load -text "Load Settings..." -command LoadDM
    button .dm.f.stub.zerl -text "Reset Zeros File ..." -command ResetZDM
    button .dm.f.buts.ok -text "  OK  " -command {destroy .dm} -font $wsdb(font)
    pack   .dm.f.stub.load .dm.f.stub.save .dm.f.stub.zerl -side left -padx 5
    pack   .dm.f.buts.flat .dm.f.buts.zerovolt .dm.f.buts.ok -side left -padx 5
    pack   .dm.f.poke .dm.f.buts .dm.f.stub -padx 5 -pady 5

    update
}

#---------------------------------------------------------------------------
# proc PokeActNine
# 
# Updates the value of a particular actuator and 8 immediate neighbours, 
# sends that actuator value to the DM.
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#---------------------------------------------------------------------------

proc PokeActNine { value } {

    global whichAct CurDrv acts volts MAX_ACT maskArray XACT_LINE_LENGTH YACT_LINE_LENGTH

    set falue [expr $value / 109.]
    for {set x -1} {$x<=1} {incr x} {
	for {set y -1} {$y<=1} {incr y} {
	    set localAct [expr {$whichAct+$y+($XACT_LINE_LENGTH*$x)}]
	    set acts($localAct) $value
	    set wact [expr $localAct - 1]
	    if {$wact>0 } {
		if {$wact<$MAX_ACT} {
		    if { [ a.extele maskArray $wact ] == 1 } {
			a.repele $falue CurDrv $wact = CurDrv
		    }
		}
	    }
	}
    }
    SetGUIActs $CurDrv
    ftov $CurDrv volts
    #set pvalue [expr $value + 109]
    #dm.poke $wact $pvalue
    dm.send volts
}


#--------------------------------------------------------------------------
# proc MDM_GUI_25
# 
# Displays the Deformable Mirror control panel, which is a graphical
# representation of the mirror actuators, and controls to change the 
# values on each.  Changing one actuator also changes the 24 immediate neighbours
#
#For Membrane 256 device
#
#--------------------------------------------------------------------------

#For Membrane 256 device

proc MDM_GUI_25 {} {
    #Update from DM1K_GUI for MDM1K
    global acts pokeVar whichAct platform wsdb maskArray 

    if { [winfo exists .dm] } {
	destroy .dm
    }
    toplevel    .dm
    wm title    .dm "Membrane DM Controls: Poking 25 Actuators at a time"
    wm geometry .dm +5-35
    frame       .dm.f
    pack        .dm.f

    frame       .dm.f.labf
    pack        .dm.f.labf -anchor w
    message     .dm.f.labf.m1 -text "Actuator:" -width 3c
    message     .dm.f.labf.m2 -textvariable whichAct -width 2c
    pack        .dm.f.labf.m1 .dm.f.labf.m2 -side left

    if {$platform == "windows"} {
	set ht 1
	set bd 1
    } else {
	set ht 0
	set bd 1
    }

    for { set y 0 } { $y < 19 } { incr y } {
	frame .dm.f.acts$y
	pack  .dm.f.acts$y
	for { set x 0 } { $x < 19 } { incr x } {
	    set bnum [expr $y * 19 + $x + 1]
	    checkbutton .dm.f.acts$y.$bnum -textvariable acts($bnum) -width 3 \
		-height $ht -bd $bd -variable selected($bnum) -command SetAct
	    pack        .dm.f.acts$y.$bnum -side left
	}
    }

    set i 0

    for { set y 0 } { $y < 19 } { incr y } {
	for { set x 0 } { $x < 19 } { incr x } {
	    if { [ a.extele maskArray $i ] != 1 } {
		set bnum [expr $y * 19 + $x + 1]
		.dm.f.acts$y.$bnum configure -state disabled
	    }
	    incr i
	}
    }

    frame .dm.f.poke
    scale .dm.f.poke.scale -from -109 -to 109 -length 350 \
	-orient horizontal -variable pokeVar -command PokeAct25
    pack  .dm.f.poke.scale

    frame  .dm.f.buts
    frame	 .dm.f.stub
    button .dm.f.buts.flat -text "Bias DM" -command FlatDM
    button .dm.f.buts.zerovolt -text "Zero Volt DM" -command ZerovoltDM
    button .dm.f.stub.save -text "Save Settings..." -command SaveDM
    button .dm.f.stub.load -text "Load Settings..." -command LoadDM
    button .dm.f.stub.zerl -text "Reset Zeros File ..." -command ResetZDM
    button .dm.f.buts.ok -text "  OK  " -command {destroy .dm} -font $wsdb(font)
    pack   .dm.f.stub.load .dm.f.stub.save .dm.f.stub.zerl -side left -padx 5
    pack   .dm.f.buts.flat .dm.f.buts.zerovolt .dm.f.buts.ok -side left -padx 5
    pack   .dm.f.poke .dm.f.buts .dm.f.stub -padx 5 -pady 5

    update
}

#---------------------------------------------------------------------------
# proc PokeAct25
# 
# Updates the value of a particular actuator and 24 immediate neighbours, 
# sends that actuator value to the DM.
#
### For DMs: Membrane 256
#
#---------------------------------------------------------------------------

proc PokeAct25 { value } {

    global whichAct CurDrv acts volts MAX_ACT maskArray XACT_LINE_LENGTH YACT_LINE_LENGTH pokeVar

    set falue [expr $value / 109.]
    for {set x -2} {$x<=2} {incr x} {
	for {set y -2} {$y<=2} {incr y} {
	    set localAct [expr {$whichAct+$y+($XACT_LINE_LENGTH*$x)}]
	    set acts($localAct) $value
	    set wact [expr $localAct - 1]
	    if {$wact>0 } {
		if {$wact<$MAX_ACT} {
		    if { [ a.extele maskArray $wact ] == 1 } {
			a.repele $falue CurDrv $wact = CurDrv
		    }
		}
	    }
	}
    }
    SetGUIActs $CurDrv
    ftov $CurDrv volts
    #set pvalue [expr $value + 109]
    #dm.poke $wact $pvalue
    dm.send volts
}


#---------------------------------------------------------------------------
#
# proc prep_arrays
#
# Creates arrays to be used with the dm.send function from the command-line
#
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#---------------------------------------------------------------------------

proc prep_arrays {} {

    global MAX_ACT
    global temp0 temp10 temp15 temp18 temp20

    a.make 0 $MAX_ACT = temp
    a.to temp uc = temp0
    a.make 10 $MAX_ACT = temp
    a.to temp uc = temp10
    a.make 15 $MAX_ACT = temp
    a.to temp uc = temp15
    a.make 18 $MAX_ACT = temp
    a.to temp uc = temp18
    a.make 20 $MAX_ACT = temp
    a.to temp uc = temp20

}
#---------------------------------------------------------------------------
#
# proc load_array_gui
#
# Puts up file dialogue to specify a file to pass to load_array
#
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#---------------------------------------------------------------------------

proc load_array_gui {} {

    global wlPanel LS_Dir

    # Put up a file selection box.
    #
    set msg "Select the file with the DM voltages you wish to load."
    set infile [PanelsGetFile $LS_Dir $msg]
    if { ($infile == "$LS_Dir/") || ($wlPanel(action) == "Abort") ||
	 ($wlPanel(action) == "Cancel") } { return }

    # Snap off the file name and save the directory for next time.
    #
    set pos [string last "/" $infile]
    if { $pos != "-1" } {
	set LS_Dir [string range $infile 0 [expr $pos - 1]]
    }

    load_array $infile 

}

#---------------------------------------------------------------------------
#
# proc load_array
#
# Creates arrays to be used with the dm.send function from the command-line
#
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#---------------------------------------------------------------------------

proc load_array { infile } {

    global whichAct CurDrv acts volts
    global pokeVar tmp MAX_ACT wlPanel

    a.make 0 $MAX_ACT = tmp

    set fp [ open $infile { RDONLY } ]
    #Check!  Can we do this as a conditional?  ie check if file exists, when opening file?

    for { set i 1 } { $i <= $MAX_ACT } { incr i } {
	gets $fp acts($i)
	set aaa $acts($i)

	#Alter conditional to fit data format from Kurczynski's simulation
	#
	#Data from Kurczynski simulation in form of absolute voltages
	#Done; hdyson 28th Oct 03

	# 	ZerovoltDM
	# 	wl_PanelsWarn "The selected file does not appear to contain DM data?" \
	    # 	    +50+300 10c
	# 	return

	set j [expr $i - 1]
	a.repele $aaa tmp $j = tmp
    }
    close $fp

    set pokeVar $acts($whichAct)
    #    a.copy tmp = CurDrv
    #    SetGUIActs $CurDrv
    #  ftov $CurDrv vvv
    a.to $tmp uc = volts
    dm.send volts

#Needs updating for transparent electrode

}


#---------------------------------------------------------------------------
# proc clloopnodisplay
#
# This function is called from the GUI to kick off the full speed closed loop.
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#---------------------------------------------------------------------------

proc clloopnodisplay {} {

    global closeLoopFlag loopType


    if { $loopType == "NULL" } {
	dialog "Please Make a Reconstructor first."
	set closeLoopFlag 0
	return
    }
    update

    if { [winfo exists .dtl] } { dtl:doExit }

    if { $closeLoopFlag == 1 } { closeloopnodisplay }
}

#---------------------------------------------------------------------------
# proc cllooppsf
#
# This function is called from the GUI to kick off the closed loop with psf display.
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#---------------------------------------------------------------------------

proc cllooppsf {} {

    global closeLoopFlag loopType


    if { $loopType == "NULL" } {
	dialog "Please Make a Reconstructor first."
	set closeLoopFlag 0
	return
    }
    update

    if { [winfo exists .dtl] } { dtl:doExit }

    if { $closeLoopFlag == 1 } { closelooppsf }
}
##---------------------------------------------------------------------------
##
## closeloopnodisplay - Actual flattening routine
## 
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
##---------------------------------------------------------------------------

proc closeloopnodisplay {} {

    global Grad Drive Drives CurDrv ivd Recon Drvs Drerr
    global modew mds integGain closeLoopFlag wlCalibrate
    global MAX_ACT platform maskArray

    set ncol [ a.rows Drvs ]
    set i 0
    # As long as the 'closeLoop' button on the panel is set,
    # keep trying to flatten the mirror.
    #
    while { $closeLoopFlag == 1 } {
	# The calculations are basically standard adaptive optics fare.
	# Use the reconstructor to produce a set of voltages for the
	# mirror, tempering the aggressiveness of the correction by the
	# 'integGain' selected by the user.
	#
	calcGrad 3
	alg.conv.pg.arrays Grad wlCalibrate(Params) = gxgy mask
	alg.recon.fast gxgy mask = opd
	update
	makeg $Grad ggg
	a.matprod Recon ggg = mod

	a.shape mod $ncol 1 = mod
	a.mul mod modew = mod
	if { $i == 0 } {
	    a.copy mod = mds
	} else {
	    a.catrow mds mod = mds
	}

	a.matprod mod Drvs = Drerr
	a.shape Drerr $MAX_ACT = Drerr
	set gain [expr $integGain / -100.]
	a.mul Drerr $gain = Drerr

	# This section addresses the fact that average piston is unobservable
	# We prevent the mean value of the active actuator drives from drifting
	# away from its initial value.
	# 
	# subtract average drive to keep things in line
        # procedure dies with error a.avemask failed.  Next line disabled.
        # plk 3/2/2005
	#a.sub Drerr [a.avemask Drerr maskArray] = Drerr

	a.add CurDrv Drerr = CurDrv

	# apply the mask to assure no unwanted drives
	a.mul CurDrv maskArray = CurDrv

	# Linit the drive signals to the allowed range
	#    a.lim CurDrv 1 = CurDrv
	#Upper limiting now done in dm.send function
	a.limlow CurDrv -1 = CurDrv

	# Added another avg subtract to keep drives in line
	# after limiting
	a.sub CurDrv [a.avemask CurDrv maskArray] = CurDrv
	SetGUIActs $CurDrv
	ftov $CurDrv Drive

	if { $i == 0 } {
	    a.copy Drive = Drives
	} else {
	    a.catrow Drives Drive = Drives
	}

	mdm.send Drive

	puts "Closed loop iteration: $i"
	incr i
	update
    }
}


##---------------------------------------------------------------------------
##
## closelooppsf - Actual flattening routine
## 
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
##---------------------------------------------------------------------------

proc closelooppsf {} {

    global Grad Drive Drives CurDrv ivd Recon Drvs Drerr
    global modew mds integGain closeLoopFlag wlCalibrate ws_result
    global MAX_ACT platform maskArray


    # Put up an image of the wavefront so the user can watch the
    # the loop perform its magic.
    #    
    #amended to display psf
    set ncol [ a.rows Drvs ]
    set i 0
    id.new psf_ivd
    id.set.title psf_ivd "Current Point-Spread Function"
    id.set.xy psf_ivd 5 360
    id.set.wh psf_ivd 300 300
    if {$platform != "windows"} {
	id.set.minmax psf_ivd -1 1
    }
    id.new opd_ivd
    id.set.title opd_ivd "Current Wavefront Shape"
    id.set.xy opd_ivd 5 360
    id.set.wh opd_ivd 300 300
    if {$platform != "windows"} {
	id.set.minmax opd_ivd -1 1
    }

    # As long as the 'closeLoop' button on the panel is set,
    # keep trying to flatten the mirror.
    #
    while { $closeLoopFlag == 1 } {
	# The calculations are basically standard adaptive optics fare.
	# Use the reconstructor to produce a set of voltages for the
	# mirror, tempering the aggressiveness of the correction by the
	# 'integGain' selected by the user.
	#
	calcGrad 3
	alg.conv.pg.arrays Grad wlCalibrate(Params) = gxgy mask
	alg.recon.fast gxgy mask = opd
	if { $opd_ivd != 0 } {
	    set rms [a.rmsmask opd mask]
	    id.set.array opd_ivd opd $rms
	    if { $platform == "windows" } {
		set min [a.min opd]
		set max [a.max opd]
		set pv [expr $max - $min]
		set pv [format %8.4f $pv]
		set rms [format %8.4f $rms]
		id.clr.text opd_ivd
		id.set.text.coords opd_ivd 0
		id.set.text.align opd_ivd -1 1
		id.set.text.color opd_ivd 1.0 1.0 0.3
		id.set.text opd_ivd "PV  = $pv microns" 10 10
		id.set.text opd_ivd "RMS = $rms microns" 10 25
	    }
	}


	#Calculate and display psf:

	set PSFsize $ncol
	set SubapSize $wlCalibrate($micronsPerPix)
	set PSFScale 10
	set Lambda 1.0

	if { $psf_ivd != 0 } {
	    #	alg.calc.psf opd mask $PSFSize $PSFSize $SubapSize $PSFScale $Lambda = psf
	    id.set.array psf_ivd $ws_result(PSF) $wlCalibrate(psfScale)
	}

	update
	makeg $Grad ggg
	a.matprod Recon ggg = mod

	a.shape mod $ncol 1 = mod
	a.mul mod modew = mod
	if { $i == 0 } {
	    a.copy mod = mds
	} else {
	    a.catrow mds mod = mds
	}


	a.matprod mod Drvs = Drerr
	a.shape Drerr $MAX_ACT = Drerr
	set gain [expr $integGain / -100.]
	a.mul Drerr $gain = Drerr

	# This section addresses the fact that average piston is unobservable
	# We prevent the mean value of the active actuator drives from drifting
	# away from its initial value.
	# 
	# subtract average drive to keep things in line
	a.sub Drerr [a.avemask Drerr maskArray] = Drerr

	a.add CurDrv Drerr = CurDrv

	# apply the mask to assure no unwanted drives
	a.mul CurDrv maskArray = CurDrv

	# Linit the drive signals to the allowed range
	#    a.lim CurDrv 1 = CurDrv
	#Upper limiting now done in dm.send function
	a.limlow CurDrv -1 = CurDrv

	# Added another avg subtract to keep drives in line
	# after limiting
	a.sub CurDrv [a.avemask CurDrv maskArray] = CurDrv
	SetGUIActs $CurDrv
	ftov $CurDrv Drive

	if { $i == 0 } {
	    a.copy Drive = Drives
	} else {
	    a.catrow Drives Drive = Drives
	}

	mdm.send Drive

	puts "Closed loop iteration: $i"
	incr i
	update
    }
    set opd_ivd 0
    set psf_ivd 0
}

#--------------------------------------------------------------------------
# proc MDM_OVER_GUI
# 
# Displays the Deformable Mirror control panel, which is a graphical
# representation of the mirror actuators, and controls to change the
# values on each.  This version deals with VOLTAGES and allows
# individual actuators to go over maximum Voltage.  This is okay for
# membrane mirrors, but not for segmented mirrors.
#
### For DMs: Membrane 256
#
#--------------------------------------------------------------------------

proc MDM_OVER_GUI {} {
    #Update from DM1K_GUI for MDM1K
    global acts pokeVar whichAct platform wsdb maskArray

    if { [winfo exists .dm] } {
	destroy .dm
    }
    toplevel    .dm
    wm title    .dm "Membrane DM Controls"
    wm geometry .dm +5-35
    frame       .dm.f
    pack        .dm.f

    frame       .dm.f.labf
    pack        .dm.f.labf -anchor w
    message     .dm.f.labf.m1 -text "Actuator:" -width 3c
    message     .dm.f.labf.m2 -textvariable whichAct -width 2c
    pack        .dm.f.labf.m1 .dm.f.labf.m2 -side left

    if {$platform == "windows"} {
	set ht 1
	set bd 1
    } else {
	set ht 0
	set bd 1
    }

    for { set y 0 } { $y < 19 } { incr y } {
	frame .dm.f.acts$y
	pack  .dm.f.acts$y
	for { set x 0 } { $x < 19 } { incr x } {
	    set bnum [expr $y * 19 + $x + 1]
	    checkbutton .dm.f.acts$y.$bnum -textvariable acts($bnum) -width 3 \
		-height $ht -bd $bd -variable selected($bnum) -command SetAct
	    pack        .dm.f.acts$y.$bnum -side left
	}
    }

    set i 0

    for { set y 0 } { $y < 19 } { incr y } {
	for { set x 0 } { $x < 19 } { incr x } {
	    if { [ a.extele maskArray $i ] != 1 } {
		set bnum [expr $y * 19 + $x + 1]
		.dm.f.acts$y.$bnum configure -state disabled
	    }
	    incr i
	}
    }

    frame .dm.f.poke

    set overpokemsg "Warning: This function operates on voltages, not deflections"
    message .dm.f.labf.overpokemsg -text $overpokemsg -aspect 1000 -font $wsdb(font)
    pack    .dm.f.labf.overpokemsg -padx 5 -pady 5

    scale .dm.f.poke.scale -from 0 -to 90 -length 350 \
	-orient horizontal -variable pokeVar -command OverPokeAct
    pack  .dm.f.poke.scale

    frame  .dm.f.buts
    frame	 .dm.f.stub
    button .dm.f.buts.zerovolt -text "Zero Volt DM" -command ZerovoltDM_VoltGUI
    button .dm.f.buts.ok -text "  OK  " -command {destroy .dm} -font $wsdb(font)
    pack   .dm.f.buts.zerovolt .dm.f.buts.ok -side left -padx 5
    pack   .dm.f.poke .dm.f.buts .dm.f.stub -padx 5 -pady 5

    update
}

#---------------------------------------------------------------------------
# proc PokeAct
# 
# Updates the value of a particular actuator, sends that actuator value
# to the DM.
# This version deals with VOLTAGES and allows individual actuators to
# go over maximum Voltage.  This is okay for membrane mirrors, but not
# for segmented mirrors.
#
#
### For DMs: Membrane 256, Membrane 1024
#
#---------------------------------------------------------------------------

proc OverPokeAct { value } {

    global whichAct acts volts CurDrv

    set acts($whichAct) $value
    set wact [expr $whichAct - 1]
    a.repele $value volts $wact = volts
    a.to volts uc = CurDrv
    #set pvalue [expr $value + 109]
    #dm.poke $wact $pvalue
    dm.send CurDrv
}

#---------------------------------------------------------------------------
# proc poke_sequence
# 
# Pokes each actuator and calls whatever test is currently open
# (eg use a test containing OPDs for recording inf fns).  
# hdyson, 24th Nov 03 (based on quiet)
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#---------------------------------------------------------------------------

proc poke_sequence { } {

    global Grad gvd CurDrv Drvs Grds MAX_ACT maskArray 
    global wlCalibrate ACT_LINE_LENGTH device

    #  set deflection 36
    #deflection in terms of bias voltage, ie 1=15V, 11=50V, 16=60V, 22=70V,28=80V,32=85V,36=90,40=95;
    #deflection { 0 1 7 11 16 22 28 32 36 } 
    set run 30
    #run used only to create unique filenames, to allow repeated measurements at same voltage
    #    foreach deflection { 36 32 28 22 16 11 7 1 0 36 32 28 22 16 11 7 1 0 } {
    #}
    #    foreach deflection { 36 } {
    #}
    foreach deflection { 36 32 28 22 16 11 7 1 0  36 32 28 22 16 11 7 1 0  36 32 28 22 16 11 7 1 0  36 32 28 22 16 11 7 1 0  36 32 28 22 16 11 7 1 0  36 32 28 22 16 11 7 1 0 } {


	#0, 15, 40, 50, 60, 70, 80, 85 & 90V

	incr run

	# make some arrays of zeros to use to fill matrices
	# when we reach dead actuators
	set nsubs [a.cols wlCalibrate(FinalCenters)]
	a.make -1 $MAX_ACT = zeros
	a.make "< 0 0 >" $nsubs = gzeros

	# Poke each actuator from 0..1, and calculate the gradient.
	#
	#  FlatDM
	ZerovoltDM
	a.copy CurDrv = CurDrv0


	#Counting Up...
	set count 0
	for { set i 0 } { $i<$ACT_LINE_LENGTH } { incr i } {
	    for { set j 0 } { $j<$ACT_LINE_LENGTH } { incr j } {
		if { [ a.extele maskArray $count ] == 1 } {
		    puts "Poking actuator: $j x $i ($count)"
		    if { $device == "tdm1024" } {
			a.make 0 $MAX_ACT = CD
		    }
		    else {
			a.make -1 $MAX_ACT = CD
		    }
		    #a.make 0 $MAX_ACT = CD
		    #					a.make -1 $MAX_ACT = CD
		    #Changed above to make reconstructor from 0V rather than bias volt position for single-electrode array devices; while from bias position for transparent electrode array devices.
		    #hdyson 10th Oct 03
		    a.repele $deflection CD $count = CD
		    a.add CD CurDrv0 = CurDrv
		    SetGUIActs $CurDrv
		    ftov $CurDrv uuu
		    dm.send uuu
		    update
		    set run_name "data_for_Act_${count}_up_deflection_${deflection}_run_${run}"
		    auto_run_test $run_name

		} else {
		    puts "Skipping actuator: $j x $i ($count)"
		}
		incr count
		update
		#				a.make -1 $MAX_ACT = CurDrv
		#				ftov $CurDrv uuu
		#				dm.send uuu
		ZerovoltDM
	    } 
	}
	#Counting Down...
	set count 360
	for { set i $ACT_LINE_LENGTH; set i [expr $i - 1]  } { $i>=0 } { set i [expr $i -1 ] } {
	    for { set j $ACT_LINE_LENGTH; set j [expr $j -1 ]} { $j >=0 } { set j [expr $j -1 ]} {
		if { [ a.extele maskArray $count ] == 1 } {
		    puts "Poking actuator: $j x $i ($count)"
		    if { $device == "tdm1024" } {
			a.make 0 $MAX_ACT = CD
		    }
		    else {
			a.make -1 $MAX_ACT = CD
		    }
		    #a.make 0 $MAX_ACT = CD
		    #					a.make -1 $MAX_ACT = CD
		    #Changed above to make reconstructor from 0V rather than bias volt position for single-electrode array devices; while from bias position for transparent electrode array devices.
		    #hdyson 10th Oct 03
		    a.repele $deflection CD $count = CD
		    a.add CD CurDrv0 = CurDrv
		    SetGUIActs $CurDrv
		    ftov $CurDrv uuu
		    dm.send uuu
		    update
		    set run_name "data_for_Act_${count}_down_deflection_${deflection}_run_${run}"
		    auto_run_test $run_name

		} else {
		    puts "Skipping actuator: $j x $i ($count)"
		}
		set count [expr $count - 1 ]
		update
		#				a.make -1 $MAX_ACT = CurDrv
		#				ftov $CurDrv uuu
		#				dm.send uuu
		ZerovoltDM
	    } 
	}
	ps_output C:/usr/data/tests/opd_only_big  C:/hdyson/Incoming/data_ascii/Final_Inf_Fns_run_${run} $deflection
	#  a.make 0 $MAX_ACT = CurDrv
	#		a.make -1 $MAX_ACT = CurDrv
	#		ftov $CurDrv uuu
	#		dm.send uuu
	ZerovoltDM

	load_array "c:/hdyson/incoming/Zernike_Files/simple_test0.txt"

    }
}
#---------------------------------------------------------------------------
# proc spatial_sequence
# 
# Writes a sequence of spatial frequencies to the DM, following a
# specific filename pattern (see code).  Measures the DM response to
# each spatial frequency measurement.
#
### For DMs: BMC 140, Membrane 256, BMC 1024, Membrane 1024
#
#---------------------------------------------------------------------------

proc spatial_sequence { } {

    foreach i { A B C D E F G H I J K L } {
	for {set Freq 0 } { $Freq <6} {incr Freq } {

	    set run_name Spatial_Freq_Test_${Freq}_null_${i}
	    load_array "C:/hdyson/Spatial_Freq_Tests/Max_Voltage/spatial_freq_0.txt"
	    auto_run_test $run_name

	    set run_name Spatial_Freq_Test_${Freq}_data_${i}
	    load_array "C:/hdyson/Spatial_Freq_Tests/Max_Voltage/spatial_freq_${Freq}.txt"
	    auto_run_test $run_name

	    set run_name Spatial_Freq_vert_Test_${Freq}_null_${i}
	    load_array "C:/hdyson/Spatial_Freq_Tests/Max_Voltage/spatial_freq_vert_0.txt"
	    auto_run_test $run_name

	    set run_name Spatial_Freq_vert_Test_${Freq}_data_${i}
	    load_array "C:/hdyson/Spatial_Freq_Tests/Max_Voltage/spatial_freq_vert_${Freq}.txt"
	    auto_run_test $run_name
	}
    }

    load_array "c:/hdyson/incoming/Zernike_Files/simple_test0.txt"

    output C:/usr/data/tests/opd_psf_big  C:/hdyson/Incoming/data_ascii/Spat_Freq_Max_Voltage

}

##########################################
##Amendments for 3rd DM below (bmc1024):

#hdyson@lucent.com: 18th May 04

#---------------------------------------------------------------------------
# proc dm1k_panel
# 
# Initialization to be done before popping up the closeLoopPanel
#
### For DMs: BMC 1024
#
#---------------------------------------------------------------------------

proc dm1k_panel {} {

    global device MAX_ACT MAX_VOLT ZeroFile MaskFile
    global CurDrv volts nmodes acts selected
    global MaskFile maskArray ACT_LINE_LENGTH

    if {$device == "bmc1024"} {
    } elseif {$device == "bmc140"} {
	rename dm.help bmcdm.help
	rename dm.send bmcdm.send
	rename dm.poke bmcdm.poke
	rename dm.pokeraw bmcdm.pokeraw
	rename dm.ping bmcdm.ping
	rename bmcdm1k.help dm.help
	rename bmcdm1k.send dm.send
	rename bmcdm1k.poke dm.poke
	rename bmcdm1k.pokeraw dm.pokeraw
	rename bmcdm1k.ping dm.ping
    } elseif { $device == "membrane256"} {
	#Reset mdm functions to generic device functions...
	rename dm.help mdm.help
	rename dm.send mdm.send
	rename dm.poke mdm.poke
	rename dm.pokeraw mdm.pokeraw
	rename dm.ping mdm.ping
	#...and then set generic functions to call membrane functions
	rename bmcdm1k.help dm.help
	rename bmcdm1k.send dm.send
	rename bmcdm1k.poke dm.poke
	rename bmcdm1k.pokeraw dm.pokeraw
	rename bmcdm1k.ping dm.ping
    } elseif { $device == "membrane1024"} {
	#Reset mdm functions to generic device functions...
	rename dm.help mdm1k.help
	rename dm.send mdm1k.send
	rename dm.poke mdm1k.poke
	rename dm.pokeraw mdm1k.pokeraw
	rename dm.ping mdm1k.ping
	#...and then set generic functions to call membrane functions
	rename bmcdm1k.help dm.help
	rename bmcdm1k.send dm.send
	rename bmcdm1k.poke dm.poke
	rename bmcdm1k.pokeraw dm.pokeraw
	rename bmcdm1k.ping dm.ping
    } elseif { $device == "tdm1024"} {
	#Reset mdm functions to generic device functions...
	rename dm.help tdm1k.help
	rename dm.send tdm1k.send
	rename dm.poke tdm1k.poke
	rename dm.pokeraw tdm1k.pokeraw
	rename dm.ping tdm1k.ping
	#...and then set generic functions to call membrane functions
	rename bmcdm1k.help dm.help
	rename bmcdm1k.send dm.send
	rename bmcdm1k.poke dm.poke
	rename bmcdm1k.pokeraw dm.pokeraw
	rename bmcdm1k.ping dm.ping
    } elseif { $device == "NULL" } {
	rename bmcdm1k.help dm.help
	rename bmcdm1k.send dm.send
	rename bmcdm1k.poke dm.poke
	rename bmcdm1k.pokeraw dm.pokeraw
	rename bmcdm1k.ping dm.ping
    }
    #if $device not one of above values, do nothing
    #At present, this situation cannot arise...

    set device "bmc1024"

    set MAX_ACT 1024
    set ACT_LINE_LENGTH 32
    set MAX_VOLT 55

    # Define file with a default zero voltage array for DM
    set ZeroFile c:/usr/aos/wavescope/src/lists/Zeros_bmc_1024

    # MaskFile is an ascii file consisting of $NMAK_ACT integer elements
    # If file entry is = 1, actuator is used in generating recon, otherwise
    # it is skpped. It is loaded as $maskArray.
    set MaskFile c:/usr/aos/wavescope/src/lists/Mask_bmc_1024.txt

    a.make 0 $MAX_ACT = CurDrv
    a.make 0 $MAX_ACT = volts

    for {set i 1} {$i <= $MAX_ACT} {incr i} {
	#To initalise to bias voltage:
	set acts($i) 0
	#To initalise to 0 Volts:
	#  set acts($i) -100
	#hdyson 8th Oct 03
	set selected($i) 0
    }

    set nmodes $MAX_ACT

    for { set i 0 } { $i < $nmodes } { incr i } {
	set mode($i) 0
	set modew($i) 1
	set mods($i) 0
    }

    a.loadasc $MaskFile i = maskArray
    closeLoopPanel
}

#--------------------------------------------------------------------------
# proc BMCDM1K_GUI
# 
# Displays the Deformable Mirror control panel, which is a graphical
# representation of the mirror actuators, and controls to change the 
# values on each.
#
### For DMs: BMC 1024
#
#--------------------------------------------------------------------------

proc BMCDM1K_GUI {} {

    global acts pokeVar whichAct platform wsdb maskArray

    if { [winfo exists .dm] } {
	destroy .dm
    }

    ScrollButton .dm "BMC 1K DM Controls" PokeAct

    update

}

#--------------------------------------------------------------------------
# proc BMCDM1K_GUI_NINE
# 
# Displays the Deformable Mirror control panel, which is a graphical
# representation of the mirror actuators, and controls to change the 
# values on each.  Controls 3x3 block of actuators at a time.
#
### For DMs: BMC 1024
#
#--------------------------------------------------------------------------

proc BMCDM1K_GUI_NINE {} {

    global acts pokeVar whichAct platform wsdb maskArray

    if { [winfo exists .dm] } {
	destroy .dm
    }

    ScrollButton .dm "BMC 1K DM Controls: 3x3" PokeActNine

    update
}

#--------------------------------------------------------------------------
# proc BMCDM1K_GUI_25
# 
# Displays the Deformable Mirror control panel, which is a graphical
# representation of the mirror actuators, and controls to change the 
# values on each.  Controls 5x5 block of actuators at a time.
#
### For DMs: BMC 1024
#
#--------------------------------------------------------------------------

proc BMCDM1K_GUI_25 {} {

    global acts pokeVar whichAct platform wsdb maskArray

    if { [winfo exists .dm] } {
	destroy .dm
    }

    ScrollButton .dm "BMC 1K DM Controls: 5x5" PokeAct25

    update
}

#--------------------------------------------------------------------------
# proc MDM1K_GUI
# 
# Displays the Deformable Mirror control panel, which is a graphical
# representation of the mirror actuators, and controls to change the 
# values on each.
#
### For DMs: Membrane 1024
#
#--------------------------------------------------------------------------

proc MDM1K_GUI {} {

    global acts pokeVar whichAct platform wsdb maskArray

    if { [winfo exists .dm] } {
	destroy .dm
    }

    ScrollButton .dm "1024 Membrane DM Controls" PokeAct

    update

}

#--------------------------------------------------------------------------
# proc MDM1K_GUI_NINE
# 
# Displays the Deformable Mirror control panel, which is a graphical
# representation of the mirror actuators, and controls to change the 
# values on each.  Controls 3x3 block of actuators at a time.
#
### For DMs: Membrane 1024
#
#--------------------------------------------------------------------------

proc MDM1K_GUI_NINE {} {

    global acts pokeVar whichAct platform wsdb maskArray

    if { [winfo exists .dm] } {
	destroy .dm
    }

    ScrollButton .dm "1024 Membrane DM Controls: 3x3" PokeActNine

    update
}

#--------------------------------------------------------------------------
# proc MDM1K_GUI_25
# 
# Displays the Deformable Mirror control panel, which is a graphical
# representation of the mirror actuators, and controls to change the 
# values on each.  Controls 5x5 block of actuators at a time.
#
### For DMs: Membrane 1024
#
#--------------------------------------------------------------------------

proc MDM1K_GUI_25 {} {

    global acts pokeVar whichAct platform wsdb maskArray

    if { [winfo exists .dm] } {
	destroy .dm
    }

    ScrollButton .dm "1024 Membrane DM Controls: 5x5" PokeAct25

    update
}

##########################################
##Amendments for 4th DM below (membrane1024):

#hdyson@lucent.com: 18th May 04

#---------------------------------------------------------------------------
# proc dm1k_panel
# 
# Initialization to be done before popping up the closeLoopPanel
#
### For DMs: Membrane 1024
#
#---------------------------------------------------------------------------

proc mdm1k_panel {} {

    global device MAX_ACT MAX_VOLT ZeroFile MaskFile
    global CurDrv volts nmodes acts selected
    global MaskFile maskArray XACT_LINE_LENGTH YACT_LINE_LENGTH

    if {$device == "membrane1024"} {
    } elseif {$device == "bmc140"} {
	rename dm.help bmcdm.help
	rename dm.send bmcdm.send
	rename dm.poke bmcdm.poke
	rename dm.pokeraw bmcdm.pokeraw
	rename dm.ping bmcdm.ping
	rename mdm1k.help dm.help
	rename mdm1k.send dm.send
	rename mdm1k.poke dm.poke
	rename mdm1k.pokeraw dm.pokeraw
	rename mdm1k.ping dm.ping
    } elseif { $device == "membrane256"} {
	#Reset mdm functions to generic device functions...
	rename dm.help mdm.help
	rename dm.send mdm.send
	rename dm.poke mdm.poke
	rename dm.pokeraw mdm.pokeraw
	rename dm.ping mdm.ping
	#...and then set generic functions to call membrane functions
	rename mdm1k.help dm.help
	rename mdm1k.send dm.send
	rename mdm1k.poke dm.poke
	rename mdm1k.pokeraw dm.pokeraw
	rename mdm1k.ping dm.ping
    } elseif { $device == "bmc1024"} {
	#Reset mdm functions to generic device functions...
	rename dm.help bmcdm1k.help
	rename dm.send bmcdm1k.send
	rename dm.poke bmcdm1k.poke
	rename dm.pokeraw bmcdm1k.pokeraw
	rename dm.ping bmcdm1k.ping
	#...and then set generic functions to call membrane functions
	rename mdm1k.help dm.help
	rename mdm1k.send dm.send
	rename mdm1k.poke dm.poke
	rename mdm1k.pokeraw dm.pokeraw
	rename mdm1k.ping dm.ping
    } elseif { $device == "tdm1024"} {
	#Reset mdm functions to generic device functions...
	rename dm.help tdm1k.help
	rename dm.send tdm1k.send
	rename dm.poke tdm1k.poke
	rename dm.pokeraw tdm1k.pokeraw
	rename dm.ping tdm1k.ping
	#...and then set generic functions to call membrane functions
	rename mdm1k.help dm.help
	rename mdm1k.send dm.send
	rename mdm1k.poke dm.poke
	rename mdm1k.pokeraw dm.pokeraw
	rename mdm1k.ping dm.ping
    } elseif { $device == "NULL" } {

	load C:/hdyson/Incoming/1024_Membrane_DMTCL_Version1/MDMDMtcl1K.dll

        #DEBUG
        puts stdout "mdm1k_panel: loaded dll"
        puts stdout "C:/hdyson/Incoming/1024_Membrane_DMTCL_Version1/MDMDMtcl1K.dll"

	rename mdm1k.help dm.help
	rename mdm1k.send dm.send
	rename mdm1k.poke dm.poke
	rename mdm1k.pokeraw dm.pokeraw
	rename mdm1k.ping dm.ping
    }
    #if $device not one of above values, do nothing
    #At present, this situation cannot arise...

    set device "membrane1024"

    set MAX_ACT 1332
    set XACT_LINE_LENGTH 36
    set YACT_LINE_LENGTH 37
    set MAX_VOLT 120

    # Define file with a default zero voltage array for DM
    set ZeroFile c:/usr/aos/wavescope/src/lists/Zeros_membrane_1024

    # MaskFile is an ascii file consisting of $NMAK_ACT integer elements
    # If file entry is = 1, actuator is used in generating recon, otherwise
    # it is skpped. It is loaded as $maskArray.
    set MaskFile c:/usr/aos/wavescope/src/lists/Mask_membrane_1024.txt

    a.make 0 $MAX_ACT = CurDrv
    a.make 0 $MAX_ACT = volts

    for {set i 1} {$i <= $MAX_ACT} {incr i} {
	#To initalise to bias voltage:
	#set acts($i) 0
	#To initalise to 0 Volts:
        set acts($i) -100
	#hdyson 8th Oct 03
	set selected($i) 0
    }

    set nmodes $MAX_ACT

    for { set i 0 } { $i < $nmodes } { incr i } {
	set mode($i) 0
	set modew($i) 1
	set mods($i) 0
    }

    a.loadasc $MaskFile i = maskArray
    closeLoopPanel
}

#--------------------------------------------------------------------------
# proc MDM1K_OVER_GUI
# 
# Displays the Deformable Mirror control panel, which is a graphical
# representation of the mirror actuators, and controls to change the
# values on each.  This version deals with VOLTAGES and allows
# individual actuators to go over maximum Voltage.  This is okay for
# membrane mirrors, but not for segmented mirrors.
#
### For DMs: Membrane 1024
#
#--------------------------------------------------------------------------

proc MDM1K_OVER_GUI {} {

    global acts pokeVar whichAct platform wsdb maskArray

    if { [winfo exists .dm] } {
	destroy .dm
    }

    ScrollButton .dm "1024 Membrane DM Controls: Over-voltage single actuator operation" OverPokeAct

    set overpokemsg "Warning: This function operates on voltages, not deflections"
    message .dm.overpokemsg -text $overpokemsg -aspect 1000 -font $wsdb(font)
    pack    .dm.overpokemsg -padx 5 -pady 5

    update

}

# proc MDM1K_OVER_GUI {} {

#   global acts pokeVar whichAct platform wsdb maskArray
#   global XACT_LINE_LENGTH YACT_LINE_LENGTH

#   if { [winfo exists .dm] } {
#     destroy .dm
#   }
#   toplevel    .dm
#   wm title    .dm "Membrane DM Controls"
#   wm geometry .dm +5-35
#   frame       .dm.f
#   pack        .dm.f

#   frame       .dm.f.labf
#   pack        .dm.f.labf -anchor w
#   message     .dm.f.labf.m1 -text "Actuator:" -width 3c
#   message     .dm.f.labf.m2 -textvariable whichAct -width 2c
#   pack        .dm.f.labf.m1 .dm.f.labf.m2 -side left

#   if {$platform == "windows"} {
#     set ht 1
# #    set bd 1
#     set bd 0
#   } else {
#     set ht 0
#     set bd 1
#   }

#   for { set y 0 } { $y < $YACT_LINE_LENGTH } { incr y } {
#     frame .dm.f.acts$y
#     pack  .dm.f.acts$y
#     for { set x 0 } { $x < $XACT_LINE_LENGTH } { incr x } {
#       set bnum [expr $y * $XACT_LINE_LENGTH + $x + 1]
#       checkbutton .dm.f.acts$y.$bnum -textvariable "" -width 0 \
    #           -height $ht -bd $bd -variable selected($bnum) -command SetAct
# #      checkbutton .dm.f.acts$y.$bnum -textvariable acts($bnum) -width 3 \
    # #          -height $ht -bd $bd -variable selected($bnum) -command SetAct
#       pack        .dm.f.acts$y.$bnum -side left
#     }
#   }

#   set i 0

#   for { set y 0 } { $y < $YACT_LINE_LENGTH } { incr y } {
#       for { set x 0 } { $x < $XACT_LINE_LENGTH } { incr x } {
# 	  if { [ a.extele maskArray $i ] != 1 } {
# 	      set bnum [expr $y * $XACT_LINE_LENGTH + $x + 1]
# 	      .dm.f.acts$y.$bnum configure -state disabled
# 	  }
# 	  incr i
#       }
#   }

#   frame .dm.f.poke

#   set overpokemsg "Warning: This function operates on voltages, not deflections"
#   message .dm.f.labf.overpokemsg -text $overpokemsg -aspect 1000 -font $wsdb(font)
#   pack    .dm.f.labf.overpokemsg -padx 5 -pady 5

#   scale .dm.f.poke.scale -from 0 -to 90 -length 350 \
    #           -orient horizontal -variable pokeVar -command OverPokeAct
#   pack  .dm.f.poke.scale

#   frame  .dm.f.buts
#   frame	 .dm.f.stub
#   button .dm.f.buts.zerovolt -text "Zero Volt DM" -command ZerovoltDM_VoltGUI
#   button .dm.f.buts.ok -text "  OK  " -command {destroy .dm} -font $wsdb(font)
#   pack   .dm.f.buts.zerovolt .dm.f.buts.ok -side left -padx 5
#   pack   .dm.f.poke .dm.f.buts .dm.f.stub -padx 5 -pady 5

#   update
# }

#############################################################
#Additional ancillary functions.  hdyson@lucent.com; 25th May 04

#--------------------------------------------------------------------------
# proc ScrollButton
#
# This function displays the electrode array in a scrollable frmae,
# for large actuator count devices.
#
### For DMs: BMC 1024, Membrane 1024
#
#--------------------------------------------------------------------------

proc ScrollButton { top title command } {

    global device MAX_ACT MAX_VOLT ZeroFile MaskFile
    global CurDrv volts nmodes acts selected
    global MaskFile maskArray XACT_LINE_LENGTH YACT_LINE_LENGTH
    global wsdb

    toplevel $top
    wm minsize $top 200 100
    wm title $top $title

    frame       $top.labf
    set current $top.labf
    pack        $current -anchor w
    message     $current.m1 -text "Actuator:" -width 3c
    message     $current.m2 -textvariable whichAct -width 2c
    pack        $current.m1 $current.m2 -side left

    set buts [ frame $top.buts  ]
    set stub [ frame $top.stub ]
    button $buts.flat -text "Bias DM" -command FlatDM
    button $buts.zerovolt -text "Zero Volt DM" -command ZerovoltDM
    button $stub.save -text "Save Settings..." -command SaveDM
    button $stub.load -text "Load Settings..." -command LoadDM
    button $stub.zerl -text "Reset Zeros File ..." -command ResetZDM
    button $buts.ok -text "  OK  " -command {destroy .dm} -font $wsdb(font)
    pack   $stub.load $stub.save $stub.zerl -side left -padx 5
    pack   $buts.flat $buts.zerovolt $buts.ok -side left -padx 5


    set pf [ frame $top.poke ]
    scale $pf.scale -from -109 -to 109 -length 350 \
	-orient horizontal -variable pokeVar -command $command
    pack  $pf.scale

    pack   $pf $buts $stub -padx 5 -pady 5 -side bottom


    frame $top.c
    canvas $top.c.canvas -width 10 -height 10 \
	-yscrollcommand [ list $top.c.yscroll set ] \
	-xscrollcommand [ list $top.c.xscroll set ]
    scrollbar $top.c.yscroll -orient vertical \
	-command [ list $top.c.canvas yview ]
    scrollbar $top.c.xscroll -orient horizontal \
	-command [ list $top.c.canvas xview ]
    pack $top.c.yscroll -side right -fill y
    pack $top.c.xscroll -side bottom -fill x
    pack $top.c.canvas -side left -fill both -expand true
    pack $top.c -side top -fill both -expand true

    Scrolled_EntrySet $top.c.canvas 
}

#--------------------------------------------------------------------------
# proc Scrolled_EntrySet
#
# This function is used by ScrollButton to store the full array of
# actuators.  Only a subset are visible through the ScrollButton
# function.
#
### For DMs: BMC 1024, Membrane 1024
#
#--------------------------------------------------------------------------

proc Scrolled_EntrySet { canvas } {

    global device MAX_ACT MAX_VOLT ZeroFile MaskFile
    global CurDrv volts nmodes acts selected
    global MaskFile maskArray XACT_LINE_LENGTH YACT_LINE_LENGTH
    global wsdb

    set f [ frame $canvas.f -bd 0 ]
    $canvas create window 0 0 -anchor nw -window $f

    set i 0

    set ht 1
    set bd 1

    for { set y 0 } { $y < $YACT_LINE_LENGTH } { incr y } {
	frame $f.acts$y
	grid  $f.acts$y
	for { set x 0 } { $x < $XACT_LINE_LENGTH } { incr x } {
	    set bnum [expr $y * $XACT_LINE_LENGTH + $x + 1]
	    checkbutton $f.acts$y.$bnum -textvariable "" -width 3 \
		-height $ht -bd $bd -variable selected($bnum) -command SetAct
	    #      checkbutton .f.acts$y.$bnum -textvariable acts($bnum) -width 3 \
		#          -height $ht -bd $bd -variable selected($bnum) -command SetAct
	    grid        $f.acts$y.$bnum -row $y -column $x
	}
    } 

    set child $f.acts0

    set i 0

    for { set y 0 } { $y < $YACT_LINE_LENGTH } { incr y } {
	for { set x 0 } { $x < $XACT_LINE_LENGTH } { incr x } {
	    if { [ a.extele maskArray $i ] != 1 } {
		set bnum [expr $y * $XACT_LINE_LENGTH + $x + 1]
		$f.acts$y.$bnum configure -state disabled
	    }
	    incr i
	}
    }

    tkwait visibility $child
    set bbox [ grid bbox $f 0 0 ]
    set incr [lindex $bbox 3 ]
    set width [winfo reqwidth $f ]
    set height [winfo reqheight $f]
    $canvas config -scrollregion " 0 0 $width $height "
    $canvas config -yscrollincrement $incr
    set max $XACT_LINE_LENGTH
    set height [expr $incr * $max]

    set height 400
    set width 400

    $canvas config -width $width -height $height
}

#############################################################

#New functions for transparent electrode operation.
#hdyson, 2nd Sep 2004

proc tdm_panel {} {

    global device MAX_ACT MAX_VOLT ZeroFile MaskFile
    global CurDrv volts nmodes acts selected
    global MaskFile maskArray XACT_LINE_LENGTH YACT_LINE_LENGTH
    global Varray

    if {$device == "tdm1024"} {
	tdm1k.ramp 0 $Varray
    } elseif {$device == "bmc140"} {
	rename dm.help bmcdm.help
	rename dm.send bmcdm.send
	rename dm.poke bmcdm.poke
	rename dm.pokeraw bmcdm.pokeraw
	rename dm.ping bmcdm.ping
	rename tdm1k.help dm.help
	rename tdm1k.send dm.send
	rename tdm1k.poke dm.poke
	rename tdm1k.pokeraw dm.pokeraw
	rename tdm1k.ping dm.ping
    } elseif { $device == "membrane256"} {
	#Reset mdm functions to generic device functions...
	rename dm.help mdm.help
	rename dm.send mdm.send
	rename dm.poke mdm.poke
	rename dm.pokeraw mdm.pokeraw
	rename dm.ping mdm.ping
	#...and then set generic functions to call membrane functions
	rename tdm1k.help dm.help
	rename tdm1k.send dm.send
	rename tdm1k.poke dm.poke
	rename tdm1k.pokeraw dm.pokeraw
	rename tdm1k.ping dm.ping
    } elseif { $device == "bmc1024"} {
	#Reset mdm functions to generic device functions...
	rename dm.help bmcdm1k.help
	rename dm.send bmcdm1k.send
	rename dm.poke bmcdm1k.poke
	rename dm.pokeraw bmcdm1k.pokeraw
	rename dm.ping bmcdm1k.ping
	#...and then set generic functions to call membrane functions
	rename tdm1k.help dm.help
	rename tdm1k.send dm.send
	rename tdm1k.poke dm.poke
	rename tdm1k.pokeraw dm.pokeraw
	rename tdm1k.ping dm.ping
    } elseif { $device == "tdm1024"} {
	#Reset mdm functions to generic device functions...
	rename dm.help tdm1k.help
	rename dm.send tdm1k.send
	rename dm.poke tdm1k.poke
	rename dm.pokeraw tdm1k.pokeraw
	rename dm.ping tdm1k.ping
	#...and then set generic functions to call membrane functions
	rename tdm1k.help dm.help
	rename tdm1k.send dm.send
	rename tdm1k.poke dm.poke
	rename tdm1k.pokeraw dm.pokeraw
	rename tdm1k.ping dm.ping
    } elseif { $device == "NULL" } {
	load C:/hdyson/Incoming/1024_Membrane_Transparent_DMTCL_Version1/TransparentMDMDMtcl1k.dll

        #DEBUG
        puts stdout "tdm_panel: loaded dll"
        puts stdout "C:/hdyson/Incoming/1024_Membrane_DMTCL_Version1/TransparentMDMDMtcl1K.dll"



	rename tdm1k.help dm.help
	rename tdm1k.send dm.send
	rename tdm1k.poke dm.poke
	rename tdm1k.pokeraw dm.pokeraw
	rename tdm1k.ping dm.ping
	tdm1k.ramp 0 $Varray
    }
    #if $device not one of above values, do nothing
    #At present, this situation cannot arise...

    set device "tdm1024"

    set MAX_ACT 1369
    set XACT_LINE_LENGTH 37
    set YACT_LINE_LENGTH 37
    set MAX_VOLT 120

    # Define file with a default zero voltage array for DM
    set ZeroFile c:/usr/aos/wavescope/src/lists/Zeros_membrane_1024

    # MaskFile is an ascii file consisting of $NMAK_ACT integer elements
    # If file entry is = 1, actuator is used in generating recon, otherwise
    # it is skpped. It is loaded as $maskArray.
    set MaskFile c:/usr/aos/wavescope/src/lists/mask_transparent_tcl.txt
    #Above for 1st device
#    set MaskFile c:/usr/aos/wavescope/src/lists/mask_transparent_2nd_device_tcl.txt
    #above for 2nd device

    a.make 0 $MAX_ACT = CurDrv
    a.make 0 $MAX_ACT = volts
#    a.to volts uc = volts

    for {set i 1} {$i <= $MAX_ACT} {incr i} {
	#To initalise to bias voltage:
	set acts($i) 0
	#To initalise to 0 Volts:
	#  set acts($i) -100
	#hdyson 8th Oct 03
	set selected($i) 0
    }

    set nmodes $MAX_ACT

    for { set i 0 } { $i < $nmodes } { incr i } {
	set mode($i) 0
	set modew($i) 1
	set mods($i) 0
    }

    a.loadasc $MaskFile i = maskArray
    closeLoopPanel

    #Note that if we're here, it implies that device=tdm1024
    bind .cl <Destroy> { if {"%W" == ".cl" } {tdm1k.ramp $Varray 0 }}

}


#---------------------------------------------------------------------------
#
# proc prep_arrays_T
#
# Creates arrays to be used with the dm.send function from the command-line for the transparent electrode device.
#
#
### For DMs: Transparent 1024 ONLY
#
#---------------------------------------------------------------------------

proc prep_arrays_T {} {

    global MAX_ACT
    #    global temp0 temp10 temp15 temp18 temp20
    global temp20 temp19 temp 21 temp18 temp22 temp16 temp24

    a.make 20 $MAX_ACT = temp
    a.to temp d = temp20
    a.make 19 $MAX_ACT = temp
    a.to temp d = temp19
    a.make 21 $MAX_ACT = temp
    a.to temp d = temp21
    a.make 18 $MAX_ACT = temp
    a.to temp d = temp18
    a.make 22 $MAX_ACT = temp
    a.to temp d = temp22
    a.make 16 $MAX_ACT = temp
    a.to temp d = temp16
    a.make 24 $MAX_ACT = temp
    a.to temp d = temp24


    #     a.make 0 $MAX_ACT = temp
    #     a.to temp uc = temp0
    #     a.make 10 $MAX_ACT = temp
    #     a.to temp uc = temp10
    #     a.make 15 $MAX_ACT = temp
    #     a.to temp uc = temp15
    #     a.make 18 $MAX_ACT = temp
    #     a.to temp uc = temp18
    #     a.make 20 $MAX_ACT = temp
    #     a.to temp uc = temp20

}

#--------------------------------------------------------------------------
# proc T_GUI
#
# Displays the Deformable Mirror control panel, which is a graphical
# representation of the mirror actuators, and controls to change the
# values on each.
#
### For DMs: Transparent 1024
#
#--------------------------------------------------------------------------

proc T_GUI {} {

    global acts pokeVar whichAct platform wsdb maskArray

    if { [winfo exists .dm] } {
	destroy .dm
    }

    ScrollButton .dm "1024 Transparent DM Controls" PokeAct

    update

}

#--------------------------------------------------------------------------
# proc T_GUI_25
#
# Displays the Deformable Mirror control panel, which is a graphical
# representation of the mirror actuators, and controls to change the
# values on each.  Controls 5x5 block of actuators at a time.
#
### For DMs: Transparent 1024
#
#--------------------------------------------------------------------------

proc T_GUI_25 {} {

    global acts pokeVar whichAct platform wsdb maskArray

    if { [winfo exists .dm] } {
	destroy .dm
    }

    ScrollButton .dm "1024 Transparent DM Controls: 5x5" PokeAct25

    update
}

#--------------------------------------------------------------------------
# proc T_GUI_NINE
#
# Displays the Deformable Mirror control panel, which is a graphical
# representation of the mirror actuators, and controls to change the
# values on each.  Controls 3x3 block of actuators at a time.
#
### For DMs: Transparent 1024
#
#--------------------------------------------------------------------------

proc T_GUI_NINE {} {

    global acts pokeVar whichAct platform wsdb maskArray

    if { [winfo exists .dm] } {
	destroy .dm
    }

    ScrollButton .dm "1024 Transparent DM Controls: 3x3" PokeActNine

    update
}


#--------------------------------------------------------------------------
# proc T_OVER_GUI
#
# Displays the Deformable Mirror control panel, which is a graphical
# representation of the mirror actuators, and controls to change the
# values on each.  This version deals with VOLTAGES and allows
# individual actuators to go over maximum Voltage.  This is okay for
# membrane mirrors, but not for segmented mirrors.
#
### For DMs: Transparent 1024
#
#--------------------------------------------------------------------------

proc T_OVER_GUI {} {

    global acts pokeVar whichAct platform wsdb maskArray

    if { [winfo exists .dm] } {
	destroy .dm
    }

    ScrollButton .dm "1024 Transparent DM Controls: Over-voltage single actuator operation" T_OverPokeAct

    set overpokemsg "Warning: This function operates on voltages, not deflections"
    message .dm.overpokemsg -text $overpokemsg -aspect 1000 -font $wsdb(font)
    pack    .dm.overpokemsg -padx 5 -pady 5

    update

}


#---------------------------------------------------------------------------
# proc T_OverPokeAct
#
# Updates the value of a particular actuator, sends that actuator value
# to the DM.
# This version deals with VOLTAGES and allows individual actuators to
# go over maximum Voltage.  This is okay for membrane mirrors, but not
# for segmented mirrors.
#
### For DMs: Transparent 1024 ONLY
#
#---------------------------------------------------------------------------

proc T_OverPokeAct { value } {

    global whichAct acts volts CurDrv

    set acts($whichAct) $value
    set wact [expr $whichAct - 1]
    set falue  $value 
    a.repele $falue CurDrv $wact = CurDrv
    ftov $CurDrv volts
    #set pvalue [expr $value + 109]
    #dm.poke $wact $pvalue

    #	a.extele volts $wact = test
    #	puts [ a.dump $test ]
#    a.to volts uc = volts
    dm.send volts

    ###Original code below:
    # 	set acts($whichAct) $value
    # 	set wact [expr $whichAct - 1]
    # 	a.repele $value volts $wact = volts
    # 	a.to volts uc = CurDrv
    # 	dm.send CurDrv
}

#---------------------------------------------------------------------------
# proc tftov
#
# Convert float values in range -1..1 to output values in the range 0..220,
# applying an scaling factor since actuator response is not linear.
#
### For DMs: Transparent 1024
#
#---------------------------------------------------------------------------

proc tftov { fracar voltar } {

    upvar $voltar vt

    global MAX_VOLT deltaV Varray

    a.sqrt $fracar = ftemp

    a.mul $ftemp $deltaV = ftemp

    a.sub $Varray $ftemp = ftemp

    # 	a.add   $fracar 1 = ftemp 
    # 	#  a.lim    ftemp 2 =  ftemp 
    # 	#Upper limiting now done in dm.send function
    # 	a.limlow ftemp 0 =  ftemp 

    # 	#Above three lines yield ftemp array running from 0-2
    # 	#(from voltar array, which should range from -1 to 1)

    # 	a.sqrt ftemp = ftemp 

    # 	set midvolt [expr {0.7071 * $MAX_VOLT}] 
    # 	#added 24th Sept.

    # 	#  a.mul   ftemp 154 = ftemp 
    # 	#Original

    # 	a.mul   ftemp $midvolt = ftemp 
    #added 24th Sept.
    a.to    ftemp d =  vt 
    #Copies (float) ftemp to unsigned char vt
}

#############################################################

#Additional testing functions

proc setarray { } {

	       global Varray MAX_ACT Varray Vm

	       a.make $Varray $MAX_ACT = temp
	       a.to $temp d = temp
	       tdm1k.pokemembrane $Vm
	       tdm1k.sendraw $temp

	   }

#############################################################
#############################################################
#############################################################
#############################################################
#############################################################
#############################################################
#############################################################

#Strictly unstable testing code below (note that this is not a claim that the code above is stable!):

proc pokebin { act volt } {

    dm.pokeraw $act $volt
    dm.pokeraw [ expr { $act + 1 } ] $volt
    dm.pokeraw [ expr { $act + 37 } ] $volt
    dm.pokeraw [ expr { $act + 38 } ] $volt
}



proc setzero { } {

    global Vm
    global Varray

    set Vm 0
    set Varray 0

    setarray
}

###########################################################
#
# Procedures below this line were added by P. Kurczynski
# plk 12/9/2004
#
###########################################################



############################################################
# poke3x3bin
#
# writes a voltage to a specified electrode and its
# adjacent electrodes to form a 3x3 bin of electrodes
# at the same, specified voltage.
#
# arguments:
#    act     the actuator number of the corner actuator
#            This number is indicated in H.Dyson's wire list
#            that is used in the C code for wavescope operation
#            of Lucent 1024 transp. electrode membr. devices
# 
#   volt     The desired voltage of the 3x3 bin of electrodes,
#            in Volts.
#
#
# plk 12/9/2004
##############################################################

proc poke3x3bin { act volt } {

    dm.pokeraw [ expr { $act + 0 } ] $volt
    dm.pokeraw [ expr { $act + 1 } ] $volt
    dm.pokeraw [ expr { $act + 2 } ] $volt

    dm.pokeraw [ expr { $act + 37 + 0 } ] $volt
    dm.pokeraw [ expr { $act + 37 + 1 } ] $volt
    dm.pokeraw [ expr { $act + 37 + 2 } ] $volt

    dm.pokeraw [ expr { $act + 38 + 0 } ] $volt
    dm.pokeraw [ expr { $act + 38 + 1 } ] $volt
    dm.pokeraw [ expr { $act + 38 + 2 } ] $volt

}

############################################################
# poke3x3diag
#
# sets a set of 3x3 bins to the same electrode voltage.
# Bins span the array in diagonal, from SW to NE chip sides
# arguments:
#      inLowVoltage    Minimum voltage of the bins
#      inHighVoltage   Maximum voltage of the bins
#
# plk 12/9/2004
##############################################################
proc poke3x3diag { inLowVoltage inHighVoltage } {

   # begin poke'ing in SW quadrant.  
   # alternate Low, High toward the NE
   poke3x3bin 228 $inLowVoltage

   poke3x3bin 342 $inHighVoltage

   poke3x3bin 456 $inLowVoltage

   poke3x3bin 570 $inHighVoltage

   poke3x3bin 684 $inLowVoltage

   poke3x3bin 798 $inHighVoltage

   poke3x3bin 912 $inLowVoltage

   poke3x3bin 1026 $inHighVoltage


}


