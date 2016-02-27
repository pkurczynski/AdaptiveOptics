#==========================================================================
# 
# 			Adaptive Optics Associates
# 			  54 CambridgePark Drive
# 			 Cambridge, MA 02140-2308
# 				    USA
# 			   (Phone) 617-864-0201
# 			    (Fax) 617-864-1348
# 
#                Copyright 1999 Adaptive Optics Associates
# 			    All Rights Reserved
# 
#==========================================================================

#--------------------------------------------------------------------------
# 
# FILE: ActiveAl.tcl
# 
# DESCRIPTION:	
#   "Active" Tip/Tilt and Pupil-centering Alignment assist
# 
# $Id: ActiveAl.tcl,v 1.8 1999/07/02 23:18:48 stacy Exp $
# 
#--------------------------------------------------------------------------


#--------------------------------------------------------------------------
# proc ActiveAl
#
# Kicks off the measured tip/tilt process.
# This is the entry point into the tip/tilt routines.
#--------------------------------------------------------------------------

proc ActiveAl {} {

  global actAlStatus wsdb ws_stat actAlStatLabel DisplayFlag wlCalibrate
  global LISTS_DIR beamPic


  # This is for using procs in Calibrate.tcl
  #
  set DisplayFlag "No"

  if { [VerifyMLM] == "Abort" } {
    return "Abort"
  }
   
  source $LISTS_DIR/sensorParams.tcl
  if { [ws_SetWSParams] == "Abort" } {
    return "Abort"
  } 
  a.load $LISTS_DIR/beam_dir.raw = beamPic

  if { [winfo exist .aawin] } { destroy .aawin }
  toplevel .aawin
  wm title .aawin "Measured Tip/Tilt Control Panel"
  wm geometry .aawin +100+80
    
  set actAlStatLabel "Setting exposure and taking measurements..."

  label   .aawin.l -font $wsdb(font) -textvariable actAlStatLabel
  frame   .aawin.bf
  pack    .aawin.l .aawin.bf -side top -pady 5

  button .aawin.bf.c -font $wsdb(font) -text "Continue" -highlightthickness 0 \
          -command { set actAlStatus "RUNNING" } -state disabled
  button .aawin.bf.e -font $wsdb(font) -text " Cancel " -highlightthickness 0 \
          -command { set actAlStatus "EXIT" }
  button .aawin.bf.h -font $wsdb(font) -text "Help" -highlightthickness 0 \
          -command { ShowHelp Alignment2.html }
  pack   .aawin.bf.c .aawin.bf.e .aawin.bf.h -side left -padx 15 -pady 10

  set actAlStatus "RUNNING"
  DoActiveAlignM
}




#--------------------------------------------------------------------------
# proc DoActiveAlignM
#
# The "main loop" of tip/tilt alignment.  Grabs images, processes what it
# gets, and makes a recommendation on aligning the source.
#--------------------------------------------------------------------------

