#------------------------------------------------------------------------
# tdm_ClosedLoopProcedures.tcl                      tcl script
#
# Procedures used in control of transparent electrode membrane mirror
# in closed loop with Wavescope wavefront sensor system.
#
# Procedures in this file:
#
#   pokeBinnedActuators_quiet    pokes binned actuators; used in making
#                                reconstructor
#
#   setActuatorWeights_WestChipSide50pctHandicap
#
#
# Note:  to initialize procedures in this file with the wavescope
# software, add lines such as the following to the tclIndex.tcl file
# in usr/aos/wavescope/scripts/
#        e.g. set auto_index(pokeBinnedActuators_quiet) \
#               [list source [file join tdm_ClosedLoopProcedures.tcl]]
#
# version 5
# plk 01/10/2005
#------------------------------------------------------------------------

global gNumberOfActuatorsPerBin
set gNumberOfActuatorsPerBin 9

global gActuatorWeight
global gModesWeightedPreviously
set gModesWeightedPreviously 0

#------------------------------------------------------------------------
# pokeBinnedActuators_quiet
#
# Pokes each actuator bin, according to a prescribed binning scheme
# and records the gradients (no noise). Based on quiet_restricted{}
#
#
# Called by:  MrPR (in dm_panels_5dms.tcl)
#
# plk 12/17/2004
#------------------------------------------------------------------------
proc pokeBinnedActuators_quiet { } {

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
             #     "PokeBinnedActuators_quiet: CurDrv histogram in plot window"
             #a.tilt 10 0 0.01 = theHistogramBins
             #a.hist CurDrv -1 0.5 25 = theCurDrvHistogramData
             #pd.new theHistogram
             #pd.set.type theHistogram 3
             #pd.set.title theHistogram "Histogram of CurDrv values"
             #pd.set.y.array theHistogram theCurDrvHistogramData
             #puts stdout "PokeBinnedActuators_quiet:  CurDrv histogram 25 0.5 bins"
             #puts stdout "[a.dump theCurDrvHistogramData]"

             # DEBUG:  CurDrv contents
             #puts stdout "*************CurDrv follows**********************"
             #puts stdout "[a.dump CurDrv]"

             # DEBUG:  CurDrv statistics
             a.min CurDrv = theMin
             a.max CurDrv = theMax
             puts stdout "pokeBinnedActuators_quiet:"
             puts stdout \
                  "     CurDrv: min= [a.dump theMin] max= [a.dump theMax]"

             # ... update the GUI display
             SetGUIActs $CurDrv

             # ... convert CurDrv to voltage
             ftov $CurDrv uuu

             # DEBUG:  voltage array histogram
             #puts stdout \
             #     "PokeBinnedActuators_quiet: voltage histogram in plot window"
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
             #puts stdout "PokeBinnedActuators_quiet: UUU info"
             #puts stdout "\t [a.info uuu] "


             # DEBUG: voltage array statistics
             a.min uuu = theUMin
             a.max uuu = theUMax
             puts stdout "PokeBinnedActuators_quiet:"
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





#------------------------------------------------------------------------
# setActuatorModeWeights_WestChipSide50pctHandicap
#
# Populates the mode weight array by setting values of this array to a
# value between 0...1.  The drive signal corresponding to each actuator
# of the array is multiplied by the appropriate element of the mode
# weight array before being converted to a drive voltage.
#
# This mode weight scheme handicaps all actuators in the west chip side
# by 50%.
#
# (old version) used global array:modew  defined in updateModew (dm_panels_5dms)
#
# (this version) uses global array gActuatorWeight
#
#   gActuatorWeight is an Nx1 array of floats (0...1). N = # of actuators
#       in wire list (e.g. 1369 for 1024 array; incl. spacers).  Value
#       is weight factor for scaling the Drive signal before converting
#       to voltages to send to the hardware.
#
#
# Called by: command line, tdm_init
#
# plk 01/09/2005
#------------------------------------------------------------------------

proc setActuatorWeights_WestChipSide50pctHandicap {} \
{
    global gNumberOfActuatorsPerBin
    global gActuatorWeight
    global gModesWeightedPreviously


    global Grad gvd CurDrv Drvs Grds MAX_ACT maskArray pokeFraction
    global wlCalibrate YACT_LINE_LENGTH XACT_LINE_LENGTH

 if { $gModesWeightedPreviously == 0 } \
 {

   #DEBUG
   puts stdout "setActuatorWeights_WestChipSide50pctHandicap:"

   set gModesWeightedPreviously 1

   # allocate the array of Bin mode weights.
   a.copy CurDrv = gActuatorWeight

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


   set theCurrentBinNumber 0
   set theNumberOfBins \
       [expr $XACT_LINE_LENGTH/$theIBinWidth * $YACT_LINE_LENGTH/$theJBinWidth]


   # loop over the actuators in the array, modulo binning
   # i,j determines actuator at the bin center (odd binning) or
   # the actuator to the immediate "lower left" of bin center (even binning).
   for { set i 0 } { $i < $XACT_LINE_LENGTH } { incr i $theIBinWidth } {
        for { set j 0 } { $j < $YACT_LINE_LENGTH } { incr j $theJBinWidth } {

             set theCurrentBinNumber [expr $theCurrentBinNumber + 1]

             #DEBUG
             #puts stdout "setActuatorModeWeights: Bin Number: $theCurrentBinNumber"
             #puts stdout "setActuatorModeWeights: Binned Actuator: i=$i j=$j"



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



                       # set the mode weight for this actuator based
                       # upon its position in the array, and upon the
                       # desired mode weighting scheme.


                       # bins are numbered 0,1,2... beginning in the SW
                       # chip corner and increasing toward the NW chip corner
                       # in columns 1st, then Eastward in rows.  The highest
                       # bin number is in the NE chip corner.
                       #
                       # this mode weighting scheme "handicaps" the actuators
                       # in the West Chip side by 50% compared to actuators
                       # in the East chip side.  Because of membrane tilt of
                       # device 11-17-2004-A, the actuators on the West chip
                       # side deliver much greater deformations at a given
                       # voltage than actuators on the East chip side.
                       # plk 01/09/2005

                       set theUpperBinThreshold \
                                [expr $theNumberOfBins/2.0]

                       if {$theCurrentBinNumber < $theUpperBinThreshold } \
                       {
                            set theCurrentModeWeight 0.5
                       } else \
                       {
                            set theCurrentModeWeight 1.0
                       }

                       # if current actuator is within the active area
                       # of the array ...
                       if { $Bi_abs >= 0 && $Bi_abs < $XACT_LINE_LENGTH } {
                            if { $Bj_abs >= 0 && $Bj_abs < $YACT_LINE_LENGTH } {


                                a.repele $theCurrentModeWeight gActuatorWeight \
                                     $theHDActuatorIndex = gActuatorWeight

                                #DEBUG
                                #puts stdout "     Actuator #: $theHDActuatorIndex  Weight: $theCurrentModeWeight"



                            }
                       }
                  }
             }


        }
   }

 } else \
 {
    puts stdout "setActuatorWeights failed:  Modes Weighted Previously."
 }
}


