
#------------------------------------------------------------------------
# tdm_MakeWavefrontProcedures.tcl                      tcl script
#
# Procedures used in control of transparent electrode membrane mirror
# to generate used specified wavefronts with Wavescope wavefront sensor system.
#
# Procedures in this file:
#               makeWavefront
#               displaySineWavefrontPanel
#               destroySSWPanel
#               (also Zernike and Bessel wavefront procedures)
#               generateUserDefWavefront
#               commandDMToUserDefWavefront
#               iterateOneWavefrontCorrection
#               displayWavefront
#               generateSineYWavefront
#
# Note:  to initialize procedures in this file with the wavescope
# software, add lines such as the following to the tclIndex.tcl file
# in usr/aos/wavescope/scripts/
#        e.g. set auto_index(makeWavefront) \
#               [list source [file join tdm_MakeWavefrontProcedures.tcl]]
#
# Note:  This version copied from _v7.  Changes in _v8 and _v9 may have
# been lost.  plk 9/27/2005
#
# version 11
# plk 09/27/2005
#------------------------------------------------------------------------

# parameters for user defined wavefront

# Sine wavefront
global gYAmplitude_int_um
global gYFrequency_int_recip_mm
global gYPhase_int_deg

# Zernike wavefront
global gZWfModeNumber
global gZWfAmplitude
global gZWfConstOffset_units

# Bessel fn. wavefront
global gMembraneRadiusFactor_unit
global gEigenModeJIndex_int



# parameter for closed loop iteration
global gIterationStepSizeParameter


# user defined wavefront, gradient data
global gUserDefWavefrontOPD_float_um
global gUserDefWavefrontGrad_v4_rad

# flag used in GUI
global gCommandDMToUserDefFlag

# window IDs for wavescope image/data
global USERDEF_OPD_WID
global USERDEF_OPD_WD


#---------------------------------------------------------------------------
# makeWavefront
#
# Initiates the wavefront generation GUI.
#
# called by:  command line
#
# plk 12/31/2004
#---------------------------------------------------------------------------
proc makeWavefront {} \
{

   displaySineWavefrontPanel
   displayZernikeWavefrontPanel
   displayBesselWavefrontPanel
}



#---------------------------------------------------------------------------
# displaySineWavefrontPanel
#
# Creates a GUI window that allows the user to select parameters for a
# sinusoidal wavefront.  GUI has controls for commanding the DM to this
# desired wavefront, taking an actual wavefront measurement and displaying
# the desired wavefront.
#
# uses procedures (event handlers):
#   commandDM_OpenLoop
#   displayActualWavefront
#   generateUserDefWavefront
#
# Called by: makeWavefront
#
# plk 12/31/2004
#---------------------------------------------------------------------------
proc displaySineWavefrontPanel { } \
{
    global gYAmplitude_int_um
    global gYFrequency_int_recip_mm
    global gYPhase_int_deg
    global gWavefrontBinLevel_int
    global gIterationStepSizeParameter

    if { [winfo exists .sSWPanel] } {
	destroy .sSWPanel
    }
    toplevel .sSWPanel
    wm title .sSWPanel "Sinusoidal Wavefront Panel"
    wm geometry .sSWPanel -30+90
    frame  .sSWPanel.f
    pack   .sSWPanel.f
    frame  .sSWPanel.f.clb -relief groove -bd 2
    button .sSWPanel.f.ok -text "  OK  " \
                          -font "helvetica" \
                          -command {destroySSWPanel}
    pack   .sSWPanel.f.clb .sSWPanel.f.ok -padx 5 -pady 5

    set theSubTitle "Wavefront phi(x,y) = A sin( ky y  +  phi_0 )"
    message .sSWPanel.f.clb.msg -text $theSubTitle \
                                -aspect 1000 \
                                -font "helvetica"
    pack    .sSWPanel.f.clb.msg -padx 5 -pady 5



    frame .sSWPanel.f.clb.tt -relief groove -bd 2
    pack  .sSWPanel.f.clb.tt -pady 5
    frame .sSWPanel.f.clb.tt.ctl1
    pack  .sSWPanel.f.clb.tt.ctl1 -padx 26
    scale .sSWPanel.f.clb.tt.ctl1.scaleYAmplitude -from 0 \
                                  -to 100 \
                                  -length 200 \
                                  -orient horizontal \
                                  -label "Amplitude, A, units?" \
                                  -variable gYAmplitude_int_um

    scale .sSWPanel.f.clb.tt.ctl1.scaleYFrequency -from 0 \
                                                  -to 500 \
                                                  -length 200 \
                                                  -orient horizontal\
                        -label "Spatial Frequency, ky, units?" \
                        -variable gYFrequency_int_recip_mm

    scale .sSWPanel.f.clb.tt.ctl1.scaleYPhase -from 0 \
                                              -to 360 \
                                              -length 200 \
                                              -orient horizontal\
                                              -label "Phase Offset, p_0, deg" \
                                              -variable gYPhase_int_deg

    pack  .sSWPanel.f.clb.tt.ctl1.scaleYAmplitude -side top -padx 10
    pack  .sSWPanel.f.clb.tt.ctl1.scaleYFrequency -side top -padx 10
    pack  .sSWPanel.f.clb.tt.ctl1.scaleYPhase -side top -padx 10


    frame .sSWPanel.f.clb.ctl
    pack  .sSWPanel.f.clb.ctl -anchor w -pady 5


    button .sSWPanel.f.clb.ctl.sdes -text "Generate Wavefront" \
                                    -command { generateUserDefSineYWavefront }

    button .sSWPanel.f.clb.ctl.cmd  -text "Command DM..." \
                                    -command { commandDMToUserDefWavefront }
    button .sSWPanel.f.clb.ctl.sact -text "Show Actual..." \
                                    -command { displayActualWavefront }
    pack   .sSWPanel.f.clb.ctl.sdes \
           .sSWPanel.f.clb.ctl.cmd \
           .sSWPanel.f.clb.ctl.sact \
           -side left \
           -padx 5


    frame .sSWPanel.f.clb.cll
    pack  .sSWPanel.f.clb.cll -anchor center -pady 5



    scale .sSWPanel.f.clb.cll.scaleIterationStepSizeParameter \
             -from 0 \
             -to 0.2 \
             -length 200 \
             -orient horizontal \
             -resolution 0.001 \
             -label "Iteration Step Size Parameter" \
             -variable gIterationStepSizeParameter


    checkbutton .sSWPanel.f.clb.cll.colb \
           -text "Close Loop: Iterate to User Defined Wavefront" \
           -variable gCommandDMToUserDefFlag \
           -command { commandDMToUserDefWavefront }

    pack .sSWPanel.f.clb.cll.colb \
         .sSWPanel.f.clb.cll.scaleIterationStepSizeParameter


    #frame .sSWPanel.f.clb.clp
    #pack  .sSWPanel.f.clb.clp -anchor center -pady 5


    update


}


