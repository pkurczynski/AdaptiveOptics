#==========================================================================
# 
# 			Adaptive Optics Associates
# 			      10 Wilson Road
# 			 Cambridge, MA 02138-1128
# 				    USA
# 			   (Phone) 617-864-0201
# 			    (Fax) 617-864-1348
# 
#                Copyright 2000 Adaptive Optics Associates
# 			    All Rights Reserved
# 
#==========================================================================
# 
# FILE: m2.tcl
# 
# DESCRIPTION:	
# Calculates M^2 from a matching pair of phase and intensity Arrays.
# Assumes `phase' is in units of microns.
# Assumes `inten' has been background subtracted and matches the phase pixel
# by pixel.
# Assums `lambda' is in units of microns, just like the `phase'.
#
# The technique it uses is quick and dirty.  It derives a gaussian sigma from
# the intensity of the input beam.  It then calculates the far field gaussian
# sigma that a perfect gaussian input beam with the derived sigma would have.
# Next it propogates the real phase and intensity to the far field and derives
# the real gaussian sigma from the PSF.  The squared ratio of the real sigma
# to the perfect sigma should be M^2.
#
# $Id: m2.tcl,v 1.4 2000/09/01 17:55:48 herb Exp $
#
#==========================================================================

proc calcM2 { phase inten lambda } \
{
  upvar $phase PH
  upvar $inten IN
  global realpsf realpsfx realpsfy
  
  set ncols [a.cols PH]
  set nrows [a.rows PH]
  #
  # Calculate 2*sigma of a gaussian which best represents the input
  # intensity.
  #
  set twosig [calcRad IN .86466]
  set sig [expr $twosig/2.]
  
  a.rebin IN 1 $nrows = INx
  a.shape INx $ncols = INx
  set twosigx [calcRadLin INx .68352]
  set sigx [expr $twosigx/2.]
  
  a.rebin IN $ncols 1 = INy
  a.shape INy $nrows = INy
  set twosigy [calcRadLin INy .68352]
  set sigy [expr $twosigy/2.]
  
  update
  #
  # Calculate a convenient power of 2 for the purpose of calculating
  # PSF.
  #
  set n [calcPower2Size $ncols $nrows]
  #
  # A perfect gaussian beam with sigma `sig' that we just calculated
  # will have a characteristic 2*sigma if we use it to calculate the PSF.
  #
  set perfect2sig [expr $n/(2.*3.141593*$sig)]
  set perfect2sigx [expr $n/(2.*3.141593*$sigx)]
  set perfect2sigy [expr $n/(2.*3.141593*$sigy)]
  #
  # Calculate the far field PSF for our real input data.
  #
  calculatePSF PH IN $lambda $n  realpsf
  update
  #
  # Calculate the characteristic 2*sigma from the real PSF.
  #
  set real2sig [calcRad realpsf .86466]
  
  a.rebin realpsf 1 $n = realpsfx
  a.shape realpsfx $n = realpsfx
  set real2sigx [calcRadLin realpsfx .68352]
  
  a.rebin realpsf $n 1 = realpsfy
  a.shape realpsfy $n = realpsfy
  set real2sigy [calcRadLin realpsfy .68352]
  
  update
  #
  # The square of the ratio of these 2sig quantities should be M^2.
  #
  set m2 [expr ($real2sig*$real2sig)/($perfect2sig*$perfect2sig)]
  set m2x [expr ($real2sigx*$real2sigx)/($perfect2sigx*$perfect2sigx)]
  set m2y [expr ($real2sigy*$real2sigy)/($perfect2sigy*$perfect2sigy)]
  
  #
  # Let us avoid some embarrasment due to round off error.
  #
  if { $m2 < 1.0 } { set m2 1.0 }
  
  return $m2
}

###############################################################################
# Returns a power of 2 which is conveniently big. It is big enough so that if
# we stick an Array of size `ncols'x`nrows' into it, then calculate the PSF, we
# will have nice resolution of the speckle pattern.
###############################################################################
proc calcPower2Size { ncols nrows } \
{
  if { $ncols > $nrows } {
    set n $ncols
  } else {
    set n $nrows
  }
  
  set n [expr pow( 2., 3 + int( log( $n ) / log( 2. ) ) )]
}

###############################################################################
# Returns the radius which encloses `fraction' of the total intensity in
# `inten'.  Notice we use alg.centroid.spot to derive the center, not
# alg.fit.spot.  This allows us to use this function on intensities which may
# not have a central peak.
###############################################################################
proc calcRad { inten fraction } \
{
  upvar $inten IN
#
# Find the center.
#
  alg.centroid.spot IN = center
  a.split center = x y
  set x [a.ave x]
  set y [a.ave y]
#
# Calculate the encircled energy energy function and normalize it.
#
  alg.calc.ene IN 1 1 $x $y = ene
  set total [a.sum IN]
  a.div ene $total = ene
#
# Find the radius which encloses `fraction'.
#
  set r [findCrossing ene $fraction]
#
# Remember that the first value in the Array returned by alg.calc.ene is
# the encircled energy inside a radius of 1., not zero.
#
  set r [expr $r+1.]
}

