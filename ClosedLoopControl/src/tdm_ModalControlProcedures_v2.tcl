#------------------------------------------------------------------------
# tdm_ModalControlProcedures.tcl                      tcl script
#
# Procedures used in control of transparent electrode membrane mirror using
# modal control algorithm.
#
# Procedures in this file:
#
#       decomposeWavefrontZernikeCoeffs
#
#
# Note:  to initialize procedures in this file with the wavescope
# software, add lines such as the following to the tclIndex.tcl file
# in usr/aos/wavescope/scripts/
#        e.g. set auto_index(decomposeWavefrontZernikeCoeffs) \
#               [list source [file join tdm_ModalControlProcedures.tcl]]
#
# version 3
# plk 05/03/2005
#------------------------------------------------------------------------

# Number of terms in Zernike expansion of wavefront, integer
global gNumberOfZernikeTerms

# Zernike coefficients of current wavefront, V2 array
global gWavefrontZernikeCoeffs



#------------------------------------------------------------------------
# decomposeWavefrontZernikeCoeffs
#
# Decomposes the current wavefront into N Zernike coefficients
#
#
# This procedure uses Wavescope atomic functions to generate and manipulate
# arrays.
#
# Procedure also makes use of current wavescope calibration data.  Wavescope
# must be calibrated before implementing this procedure!
#
# NOTE:  Coefficients output by this procedure are off by a factor of
# 0.06 from coefficients computed by the real time wavescope display.

# e.g.
#    Zernike coefficients for test wavefront
#    this code (um)?     wavescope (um)
#    ---------           ---------
#      0.000696          -0.0115       tilt (rcos)
#      0.002204          -0.0401       tilt
#      0.004935          -0.0845       focus
#
#
# Called by:  (wish shell)
#
# plk 05/02/2005
#---------------------------------------------------------------------------
proc decomposeWavefrontZernikeCoeffs { } \
{
   global gNumberOfZernikeTerms
   global gWavefrontZernikeCoeffs

   global Grad gvd CurDrv Drvs Grds MAX_ACT maskArray pokeFraction
   global wlCalibrate YACT_LINE_LENGTH XACT_LINE_LENGTH


   set gNumberOfZernikeTerms 35


   # take WFS measurement.  Avg. 15x frames.  Data stored in Grad array
   calcGrad 15


   # get x,y center of current image plane from calibration data
   a.ave wlCalibrate(FinalCenters) = theSamplePositions_avg_V2
   a.v2toxy theSamplePositions_avg_V2 = theCenterColumn_V0 theCenterRow_V0
   set theCenterRow [a.dump theCenterRow_V0]
   set theCenterColumn [a.dump theCenterColumn_V0]


   # Use the value of pupil radius that will center the wavefront
   # over the sampled area of the spot image plane.
   # NOTE:  This value of pupil radius assumes that image radius is
   # closely aligned with membrane radius.
   # set thePupilRadius_pix [expr $theCenterRow - 0.01*$theCenterRow]
   set thePupilRadius_pix [expr $theCenterRow ]

   # DEBUG
   # typical values (determined during WFS calibration)
   # CenterRow         242.88
   # CenterCol         358.34
   # Radius (pix)      240
   # plk 5/2/2005

   puts "theCenterRow        = $theCenterRow"
   puts "theCenterColumn     = $theCenterColumn"
   puts "thePupilRadius_pix  = $thePupilRadius_pix"


   # wavefront gradients stored in Grad array (v4), which is
   # populated during a WFS measurment called by calcGrad
   zern.decomp.grad.coefs Grad \
                          $gNumberOfZernikeTerms \
                          $theCenterColumn \
                          $theCenterRow \
                          $thePupilRadius_pix = gWavefrontZernikeCoeffs


   # DEBUG
   # convert the coeffs. to strings, and print...
   zern.conv.string gWavefrontZernikeCoeffs


}