#------------------------------------------------------------------------
# setActuatorModeWeights_WestSector50pctHandicap
#
# Populates the mode weight array by setting values of this array to a
# value between 0...1.  The drive signal corresponding to each actuator
# of the array is multiplied by the appropriate element of the mode
# weight array before being converted to a drive voltage.
#
# This mode weight scheme handicaps all actuators in a sector of the
# device corresponding to the West chip side, but not the entire West
# chip side.
#
# (old version) used global array:modew  defined in updateModew (dm_panels_5dms)
#
# (this version) uses global array gActuatorWeight
#
#   gActuatorWeight is an Nx1 array of floats (0...1). N = # of actuators
#       in wire list (e.g. 1369 for 1024 array; incl. spacers).  Value
#       is weight factor for scaling the Drive signal before converting
#       to voltages to send to the hardware.
#
#
# Called by: command line, tdm_init
#
# plk 01/09/2005
#------------------------------------------------------------------------

proc setActuatorWeights_WestSector50pctHandicap {} \
{
    global gNumberOfActuatorsPerBin
    global gActuatorWeight
    global gModesWeightedPreviously


    global Grad gvd CurDrv Drvs Grds MAX_ACT maskArray pokeFraction
    global wlCalibrate YACT_LINE_LENGTH XACT_LINE_LENGTH

 if { $gModesWeightedPreviously == 0 } \
 {

   #DEBUG
   puts stdout "setActuatorWeights_WestChipSide50pctHandicap:"

   set gModesWeightedPreviously 1

   # allocate the array of Bin mode weights.
   a.copy CurDrv = gActuatorWeight

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


   set theCurrentBinNumber 0
   set theNumberOfBins \
       [expr $XACT_LINE_LENGTH/$theIBinWidth * $YACT_LINE_LENGTH/$theJBinWidth]


   # loop over the actuators in the array, modulo binning
   # i,j determines actuator at the bin center (odd binning) or
   # the actuator to the immediate "lower left" of bin center (even binning).
   for { set i 0 } { $i < $XACT_LINE_LENGTH } { incr i $theIBinWidth } {
        for { set j 0 } { $j < $YACT_LINE_LENGTH } { incr j $theJBinWidth } {

             set theCurrentBinNumber [expr $theCurrentBinNumber + 1]

             #DEBUG
             #puts stdout "setActuatorModeWeights: Bin Number: $theCurrentBinNumber"
             #puts stdout "setActuatorModeWeights: Binned Actuator: i=$i j=$j"



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



                       # set the mode weight for this actuator based
                       # upon its position in the array, and upon the
                       # desired mode weighting scheme.


                       # bins are numbered 0,1,2... beginning in the SW
                       # chip corner and increasing toward the NW chip corner
                       # in columns 1st, then Eastward in rows.  The highest
                       # bin number is in the NE chip corner.
                       #
                       # this mode weighting scheme "handicaps" the actuators
                       # in the 1st two rows of the West Chip side by 50%
                       # (assuming 3x3 binning...169 binned actuators total...
                       # 13x13 array of effective actuators)compared to actuators
                       # in the East chip side.  Because of membrane tilt of
                       # device 11-17-2004-A, the actuators on the West chip
                       # side deliver much greater deformations at a given
                       # voltage than actuators on the East chip side.
                       # plk 01/13/2005

                       set theUpperBinThreshold 26

                       if {$theCurrentBinNumber < $theUpperBinThreshold } \
                       {
                            set theCurrentModeWeight 0.5
                       } else \
                       {
                            set theCurrentModeWeight 1.0
                       }

                       # if current actuator is within the active area
                       # of the array ...
                       if { $Bi_abs >= 0 && $Bi_abs < $XACT_LINE_LENGTH } {
                            if { $Bj_abs >= 0 && $Bj_abs < $YACT_LINE_LENGTH } {


                                a.repele $theCurrentModeWeight gActuatorWeight \
                                     $theHDActuatorIndex = gActuatorWeight

                                #DEBUG
                                #puts stdout "     Actuator #: $theHDActuatorIndex  Weight: $theCurrentModeWeight"



                            }
                       }
                  }
             }


        }
   }

 } else \
 {
    puts stdout "setActuatorWeights failed:  Modes Weighted Previously."
 }
}


