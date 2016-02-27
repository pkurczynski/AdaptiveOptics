#------------------------------------------------------------------------
# tdm_ModalControlGUI.tcl                          tcl script
#
# Procedures used in control of transparent electrode membrane mirror
# to implement modal control algorithm.
#
# Procedures in this file:
#              modalControl
#              displayModalControlPanel
#              destroymcPanel
#              loadTrainingData
#              saveTrainingData
#              displaySemiAutoCalibrationPanel
#              destroySatPanel
#              displayValidateCalibrationPanel
#              destroyVdtPanel
#
# Note:  to initialize procedures in this file with the wavescope
# software, add lines such as the following to the tclIndex.tcl file
# in usr/aos/wavescope/scripts/
#        e.g. set auto_index(makeWavefront) \
#               [list source [file join tdm_MakeWavefrontProcedures.tcl]]
#
# version 9
# plk 06/15/2005
#------------------------------------------------------------------------


# parameter for closed loop iteration
global gMCStepSizeParameter

global gNAPerSide

# flag used in GUI
global gFlattenDMUsingModalControlFlag


# window IDs for wavescope image/data
global MODALCONTROL_OPD_WID
global MODALCONTROL_OPD_WD


global gFirstTestActuatorRow
global gFirstTestActuatorCol
global gSecondTestActuatorRow
global gSecondTestActuatorCol

global gCurrentTestActuatorRow
global gCurrentTestActuatorCol



#---------------------------------------------------------------------------
# modalControl
#
# Initiates the modal control GUI.
#
# called by:  command line (wish shell)
#
# plk 12/31/2004
#---------------------------------------------------------------------------
proc modalControl {} \
{
   global gTrainDMForModalControlFlag


   set gTrainDMForModalControlFlag 0
   displayModalControlPanel

   
}




#---------------------------------------------------------------------------
# displayModalControlPanel
#
# Creates a GUI for the modal control algorithm.
#
# uses procedures (event handlers):
#               trainDMForModalControl
#               flattenDMUsingModalControl
#
# Called by: modalControl
#
# plk 05/16/2005
#---------------------------------------------------------------------------
proc displayModalControlPanel { } \
{
   global gMCStepSizeParameter
   global gModalControlNumberOfActuatorsPerBin
   global gNAPerSide

    if { [winfo exists .mcPanel] } {
	destroy .mcPanel
    }
    toplevel .mcPanel
    wm title .mcPanel "Modal Control Panel"
    wm geometry .mcPanel -30+90
    frame  .mcPanel.f
    pack   .mcPanel.f
    frame  .mcPanel.f.clb -relief groove -bd 2
    button .mcPanel.f.ok -text "  OK  " \
                          -font "helvetica" \
                          -command {destroymcPanel}
    pack   .mcPanel.f.clb .mcPanel.f.ok -padx 5 -pady 5


    frame .mcPanel.f.clb.ctq
    pack  .mcPanel.f.clb.ctq -anchor w -pady 5


    button .mcPanel.f.clb.ctq.sdes -text "Regist Coord..." \
                                    -command { displayRegisterCoordsPanel }

    button .mcPanel.f.clb.ctq.cmd  -text "Load Registration" \
                                    -command { displayRegisterCoordsPanel }

    button .mcPanel.f.clb.ctq.sact -text "Save Registration..." \
                                    -command { displayRegisterCoordsPanel }

    pack   .mcPanel.f.clb.ctq.sdes \
           .mcPanel.f.clb.ctq.cmd \
           .mcPanel.f.clb.ctq.sact \
           -side left \
           -padx 5





    frame .mcPanel.f.clb.ctl
    pack  .mcPanel.f.clb.ctl -anchor w -pady 5


    button .mcPanel.f.clb.ctl.sdes -text "Calibrate DM..." \
                                    -command { displaySemiAutoCalibrationPanel }

    button .mcPanel.f.clb.ctl.cmd  -text "Load Calibration..." \
                                    -command { loadCalibrationData }

    button .mcPanel.f.clb.ctl.sact -text "Save Calibration..." \
                                    -command { saveCalibrationData }

    pack   .mcPanel.f.clb.ctl.sdes \
           .mcPanel.f.clb.ctl.cmd \
           .mcPanel.f.clb.ctl.sact \
           -side left \
           -padx 5


    frame .mcPanel.f.clb.ctx
    pack  .mcPanel.f.clb.ctx -anchor w -pady 5

    button .mcPanel.f.clb.ctx.traindm -text "   Train DM...   " \
                                    -command { displayDMTrainingPanel }

    button .mcPanel.f.clb.ctx.loadtrain  -text "Load Training...    " \
                                    -command {  }

    button .mcPanel.f.clb.ctx.savetrain -text "Save Training...   " \
                                    -command {  }

    pack   .mcPanel.f.clb.ctx.traindm \
           .mcPanel.f.clb.ctx.loadtrain \
           .mcPanel.f.clb.ctx.savetrain \
           -side left \
           -padx 5


    frame .mcPanel.f.clb.cll
    pack  .mcPanel.f.clb.cll -anchor center -pady 5

    scale .mcPanel.f.clb.cll.scaleMCActuatorBinParameter \
             -from 1 \
             -to 32 \
             -length 200 \
             -orient horizontal \
             -resolution 1 \
             -label "Actuator Binning:  NxN Actuators Per Bin" \
             -variable gNAPerSide


    scale .mcPanel.f.clb.cll.scaleMCStepSizeParameter \
             -from 0 \
             -to 0.2 \
             -length 200 \
             -orient horizontal \
             -resolution 0.001 \
             -label "Modal Control Iteration Step Parameter" \
             -variable gMCStepSizeParameter


    checkbutton .mcPanel.f.clb.cll.colb \
           -text "Close Loop: Flatten membrane" \
           -variable gFlattenDMUsingModalControlFlag \
           -command { flattenDMUsingModalControl }

           
    pack .mcPanel.f.clb.cll.scaleMCActuatorBinParameter \
         .mcPanel.f.clb.cll.scaleMCStepSizeParameter \
         .mcPanel.f.clb.cll.colb

    update


}




