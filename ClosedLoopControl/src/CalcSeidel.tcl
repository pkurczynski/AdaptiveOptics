proc calcSeidel { } \
{

#####################################################################
# A proc to convert a Zernike coef array into
# the equivalent Seidel Aberration coefficients
# It takes two arguments, the first is the 
# Zernike coef array. The second is an output
# and is a array that
# contains the Seidel coefficients 
# coma astig focus comagang tilt astigang sphere tiltang
#
#####################################################################

    global ws_results wlCalibrate wsParams	
#
# Calculate the zernike coeffs 
#
    set ztype [zern.get.type]
    zern.set.type Zygo
    set PupX [a.extele wlCalibrate(Pupil) 0]
    set PupY [a.extele wlCalibrate(Pupil) 1]
    set PupR [a.extele wlCalibrate(Pupil) 2]
    set PScale [a.extele wlCalibrate(Params) 0]
    set ZScale [expr $PScale * $PupR]
	
    zern.decomp.grad.coefs $ws_results(Gradient) 8 \
	$PupX $PupY $PupR = zern
    a.v2toxy zern = zernin zernco
    a.mul zernco $ZScale = zernco
    a.xytov2 zernin zernco = zc
    zern.set.type $ztype
    update
	
#
# Test to be sure there are enough Zernikes
# Note that this assumes that the Zernike list
# is complete. Other zern.* functions do not make
# this assumption (that is you can have a zernike
# coef array with one element that is Zernike 33)
# but to implement that requires a little more
# code that isn't necessary for this example
#
	
    if {[a.cols zc] < 8} {puts "too few Zernike coeficients"}
    a.make 0 8 = sei
    a.v2toxy zc = iii zcoef
    
#
# Now split up the zern coefs into a tcl array
#
	
    for { set i 1 } { $i < 9 } { incr i } \
    {
	set Zern($i) [a.extele zcoef [expr $i - 1] ]
    }
#
# The rest is the arithmetic to calculate the Seidels
# and then format the output in a readable way
#

#
# Tip and Tilt
#
    set Xtilt [expr $Zern(1) - ( $Zern(6) * 2.0 ) ]
    set Ytilt [expr $Zern(2) - ( $Zern(7) * 2.0 ) ]
    
    set Tmag  [expr $Xtilt * $Xtilt + $Ytilt * $Ytilt]
    set Tmag  [expr sqrt($Tmag)]
    
    if { $Tmag == 0.0 } { set Tang 0.0 } \
    else \
    { set Tang  [expr 57.296 * atan2( $Ytilt,$Xtilt )]  }

    a.repele  $Tmag sei 0 = sei
    a.repele  $Tang sei 1 = sei

#
# Focus
#
    set root [expr $Zern(4) * $Zern(4) + $Zern(5) * $Zern(5)]
    set root [expr sqrt($root)]
    
    set cnst [expr ($Zern(3) * 2.0) - ($Zern(8) * 6.0)]
    
    set t1 [expr abs([expr $cnst + $root])]
    set t2 [expr abs([expr $cnst - $root])]
    
    if { $t1 <= $t2 } { set Sfoc [expr $cnst + $root]  ; set sign -1.0 } \
    else \
    { set Sfoc [expr $cnst - $root] ; set sign 1.0 } 

    a.repele  $Sfoc sei 2 = sei

#
# Astigmatism
#
    set Amag [expr $Zern(4) * $Zern(4) + $Zern(5) * $Zern(5)]
    set Amag [expr [expr sqrt($Amag)] * 2.0 * $sign]
    if { $Amag == 0.0 } { set Aang 0.0 } \
    else \
    { set Aang [expr 28.648 * atan2( $Zern(5), $Zern(4))]}

    a.repele  $Amag sei 3 = sei
    a.repele  $Aang sei 4 = sei

#
# Coma
#
    set Cmag [expr $Zern(6) * $Zern(6) + $Zern(7) * $Zern(7)]
    set Cmag [expr sqrt($Cmag) * 3.0 ]
	
    if { $Cmag == 0.0 } { set Cang 0.0 } \
    else \
    { set Cang [expr 57.296 * atan2( $Zern(7), $Zern(6))] }

    a.repele  $Cmag sei 5 = sei
    a.repele  $Cang sei 6 = sei
	
#
# Spherical
#
    
    set Spmag [expr $Zern(8) * 6.0]
	
    a.repele  $Spmag sei 7 = sei
    a.copy sei =  ws_results(Seidel)
	
}