proc DoActiveAlignM {} {

  global wlCalibrate stagePos stageParams actAlStatus actAlStatLabel
  global Rects Posn Grad beamPic platform 


  raise .aawin
  update

  stage.calibrate.absolute $stagePos(BestRefSpots)
  if { [SetProperExposure refSpotExposure] == "Abort" } {
    destroy .aawin
    return "Abort"
  }

  if [ catch { fg.grabc_init } result ] {
    dialog "Another process is using the frame grabber.  Measured Tip/Tilt aborted."
    destroy .aawin
    return
  }
  fg.grabc 1 = refim
  alg.find.rects refim = Rects

  set nrect [a.cols Rects]
  if { $nrect < 10 } {
    dialog "There aren't enough spots to take a measurement.  Measured Tip/Tilt aborted."
    fg.grabc_term
    destroy .aawin
    return
  }

  set st1 $stagePos(BestRefSpots)
  set stl $stagePos(CloserRefSpots)
  set stp $stagePos(PupilImage)

  set stdif $stageParams(StepsPerMM)

  set nnn [expr int([expr ( $st1 - $stl ) / $stdif ])]
  set mmm [expr $nnn +1]
  a.make 0  $mmm = amps
  a.make "< 0 0 >" $mmm = vecs
  a.tilt $mmm 0 1 = poses

  while { $actAlStatus != "EXIT" } {
      
    while { $actAlStatus == "RUNNING" } {

      stage.calibrate.absolute $st1
      while { [ stage.get.moving ] == 1 } {
	update 
      }
    
      fg.grabc 1 = refim
      alg.find.rects refim = Rects
      ActAlCalcPos 1 

      for { set i 0 } { $i <= $nnn } { incr i }	{

	set st2 [ expr $st1 - $i * $stdif]
	stage.calibrate.absolute $st2
	while { [ stage.get.moving ] == 1 } {
	  update 
	}

	ActAlCalcGrad 1 $Posn
		
	a.ave Grad = agrad
	a.v4tov2v2 agrad = gpos ggg
	a.to ggg com = cg
	a.amp cg = amp
		
	a.repele amp amps $i = amps
	a.repele ggg vecs $i = vecs
		
      }
    
      a.div amps poses = sizs
      a.div sizs $wlCalibrate(wsMag) = sizs
      a.mul sizs $wlCalibrate(wsPixSiz) = sizs
      for { set i 0 } { $i <= $nnn } { incr i }	{
	a.extele sizs $i = ang
	set siz [a.ave ang]
	a.extele vecs $i = vec
	a.extele poses $i = pose
	a.shape vec 1 1 = vec
	if { $siz > 10 } {
	  break
	}
      }

      a.to vec com = cec
      a.mul cec -1 = cec
      set posit [a.ave pose]
      a.div cec $posit = cec
      a.div cec $wlCalibrate(wsMag) = cec
      a.mul cec $wlCalibrate(wsPixSiz) = cec
      a.to cec v2 = vec
      a.v2toxy vec = gx gy
      set gradx [a.ave gx]
      set grady [a.ave gy]
      set xdir "Away From"
      set ydir "Away From"
      if { $gradx > 0 } { set xdir "Toward" }
      if { $grady < 0 } { set ydir "Toward" }

      if { abs($gradx) > 7 || abs($grady) > 7 } {

	.aawin.bf.c configure -state normal
	set actAlStatLabel "\
            Composite Tip/Tilt is $siz mr\n\
            Horizontal Tilt is .. $gradx mr\n\
            Vertical Tip is ..... $grady mr\n\
	    The picture below indicates beam direction in each plane.\n\
	    A RED beam indicates adjustment is necessary.\n\
	    A Green beam indicates alignment in that plane is acceptable.\n\
	    Adjust Alignment and click Continue."
	set actAlStatus "WAIT"
	if { ! [info exists aaid] } { 
	  id.new aaid 
	  id.set.xy aaid 150 290
	  id.set.wh aaid 450 350
	  id.set.over.width aaid 5
	}
	id.set.array aaid beamPic
	id.clr.over.array aaid

	if { abs($gradx) > 7 } {
 	    id.set.over.color aaid 1.0 0.0 0.0
	} else {
 	    id.set.over.color aaid 0.0 1.0 0.0
	}
	if { $platform == "windows" } { 
	  id.set.over.coords aaid 1
 	} 
 	set offx [expr 113 + $gradx]
	if { $offx < 15 }  { set offx 15 }
	if { $offx > 215 } { set offx 215 }
	a.make "<$offx 20 113 165>" 1 = over
	id.set.over.array aaid over

	if { abs($grady) > 7 } {
	    id.set.over.color aaid 1.0 0.0 0.0
	} else {
 	    id.set.over.color aaid 0.0 1.0 0.0
	}
	if { $platform == "windows" } { 
	  id.set.over.coords aaid 1
	}
 	set offy [expr 182 - $grady]
	if { $offy > 260 } { set offy 260 }
        if { $offy < 100 } { set offy 100 }
	a.make "<260 $offy 375 182>" 1 = over2
	id.set.over.array aaid over2
   
	raise .aawin
	update

      } else {

	.aawin.bf.c configure -state normal
	set actAlStatLabel "\Composite Tip/Tilt is Acceptable\n\
            Composite Tip/Tilt is: $siz mr \n\
            Horizontal Tilt is ... $gradx mr\n\
            Vertical Tip is ...... $grady mr\n\
	    Click Cancel to exit."
	set actAlStatus "WAIT"
	if { ! [info exists aaid] } { 
	  id.new aaid 
	  id.set.xy aaid 150 290
	  id.set.wh aaid 450 350
	  id.set.over.width aaid 5
	}
	id.set.array aaid beamPic
 	id.set.over.color aaid 0.0 1.0 0.0
	if { $platform == "windows" } { 
	  id.set.over.coords aaid 1
 	} 
	set offx [expr 113 + $gradx]
	set offy [expr 182 - $grady]
	id.clr.over.array aaid
	a.make "<$offx 20 113 165>" 1 = over
	a.make "<260 $offy 375 182>" 1 = over2
	id.set.over.array aaid over
	id.set.over.array aaid over2
   
	raise .aawin
	update
      }
    }
    update
  }
  fg.grabc_term
  destroy .aawin
  unset aaid
}


