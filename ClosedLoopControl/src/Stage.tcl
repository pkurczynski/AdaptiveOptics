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
## 	Stage.tcl
## 
## CONTENTS:
## 
## 	Stage commands available from the TCL prompt.
## 
## 
## $Id: Stage.tcl,v 1.13 1999/07/02 23:20:31 stacy Exp $
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
## 	stage.init
## 
## ARGUMENTS:	
## 
## 	port - serial port where stage is connected 
## 
## 
## RETURN:	
## 
## 	message
## 
## DESCRIPTION:	
## 
## 	Opens and initializes the serial connection to the stage.
## 
## 
## 
## 
##---------------------------------------------------------------------------

proc stage.init { port } {
    global platform
    
    if { $platform == "windows" } {
	global ws_comp
	if { [catch {set ws_comp [open $port r+]} ] } {  
		return "";
	}
	fconfigure $ws_comp -mode 9600,n,8,1 -blocking 1 -buffering full 
	stage.do C
	stage.do " "
	stage.do \n
	stage.do \n
	stage.do \r
	return {Serial connection to stage opened and initialized.}
    } else {
	stage.open $port;
	stage.do C;
	stage.do " ";
	stage.do 10;
	stage.do 10;
	stage.do 13;
	return {Serial connection to stage opened and initialized.}
    }
}

proc stage.shut { } {
    global platform
    
    if { $platform == "windows" } {
	global ws_comp
	close $ws_comp
    } else {
	stage.close
    }
}

#---------------------------------------------------------------------------
##TCLAPI
## 
## PROCEDURE:	
## 
## 	stage.move.absolute
## 
## ARGUMENTS:	
## 
## 	pos - absolute position
## 
## 
## RETURN:	
## 	
## 	
## 
## DESCRIPTION:	
## 
## 	Move the stage to an absolute position.
## 
## 
## 
## 
##---------------------------------------------------------------------------

proc stage.move.absolute { pos } {
    stage.do "R$pos"
    while { [stage.get.moving] == 1 } {
	update
    } 
    return $pos
}

proc stage.calibrate.absolute { pos } {
    set step [expr $pos + 100]
    stage.do "R$step"
    stage.do "R$pos"
    while { [stage.get.moving] == 1 } { 
	update
    }
    return $pos 
}

#---------------------------------------------------------------------------
##TCLAPI
## 
## PROCEDURE:	
## 
## 	stage.move.relative
## 
## ARGUMENTS:	
## 
## 	pos - relative position ( positive or negative )
## 
## 
## RETURN:	
## 
## 
## 
## DESCRIPTION:	
## 
## 	Move the stage to a relative position
## 
## 
## 
## 
##---------------------------------------------------------------------------

proc stage.move.relative { pos } {
    if {$pos>0} { 
	return [stage.do +$pos] 
    } else {
	return [stage.do $pos]
    }
}


#---------------------------------------------------------------------------
##TCLAPI
## 
## PROCEDURE:	
## 
## 	stage.get.moving
## 
## ARGUMENTS:	
## 
## 	NONE	
## 
## 
## RETURN:	
## 
## 	0 	stage not moving
## 	1	stage moving
##
## DESCRIPTION:	
## 
##	Determines if is stage is already in motion
## 
## 
## 
## 
##---------------------------------------------------------------------------

proc stage.get.moving { } {
    set reply [lindex [stage.do ^] 1]
    if { $reply=="0" } {
	return 0
    } else {
	return 1
    }
}

# ****************************************************************************
#  stage.move.home
# 
# ****************************************************************************

proc stage.move.home { vel dir } {
    if {{$i=="left"}||{$i=="0"}||{$i=="negative"}} {
	return [stage.do { F $vel 0 }]
    } else {
	return [stage.do { F $vel 1 }]
    }
}


#---------------------------------------------------------------------------
##TCLAPI
## 
## PROCEDURE:	
## 
## 	stage.move.velocity
## 
## ARGUMENTS:	
## 
## 	val - velocity
## 
## 
## RETURN:	
## 
## 	
## 
## DESCRIPTION:	
## 
## 	Move the stage at a constant velocity, with + or - direction.
## 
## 
## 
## 
##---------------------------------------------------------------------------

proc stage.move.velocity { val } {
    if { $val > 4500 } { set val 4500 }
    if { $val < 20 } { set val 20 } 
    return [lindex [stage.do "M $val"] 1]
}


#---------------------------------------------------------------------------
##TCLAPI
## 
## PROCEDURE:	
## 
## 	stage.stop
## 
## ARGUMENTS:	
## 
## 	NONE
## 
## 
## RETURN:	
## 
## 	NONE
## 
## DESCRIPTION:	
## 
## 	Stops the motion of the stage.
## 
## 
## 
## 
##---------------------------------------------------------------------------

proc stage.stop { } {
    stage.do @
}


#---------------------------------------------------------------------------
##TCLAPI
## 
## PROCEDURE:	
## 
## 	stage.set.origin
## 
## ARGUMENTS:	
## 
## 	NONE
## 
## 
## RETURN:	
## 
## 	NONE
## 
## DESCRIPTION:	
## 
## 	Sets the stage origin to the current position.
## 
## 
## 
## 
##---------------------------------------------------------------------------

proc stage.set.origin { } {
    stage.do O
}

#---------------------------------------------------------------------------
##TCLAPI
## 
## PROCEDURE:	
## 
## 	stage.get.position
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
## 	Gets the position of the stage.
## 
## 
## 
## 
##---------------------------------------------------------------------------

proc stage.get.position { } {
    return [stage.do Z]
}


#---------------------------------------------------------------------------
##TCLAPI
## 
## PROCEDURE:	
## 
## 	stage.write.port
## 
## ARGUMENTS:	
## 
## 	val - value to set the output ports
## 
## 
## RETURN:	
## 
## 
## 
## DESCRIPTION:	
## 
## 	Writes a value to set the output ports
## 
## 	"A"DATA		OUT1	OUT2	OUT3
## 	   0		low 	low	low		
## 	   8 		high	low 	low
##	  16		low 	high	low
##	  24		high 	high	low
## 	  32		low 	low	high
##	  40		high 	low	high
##	  48	       	low	high	high
##	  56 		high	high	high
##
##---------------------------------------------------------------------------

proc stage.write.port { val } {
    if {($val>=0) && ($val<=128)} {
	stage.do "A $val"
    }
}


#---------------------------------------------------------------------------
##TCLAPI
## 
## PROCEDURE:	
## 
## 	stage.read.port
## 
## ARGUMENTS:	
## 
## 	NONE
## 
## 
## RETURN:	
## 
##      State of the general purpose inputs and outputs.
## 
## DESCRIPTION:	
## 
## 	Reads the input and output ports.
## 
## 	bit 7 |	bit 6 |	bit 5 |	bit 4 |	bit 3 |	bit 2 |	bit 1 |	bit 0
##            |       |       |       |       |       |       |       
## 	 n/a  |	 n/a  |	 out3 |	 out2 |	 out1 |	 in3  |	 in2  |	 in1
##            |       |       |       |       |       |       |       
## 	bit weights   |	  32  |	  16  |	  8   |	  4   |   2   |	  1
##
##---------------------------------------------------------------------------

proc stage.read.port {} {
    stage.do "A 129"
}
    

###########################################################################
#				END OF FILE
###########################################################################