#---------------------------------------------------------------------------
# displayZernikeWavefrontPanel
#
# Creates a GUI window that allows the user to select parameters for a
# parabolic wavefront.  GUI has controls for commanding the DM to this
# desired wavefront, taking an actual wavefront measurement and displaying
# the desired wavefront.
#
# uses procedures (event handlers):
#       generateUserDefWavefront
#       commandDMtoUserDefWavefront
#
# Called by: makeWavefront
#
# plk 01/12/2005
#---------------------------------------------------------------------------
proc displayZernikeWavefrontPanel { } \
{
    global gZWfModeNumber
    global gZWfAmplitude
    global gZWfConstOffset_units
    global gIterationStepSizeParameter

    if { [winfo exists .zWfPanel] } {
	destroy .zWfPanel
    }
    toplevel .zWfPanel
    wm title .zWfPanel "Zernike Wavefront Panel"
    wm geometry .zWfPanel -30+90
    frame  .zWfPanel.f
    pack   .zWfPanel.f
    frame  .zWfPanel.f.clb -relief groove -bd 2
    button .zWfPanel.f.ok -text "  OK  " \
                          -font "helvetica" \
                          -command {destroyZWfPanel}
    pack   .zWfPanel.f.clb .zWfPanel.f.ok -padx 5 -pady 5

    set theSubTitle "Wavefront: phi(r,t)=A Z_n(r,t) + Q"
    message .zWfPanel.f.clb.msg -text $theSubTitle \
                                -aspect 1000 \
                                -font "helvetica"
    pack    .zWfPanel.f.clb.msg -padx 5 -pady 5



    frame .zWfPanel.f.clb.tt -relief groove -bd 2
    pack  .zWfPanel.f.clb.tt -pady 5
    frame .zWfPanel.f.clb.tt.ctl1
    pack  .zWfPanel.f.clb.tt.ctl1 -padx 26

    scale .zWfPanel.f.clb.tt.ctl1.scaleZWfModeNumber -from 0 \
                                  -to 35 \
                                  -length 200 \
                                  -orient horizontal \
                                  -label "Zernike Mode Number, n" \
                                  -variable gZWfModeNumber



    scale .zWfPanel.f.clb.tt.ctl1.scaleZWfAmplitude -from 0 \
                                  -to 50 \
                                  -length 200 \
                                  -orient horizontal \
                                  -label "Amplitude, A, unit?" \
                                  -variable gZWfAmplitude


    scale .zWfPanel.f.clb.tt.ctl1.scaleZWfConstOffset -from 0 \
                                   -to 300 \
                                   -length 200 \
                                   -orient horizontal\
                                   -label "Constant Offset, units?" \
                                   -variable gZWfConstOffset_units


    pack  .zWfPanel.f.clb.tt.ctl1.scaleZWfModeNumber -side top -padx 10
    pack  .zWfPanel.f.clb.tt.ctl1.scaleZWfAmplitude -side top -padx 10
    pack  .zWfPanel.f.clb.tt.ctl1.scaleZWfConstOffset -side top -padx 10


    frame .zWfPanel.f.clb.ctl
    pack  .zWfPanel.f.clb.ctl -anchor w -pady 5


    button .zWfPanel.f.clb.ctl.sdes -text "Generate Wavefront" \
                                    -command { generateUserDefZernikeWavefront }

    button .zWfPanel.f.clb.ctl.cmd  -text "Command DM..." \
                                    -command { commandDMToUserDefWavefront }
    button .zWfPanel.f.clb.ctl.sact -text "Show Actual..." \
                                    -command { displayActualWavefront }
    pack   .zWfPanel.f.clb.ctl.sdes \
           .zWfPanel.f.clb.ctl.cmd \
           .zWfPanel.f.clb.ctl.sact \
           -side left \
           -padx 5


    frame .zWfPanel.f.clb.cll
    pack  .zWfPanel.f.clb.cll -anchor center -pady 5



    scale .zWfPanel.f.clb.cll.scaleIterationStepSizeParameter \
             -from 0 \
             -to 0.2 \
             -length 200 \
             -orient horizontal \
             -resolution 0.001 \
             -label "Iteration Step Size Parameter" \
             -variable gIterationStepSizeParameter


    checkbutton .zWfPanel.f.clb.cll.colb \
           -text "Close Loop: Iterate to User Defined Wavefront" \
           -variable gCommandDMToUserDefFlag \
           -command { commandDMToUserDefWavefront }

    pack .zWfPanel.f.clb.cll.colb \
         .zWfPanel.f.clb.cll.scaleIterationStepSizeParameter


    update


}