###############################################################################
# Returns the radius which encloses `fraction' of the total intensity in
# `inten'.  Notice we use alg.centroid.spot to derive the center, not
# alg.fit.spot.  This allows us to use this function on intensities which may
# not have a central peak.
###############################################################################
proc calcRadLin { inten fraction } \
{
  upvar $inten IN
  global ene
  calcLinEne IN ene
  
#
# Find the radius which encloses `fraction'.
#
  set r [findCrossing ene $fraction]
#
# Remember that the first value in the Array returned by alg.calc.ene is
# the encircled energy inside a radius of 1., not zero.
#
  set r [expr $r+1.]
}


###############################################################################
# Returns the fractional column in the 1-D input Array `func' where the value
# crosses `val'.  It assumes `func' is monotonically increasing.  If the first
# column of `func' is above `val', it returns 0.  If the last column of `func'
# is below `val', it returns the number of columns in `func'.
###############################################################################
proc findCrossing { func val } \
{
  upvar $func FU

  set ncols [a.cols FU]
    
  set f0 [a.extele FU 0]

  if { $f0 >= $val } { return 0. }

  for { set x0 0 } { $x0 < $ncols - 1 } { incr x0 } {
    set x1 [expr $x0+1]
    set f0 [a.extele FU $x0]
    set f1 [a.extele FU $x1]
    
    if { $f1 >= $val } {
      set x [expr $x0+($val-$f0)/($f1-$f0)]
      return $x
    }
  }

  return $ncols
}

#############################################################################
# Takes an FFT of something, which has its peak typically at 0,0, and centers
# the peak within the Array.  This is purely to make pretty pictures.
#############################################################################
proc centerFFT { in out } \
{
  upvar $out OUT
  
  set ncols [a.cols $in]
  set nrows [a.rows $in]
  
  set hcols [expr $ncols/2]
  set hrows [expr $nrows/2]
  
  a.ext $in      0      0 $hcols $hrows = u00
  a.ext $in $hcols      0 $hcols $hrows = u10
  a.ext $in      0 $hrows $hcols $hrows = u01
  a.ext $in $hcols $hrows $hcols $hrows = u11
  
  a.catcol $u11 $u01 = u0
  a.catcol $u10 $u00 = u1
  a.catrow $u0  $u1  = OUT
}

#############################################################################
# Calculates the psf from the `phase' and `intensity'.  The `phase'
# should be in the same units as `lambda', the wavelength.  The `fftsize' is
# a power of 2 used to acually perform the FFTs.
# The psf output is scaled so that the sum of the psf equals the
# sum of the input intensity.  The output will be `fftsize' x `fftsize'.
#############################################################################
proc calculatePSF { phase intensity lambda fftsize out } \
{
  upvar $phase PHASE
  upvar $intensity INTENSITY
  upvar $out OUT
  
  set ncols [a.cols INTENSITY]
  set nrows [a.rows INTENSITY]
  set n [calcPower2Size $ncols $nrows]
#
# Calculate the sin and cos of the phase
#
  a.div $PHASE $lambda = ph
  a.mul $ph 6.2832 = ph
  a.cos $ph = c
  a.sin $ph = s
#
# Calculate the square root of the intensity and multiply it by the
# sin and cos of the phase.  This gives us the real and imaginary parts
# of the amplitude of E-fields.
#
  a.limlow $INTENSITY 0 = in
  a.sqrt $in = in
  a.mul c in = c
  a.mul s in = s
#
# Convert the real and imaginary parts to complex, and stick the
# complex Array into a bigger power of 2 Array used for FFTs.
#
  a.to $c $s com = e
  a.flat $n $n 0 = flat
  a.ins e flat 0 0 = e
#
# Calculate square of the amplitude of the FFT.
#
  a.fft $e i = fe
  a.amp $fe = a
  a.sq $a = a
#
# Move zero frequency to the center of the image.
#
  centerFFT $a OUT
#
# Rescale the output to take into account the renormalization
# performed by the FFT.
#
  set nn [expr $n * $n]
  a.mul $OUT $nn = OUT
}	

#######################################
#
# There is some concern that this calcPSF and the
# one used in WaveScope are not the same and may
# yield different results under some circumstances
# This should be checked.
#
#######################################


