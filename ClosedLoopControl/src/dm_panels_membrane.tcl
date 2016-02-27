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
# FILE: dm_panels_bmc.tcl
# 
# DESCRIPTION: BMC Micromachined deformable mirror closed loop scripts
# 
# $Id: dm_panels_bmc.tcl,v 1.1 2000/11/07 16:37:19 herb Exp $
# 
#--------------------------------------------------------------------------
#####
# Modified by allan 2001/04/26 to include refinements developed for
# control of DM with missing or unobserved actuators
#####

## 
# Modified for 256 channel membrane mirror, hdyson, 14th Oct 03
# To Do list at end of file
#
# Change convention: Where an executable line follows a similar comment line,
# the comment line has been replaced by the executable, where the new executable
# is for the membrane mirror, while the comment was for the original BMC mirror
##

#
# GLOBALS
#

global volts CurDrv whichAct integGain ModFlg doneit selected
global mdm_closeloopFlag pokeVar mode modew mods mod modn wgtVar nmodes

set mdm_closeloopFlag Off
set integGain 30
set MAX_ACT 360

#Added Sep 24th hdyson@lucent.com (used in mdm_ftov function)
global MAX_VOLT
set MAX_VOLT 20

# Define file with a default zero voltage array for DM
set ZeroFile c:/usr/aos/wavescope/src/lists/Zeros_membrane

# new globals, part of improved reconstructor generation
#
# MaskFile is an ascii file consisting of $NMAK_ACT integer elements
# If file entry is = 1, actuator is used in generating recon, otherwise
# it is skpped. It is loaded as $maskArray.
set MaskFile c:/usr/aos/wavescope/src/lists/256_Membrane_Mask.txt
#
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
#set pokeFraction 0.5
set pokeFraction 0.5
#
set ModFlg "Poke"
set HW_Flag "True"
set LS_Dir [pwd]

for {set i 1} {$i <= $MAX_ACT} {incr i} {
  set acts($i) 0
  set selected($i) 0
}

set loopType NULL
set whichAct 2
set selected(2) 1
set pokeVar 0
set nmodes $MAX_ACT
set doneit 0
set mod 0
set modn 0

for { set i 0 } { $i < $nmodes } { incr i } {
  set mode($i) 0
  set modew($i) 1
  set mods($i) 0
}

a.make 0 $MAX_ACT = CurDrv
a.make 0 $MAX_ACT = volts



#---------------------------------------------------------------------------
# proc dm_panel
# 
# Initialization to be done before popping up the mdm_mdm_closeloopPanel
#---------------------------------------------------------------------------

proc mdm_panel {} {

  puts stdout "In mdm_panel, calling mdm_mdm_closeloopPanel"

#   global MaskFile maskArray
#   a.loadasc $MaskFile i = maskArray
#   puts stdout "In mdm_panel, calling mdm_mdm_closeloopPanel"
#   mdm_mdm_closeloopPanel
}



#---------------------------------------------------------------------------
# proc mdm_mdm_closeloopPanel
# 
# Closed loop/mirror flattening control panel
#---------------------------------------------------------------------------

