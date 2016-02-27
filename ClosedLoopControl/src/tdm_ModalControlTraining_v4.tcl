#------------------------------------------------------------------------
# tdm_ModalControlTraining.tcl                      tcl script
#
# Procedures used in control of transparent electrode membrane mirror using
# modal control algorithm.  Based upon tdm_ModalControlProcedures_v12.tcl
# which is its predecessor.
#
# Procedures in this file:
#       initDMTraining
#       trainDM
#           trainBinnedActuator
#           takeMeasurementAtCurrentTrainingPoint
#           sendCurrentTrainingVoltagesToDACs
#           reconstructCurrentWavefront
#           decomposeWavefrontIntoZernikeCoeffs
#           getXYPositionOfBinnedActuator
#           computeWavefrontAndLaplacian
#       testDecomposeWavefrontIntoZernikeCoeffs
#       computeMembraneShapeAndLaplacian
#
#
# Note:  to initialize procedures in this file with the wavescope
# software, add lines such as the following to the tclIndex.tcl file
# in usr/aos/wavescope/scripts/
#        e.g. set auto_index(decomposeWavefrontZernikeCoeffs) \
#               [list source [file join tdm_ModalControlProcedures.tcl]]
#
# version 4
# plk 06/24/2005
#------------------------------------------------------------------------


# Flag is set to 1 upon training.  Must be set prior to closed loop operation.
# See tdm_ModalControlCalibration_v<4+>.tcl for other operation flags.
global gTrainDMForModalControlFlag


global gNumberOfMeasurementsAtTrainingPoint

# arrays for storing the actuator, membrane voltage values to use during
# DM training measurements.  Set in initDMTraining

global gActuatorTrainingVoltageV4
global gMembraneTrainingVoltageV4

# electrode i,j values of current binned actuator
# center, of current electrode (during DMTraining)
global gCurrentTrainingPointIJV2

# Membrane shape and Laplacian, computed at actuator center positions
# < xi  yi   xi(xi,yi)   del2 xi(xi,yi) >
# See computeMembraneShapeAndLaplacian
global gMembraneShapeV4


#---------------------------------------------------------------------------
# initDMTraining
#
# Initializes DM training procedure.  Uses procedures from calibPoint.dll
# calibPoint.dll must have been loaded into Tcl/wish prior to executing
# this procedure.
#
# called by:  displayDMTrainingPanel
# plk 06/10/2005
#---------------------------------------------------------------------------
proc initDMTraining { } \
{
    global gNumberOfMeasurementsAtTrainingPoint
    global gNumberOfBinnedActuators

    global gActuatorTrainingVoltageV4
    global gMembraneTrainingVoltageV4


    set gNumberOfMeasurementsAtTrainingPoint 3

    # DEBUG VALUE:  Normally this variable is set
    # during ModalControlCalibration
    set gNumberOfBinnedActuators 100

    # assume square binned actuators, symmetrical array
    set theNumBARows [expr int(sqrt($gNumberOfBinnedActuators))]
    set theNumBACols [expr int(sqrt($gNumberOfBinnedActuators))]



    # allocate arrays for measurement voltage values
    # inital values are the voltages at which measurements
    # will be made (actuator and membrane).  Initialization
    # is a v4 vector, assuming 4 or less measurements per
    # binned actuator.

    a.make "<10 20 30 0>" \
           $theNumBACols \
           $theNumBARows \
           = gActuatorTrainingVoltageV4

    a.make "<0 0 10 0>" \
           $theNumBACols \
           $theNumBARows \
           = gMembraneTrainingVoltageV4


    # DEBUG
    #puts stdout "initDMTraining: [a.info gMembraneTrainingVoltageV4]"


    # initialize the calibration computations.  calibPoint.dll
    # must have been previously loaded.  See CalibPoint.c for
    # details on these procedures.

    set theSendCalibPointOutputToFile 1
    initCalibPointComputations $gNumberOfMeasurementsAtTrainingPoint \
                               $theSendCalibPointOutputToFile

    puts stdout "initDMTraining: completed."
}