#---------------------------------------------------------------------------
# displayBesselWavefrontPanel
#
# Creates a GUI window that allows the user to select parameters for a
# Bessel function wavefront.  GUI has controls for commanding the DM to this
# desired wavefront, taking an actual wavefront measurement and displaying
# the desired wavefront.
#
# W(x,y) =  N * J_v(x_vn * r/a) * e^i*v*phi
#
# N = 2/(a*sqrt(pi)*|J_v+1(x_vn)|)
#
# j index:  j= 9 v + n - 1  convention used to renumber the eigenfunctions.
#
#
# uses procedures (event handlers):
#   commandDM_OpenLoop
#   displayActualWavefront
#   generateUserDefWavefront
#
# Called by: makeWavefront
#
# plk 09/19/2005
#---------------------------------------------------------------------------
proc displayBesselWavefrontPanel { } \
{
    global gMembraneRadiusFactor_unit
    global gEigenModeJIndex_int
    global gWavefrontBinLevel_int
    global gIterationStepSizeParameter

    if { [winfo exists .bSWPanel] } {
	destroy .bSWPanel
    }
    toplevel .bSWPanel
    wm title .bSWPanel "Bessel Wavefront Panel"
    wm geometry .bSWPanel -30+90
    frame  .bSWPanel.f
    pack   .bSWPanel.f
    frame  .bSWPanel.f.clb -relief groove -bd 2
    button .bSWPanel.f.ok -text "  OK  " \
                          -font "helvetica" \
                          -command {destroybSWPanel}
    pack   .bSWPanel.f.clb .bSWPanel.f.ok -padx 5 -pady 5

    set theSubTitle "W(x,y) =  N * J_v(x_vn * r/a) * e^i*v*phi"
    message .bSWPanel.f.clb.msg -text $theSubTitle \
                                -aspect 1000 \
                                -font "helvetica"
    #set theSubSubTitle " N = 2/(a*sqrt(pi)*|J_v+1(x_vn)|)"
    #message .bSWPanel.f.clb.msg -text $theSubSubTitle \
    #                            -aspect 1000 \
    #                            -font "helvetica"

    pack    .bSWPanel.f.clb.msg -padx 5 -pady 5



    frame .bSWPanel.f.clb.tt -relief groove -bd 2
    pack  .bSWPanel.f.clb.tt -pady 5
    frame .bSWPanel.f.clb.tt.ctl1
    pack  .bSWPanel.f.clb.tt.ctl1 -padx 26
    scale .bSWPanel.f.clb.tt.ctl1.scaleMembraneRadiusFactor -from 0 \
                                  -to 100 \
                                  -length 200 \
                                  -orient horizontal \
                                  -label "Membrane Radius Factor (unit?)" \
                                  -variable gMembraneRadiusFactor_unit

    scale .bSWPanel.f.clb.tt.ctl1.scaleEigenModeJIndex -from 0 \
                                                  -to 9 \
                                                  -length 200 \
                                                  -orient horizontal\
                        -label "EigenModeJIndex, j = 9*v + n - 1" \
                        -variable gEigenModeJIndex_int


    pack  .bSWPanel.f.clb.tt.ctl1.scaleMembraneRadiusFactor -side top -padx 10
    pack  .bSWPanel.f.clb.tt.ctl1.scaleEigenModeJIndex -side top -padx 10


    frame .bSWPanel.f.clb.ctl
    pack  .bSWPanel.f.clb.ctl -anchor w -pady 5


    button .bSWPanel.f.clb.ctl.sdes -text "Generate Wavefront" \
                                    -command { generateUserDefBesselWavefront }

    button .bSWPanel.f.clb.ctl.cmd  -text "Command DM..." \
                                    -command { commandDMToUserDefWavefront }
    button .bSWPanel.f.clb.ctl.sact -text "Show Actual..." \
                                    -command { displayActualWavefront }
    pack   .bSWPanel.f.clb.ctl.sdes \
           .bSWPanel.f.clb.ctl.cmd \
           .bSWPanel.f.clb.ctl.sact \
           -side left \
           -padx 5


    frame .bSWPanel.f.clb.cll
    pack  .bSWPanel.f.clb.cll -anchor center -pady 5



    scale .bSWPanel.f.clb.cll.scaleIterationStepSizeParameter \
             -from 0 \
             -to 0.2 \
             -length 200 \
             -orient horizontal \
             -resolution 0.001 \
             -label "Iteration Step Size Parameter" \
             -variable gIterationStepSizeParameter


    checkbutton .bSWPanel.f.clb.cll.colb \
           -text "Close Loop: Iterate to User Defined Wavefront" \
           -variable gCommandDMToUserDefFlag \
           -command { commandDMToUserDefWavefront }

    pack .bSWPanel.f.clb.cll.colb \
         .bSWPanel.f.clb.cll.scaleIterationStepSizeParameter


    #frame .bSWPanel.f.clb.clp
    #pack  .bSWPanel.f.clb.clp -anchor center -pady 5


    update


}




#---------------------------------------------------------------------------
# destroySSWPanel
#
# Destroys the SineWavefrontPanel, optionally prints the values of
# the global variables set by the user to stdout.
#
#
# Called by: displaySineWavefrontPanel
#
# plk 12/31/2004
#---------------------------------------------------------------------------
proc destroySSWPanel { } \
{
   global gYAmplitude_int_um
   global gYFrequency_int_recip_mm
   global gYPhase_int_deg
   global gIterationStepSizeParameter

   destroy .sSWPanel

   #DEBUG
   puts stdout "destroySSWPanel:  The wavefront:"
   puts stdout "Amplitude, um:  $gYAmplitude_int_um"
   puts stdout "Frequency, mm:  $gYFrequency_int_recip_mm"
   puts stdout "Phase,    deg:  $gYPhase_int_deg"
   puts stdout "Iter. param. :  $gIterationStepSizeParameter"

   set USERDEF_OPD_WID 0
}


#---------------------------------------------------------------------------
# destroyZWfPanel
#
# Destroys the SphereWavefrontPanel, optionally prints the values of
# the global variables set by the user to stdout.
#
#
# Called by: displayZernikeWavefrontPanel
#
# plk 12/31/2004
#---------------------------------------------------------------------------
proc destroyZWfPanel { } \
{
   global gZWfModeNumber
   global gZWfAmplitude
   global gZWfConstOffset_units
   global gIterationStepSizeParameter
   

   destroy .zWfPanel

   #DEBUG
   puts stdout "destroyZWfPanel:  The Zernike wavefront:"
   puts stdout "Mode Number, n             :  $gZWfModeNumber"
   puts stdout "Amplitude, A units?        :  $gZWfAmplitude"
   puts stdout "Constant Offset, Q, units? :  $gZWfConstOffset_units"
   puts stdout "Iter. param.               :  $gIterationStepSizeParameter"

}


#---------------------------------------------------------------------------
# destroybSWPanel
#
# Destroys the SineWavefrontPanel, optionally prints the values of
# the global variables set by the user to stdout.
#
#
# Called by: displayBesselWavefrontPanel
#
# plk 12/31/2004
#---------------------------------------------------------------------------
proc destroybSWPanel { } \
{

   global gMembraneRadiusFactor_unit
   global gEigenModeJIndex_int

   global gIterationStepSizeParameter

   destroy .bSWPanel

   #DEBUG
   puts stdout "destroybSWPanel:  The wavefront:"
   puts stdout "gMembraneRadiusFactor_unit:  $gMembraneRadiusFactor_unit"
   puts stdout "gEigenModeJIndex_int:  $gEigenModeJIndex_int"
   puts stdout "Iter. param. :  $gIterationStepSizeParameter"

   set USERDEF_OPD_WID 0
}