proc mdm_mdm_closeloopPanel {} {

  global mdm_closeloopFlag integGain thresh wsdb


  if { [winfo exists .cl] } {
    destroy .cl
  }
  toplevel .cl
  wm title .cl "DM Controls"
  wm geometry .cl -30+90
  frame  .cl.f
  pack   .cl.f
  frame  .cl.f.clb -relief groove -bd 2
  button .cl.f.ok -text "  OK  " -font $wsdb(font) -command {mdm_endloop}
  pack   .cl.f.clb .cl.f.ok -padx 5 -pady 5

  set msg "Membrane DM Controls"
  message .cl.f.clb.msg -text $msg -aspect 1000 -font $wsdb(font)
  pack    .cl.f.clb.msg -padx 5 -pady 5

  button .cl.f.clb.poke -text "Poke DM..." -command { mdm_MDM_GUI }
  pack   .cl.f.clb.poke -side top -pady 5

  frame .cl.f.clb.ctl
  pack  .cl.f.clb.ctl -anchor w -pady 5
  
  button .cl.f.clb.ctl.mack -text "Make Recon..." -command { mdm_Mdm_MakereconPanel }  
  button .cl.f.clb.ctl.show -text "Display Modes..." -command { mdm_ShowModes }
  button .cl.f.clb.ctl.pick -text "Select Modes..." -command { mdm_PickModes }
  pack   .cl.f.clb.ctl.mack .cl.f.clb.ctl.show .cl.f.clb.ctl.pick \
      -side left -padx 5
              
  frame .cl.f.clb.cll
  pack  .cl.f.clb.cll -anchor center -pady 5
  
  checkbutton .cl.f.clb.cll.colb -text "Close Loop Slow - with OPD" \
      -variable mdm_closeloopFlag -command { mdm_clloop }
  checkbutton .cl.f.clb.cll.colb -text "Close Loop Slow - with OPD and PSF" \
      -variable mdm_closeloopFlag -command { mdm_cllooppsf }
  checkbutton .cl.f.clb.cll.colb -text "Close Loop Slow - with no display" \
      -variable mdm_closeloopFlag -command { mdm_clloopnodisplay }
  button      .cl.f.clb.cll.resp -text "Show Response" -command { mdm_ShowResp }
  pack        .cl.f.clb.cll.colb .cl.f.clb.cll.resp
 
  frame .cl.f.clb.tt -relief groove -bd 2
  pack  .cl.f.clb.tt -pady 5
  frame .cl.f.clb.tt.ctl1
  pack  .cl.f.clb.tt.ctl1 -padx 26
  scale .cl.f.clb.tt.ctl1.scaleG -from 0 -to 100 -length 200 -orient horizontal\
      -label "Gain" -variable integGain 
  pack  .cl.f.clb.tt.ctl1.scaleG -side left -padx 10

  update
}


#---------------------------------------------------------------------------
# proc mdm_PickModes
# 
# Closed loop mode selection control panel
#---------------------------------------------------------------------------

proc mdm_PickModes {} {

  global nmodes modw wsdb loopType


  if { $loopType == "NULL" } {
    dialog "Please Make a Reconstructor first."
    return
  }

  if { [winfo exists .pm] } { destroy .pm }
  
  set nmodes [a.cols modw]
  a.ext modw 0 0 1 1 = mw 
                          #a.ext? Extracts region from an array (ie modw) 
                          #and puts result in another array (ie mw)
  set wgtVar [a.ave mw]   
                          #a.ave? Averages input arrary(s)
  
  
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
               -length 250 -command {mdm_updateModew} -orient horizontal \
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
	  -variable mode($k) -command "mdm_updateModes $k" -width 6
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
	-variable mode($k) -command "mdm_updateModes $k" -width 6
    pack        .pm.f.snb.n$i.lt1  -side left -padx 10
  }
 
  update
}


proc mdm_updateModes { mod } \
{
	global modn nmodes mode wgtVar modw
	set modn $mod
	
	a.ext modw $mod 0 1 1 = mw
	set wgtVar [a.ave mw]
	for {set i 0} { $i < $nmodes } { incr i } \
  	{
  		if { $i != $modn} { set mode($i) 0}
 	}
}

proc mdm_updateModew { weight } \
{
	global modw modn doneit
	
	if { $doneit == 0 } \
	{
		a.ext modw 0 0 1 1 = mw
  		set weight [a.ave mw]
  		set modn 0
  		set doneit 1
	}

	a.repele $weight modw $modn 0 = modw
}




#---------------------------------------------------------------------------
# proc mdm_ShowModes
# 
# Mode display control panel
#---------------------------------------------------------------------------

proc mdm_ShowModes {} {

  global nmodes modw opd_idcl opd_wdcl lid movie wsdb loopType


  if { $loopType == "NULL" } {
    dialog "Please Make a Reconstructor first."
    return
  }

  if { [winfo exists .sm] } { destroy .sm }
  
  set movie 0
  set nmodes [a.cols modw]

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
  wm geometry .sm -5-5 
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
                    -command "mdm_showMode $k" -width 6
      pack        .sm.f.smb.f$j.m$i -padx 5
    }
  }

  if {$nrr > 0} {
    frame  .sm.f.smb.lf
    pack   .sm.f.smb.lf -side left -anchor n
    for { set i 0} { $i < $nrr } { incr i } {
      set k [expr 13 * $ncols + $i]
      checkbutton .sm.f.smb.lf.n$i -text " $k " -variable mods($k) \
                  -command "mdm_showMode $k" -width 6
      pack        .sm.f.smb.lf.n$i -padx 5
    }
  }

  checkbutton .sm.f.movie -text MOVIE -variable movie -command {mdm_cycle}
  button      .sm.f.ok -text "   OK   " -command {mdm_destr} -font $wsdb(font)
  pack        .sm.f.movie .sm.f.ok -padx 25 -pady 5 -side left
 
  update
}



