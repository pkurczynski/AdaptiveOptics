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
## 	Atp.tcl
## 
## CONTENTS:
## 
##	Tests for performance and stage wobble.
## 
## 
## $Id: ATP.tcl,v 1.2 2000/05/24 20:46:59 herb Exp $
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
## 	ATP
## 
## ARGUMENTS:	
## 
## 	unit #
## 
## RETURN:	
## 
## 	
## 
## DESCRIPTION:	
## 
## 	Tests to see if the system passes the accuracy, repeatabiliy and
##	dynamic range for all 3 MLMs.
## 
## 
## 
##---------------------------------------------------------------------------

proc doOpds { MLM } \
{
	cd ../opd1MLM${MLM}
	a.load Opds/0001 = opd1
	cd ../opd2MLM${MLM}
	a.load Opds/0001 = opd2
	cd ../opd3MLM${MLM}
	a.load Opds/0001 = opd3
	
	a.sub opd1 opd2 = sub1
	a.sub opd1 opd3 = sub2
	a.sub opd2 opd3 = sub3
	
	a.rms sub1 = rms1
	a.rms sub2 = rms2
	a.rms sub3 = rms3
	
	set averms [a.ave rms1 rms2 rms3]
	return $averms
}

proc doGrads { MLM } \
{
	global avegrad
	
	cd ../opd1MLM${MLM}
	a.load Gradients/0001 = grad1
	cd ../opd2MLM${MLM}
	a.load Gradients/0001 = grad2
	cd ../opd3MLM${MLM}
	a.load Gradients/0001 = grad3
	
	a.sub grad1 grad2 = sub1
	a.sub grad1 grad3 = sub2
	a.sub grad2 grad3 = sub3
	
	a.rms sub1 = rms1
	a.rms sub2 = rms2
	a.rms sub3 = rms3

	a.ave rms1 rms2 rms3 = avegrad
}

proc ATP { unit } \
{
	global avegrad platform
	
	puts ""
	
	puts "**********Acceptance Test Procedure for $unit************"
		
	puts ""
	
	if { $platform == "windows" } { 
		set ttt [clock seconds]			
 		puts "Test performed on [clock format $ttt -format %c]"
      } else { 
		puts "Test performed on [exec date]"
	}

	puts ""

	foreach MLM { 133 300 480 } { 
	
	cd /usr/data/TESTS/${unit}TestB
	set flag 0
	
	puts "$MLM MLM"
	
	cd opd1MLM${MLM}
	a.load Zernikes/0001 = zern
	a.v2toxy zern = num val
	set abs [a.extele val 2]
	
#Min and max values of 3rd Zernike calculated by adding +/- half of theoretical accuracy
#of gradient measurement to -0.255
	
	if { $MLM == 133 } {
		set minzern -0.274
		set maxzern -0.236 
	}
	if { $MLM == 300 } {
		set minzern -0.265
		set maxzern -0.245
	}
	if { $MLM == 480 } {
		set minzern -0.267
		set maxzern -0.243 
	}
	if { ($abs < $maxzern ) && ( $abs > $minzern )} {
		puts "Absolute Accuracy 3rd Zernike should be between $maxzern and $minzern  $abs         -- PASS!"
	} else {
		puts "Absolute Accuracy 3rd Zernike should be between $maxzern and $minzern  $abs         -- FAIL!!!"
		set flag 1
	}
	
	set aveopd [doOpds $MLM]
#set opdacc to be 2*(2)^0.5/3^0.5 (factor of 2 as 4 grads ared added and (3^0.5) as we average
#3 measurements the accuracy of each measurement.
	
	if { $MLM == 133 } {
		set opdacc 0.0588
	}
	if { $MLM == 300 } {
		set opdacc 0.0310
	}
	if { $MLM == 480 } {
		set opdacc 0.0392 
	}
	if { $aveopd < $opdacc } {
    		puts "Relative Accuracy for Opds should be $opdacc microns and is \t$aveopd microns -- PASS!"
	} else {
		puts "Relative Accuracy for Opds should be $opdacc microns and is \t$aveopd microns -- FAIL!!!"
		set flag 1
	}
	
	doGrads $MLM
	a.v4tov2v2 avegrad = pos val
	a.v2toxy val = dx dy
	set x [a.dump dx]
	set y [a.dump dy]
	
#Choose the appropriate relative accuracy of the gradients for each MLM multiplied by (2/3)^0.5

	if { $MLM == 133 } {
		set gradacc 0.0294 
	}
	if { $MLM == 300 } {
		set gradacc 0.0155 
	}
	if { $MLM == 480 } {
		set gradacc 0.0196 
	}
	
	
	if { $x < $gradacc } {
    		puts "Relative Accuracy for x Gradients should be $gradacc microns and is $x microns -- PASS!"
	} else {
		puts "Relative Accuracy for x Gradients should be $gradacc microns and is $x microns -- FAIL!!!"
		set flag 1
	}
	if { $y < $gradacc } {
    		puts "Relative Accuracy for y Gradients should be $gradacc microns and is $y microns -- PASS!"
	} else {
		puts "Relative Accuracy for y Gradients should be $gradacc microns and is $y microns -- FAIL!!!"
		set flag 1
	}
	
	cd ../opd4MLM${MLM}
	a.load Zernikes/0001 = z1
	a.v2toxy z1 = num val
	a.extele val 0 = ave
	set value [a.dump ave]
	a.abs ave = avet
	set avetilt [ a.dump avet ]
	
	if { ($avetilt > 128) && ($avetilt < 144) } { 
		puts "Dynamic range should be 136 +/- 8\t\t\t\t$value\t      -- PASS!"
	} else {
		puts "Dynamic range should be 136 +/- 8 \t\t\t\t$value\t      -- FAIL!!!"
		set flag 1
	} 
	
	if { $flag == 0 } { 
		puts "All tests PASSED for MLM $MLM"
	} else {
		puts "MLM $MLM FAILED"
	}
	puts ""
	}
	cd /usr/home/wavescope
}	