#---------------------------------------------------------------------------
# generateUserDefZernikeWavefront
#
# Event handler called when user wants to generate the desired wavefront.
# The wavefront data is stored in the global variable:
# gUserDefWavefrontOPD_float_um
#
# Called by: displaySineWavefrontPanel, displayZernikeWavefrontPanel
#
# plk 01/02/2005
#---------------------------------------------------------------------------
proc generateUserDefZernikeWavefront { } \
{

     generateZernikeWavefront
     displayWavefront
}


#---------------------------------------------------------------------------
# generateUserDefSineYWavefront
#
# Event handler called when user wants to generate the desired wavefront.
# The wavefront data is stored in the global variable:
# gUserDefWavefrontOPD_float_um
#
# Called by: displaySineWavefrontPanel
#
# plk 01/14/2005
#---------------------------------------------------------------------------
proc generateUserDefSineYWavefront { } \
{

     generateSineYWavefront
     displayWavefront
}



#---------------------------------------------------------------------------
# generateUserDefBesselWavefront
#
# Event handler called when user wants to generate the desired wavefront.
# The wavefront data is stored in the global variable:
# gUserDefWavefrontOPD_float_um
#
# Called by: displayBesselWavefrontPanel
#
# plk 09/19/2005
#---------------------------------------------------------------------------
proc generateUserDefBesselWavefront { } \
{

     generateBesselWavefront
     displayWavefront
}


#---------------------------------------------------------------------------
# commandDMToUserDefWavefront
#
# Event handler called when user wants to command the DM to the
# create the desired wavefront in the optical system.
#
# The gradient of the wavefront is stored in the global variable:
# gUserDefWavefrontGrad_v4_rad
#
# Called by: displaySineWavefrontPanel, displayZernikeWavefrontPanel
#
# plk 01/03/2005
#---------------------------------------------------------------------------
proc commandDMToUserDefWavefront { } \
{
    global gCommandDMToUserDefFlag

    global opd_ivd
    global platform
    global Drvs
    

    # Put up an image of the wavefront so the user can watch the
    # the loop perform its magic.
    #
    id.new opd_ivd
    id.set.title opd_ivd "Current Wavefront Shape"
    id.set.xy opd_ivd 5 360
    id.set.wh opd_ivd 300 300
    if {$platform != "windows"} {
	id.set.minmax opd_ivd -1 1
    }

    # As long as the 'closeLoop' button on the panel is set,
    # keep trying to generate the desired wavefront.
    #

    set i 0
    while { $gCommandDMToUserDefFlag == 1 } {

        # get current wavefront data (avg 3 frames).
        # data stored in global array "Grad"
	calcGrad 3

        # compute the CurDrv array values for one
        # iteration of the wavefront correction.
        iterateOneWavefrontCorrection i


        computeDriveVoltagesAndSendToDACs i


	puts "Closed loop iteration: $i"
	incr i
	update
    }
    set opd_ivd 0


}


