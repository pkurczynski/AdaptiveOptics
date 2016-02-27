#------------------------------------------------------------------------
# tdm_ModalControlExecution.tcl                      tcl script
#
# Procedures used in control of transparent electrode membrane mirror using
# modal control algorithm.  Based upon tdm_ModalControlProcedures_v12.tcl
# which is its predecessor.
#
# Procedures in this file:
#
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
# version 1
# plk 06/10/2005
#------------------------------------------------------------------------

# Membrane shape and Laplacian, computed at actuator center positions
# < xi  yi   xi(xi,yi)   del2 xi(xi,yi) >
# See computeMembraneShapeAndLaplacian
global gMembraneShapeV4

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



#------------------------------------------------------------------------
# computeWavefrontAndLaplacian                    NOT IN USE
#
#
# under construction
#
# called by: takeMeasurementAtCurrentTrainingPoint
#
# 6/13/2005
#------------------------------------------------------------------------
proc OLD_V5_computeWavefrontAndLaplacian { inX_ImagPix  \
                                    inY_ImagPix \
                                    inZernikeCoeffsV2 \
                                    outWavefront_um \
                                    outLaplacian_OneByum } \
{
  global wlCalibrate

  upvar $inX_ImagPix theX_ImagPix
  upvar $inY_ImagPix theY_ImagPix
  upvar $inZernikeCoeffsV2 theZernikeCoeffsV2
  upvar $outWavefront_um theWavefront_um
  upvar $outLaplacian_OneByum theLaplacian_OneByum


  #DEBUG
  #set theWavefront_um 7.0
  #set theLaplacian_OneByum 8.0
  #puts stdout "computeWavefrontAndLaplacian: X,Y = $theX_ImagPix , $theY_ImagPix"

  a.extele wlCalibrate(Pupil) 0 = thePupilXCenterA
  a.extele wlCalibrate(Pupil) 1 = thePupilYCenterA
  a.extele wlCalibrate(Pupil) 2 = thePupilRadiusA

  set thePupilXCenter_ImagPix [a.dump thePupilXCenterA]
  set thePupilYCenter_ImagPix [a.dump thePupilYCenterA]
  set thePupilRadius_ImagPix [a.dump thePupilRadiusA]

  set theXR [expr $inX_ImagPix - $thePupilXCenter_ImagPix]
  set theYR [expr $inY_ImagPix - $thePupilYCenter_ImagPix]
  set theRAbs [expr sqrt($theXR * $theXR + $theYR * $theYR)]
  set theRRel_ImagPix [expr $theRAbs / $thePupilRadius_ImagPix]
  set theTheta_Rad [expr atan2($theYR, $theXR)]

  a.rows theZernikeCoeffsV2 = theNumberOfZernikeTermsA
  set theNumberOfZernikeTerms [a.dump theNumberOfZernikeTermsA]

  set theWavefrontSum_pix 0.0
  for { set k 0 } { $k < $theNumberOfZernikeTerms } { incr k } {



  }



}

