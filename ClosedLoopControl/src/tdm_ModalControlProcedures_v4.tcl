#------------------------------------------------------------------------
# tdm_ModalControlProcedures.tcl                      tcl script
#
# Procedures used in control of transparent electrode membrane mirror using
# modal control algorithm.
#
# Procedures in this file:
#
#       decomposeWavefrontIntoZernikeCoeffs
#
#
# Note:  to initialize procedures in this file with the wavescope
# software, add lines such as the following to the tclIndex.tcl file
# in usr/aos/wavescope/scripts/
#        e.g. set auto_index(decomposeWavefrontZernikeCoeffs) \
#               [list source [file join tdm_ModalControlProcedures.tcl]]
#
# version 4
# plk 05/16/2005
#------------------------------------------------------------------------

# Flag is set to 1 upon training.  Must be set prior to closed loop operation.
global gTrainDMForModalControlFlag

# Number of terms in Zernike expansion of wavefront, integer
global gNumberOfZernikeTerms

# Zernike coefficients of current wavefront, V2 array
global gWavefrontZernikeCoeffsV2

global gMembraneShapeZernikeCoeffsV2
global gMembraneLaplacianZernikeCoeffsV2

# Membrane shape and Laplacian, computed at actuator center positions
# < xi  yi   xi(xi,yi)   del2 xi(xi,yi) >
# See computeMembraneShapeAndLaplacian
global gMembraneShapeV4

# X,Y positions of each binned actuator center
global gActuatorPositionV2

global gModalControlNumberOfActuatorsPerBin

#---------------------------------------------------------------------------
# proc trainDMForModalControl
#
#
# called by:  displayModalControlPanel
#---------------------------------------------------------------------------

proc trainDMForModalControl {} {

    global gTrainDMForModalControlFlag

    global loopType wlCalibrate stagePos


    set gTrainDMForModalControlFlag 1

    #DEBUG
    #dialog "Debug Pause Here"

    if { $wlCalibrate(doneInit) != "Yes" } {
	dialog "Please Calibrate WaveScope."
	return
    }
    stage.calibrate.absolute $stagePos(BestRefSpots)


    pokeBinnedActuators_TrainModalControl

    #makerecon
    #set loopType Mat



}










#------------------------------------------------------------------------
# pokeBinnedActuators_TrainModalControl
#
# Pokes each actuator bin, according to a prescribed binning scheme
# and records the gradients (no noise).  This procedure populates the
# Grds array, which contains wavefront gradient information corresponding
# to each "poke" of a (possibly binned) electrode influence function.
#
# For each "poke" of device, this procedure calculates the x,y position
# of the minimum of the wavefront, and stores this position as the
# coordinates of the binned electrode.
#
# Based on pokeBinnedActuators_quiet{}
#
# These global variables must be set before calling procedure:
#
#       gNumberOfActuatorsPerBin
#
# Output of this procedure:
#
#       Grds                    array of v4 wavefront gradients; one row
#                               per electrode influence function
#
#       gActuatorPositionV2       array of v2 actuator center x,y positions
#                               determined from poke procedure.
#
#
# Called by:  trainDMForModalControl
#
# PROCEDURE COMPLETED BUT NEEDS TESTING/DEBUGING.
# plk 05/12/2005
#------------------------------------------------------------------------
proc pokeBinnedActuators_TrainModalControl { } {

    global gModalControlNumberOfActuatorsPerBin
    global gActuatorPositionV2

    global Grad gvd CurDrv Drvs Grds MAX_ACT maskArray pokeFraction
    global wlCalibrate YACT_LINE_LENGTH XACT_LINE_LENGTH

    # Display gradients while we work.
    #
    vd.new gvd
    vd.set.title gvd "Measured Gradient"
    vd.set.xy gvd 50 50
    vd.set.wh gvd 300 300


    #set, initialize array of actuator center positions
    a.make "<-1 2>" 1 1 = gActuatorPositionV2
    a.make "<-1 2>" 1 1 = theTempV2


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
   #
   # why is this a global variable?
   set gModalControlNumberOfActuatorsPerBin 25

   # for N X N binning of actuators
   # theNumberOfActuatorsPerBin = N*N
   set theNumberOfActuatorsPerBin $gModalControlNumberOfActuatorsPerBin

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


   set theNumberOfBinnedActuators 1


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
             puts stdout "pokeBinnedActuators_TrainModalControl: Binned Actuator: i=$i j=$j"

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


             # ... update the GUI display
             SetGUIActs $CurDrv

             # ... convert CurDrv to voltage
             ftov $CurDrv uuu


             # ... send voltages to the hardware
             dm.send uuu
             update

             # calculate gradient by grabbing 10 images; result
             # is stored in global variable Grad
             calcGrad 10


             # this is where you must calculate the x,y position of
             # each actuator.

             # first find the element of Grad which has the gradient
             # nearest to zero.  Grad is a v4 vector (x,y, dphi/dx, dphi/dy)
             getV4GradientEqZeroPosition Grad theXYv2

             # DEBUG
             #puts stdout "[a.info theXYv2]"
             #puts stdout "[a.dump theXYv2]"
             #dialog "Debug Pause Here"

             # draw a small circle on the video display at the position
             # of the current x,y center position


             # insert 500 ms wait time here for membrane to settle.
             # set voltages to zero.  Wait for membrane to settle once more.
             after 500
             setzero
             after 500

             vd.set.array gvd Grad


             # populate the gActuatorPositionV2 array current row element
             # with the x,y positions of the current actuator.
             if { $theNumberOfBinnedActuators == 1 }\
             {
                  a.copy CD = Drvs
                  a.copy Grad = Grds
                  a.repele theXYv2 gActuatorPositionV2 0 0 = gActuatorPositionV2

                  #DEBUG
                  puts stdout "[a.info gActuatorPositionV2]"
                  puts stdout "[a.dump gActuatorPositionV2]"
                  #dialog "Debug Pause Here too!"
                  

             } else \
             {
                  a.catrow Drvs CD = Drvs
                  a.catrow Grds Grad = Grds
                  a.repele theXYv2 theTempV2 0 0 = theTempV2
                  a.catrow gActuatorPositionV2 theTempV2 = gActuatorPositionV2
             }

             incr theNumberOfBinnedActuators

             update
        }
   }

   a.make 0 $MAX_ACT = CurDrv

   # alternately, compute actuator positions here.  Operate on Grds
   # array one row at a time and compute x,y position of each row.
   # However, if done here, there will be no opportunity for visual
   # feedback on the CRT display.

   # Uncomment these next two lines to save the
   # calculated drive signal and gradients to disk.
   #
   a.saveasc Drvs Drvs
   a.saveasc Grds Grds

   set gvd 0

}