#---------------------------------------------------------------------------
# proc ActAlCalcGrad
#
# Calculates gradients by grabbing 'n' images and averaging over the images
# This has been modified to take a reference
#---------------------------------------------------------------------------

proc ActAlCalcGrad { n ref } {

  global Rects Grad bigim


  # Grab the image(s)
  #
  fg.grabc 1 = bigim
  set ncol [a.cols Rects]
  

  # Depending on the number of images grabbed, do the average.
  #
  if { $n == 1 } {  
    alg.fit.spots bigim Rects = pos

  } else {

    for { set i 0 } { $i < $n } { incr i } {
      a.extpln bigim $i = tempim
      alg.fit.spots tempim Rects = pos
      if { $i == 0 } { a.copy pos = sum } else { a.catrow sum pos = sum }
    }
    a.rebin sum 1 $n = pos
    a.shape pos $ncol = pos
  }
     
  a.sub pos $ref = diff
  
  a.v2v2tov4 pos diff = Grad
  update
}


#---------------------------------------------------------------------------
# proc ActAlCalcPos
#
# Calculates spot position by grabbing 'n' images and 
# averaging over the images
#---------------------------------------------------------------------------

proc ActAlCalcPos { n } {

  global Posn Rects bigim


  # Grab the image(s)
  #
  fg.grabc 1 = bigim
  set ncol [a.cols Rects]
  

  # Depending on the number of images grabbed, do the average.
  #
  if { $n == 1 } {  
    alg.fit.spots bigim Rects = pos

  } else {

    for { set i 0 } { $i < $n } { incr i } {
      a.extpln bigim $i = tempim
      alg.fit.spots tempim Rects = pos
      if { $i == 0 } { a.copy pos = sum } else { a.catrow sum pos = sum }
    }
    a.rebin sum 1 $n = pos
    a.shape pos $ncol = pos
  }
  
  a.copy pos = Posn
  update
}


#--------------------------------------------------------------------------
# proc AsPup
#
# Kicks off the measured pupil center process.
# This is the entry point into the measured pupil center routines.
#--------------------------------------------------------------------------