#---------------------------------------------------------------------------
# proc mdm_cycle
# 
# Puts up a movie of the selected mode as long as the movie button is checked.
#---------------------------------------------------------------------------

proc mdm_cycle {} {

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
		
    mdm_SetGUIActs $CurDrv
    mdm_ftov $CurDrv  vvv
    mdm.send vvv
    update
  }
}



#---------------------------------------------------------------------------
# proc mdm_destr
# 
# Cleans up from the mdm_ShowModes/movie capability.
#---------------------------------------------------------------------------

proc mdm_destr {} {

  global opd_idcl opd_wdcl lid movie


  set movie 0
  set opd_idcl 0
  set opd_wdcl 0
  set lid 0
  destroy .sm
}



proc mdm_lap { vect lap } {

  upvar $lap lll
  

  a.v2toxy $vect = xg yg
  a.grad xg = dxg
  a.v2toxy dxg = dxx dxy
  a.grad yg = dyg
  a.v2toxy dyg = dyx dyy
  a.add dxx dyy = lll
}



proc mdm_conv { vvvv vv } {

  global wlCalibrate
  upvar $vv vect


  alg.conv.pg.arrays $vvvv $wlCalibrate(Params) = vect mask
}



proc mdm_calcLap {} {

  global Grad Lap


  mdm_conv $Grad gxgy
  mdm_lap $gxgy Lap
}



#---------------------------------------------------------------------------
# proc mdm_showMode
#
# Places a mode from the reconstructor creation onto the mirror.
#---------------------------------------------------------------------------

proc mdm_showMode { mod } {

  global opd_idcl modenum opd_wdcl wlCalibrate platform
  global Drvs nmodes mods Grad lid Lap CurDrv modw ZeroFile

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
  mdm_SetGUIActs $CurDrv
  mdm_ftov $CurDrv vvv
  mdm.send vvv
  
  puts [a.ext modw $mod 0 1 1 ])]
  mdm_calcGrad 3
  mdm_calcLap
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
##---------------------------------------------------------------------------

proc mdm_endloop { } \
{
  global mdm_closeloopFlag

  set mdm_closeloopFlag 0

  destroy .cl
}



#---------------------------------------------------------------------------
# proc mdm_ShowResp
# 
# Plot response from closed loop
#---------------------------------------------------------------------------

proc mdm_ShowResp {} {

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
  		-value "modes" -command mdm_doit
  radiobutton .sr.f.drv -variable dtype -text "drive signals" \
  		-value "drives" -command mdm_doit
  
  button      .sr.f.ok -text "  OK  " -font $wsdb(font) -command {mdm_destry}
  pack        .sr.f.msg .sr.f.srb .sr.f.mod .sr.f.drv .sr.f.ok -padx 5 -pady 5
}


proc mdm_doit {} \
{
	global rid rwd mds Drives dtype
	if { $dtype == "drives" } \
	{ 
		id.set.array rid Drives 
		wd.set.array rwd Drives
		mdm_plotit $Drives
	}
	if { $dtype == "modes"  } \
	{ 
		id.set.array rid mds 
		wd.set.array rwd mds
		mdm_plotit $mds
	}
}

proc mdm_plotit { data } \
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

proc mdm_destry {} \
{
	global rid rwd rpd
	set rid 0
	set rwd 0
	set rpd 0
	destroy .sr
}


#---------------------------------------------------------------------------
# proc mdm_Mdm_MakereconPanel
# 
# Reconstructor control panel
#---------------------------------------------------------------------------

proc mdm_Mdm_MakereconPanel {} { 

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
  
  button .mr.f.mrb.ctl.poke -text " Make Poke Recon " -command { mdm_MPR }
 
  pack   .mr.f.mrb.ctl.poke  -side left -padx 10
  
  frame .mr.f.mrb.ctm
  pack  .mr.f.mrb.ctm -pady 5
    
  button .mr.f.mrb.ctm.madk -text "Make Modal Recon" -command { mdm_MMR }

  pack   .mr.f.mrb.ctm.madk  -side left -padx 10

}




