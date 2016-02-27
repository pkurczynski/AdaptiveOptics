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
# version 8
# plk 06/29/2005
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

# arrays for storing device parameters at each
# electrode position on the membrane.  Initialized
# in initDMTraining
global gMembraneTension_NByMA
global gMembrArrayDist_umA
global gMembrTEDist_umA

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
    global gRegisterCoordsForModalControlFlag
    global gCalibrateDMForModalControlFlag
    global gTrainDMForModalControlFlag

    global gNumberOfMeasurementsAtTrainingPoint

    global gMembraneTension_NByMA
    global gMembrArrayDist_umA
    global gMembrTEDist_umA

    global gActuatorTrainingVoltageV4
    global gMembraneTrainingVoltageV4

    global YACT_LINE_LENGTH
    global XACT_LINE_LENGTH
    global wlCalibrate


    if { $wlCalibrate(doneInit) != "Yes" } {
	dialog "Please Calibrate WaveScope."
	return
    }

    if { $gRegisterCoordsForModalControlFlag != 1 } {
	dialog "Please Register Coordinates."
	return
    }

    if { $gCalibrateDMForModalControlFlag != 1 } {
	dialog "Please Calibrate DM."
	return
    }

    # Number of wavefront measurements at each
    # binned electrode position on the membrane.
    set gNumberOfMeasurementsAtTrainingPoint 3


    set theMaxNumberOfBinnedActuators 1032

    # assume square binned actuators, symmetrical array
    set theNumBARows [expr int(sqrt($theMaxNumberOfBinnedActuators))]
    set theNumBACols [expr int(sqrt($theMaxNumberOfBinnedActuators))]



    # allocate arrays for measurement voltage values
    # initial values are the voltages at which measurements
    # will be made (actuator and membrane).  Initialization
    # is a v4 vector, assuming 4 or less measurements per
    # binned actuator.

    # e.g. if gActuatorTrainingVoltageV4 = <10 15 20 0>
    # and  if gMembraneTrainingVoltageV4 = < 0  0 10 0>
    # then training measurements will be made as follows:
    # Measurement    Actuator         Membrane
    #   Number        Voltage          Voltage
    #  ----------    ---------        --------
    #     1             10               0
    #     2             15               0
    #     3             20              10
    #     4*             0               0
    #
    # *only if 4 measurements per binned actuator are specified
    # (normally 3 measurements per binned actuator).  See
    # gNumberOfMeasurementsAtTrainingPoint above in this procedure.
    
    a.make "<10 15 20 0>" \
           $theNumBACols \
           $theNumBARows \
           = gActuatorTrainingVoltageV4

    a.make "<0 0 10 0>" \
           $theNumBACols \
           $theNumBARows \
           = gMembraneTrainingVoltageV4


    # DEBUG
    #puts stdout "initDMTraining: [a.info gMembraneTrainingVoltageV4]"



    # arrays for storing position dependent membrane parameters
    a.make "0" $XACT_LINE_LENGTH $YACT_LINE_LENGTH = gMembraneTension_NByMA
    a.make "0" $XACT_LINE_LENGTH $YACT_LINE_LENGTH = gMembrArrayDist_umA
    a.make "0" $XACT_LINE_LENGTH $YACT_LINE_LENGTH = gMembrTEDist_umA


    # initialize the calibration computations.  calibPoint.dll
    # must have been previously loaded.  See CalibPoint.c for
    # details on these procedures.

    # By default, wavescope writes the calibPointLogFile.txt to
    # the C:/Winnt directory.  The file is written upon calling
    # exitCalibPointComputations in trainDM below.
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
   global gNAPerSide
   global gModalControlNumberOfActuatorsPerBin
   global gCurrentTrainingPointIJV2


   global YACT_LINE_LENGTH
   global XACT_LINE_LENGTH



   # DEBUG VALUES ONLY
   #set XACT_LINE_LENGTH 37
   #set YACT_LINE_LENGTH 37


   # set the parameters for the binning of actuators based on
   # the number of actuators per bin.
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

   # Write log data to c:\Winnt\calibPointLogFile.txt
   # and close the open log file
   exitCalibPointComputations

   set gTrainDMForModalControlFlag 1
   puts stdout "trainDM: completed."
}