proc AsPup { } {

  global asPupStatLabel asPupStatus wsdb DisplayFlag ws_stat

  if { $ws_stat(mlm) == "" } { 
	if { [ws_SetWSParams] == "Abort" } {
   	 return "Abort"
  	} 
  } else {
    if { [VerifyMLM] == "Abort" } {
      return "Abort"
    }
  }

  # This is for using procs in Calibrate.tcl
  #
  set DisplayFlag "No"

  if { [winfo exist .apwin] } { destroy .apwin }
  toplevel .apwin
  wm title .apwin "Measured Pupil Center Control Panel"
  wm geometry .apwin +100+80
    
  set asPupStatLabel "Setting exposure and taking measurements..."

  label   .apwin.l -font $wsdb(font) -textvariable asPupStatLabel
  frame   .apwin.bf
  pack    .apwin.l .apwin.bf -side top -pady 5

  button .apwin.bf.c -font $wsdb(font) -text "Continue" -highlightthickness 0 \
      -command { set asPupStatus "RUNNING" } -state disabled
  button .apwin.bf.e -font $wsdb(font) -text " Cancel " -highlightthickness 0 \
      -command { set asPupStatus "EXIT" }
  button .apwin.bf.h -font $wsdb(font) -text "Help" -highlightthickness 0 \
      -command { ShowHelp Alignment2.html }
  pack   .apwin.bf.c .apwin.bf.e .apwin.bf.h -side left -padx 15 -pady 10

  set asPupStatus "RUNNING"
  DoAsPup
}


#--------------------------------------------------------------------------
# proc DoAsPup
#
# The "main loop" of pupil centering.  Grabs images, processes what it
# gets, and assesses the quality and location of the illumination of the
# pupil.
#--------------------------------------------------------------------------

proc DoAsPup { } {

  global p stagePos mask platform asPupStatLabel asPupStatus
  global smmo smask


  raise .apwin
  update

  stage.calibrate.absolute $stagePos(PupilImage)
  if { [SetProperExposure refSpotExposure] == "Abort" } {
    destroy .apwin
    return "Abort"
  }

  if [ catch { fg.grabc_init } result ] {
    dialog "Another process is using the frame grabber.  Measured Pupil Center aborted."
    destroy .apwin
    return
  }

  while { $asPupStatus != "EXIT" } {
      
    while { $asPupStatus == "RUNNING" } {

      if { ! [info exists apid] } { 
	id.new apid
	id.set.xy apid 100 260
	id.set.wh apid 600 500
	id.set.over.width apid 3
      }
      fg.grabc 1 = im
      id.set.array apid im
      update

      a.ext im 64 0 512 478 = im
      a.make 0 512 17 = noth
      a.catrow noth im noth = im
      a.gauss 64 64 1 32 32 25 25 = kern
      a.div kern [a.sum kern] = kern
      a.conv im kern = smoo
      a.ext smoo 56 56 400 400 = smmo
      a.grad smmo = ggg
      #a.rebin grad 10 10 = grad

      a.to ggg com = ggg
      a.sq ggg = sss
      a.rebin sss 10 10 = sss
      a.sqrt sss = sss

      FindCenter sss

      a.shape p 2 = p
      a.mul p 10 = cent
      a.add cent "( 56 40 )" = cent
      a.sub cent "( 320 240 )" = rcent

	set max [a.max  smmo]
  	set min [a.min smmo]
  	
  	set cutlevel [expr $min + ( $max - $min )/2.]
  	a.cut smmo $cutlevel = smask

      #a.rebin smmo 10 10 = smim
      set aave [a.avemask smmo smask]
      set arms [a.rmsmask smmo smask]
      set amin [a.minmask smmo smask]
      set amax [a.maxmask smmo smask]
      set ravacfr [expr 100 * ($amax - $amin) / $amax]
      set fracvar [expr 100 * $arms / $aave]

      set xc [a.ave [a.ext cent 0 1]]
      set yc [a.ave [a.ext cent 1 1]]

      id.clr.over.array apid
      if { $platform == "windows" } {
	id.set.over.coords apid 1
      }
      id.set.over.color apid .9 .7 0
      makecir $xc $yc 50 cirover
      id.set.over.array apid cirover

      a.copy "< 320 0 320 480 >" = tcent
      a.catcol tcent "< 0 240 640 240 >" = tcent

      id.set.over.color apid .5 0 .5
      id.set.over.array apid tcent

      set erx [expr abs([expr $xc - 320])]
      set ery [expr abs([expr $yc - 240])]

      .apwin.bf.c configure -state normal

      if { $erx > 100 || $ery > 75 } {
	set w1 "WARNING: Light Distribution Not Centered\n\ "
      } else {
	set w1 " "
      }

      if { $fracvar > 20 || $ravacfr > 75 } {
	set w2 "WARNING: Light Distribution Not Uniform\n\ "
      } else {
	set w2 " "
      }

      set v1 [format "RMS variation in Illumination %4.1f percent\n\ " $fracvar]
      set v2 [format "Total variation in Illumination %4.1f percent\n\ " $ravacfr ]

      set asPupStatLabel "$w1$w2\
	  Apparent center of illumination is\n\ [a.dump rcent] pixels from CCD center\n\ $v1 $v2 Click Cancel to exit."
      set asPupStatus "WAIT"

      a.to cent v2 = vent
      a.add vent "<  10  10 >" = ur
      a.sub vent "<  10  10 >" = ll
      a.add vent "< -10  10 >" = ul
      a.add vent "<  10 -10 >" = lr
      a.v2v2tov4 ur ll = llur
      a.v2v2tov4 ul lr = lrul
      a.catcol llur lrul = llurlrul
      id.set.over.color apid 0 .7 0.9
      id.set.over.array apid llurlrul
   
      raise .apwin
      update
    }
    update
  }
  fg.grabc_term
  destroy .apwin
  unset apid
}