#############################################################################
# 
# M2trans transforms the input OPD and input Intensity maps
# to forms that can be used in the M2 calculation. Using the pupil
# subaperture params, the OPD is scaled and rotated to match the 
# intensity coordinate system. Then both are rebinned 8X8
# The translation portion of the transformation should be verified
# by an independent reviewer.
#
#############################################################################
proc M2trans { inopd outopd inint outint } \
{
  upvar $inopd inn
  upvar $outopd outt
  upvar $inint inin
  upvar $outint outin
  global wlCalibrate 
  update
  a.ext wlCalibrate(Params) 0 4 = ppp
  a.shape ppp 2 2 = ppp
  a.matinv ppp = ppp
  a.extcol ppp 0 = para
  a.ext wlCalibrate(Params) 4 1 = off1
  a.ext wlCalibrate(Params) 5 1 = off2
  update
  a.catcol para off1 0 = para
  a.extcol ppp 1 = pary
  a.catcol para pary off2 0 = para
  a.transform $inn 640 480 para = big
  a.rebin big 8 8 = outt
  update
  a.rebin inin  8 8 = outin	
}


#############################################################################
# 
# Move the stage and set the exposure
# Grab an image
# calculate the OPD
# Move to Pupil Plane
# Grab background and Pupil image
# Subtract background
# Calculate M2
#
#############################################################################
proc Calculate_M2 {} \
{
  global stagePos ws_results lint opd typel ws_results
  global wsParam DisplayFlag calFiles wlCalibrate ws_stat

  stage.move.absolute $stagePos(PupilImage)
  SetProperExposure testPupilExposure
  
  wl_PanelsWarn "For M Squared Calculation, block the input beam"
  fg.grabc 1 = back
  a.to back f = back
  wl_PanelsWarn "For M Squared Calculation, un-block the input beam"
  fg.grabc 1 = im
  a.sub im back = int
  update
  M2trans ws_results(Opd) opd int lint
  update
  stage.move.absolute $stagePos(BestRefSpots)
  update
  SetProperExposure testSpotExposure
  set M2 [calcM2 opd lint $wsParam(Lambda)]
  update
  set M2 [format %8.4f $M2]
  a.copy $M2 = ws_results(Msquared) 
}

proc calcLinEne { inar outar } \
{
  upvar $inar inn
  upvar $outar outt
  global sum
  set peak [alg.fit.spot inn]


  set rem [expr fmod($peak,1.0)]
  set nnn [a.cols inn]
  a.copy "( 1 $rem 0 )" = coef
  a.transform inn $nnn coef = intr
  set pk [expr int($peak)]
  set pkr [expr $nnn - $pk]

  if { $pk > $pkr } { set siz $pk } else { set siz $pkr }
  a.make 0 $siz = sum
  a.make 0 $siz = divd
  a.ext intr 0 $pk = ex1
  a.ext intr $pk $pkr = ex2
  a.flip ex1 = xe1
  a.ins xe1 sum 0 = sum
  a.ins ex2 sum 0 = sum
  a.make 1 $pk = pp1
  a.make 1 $pkr = pp2
  a.ins pp1 divd 0 = divd
  a.ins pp2 divd 0 = divd
  a.div sum divd = sum
  a.make 0 $siz = outt


  for { set i 1 } { $i <= $siz } { incr i } \
    {
      
      a.ext sum 0 $i = exts
      a.sum exts = sexts

      set j [ expr $i -1 ]
      a.repele sexts outt $j = outt
    }
  a.div outt [a.sum sum] = outt
}

proc makeLin { inarr outarx outary } \
{
  upvar $inarr inn
  upvar $outarx outx
  upvar $outary outy
  set ncols [a.cols inn]
  set nrows [a.rows inn]
  a.rebin inn 1 $nrows = inx
  a.shape inx $ncols = outx
  a.rebin inn $ncols 1 = iny
  a.shape iny $nrows = outy
}

proc doHerm { inarr ord coefs } \
{
  upvar $inarr inn
  upvar $coefs cof
  alg.centroid.spot inn = center
  a.split center = x y
  set x [a.ave x]
  set y [a.ave y]
  makeLin inn lx ly
  set real2sigx [calcRadLin lx .68352]
  puts $real2sigx
  set real2sigy [calcRadLin ly .68352]
  puts $real2sigy
  herm.decomp.surf.coefs inn $ord $x $y $real2sigx $real2sigy = cof
}

proc m2Stat {}\
{
	global ws_stat big
	set i 0
	foreach frame [glob $ws_stat(rundir)/Msquareds/*]\
	{
		a.load $frame = tmp
		if {$i == 0 } {a.copy tmp = big} else {a.catcol tmp big = big}
		incr i
	}
	puts "Average M2 = [a.ave big]"
	puts "rms M2 = [a.rms big]"
}