#---------------------------------------------------------------------------
# destroymcPanel
#
# Destroys the SphereWavefrontPanel, optionally prints the values of
# the global variables set by the user to stdout.
#
#
# Called by: displayModalControlPanel
#
# plk 12/31/2004
#---------------------------------------------------------------------------
proc destroymcPanel { } \
{
   global gNAPerSide

   destroy .mcPanel

   #DEBUG
   puts stdout "Actuators per side:  $gNAPerSide"

}


#---------------------------------------------------------------------------
# loadCalibrationData
#
# Loads previously saved training data.
#
# called by:  displayModalControlPanel
#---------------------------------------------------------------------------
proc loadCalibrationData { } \
{
   global gActuatorPositionV4
   global gTrainDMForModalControlFlag


   set theAPFileName "ActuatorPositions.txt"

   a.loadasc $theAPFileName v4 = gActuatorPositionV4
   puts stdout "Loaded data from file:  $theAPFileName"
   puts stdout "Ready for closed loop operation."


   set gTrainDMForModalControlFlag 1


   #DEBUG
   #puts stdout "[a.dump gActuatorPositionV4]"
}


#---------------------------------------------------------------------------
# saveCalibrationData
#
# Saves training data. ASCii format.  Current default directory ?
#
# called by:  displayModalControlPanel
#---------------------------------------------------------------------------
proc saveCalibrationData { } \
{
   global gActuatorPositionV4

   set theAPFileName "ActuatorPositions.txt"


   a.saveasc gActuatorPositionV4 $theAPFileName
   puts stdout "Saved training data to file: $theAPFileName"

   #DEBUG
   #puts stdout "[a.dump gActuatorPositionV4]"
}



#---------------------------------------------------------------------------
# displayRegisterCoordsPanel
#
# Creates a GUI for the coordinate registration procedure.
#
# uses procedures (event handlers):
#
# Called by: displayModalControlPanel
#
# plk 05/16/2005
#---------------------------------------------------------------------------
proc displayRegisterCoordsPanel { } \
{
    global gNAPerSide
    global gFirstTestActuatorRow
    global gFirstTestActuatorCol
    global gSecondTestActuatorRow
    global gSecondTestActuatorCol


    if { [winfo exists .rcPanel] } {
	destroy .rcPanel
    }
    toplevel .rcPanel
    wm title .rcPanel "Coordinate Registration"
    wm geometry .rcPanel -30+90
    frame  .rcPanel.f
    pack   .rcPanel.f
    frame  .rcPanel.f.clb -relief groove -bd 2




    button .rcPanel.f.sdes -text "Register" \
                            -command { registerCoordsForModalControl }


    button .rcPanel.f.ok -text "  OK  " \
                          -font "helvetica" \
                          -command {destroyRCPanel}

    pack   .rcPanel.f.clb


    pack   .rcPanel.f.sdes \
           .rcPanel.f.ok \
           -side left \
           -padx 5 \
           -pady 10



    frame .rcPanel.f.clb.ctl
    pack  .rcPanel.f.clb.ctl -anchor w -pady 5




    frame .rcPanel.f.clb.cll
    pack  .rcPanel.f.clb.cll -anchor center -pady 5



    button .rcPanel.f.clb.cll.sact -text "Register East" \
                                    -command { calibrateFirstTestActuator }


    pack .rcPanel.f.clb.cll.sact





    button .rcPanel.f.clb.cll.sact2 -text "Register North" \
                                    -command { calibrateSecondTestActuator }


    pack .rcPanel.f.clb.cll.sact2



    update


}




