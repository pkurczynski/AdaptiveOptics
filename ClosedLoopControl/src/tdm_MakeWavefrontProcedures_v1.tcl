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
#               displayDesiredWavefront
#               generateSineYWavefront
#
# Note:  to initialize procedures in this file with the wavescope
# software, add lines such as the following to the tclIndex.tcl file
# in usr/aos/wavescope/scripts/
#        e.g. set auto_index(makeWavefront) \
#               [list source [file join tdm_MakeWavefrontProcedures.tcl]]
#
# version 1
# plk 01/02/2005
#------------------------------------------------------------------------
global gYAmplitude_int_um
global gYFrequency_int_recip_mm
global gYPhase_int_deg
global gWavefrontBinLevel_int

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
#   displayDesiredWavefront
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

    set theSubTitle "variation in y:  A sin( ky y  +  p_0 )"
    message .sSWPanel.f.clb.msg -text $theSubTitle \
                                -aspect 1000 \
                                -font "helvetica"
    pack    .sSWPanel.f.clb.msg -padx 5 -pady 5



    frame .sSWPanel.f.clb.tt -relief groove -bd 2
    pack  .sSWPanel.f.clb.tt -pady 5
    frame .sSWPanel.f.clb.tt.ctl1
    pack  .sSWPanel.f.clb.tt.ctl1 -padx 26
    scale .sSWPanel.f.clb.tt.ctl1.scaleYAmplitude -from 0 \
                                                  -to 10 \
                                                  -length 200 \
                                                  -orient horizontal\
                                                  -label "Amplitude, A, um" \
                                                  -variable gYAmplitude_int_um

    scale .sSWPanel.f.clb.tt.ctl1.scaleYFrequency -from 0 \
                                                  -to 12 \
                                                  -length 200 \
                                                  -orient horizontal\
                        -label "Spatial Frequency, ky, mm^-1" \
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

    scale .sSWPanel.f.clb.tt.ctl1.scaleActuatorBinning \
                                -from 1 \
                                -to 10 \
                                -length 200 \
                                -orient horizontal\
                                -label "Actuator Binning, N, (i.e. NxN)" \
                                -variable gWavefrontBinLevel_int
    pack  .sSWPanel.f.clb.tt.ctl1.scaleActuatorBinning -side top -padx 10


    frame .sSWPanel.f.clb.ctl
    pack  .sSWPanel.f.clb.ctl -anchor w -pady 5

    button .sSWPanel.f.clb.ctl.cmd  -text "Command DM..." \
                                    -command { commandDM_OpenLoop }
    button .sSWPanel.f.clb.ctl.sact -text "Show Actual..." \
                                    -command { displayActualWavefront }
    button .sSWPanel.f.clb.ctl.sdes -text "Show Desired..." \
                                    -command { displayDesiredWavefront }
    pack   .sSWPanel.f.clb.ctl.cmd \
           .sSWPanel.f.clb.ctl.sact \
           .sSWPanel.f.clb.ctl.sdes \
           -side left \
           -padx 5


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
   global gWavefrontBinLevel_int


   destroy .sSWPanel

   #DEBUG
   puts stdout "The wavefront:"
   puts stdout "Amplitude, um:  $gYAmplitude_int_um"
   puts stdout "Frequency, mm:  $gYFrequency_int_recip_mm"
   puts stdout "Phase,    deg:  $gYPhase_int_deg"
   puts stdout "Binning,  NxN:  $gWavefrontBinLevel_int"

}




