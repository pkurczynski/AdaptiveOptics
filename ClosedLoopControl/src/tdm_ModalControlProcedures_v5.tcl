#------------------------------------------------------------------------
# tdm_ModalControlProcedures.tcl                      tcl script
#
# Procedures used in control of transparent electrode membrane mirror using
# modal control algorithm.
#
# Procedures in this file:
#
#       trainDMForModalControl
#       pokeBinnedActuators_TrainModalControl
#       getWFReconInflFuncPeakPosition
#       findPeakInteractive
#       mouseDownEvent
#       flattenDMUsingModalControl
#       computeMembraneShapeAndLaplacian
#       computeModalControlVoltagesAndSendToDACs
#       decomposeWavefrontIntoZernikeCoeffs
#
# Note:  to initialize procedures in this file with the wavescope
# software, add lines such as the following to the tclIndex.tcl file
# in usr/aos/wavescope/scripts/
#        e.g. set auto_index(decomposeWavefrontZernikeCoeffs) \
#               [list source [file join tdm_ModalControlProcedures.tcl]]
#
# version 5
# plk 05/17/2005
#------------------------------------------------------------------------

# Image display ID for the FINDPEAK image display window.  Used in
# modal control training.
global FINDPEAK_ID

# User selected position of peak in current image.  Used in findPeakInteractive
global double gUserSelectPeakX
global double gUserSelectPeakY


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

    global FINDPEAK_ID
    global gTrainDMForModalControlFlag

    global loopType wlCalibrate stagePos



    #DEBUG
    #dialog "Debug Pause Here"

    if { $wlCalibrate(doneInit) != "Yes" } {
	dialog "Please Calibrate WaveScope."
	return
    }
    stage.calibrate.absolute $stagePos(BestRefSpots)


    pokeBinnedActuators_TrainModalControl
    set gTrainDMForModalControlFlag 1

    # set image display for the findpeak window, used in
    # findPeakInteractive procedure
    id.new FINDPEAK_ID

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
   set gModalControlNumberOfActuatorsPerBin 256

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


             # find the x,y coordinates of the influence function
             # peak centers.  Grad is an array of v4 vectors
             # (x,y, dphi/dx, dphi/dy) containing wavefront data
             getWFReconInflFuncPeakPosition Grad theXYv2

             # DEBUG
             puts stdout "[a.info theXYv2]"
             puts stdout "[a.dump theXYv2]"
             dialog "Debug Pause Here"

             

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
# getWFReconInflFuncPeakPosition
#
# Gets the wavefront recontstructed influence function peak position. Given
# wavefront gradient data from an influence function measurement, this
# procedure reconstructs the wavefront, finds the extremum, corresponding
# to the peak of the wavefront, and returns the X,Y coordinates of this
# peak.
#
#
# input parameter:   inGradV4     column vector array of v4 elements where
#                                 each element is of the form
#                                 < x , y, dphi/dx , dphi/dy >.  This is
#                                 the measured wavefront gradient.
#
# output parameter:  outXYV2      v2 array specifying the x,y coordinates
#                                 of the position where
#                                 abs( (dphi/dx)^2 + (dphi/dy)^2 )
#                                 is a minimum.
#
# (will be) called by:  pokeBinnedActuators_TrainModalControl
# in place of getV4GradientEqZeroPosition
#
# READY FOR TEST/DEBUG AT WAVESCOPE
#
# plk 5/17/2005
#---------------------------------------------------------------------------

proc getWFReconInflFuncPeakPosition { inGradV4 outXYV2 } {

   global wlCalibrate params

   upvar $inGradV4 theGradV4
   upvar $outXYV2 theXYV2

   a.v4tov2v2 $theGradV4 = theXYPosV2 theGradV2

   # create a regular 2D output gradient array and weight mask
   alg.conv.pg.arrays $theGradV2 $wlCalibrate(Params) = theGxGyV2 theMaskArray

   # reconstruct the wavefront from gradient, mask data.  Output is
   # 2D array of floating point values.
   alg.recon.fast theGxGyV2 theMaskArray = theWavefrontSurfaceF

   findPeakInteractive theWavefrontSurfaceF theXYV2

}



#---------------------------------------------------------------------------
# findPeakInteractive
#
# finds the spot(s) / peaks in an array and returns the peak position in
# x,y coordinates as a vector V2.
#
# Uses wavescope atomic functions to perform image segmentation.  Displays
# OPD on an image display window, along with rectangle marking the peak
# identified with this procedure.
#
# parameters   in2DArrayF    input 2D array of float values (i.e. an image,
#                            or a wavefront).
#              outXYV2       output vector V2 of < x, y > column, row
#                            values of the peak in the input array.
#
# called by:  getWFReconInflFuncPeakPosition
#
# plk 5/17/2005
#---------------------------------------------------------------------------

