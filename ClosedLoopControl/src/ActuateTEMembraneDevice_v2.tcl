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
# version 2
# plk 12/16/2004
#--------------------------------------------------------

set gNumRows 37
set gNumColumns 37

set Vm 0
set Varray 0




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
# called by: ActuateWestChipSector
#
# plk 12/10/2004
#--------------------------------------------------------
proc pokeNcolumns {inStartColumn inNumColumns inVoltage} {

     # DEBUG statement
     puts stdout "       Now executing pokeNrows"

     global gNumRows
     global gNumColumns

     set theStopColumn [expr $inStartColumn + $inNumColumns]
     for {set i 1} {$i <=$gNumRows} {incr i} {
        for {set j $inStartColumn} {$j <= $theStopColumn} {incr j} {

            set theHDActuatorNum [expr $i * $gNumColumns + $j]

            # DEBUG statement
            # puts stdout "      Actuator Number: $theHDActuatorNum"

            dm.pokeraw $theHDActuatorNum $inVoltage

        }
     }
}


#--------------------------------------------------------
# ArrayControlGUI
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
proc ArrayControlGUI { } {


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
        -text "EMO NOW! " \
        -width 20 \
        -height 5 \
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
# called by:  ArrayControlGUI
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
# called by:  ArrayControlGUI
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

     puts stdout "       Now executing executeSetArray"
     puts stdout "             Vm = $Vm   Varray = $Varray"

}

proc executeEmergencyOff {w} {

     #setzero
     
     $w config -bg LightBlue1
     $w.buttons config -bg LightBlue1

     puts stdout " EMO executed.  Voltages set to zero"
     destroy $w
}