#---------------------------------------------------------------------------
# getV4GradientEqZeroPosition
#
# Finds the minimum of the absolute value of the gradient of a v4 (gradient)
# array, and returns the x,y coordinates of this minimum
#
# input parameter:    inGrad      column vector array of v4 elements where
#                                 each element is of the form
#                                 < x , y, dphi/dx , dphi/dy >
#
#
#
# output parameter:  outXYV2      v2 array specifying the x,y coordinates
#                                 of the position where
#                                 abs( (dphi/dx)^2 + (dphi/dy)^2 )
#                                 is a minimum.
#
#   NOTE:  output parameter does not need to be defined before executing
#          this procedure.
#
# called by: pokeBinnedActuators_TrainModalControl
#
# NOTE:  this procedure is probably not going to work.  Instead of
#        searching the gradient for a minimum Euclidean norm, and
#        hoping that this is the extremum of the wavefront and therefore
#        the center of the influence function peak, try reconstructing
#        the wavefront from the gradients, and then searching the
#        reconstructed wavefront for the peak. plk 5/16/2005
#
# PROCEDURE EXECUTES, BUT OUTPUT IS DUBIOUS.  see NOTE above.
# plk 5/12/2005
#---------------------------------------------------------------------------
proc getV4GradientEqZeroPosition { inGradV4 outXYV2 } {

   upvar $inGradV4 theGradV4
   upvar $outXYV2 theXYV2

   a.v4tov2v2 $theGradV4 = theXYPosV2 theGradV2

   set theTestNorm 0

   a.min theGradV2 = theMinNorm
   a.v2toxy theMinNorm = theMNX theMNY
   a.mul theMNX theMNX = theMNX2
   a.mul theMNY theMNY = theMNY2
   a.add theMNX2 theMNY2 = theMN2
   a.sqrt theMN2 = theMinNorm

   set theCurrentElementIndex 0
   set theMinElementIndex 0


   # NOTE:  procedure assumes that input array is a column vector
   # here.  If input array is a row vector then replace a.cols with
   # a.rows below (only one replacement reqd.)
   a.cols theGradV4 = theNumA
   set theNumElements [a.dump theNumA]

   #DEBUG
   #puts "theMinNorm = [a.dump $theMinNorm]"

   # search Grad array for index value of element with minimum
   # Euclidean norm
   for { set i 0 } { $i < $theNumElements } { incr i } {


        a.extele theGradV2 $i = theTestElementV2
        a.v2toxy theTestElementV2 = theXTest theYTest
        a.mul theXTest theXTest = theX2Test
        a.mul theYTest theYTest = theY2Test
        a.add theX2Test theY2Test = theNorm2Test
        a.sqrt theNorm2Test = theTestNorm


        #DEBUG
        #puts stdout "theTestNorm = [a.dump $theTestNorm]"


        if { [a.dump theTestNorm] == [a.dump theMinNorm] } {

                set theMinElementIndex $theCurrentElementIndex

                # DEBUG
                #puts stdout "theMinElementIndex = $theMinElementIndex"

                break
        }
        incr theCurrentElementIndex
   }

   # extract the position of the corresponding minimum of the
   # gradient from the position array.  Gradient and XY positions
   # have the same indexing because they came from the same V4 array
   a.extele theXYPosV2 $theMinElementIndex = theXYV2

}