#---------------------------------------------------------------------------
# IterateOneWavefrontCorrection
#
# Computes one iteration of the wavefront correction algorithm.
#
# The gradient of the wavefront is stored in the global variable:
# gUserDefWavefrontGrad_v4_rad
#
# argument:  i   the integer iteration number.
#
# Called by: commandDMToUserDefWavefront
#
# plk 02/17/2005
#---------------------------------------------------------------------------
proc iterateOneWavefrontCorrection { i } \
{

        global gUserDefWavefrontGrad_v4_rad
        global gIterationStepSizeParameter
        global gActuatorWeight
        global opd_ivd

        global Grad Drive Drives CurDrv ivd Recon Drvs Drerr
        global modew mds integGain wlCalibrate
        global MAX_ACT platform maskArray


        set ncol [ a.rows Drvs ]


        alg.conv.pg.arrays Grad wlCalibrate(Params) = gxgy mask
	alg.recon.fast gxgy mask = opd
	if { $opd_ivd != 0 } {
	    set rms [a.rmsmask opd mask]
	    id.set.array opd_ivd opd $rms
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
	update


        #DEBUG

        puts stdout "iterateOneWavefrontCorrection: Grad info"
        puts stdout "\t [a.info Grad] "
        a.min Grad = theMin
        a.max Grad = theMax
        puts stdout \
        "     Grad: min= [a.dump theMin] max= [a.dump theMax]"

        puts stdout "iterateOneWavefrontCorrection: gUserDefWavefrontGrad_v4_rad info"
        puts stdout "\t [a.info gUserDefWavefrontGrad_v4_rad] "
        a.min gUserDefWavefrontGrad_v4_rad = theMin
        a.max gUserDefWavefrontGrad_v4_rad = theMax
        puts stdout \
        "     gUserDefWavefrontGrad_v4_rad: min= [a.dump theMin] max= [a.dump theMax]"



        # dialog "DEBUG Pause Here"





        # Difference between the actual (measured) wavefront
        # and the desired wavefront forms the basis for the
        # correction signal for the current iteration.
        a.sub Grad gUserDefWavefrontGrad_v4_rad = theDiffGrad_rad

	makeg $theDiffGrad_rad ggg
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
	# (section removed since it was disabled in closeloop{}
        # plk 1/3/2005

	a.add CurDrv Drerr = CurDrv

        # peform actuator based weighting.  Each actuator has a weight
        # value (0...1) associated with it.  This value scales the drive
        # signal.  See setActuatorWeights{} for more details.
        # a.mul CurDrv gActuatorWeight = CurDrv



	# Limit the drive signals to the allowed range
	#Upper limiting now done in dm.send function
	a.limlow CurDrv -1 = CurDrv


	#Addition for setting drive voltage to immobile actuators to -1 (ie 0V)
	for { set index 0 } { $index < $MAX_ACT } { incr index } {
	    if { [ a.extele maskArray $index ] == 0 } {
		a.repele -1 CurDrv $index = CurDrv
	    }
	}
	#hdyson, 9th Oct


	SetGUIActs $CurDrv

}



#---------------------------------------------------------------------------
# computeDriveVoltagesAndSendToDACs
#
# Computes drive voltages from notional drive signal values and sends
# the appropriate voltage values to the DACs to power the DM to the
# desired, new position.
#
# The gradient of the wavefront is stored in the global variable:
# gUserDefWavefrontGrad_v4_rad
#
# argument:  i   the integer iteration number.
#
# Called by: commandDMToUserDefWavefront
#
# plk 02/17/2005
#---------------------------------------------------------------------------
proc computeDriveVoltagesAndSendToDACs { i } \
{
        global gIterationStepSizeParameter

        global Drive Drives CurDrv



        # convert notional drive signals to actual
        # voltages for sending to the electronics.
	ftov $CurDrv Drive

	if { $i == 0 } {
	    a.copy Drive = Drives
	} else {
	    a.catrow Drives Drive = Drives
	}


        # Multiply the drive voltage correction by an
        # adjustable parameter between 0...1 to reduce
        # the iteration step size.  (mitigate instability).
        a.mul Drive $gIterationStepSizeParameter = Drive


        # DEBUG:  Drive voltage statistics
        a.min Drive = theMin
        a.max Drive = theMax
        puts stdout "commandDMToUserDefWavefront:"
        puts stdout \
              "     Drive: min= [a.dump theMin] max= [a.dump theMax]"

        # BEWARE!
        # This command sends voltages to the hardware.
        dm.send Drive

}




#---------------------------------------------------------------------------
# displayWavefront
#
# display the specified wavefront on the monitor.
#
#
# Called by: generateUserDefWavefront
#
# plk 01/02/2005
#---------------------------------------------------------------------------
proc displayWavefront { } \
{
   global USERDEF_OPD_WD
   global gUserDefWavefrontOPD_float_um
   global wsMLMParams

   # DEBUG
   # display the created wavefront as an image
   # id.new USERDEF_OPD_WID
   # id.set.xy USERDEF_OPD_WID 5 360
   # id.set.wh USERDEF_OPD_WID 300 300
   # id.set.array USERDEF_OPD_WID gUserDefWavefrontOPD_float_um
   # id.set.title USERDEF_OPD_WID "User Defined Wavefront Shape"

   # Debug
   # display the created wavefront as a wireframe display
   wd.new USERDEF_OPD_WD
   wd.set.array USERDEF_OPD_WD gUserDefWavefrontOPD_float_um
   wd.set.xy USERDEF_OPD_WD 5 360
   wd.set.wh USERDEF_OPD_WD 300 300
   wd.set.title USERDEF_OPD_WD "User Defined Wavefront Shape"
   wd.set.axes USERDEF_OPD_WD OPD $wsMLMParams(spacing)
   
   #dialog "DEBUG Pause Here"

}





#---------------------------------------------------------------------------
# generateZernikeWavefront
#
# generates a wavefront based on a user specified Zernike polynomial
#
#
# This procedure uses Wavescope atomic functions to generate and manipulate
# arrays as well as reconstruct the wavefront from computed gradients.
#
# Procedure also makes use of current wavescope calibration data.  Wavescope
# must be calibrated before implementing this procedure!
#
#
# Called by: GenerateUserDefWavefront
#
# plk 01/11/2005

#---------------------------------------------------------------------------
proc generateZernikeWavefront { } \
{
   global gZWfModeNumber
   global gZWfAmplitude
   global gZWfConstOffset_units

   global gWavefrontBinLevel_int
   global gUserDefWavefrontOPD_float_um
   global gUserDefWavefrontGrad_v4_rad

   global Grad gvd CurDrv Drvs Grds MAX_ACT maskArray pokeFraction
   global wlCalibrate YACT_LINE_LENGTH XACT_LINE_LENGTH


   # compute wavefront gradients.  Store them in an array that
   # is compatible for joining with WFS spot position array

   # Find the number of rows, columns in the spot image data.
   #
   # This number is the same as the number of sampled wavefront points.
   # wlCalibrate(FinalCenters) is a row vector (1 row, N cols)
   # of <Vector 2> data.  Each element is an x,y pair of spot
   # center positions in the WFS spot image plane(?) The
   # number of columns is the total number of spot center positions(?)
   # Assuming a square array of spot images, then the number of
   # rows, cols in the spot image is sqrt(N).


   a.ave wlCalibrate(FinalCenters) = theSamplePositions_avg_V2
   a.v2toxy theSamplePositions_avg_V2 = theCenterColumn_V0 theCenterRow_V0
   set theCenterRow [a.dump theCenterRow_V0]
   set theCenterColumn [a.dump theCenterColumn_V0]

   # Use the value of pupil radius that will center the wavefront
   # over the sampled area of the spot image plane.
   set thePupilRadius_pix [expr $theCenterRow - 0.2*$theCenterRow]

   # Constant Z offset to add to the generated wavefront; use to
   # correct for the fact that Zernike's have maximum excursions
   # at the pupil radius (whereas membranes are constrained at the
   # edge)
   set theConstOffset $gZWfConstOffset_units


   #DEBUG values
   #set theCenterColumn 350
   #set theCenterRow 230
   #set thePupilRadius_pix 200


   # generate the gradient of the User selected Zernike
   # polynomial,imposed on the spot image plane.
   zern.make.grad wlCalibrate(FinalCenters) \
                  $gZWfModeNumber \
                  $theCenterColumn \
                  $theCenterRow \
                  $thePupilRadius_pix \
                  = gUserDefWavefrontGrad_v4_rad


   #DEBUG
   #puts stdout "generateZernikeWavefront: gUserDefWavefrontGrad_v4_rad info"
   #puts stdout "\t [a.info gUserDefWavefrontGrad_v4_rad] "
   #puts stdout "\t Averages        :  [a.ave gUserDefWavefrontGrad_v4_rad] "
   #puts stdout "\t Mode Number     : $gZWfModeNumber"
   #puts stdout "\t Center column   : $theCenterColumn"
   #puts stdout "\t Center row      : $theCenterRow"
   #puts stdout "\t Pupil radius    : $thePupilRadius_pix"

   # create an appropriately sized weight mask; it is not needed for
   # generation of the wavefront, therefore reset its values to be
   # all equal to one.
   alg.conv.pg.arrays $gUserDefWavefrontGrad_v4_rad \
                $wlCalibrate(Params) = theGradWavefront_v2_rad theWeightMask
   a.mul theWeightMask 0 = theWeightMask
   a.add theWeightMask 1 = theWeightMask

   # finally, reconstruct the wavefront from the gradients, weight mask
   alg.recon.slow theGradWavefront_v2_rad theWeightMask = theWavefrontOPD_float

   # scale the OPD
   a.mul theWavefrontOPD_float \
         $wlCalibrate(micronsPerPix) = gUserDefWavefrontOPD_float_um


   # set theWavefront $gUserDefWavefrontOPD_float_um
   


   #dialog "DEBUG Pause Here"


}




#---------------------------------------------------------------------------
# generateSineYWavefront
#
# generates a wavefront based on user parameters of the form:
#
#      phi(x,y) = a sin ( ky + phi0)
#
#    a = gYAmplitude_int_um
#    k = gYFrequency_int_recip_mm
# phi0 = gYPhase_int_deg
#
# This procedure uses Wavescope atomic functions to generate and manipulate
# arrays as well as reconstruct the wavefront from computed gradients.
#
# Procedure also makes use of current wavescope calibration data.  Wavescope
# must be calibrated before implementing this procedure!
#
#
# Called by: generateUserDefWavefront
#
# plk 01/02/2005
#---------------------------------------------------------------------------
proc generateSineYWavefront { } \
{
   global gYAmplitude_int_um
   global gYFrequency_int_recip_mm
   global gYPhase_int_deg
   global gWavefrontBinLevel_int
   global gUserDefWavefrontOPD_float_um
   global gUserDefWavefrontGrad_v4_rad

   global Grad gvd CurDrv Drvs Grds MAX_ACT maskArray pokeFraction
   global wlCalibrate YACT_LINE_LENGTH XACT_LINE_LENGTH

   # attempt to implement procedure with an output
   # parameter, accessed using the upvar command.
   # Not clear if this is working.  plk 1/3/2005
   # upvar $outWavefrontVector theWavefront

   # X,Y coordinates of the spot centers,
   # obtained from wavescope calibration data.
   a.v2toxy wlCalibrate(FinalCenters) = theXCoords_pix theYCoords_pix
   a.mul theXCoords_pix $wlCalibrate(micronsPerPix) = theXCoords_um
   a.mul theYCoords_pix $wlCalibrate(micronsPerPix) = theYCoords_um

   #DEBUG
   #puts stdout "generateSineWavefront: "
   #a.min theYCoords_um = theMin
   #a.max theYCoords_um = theMax
   #puts stdout \
   #"     theYCoords_um: min= [a.dump theMin] max= [a.dump theMax]"
   #a.min theXCoords_um = theMin
   #a.max theXCoords_um = theMax
   #puts stdout \
   #"     theXCoords_um: min= [a.dump theMin] max= [a.dump theMax]"
   #puts stdout \
   #"     micronsperpix: $wlCalibrate(micronsPerPix)"




   # Compute the gradient of the wavefront from the user params: a,k, phi0
   # Wavefront is computed at spot positions, determined from Wavescope
   # calibration.
   # Wavefront:  phi(x,y) =  a sin( ky + phi0)
   # gradient :  d phi /dy = ak cos (ky + phi0)  d phi /dx = 0
   #
   set theYFrequency_recip_um [expr $gYFrequency_int_recip_mm * 0.001]
   set theYPhase_rad [expr $gYPhase_int_deg * 0.017453292]

   set theGradScale [expr $gYAmplitude_int_um * $theYFrequency_recip_um]

   a.mul theYCoords_um $theYFrequency_recip_um = theFreqScaledYCoords_rad
   a.add theFreqScaledYCoords_rad $theYPhase_rad = theGradYArg_rad
   a.cos theGradYArg_rad = theGradYWavefront_rad

   # y gradients are given here
   a.mul theGradYWavefront_rad $theGradScale = theGradYWavefront_rad

   # x gradients are all zero.
   a.mul theXCoords_um 0 = theGradXWavefront_rad


   # use wavescope atomic functions to reconstruct the
   # wavefront from the gradients...
   #
   a.xytov2 theGradXWavefront_rad \
            theGradYWavefront_rad = theGradWavefront_v2_rad

   a.v2v2tov4 wlCalibrate(FinalCenters) \
              theGradWavefront_v2_rad = gUserDefWavefrontGrad_v4_rad

   #DEBUG
   puts stdout "generateSineYWavefront: gUserDefWavefrontGrad_v4_rad info"
   puts stdout "\t [a.info gUserDefWavefrontGrad_v4_rad] "


   # create an appropriately sized weight mask; it is not needed for
   # generation of the wavefront, therefore reset its values to be
   # all equal to one.
   alg.conv.pg.arrays $gUserDefWavefrontGrad_v4_rad \
                $wlCalibrate(Params) = theGradWavefront_v2_rad theWeightMask

   #-----------------------------
   # test alg.conv.pg.circ.arrays
   # this method of wavefront gradient also works but seems to generate
   # wavefronts that don't go to zero at the edge, unlike the above
   # procedure.  plk 9/27/2005

   #a.extele wlCalibrate(Pupil) 0 = theCenterCol_pix
   #a.extele wlCalibrate(Pupil) 1 = theCenterRow_pix
   #a.extele wlCalibrate(Pupil) 2 = thePupilRadius_pix
   #alg.conv.pg.circ.arrays $gUserDefWavefrontGrad_v4_rad \
   #                        $wlCalibrate(Params) \
   #                        theCenterCol_pix \
   #                        theCenterRow_pix \
   #                        thePupilRadius_pix \
   #                        = theGradWavefront_v2_rad theWeightMask
   # end test
   #------------------------------


   a.mul theWeightMask 0 = theWeightMask
   a.add theWeightMask 1 = theWeightMask

   # finally, reconstruct the wavefront from the gradients, weight mask
   alg.recon.slow theGradWavefront_v2_rad theWeightMask = theWavefrontOPD_float

   # scale the OPD
   a.mul theWavefrontOPD_float \
         $wlCalibrate(micronsPerPix) = gUserDefWavefrontOPD_float_um


   # set theWavefront $gUserDefWavefrontOPD_float_um



   #dialog "DEBUG Pause Here"


}





#---------------------------------------------------------------------------
# generateBesselWavefront
#
# generates a wavefront based on a user specified Bessel function
#
#
# This procedure uses Wavescope atomic functions to generate and manipulate
# arrays as well as reconstruct the wavefront from computed gradients.
#
# Procedure also makes use of current wavescope calibration data.  Wavescope
# must be calibrated before invoking this procedure!
#
# NOTE:  Pupil radius is used for membrane radius in calculations below.
#        If the pupil is not aligned with the edge of the membrane, you
#        must change this.  plk 9/27/2005
#
# W(x,y) =  N * J_v(x_vn * r/a) * e^i*v*phi
#
#       N = 2/(a*sqrt(pi)*|J_v+1(x_vn)|)
#
#       a = gMembraneRadiusFactor_unit
#       j = gEigenModeJIndex_int
#               j index:  j= 9 v + n - 1  integer used to label eigenfunctions.
#
# Called by: generateUserDefBesselWavefront
#
# This procedure uses Bessel functions.  You must have loaded the dll
# Bessj.dll prior to calling this procedure.  Use syntax:
# tcl% load <filename and path>.dll  (executed in tclshrc.tcl)
#
# COMPLETED.  NEEDS DEBUGGING.
# plk 09/28/2005
#---------------------------------------------------------------------------
proc generateBesselWavefront { } \
{
   global gMembraneRadiusFactor_unit
   global gEigenModeJIndex_int


   global gWavefrontBinLevel_int
   global gUserDefWavefrontOPD_float_um
   global gUserDefWavefrontGrad_v4_rad

   global Grad gvd CurDrv Drvs Grds MAX_ACT maskArray pokeFraction
   global wlCalibrate YACT_LINE_LENGTH XACT_LINE_LENGTH


   # Get coordinates of spot centers; convert to polar coordinates
   #
   # X,Y coordinates of the spot centers, obtained from wavescope
   # calibration data.  Wavefront is computed at spot positions,
   # determined from Wavescope calibration.

   a.v2toxy wlCalibrate(FinalCenters) = theXCoord_pix theYCoord_pix

   a.sq theXCoord_pix = theX2_pix
   a.sq theYCoord_pix = theY2_pix



   #----------------------------------------------------------------------
   # Below code may be replaced using  wlCalibrate(Pupil) to get the
   # current wavefront pupil radius.
   #
   # scale the radial coordinate by the pupil radius
   #
   #a.ave wlCalibrate(FinalCenters) = theSamplePositions_avg_V2
   #a.v2toxy theSamplePositions_avg_V2 = theCenterColumn_V0 theCenterRow_V0
   #set theCenterRow [a.dump theCenterRow_V0]
   #set theCenterColumn [a.dump theCenterColumn_V0]
   #
   # Use the value of pupil radius that will center the wavefront
   # over the sampled area of the spot image plane.
   #set thePupilRadius_pix [expr $theCenterRow - 0.2*$theCenterRow]
   #
   # END Replacement code
   #----------------------------------------------------------------------


   # set the membrane radius equal to the pupil radius.

   a.extele wlCalibrate(Pupil) 2 = thePupilRadius_pixA
   set theMembraneRadius_pix [expr a.dump thePupilRadius_pixA]



   # theta coord. (computation not necessary for v=0 eigenfuncs)
   # For j>9 uncomment these lines to compute theta.
   # a.div theYCoord_pix theXCoord_pix = theYByX_pix
   # a.atan theYByX_pix = theTheta_rad



   # compute normalization factor for wavefront computation.

   set theNDenomFact1 [expr $theMembraneRadius_pix * sqrt(3.14159)]

   # Bessel function factor:
   # for j>9 this line must be replaced with procedure to compute the
   # correct bessel function factor:  J_v+1(X_vn).
   bessj1 $theXvn theNDenomFact2

   set theNDenomFact2 [expr abs($theNDenomFact2)]
   set theNDenom [expr $theNDenomFact1 * $theNDenomFact2]
   set theNorm [expr 2/$theNDenom]



   # array for storing wavefront OPD information at each
   # sampled point (x,y) = (r,theta)
   a.make 0 $theNumXValues = theWavefrontOPD_pixA


   # loop limits in for loop below.
   a.cols theXCoord_pix = theNumXValuesA
   set theNumXValues [expr a.dump theNumXValuesA]


   # compute the wavefront value at each sampled point.

   for { set i 0 } { $i < $theNumXValues } { incr i } {

             # get coords of current sampled point.
             a.extele theX2_pix i = theCX2_pix
             a.extele theY2_pix j = theCY2_pix


             # compute the scaled, current radial
             # coordinate of the sample point.

             a.add theCX2_pix theCY2_pix = theCR2_pix
             a.sqrt theCR2_pix = theCR_pix
             a.div theCR_pix $theMembraneRadius_pix = theSCR_dimlessA
             set theSCR_dimless [expr a.dump theSCR_dimlessA]


             # for j>9 compute theta coordinate here.


             # compute the wavefront value by evaluating the Bessel
             # function expression.

             # For j>9 compute the angular factor here and multiply
             # into the existing expression for theWav_pix (use the
             # real part only)

             set theArg [expr $theSCR_dimless*$theXvn]
             bessj0 $theArg theBessjValue_dimless
             set theWav_pix [expr $theBessjValue_dimless * $theNorm]

             a.repele theWav_pix theWavefrontOPD_pixA i = theWavefrontOPD_pixA
        }

   }

   # scale the OPD
   a.mul theWavefrontOPD_pixA \
         $wlCalibrate(micronsPerPix) = theWavefrontOPD_um


   # so far, position & wavefront information are in 1D-list format
   # ie.  X1, Y1, R1, theta1, wav1
   #      X2, Y2, R2, theta2, wav2
   #      X3, Y3, R3, theta3, wav3  etc.
   #
   # now convert this format into 2D wavefront array using wavescope
   # atomic function alg.conv.pg.arrays

   a.xytov2 theWavefrontOPD_um theWavefrontOPD_um = theWavefrontOPD_umV2

   a.v2v2tov4 wlCalibrate(FinalCenters) \
              theWavefrontOPD_umV2 \
              = theWavefrontOPD_umV4

   alg.conv.pg.arrays theWavefrontOPD_umV4 \
                      wlCalibrate(Params) \
                      = theWavefrontOPD_um2DFloat theWavMaskArray

   a.copy theWavefrontOPD_um2DFloat = gUserDefWavefrontOPD_float_um

}


