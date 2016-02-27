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

#---------------------------------------------------------------------------#
##TCLSRC
## 
## FILE:
## 
## 	Stage_Positions.tcl
## 
## CONTENTS:
## 
## 
## 
## 
## $Id: Stage_Positions.tcl,v 1.9 1998/02/04 21:33:01 stacy Exp $
## 
##--------------------------------------------------------------------------#

###########################################################################
#				  GLOBALS
###########################################################################

###########################################################################
#				PROCEDURES
###########################################################################


#---------------------------------------------------------------------------
##TCLAPI
## 
## PROCEDURE:	
## 
## 	Stage_Positions
## 
## ARGUMENTS:	
## 
## 	NONE
## 
## 
## RETURN:	
## 
## 
## 
## DESCRIPTION:	
## 
##      Sets the stage positions based on the position of the PupilImage.
##    
##      
##    
##
##---------------------------------------------------------------------------

proc Stage_Positions { } { 

    global stagePos wsMLMParams stageParams wlCalibrate

    set f [ expr $wsMLMParams(fl) *  $stageParams(StepsPerMM)]
    
    set stagePos(PupilImage) $stageParams(PosPupilImage)
    
#
# Try something to fix the stage wobble
#

    set stagePos(CloserPupilImage) [ expr $stagePos(PupilImage) - $stageParams(StepsPerMM) ]
    set stagePos(FartherPupilImage) [ expr $stagePos(PupilImage) + $stageParams(StepsPerMM) ]

    set stagePos(BestRefSpots) [ expr $stagePos(PupilImage) + $f ]

    set diff [ expr ($f * 0.8) / $stageParams(StepsPerMM) ]
    set diff [ expr  int($diff)  * $stageParams(StepsPerMM) ]
    set stagePos(CloserRefSpots) [ expr $stagePos(PupilImage) + $diff]

    set list { PupilImage CloserPupilImage FartherPupilImage BestRefSpots \
		   CloserRefSpots }
    if { [file exists $wlCalibrate(saveDir)] } {
	set fileid [open $wlCalibrate(saveDir)/calData a]
	foreach i $list {
	    puts $fileid "set stagePos($i) {$stagePos($i)}"
	}
	close $fileid
    }
}

###########################################################################
#				END OF FILE
###########################################################################