#------------------------------------------------------------------------
# setActuatorModeWeights_NS_Stripes
#
# Populates the mode weight array by setting values of this array to a
# value between 0...1.  The drive signal corresponding to each actuator
# of the array is multiplied by the appropriate element of the mode
# weight array before being converted to a drive voltage.
#
# This mode weight scheme handicaps all actuators in the west chip side
# by 50%.
#
# (old version) used global array:modew  defined in updateModew (dm_panels_5dms)
#
# (this version) uses global array gActuatorWeight
#
#   gActuatorWeight is an Nx1 array of floats (0...1). N = # of actuators
#       in wire list (e.g. 1369 for 1024 array; incl. spacers).  Value
#       is weight factor for scaling the Drive signal before converting
#       to voltages to send to the hardware.
#
#
# Called by: command line
#
# plk 01/09/2005
#------------------------------------------------------------------------

proc setActuatorWeights_NS_Stripes {} \
{
    global gNumberOfActuatorsPerBin
    global gActuatorWeight
    global gModesWeightedPreviously


    global Grad gvd CurDrv Drvs Grds MAX_ACT maskArray pokeFraction
    global wlCalibrate YACT_LINE_LENGTH XACT_LINE_LENGTH

 if { $gModesWeightedPreviously == 0 } \
 {

   #DEBUG
   puts stdout "setActuatorWeights_NS_Stripes:"

   set gModesWeightedPreviously 1

   # allocate the array of Bin mode weights.
   a.copy CurDrv = gActuatorWeight

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


   set theCurrentBinNumber 0
   set theNumberOfBins \
       [expr $XACT_LINE_LENGTH/$theIBinWidth * $YACT_LINE_LENGTH/$theJBinWidth]


   # loop over the actuators in the array, modulo binning
   # i,j determines actuator at the bin center (odd binning) or
   # the actuator to the immediate "lower left" of bin center (even binning).
   for { set i 0 } { $i < $XACT_LINE_LENGTH } { incr i $theIBinWidth } {
        for { set j 0 } { $j < $YACT_LINE_LENGTH } { incr j $theJBinWidth } {

             set theCurrentBinNumber [expr $theCurrentBinNumber + 1]

             #DEBUG
             #puts stdout "setActuatorModeWeights: Bin Number: $theCurrentBinNumber"
             #puts stdout "setActuatorModeWeights: Binned Actuator: i=$i j=$j"



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



                       # set the mode weight for this actuator based
                       # upon its position in the array, and upon the
                       # desired mode weighting scheme.


                       # bins are numbered 0,1,2... beginning in the SW
                       # chip corner and increasing toward the NW chip corner
                       # in columns 1st, then Eastward in rows.  The highest
                       # bin number is in the NE chip corner.
                       #


                       set theStripe1UpperBinThreshold \
                                [expr $theNumberOfBins/4.0]

                       set theStripe2UpperBinThreshold \
                                [expr 2*$theNumberOfBins/4.0]

                       set theStripe3UpperBinThreshold \
                                [expr 3*$theNumberOfBins/4.0]

                       # Stripe 1: West chip side;  low
                       if {$theCurrentBinNumber < $theStripe1UpperBinThreshold } \
                       {
                            set theCurrentModeWeight 0.2
                       }

                       # Stripe 2: West chip side;  high
                       if {$theCurrentBinNumber < $theStripe2UpperBinThreshold && \
                           $theCurrentBinNumber >= $theStripe1UpperBinThreshold} \
                       {
                            set theCurrentModeWeight 1.0
                       }

                       # Stripe 3: East chip side;  low
                       if {$theCurrentBinNumber < $theStripe3UpperBinThreshold && \
                           $theCurrentBinNumber >= $theStripe2UpperBinThreshold} \
                       {
                            set theCurrentModeWeight 0.2
                       }

                       # Stripe 4: East chip side;  high
                       if {$theCurrentBinNumber >= $theStripe3UpperBinThreshold} \
                       {
                            set theCurrentModeWeight 1.0
                       }

                       # if current actuator is within the active area
                       # of the array ...
                       if { $Bi_abs >= 0 && $Bi_abs < $XACT_LINE_LENGTH } {
                            if { $Bj_abs >= 0 && $Bj_abs < $YACT_LINE_LENGTH } {


                                a.repele $theCurrentModeWeight gActuatorWeight \
                                     $theHDActuatorIndex = gActuatorWeight

                                #DEBUG
                                #puts stdout "     Actuator #: $theHDActuatorIndex  Weight: $theCurrentModeWeight"



                            }
                       }
                  }
             }


        }
   }

 } else \
 {
    puts stdout "setActuatorWeights failed:  Modes Weighted Previously."
 }
}