#---------------------------------------------------------------------------
# flattenDMUsingModalControl
#
# Event handler called when user wants to command the DM to the
# create the desired wavefront in the optical system.
#
#
# Called by: displayModalControlPanel
#
# PROCEDURE IS UNDER CONSTRUCTION
# plk 05/15/2005
#---------------------------------------------------------------------------
proc flattenDMUsingModalControl { } \
{
    global gFlattenDMUsingModalControlFlag
    global gTrainDMForModalControlFlag

    global opd_ivd
    global platform
    global Drvs


    if { $gTrainDMForModalControlFlag != 1} {
       dialog "Please train DM..."
       return
    }

    
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

    while { $gFlattenDMUsingModalControlFlag == 1 } {


        # get current wavefront data (avg 3 frames).
        # data stored in global array "Grad"
	# calcGrad 3

        # compute the CurDrv array values for one
        # iteration of the wavefront correction.

        # THIS PROCEDURE MUST BE WRITTEN TO USE MODAL CONTROL ALGORITHM
        # 5/15/2005
        #computeMembraneShapeAndLaplacian  i gMembraneShapeV4

        # THIS PROCEDURE MUST BE WRITTEN TO USE MODAL CONTROL ALGORITHM
        # 5/15/2005
        #computeModalControlVoltagesAndSendToDACs i


	puts "Closed loop iteration: $i"
	incr i
	update
    }
    set opd_ivd 0


}




#---------------------------------------------------------------------------
# computeMembraneShapeAndLaplacian
#
# Computes membrane shape and Laplacian, at actuator center positions
#
#
# Derived from tdm_MakeWavefrontProcedures::iterateOneWavefrontCorrection
#
#
# argument:  i                   the integer iteration number.
#
#            outMembraneShapeV4  V4 array with the following format:
#                                < xi  yi   xi(xi,yi)   del2 xi(xi,yi) >
#
#
# Called by: flattenDMUsingModalControl
#
# PROCEDURE IS UNDER CONSTRUCTION
# plk 05/15/2005
#---------------------------------------------------------------------------
proc computeMembraneShapeAndLaplacian { i outMembraneShapeV4 } \
{

        upvar $outMembraneShapeV4 theMembraneShapeV4


        # Number of terms in Zernike expansion of wavefront, integer
        global gNumberOfZernikeTerms

        # Zernike coefficients of current wavefront, V2 array
        global gWavefrontZernikeCoeffsV2

        global gMembraneShapeZernikeCoeffsV2
        global gMembraneLaplacianZernikeCoeffsV2

        # X,Y positions of each binned actuator center
        global gActuatorPositionV2


        a.rows gActuatorPosistionV2 = theNumRows


        for { set index 0 } { $index < $theNumRows} { incr index } {


           # compute membrane shape from measured wavefront, store in
           # 1st element of local V2 vector

           # compute laplacian of membrane shape from membrane shape,
           # store in 2nd element of local V2 vector


	}


        # combine gActuatorPositionV2 and local V2 vector to create
        # output V4 vector

        # dialog "DEBUG Pause Here"


}



#---------------------------------------------------------------------------
# computeModalControlVoltagesAndSendToDACs
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
# Called by: flattenDMUsingModalControl
#
# PROCEDURE IS UNDER CONSTRUCTION
# plk 05/15/2005
#---------------------------------------------------------------------------
proc computeModalControlVoltagesAndSendToDACs { i } \
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




#------------------------------------------------------------------------
# decomposeWavefrontIntoZernikeCoeffs
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
#
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
# FIRST VERSION COMPLETED/DEBUGGED.  MINOR REVISIONS NEED TO BE TESTED/DEBUGGED
# plk 05/02/2005
#---------------------------------------------------------------------------
proc decomposeWavefrontIntoZernikeCoeffs { } \
{
   global gNumberOfZernikeTerms
   global gWavefrontZernikeCoeffsV2

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
                          $thePupilRadius_pix = gWavefrontZernikeCoeffsV2


   # DEBUG
   # convert the coeffs. to strings, and print...
   a.copy gWavefrontZernikeCoeffsV2 = theWavefrontZernikeCoeffsV2
   zern.conv.string theWavefrontZernikeCoeffsV2


}







#------------------------------------------------------------------------
# InflFuncZernikeDecomp
#
# Computes the set of Zernike expansion coefficients corresponding to
# each "poke" of the device made during pokeBinnedActuators_ZernikeDecomp
#
#
# output of this procedure:
#
#
# Called by:  Must call after pokeBinnedActuators_ZernikeDecomp
#
# PROCEDURE IS UNDER CONSTRUCTION
# plk 05/15/2005
#------------------------------------------------------------------------
proc InflFuncZernikeDecomp{ } {

    global gNumberOfActuatorsPerBin

    global Grad gvd CurDrv Drvs Grds MAX_ACT maskArray pokeFraction
    global wlCalibrate YACT_LINE_LENGTH XACT_LINE_LENGTH


    # Do this in higher level function...
    # poke each actuator/binned actuator
    # pokeBinnedActuators_ZernikeDecomp

    # Wavefront information from each "poke" is kept
    # in Grad array.  Use this data to create the Zernike
    # coeff. data



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


             #DEBUG
             puts stdout "InflFuncZernikeDecomp: Binned Actuator: i=$i j=$j"

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

        }
   }



}