#---------------------------------------------------------------------------
# trainBinnedActuator
#
# under construction
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

   global gMembraneTension_NByMA
   global gMembrArrayDist_umA
   global gMembrTEDist_umA
   global gCurrentTrainingPointIJV2



   a.make 0.0 1 4 = theCalibPointInputDataF

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
                $theMembraneVoltage \
                theCalibPointInputDataF


        # populate the theCalibPointInputDataArrayF
        # with the input parameters generated by the
        # current measurement:  xi, Dxi, Va, Vm.
        # Finally, DataArrayF should have
        # $gNumberOfMeasurementsAtTrainingPoint cols.
        if { $k == 0 }\
        {
                a.copy theCalibPointInputDataF = theCalibPointInputDataArrayF
        } else \
        {
                a.catcol theCalibPointInputDataArrayF \
                         theCalibPointInputDataF \
                         = theCalibPointInputDataArrayF
        }

   }

   # execute nonlinear solver with input parameters determined
   # by training measurements.  This solver determines the local
   # membrane stress, and both gap distances.  Store these output
   # parameters in global arrays for access by closed loop routine.
   #
   # NOTE: the solver is implemented in C and compiled as a dll
   # for use with Tcl.  calibPoint.dll must have been loaded in
   # Tcl prior to executing the solver.
   set theMembrArrayDist_um 0
   set theMembrTEDist_um 0
   set theTension_NByM 0

   solveForDeviceParamsAtCalibPoint theCalibPointInputDataArrayF \
                                    theMembrArrayDist_um \
                                    theMembrTEDist_um \
                                    theTension_NByM


   # absolute row, column of current binned electrode
   # center.  Not to be confused with the binned
   # electrode indices inI, inJ.  theI, theJ ... [0,37]
   a.v2toxy gCurrentTrainingPointIJV2 = theI theJ

   # populate global arrays with local device params.
   a.repele $theTension_NByM \
            gMembraneTension_NByMA \
            theI \
            theJ \
            = gMembraneTensioN_NByMA

   a.repele $theMembrArrayDist_um \
            gMembrArrayDist_umA \
            theI \
            theJ \
            = gMembrArrayDist_umA

   a.repele $theMembrTEDist_um \
            gMembrTEDist_umA \
            theI \
            theJ \
            = gMembrTEDist_umA

}


