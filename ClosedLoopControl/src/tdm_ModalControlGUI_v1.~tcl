#------------------------------------------------------------------------
# tdm_ModalControlGUI.tcl                          tcl script
#
# Procedures used in control of transparent electrode membrane mirror
# to implement modal control algorithm.
#
# Procedures in this file:
#               makeWavefront
#               displaySineWavefrontPanel
#               destroySSWPanel
#               generateUserDefWavefront
#               commandDMToUserDefWavefront
#               iterateOneWavefrontCorrection
#               displayWavefront
#               generateSineYWavefront
#
# Note:  to initialize procedures in this file with the wavescope
# software, add lines such as the following to the tclIndex.tcl file
# in usr/aos/wavescope/scripts/
#        e.g. set auto_index(makeWavefront) \
#               [list source [file join tdm_MakeWavefrontProcedures.tcl]]
#
# version 1
# plk 05/15/2005
#------------------------------------------------------------------------


# parameter for closed loop iteration
global gMCStepSizeParameter



# flag used in GUI
global gFlattenDMUsingModalControlFlag


# window IDs for wavescope image/data
global MODALCONTROL_OPD_WID
global MODALCONTROL_OPD_WD


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


    frame .mcPanel.f.clb.ctl
    pack  .mcPanel.f.clb.ctl -anchor w -pady 5


    button .mcPanel.f.clb.ctl.sdes -text "Train DM..." \
                                    -command { trainDMForModalControl }

    button .mcPanel.f.clb.ctl.cmd  -text "Command DM..."
    #                                -command { commandDMToUserDefWavefront }

    button .mcPanel.f.clb.ctl.sact -text "Show Actual..."
    #                                -command { displayActualWavefront }

    pack   .mcPanel.f.clb.ctl.sdes \
           .mcPanel.f.clb.ctl.cmd \
           .mcPanel.f.clb.ctl.sact \
           -side left \
           -padx 5


    frame .mcPanel.f.clb.cll
    pack  .mcPanel.f.clb.cll -anchor center -pady 5



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

    pack .mcPanel.f.clb.cll.colb \
         .mcPanel.f.clb.cll.scaleMCStepSizeParameter


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
   global gmcModeNumber
   global gmcAmplitude
   global gmcConstOffset_units
   global gMCStepSizeParameter
   

   destroy .mcPanel

   #DEBUG
   puts stdout "Modal Control Interation Step Size:  $gMCStepSizeParameter"

}

 