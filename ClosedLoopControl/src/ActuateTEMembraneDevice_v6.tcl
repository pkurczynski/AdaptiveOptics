#--------------------------------------------------------
# ActuateTEMembraneDevice.tcl            tcl script
#
# Contains procedures for use in commanding 1024 electrode
# membrane mirror with transparent electrode.
#
# To run these procedures, tdm_panel must have been sourced
# previously, in order to define procedures called by these
# scripts.  Source code for tdm_panel is dm_panels_5dms.tcl
#
# global variables
#
# gNumRows        the number of rows, columns in the
# gNumColumns     electrode array.
#
# NOTE:  "Rows" defined in this software are lines of
# electrodes that run from chip side "West" to chip side
# "East."  The first row runs along the "South" chip side
# and is numbered "1." Row numbers increase from "South" to
# "North" and span the range [1,37].  Similarly columns are
# lines of electrodes that run from "South" to "North."  The
# first column runs along the "West" chip side and is numbered
# "1."  Column numbers increase from "West" to "East" and
# span the range [1,37].
#
# version 6
# plk 01/16/2005
#--------------------------------------------------------

set gNumRows 37
set gNumColumns 37

set Vm 0
set Varray 0


proc tdm_init { } {


   displayArrayControlGUI
   tdm_panel
   #setActuatorWeights_WestChipSide50pctHandicap
   makeWavefront
   
}




#--------------------------------------------------------
# ActuateSouthChipSector
#
# Actuates a sector of the electrode array on
# the south chip side to a specified voltage.
# Sector is defined as all the electrodes in the
# array with an HDColumn number less than the input
# value
#
# arguments:
#
# inHDColumn  the column value that defines the edge
#             of the sector.  Column values greater
#             than this input value will not be actuated.
#
# inVoltage   the desired voltage value for the sector.
#
# uses procedures:  pokeNrows
#
# called by: <command line>
#
#
# plk 12/10/2004
#--------------------------------------------------------
proc ActuateSouthChipSector {inHDColumn inVoltage} {

     global gNumRows
     global gNumColumns


     for {set i 1} {$i <= $inHDColumn } {incr i} {

        set theNumRows 1

        #DEBUG statement
        #puts stdout "ActuateSouthChipSector: The current loop index is $i."

        pokeNrows $i $theNumRows $inVoltage

     }

}

#--------------------------------------------------------
# ActuateWestChipSector
#
# Actuates a sector of the electrode array on
# the south chip side to a specified voltage.
# Sector is defined as all the electrodes in the
# array with an HDColumn number less than the input
# value
#
# arguments:
#
# inHDColumn  the column value that defines the edge
#             of the sector.  Column values greater
#             than this input value will not be actuated.
#
# inVoltage   the desired voltage value for the sector.
#
# uses procedures:  pokeNcolumns
#
# called by: <command line>
#
#
# plk 12/10/2004
#--------------------------------------------------------
proc ActuateWestChipSector {inHDRow inVoltage} {

     global gNumRows
     global gNumColumns

     set theNumColumns 1

     for {set i 1} {$i <= $inHDRow } {incr i} {

        #DEBUG statement
        #puts stdout "ActuateWestChipSector: The current loop index is $i."

        pokeNcolumns $i $theNumColumns $inVoltage

     }

}