#---------------------------------------------------------------------------
# takeMeasurementAtCurrentTrainingPoint
#
# called by: trainBinnedActuator
#---------------------------------------------------------------------------
proc takeMeasurementAtCurrentTrainingPoint { inActuatorVoltage \
                                             inMembraneVoltage \
                                             outCalibPointInputDataF } \
{
    global wlCalibrate
    global Grad
    global gCurrentTrainingPointIJV2

    upvar $outCalibPointInputDataF theCalibPointInputDataF


    set theWavefront_um 0.0
    set theLaplacian_OneByum 0.0
    a.make "<0 0>" = theXYV2


    # Send voltages to the DACs
    # This procedure activates the hardware DACs.  Be careful.
    sendCurrentTrainingVoltagesToDACs $inActuatorVoltage $inMembraneVoltage


    # insert XXX ms wait time here for membrane to settle.
    set theSettleTime_ms 5000
    #after $theSettleTime_ms

    dialog "OK to continue."


    #DEBUG
    puts stdout "takeMeasurementAtCurrentTrainingPoint:"
    puts stdout "   waiting $theSettleTime_ms milliseconds before measurement."

    # take WFS measurement.
    set theNumberOfFramesToAverage 3
    calcGrad $theNumberOfFramesToAverage

    # allocate arrays for wavefront and laplacian
    # to be compatible with wfs measurement data.
    a.rows Grad = theNumRows
    a.cols Grad = theNumCols
    a.make "0" theNumCols theNumRows = theWavefrontF
    a.make "0" theNumCols theNumRows = theLaplacianF

    #DEBUG
    #generateZernikeWavefrontGradient 3 Grad


    # compute the wavefront using standard wavefront reconstruction
    computeWavefrontByWavescopeMethod Grad theWavefrontF theLaplacianF

    #DEBUG
    #testWavefrontComputation theWavefrontF theLaplacianF

    # alternate method of wavefront computation:  Zernike series computation
    #computeWavefrontByZernikeMethod Grad theWavefrontF theLaplacianF



    # get x,y coordinates (on wavefront surface) corresponding
    # to i,j values of current binned actuator.  Correspondence
    # made during ModalControlCalibration and stored in lookup
    # table gActuatorPosition_ImagPixV4

    getXYPositionOfBinnedActuator gCurrentTrainingPointIJV2 theXYV2

    #DEBUG
    puts stdout \
         "takeMeasurementAtCurrentTrainingPoint: gCurrentTrainingPointIJV2"
    puts stdout "[a.dump gCurrentTrainingPointIJV2]"

    EvaluateWavefrontAndLaplacianAtPosition theXYV2 \
                                            theWavefrontF \
                                            theLaplacianF \
                                            theWavefrontValue_um \
                                            theLaplacianValue_OneByum



    # store wavefront (xi), del2 xi, Va, Vm in CalibPointInputDataF
    a.repele $theWavefrontValue_um \
             theCalibPointInputDataF 0 0 = theCalibPointInputDataF
    a.repele $theLaplacianValue_OneByum \
             theCalibPointInputDataF 0 1 = theCalibPointInputDataF
    a.repele $inActuatorVoltage \
             theCalibPointInputDataF 0 2 = theCalibPointInputDataF
    a.repele $inMembraneVoltage \
             theCalibPointInputDataF 0 3 = theCalibPointInputDataF

    #DEBUG
    puts stdout "takeMeasurementAtCurrentTrainingPoint: theCalibPointInputDataF"
    puts stdout "[a.dump theCalibPointInputDataF]"




    setzero

    #DEBUG
    puts stdout "takeMeasurementAtCurrentTrainingPoint: voltages set to zero."
    #puts stdout "   waiting $theSettleTime_ms milliseconds before measurement."

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
    global gNAPerSide

    a.v2toxy gCurrentTrainingPointIJV2 = theIA theJA
    set theCurrentTrainingPointI [a.dump theIA]
    set theCurrentTrainingPointJ [a.dump theJA]

    #DEBUG
    puts stdout "sendCurrentTrainingVoltagesToDACs:"
    puts stdout "i,j: $theCurrentTrainingPointI, $theCurrentTrainingPointJ"

    # Actuate device:  Put voltage on the membrane, and on
    # the current binned actuator.  Send voltages to the
    # hardware / DACs

    # this procedure is tcl wrapper around low level C code.
    # see file:  ****.c for details.
    tdm1k.pokemembrane $inMembraneVoltage

    # this procedure is implemented in ActuateTEMembraneDevice_v7.tcl

    # Don't get row/column confused here.  The first argument to this
    # procedure is "I" which are called "columns" in the wavescope
    # software.  These correspond to "x" values in the i,j <--> x,y
    # coordinate transformations.  the "I" value is the first argument
    # in all procedures within these scripts (both wavescope and those
    # written by plk).  7/5/2005.
    pokeNxNbin $theCurrentTrainingPointI \
               $theCurrentTrainingPointJ \
               $gNAPerSide \
               $inActuatorVoltage


}