#---------------------------------------------------------------------------
##TCLAPI
## 
## PROCEDURE:	
## 
## 	StageWobblel
## 
## ARGUMENTS:	
## 
## 	stage_position (4200 fo spots) 
##      n   Number of samples
## 	max_error - wobble tollerance ( < .1 to pass)
## 
## RETURN:	
## 
## 	message
## 
## DESCRIPTION:	
## 
## 	Tests to see if stage wobble is acceptably small.
## 
## 
## 
## 
##---------------------------------------------------------------------------

proc StageWobblel {position  n max_error} {


puts "position = $position, n = $n, Max error = $max_error"
## Global declarations
## Declare global anything that I want to see from Tcl after end of this procedure

	
	global difarr difnot bigr circ wid wlCalibrate

   set wlCalibrate(idxpos) 500
   set wlCalibrate(idypos) 200
	
## Establish Controller communication and origin
## These eteps are needed if the power is turned OFF on the controller
## and you do not wish to exit from WaveScope
 
   puts {  Establishing controller communication and origin } 


## the better way of doing it

    	hardware_init
    	
## The hard way of doing hardware init
##   	stage.init /dev/ttyS0  ## setup serial port
##   	stage_init	
##   	stage_set_limit_b_origin
##   	while { [stage.get.moving] == 1 } { }
 
## go to spot focus position
  
   	puts "Going to spots location $position"
   	stage.move.absolute $position
   	while { [stage.get.moving] == 1 } { }
   	puts "Check that lens is showing sharp spots and "
   	puts "Check and adjust focus and exposure if needed"
   	set_test_spot_exposure
##   	gets stdin kkk
   
## grab spot images at n 45 degree intervals of motor motion

	for { set i 0 } { $i < $n } { incr i } \
	{
		puts "Taking image number $i"
		fg.grab 1 = pos$i
		stage.move.relative 25
	}

	
## find rectangles of 1st spot image

	puts { Finding reference rectangle of first image }
	alg.find.rects pos0 = rect
	
## fit spots for all images, take first pos as reference

	alg.fit.spots pos0 rect = sp0
	a.copy sp0 = sparr
	
	for { set i 1 } { $i < $n } { incr i } \
	{
		
		alg.fit.spots pos$i rect = sp
		a.catrow sparr sp = sparr
	}


## calculate difference between spots

	puts { Calculating differences }
	a.sub sparr sp0 = difarr
	
	
## analysis
	
	puts { doing stuff }
	
	puts "form average for each frame"
	set cols [a.cols difarr]
	a.rebin difarr $cols 1 = difave
	
	puts "fit to global tilt"
	a.v2toxy difave = difx dify
	a.tilt $n 0 1 = ramp
	alg.regress ramp difx = coefx
	
	alg.regress ramp dify = coefy
	
	a.ext coefx 0 1 = axx
	a.ext coefx 1 1 = bxx
	a.ext coefy 0 1 = ayy
	a.ext coefy 1 1 = byy
	
	set ax [a.ave axx ]
	set bx [a.ave bxx ]
	set ay [a.ave ayy ]
	set by [a.ave byy ]
	
	puts "remove global tilt"
	a.tilt  $n $bx  $ax = rx
	a.tilt  $n $by  $ay = ry
	a.xytov2 rx ry = ramp
	a.shape difave $n = difave
	a.sub difave ramp = difnot
	
	puts "find amplitude"
	a.tilt $n 0 0.785398 = ang
	a.sin ang = sss
	a.cos ang = ccc
	a.v2toxy difnot = dx dy
	alg.regress sss ccc dx = coefx
	a.ext coefx 0 1 = aax
	a.ext coefx 1 1 = bbx
	a.ext coefx 2 1 = ccx
	
	alg.regress sss ccc dy = coefy
	a.ext coefy 0 1 = aay
	a.ext coefy 1 1 = bby
	a.ext coefy 2 1 = ccy
	
	set aaax [a.ave aax]
	set bbbx [a.ave bbx]
	set cccx [a.ave ccx]
	set phasex [expr atan2( $bbbx , $aaax )]
	set sphasex [expr sin($phasex)]
	set cphasex [expr cos($phasex)]
	set ampsx [expr $aaax / $cphasex ]
	set ampcx [expr $bbbx / $sphasex ]
	puts "doing x"
	puts "sin amp = $ampsx  cos amp = $ampcx  phase = $phasex  offset = $cccx"
	
	set aaay [a.ave aay]
	set bbby [a.ave bby]
	set cccy [a.ave ccy]
	set phasey [expr atan2( $bbby , $aaay )]
	set sphasey [expr sin($phasey)]
	set cphasey [expr cos($phasey)]
	set ampsy [expr $aaay / $cphasey ]
	set ampcy [expr $bbby / $sphasey ]
	puts "doing y"
	puts "sin amp = $ampsy  cos amp = $ampcy  phase = $phasey  offset = $cccy"
	
	#make a model
	a.make "< 0 0 0 0 >" 100 = circ
	for { set i 0 } { $i < 100 } { incr i } \
	{
		set angl1 [expr (6.28318 * $i) / 100. ]
		set angl2 [expr (6.28318 * ( $i + 1)) / 100. ]
		
		set xx1 [expr $ampsx * [expr sin([expr $angl1 + $phasex ])] + $cccx ]
		set yy1 [expr $ampsy * [expr sin([expr $angl1 + $phasey ])] + $cccy ]
		set xx2 [expr $ampsx * [expr sin([expr $angl2 + $phasex ])] + $cccx ]
		set yy2 [expr $ampsy * [expr sin([expr $angl2 + $phasey ])] + $cccy ]
		
		a.repele "< $xx1 $yy1 $xx2 $yy2 >" circ $i = circ
		
	}
	
	#make a display
	id.new wid
	a.make 1 2 2 = dum
	id.set.array wid dum
	a.add difnot "< 1 1 >" = poss
	a.add circ "< 1 1 1 1 >" = cir
	id.set.over.array wid cir
	id.set.pos.array wid poss
	
	set fulamp [expr sqrt( [expr ($ampsx * $ampsx) + ($ampsy * $ampsy)] )]
	
	if { $fulamp > $max_error } { puts "Failed, Error = $fulamp" } else \
		{ puts "Passed, Error = $fulamp" }

## Restoring Pupil focus at test end location

	puts {Going to pupil location 1000}
	stage.move.absolute 1000
   	while { [stage.get.moving] == 1 } { }
   	puts "Check that lens focus is set for pupil image"
   	puts "Press Enter after checking focus"
   	set_test_spot_exposure
##   	gets stdin kkk
	
}


###########################################################################
#				END OF FILE
###########################################################################