#--------------------------------------------------------
# pokeNrows
#
# Actuates a specified number of rows of the electrode
# array to the same voltage.  Writes this voltage to the
# hardware using dm.pokeraw
#
# NOTE:  "Rows" defined in this software are lines of
# electrodes that run from chip side "West" to chip side
# "East."  The first row runs along the "South" chip side
# and is numbered "1." Row numbers increase from "South"
# "North" and span the range [1,37].
#
# arguments:
#
# inStartRow  the column value that defines the edge
#             of the sector.  Column values greater
#             than this input value will not be actuated.
#
# inNumRows   the integer number of rows to set to the
#             same voltage.
#
# inVoltage   the desired voltage value for the rows.
#
# uses procedures:  dm.pokeraw
#
# called by: ActuateSouthChipSector
#
# plk 12/10/2004
#--------------------------------------------------------
proc pokeNrows {inStartRow inNumRows inVoltage} {

     # DEBUG statement
     puts stdout "       Now executing pokeNrows"

     global gNumColumns

     set theStopRow [expr $inStartRow + $inNumRows]
     for {set i 1} {$i <=$gNumColumns} {incr i} {
        for {set j $inStartRow} {$j <= $theStopRow} {incr j} {

            set theHDActuatorNum [expr $j * $gNumColumns + $i]

            # DEBUG statement
            # puts stdout "      Actuator Number: $theHDActuatorNum"

            dm.pokeraw $theHDActuatorNum $inVoltage

        }
     }
}

#--------------------------------------------------------
# pokeNcolumns
#
# Actuates a specified number of rows of the electrode
# array to the same voltage.  Writes this voltage to the
# hardware using dm.pokeraw
#
# NOTE:  "Rows" defined in this software are lines of
# electrodes that run from chip side "West" to chip side
# "East."  The first row runs along the "South" chip side
# and is numbered "1." Row numbers increase from "South"
# "North" and span the range [1,37].
#
# arguments:
#
# inStartRow  the column value that defines the edge
#             of the sector.  Column values greater
#             than this input value will not be actuated.
#
# inNumRows   the integer number of rows to set to the
#             same voltage.
#
# inVoltage   the desired voltage value for the rows.
#
# uses procedures:  dm.pokeraw
#
# called by: ActuateWestChipSector
#
# plk 12/10/2004
#--------------------------------------------------------
proc pokeNcolumns {inStartColumn inNumColumns inVoltage} {

     # DEBUG statement
     puts stdout "pokeNcolumns:"

     global gNumRows
     global gNumColumns

     set theStopColumn [expr $inStartColumn + $inNumColumns]
     for {set i 1} {$i <=$gNumRows} {incr i} {
        for {set j $inStartColumn} {$j <= $theStopColumn} {incr j} {

            set theHDActuatorNum [expr $i * $gNumColumns + $j]

            # DEBUG statement
            puts stdout "      Actuator Number: $theHDActuatorNum"

            dm.pokeraw $theHDActuatorNum $inVoltage

        }
     }
}



#--------------------------------------------------------
# poke4rows
#
# Actuates 4 rows of the electrode
# array to the same voltage.  
#
# NOTE:  "Rows" defined in this software are lines of
# electrodes that run from chip side "West" to chip side
# "East."  The first row runs along the "South" chip side
# and is numbered "1." Row numbers increase from "South"
# "North" and span the range [1,37].
#
# arguments:
#
# inVoltage   the desired voltage value for the rows.
#
# uses procedures:  pokeNrows
#
# called by: command line
#
# plk 12/14/2004
#--------------------------------------------------------
proc poke4rows {inVoltage} {

    pokeNrows 7 1 $inVoltage
    pokeNrows 15 1 $inVoltage
    pokeNrows 24 1 $inVoltage
    pokeNrows 32 1 $inVoltage

}

#--------------------------------------------------------
# pokeNx1stripes
#
# Actuates a specified number of consecutive rows to
# the same, specified voltage, repeating this pattern
# throghout the array.
#
# arguments:
#     inBinWidth     the width of each stripe (number
#                    of rows).
#     inVoltage	     the voltage to assign the downward
#                    pulling rows of electrodes (othes
#                    are kept at zero.)
#
#
# Use this procedure for 1-D spatial frequency tests
#
# plk 12/13/2004
#--------------------------------------------------------
proc pokeNx1stripes { inBinWidth inVoltage } {

     global gNumRows     

     set theStopRow [expr $gNumRows - $inBinWidth]
     set theCurrentLowRow 0
     set theCurrentHighRow [expr $theCurrentLowRow +$inBinWidth]
     while { $theCurrentHighRow <= $theStopRow } {
        
        #DEBUG statement
        puts stdout "The current value of the loop index is $theCurrentLowRow."

        pokeNrows $theCurrentLowRow $inBinWidth $inVoltage
        pokeNrows $theCurrentHighRow $inBinWidth 0

        incr theCurrentLowRow [expr 2 * $inBinWidth ]
        incr theCurrentHighRow [expr 2 * $inBinWidth ]
     
     }
}