#---------------------------------------------------------------------------
# displayDesiredWavefront
#
# Event handler called when user wants to display the desired wavefront.
#
# Called by: displaySineWavefrontPanel
#
# plk 01/02/2005
#---------------------------------------------------------------------------
proc displayDesiredWavefront { } \
{
     generateSineYWavefront
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
# Called by: displayDesiredWavefront
#
# plk 01/02/2005
#---------------------------------------------------------------------------
proc generateSineYWavefront { } \
{
   global Grad gvd CurDrv Drvs Grds MAX_ACT maskArray pokeFraction
   global wlCalibrate YACT_LINE_LENGTH XACT_LINE_LENGTH


   # X,Y coordinates of the spot centers,
   # obtained from wavescope calibration data.
   a.v2toxy wlCalibrate(FinalCenters) = theXCoords_pix theYCoords_pix
   a.mul theXCoords_pix $wlCalibrate(micronsPerPix) = theXCoords_um
   a.mul theYCoords_pix $wlCalibrate(micronsPerPix) = theYCoords_um


   # Compute the gradient of the wavefront from the user params: a,k, phi0
   # Wavefront is computed at spot positions, determined from Wavescope
   # calibration.
   # Wavefront:  phi(x,y) =  a sin( ky + phi0)
   # gradient :  d phi /dy = ak cos (ky + phi0)  d phi /dx = 0
   #
   set theYFrequency_recip_um [expr $gYFrequency_int_recip_mm * 1e-3]
   set theYPhase_rads [expr $gYPhase_int_deg * 0.017453292]

   set theGradScale [expr $gAmplitude_int_um * theYFrequency_recip_um]

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
              theGradWavefront_v2_rad = theGradWavefront_v4_rad

   # create an appropriately sized weight mask; it is not needed for
   # generation of the wavefront, therefore reset its values to be
   # all equal to one.
   alg.conv.pg.arrays $theGradWavefront_v4_rad \
                $wlCalibrate(Params) = theGradWavefront_v2_rad theWeightMask
   a.mul theWeightMask 0 = theWeightMask
   a.add theWeightMask 1 = theWeightMask

   # finally, reconstruct the wavefront from the gradients, weight mask
   alg.recon.fast theGradWavefront_v2_rad theWeightMask = theWavefrontOPD_float

   # scale the OPD
   a.mul theWavefrontOPD_float \
         $wlCalibrate(micronsPerPix) = theWavefrontOPD_float_um

   # DEBUG
   # display the created wavefront!
   id.new USERDEF_OPD_ID
   id.set.array USERDEF_OPD_ID theWavefrontOPD_float_um



}






proc generateWavefront_old { } \
{
   global Grad gvd CurDrv Drvs Grds MAX_ACT maskArray pokeFraction
   global wlCalibrate YACT_LINE_LENGTH XACT_LINE_LENGTH

   # set the parameters for the binning of actuators based on
   # the number of actuators per bin.

   # for N X N binning of actuators
   # theNumberOfActuatorsPerBin = N*N
   set theNumberOfActuatorsPerBin \
        [expr $gWavefrontBinLevel_int*$gWavefrontBinLevel_int]

   set theIBinWidth [expr int(sqrt($theNumberOfActuatorsPerBin))]
   set theJBinWidth [expr int(sqrt($theNumberOfActuatorsPerBin))]

   # assume square bins for computing the row, column ranges below
   set theN $theIBinWidth

   # set the relative row, column ranges for the NxN bin
   # this code will produce the following (e.g.)
   # # actuators   binning    Bx_lo   Bx_hi
   # -----------   -------    -----   -----
   #      4          2x2         0       1
   #      9          3x3        -1       1
   #     25          5x5        -2       2
   #    256         16x16       -7       8
   #    512         32x32       -15     16

   set theNisEven [expr int(1 - fmod($theN,2))]
   set Bi_lo [expr -1*int($theN/2) + $theNisEven]
   set Bi_hi [expr int($theN/2)]
   set Bj_lo [expr -1*int($theN/2) + $theNisEven]
   set Bj_hi [expr int($theN/2)]


   set count 0


   # loop over the actuators in the array, modulo binning
   # i,j determines actuator at the bin center (odd binning) or
   # the actuator to the immediate "lower left" of bin center (even binning).
   for { set i 0 } { $i < $XACT_LINE_LENGTH } { incr i $theIBinWidth } {
        for { set j 0 } { $j < $YACT_LINE_LENGTH } { incr j $theJBinWidth } {


             #DEBUG
             puts stdout "generateWavefront: Binned Actuator: i=$i j=$j"

             # loop over actuators in each bin.  Limits are determined by
             # the type of binning, defined above.
             for { set Bi $Bi_lo } { $Bi <= $Bi_hi } { incr Bi } {
                  for { set Bj $Bj_lo } { $Bj <= $Bj_hi} { incr Bj } {

                       # absolute i,j values of the current actuator
                       set Bi_abs [expr $Bi + $i]
                       set Bj_abs [expr $Bj + $j]

                       # Harold Dysons integer index number of the actuator
                       set theHDActuatorIndex \
                                [expr $Bi_abs*$XACT_LINE_LENGTH +$Bj_abs]

                       # if current actuator is within the active area
                       # of the array ...
                       if { $Bi_abs >= 0 && $Bi_abs < $XACT_LINE_LENGTH } {
                            if { $Bj_abs >= 0 && $Bj_abs < $YACT_LINE_LENGTH } {



                            }
                       }
                  }
             }

             a.add CD CurDrv0 = CurDrv


        }
   }


}
