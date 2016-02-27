#===========================================================================#
# 
# 			Adaptive Optics Associates
# 			  54 CambridgePark Drive
# 			 Cambridge, MA 02140-2308
# 				    USA
# 			   (Phone) 617-864-0201
# 			    (Fax) 617-864-1348
# 
# 			  Copyright (C) 1997 AOA
# 			    All Rights Reserved
# 
#===========================================================================#
# 
# File:
# 
# 	scripts/Makefile
# 
# Description:
# 
# 	Makefile to build the Wavescope scripts
# 
# $Id: Makefile,v 1.28 1999/09/29 17:02:14 stacy Exp $
# 
#===========================================================================#

#
# Project
#
PROJECT			= wavescope

#
# Wavelab Scripts
#
TCLSCRIPT_TARGETS	= wavescope

wavescope.INSTALL_DIR	= $(PROJECT_SCRIPT_DIR)
wavescope.SOURCES		= \
				ActiveAl.tcl \
				Alignment.tcl \
				CalcSeidel.tcl \
				Calibrate.tcl \
				ContTest.tcl \
				Convert.tcl \
				DataMan.tcl \
				Help.tcl \
				IO.tcl \
				ListBox.tcl \
				Main.tcl \
				Panels.tcl \
				Parameters.tcl \
				RunInfo.tcl \
				Stage.tcl \
				StageSetup.tcl \
				Stage_Positions.tcl \
				Test_proc.tcl \
				TestEx.tcl \
				circle.tcl \
				m2.tcl \
				rect_pupil.tcl \
				put_displays.tcl \
				TextDisp.tcl \
				slice.tcl \
				system.tcl \
				wsGUI.tcl \
				wsData.tcl \
				ws_Init.tcl 

#
# X Application defaults, logos, bitmaps, any miscellaneous files
#
NONEXEC_TARGETS		+= misc
misc.SOURCES		= AOA_UTblue.gif WaveScope_UTblue.gif \
	AOA_Blue.gif WaveScope_Blue.gif
misc.INSTALL_DIR	= $(PROJECT_SCRIPT_DIR)