#---------------------------------------------------------------------------
# procs mdm_MPR mdm_MMR mdm_MRR mdm_RMR
#
# These procedures are boilerplate to create the different reconstructors.
#---------------------------------------------------------------------------

proc mdm_MPR {} {
  global loopType ModFlg wlCalibrate stagePos

  if { $wlCalibrate(doneInit) != "Yes" } {
    dialog "Please Calibrate WaveScope."
    return
  }
  stage.calibrate.absolute $stagePos(BestRefSpots)
  set ModFlg Poke
  mdm_quiet
  mdm_makerecon
  set loopType Mat
}

proc mdm_MMR {} {
  global loopType ModFlg wlCalibrate stagePos

  if { $wlCalibrate(doneInit) != "Yes" } {
    dialog "Please Calibrate WaveScope."
    return
  }
  stage.calibrate.absolute $stagePos(BestRefSpots)
  set ModFlg Mod
  mdm_quiet
  mdm_makerecon
  set loopType Mat
}

proc mdm_MRR { } {
  global NRP loopType ModFlg wlCalibrate stagePos

  if { $wlCalibrate(doneInit) != "Yes" } {
    dialog "Please Calibrate WaveScope."
    return
  }
  stage.calibrate.absolute $stagePos(BestRefSpots)
  set ModFlg Poke
  mdm_noisy $NRP
  mdm_makerecon
  set loopType Mat
}

proc mdm_RMR { } {
  global NRP loopType ModFlg wlCalibrate stagePos

  if { $wlCalibrate(doneInit) != "Yes" } {
    dialog "Please Calibrate WaveScope."
    return
  }
  stage.calibrate.absolute $stagePos(BestRefSpots)
  set ModFlg Mod
  mdm_noisy $NRP
  mdm_makerecon
  set loopType Mat
}


#---------------------------------------------------------------------------
# proc mdm_ftov
#
# Convert float values in range -1..1 to output values in the range 0..220,
# applying an influence function since actuator response is not linear.
#---------------------------------------------------------------------------

proc mdm_ftov { fracar voltar } {

  upvar $voltar vt

  global MAX_VOLT

  a.add   $fracar 1 = ftemp 
#a.add: add elements of input arrays to form output array
  a.lim    ftemp 2 =  ftemp 
#a.lim: replaces elements of array (ie ftemp) > limit (ie 2) with limit
  a.limlow ftemp 0 =  ftemp 
#a.limlow: as a.lim, but limit is a lower limit

  #Above three lines yield ftemp array running from 0-2
  #(from voltar array, which should range from -1 to 1)

  a.sqrt ftemp = ftemp 
#Calculate +ve square root of each element in array

  set midvolt [expr {0.7071 * $MAX_VOLT}] 
#added 24th Sept.

#  a.mul   ftemp 154 = ftemp 
#Original

  a.mul   ftemp $midvolt = ftemp 
#added 24th Sept.
  a.to    ftemp uc =  vt 
#Copies (float) ftemp to unsigned char vt
}


#---------------------------------------------------------------------------
# proc mdm_noisy
# 
# Pokes each actuator and records the gradients, uses uniform noise to
# introduce a random element.
#---------------------------------------------------------------------------

proc mdm_noisy { n } {

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
    mdm_ftov $fracDrv CurDrv
    if { $i == 0 } { a.copy fracDrv = Drvs } \
    else { a.catrow Drvs fracDrv = Drvs}
 
    mdm.send CurDrv
    update
    mdm_calcGrad 10
    vd.set.array gvd Grad
    if { $i == 0 } { a.copy Grad = Grds } \
    else { a.catrow Grds Grad = Grds }

    update
  } 
  a.make 0 $MAX_ACT = CurDrv


  # Uncomment these next two lines to save the
  # calculated drive signal and gradients to disk.
  #
  #a.save Drvs Drvs
  #a.save Grds Grds 

  set gvd 0  
}



#---------------------------------------------------------------------------
# proc mdm_quiet
# 
# Pokes each actuator and records the gradients (no noise)
#---------------------------------------------------------------------------