#---------------------------------------------------------------------------
# trainDM
#
#
#
#
# UNDER CONSTRUCTION
#
# Called by: displayDMTrainingPanel
#
# plk 06/13/2005
#---------------------------------------------------------------------------
proc trainDM { } \
{
    global gRegisterCoordsForModalControlFlag
    global gCalibrateDMForModalControlFlag
    global gTrainDMForModalControlFlag

    global gNAPerSide
    global gModalControlNumberOfActuatorsPerBin
    global gActuatorPositionV4
    global gCurrentTrainingPointIJV2

    global wlCalibrate
    global YACT_LINE_LENGTH XACT_LINE_LENGTH


    if { $wlCalibrate(doneInit) != "Yes" } {
	dialog "Please Calibrate WaveScope."
	return
    }

    if { $gRegisterCoordsForModalControlFlag != 1 } {
	dialog "Please Register Coordinates."
	return
    }

    if { $gCalibrateDMForModalControlFlag != 1 } {
	dialog "Calibrate DM."
	return
    }



   # DEBUG VALUES ONLY
   set XACT_LINE_LENGTH 37
   set YACT_LINE_LENGTH 37


   # set the parameters for the binning of actuators based on
   # the number of actuators per bin.
   #
   # why is this a global variable?
   set gModalControlNumberOfActuatorsPerBin [expr $gNAPerSide * $gNAPerSide]

   # for N X N binning of actuators
   # theNumberOfActuatorsPerBin = N*N
   set theNumberOfActuatorsPerBin $gModalControlNumberOfActuatorsPerBin

   set theIBinWidth [expr int(sqrt($theNumberOfActuatorsPerBin))]
   set theJBinWidth [expr int(sqrt($theNumberOfActuatorsPerBin))]

   # binned actuator i,j indices:  0 ... <num. binned actuators per side> - 1
   set theBAI 0
   set theBAJ 0


   # loop over the actuators in the array, modulo binning
   # i,j determines actuator at the bin center (odd binning) or
   # the actuator to the immediate "lower left" of bin center (even binning).
   for { set i 0 } { $i < $XACT_LINE_LENGTH } { incr i $theIBinWidth } {

        set theBAJ 0
        for { set j 0 } { $j < $YACT_LINE_LENGTH } { incr j $theJBinWidth } {


            a.make "<$i $j>" = gCurrentTrainingPointIJV2

            #DEBUG
            puts stdout "trainDM: Binned Actuator: i=$i j=$j"

            trainBinnedActuator $theBAI $theBAJ
            incr theBAJ
        }

        incr theBAI
   }


   set gTrainDMForModalControlFlag 1
   puts stdout "trainDM: completed."
}


#---------------------------------------------------------------------------
# trainBinnedActuator
#
# called by:  trainDM
#
# plk 06/13/2005
#---------------------------------------------------------------------------
proc trainBinnedActuator { inI  inJ } \
{
   global gNumberOfMeasurementsAtTrainingPoint
   global gActuatorTrainingVoltageV4
   global gMembraneTrainingVoltageV4



   # parse the V4 arrays with voltage information
   a.extele gActuatorTrainingVoltageV4 $inI $inJ = \
        theActuatorTrainingVoltageV4
   a.extele gMembraneTrainingVoltageV4 $inI $inJ = \
        theMembraneTrainingVoltageV4

   # convert V4 to scalar, floating point vector
   a.to theActuatorTrainingVoltageV4 f = theActuatorTrainingVoltageF
   a.to theMembraneTrainingVoltageV4 f = theMembraneTrainingVoltageF


   # take a set of measurements for training
   for { set k 0 } { $k < $gNumberOfMeasurementsAtTrainingPoint } { incr k } {

        # get actuator voltage, membrane voltage for this measurement
        a.extele theActuatorTrainingVoltageF $k = theActuatorVoltageS
        a.extele theMembraneTrainingVoltageF $k = theMembraneVoltageS
        set theActuatorVoltage [a.dump theActuatorVoltageS]
        set theMembraneVoltage [a.dump theMembraneVoltageS]


        # take one measurement at specified voltage setting
        takeMeasurementAtCurrentTrainingPoint \
                $theActuatorVoltage \
                $theMembraneVoltage

   }



}