#--------------------------------------------------------
# displayArrayControlGUI
#
# Displays a graphical user interface for controlling
# voltages to the 1024 electrode array device.  Scales
# are used to control voltages to the electrode array
# and the membrane independently.  An EMO button enables
# rapidly setting all voltages to zero.
#
# Hardware control is implemented via Harold Dyson's
# setarray function, which uses the global variables
# Vm and Varray
#
# plk 12/10/2004
#--------------------------------------------------------
proc displayArrayControlGUI { } {


     set w .te_membranecontrol
     catch {destroy $w}
     toplevel $w
     wm title $w "ArrayControlGUI"
     wm iconname $w "button"


     frame $w.buttons
     pack $w.buttons -side bottom -fill x -pady 2m

     button $w.buttons.dismiss -text Dismiss -command "destroy $w"
     pack $w.buttons.dismiss

     button $w.emo \
        -text "EMO! " \
        -width 20 \
        -height 5 \
        -bg Red \
	-command "executeEmergencyOff $w"

     # edit command text above with call to procedure setzero to execute
     # the emergency off function

     pack $w.emo -side top -expand yes -pady 2

     #-----------------------------------------------------
     # Varray scale
     #-----------------------------------------------------

     frame $w.frame -borderwidth 10
     pack $w.frame

     scale $w.frame.theVarrayScale \
        -orient vertical \
        -length 284 \
        -from 0 \
        -to 40 \
	-command "setElectrodeArray $w.frame.theVarrayCanvas" \
        -tickinterval 5


     # edit the above code by executing the setarray procedure in the
     # command argument

     canvas $w.frame.theVarrayCanvas -width 50 -height 50 -bd 0 \
        -highlightthickness 0
     $w.frame.theVarrayCanvas create polygon 0 0 1 1 2 2 -fill SeaGreen3 \
        -tags poly
     $w.frame.theVarrayCanvas create line 0 0 1 1 2 2 0 0 -fill black \
        -tags line
     #frame $w.frame.right -borderwidth 15

     label $w.frame.title -justify left \
        -text "Array Voltage          Membrane Voltage"
     pack $w.frame.title -side top


     pack $w.frame.theVarrayScale -side left -anchor ne
     pack $w.frame.theVarrayCanvas -side left -anchor nw -fill y
     $w.frame.theVarrayScale set 0


     #-----------------------------------------------------
     # Vm scale
     #-----------------------------------------------------


     scale $w.frame.theVmScale \
        -orient vertical \
        -length 284 \
        -from 0 \
        -to 50 \
	-command "setMembrane $w.frame.theVmCanvas" \
        -tickinterval 5

     canvas $w.frame.theVmCanvas -width 50 -height 50 -bd 0 \
        -highlightthickness 0
     $w.frame.theVmCanvas create polygon 0 0 1 1 2 2 \
        -fill SeaGreen3 \
        -tags uparrow_poly
     $w.frame.theVmCanvas create line 0 0 1 1 2 2 0 0 \
        -fill black \
        -tags uparrow_line
     #frame $w.frame.right -borderwidth 15
     pack $w.frame.theVmScale -side left -anchor ne
     pack $w.frame.theVmCanvas -side left -anchor nw -fill y
     $w.frame.theVmScale set 0

}


#--------------------------------------------------------
# setElectrodeArray
#
# Sets the electrode array to a voltage specified by the
# user using a scale widget.
#
# Hardware control is implemented via Harold Dyson's
# setarray function, which uses the global variables
# Vm and Varray
#
# called by:  displayArrayControlGUI
#
# plk 12/10/2004
#--------------------------------------------------------