#------------------------------------------------------------------------
# computeWavefrontByWavescopeMethod
#
# Computes wavefront and laplacian of the wavefront at points within the
# pupil based upon wavescope method of reconstruction.  Laplacian is
# determined by taking the divergence of the wavefront gradient.
#
# parameters: inGradV4  wavefront gradient data determined by the WFS,
#                       e.g. in call to calcGrad
#             outWavefrontF  scalar array of wavefront data.  Units?
#             outLaplacianF  scalar array of laplacian of wavefront.  Units?
#
# called by: takeMeasurementAtCurrentTrainingPoint
#
# under construction
# 6/28/2005
#------------------------------------------------------------------------
proc computeWavefrontByWavescopeMethod {inGradV4 outWavefrontF outLaplacianF } \
{
   global wlCalibrate params

   upvar $inGradV4 theGradV4
   upvar $outWavefrontF theWavefrontSurfaceF
   upvar $outLaplacianF theLaplacianF


   # create a regular 2D output gradient array and weight mask
   alg.conv.pg.arrays $theGradV4 \
                      $wlCalibrate(Params) \
                      = theGxGyV2 theMaskArray


   # reconstruct the wavefront from gradient, mask data.
   # Output is 2D array of floating point values.
   alg.recon.fast theGxGyV2 theMaskArray = theWavefrontSurfaceF

   # compute Laplacian of wavefront by computing
   # the divergence of the gradient
   divergence theGxGyV2 theLaplacianF

}



#------------------------------------------------------------------------
# computeWavefrontByZernikeSeries
#
# Computes an array for the wavefront and laplacian of the wavefront
# at points within the pupil based upon specified Zernike coefficients
#
# under construction
#
# called by: takeMeasurementAtCurrentTrainingPoint
#
# 6/28/2005
#------------------------------------------------------------------------
proc computeWavefrontByZernikeSeries {inGradV4 outWavefrontF outLaplacianF } \
{
  global wlCalibrate

  upvar $inGradV4 theGrad
  upvar $outWavefrontF theWavefrontSurfaceF
  upvar $outLaplacianF theLaplacianF


  #DEBUG
  #puts stdout "computeWavefrontAndLaplacianByZernikeSeries:"




  # NOTE:  Must define theZernikeCoeffsV2 as a V2 array
  # before calling decomposeWavefrontIntoZernikeCoeffs below!



  # decompose current wavefront into Zernikes.  This
  # procedure is called with the wavefront gradient
  # as the input parameter, not the wavefront itself.
  decomposeWavefrontIntoZernikeCoeffs theGrad theZernikeCoeffsV2



  # =====================================================
  # compute column, row info from calibration data. For
  # use in wavescope atomic function zern.make.surf.coefs.
  #======================================================
  a.extele wlCalibrate(Pupil) 0 = thePupilXCenterA
  a.extele wlCalibrate(Pupil) 1 = thePupilYCenterA
  a.extele wlCalibrate(Pupil) 2 = thePupilRadiusA

  a.xytov2 thePupilXCenterA thePupilYCenterA = thePupilXYCenter_ImagPixV2
  a.xytov2 thePupilRadiusA thePupilRadiusA = thePupilRadius_ImagPixV2

  alg.conv.xy.ij wlCalibrate(Params) \
                 thePupilXYCenter_ImagPixV2 \
                 = thePupilXYCenter_GridV2

  alg.conv.xy.ij wlCalibrate(Params) \
                 thePupilRadius_ImagPixV2 \
                 = thePupilRadius_GridV2

  a.v2toxy thePupilXYCenter_GridV2 = thePupilXCenter_GridA thePupilYCenter_GridA
  a.v2toxy thePupilRadius_GridV2 = thePupilRadius_GridA theDummyValue

  set thePupilXCenter_Grid [a.dump thePupilXCenter_GridA]
  set thePupilYCenter_Grid [a.dump thePupilYCenter_GridA]
  set thePupilRadius_Grid [a.dump thePupilRadius_GridA]


  # max. column, row are determined assuming a 640x480 pixel
  # ccd field of view.
  a.make "<640 480>" = theCCDPixelV2
  alg.conv.xy.ij wlCalibrate(Params) theCCDPixelV2 = theMaxColRow_Grid
  a.v2toxy theMaxColRow_Grid = theMaxCol_GridA theMaxRow_GridA
  set theMaxCol_Grid [a.dump theMaxCol_GridA]
  set theMaxRow_Grid [a.dump theMaxRow_GridA]

  #=========================================================
  # make the surface as a sum of zernike terms, computed
  # in the _Grid coordinate system (column --> X; row --> y)
  #=========================================================
  zern.make.surf.coefs theZernikeCoeffsV2 \
                       theMaxCol_Grid \
                       theMaxRow_Grid \
                       thePupilXCenter_Grid \
                       thePupilYCenter_Grid \
                       thePupilRadius_Grid \
                       = theWavefrontSurfaceF


  #=========================================================
  # compute the laplacian of the wavefront here.
  #=========================================================


}