#---------------------------------------------------------------------------
# takeMeasurementAtCurrentTrainingPoint
#
# called by: trainBinnedActuator
#---------------------------------------------------------------------------
proc takeMeasurementAtCurrentTrainingPoint { inActuatorVoltage \
                                             inMembraneVoltage } \
{
    global Grad
    global gCurrentTrainingPointIJV2

    a.make 0.0 4 = theCalibPointInputDataF
    set theWavefront_um 0.0
    set theLaplacian_OneByum 0.0
    a.make "<0 0>" = theXYV2


    # Send voltages to the DACs
    # This procedure activates the hardware DACs.  Be careful.
    #sendCurrentTrainingVoltagesToDACs $inActuatorVoltage $inMembraneVoltage


    # insert 500 ms wait time here for membrane to settle.
    #after 500

    # take WFS measurement.
    set theNumberOfFramesToAverage 3
    calcGrad $theNumberOfFramesToAverage


    # decompose current wavefront into Zernikes.  This
    # procedure is called with the wavefront gradient
    # as the input parameter, not the wavefront itself.
    decomposeWavefrontIntoZernikeCoeffs Grad theZernikeCoeffsV2

    # get x,y coordinates (on wavefront surface) corresponding
    # to i,j values of current binned actuator.  Correspondence
    # made during ModalControlCalibration and stored in lookup
    # table gActuatorPosition_ImagPixV4

    getXYPositionOfBinnedActuator gCurrentTrainingPointIJV2 theXYV2
    a.v2toxy theXYV2 = theXA theYA
    set theX_ImagPix [a.dump theXA]
    set theY_ImagPix [a.dump theYA]

    puts stdout "trainBinnedActuator:"
    puts stdout "[a.dump gCurrentTrainingPointIJV2]"
    
    computeWavefrontAndLaplacian theX_ImagPix  \
                                 theY_ImagPix \
                                 theZernikeCoeffsV2 \
                                 theWavefront_um \
                                 theLaplacian_OneByum


    # store wavefront (xi), del2 xi, Va, Vm in CalibPointInputDataF
    a.repele $theWavefront_um \
             theCalibPointInputDataF 0 = theCalibPointInputDataF
    a.repele $theLaplacian_OneByum \
             theCalibPointInputDataF 1 = theCalibPointInputDataF
    a.repele $inActuatorVoltage \
             theCalibPointInputDataF 2 = theCalibPointInputDataF
    a.repele $inMembraneVoltage \
             theCalibPointInputDataF 3 = theCalibPointInputDataF

    #DEBUG
    #puts stdout "takeMeasurementAtCurrentTrainingPoint: theCalibPointInputDataF"
    #puts stdout "[a.dump theCalibPointInputDataF]"






}



#---------------------------------------------------------------------------
# sendCurrentTrainingVoltagesToDACs
#
# called by: takeMeasurementAtCurrentTrainingPoint
#
# completed.  Needs debugging.
#
# plk 6/13/2005
#---------------------------------------------------------------------------
proc sendCurrentTrainingVoltagesToDACs { inActuatorVoltage \
                                         inMembraneVoltage } \
{
    global gCurrentTrainingPointIJV2


    a.v2toxy gCurrentTrainingPointIJV2 = theIA theJA
    set theCurrentTrainingPointI [a.dump theIA]
    set theCurrentTrainingPointJ [a.dump theJA]


    # Actuate device:  Put voltage on the membrane, and on
    # the current binned actuator.  Send voltages to the
    # hardware / DACs

    # this procedure is tcl wrapper around low level C code.
    # see file:  ****.c for details.
    tdm1k.pokemembrane $inMembraneVoltage

    # this procedure is implemented in ActuateTEMembraneDevice_v7.tcl

    # row, column confusion here?  Should I-->row J-->column or vice versa?
    # plk 6/13/2005
    pokeNxNbin $theCurrentTrainingPointI \
               $theCurrentTrainingPointJ \
               $gNAPerSide \
               $inActuatorVoltage


}