proc mdm_quiet { } {

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
  mdm_FlatMDM
  a.copy CurDrv = CurDrv0
  
  for { set i 0 } { $i < $MAX_ACT } { incr i } {
    if { [ a.extele maskArray $i ] == 1 } {
	    puts "Poking actuator: $i"
	    a.make 0 $MAX_ACT = CD
	    a.repele $pokeFraction CD $i = CD
	    a.add CD CurDrv0 = CurDrv
	    mdm_SetGUIActs $CurDrv
	    mdm_ftov $CurDrv uuu
	    mdm.send uuu
	    update
	    mdm_calcGrad 10
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
  #a.save Drvs Drvs
  #a.save Grds Grds 

  set gvd 0  
}



#---------------------------------------------------------------------------
# proc mdm_quietl
# 
# Pokes each actuator and records the laplacian curvature (no noise)
#---------------------------------------------------------------------------

proc mdm_quietl { } {

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

    mdm_ftov $CurDrv uuu
    mdm.send uuu
    update
    mdm_calcGrad 10
    mdm_calcLap
    id.set.array gvd Lap

    if { $i == 0 } { a.copy Lap = Grds } \
    else { a.catpln Grds Lap = Grds }

    update
  } 
  a.make 0 $MAX_ACT = CurDrv


  # Uncomment these next two lines to save the
  # calculated drive signal and gradients to disk.
  #
  #a.save Drvs Drvs
  #a.save Grds Laps 

  set gvd 0  
}


##---------------------------------------------------------------------------
##
## Calculates gradients by grabbing 'n' images and averaging over the images
##
##---------------------------------------------------------------------------

proc mdm_calcGrad { n } \
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
  update
}



##---------------------------------------------------------------------------
##
## Makes the reconstructor matrix from Drvs and Grds
##
##---------------------------------------------------------------------------

proc mdm_makerecon {} \
{
  global Drvs Grds Recon modw thresh
  global ModFlg 
  global thresh pthresh condth pokeFraction

# for debug
  global gmm mrat Wmask
	
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



  # After this, we should have a square autocorrelation array.
  #
  a.transpose ggg = gt
  a.matprod ggg gt = au


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


  a.inv W = Wi
  a.transpose Vt = V
 
  a.matprod V Wi = tmp
  a.matprod tmp Ut = Inv
 
  a.matprod Inv ggg = Recon
  a.matprod Vt Drvs = B
  set ncol [ a.rows Drvs ]
 
  if { $ModFlg == "Poke" } \
  {
    a.make 1 $ncol 1 = modw

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
    mdm_makegs $Grds hhh	
    a.matprod Vt hhh = Mg
    a.matprod Wi Mg = Recon
    a.copy B = Drvs
    a.sqrt W = w
    a.rebin w 1 $ncol = modw
    a.mul modw $ncol = modw
  }

  puts "Reconstructor complete.  Ready for closed loop operation."
}



##---------------------------------------------------------------------------
##
## Converts 1D V4 gradients array into 2D scalar array with Xs, then Ys
## 
##---------------------------------------------------------------------------

proc mdm_makeg { pgrad ggg } \
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
##---------------------------------------------------------------------------