#---------------------------------------------------------------------------
# destroyRCPanel
#
#
#
# Called by: displayRegisterCoordsPanel
#
# plk 12/31/2004
#---------------------------------------------------------------------------
proc destroyRCPanel { } \
{

   destroy .rcPanel

   #DEBUG
   puts stdout "Destroyed .rcPanel"

}



#---------------------------------------------------------------------------
# displaySemiAutoCalibrationPanel
#
# Creates a GUI for the semi-auto calibration procedure.
#
# uses procedures (event handlers):
#     calibrateSemiAutoDMForModalControl
#     validateSemiAutoDMTraining
#     trainDMForModalControl
#     destroySatPanel
#     calibrateFirstTestActuator
#     calibrateSecondTestActuator
#
# Called by: displayModalControl
#
# plk 05/16/2005
#---------------------------------------------------------------------------
proc displaySemiAutoCalibrationPanel { } \
{
    global gNAPerSide
    global gFirstTestActuatorRow
    global gFirstTestActuatorCol
    global gSecondTestActuatorRow
    global gSecondTestActuatorCol


    if { [winfo exists .satPanel] } {
	destroy .satPanel
    }
    toplevel .satPanel
    wm title .satPanel "Semi-Auto Calibration"
    wm geometry .satPanel -30+90
    frame  .satPanel.f
    pack   .satPanel.f
    frame  .satPanel.f.clb -relief groove -bd 2




    button .satPanel.f.sdes -text "Semi-Auto" \
                            -command { calibrateSemiAutoDMForModalControl }

    button .satPanel.f.vald -text "Validate" \
                            -command { displayValidateCalibrationPanel }


    button .satPanel.f.man -text "Manual" \
                          -command {calibrateDMForModalControl}


    button .satPanel.f.ok -text "  OK  " \
                          -font "helvetica" \
                          -command {destroySatPanel}

    pack   .satPanel.f.clb


    pack   .satPanel.f.sdes \
           .satPanel.f.vald \
           .satPanel.f.man \
           .satPanel.f.ok \
           -side left \
           -padx 5 \
           -pady 10



    frame .satPanel.f.clb.ctl
    pack  .satPanel.f.clb.ctl -anchor w -pady 5




    frame .satPanel.f.clb.cll
    pack  .satPanel.f.clb.cll -anchor center -pady 5


    scale .satPanel.f.clb.cll.scaleFirstTestActuatorRow \
             -from 0 \
             -to 32 \
             -resolution $gNAPerSide \
             -length 200 \
             -orient horizontal \
             -label "Test Actuator 1:  Row" \
             -variable gFirstTestActuatorRow

    scale .satPanel.f.clb.cll.scaleFirstTestActuatorCol \
             -from 0 \
             -to 32 \
             -length 200 \
             -orient horizontal \
             -resolution $gNAPerSide \
             -label "Test Actuator 1:  Column" \
             -variable gFirstTestActuatorCol

    button .satPanel.f.clb.cll.sact -text "Calibrate 1" \
                                    -command { calibrateFirstTestActuator }


    pack .satPanel.f.clb.cll.scaleFirstTestActuatorRow \
         .satPanel.f.clb.cll.scaleFirstTestActuatorCol \
         .satPanel.f.clb.cll.sact




    scale .satPanel.f.clb.cll.scaleSecondTestActuatorRow \
             -from 0 \
             -to 32 \
             -length 200 \
             -orient horizontal \
             -resolution $gNAPerSide \
             -label "Test Actuator 2:  Row" \
             -variable gSecondTestActuatorRow

    scale .satPanel.f.clb.cll.scaleSecondTestActuatorCol \
             -from 0 \
             -to 32 \
             -length 200 \
             -orient horizontal \
             -resolution $gNAPerSide \
             -label "Test Actuator 2:  Column" \
             -variable gSecondTestActuatorCol

    button .satPanel.f.clb.cll.sact2 -text "Calibrate 2" \
                                    -command { calibrateSecondTestActuator }


    pack .satPanel.f.clb.cll.scaleSecondTestActuatorRow \
         .satPanel.f.clb.cll.scaleSecondTestActuatorCol \
         .satPanel.f.clb.cll.sact2




    update


}