#--------------------------------------------------------------------------
# proc FindCenter
#
# Used by AsPup to find the center of the pupil.
#
#--------------------------------------------------------------------------

proc FindCenter { complexarray } {

  upvar $complexarray IN
  global mask p bigmask


  set ncols [a.cols IN]
  set nrows [a.rows IN]

  a.amp IN = amp
  a.div IN amp = norm
  a.real norm = sx
  a.imag norm = sy
  a.to sx d = sx
  a.to sy d = sy

  set max [a.max amp]
  set min [a.min amp]
  set ave [a.ave amp]

  #puts [format "min amp %7.4f   max amp %7.4f" $min $max]
    
  #if { $ave < 0.05 } {
  #  puts "Warning: Uniform Illumination, Center Unreliable"
  #}

  a.cutlow amp 0.3 = bigmask

  a.mul amp bigmask = amp
  set max [a.max  amp]
  set min [a.min amp]
  #puts [format "Masked min amp %7.4f   max amp %7.4f" $min $max]
  set cutlevel [expr $min + ( $max - $min )/4.]
  a.cut amp $cutlevel = mask

  a.tilt $ncols $nrows 0.5 1 0 = x0
  a.tilt $ncols $nrows 0.5 0 1 = y0
  a.to x0 d = x0
  a.to y0 d = y0

  a.mul sx sx = sxsx
  a.mul sy sy = sysy
  a.mul sx sy = sxsy
  a.mul sy sy x0 = sysyx0
  a.mul sx sy y0 = sxsyy0
  a.mul sx sx y0 = sxsxy0
  a.mul sx sy x0 = sxsyx0

  a.summask sxsx mask = sumsxsx 
  a.summask sysy mask = sumsysy 
  a.summask sxsy mask = sumsxsy 

  a.sub sysyx0 sxsyy0 = kx
  a.sub sxsxy0 sxsyx0 = ky
  a.summask kx mask = sumkx
  a.summask ky mask = sumky

  a.mul sumsxsx sumsysy = d0
  a.mul sumsxsy sumsxsy = d1
  a.sub d0 d1 = det
  
  a.flat 2 2 0 = m
  a.to m d = m

  a.repele sumsxsx m 0 0 = m
  a.repele sumsxsy m 0 1 = m
  a.repele sumsxsy m 1 0 = m
  a.repele sumsysy m 1 1 = m
  a.div m det = m

  a.flat 1 2 0 = k
  a.to k d = k
  a.repele sumkx k 0 0 = k
  a.repele sumky k 0 1 = k

  a.matprod m k = p
  #puts [a.dump p]
}