proc findPeakInteractive { in2DArrayF outXYV2 } {

    global FINDPEAK_ID
    global double gUserSelectPeakX
    global double gUserSelectPeakY

    upvar $in2DArrayF theArray
    upvar $outXYV2 theXYV2

     
    # display the current array in the findpeak window
    id.set.array FINDPEAK_ID theArray

    # execute this procedure when user selects a point with the mouse
    id.set.callback FINDPEAK_ID mouseDownEvent

    # find the peak(s) in theArray
    alg.find.rects.slow theArray = theRectArray

    # display the found peak as circumscribing rectangle(s)
    id.set.rect.array FINDPEAK_ID theRectArray

    # parse the rectangle and find the center from (x,y)_upper left and
    # width, height.  theRectArray elements are of the form:
    # < x y w h >.  Units of theXYV2 are row, column of the input array.
    a.v4tov2v2 theRectArray = theRectXY theRectWH

    set theNumRects [a.cols theRectArray]


    a.v2toxy theRectXY = theRectX theRectY
    a.v2toxy theRectWH = theRectW theRectH

    a.mul theRectW 0.5 = theRectHalfW
    a.mul theRectH 0.5 = theRectHalfH

    a.add theRectX theRectHalfW = thePeakCenterX
    a.add theRectY theRectHalfH = thePeakCenterY

    # theXYV2 is the V2 array of <x y> positions of the centers
    # of the peaks found by the segmentation algorithm.
    a.xytov2 thePeakCenterX thePeakCenterY = theXYV2

    # Wait for User to click "OK" after choosing a peak
    # position in the ID window ...
    dialog "Select peak center"

    # clear the callback request (mouse down event handler)
    id.set.callback FINDPEAK_ID " "

    # transfer user selected x,y values of peak position to
    # output parameter of this procedure.

    a.make 0.0 1 = theUserSelectPeakXA
    a.make 0.0 1 = theUserSelectPeakYA

    a.repele $gUserSelectPeakX theUserSelectPeakXA 0 = theUserSelectPeakXA
    a.repele $gUserSelectPeakY theUserSelectPeakYA 0 = theUserSelectPeakYA
    a.xytov2 theUserSelectPeakXA theUserSelectPeakYA = theXYV2

}

#---------------------------------------------------------------------------
# mouseDownEvent
#
# Event handler for the mouseDown event.  Allows user to select a point
# on the active image display.  The X,Y coordinates of the point are
# stored in global variables, and a box is drawn around the selected
# position.  Coordinates are stored in floating point, row, column units.
#
# See wavescope manual entry id.set.callback
#
# parameters:  inID     image display ID
#              inEvent  1 = mouse moved
#                       2 = mouse down
#                       3 = mouse up
#              inX      X coord of event (column, floating point)
#              inY      Y coord of event (row, floating point)
#              inT      Time of event (floating point)
#              inKBD    Keyboard state (mouse mask bits)
#                       1 = button 1
#                       2 = button 2
#                       4 = shift key down
#                       8 = ctrl key down
#
# uses global variables:
#
#             FINDPEAK_ID               Image display ID of window
#             gUserSelectPeakX          floating point, column number of
#                                       user selected position
#             gUserSelectPeakY          floating point, row number of
#                                       user selected position
#
# called by: findPeakInteractive (mouseDown event handler)
#
# 05/17/2005
#---------------------------------------------------------------------------
proc mouseDownEvent { inID inEvent inX inY inT inKBD } {

  global FINDPEAK_ID

  global double gUserSelectPeakX
  global double gUserSelectPeakY


  # If Mouse Down Event ...
  if { $inEvent == 2 } {

       puts stdout "mouseDownEvent: position x=$inX  y=$inY"

       # place a rectangle centered over the mouse image
       set theXL [expr $inX-1]
       set theYL [expr $inY-1]
       set theW 2
       set theH 2
       set theV4Element "<$theXL $theYL $theW $theH>"
       a.make $theV4Element = theRectV4
       id.set.rect.array FINDPEAK_ID theRectV4

       # store user selected x,y coords in global variable
       # for transfer to return parameter of findPeakInteractive
       set gUserSelectPeakX $inX
       set gUserSelectPeakY $inY
  }

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