proc setElectrodeArray {w height} {

    global Varray
    global Vm

    set Varray [expr $height]
    executeSetArray

    set height [expr $height * 6]
    incr height 21

    set y2 [expr $height - 15]
    if {$y2 < 21} {
	set y2 21
    }

    $w coords poly 15 20 35 20 35 $y2 45 $y2 25 $height 5 $y2 15 $y2 15 20
    $w coords line 15 20 35 20 35 $y2 45 $y2 25 $height 5 $y2 15 $y2 15 20
}


#--------------------------------------------------------
# setMembrane
#
# Sets the membrane to a voltage specified by the
# user using a scale widget.
#
# Hardware control is implemented via Harold Dyson's
# setarray function, which uses the global variables
# Vm and Varray
#
# called by:  displayArrayControlGUI
#
# plk 12/10/2004
#--------------------------------------------------------
proc setMembrane {w height} {

    global Varray
    global Vm

    set Vm [expr $height]
    executeSetArray

    set height [expr $height * 6]
    incr height 21

    set y3 [expr $height - 15]
    if {$y3 > 36} {
	set y3 36
    }
    if {$y3 < 21} {
        set y3 21
    }

    set theScaledHeight [expr $height * 40 / 285]
    $w coords uparrow_poly \
        15 $height 35 $height 35 $y3 45 $y3 25 20 5 $y3 15 $y3 15 $height
    $w coords uparrow_line \
        15 $height 35 $height 35 $y3 45 $y3 25 20 5 $y3 15 $y3 15 $height
}


proc executeSetArray { } {
     global Varray
     global Vm

     # DEBUG
     # puts stdout "       Now executing executeSetArray"
     # puts stdout "             Vm = $Vm   Varray = $Varray"

     setarray
}

proc executeEmergencyOff {w} {

     setzero
     
     $w config -bg LightBlue1
     $w.buttons config -bg LightBlue1

     puts stdout " EMO executed.  Voltages set to zero"
     destroy $w
}



#----------------------------------------------------------------------------
# pokeNxNbin
#
# Sets a specified NxN bin of electrodes on the array to the same voltage.
#
# uses procs:  dm.pokeraw (C function, initialized with wavesecope software)
#
# uses global variables:  XACT_LINE_LENGTH, YACT_LINE_LENGTH set in tdm_panel
#
# called by:  command line
#
# plk 12/20/2004
#-----------------------------------------------------------------------------

proc pokeNxNbin { inRow inColumn inN inVoltage } {

   global XACT_LINE_LENGTH
   global YACT_LINE_LENGTH
   global maskArray


   # for N X N binning of actuators
   # theNumberOfActuatorsPerBin = N*N
   set theNumberOfActuatorsPerBin [expr $inN*$inN]

   # set the row, column ranges for the NxN bin
   # this code will produce the following (e.g.)
   # binning    Bx_lo   Bx_hi
   # -------    -----   -----
   #  2x2         0       1
   #  3x3        -1       1
   #  5x5        -2       2
   # 16x16       -7       8
   # 32x32       -15     16
   set theNisEven [expr int(1 - fmod($inN,2))]
   set Bi_lo [expr -1*int($inN/2) + $theNisEven]
   set Bi_hi [expr int($inN/2)]
   set Bj_lo [expr -1*int($inN/2) + $theNisEven]
   set Bj_hi [expr int($inN/2)]


   # loop over each actuator in the bin.  Set its voltage, if possible.
   for { set Bi $Bi_lo } { $Bi <= $Bi_hi } { incr Bi } {
       for { set Bj $Bj_lo } { $Bj <= $Bj_hi} { incr Bj } {

           # absolute i,j values of the current actuator
           set Bi_abs [expr $Bi + $inRow]
           set Bj_abs [expr $Bj + $inColumn]

           # Harold Dysons integer index number of the actuator
           set theHDActuatorIndex \
               [expr $Bi_abs*$XACT_LINE_LENGTH +$Bj_abs]

           # if current actuator is within the active area
           # of the array ...
           if { $Bi_abs >= 0 && $Bi_abs < $XACT_LINE_LENGTH } {
              if { $Bj_abs >= 0 && $Bj_abs < $YACT_LINE_LENGTH } {

                 # ...and if the actuator is not masked ...
                 if { [ a.extele maskArray $theHDActuatorIndex ] == 1 } {

                        dm.pokeraw $theHDActuatorIndex $inVoltage

                 } else {
                        # ...else the actutor is masked

                        #DEBUG
                        #puts "Skipping masked actuator: $Bj_abs x $Bi_abs"

                 }
              }
           }
       }
   }
}



