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
#               generateUserDefWavefront
#               commandDMToUserDefWavefront
#               displayWavefront
#               generateSineYWavefront
#
# Note:  to initialize procedures in this file with the wavescope
# software, add lines such as the following to the tclIndex.tcl file
# in usr/aos/wavescope/scripts/
#        e.g. set auto_index(makeWavefront) \
#               [list source [file join tdm_MakeWavefrontProcedures.tcl]]
#
# version 3
# plk 01/03/2005
#------------------------------------------------------------------------

# parameters for user defined wavefront
global gYAmplitude_int_um
global gYFrequency_int_recip_mm
global gYPhase_int_deg

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
# Called by:
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
                                    -command { generateUserDefWavefront }

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
             -to 1 \
             -length 200 \
             -orient horizontal \
             -resolution 0.01 \
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
   puts stdout "The wavefront:"
   puts stdout "Amplitude, um:  $gYAmplitude_int_um"
   puts stdout "Frequency, mm:  $gYFrequency_int_recip_mm"
   puts stdout "Phase,    deg:  $gYPhase_int_deg"
   puts stdout "Iter. param. :  $gIterationStepSizeParameter"

   set USERDEF_OPD_WID 0
}




#---------------------------------------------------------------------------
# generateUserDefWavefront
#
# Event handler called when user wants to generate the desired wavefront.
# The wavefront data is stored in the global variable:
# gUserDefWavefrontOPD_float_um
#
# Called by: displaySineWavefrontPanel
#
# plk 01/02/2005
#---------------------------------------------------------------------------
proc generateUserDefWavefront { } \
{

     # DEBUG
     #generateFlatWavefront

     generateSineYWavefront
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
# Called by: displaySineWavefrontPanel
#
# plk 01/03/2005
#---------------------------------------------------------------------------
proc commandDMToUserDefWavefront { } \
{
    global gCommandDMToUserDefFlag
    global gUserDefWavefrontGrad_v4_rad
    global gIterationStepSizeParameter

    global Grad Drive Drives CurDrv ivd Recon Drvs Drerr
    global modew mds integGain wlCalibrate
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
    # keep trying to generate the desired wavefront.
    #
    while { $gCommandDMToUserDefFlag == 1 } {

        # get current wavefront data (avg 3 frames).
        # data stored in global array "Grad"
	calcGrad 3
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

        puts stdout "commandDMToUserDefWavefront: Grad info"
        puts stdout "\t [a.info Grad] "

        a.min Grad = theMin
        a.max Grad = theMax
        puts stdout \
        "     Grad: min= [a.dump theMin] max= [a.dump theMax]"


        puts stdout "commandDMToUserDefWavefront: gUserDefWavefrontGrad_v4_rad info"
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


	puts "Closed loop iteration: $i"
	incr i
	update
    }
    set opd_ivd 0


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