#---------------------------------------------------------------------------
# reconstructCurrentWavefront
#
# reconstructs a wavefront from the current gradient data, measured
# by the wavescope.  These data are stored in the global array Grad
#
#
# called by: takeMeasurementAtCurrentTrainingPoint
#
# completed.  Needs debugging.
#
# 6/13/2005
#---------------------------------------------------------------------------
proc reconstructCurrentWavefront { outWavefrontSurfaceF } \
{
    global Grad
    global wlCalibrate


    upvar $outWavefrontSurfaceF theWavefrontSurfaceF

    stage.calibrate.absolute $stagePos(BestRefSpots)
    a.v4tov2v2 $Grad = theXYPosV2 theGradV2

    # create a regular 2D output gradient array and weight mask
    alg.conv.pg.arrays $Grad $wlCalibrate(Params) = theGxGyV2 theMaskArray

    # reconstruct the wavefront from gradient, mask data.  Output is
    # 2D array of floating point values.
    alg.recon.fast theGxGyV2 theMaskArray = theWavefrontSurfaceF

}


#------------------------------------------------------------------------
# decomposeWavefrontIntoZernikeCoeffs
#
# Decomposes the input wavefront gradient into a wavefront characterized
# by N Zernike coefficients
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
# Called by:  takeMeasurementAtCurrentTrainingPoint
#
# completed.  Needs debugging.  Note test<...> was completed/debugged.
#
# modified procedure to take pupil x,y radius from wlCalibrate(Pupil)
# rather than "figuring it out" separately.
#
# plk 06/24/2005
#---------------------------------------------------------------------------
proc decomposeWavefrontIntoZernikeCoeffs {inWavefrontGradient \
                                          outZernikeCoeffsV2} \
{
   global wlCalibrate

   upvar $inWavefrontGradient theWavefrontGradientF
   upvar $outZernikeCoeffsV2 theWavefrontZernikeCoeffsV2

   set theNumberOfZernikeTerms 35



   # get x,y center of current image plane from calibration data
   #a.ave wlCalibrate(FinalCenters) = theSamplePositions_avg_V2
   #a.v2toxy theSamplePositions_avg_V2 = theCenterColumn_V0 theCenterRow_V0
   #set theCenterRow [a.dump theCenterRow_V0]
   #set theCenterColumn [a.dump theCenterColumn_V0]

   a.extele wlCalibrate(Pupil) 0 = theCenterColumnA
   a.extele wlCalibrate(Pupil) 1 = theCenterRowA
   a.extele wlCalibrate(Pupil) 2 = thePupilRadiusA

   set theCenterColX_ImagPix [a.dump theCenterColumnA]
   set theCenterRowY_ImagPix [a.dump theCenterRowA]
   set thePupilRadius_ImagPix [a.dump thePupilRadiusA]


   # Use the value of pupil radius that will center the wavefront
   # over the sampled area of the spot image plane.
   # NOTE:  This value of pupil radius assumes that image radius is
   # closely aligned with membrane radius.
   # set thePupilRadius_pix [expr $theCenterRow - 0.01*$theCenterRow]
   # set thePupilRadius_pix [expr $theCenterRow ]

   # DEBUG
   # typical values (determined during WFS calibration)
   # CenterRow         242.88
   # CenterCol         358.34
   # Radius (pix)      240
   # plk 5/2/2005

   #puts "theCenterRowY_ImagPix     = $theCenterRowY_ImagPix"
   #puts "theCenterColX_ImagPix     = $theCenterColX_ImagPix"
   #puts "thePupilRadius_ImagPix    = $thePupilRadius_ImagPix"


   # wavefront gradients stored in Grad array (v4), which is
   # populated during a WFS measurment called by calcGrad
   zern.decomp.grad.coefs $theWavefrontGradientF \
                          $theNumberOfZernikeTerms \
                          $theCenterColX_ImagPix \
                          $theCenterRowY_ImagPix \
                          $thePupilRadius_ImagPix \
                          = theWavefrontZernikeCoeffsV2


   #DEBUG
   #puts stdout "decomposeWavefrontIntoZernikeCoeffs:"
   #puts stdout "[a.dump theWavefrontZernikeCoeffsV2]"
   
}