#---------------------------------------------------------------------------
# destroySatPanel
#
# Destroys the SphereWavefrontPanel, optionally prints the values of
# the global variables set by the user to stdout.
#
#
# Called by: displayModalControlPanel
#
# plk 12/31/2004
#---------------------------------------------------------------------------
proc destroySatPanel { } \
{

   destroy .satPanel

   #DEBUG
   puts stdout "Destroyed .satPanel"

}




#---------------------------------------------------------------------------
# displayValidateCalibrationPanel
#
# Creates a GUI for the training validation procedure.
#
# uses procedures (event handlers):
#
# Called by: displaySemiAutoCalibrationPanel
#
# plk 06/06/2005
#---------------------------------------------------------------------------
proc displayValidateCalibrationPanel {} \
{
    global gNAPerSide
    global gCurrentTestActuatorRow
    global gCurrentTestActuatorCol

    if { [winfo exists .vdtPanel] } {
	destroy .vdtPanel
    }
    toplevel .vdtPanel
    wm title .vdtPanel "Validate Training"
    wm geometry .vdtPanel -30+90
    frame  .vdtPanel.f
    pack   .vdtPanel.f
    frame  .vdtPanel.f.clb -relief groove -bd 2


    button .vdtPanel.f.poke -text "Poke Actuator" \
                            -command { pokeCurrentActuator }

    button .vdtPanel.f.zero -text "Zero" \
                            -command { setZeroAndUpdateDisplay }


    button .vdtPanel.f.ok -text "  OK  " \
                          -font "helvetica" \
                          -command {destroyVdtPanel}

    pack   .vdtPanel.f.clb

    pack   .vdtPanel.f.poke \
           .vdtPanel.f.zero \
           .vdtPanel.f.ok \
           -side left \
           -padx 5 \
           -pady 10



    frame .vdtPanel.f.clb.ctl
    pack  .vdtPanel.f.clb.ctl -anchor w -pady 5



    frame .vdtPanel.f.clb.cll
    pack  .vdtPanel.f.clb.cll -anchor center -pady 5


    scale .vdtPanel.f.clb.cll.scaleTestActuatorRow \
             -from 0 \
             -to 32 \
             -resolution $gNAPerSide \
             -length 200 \
             -orient horizontal \
             -label "Test Actuator:  Row" \
             -variable gCurrentTestActuatorRow

    scale .vdtPanel.f.clb.cll.scaleTestActuatorCol \
             -from 0 \
             -to 32 \
             -length 200 \
             -orient horizontal \
             -resolution $gNAPerSide \
             -label "Test Actuator:  Column" \
             -variable gCurrentTestActuatorCol

    
    pack .vdtPanel.f.clb.cll.scaleTestActuatorRow \
         .vdtPanel.f.clb.cll.scaleTestActuatorCol \


    update


    displayActuatorGridAndWavefront
}



#---------------------------------------------------------------------------
# destroyVdtPanel
#
# Destroys the VdtPanel
#
#
# Called by: displayValidateCalibrationPanel
#
# plk 12/31/2004
#---------------------------------------------------------------------------
proc destroyVdtPanel { } \
{
   global ACTUATORGRIDANDWAVEFRONT_ID

   destroy .vdtPanel
   id.exit ACTUATORGRIDANDWAVEFRONT_ID

   #DEBUG
   puts stdout "Destroyed .vdtPanel"

}



#---------------------------------------------------------------------------
# pokeCurrentActuator
#
#
#
#
# Called by: displayValidateCalibrationPanel
#
# plk 06/07/2005
#---------------------------------------------------------------------------
proc pokeCurrentActuator { } \
{
   global gCurrentTestActuatorCol
   global gCurrentTestActuatorRow

   
   pokeBinnedActuator gCurrentTestActuatorRow gCurrentTestActuatorCol

}




#---------------------------------------------------------------------------
# setZeroAndUpdateDisplay
#
# sets all actuators to zero.  Takes a wavefront image and puts it on
# the actuatorGridAndWavefront display.
#
#
# Called by: displayValidateCalibrationPanel
#
# plk 06/07/2005
#---------------------------------------------------------------------------
proc setZeroAndUpdateDisplay { } \
{
   setzero
   updateActuatorGridAndWavefrontDisplay

}




#---------------------------------------------------------------------------
# displayDMTrainingPanel
#
#
#
# Called by: 
#
# plk 06/10/2005
#---------------------------------------------------------------------------

proc displayDMTrainingPanel { } \
{
   # no controls are necessary for DM Training at this point.
   # just execute the initialization and training scripts.

   initDMTraining
   trainDM

}

