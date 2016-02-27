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
# version 1
# plk 05/02/2005
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
#
# Called by:
#
# plk 05/02/2005
#---------------------------------------------------------------------------
proc decomposeWavefrontZernikeCoeffs { } \
{
   global gNumberOfZernikeTerms
   global gWavefrontZernikeCoeffs

   global Grad gvd CurDrv Drvs Grds MAX_ACT maskArray pokeFraction
   global wlCalibrate YACT_LINE_LENGTH XACT_LINE_LENGTH


   # get x,y center of current image plane from calibration data
   a.ave wlCalibrate(FinalCenters) = theSamplePositions_avg_V2
   a.v2toxy theSamplePositions_avg_V2 = theCenterColumn_V0 theCenterRow_V0
   set theCenterRow [a.dump theCenterRow_V0]
   set theCenterColumn [a.dump theCenterColumn_V0]


   # Use the value of pupil radius that will center the wavefront
   # over the sampled area of the spot image plane.
   # NOTE:  This value of pupil radius assumes that image radius is
   # closely aligned with membrane radius.
   set thePupilRadius_pix [expr $theCenterRow - 0.2*$theCenterRow]

   # wavefront gradients stored in Grad array (v4), which is
   # populated during a WFS measurment called by calcGrad
   zern.decomp.grad.coefs wlCalibrate(FinalCenters) \
                          gNumberOfZernikeTerms \
                          theCenterColumn \
                          theCenterRow \
                          thePupilRadius_pix = gWavefrontZernikeCoeffs

   # DEBUG
   # convert the coeffs. to strings, and print...
   zern.conv.string gWavefrontZernikeCoeffs


}