#----------------------------------------------------------------------------
# poke5bins
#
# sets a pattern of 5 2x2 bins on the array to the same voltage.
#
# bin pattern:                    x       x
#
#                                     x
#
#                                 x       x
#
#
# called by:  command line
#
# plk 12/20/2004
#-----------------------------------------------------------------------------
proc poke5bins { inVoltage } {

pokeNxNbin 17 17 2 $inVoltage
pokeNxNbin 9 9 2 $inVoltage
pokeNxNbin 25 9 2 $inVoltage
pokeNxNbin 9 25 2 $inVoltage
pokeNxNbin 25 25 2 $inVoltage


}

#----------------------------------------------------------------------------
# poke9bins
#
# sets a pattern of 9 2x2 bins on the array to the same voltage.
#
# bin pattern:                    x   x    x
#
#                                 x   x    x
#
#                                 x   x    x
#
#
# called by:  command line
#
# plk 12/20/2004
#-----------------------------------------------------------------------------
proc poke9bins { inVoltage } {

set theBinLevel 4
pokeNxNbin 9 9 $theBinLevel $inVoltage
pokeNxNbin 9 17 $theBinLevel $inVoltage
pokeNxNbin 9 25 $theBinLevel $inVoltage

pokeNxNbin 17 9 $theBinLevel $inVoltage
pokeNxNbin 17 17 $theBinLevel $inVoltage
pokeNxNbin 17 25 $theBinLevel $inVoltage

pokeNxNbin 25 9 $theBinLevel $inVoltage
pokeNxNbin 25 25 $theBinLevel $inVoltage
pokeNxNbin 25 17 $theBinLevel $inVoltage


}

#----------------------------------------------------------------------------
# poke13bins
#
# sets a pattern of 13 NxN bins on the array to the same voltage.
#                                     E
#
# bin pattern:                        x
#
#                                 x   x    x
#
#                       S     x   x   x    x    x    N
#
#                                 X   X   X
#
#                                     X
#
#                                     W
#
#
# x electrodes set to voltage, "x"
# X electrodes set to voltage, "x + 0.25*x"
#
# called by:  command line
#
# plk 12/20/2004
#-----------------------------------------------------------------------------
proc poke13bins { inVoltage } {

set theBinLevel 4

set theWestChipSideVoltage [expr $inVoltage + 0.06*$inVoltage]


pokeNxNbin 2 17 $theBinLevel $theWestChipSideVoltage

pokeNxNbin 9 9 $theBinLevel $theWestChipSideVoltage
pokeNxNbin 9 17 $theBinLevel $theWestChipSideVoltage
pokeNxNbin 9 25 $theBinLevel $theWestChipSideVoltage

pokeNxNbin 17 2 $theBinLevel $inVoltage
pokeNxNbin 17 9 $theBinLevel $inVoltage
pokeNxNbin 17 17 $theBinLevel $inVoltage
pokeNxNbin 17 25 $theBinLevel $inVoltage
pokeNxNbin 17 32 $theBinLevel $inVoltage


pokeNxNbin 25 9 $theBinLevel $inVoltage
pokeNxNbin 25 25 $theBinLevel $inVoltage
pokeNxNbin 25 17 $theBinLevel $inVoltage

pokeNxNbin 32 17 $theBinLevel $inVoltage

}