#---------------------------------------------------------------------------
# generateFlatWavefront
#
# generates a wavefront based on user parameters of the form:
#
#      phi(x,y) = 0
#
#
# This procedure uses Wavescope atomic functions to generate and manipulate
# arrays as well as reconstruct the wavefront from computed gradients.
#
# Procedure also makes use of current wavescope calibration data.  Wavescope
# must be calibrated before implementing this procedure!
#
#
# Called by: generateUserDefWavefront
#
# plk 01/02/2005
#---------------------------------------------------------------------------
proc generateFlatWavefront { } \
{
   global gYAmplitude_int_um
   global gYFrequency_int_recip_mm
   global gYPhase_int_deg
   global gWavefrontBinLevel_int
   global gUserDefWavefrontOPD_float_um
   global gUserDefWavefrontGrad_v4_rad

   global Grad gvd CurDrv Drvs Grds MAX_ACT maskArray pokeFraction
   global wlCalibrate YACT_LINE_LENGTH XACT_LINE_LENGTH


   # X,Y coordinates of the spot centers,
   # obtained from wavescope calibration data.
   a.v2toxy wlCalibrate(FinalCenters) = theXCoords_pix theYCoords_pix
   a.mul theXCoords_pix $wlCalibrate(micronsPerPix) = theXCoords_um
   a.mul theYCoords_pix $wlCalibrate(micronsPerPix) = theYCoords_um

   #DEBUG
   #puts stdout "generateSineWavefront: "
   #a.min theYCoords_um = theMin
   #a.max theYCoords_um = theMax
   #puts stdout \
   #"     theYCoords_um: min= [a.dump theMin] max= [a.dump theMax]"
   #a.min theXCoords_um = theMin
   #a.max theXCoords_um = theMax
   #puts stdout \
   #"     theXCoords_um: min= [a.dump theMin] max= [a.dump theMax]"
   #puts stdout \
   #"     micronsperpix: $wlCalibrate(micronsPerPix)"



   
   # Compute the gradient of the wavefront from the user params: a,k, phi0
   # Wavefront is computed at spot positions, determined from Wavescope
   # calibration.
   # Wavefront:  phi(x,y) =  a sin( ky + phi0)
   # gradient :  d phi /dy = ak cos (ky + phi0)  d phi /dx = 0
   #
   set theYFrequency_recip_um [expr $gYFrequency_int_recip_mm * 0.001]
   set theYPhase_rad [expr $gYPhase_int_deg * 0.017453292]

   set theGradScale [expr $gYAmplitude_int_um * $theYFrequency_recip_um]

   a.mul theYCoords_um $theYFrequency_recip_um = theFreqScaledYCoords_rad
   a.add theFreqScaledYCoords_rad $theYPhase_rad = theGradYArg_rad
   a.cos theGradYArg_rad = theGradYWavefront_rad

   # y gradients are all zero
   a.mul theYCoords_um 0 = theGradYWavefront_rad

   # x gradients are all zero.
   a.mul theXCoords_um 0 = theGradXWavefront_rad


   # use wavescope atomic functions to reconstruct the
   # wavefront from the gradients...
   #
   a.xytov2 theGradXWavefront_rad \
            theGradYWavefront_rad = theGradWavefront_v2_rad

   a.v2v2tov4 wlCalibrate(FinalCenters) \
              theGradWavefront_v2_rad = gUserDefWavefrontGrad_v4_rad

   #DEBUG
   puts stdout "generateFlatWavefront: gUserDefWavefrontGrad_v4_rad info"
   puts stdout "\t [a.info gUserDefWavefrontGrad_v4_rad] "


   # create an appropriately sized weight mask; it is not needed for
   # generation of the wavefront, therefore reset its values to be
   # all equal to one.
   alg.conv.pg.arrays $gUserDefWavefrontGrad_v4_rad \
                $wlCalibrate(Params) = theGradWavefront_v2_rad theWeightMask
   a.mul theWeightMask 0 = theWeightMask
   a.add theWeightMask 1 = theWeightMask

   # finally, reconstruct the wavefront from the gradients, weight mask
   alg.recon.slow theGradWavefront_v2_rad theWeightMask = theWavefrontOPD_float

   # scale the OPD
   a.mul theWavefrontOPD_float \
         $wlCalibrate(micronsPerPix) = gUserDefWavefrontOPD_float_um


   # set theWavefront $gUserDefWavefrontOPD_float_um
   


   #dialog "DEBUG Pause Here"


}