#------------------------------------------------------------------------
# generateZernikeWavefrontGradient
#
# generates a Zernike wavefront gradient.  See comments for procedure
# testWavefrontComputation below for more information.
#
# parameters:
#              inZernikeModeNumber   integer Zernike Mode Number
#              ioGrad      Gradient array resulting from wfs
#                          measurement.  On output, this array is
#                          populated with test data.
#
# called by: takeMeasurementAtCurrentTrainingPoint (DEBUG)
#
# 6/29/2005
#------------------------------------------------------------------------
proc generateZernikeWavefrontGradient { inZernikeModeNumber ioGrad } \
{

    global wlCalibrate

    upvar $ioGrad theGrad


    a.v4tov2v2 theGrad = theXYV2 theGradV2
    a.make "4" = theZernikeModeNumber
    a.extele wlCalibrate(Pupil) 0 = theCenterCol
    a.extele wlCalibrate(Pupil) 1 = theCenterRow
    a.extele wlCalibrate(Pupil) 2 = thePupilRadius

    zern.make.grad theXYV2 \
                   $inZernikeModeNumber \
                   theCenterCol \
                   theCenterRow \
                   thePupilRadius \
                   = theGrad

}



#------------------------------------------------------------------------
# testWavefrontComputation
#
# Displays an image of the wavefront and prints diagnostic information
# about the wavefront data array to the wish console.  Ditto the laplacian.
#
# This procedure was used in conjunction with generateZernikeWavefrontGradient
# to generate test data and evaluate the computation of the wavefront and
# laplacian ( i.e. to test the procedure computeWavefrontByWavescopeMethod )
# Here is a synopsis of results:
#
# TEST RESULTS
#
# ZYGO Zernike Mode number indicated below
# Zernike Mode  PV Wavefront  PV Lapl   Expctd PV Lapl.   Notes
# ------------  ------------  -------   ---------------   -----------------
#  10 trefoil         33 (um)       5            0    Lapl. nonzero at edge
#   8 focus           40           54          !=0
#  other non sph.                  ~5            0    Lapl. nonzero at edge
#
#
#
# parameters:
#
# called by: takeMeasurementAtCurrentTrainingPoint (DEBUG)
#
# 6/29/2005
#------------------------------------------------------------------------
proc testWavefrontComputation { inWavefrontF inLaplacianF } \
{
    global wlCalibrate

    upvar $inWavefrontF theWavefrontF
    upvar $inLaplacianF theLaplacianF

    # set image display.  Initialize ID window
    # and place it on the display.
    wd.new TESTWAVEFRONTID
    wd.set.title TESTWAVEFRONTID "Test Wavefront. East is Up; North is Right."
    wd.set.wh TESTWAVEFRONTID 350 350
    wd.set.xy TESTWAVEFRONTID 50 100

    wd.set.array TESTWAVEFRONTID theWavefrontF

    puts stdout "testWavefrontComputation: Wavefront statistics"
    puts stdout "[a.info theWavefrontF]"
    puts stdout "min = [a.min theWavefrontF]"
    puts stdout "max = [a.max theWavefrontF]"

    a.rows theWavefrontF = theNumRows
    a.cols theWavefrontF = theNumCols
    a.xytov2 theNumCols theNumRows = theMaxIJV2

    alg.conv.ij.xy wlCalibrate(Params) theMaxIJV2 = theMaxXYV2

    puts stdout "theMaxIJV2 = [a.dump theMaxIJV2]"
    puts stdout "theMaxXYV2 = [a.dump theMaxXYV2]"

    
    wd.new TESTLAPLACIANID
    wd.set.title TESTLAPLACIANID "Test Laplacian. East is Up; North is Right."
    wd.set.wh TESTLAPLACIANID 350 350
    wd.set.xy TESTLAPLACIANID 600 100

    wd.set.array TESTLAPLACIANID theLaplacianF

    puts stdout "testWavefrontComputation: Laplacian statistics"
    puts stdout "[a.info theLaplacianF]"
    puts stdout "min = [a.min theLaplacianF]"
    puts stdout "max = [a.max theLaplacianF]"

    a.rows theLaplacianF = theNumRows
    a.cols theLaplacianF = theNumCols
    a.xytov2 theNumCols theNumRows = theMaxIJV2

    alg.conv.ij.xy wlCalibrate(Params) theMaxIJV2 = theMaxXYV2

    puts stdout "theMaxIJV2 = [a.dump theMaxIJV2]"
    puts stdout "theMaxXYV2 = [a.dump theMaxXYV2]"

    dialog "TestWavefrontComputation."

}