#------------------------------------------------------------------------
# getXYPositionOfBinnedActuator
#
# Search the gActuatorPosition_ImagPixV4 array for the x,y position
# corresponding to the input i,j index values.
#
# parameters:  inIJA        V2 array of i,j indices of the binned actuator
#                           of interest.
#
#              outXYA_mm    V2 array of x,y values of the corresponding
#                           actuator.  These coordinates depend upon
#                           the DM calibration.
#
# NOTE:  DM calibration must be done prior to executing this procedure.
#        This procedure uses the global array gActuatorPositionV4
#
# tested with command line / wish shell.
# re-tested with command line /wish shell. ok. 6/24/2005.
#
# called by: takeMeasurementAtCurrentTrainingPoint
#
# 6/24/2005
#------------------------------------------------------------------------
proc getXYPositionOfBinnedActuator { inIJA outXYA_ImagPix } \
{
   global gActuatorPosition_ImagPixV4
   global gCurrentTrainingPointIJV2


   upvar $outXYA_ImagPix theXYA_mm
   upvar $inIJA theIJA

   a.rows gActuatorPosition_ImagPixV4 = theNumRowsA
   set theNumRows [a.dump theNumRowsA]

   #DEBUG
   #puts stdout "getXYPositionOfBinnedActuator:"

   for { set k 0 } { $k < $theNumRows } { incr k } {

        # When gActuatorPosition_ImagPixV4 is formed using wish shell,
        # the array has 1 dimension, N columns.  a.extele should then
        # be called with a single argument.
        #
        # When gActuatorPosition_ImagPixV4 is formed using the scripts/
        # software, it is a 2D array:  1 column and N rows.  Therefore
        # a.extele must be called with two arguements (1st one "0")

        a.extele gActuatorPosition_ImagPixV4 0 $k = theTestActuatorPositionV4
        a.v4tov2v2 theTestActuatorPositionV4 = theTestIJA theTestXYA
        a.sub theIJA theTestIJA = theTestDiffA

        #DEBUG
        #puts stdout "Searching for value: [a.dump theIJA]"
        #puts stdout "The current test value: [a.dump theTestIJA]"
        #puts stdout "The difference: [a.dump theTestDiffA]"


        a.v2toxy theTestDiffA = theTestDIA theTestDJA
        set theTestDI [a.dump theTestDIA]
        set theTestDJ [a.dump theTestDJA]

        if { $theTestDI == 0 && $theTestDJ == 0 } {
           a.repele theTestXYA theXYA_mm = theXYA_mm
           return
        }
   }

   # if no match is found return an error
   error getXYPositionOfBinnedActuator_NoMatch
}



#------------------------------------------------------------------------
# computeWavefrontAndLaplacian
#
#
# under construction
#
# called by: takeMeasurementAtCurrentTrainingPoint
#
# 6/13/2005
#------------------------------------------------------------------------
proc computeWavefrontAndLaplacian { inX_ImagPix  \
                                    inY_ImagPix \
                                    inZernikeCoeffsV2 \
                                    outWavefront_um \
                                    outLaplacian_OneByum } \
{
  upvar $outWavefront_um theWavefront_um
  upvar $outLaplacian_OneByum theLaplacian_OneByum
  upvar $inX_ImagPix theX_ImagPix
  upvar $inY_ImagPix theY_ImagPix


  set theWavefront_um 7.0
  set theLaplacian_OneByum 8.0

  #DEBUG
  puts stdout "computeWavefrontAndLaplacian: X,Y = $theX_ImagPix , $theY_ImagPix"


}



#------------------------------------------------------------------------
# testDecomposeWavefrontIntoZernikeCoeffs
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
proc testDecomposeWavefrontIntoZernikeCoeffs { } \
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
        global gActuatorPositionV4


        a.rows gActuatorPositionV4 = theNumRows


        for { set index 0 } { $index < $theNumRows} { incr index } {


           # compute membrane shape from measured wavefront, store in
           # 1st element of local V2 vector

           # compute laplacian of membrane shape from membrane shape,
           # store in 2nd element of local V2 vector


	}


        # combine gActuatorPositionV4 and local V2 vector to create
        # output V4 vector

        # dialog "DEBUG Pause Here"


}