#---------------------------------------------------------------------------
# lookupBesselIndicesAndZero
#
# returns the v,n indices and the zero xvn corresponding to a given
# Bessel J index.
#
# data taken from \\Gigabytes\home\jkl\kraken\krakenlap\Membrane Calculations\
# Analytical Calculations\Stability and Snap Down Calculations\Stability Formal
# Calculation\Program\Version 4\BesselJZeros.h
#
#  J   v   n    X_vn
#{ 0 , 0 , 1 , 2.405 },
#{ 1 , 0 , 2 , 5.52 },
#{ 2 , 0 , 3 , 8.654 },
#{ 3 , 0 , 4 , 11.792 },
#{ 4 , 0 , 5 , 14.931 },
#{ 5 , 0 , 6 , 18.071 },
#{ 6 , 0 , 7 , 21.212 },
#{ 7 , 0 , 8 , 24.353 },
#{ 8 , 0 , 9 , 27.494 },
#{ 9 , 1 , 1 , 3.832 },
#{ 10 , 1 , 2 , 7.016 },
#
# called by:  generateBesselWavefront
#
# UNDER CONSTRUCTION
#
# 9/20/2005
#---------------------------------------------------------------------------
proc lookupBesselIndicesAndZero { inJ outV outN outXvn } \
{

   upvar $outV theV
   upvar $outN theN
   upvar $outXvn theXvn

   switch -- $inJ {

      0 { set theV 0; set theN 0; set theXvn 2.405 }
      1 { set theV 0; set theN 2; set theXvn 5.52 }
      2 { set theV 0; set theN 3; set theXvn 8.654 }
      3 { set theV 0; set theN 4; set theXvn 11.792 }
      4 { set theV 0; set theN 5; set theXvn 14.931 }
      5 { set theV 0; set theN 6; set theXvn 18.071 }
      6 { set theV 0; set theN 7; set theXvn 21.212 }
      7 { set theV 0; set theN 8; set theXvn 24.353 }
      8 { set theV 0; set theN 9; set theXvn 27.494 }
      9 { set theV 1; set theN 1; set theXvn 3.832 }
     10 { set theV 1; set theN 2; set theXvn 7.016 }


   }



}