#------------------------------------------------------------------------
# pokeBinnedActuators_quiet
#
# Pokes each actuator bin, according to a prescribed binning scheme
# and records the gradients (no noise). Computes the coefficients of
# the Zernike expansion for each influence function.
# Based on quiet_restricted{}
#
#
# Called by:  MrPR (in dm_panels_5dms.tcl)
#
# plk 12/17/2004
#------------------------------------------------------------------------
proc pokeBinnedActuators_ZernikeDecomp { } {

    global gNumberOfActuatorsPerBin

    global Grad gvd CurDrv Drvs Grds MAX_ACT maskArray pokeFraction
    global wlCalibrate YACT_LINE_LENGTH XACT_LINE_LENGTH

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

   # set the parameters for the binning of actuators based on
   # the number of actuators per bin.

   # for N X N binning of actuators
   # theNumberOfActuatorsPerBin = N*N
   set theNumberOfActuatorsPerBin $gNumberOfActuatorsPerBin

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

             # array for storing preliminary desired deflection data
             a.make 0 $MAX_ACT = CD

             # set Grad array.  This step may not be necessary for computations
             # below, but Grad must be defined on first pass through the
             # for loops
             vd.new Grad
             update
             calcGrad 10
             vd.set.array gvd Grad

             #DEBUG
             puts stdout "PokeBinnedActuators_quiet: Binned Actuator: i=$i j=$j"

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

                                 # ...and if the actuator is not masked ...
                                 if { [ a.extele maskArray $theHDActuatorIndex ] == 1 } {

                                      # ...set the corresponding element of
                                      # the CD (curvature drive) array to the
                                      # value $pokeFraction.  This actuator
                                      # will then have a voltage applied to
                                      # it (below).

                                      # DEBUG
                                      #puts stdout \
                                      #   "\t Bi=$Bi Bj=$Bj Index $theHDActuatorIndex"

                                      # ... then update CD array
                                      a.repele $pokeFraction CD $theHDActuatorIndex = CD


                                 } else {
                                      # ...else the actutor is masked

                                      #DEBUG
                                      #puts "Skipping masked actuator: $j x $i"

                                      # why set CD array to zero below?
                                      # this line commented out.
                                      # plk 12/17/2004
                                      #a.copy zeros = CD

                                      a.v2v2tov4 wlCalibrate(FinalCenters) gzeros = Grad
                                 }
                            }
                       }
                  }
             }

             a.add CD CurDrv0 = CurDrv

             # DEBUG:  Display histogram and statistics of CurDrv
             #puts stdout \
             #     "PokeBinnedActuators_ZernikeDecomp: CurDrv histogram in plot window"
             #a.tilt 10 0 0.01 = theHistogramBins
             #a.hist CurDrv -1 0.5 25 = theCurDrvHistogramData
             #pd.new theHistogram
             #pd.set.type theHistogram 3
             #pd.set.title theHistogram "Histogram of CurDrv values"
             #pd.set.y.array theHistogram theCurDrvHistogramData
             #puts stdout "PokeBinnedActuators_ZernikeDecomp:  CurDrv histogram 25 0.5 bins"
             #puts stdout "[a.dump theCurDrvHistogramData]"

             # DEBUG:  CurDrv contents
             #puts stdout "*************CurDrv follows**********************"
             #puts stdout "[a.dump CurDrv]"

             # DEBUG:  CurDrv statistics
             a.min CurDrv = theMin
             a.max CurDrv = theMax
             puts stdout "pokeBinnedActuators_ZernikeDecomp:"
             puts stdout \
                  "     CurDrv: min= [a.dump theMin] max= [a.dump theMax]"

             # ... update the GUI display
             SetGUIActs $CurDrv

             # ... convert CurDrv to voltage
             ftov $CurDrv uuu

             # DEBUG:  voltage array histogram
             #puts stdout \
             #     "PokeBinnedActuators_ZernikeDecomp: voltage histogram in plot window"
             #a.tilt 10 0 0.01 = theHistogramBins
             #a.hist uuu 0 1 15 = theUUUHistogramData
             #pd.new theHistogram
             #pd.set.type theHistogram 3
             #pd.set.title theHistogram "Histogram of voltages"
             #pd.set.y.array theHistogram theUUUHistogramData
             #puts stdout "PokeBinnedActuators_quiet: UUU histogram: 15 1V bins"
             #puts stdout "\t [a.dump theUUUHistogramData]"

             #DEBUG: voltage array info.
             #puts stdout "************* uuu follows**********************"
             #puts stdout "PokeBinnedActuator_ZernikeDecomp: UUU info"
             #puts stdout "\t [a.info uuu] "


             # DEBUG: voltage array statistics
             a.min uuu = theUMin
             a.max uuu = theUMax
             puts stdout "PokeBinnedActuators_ZernikeDecomp:"
             puts stdout "     UUU: min= [a.dump theUMin] max= [a.dump theUMax]"

             # ... send voltages to the hardware
             dm.send uuu
             update

             # calculate gradient by grabbing 10 images; result
             # is stored in global variable Grad
             calcGrad 10

             # insert 500 ms wait time here for membrane to settle.
             # set voltages to zero.  Wait for membrane to settle once more.
             after 500
             setzero
             after 500

             vd.set.array gvd Grad

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