proc mdm_makegs { pgrad ggg } {

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
## mdm_closeloop - Actual flattening routine
## 
##---------------------------------------------------------------------------

proc mdm_closeloop {} {

  global Grad Drive Drives CurDrv ivd Recon Drvs Drerr
  global modw mds integGain mdm_closeloopFlag wlCalibrate
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

  # As long as the 'mdm_closeloop' button on the panel is set,
  # keep trying to flatten the mirror.
  #
  while { $mdm_closeloopFlag == 1 } {
    # The calculations are basically standard adaptive optics fare.
    # Use the reconstructor to produce a set of voltages for the
    # mirror, tempering the aggressiveness of the correction by the
    # 'integGain' selected by the user.
    #
    mdm_calcGrad 3
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
    mdm_makeg $Grad ggg
    a.matprod Recon ggg = mod
 
    a.shape mod $ncol 1 = mod
    a.mul mod modw = mod
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
    a.lim CurDrv 1 = CurDrv
    a.limlow CurDrv -1 = CurDrv

    # Added another avg subtract to keep drives in line
    # after limiting
    a.sub CurDrv [a.avemask CurDrv maskArray] = CurDrv
    mdm_SetGUIActs $CurDrv
    mdm_ftov $CurDrv Drive

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
}

##---------------------------------------------------------------------------
##
## mdm_closeloopnodisplay - Actual flattening routine
## 
##---------------------------------------------------------------------------

proc mdm_closeloopnodisplay {} {

  global Grad Drive Drives CurDrv ivd Recon Drvs Drerr
  global modw mds integGain mdm_closeloopFlag wlCalibrate
  global MAX_ACT platform maskArray

  set ncol [ a.rows Drvs ]
  set i 0
  # As long as the 'mdm_closeloop' button on the panel is set,
  # keep trying to flatten the mirror.
  #
  while { $mdm_closeloopFlag == 1 } {
    # The calculations are basically standard adaptive optics fare.
    # Use the reconstructor to produce a set of voltages for the
    # mirror, tempering the aggressiveness of the correction by the
    # 'integGain' selected by the user.
    #
    mdm_calcGrad 3
    alg.conv.pg.arrays Grad wlCalibrate(Params) = gxgy mask
    alg.recon.fast gxgy mask = opd
    update
    mdm_makeg $Grad ggg
    a.matprod Recon ggg = mod
 
    a.shape mod $ncol 1 = mod
    a.mul mod modw = mod
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
    a.lim CurDrv 1 = CurDrv
    a.limlow CurDrv -1 = CurDrv

    # Added another avg subtract to keep drives in line
    # after limiting
    a.sub CurDrv [a.avemask CurDrv maskArray] = CurDrv
    mdm_SetGUIActs $CurDrv
    mdm_ftov $CurDrv Drive

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
## mdm_closelooppsf - Actual flattening routine
## 
##---------------------------------------------------------------------------

proc mdm_closelooppsf {} {

  global Grad Drive Drives CurDrv ivd Recon Drvs Drerr
  global modw mds integGain mdm_closeloopFlag wlCalibrate ws_result
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

  # As long as the 'mdm_closeloop' button on the panel is set,
  # keep trying to flatten the mirror.
  #
  while { $mdm_closeloopFlag == 1 } {
    # The calculations are basically standard adaptive optics fare.
    # Use the reconstructor to produce a set of voltages for the
    # mirror, tempering the aggressiveness of the correction by the
    # 'integGain' selected by the user.
    #
    mdm_calcGrad 3
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
    set SubapSize $micronsPerPix
    set PSFScale 10
    set Lambda 1.0
    
    if { $psf_ivd != 0 } {
#	alg.calc.psf opd mask $PSFSize $PSFSize $SubapSize $PSFScale $Lambda = psf
	id.set.array psf_ivd $ws_result(PSF) $wlCalibrate(psfScale)
    }

    update
    mdm_makeg $Grad ggg
    a.matprod Recon ggg = mod
 
    a.shape mod $ncol 1 = mod
    a.mul mod modw = mod
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
    a.lim CurDrv 1 = CurDrv
    a.limlow CurDrv -1 = CurDrv

    # Added another avg subtract to keep drives in line
    # after limiting
    a.sub CurDrv [a.avemask CurDrv maskArray] = CurDrv
    mdm_SetGUIActs $CurDrv
    mdm_ftov $CurDrv Drive

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

#---------------------------------------------------------------------------
# proc mdm_clloop
#
# This function is called from the GUI to kick off the regular closed loop.
#---------------------------------------------------------------------------

proc mdm_clloop {} {

  global mdm_closeloopFlag loopType


  if { $loopType == "NULL" } {
    dialog "Please Make a Reconstructor first."
    set mdm_closeloopFlag 0
    return
  }
  update

  if { [winfo exists .dtl] } { dtl:doExit }

  if { $mdm_closeloopFlag == 1 } { mdm_closeloop }
}
#---------------------------------------------------------------------------
# proc mdm_clloopnodisplay
#
# This function is called from the GUI to kick off the regular closed loop.
#---------------------------------------------------------------------------

proc mdm_clloopnodisplay {} {

  global mdm_closeloopFlag loopType


  if { $loopType == "NULL" } {
    dialog "Please Make a Reconstructor first."
    set mdm_closeloopFlag 0
    return
  }
  update

  if { [winfo exists .dtl] } { dtl:doExit }

  if { $mdm_closeloopFlag == 1 } { mdm_closeloopnodisplay }
}

#---------------------------------------------------------------------------
# proc mdm_cllooppsf
#
# This function is called from the GUI to kick off the regular closed loop.
#---------------------------------------------------------------------------

proc mdm_cllooppsf {} {

  global mdm_closeloopFlag loopType


  if { $loopType == "NULL" } {
    dialog "Please Make a Reconstructor first."
    set mdm_closeloopFlag 0
    return
  }
  update

  if { [winfo exists .dtl] } { dtl:doExit }

  if { $mdm_closeloopFlag == 1 } { mdm_closelooppsf }
}


#---------------------------------------------------------------------------
# proc mdm_SetGUIActs
#
# Convert float values in range -1..1 to GUI actuator values in the range
# -109..109, then place those values into the GUI actuator display.
#---------------------------------------------------------------------------

proc mdm_SetGUIActs { voltar } {

  global acts MAX_ACT


  a.mul voltar 109 = temp
  a.to temp c = actVals

  for {set i 1} {$i <= $MAX_ACT} {incr i} {
    scan [a.extele actVals [expr $i-1]] "%d" acts($i)
  }
}


#---------------------------------------------------------------------------
# proc mdm_PokeAct
# 
# Updates the value of a particular actuator, sends that actuator value
# to the DM.
#---------------------------------------------------------------------------

proc mdm_PokeAct { value } {

  global whichAct CurDrv acts volts


  set acts($whichAct) $value
  set wact [expr $whichAct - 1]
  set falue [expr $value / 109.]
  a.repele $falue CurDrv $wact = CurDrv
  mdm_ftov $CurDrv volts
  #set pvalue [expr $value + 109]
  #dm.poke $wact $pvalue
  mdm.send volts
}


#---------------------------------------------------------------------------
# proc mdm_SetAct
# 
# Sets variables when the user picks which actuator to poke
#---------------------------------------------------------------------------

proc mdm_SetAct {} {

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
# proc mdm_ZeroMDM
# 
# Sets all actuators to default zero voltages, then sends that frame to the DM
#--------------------------------------------------------------------------

proc mdm_ZeroMDM {} {

  global acts pokeVar CurDrv volts MAX_ACT


  for {set i 1} { $i <= $MAX_ACT } { incr i } {
    set acts($i) 0
  }
  a.make 0 $MAX_ACT = CurDrv
  a.repele 0 CurDrv 0 = CurDrv
  mdm_SetGUIActs $CurDrv
  mdm_ftov $CurDrv actv
  mdm.send actv
  set pokeVar 0
}

#--------------------------------------------------------------------------
# proc mdm_FlatMDM
# 
# Sets all actuators to zero, then sends that frame to the DM
#--------------------------------------------------------------------------

proc mdm_FlatMDM {} {

  global acts pokeVar CurDrv volts MAX_ACT ZeroFile

  a.load $ZeroFile = CurDrv
  mdm_SetGUIActs $CurDrv
  mdm_ftov $CurDrv actv
  mdm.send actv
  set pokeVar 0
}

#--------------------------------------------------------------------------
# proc mdm_RandomMDM
# 
# Sets all actuators to zero, then sends that frame to the DM
#--------------------------------------------------------------------------

proc mdm_RandomMDM {} {

  global acts pokeVar CurDrv volts MAX_ACT ZeroFile
  a.make -1 $MAX_ACT = CurDrv
  a.normalnoise CurDrv 1 = CurDrv
  a.lim CurDrv 0 = CurDrv
#  a.load $ZeroFile = CurDrv
  mdm_SetGUIActs $CurDrv
  mdm_ftov $CurDrv actv
  mdm.send actv
  set pokeVar 0
}

#--------------------------------------------------------------------------
# proc mdm_ZeroVoltMDM
# 
# Sets all actuators to zero, then sends that frame to the DM
#--------------------------------------------------------------------------

proc mdm_ZeroVoltMDM {} {

  global acts pokeVar CurDrv volts MAX_ACT ZeroFile

  a.make -1 $MAX_ACT = CurDrv
#  a.load $ZeroFile = CurDrv
  mdm_SetGUIActs $CurDrv
  mdm_ftov $CurDrv actv
  mdm.send actv
  set pokeVar 0
}


#--------------------------------------------------------------------------
# proc SaveDM
# 
# Prompt the user to save the current DM settings to a file.
#--------------------------------------------------------------------------

proc mdm_SaveMDM {} {

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
#--------------------------------------------------------------------------

proc mdm_LoadMDM {} {

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
      mdm_FlatMDM
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
  mdm_SetGUIActs $CurDrv
  mdm_ftov $CurDrv vvv
  mdm.send vvv
}

#--------------------------------------------------------------------------
# proc ResetZDM
# 
# Saves the current dm drives as the default zero positions
#--------------------------------------------------------------------------

proc mdm_ResetZMDM {} {

  global CurDrv ZeroFile
  set msg "This will overwrite the default DM Zero voltage file!"
  if { [wl_PanelsContinueAbort $msg] == "Abort"} { return }
  a.save  CurDrv $ZeroFile

}



#--------------------------------------------------------------------------
# proc mdm_MDM_GUI
# 
# Displays the Deformable Mirror control panel, which is a graphical
# representation of the mirror actuators, and controls to change the 
# values on each.
#--------------------------------------------------------------------------

proc mdm_MDM_GUI {} {

  global acts pokeVar whichAct platform wsdb


  if { [winfo exists .mdm] } {
    destroy .mdm
  }
  toplevel    .mdm
  wm title    .mdm "Membrane DM Controls"
#  wm geometry .mdm +5-35
  wm geometry .mdm +5+5
  frame       .mdm.f
  pack        .mdm.f

  frame       .mdm.f.labf
  pack        .mdm.f.labf -anchor w
  message     .mdm.f.labf.m1 -text "Actuator:" -width 3c
  message     .mdm.f.labf.m2 -textvariable whichAct -width 2c
  pack        .mdm.f.labf.m1 .mdm.f.labf.m2 -side left

  if {$platform == "windows"} {
    set ht 1
    set bd 1
  } else {
    set ht 0
    set bd 1
  }

#  for { set y 0 } { $y < 12 } { incr y } {
  for { set y 0 } { $y < 19 } { incr y } {
    frame .mdm.f.acts$y
    pack  .mdm.f.acts$y
#    for { set x 0 } { $x < 12 } { incr x } {
    for { set x 0 } { $x < 19 } { incr x } {
#      set bnum [expr $y * 12 + $x + 1]
      set bnum [expr $y * 19 + $x + 1]
      checkbutton .mdm.f.acts$y.$bnum -textvariable acts($bnum) -width 3 \
          -height $ht -bd $bd -variable selected($bnum) -command mdm_SetAct
      pack        .mdm.f.acts$y.$bnum -side left
    }
  }
#  .mdm.f.acts0.1 configure -state disabled
#  .mdm.f.acts0.12 configure -state disabled
#  .mdm.f.acts11.133 configure -state disabled
#  .mdm.f.acts11.144 configure -state disabled

#To do: disable masked actuators

  frame .mdm.f.poke
  scale .mdm.f.poke.scale -from -109 -to 109 -length 350 \
          -orient horizontal -variable pokeVar -command mdm_PokeAct
  pack  .mdm.f.poke.scale

  frame  .mdm.f.buts
  frame	 .mdm.f.stub

#Addition:
  button .mdm.f.buts.flat -text "Zero Volt MDM" -command mdm_ZeroVoltMDM
  button .mdm.f.buts.flat -text "Random Volts (0-50% deflection)" -command mdm_RandomMDM

  button .mdm.f.buts.flat -text "Zero MDM" -command mdm_FlatMDM
  button .mdm.f.stub.save -text "Save Settings..." -command mdm_SaveMDM
  button .mdm.f.stub.load -text "Load Settings..." -command mdm_LoadMDM
  button .mdm.f.stub.zerl -text "Reset Zeros File ..." -command mdm_ResetZMDM
  button .mdm.f.buts.ok -text "  OK  " -command {destroy .mdm} -font $wsdb(font)
  pack   .mdm.f.stub.load .mdm.f.stub.save .mdm.f.stub.zerl -side left -padx 5
  pack   .mdm.f.buts.flat .mdm.f.buts.ok -side left -padx 5
  pack   .mdm.f.poke .mdm.f.buts .mdm.f.stub -padx 5 -pady 5

  update
}

##
#
#To Do:
#
# 1) Disable masked actuators (mdm_MDM_GUI)
#
##