#------------------------------------------------------------------------
# EvaluateWavefrontAndLaplacianAtPosition
#
#
# parameters:
#
# called by: takeMeasurementAtCurrentTrainingPoint
#
# 6/29/2005
#------------------------------------------------------------------------
proc EvaluateWavefrontAndLaplacianAtPosition { inXY_ImagPixV2 \
                                               inWavefrontF \
                                               inLaplacianF \
                                               outWavefrontValue_um \
                                               outLaplacianValue_OneByum } \
{
   global wlCalibrate

   upvar $inXY_ImagPixV2 theXYV2
   upvar $inWavefrontF theWavefrontF
   upvar $inLaplacianF theLaplacianF
   upvar $outWavefrontValue_um theWavefrontValue_um
   upvar $outLaplacianValue_OneByum theLaplacianValue_OneByum


   # convert x,y in image pixel coordinates to column, row
   # coordinates for use in looking up wavefront, laplacian.
   alg.conv.xy.ij wlCalibrate(Params) theXYV2 = theIJV2

   a.v2toxy theIJV2 = theIA theJA
   a.extele theWavefrontF theIA theJA = theWavefrontValue_um
   a.extele theLaplacianF theIA theJA = theLaplacianValue_OneByum

   #---------------------------------------------
   #DEBUG
   #---------------------------------------------
   puts stdout "EvaluateWavefrontAndLaplacianAtPosition:"
   puts stdout "i,j: [a.dump theIJV2]"
   puts stdout "x,y: [a.dump theXYV2]"

   puts stdout "theWavefrontValue_um: [a.dump theWavefrontValue_um]"
   puts stdout "wavefront array min, max:"
   puts stdout "[a.min theWavefrontF]"
   puts stdout "[a.max theWavefrontF]"


   puts stdout "theLaplacianValue: [a.dump theLaplacianValue_OneByum]"
   puts stdout "laplacian array min, max:"
   puts stdout "[a.min theLaplacianF]"
   puts stdout "[a.max theLaplacianF]"


   # wireframe display of wavefront
   wd.new WAVID
   wd.set.array WAVID theWavefrontF
   wd.set.title WAVID "Current wavefront"

   # image of wavefront, with rectangle
   # overlay of current position (i,j)
   id.new WAVIMID
   id.set.array WAVIMID theWavefrontF
   a.make "<2 2>" = theWHV2
   a.v2v2tov4 theIJV2 theWHV2 = theRectV4
   id.set.rect.array WAVIMID theRectV4

   wd.new LAPID
   wd.set.array LAPID theLaplacianF
   wd.set.title LAPID "Current laplacian"

   #-----------------------------------------------
   # end DEBUG
   #-----------------------------------------------

   dialog "OK to continue"
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
#        This procedure uses the global array gActuatorPosition_ImagPixV4
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



#---------------------------------------------------------------------------
# proc divergence
#
# Takes the divergence of the input data.  Used for computing the
# laplacian of the wavefront.  Based on calcLap in dm_panels_5dms.tcl
#
# called by:  computeWavefrontAndLaplacianByWavescopeMethod
#
# completed.  Needs debugging.
# 6/28/2005
#---------------------------------------------------------------------------
proc divergence { inVectV2 outDivF } \
{

    upvar $inVectV2 theVect
    upvar $outDivF theDiv

    a.v2toxy theVect = xg yg
    a.grad xg = dxg
    a.v2toxy dxg = dxx dxy
    a.grad yg = dyg
    a.v2toxy dyg = dyx dyy

    a.add dxx dyy = theDiv
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
# NOTE:  This procedure needs the global variables defined:
#               gNumberOfZernikeTerms
#               gWavefrontZernikeCoeffsV2
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
# solveForDeviceParamsAtCalibPoint
#
#
# called by:  trainBinnedActuator
#
# under construction
# 6/29/2005
#---------------------------------------------------------------------------
proc solveForDeviceParamsAtCalibPoint { inCalibPointInputDataArrayF \
                                        outMembrArrayDist_um \
                                        outMembrTEDist_um \
                                        outTension_NByM } \
{
   global gCalibPointParamGuess
   global gCalibPointOutputParam
   global gNumberOfMeasurementsAtTrainingPoint

   upvar $inCalibPointInputDataArrayF theCalibPointInputDataArrayF
   upvar $outMembrArrayDist_um theMembrArrayDist_um
   upvar $outMembrTEDist_um theMembrTEDist_um
   upvar $outTension_NByM theTension_NByM

   
   #====================================================
   # set starting guess parameters for nonlinear solver
   # Tension 3 N/m; dA = 36 um; dT = 27 um
   #====================================================
   CalibPointOutputParam_Tension_NbyM_set $gCalibPointParamGuess 3.0
   CalibPointOutputParam_dA_um_set $gCalibPointParamGuess 36
   CalibPointOutputParam_dT_um_set $gCalibPointParamGuess 27

   set gNumMeasurementsAtCalibPoint $gNumberOfMeasurementsAtTrainingPoint


   for { set k 0 } { $k < $gNumberOfMeasurementsAtTrainingPoint } { incr k } {

        a.extele theCalibPointInputDataArrayF $k 0 = theXiA
        a.extele theCalibPointInputDataArrayF $k 1 = theDXiA
        a.extele theCalibPointInputDataArrayF $k 2 = theVaA
        a.extele theCalibPointInputDataArrayF $k 3 = theVmA

        set theXi [a.dump theXiA]
        set theDxi [a.dump theDXiA]
        set theVa [a.dump theVaA]
        set theVm [a.dump theVmA]

        setCalibPointInputData $k 0 $theXi
        setCalibPointInputData $k 1 $theDxi
        setCalibPointInputData $k 2 $theVa
        setCalibPointInputData $k 3 $theVm

   }

   # nonlinear solver implemented in calibPoint.dll
   # NOTE: use version 4 of this software (or greater).
   # executing the solver in this fashion causes the
   # wavescope system to crash.  7/1/2005

   computeDeviceParamsAtCalibPoint


   set theTension_NByM \
        [CalibPointOutputParam_Tension_NbyM_get $gCalibPointOutputParam]

   set theMembrArrayDist_um \
        [CalibPointOutputParam_dA_um_get $gCalibPointOutputParam]

   set theMembrTEDist_um \
        [CalibPointOutputParam_dT_um_get $gCalibPointOutputParam]

}


