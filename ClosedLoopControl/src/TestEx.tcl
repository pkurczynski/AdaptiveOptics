#==========================================================================
# 
# 			Adaptive Optics Associates
# 			      10 Wilson Road
# 			    Cambridge, MA 02138
# 				    USA
# 			   (Phone) 617-864-0201
# 			    (Fax) 617-864-1348
# 
#                Copyright 2000 Adaptive Optics Associates
# 			    All Rights Reserved
# 
#==========================================================================
# 
# FILE: TestEx.tcl
# 
# DESCRIPTION:	
#   The procedures in this file are the bulk of actually executing a test.
# 
# $Id: TestEx.tcl,v 1.79 2001/05/18 20:16:31 herb Exp $
# 
#==========================================================================


#-----------------------------------------------------------------------------
#  Calculates Gradients, OPD, Zernikes and Monomials from 
#  input spot image. Expects calibration data
#  in global wlCalibrate. Puts reuslts into global ws_results
#  What is calculated is based on array typel
#  Typel(0) = 1 -> Calc Gradient
#  Typel(1) = 1 -> Calc OPD
#  Typel(2) = 1 -> Calc PSF
#  Typel(3) = 1 -> Calc MTF
#  Typel(4) = 1 -> Calc ENE
#  Typel(5) = 1 -> Calc Fringes
#  Typel(6) = 1 -> Calc Beam Profile
#  Typel(7) = 1 -> Calc Zernikes
#  Typel(8) = 1 -> Calc Monimials
#  Typel(9) = 1 -> Calc Seidels
#  Typel(10) = 1 -> Calc Hermites
#  Typel(11) = 1 -> Calc Chebychev
#  Typel(12) = 1 -> Calc Legendre
#  Typel(13) = 1 -> Text Entry
#  Typel(14) = 1 -> Calc Msquared
#  
#-----------------------------------------------------------------------------
proc LCalcWF {ImIn} {
    
#
# The polynomial parameters should be put into an array
#

    global wlCalibrate typel ws_results wsMLMParams wsParam wsRunInfo 
    global ws_stat

    upvar $ImIn tempim

# wsObjList is list of types of data that can be calculated
# ws_results is array of calculated results
    update
    set wsObjList { Image AveImage Gradient Opd PSF MTF ENE Fringe Zernike\
		    Seidel Monomial Chebychev Legendre BeamP Hermite Text }

# first clear out any old results

    foreach obj $wsObjList \
    {
	if { [ array names ws_results $obj ] != "" } \
	{
	    unset ws_results($obj)
	}
    }
    update

# Put image into ws_results(Image)

    set nplns [a.plns tempim]
    # either a single image or multiple planes
    a.copy tempim = ws_results(Image)
    
# Then calculate all the things that the user asked for
# Before all else, calculate spot motions and convert to
# microns of tilt per subaperture
    update
    if { $typel(0) > 0} \
    {
	if { $nplns > 1 } { 
	    a.extpln tempim 0 = fts
	    alg.fit.spots fts wlCalibrate(FinalTestRects) \
	    	= sumTestPos
	    a.copy fts = aveIm
	    a.to aveIm f = aveIm
	    for {set j 1} {$j < $nplns} {incr j} {
	        a.extpln tempim $j = ttt
	        alg.fit.spots ttt wlCalibrate(FinalTestRects) \
		    = parTestPos
	        a.add parTestPos sumTestPos = sumTestPos
		a.add ttt aveIm = aveIm
		update
	    }
  	    a.v2toxy sumTestPos = x y
	    a.div x $nplns = x
	    a.div y $nplns = y
	    a.xytov2 x y = pos
	    a.div aveIm $nplns = tempim
        } else {
	    alg.fit.spots tempim wlCalibrate(FinalTestRects) = pos
    	}
	   
	update

	# switch the order of the subtraction
	a.sub wlCalibrate(RefPos) pos = diff
	if { $wsParam(tiltRemFlag) == "Yes" } \
        {
	    a.sub diff [a.ave diff] = diff
	}
	update
	a.v2toxy diff = dxx dyy
	a.mul dxx $wlCalibrate(micronsPerPix) = dxx
	a.mul dyy $wlCalibrate(micronsPerPix) = dyy
	a.xytov2 dxx dyy = diff
	a.v2v2tov4 wlCalibrate(FinalCenters) diff = ws_results(Gradient)
	if { ($wsParam(focusRemFlag) == "Yes") && \
		 ($wlCalibrate(PupilShape) == "Circular") } \
	{
	    set PupX [a.extele wlCalibrate(Pupil) 0]
	    set PupY [a.extele wlCalibrate(Pupil) 1]
	    set PupR [a.extele wlCalibrate(Pupil) 2]
	    set PScale [a.extele wlCalibrate(Params) 0]
	    set ZScale [expr $PScale * $PupR]
	    set ztype [lindex [split [zern.get.type]] 0]
	    
	    if { $ztype == "Zygo" } { 
		set limit 3
		set znum 3
	    } elseif { $ztype == "Code_V" } { 
		set limit 5 
		set znum 4
	    } elseif { $ztype == "Fringe_Code_V" } { 
		set limit 4
		set znum 3
	    } else  { 
		set limit 4
		set znum 3
	    }
	    if { $wsParam(NZerns) < $limit } {
		puts "error"
		return 0
	    } 
	    zern.decomp.grad.coefs $ws_results(Gradient) $wsParam(NZerns) \
		$PupX $PupY $PupR = zern
	    a.extele zern [expr $znum - 1] = fzern
	    zern.make.grad.coefs $wlCalibrate(FinalCenters) fzern \
		$PupX $PupY $wlCalibrate(CCDxpix) = fgrad
	    set zfactor [expr $wlCalibrate(CCDxpix) / $PupR]
	    a.v4tov2v2 $ws_results(Gradient) = gpos grads
	    a.v4tov2v2 fgrad = ptemp fgrads
	    a.v2toxy fgrads = xfg yfg
	    a.mul xfg $zfactor = xfg
	    a.mul yfg $zfactor = yfg
	    a.xytov2 xfg yfg = fgrads
	    a.sub grads fgrads = gradif


	    if { $wsParam(tiltRemFlag) == "Yes" } \
            {
	    	a.sub gradif [a.ave gradif] = gradif
	    }


	    a.v2v2tov4 gpos gradif = ws_results(Gradient)
	    
	}
	update
    } else {
	# option to compute/save image if averaging
	if { $nplns > 1 } { 
	    a.extpln tempim 0 = aveIm
	    a.to aveIm f = aveIm
	    for {set j 1} {$j < $nplns} {incr j} {
		a.extpln tempim $j = ttt
		a.add ttt aveIm = aveIm
		update
	    }
	    a.div aveIm $nplns = tempim
	} 
    }

# 
# Save AveImage if necessary
#
    if { $nplns > 1 } { 
	a.to tempim uc = ws_results(AveImage)
    }    
    
#	
# Next possible step is OPD (and the mask of valid subaps)
#

    if { $typel(1) == 1  } \
    {
	alg.conv.pg.arrays $ws_results(Gradient) wlCalibrate(Params) \
	    = ggg ws_results(Mask)
	alg.recon.fast ggg ws_results(Mask) = ws_results(Opd)
	update
    }
	
#
# Now the PSF using the true pupil intensity
# We may some day add other choices for pupil intensity maps
#
    if { $typel(2) == 1  } \
    {
	a.make 0 [a.cols wlCalibrate(FinalTestRects)] = nulv
	
	alg.intensity.spots tempim wlCalibrate(FinalTestRects) = intlist
	a.merge intlist nulv = vint
	a.v2v2tov4 wlCalibrate(FinalCenters) vint = vint
	alg.conv.pg.arrays vint wlCalibrate(Params) = gint mmm
	a.v2toxy gint = pupil  zxv

# Use the CalcPsf routine to try to make a more pleasing PSF

	if { [CalcPsf $pupil] == "Abort" } {
	    return "Abort"
	}
	update
		
    }
#
# Added some scaling to MTF calculation so that it works better
#	
    if { $typel(3) == 1  } \
    {
	set mtfScale \
	    [expr 1.0 / ($wsParam(PSFSize) *  $wlCalibrate(psfScale))] 
	set otfSize  [expr  $wsParam(PSFSize) / 2.0 ]
	alg.calc.otf  $ws_results(PSF) $otfSize \
	    $otfSize $wlCalibrate(psfScale)\
	    $mtfScale = otf
	alg.calc.mtf otf = ws_results(MTF)
	update
    }
    
#
# This does the ENE calculation
#
    if { $typel(4) == 1  } \
    {
	set cent [expr  $wsParam(PSFSize) / 2.0 ]
	alg.calc.ene  $ws_results(PSF) $wlCalibrate(psfScale) \
	    $wlCalibrate(psfScale) $cent $cent  = ws_results(ENE)
	set summ [a.sum $ws_results(PSF)]
	a.div ws_results(ENE) $summ = ws_results(ENE)
	update 
    }

#
# This section implements the fake fringe picture
#

    if { $typel(5) == 1  } \
    {
	set rows  [a.rows $ws_results(Opd)]
	set cols  [a.cols $ws_results(Opd)]
	set tilt  [expr 45.0 / $cols ]
	set scale [expr 2.0 * 3.14159 / $wsParam(Lambda) ]
	
	a.tilt $cols $rows 0 $tilt 0 = ref
	a.mul  $scale $ws_results(Opd) = opd
	a.sub opd ref = opd
	a.sin opd = fring
	a.mul $ws_results(Mask) fring = ws_results(Fringe)
	update

    }
#
# Now for the Zernike decomposition (scaled to microns of OPD)
#

    if {  $typel(7) == 1 } \
    {
	if { $wlCalibrate(PupilShape) == "Circular" } { 
	    set PupX [a.extele wlCalibrate(Pupil) 0]
	    set PupY [a.extele wlCalibrate(Pupil) 1]
	    set PupR [a.extele wlCalibrate(Pupil) 2]
	    set PScale [a.extele wlCalibrate(Params) 0]
	    set ZScale [expr $PScale * $PupR]
		
	    zern.decomp.grad.coefs $ws_results(Gradient) $wsParam(NZerns) \
		$PupX $PupY $PupR = zern
	    a.v2toxy zern = zernin zernco
	    a.mul zernco $ZScale = zernco
	    a.xytov2 zernin zernco = ws_results(Zernike)
	} else { 
	    set ws_results(Zernike) "Zernike Coefficients cannot be generated\
		with a rectangular pupil."
	}
	update
    }
#	
# This is the monomial decomposition of the OPD
#	
    if { $typel(8) == 1 } \
    {
	if { $wlCalibrate(PupilShape) == "Rectangular" } {
	    TransRectPup pupcen pupsiz
	    set VPC [a.extele pupcen 0]
	    set HPC [a.extele pupcen 1]
	    set SCX [a.extele pupsiz 0]
	    set SCY [a.extele pupsiz 1]
	    mon.decomp.surf.mask.coefs $ws_results(Opd) ws_results(Mask) \
		    $wsParam(NMons) $VPC $HPC $SCX $SCY = ws_results(Monomial)
	} else { 
	    set ws_results(Monomial) \
      	     "Monomial Coefficients cannot be generated with a circular pupil."
	}
	update
   }
#
# Seidels
#
    if { $typel(9) == 1 } { 
	if { $wlCalibrate(PupilShape) == "Circular" } { 
	    calcSeidel 
	} else {
	    set ws_results(Seidel) "Seidel Coefficients cannot be generated\
		with a rectangular pupil."
	}
	update
    }

#
# This routine uses the alg.conv.pg.arrays algorithm to
# convert the subaperture intensity list to a 2-D pupil intensity map
#	
    if { $typel(6) == 1 || $typel(10) == 1 } \
    {
	a.make 0 [a.cols wlCalibrate(FinalTestRects)] = nulv
        if { [info exists wlCalibrate(Dark)] } { 
	  a.sub tempim wlCalibrate(Dark) = tim
	} else {
	  a.copy tempim = tim
	}
	alg.intensity.spots tim wlCalibrate(FinalTestRects) = intlist
	a.merge intlist nulv = vint
	a.v2v2tov4 wlCalibrate(FinalCenters) vint = vint
	alg.conv.pg.arrays vint wlCalibrate(Params) = gint beamp_mask
	a.v2toxy gint = ws_results(BeamP) zxv
	update
    }
#
# Now for the Hermite decomposition of the Beam Profile
#
	
    if { $typel(10) == 1 } \
    {
	if { $wlCalibrate(PupilShape) == "Rectangular" } { 
	    TransRectPup pupcen pupsiz
	    set PupX [a.extele pupcen 0]
	    set PupY [a.extele pupcen 1]	    
	    herm.decomp.surf.mask.coefs ws_results(BeamP) beamp_mask \
		    $wsParam(NHerms) $PupX $PupY $wsParam(GauSig)\
		    $wsParam(GauSig) = ws_results(Hermite) 
	} else {
	    set ws_results(Hermite) "Hermite Polynomial Coefficients\
                 cannot be generated with a circular pupil."
	}
	update
    }
#
# Chebychev and Legendre are the last
#
    if { $typel(11) == 1 } \
    {	
	if { $wlCalibrate(PupilShape) == "Rectangular" } { 
	    TransRectPup pupcen pupsiz
	    set PupX [a.extele pupcen 0]
	    set PupY [a.extele pupcen 1]	    
	    cheby.decomp.surf.mask.coefs ws_results(Opd) \
		ws_results(Mask) $wsParam(Ncheb) $PupX $PupY\
		= ws_results(Chebychev)
	} else { 
	    set ws_results(Chebychev) "Chebychev Polynomial\
                Coefficients cannot be generated with a circular pupil."
	}
	update
    }
    
    if { $typel(12) == 1 } \
    {
	if { $wlCalibrate(PupilShape) == "Rectangular" } { 
	    TransRectPup pupcen pupsiz
	    set PupX [a.extele pupcen 0]
	    set PupY [a.extele pupcen 1]	    
	    legen.decomp.surf.mask.coefs ws_results(Opd) \
		 ws_results(Mask) $wsParam(Nleg) $PupX $PupY \
		 = ws_results(Legendre)
	} else { 
	    set ws_results(Legendre) "Legendre Polynomial Coefficients\
                 cannot be generated with a circular pupil."
	}
	update
    }

#
# Text display
#
    if { $typel(13) == 1 } \
    {
	set res [.text_entry.frm.txt index end]
	set last [expr $res - 0.09]
	set ws_results(Text) [.text_entry.frm.txt get 1.0 $last]

	foreach i { user_name run_name date } {
	    set wsRunInfo($i) [.text_entry.wsRunInfo($i).entry get]
	}
    }

#
# MSquared
#
    if {  $typel(14) == 1 } \
    {
      if { $ws_stat(current_run) == "Re-Reduce" || $ws_stat(reduce_custom) == 1 } {
        set ws_results(Msquared) "# Cannot be calculated using Re-reduce options."
      } else {
	Calculate_M2
      }
    }

    update
    return
}


###############################################################################
#
# These 2 routines transform the pupil coordinates from pixel coordinate system
# to subaperture coordinates
#
###############################################################################
proc PixSubTrans { inpos outpos } \
{
	upvar $inpos inn
	upvar $outpos outt
	
	global wlCalibrate 
	a.ext wlCalibrate(Params) 0 4 = ppp
	a.copy "( 1 -1 -1 1)" = con
	a.mul ppp con = ppp
	a.shape ppp 2 2 = ppp
	a.shape inn 1 2 = pos
	a.matprod ppp pos = sop
	a.shape sop 2 = sop
	a.ext wlCalibrate(Params) 4 2 = off
	a.add sop off = outt
}

proc TransRectPup { PupSubCen PupSubSiz } \
{
	upvar $PupSubCen psc
	upvar $PupSubSiz pss
	global wlCalibrate
	a.v4tov2v2 wlCalibrate(Pupil) = pupcorn pupsiz
	
	a.add pupcorn pupsiz = pupcornup
	a.ave pupcornup pupcorn = pupcen
	a.to pupcen f = pupcen
	PixSubTrans pupcen psc
	a.to pupsiz f = pupsiz
	PixSubTrans pupsiz pss
}


#--------------------------------------------------------------------------
# proc doTest
#
# This routine actually performs the calculations and updates the displays
#--------------------------------------------------------------------------

proc doTest { } {

  global  ws_results stagePos wsdb hw_flg ws_stat wsRunInfo
  global  platform wlCalibrate wlData wsMLMParams wsParam


  # If re-reducing, return
  #
  if { $ws_stat(re_reduce) == 1 } { 
    return
  }

  # if the hw_flg is on, grab frame(s)
  # if the hw_flg is off, do something to allow running
  #
  update
  set inter [expr int($ws_stat(frminterval) * 1000)]
  if { $inter < 1 } { set inter 0 }

  if { $hw_flg == "TRUE" } {
    #
    # Live Display
    #
    if { $ws_stat(save_data) != 1 } { 

      #
      # Not Averaging
      #
      if { $ws_stat(frame_ave) == 1} {
	set_date
	fg.grabc 1 = CI

	if { [calcnsave CI] == "Abort" } {
	  return "Abort"
	}

        after $inter

      } else {
	#
	# Interval
	#
	for {set fave 1} {$fave<=$ws_stat(frame_ave)} {incr fave} {
	  set_date
	  fg.grabc 1 = CI$fave
	  
	  if { $fave == 1 } {
	    wl_PanelsWait .winex "Grabbing Wavefront Measurement 1 of\
                              $ws_stat(frame_ave) Wavefronts to average." +475+35
	    a.copy CI$fave = CI
	    unset CI$fave
	  } else { 
	    if { [winfo exist .winex] } { 
	      .winex.frame.mess configure -text \
		"Grabbing Wavefront Measurement $fave of\
                                  $ws_stat(frame_ave) Wavefronts to average."
	    } else { return }
	    a.catpln CI CI$fave = CI
	    unset CI$fave
	  }
	  
	  update

	  after $inter
	  
	  if { $fave == $ws_stat(frame_ave) } { 
	    if { [calcnsave CI] == "Abort" } {
	      return "Abort"
	    }
	  }
	}	
      }
      #
      # Run/Save
      #
    } else {
      
      #
      # Running 30Hz
      #
      if { ($ws_stat(contfrm) == "Yes") } {

	set ws_stat(current_frame) 1
	#
	# Not Averaging
	#
	if { $ws_stat(frame_ave) == 1 } {

	  set msg "Grabbing $ws_stat(num_frames) Wavefront Measurements." 
	  make_stop_panel $msg
	  
	  # determine the number of captures to get to
	  # the total number of frames
	  set loop_num\
	    [expr $ws_stat(num_frames) / $wsParam(maxFrames)]

	  # if grabbing less than max frames, capture exact number of
	  # frames
	  if { $loop_num == 0 } {
	    set capture_frames $ws_stat(num_frames)
	  } else {
	    # if grabbing more than max frames, must add another
	    # set of frames if not divisable by max frames
	    if { [expr $ws_stat(num_frames) % $wsParam(maxFrames)]\
		   == 0 } {
	      set loop_num [expr $loop_num - 1]
	    }
	    set capture_frames $wsParam(maxFrames)
	  }
	  update
	  
	  # for each set grab the proper number of frames
	  for { set i 0 } { $i <= $loop_num } { incr i } {
	    set_date
	    fg.grabc $capture_frames = CurrIm$i

	    if { $i == 0 } { 
	      # save the first set of images into array CurrIm
	      a.copy CurrIm0 = CurrIm
	    } else { 
	      # if more than 1 set, concat the arrays into 1
	      a.catpln CurrIm CurrIm$i = CurrIm
	    }
	    update
	  }

	  if { ![winfo exist .wstop] } {
	    return "Abort"
	  } else { raise .wstop } 
	  

	  # reduce data
	  for {set fn 1} {$fn <= $ws_stat(num_frames)} {incr fn} {
	    if { [winfo exist .wstop] } {
	      raise .wstop
	      .wstop.mess configure -text \
		"Saving wavefront measurement $fn."
	    } else {
	      return "Abort"
	    }
	    update
	    set ws_stat(current_frame) $fn
	    set plnum [expr $fn - 1 ]
	    a.extpln CurrIm $plnum = Cim
	    if { [calcnsave Cim] == "Abort" } {
	      return "Abort"
	    }
	  }
	} else {
	  #
	  # Averaging <= MaxFrames for Frame Grabber
	  #
	  if { $ws_stat(frame_ave) <= $wsParam(maxFrames) } {
	    for {set i 1} {$i <= $ws_stat(num_frames)} {incr i} {
	      if { $i == 1 } { 
		set msg\
		  "Grabbing $ws_stat(frame_ave) Wavefront Measurements to\
                               average for Wavefront $i of\
                               $ws_stat(num_frames) Wavefront Measurements."
		make_stop_panel $msg
	      } else {
		if { [winfo exist .wstop] } { 
		  .wstop.mess configure -text \
		    "Grabbing $ws_stat(frame_ave) Wavefront Measurements\
                                to average for Wavefront $i of\
                                $ws_stat(num_frames) Wavefront Measurements."
		} else {
		  return "Abort"
		}
	      }
	      update
	      set_date
	      fg.grabc $ws_stat(frame_ave) = CurrIm$i
	      update
	    }

	    
	    update
	    for {set i 1} {$i <= $ws_stat(num_frames)} {incr i} {
	      if { [winfo exist .wstop] } {
		raise .wstop
		.wstop.mess configure -text \
		  "Saving wavefront measurement $i."
	      } else {
		return "Abort"
	      }
	      update
	      set ws_stat(current_frame) $i
	      if { [calcnsave CurrIm$i] == "Abort" } {
		return "Abort"
	      }
	      update
	    }
	  } else {
	    # Averaging > MaxFrames for Frame Grabber
	    # 
	    
	    set total_frames \
	      [expr $ws_stat(num_frames) * $ws_stat(frame_ave)]
	    set loop_num [expr $total_frames / $wsParam(maxFrames)]
	    # if grabbing more than max frames, must add another
	    # set of frames if not divisable by max frames
	    if { [expr $total_frames % $wsParam(maxFrames)] == 0 } {
	      set loop_num [expr $loop_num - 1]
	    }
	    set capture_frames $wsParam(maxFrames)

	    set msg\
	      "Grabbing $ws_stat(frame_ave) Wavefront Measurements for each\
			    of $ws_stat(num_frames) Wavefronts."
	    make_stop_panel $msg
	    
	    update
	    # for each set grab the proper number of frames
	    for { set i 0 } { $i <= $loop_num } { incr i } {
	      set_date
	      fg.grabc $capture_frames = CurrIm$i
	      update
	      if { ![winfo exist .wstop] } {
		return "Abort"
	      } else { raise .wstop }
	    }

	    update
	    set ca 0
	    set count 0
	    set cn 0
	    set num 0
	    for {set i 0} {$i <= $loop_num} {incr i} {
	      for {set j 0} {$j < $wsParam(maxFrames)} {incr j} {
		if { $num == 0 } {     
		  a.extpln CurrIm$i $j = CI$count 
		} else { 
		  a.extpln CurrIm$i $j = ci
		  a.catpln CI$count ci = CI$count
		}
		incr ca
		incr num
		if { $ca == $wsParam(maxFrames) } { 
		  set ca 0
		  incr cn   
		}
		if { $num == $ws_stat(frame_ave) } {
		  incr count
		  set num 0
		}
		update
		if { ![winfo exist .wstop] } {
		  return "Abort"
		} 
	      }
	    }

	    update
	    for { set i 0 } { $i < $ws_stat(num_frames) } { incr i } {
	      if { ![winfo exist .wstop] } {
		return "Abort"
	      } else {
		.wstop.mess configure -text \
		  "Saving data."
		raise .wstop
	      }
	      
	      set ws_stat(current_frame) [expr $i + 1]
	      if { [calcnsave CI$i] == "Abort" } {	   
		return "Abort"
	      }
	      update
	    }
	  }
	}
	
      } else {
	# 
	# Interval
	#

	set ws_stat(current_frame) 1		
	set msg\
	  "Saving Wavefront Measurement $ws_stat(current_frame) of\
 $ws_stat(num_frames)."
	make_stop_panel $msg
	
	for {set fnum 1} {$fnum <= $ws_stat(num_frames)} {incr fnum} {
	  for {set fave 1} {$fave <= $ws_stat(frame_ave)} {incr fave} { 
	    update
	    set ws_stat(current_frame) $fnum
	    if { [winfo exist .wstop] } {
	      if { $ws_stat(frame_ave) == 1 } { 
		.wstop.mess configure -text \
		  "Grabbing Wavefront Measurement $fnum of $ws_stat(num_frames)."
	      } else {
		.wstop.mess configure -text \
		  "Grabbing Wavefront Measurement $fave of\
                       $ws_stat(frame_ave) measurements to average for\
                       Wavefront $fnum of $ws_stat(num_frames)."
	      }
	      raise .wstop
	      update
	    }

	    set_date
	    fg.grabc 1 = CI($fnum)$fave
	    
	    if { $fave == 1 } {
	      a.copy CI($fnum)$fave = CI$fnum
	      unset CI($fnum)$fave
	    } else { 
	      a.catpln CI$fnum CI($fnum)$fave = CI$fnum
	      unset CI($fnum)$fave
	    }

	    after $inter

	    if { ![winfo exist .wstop] } {
	      return "Abort"
	    } else { raise .wstop }
	  }
	}
	
	for {set fnum 1} {$fnum <= $ws_stat(num_frames)} {incr fnum} {
	  set ws_stat(current_frame) $fnum
	  if { [winfo exist .wstop] } {
	    .wstop.mess configure -text \
	      "Saving Wavefront Measurement $fnum of $ws_stat(num_frames)."
	    raise .wstop
	    update
	  }

	  if { [calcnsave CI$fnum] == "Abort" } {
	    return "Abort"
	  }
	  if { ![winfo exist .wstop] } {
	    return "Abort"
	  } else { raise .wstop }
	}
      }	
      
      if { [winfo exists .wstop] } { destroy .wstop } 

      #
      # Make a Calibration directory
      #
      if { $platform == "windows" } {
	if { ![ file isdirectory $ws_stat(rundir)/Calibration ]} { 
	  file mkdir $ws_stat(rundir)/Calibration
	}
      } else {
	if { ![ file isdirectory $ws_stat(rundir)/Calibration ]} { 
	  exec mkdir $ws_stat(rundir)/Calibration
	}
      }
      
      #
      # Save Calibration Data for Re-Reduction
      #
      set obj_list { BestRefSpots BestTestSpots Centers CloserRefSpots \
		       CloserTestSpots FinalCenters FinalRefRects \
		       FinalTestRects Params Pupil PupilImage RefMatches \
		       RefPos RefRects TestMatches TestRects }
      foreach obj $obj_list { 
	a.save wlCalibrate($obj) $ws_stat(rundir)/Calibration/$obj
      }
      if { $platform == "windows" } { 
	file copy $wlData(rootDir)/Calibration/calData.tcl \
	  $ws_stat(rundir)/Calibration
      } else { 
	exec cp $wlData(rootDir)/Calibration/calData.tcl \
	  $ws_stat(rundir)/Calibration/.
      }	
    } 	
  } else {
    a.load /usr/home/wavescope/Calibration/BestTestSpots = CurrIm
    set ws_stat(num_frames) [a.cols CurrIm]
    for {set fnum 1} {$fnum <= $ws_stat(num_frames)} {incr fnum} {	
      set ws_stat(current_frame) $fnum
      if { [calcnsave Cim] == "Abort" } {
	return "Abort"
      }
    }
  }
  
  return "O.k."
}


#--------------------------------------------------------------------------
# proc doReduce
#
# Runs a Rereduce or a Custom Rereduce
#--------------------------------------------------------------------------

proc doReduce { } { 

  global ws_stat wlCalibrate platform BASE_TEST_DIR wsParam wsMLMParams
  global wsRunInfo Run_list


  # Initialization
  #
  set flag 0
  set starting_dir [pwd]

  # We need to find out which tests (if any) are candidates for rereduction.
  # The basic requirements are a Calibration directory and an Images
  # directory.
  #
  wl_PanelsWait .img "Looking for tests that can be rereduced..." +400+80
  update
  set valid {}
  set prevDir [pwd]
  cd $BASE_TEST_DIR
  if { $platform == "windows" } {
    catch {glob */*/Images} imgList
    set firstCut 0
  } else {
    set imgList [split [exec /bin/csh -c "find . -name Images -print" ]]
    set firstCut 2
  }
  foreach dir $imgList {
    set test [string range $dir $firstCut [expr [string last "Images" $dir] - 2]]
    set img $BASE_TEST_DIR/$test/Images
    set cal $BASE_TEST_DIR/$test/Calibration
    if { [file isdirectory $img] && [file isdirectory $cal] } {
      lappend valid $test
    }
  }
  # alphabetical order
  set valid [lsort -ascii $valid]
  
  if {[ winfo exists .img ]} { destroy .img }
  cd $prevDir

  # Make sure we found something.  If not, inform the user.
  #
  if { [llength $valid] == 0 } {
    set msg "There do not appear to be any tests with saved data."
    wl_PanelsWarn $msg +400+80 10c
    return "Abort"
  } else {
    # Put up a list box showing the test/run names determined above and let
    # the user pick.  As a side effect of the selection, the global variable
    # $ws_stat(rered) will be set.
    #
    set ok [ListBox .select_run $valid "Test/Run:" rered +450+80]
    if { ! $ok } {
      return "Abort"
    }
  }

  # Take the user's test/run selection and first verify that the Image
  # data for the user's selection are valid.  If that checks out, try
  # to load Calibration data.
  #
  a.load $BASE_TEST_DIR/$ws_stat(rered)/Images/0001 = im
  set cols [a.cols im]
  set rows [a.rows im] 
  if { ($cols != $wlCalibrate(CCDxpix)) || ($rows != $wlCalibrate(CCDypix)) } {
    set msg "The test/run you chose does not have valid Image data.\n\
(Expected $wlCalibrate(CCDxpix),$wlCalibrate(CCDypix) and got: $cols,$rows"
    wl_PanelsWarn $msg +400+80
    return
  } else  { 

    # Validate/load calibration data
    #
    if { ![file isdirectory $BASE_TEST_DIR/$ws_stat(rered)/Calibration] } {
      set msg "The test/run you chose does not have valid Calibration data."
      wl_PanelsWarn $msg +400+80
      cd $starting_dir
      return "Abort"
    }

    # Load the calibration data
    #
    if {[CalLoadRunData $BASE_TEST_DIR/$ws_stat(rered)/Calibration] == "Abort"} {
      cd $starting_dir
      return "Abort"
    }

    # Determine the pupil shape
    #
    if { [a.cols wlCalibrate(Pupil)] == 1 }  {
      set wlCalibrate(PupilShape) "Rectangular"
    } else {
      set wlCalibrate(PupilShape) "Circular"
    }

    set ws_stat(reduce_shape) $wlCalibrate(PupilShape)
    
    # get MLM information
    set calData $BASE_TEST_DIR/$ws_stat(rered)/Calibration/calData.tcl
    if { [file exists $calData] } {
      source $calData
    }
    set ws_stat(mlm) $wsMLMParams(name)
    ws_GetMLMSpec
    Stage_Positions

    # Custom Reduce option
    if { $ws_stat(reduce_custom) } {
      # Point to reduction directories
      set wlData(rootDir) "$BASE_TEST_DIR/$ws_stat(rered)"
      wl_CalSetSaveDir $wlData(rootDir)
      wl_CalSetLoadDir $wlData(rootDir)
      # save the calData.tcl file
      if { $platform == "windows" } {
	file copy -force $calData $wlCalibrate(saveDir)/calData.tmp
      } else {
	exec cp -f $calData $wlCalibrate(saveDir)/calData.tmp
      }

      # Call Calibration functions
      set status [Calibrate reduce]
      if { $status == "Abort" } {
	# replace calData.tcl file 
	if { $platform == "windows" } {
	  file rename -force $wlCalibrate(saveDir)/calData.tmp $calData
	} else {
	  exec mv -f $wlCalibrate(saveDir)/calData.tmp $calData
	}
	# Point to home directories and source calData for MLM information
	set wlData(rootDir) /usr/home/wavescope
	wl_CalSetSaveDir $wlData(rootDir)
	wl_CalSetLoadDir $wlData(rootDir)
	set calData $wlCalibrate(saveDir)/calData.tcl
	CalLoadRunData $wlCalibrate(saveDir)

	if { [file exists $calData] } {
	  source $calData
	}
	set ws_stat(mlm) $wsMLMParams(name)
	ws_GetMLMSpec
	Stage_Positions
	cd $starting_dir  	 
	return "Abort"
      } elseif { $status == "NoCal" } {
	# Reload the reduction files since cleared in CalInit
	if {[CalLoadRunData $BASE_TEST_DIR/$ws_stat(rered)/Calibration] == "Abort"} {
	  cd $starting_dir
	  return "Abort"
	}
	
	if { [a.cols wlCalibrate(Pupil)] == 1 }  {
	  set wlCalibrate(PupilShape) "Rectangular"
	} else {
	  set wlCalibrate(PupilShape) "Circular"
	}
      }
    } else {
      # do not want to save data for original re-reduce
      set ws_stat(save_data) 0
    }
    
    # Save away some parameters that we need to change to do the re-reduce.
    # We need to restore these parameters after the re-reduce.
    #
    set wsParam(Hold_tiltRemFlag) $wsParam(tiltRemFlag)
    set wsParam(Hold_focusRemFlag) $wsParam(focusRemFlag)
    set wsParam(Hold_Lambda) $wsParam(Lambda)

    # Bring in some parameters needed for the re-reduce. This
    # clobbers the internal variables we saved above.
    #
    source $BASE_TEST_DIR/$ws_stat(rered)/Run_Info.tcl
    
    if { $ws_stat(save_data) == 1 } { 
      if { [run_test] == "Abort" } { 
	cd $starting_dir
	restoreReduce
	return "Abort"
      }
      set flag "save"
    }
    
    set_date	
    parse_displist
	
    set dir_list [glob $BASE_TEST_DIR/$ws_stat(rered)/Images/*]
    set length [llength $dir_list]
    set msg "Reducing frame 1 of $length."
    make_stop_panel $msg
    
    # Load the data and Reduce!
    #
    for {set fnum 1} {$fnum <= $length} {incr fnum} {
      update
      set ws_stat(current_frame) $fnum
      .wstop.mess configure -text \
	"Reducing frame $ws_stat(current_frame) of $length."
      raise .wstop
      update	
      
      set image [fix_fnum $fnum]
      a.load $BASE_TEST_DIR/$ws_stat(rered)/Images/$image = CurrIm
      if { [calcnsave CurrIm] == "Abort" } {
	break
      }
      
      if { ![winfo exist .wstop] } {
	if { $flag == "save" } {
	  set flag "remove"
	}
	break
      }
    }
  }
  
  # Restore the stuff we changed and return
  #
  if { [winfo exists .wstop] } { destroy .wstop }
  if { $flag == "remove" } {
    set Run_list [ldelete $Run_list $wsRunInfo(run_name)]
    if ![ string compare $platform "windows" ] {
      file delete -force $BASE_TEST_DIR/$ws_stat(current_test)/$wsRunInfo(run_name)
    } else {
      exec rm -r $BASE_TEST_DIR/$ws_stat(current_test)/$wsRunInfo(run_name)
    }

    set fileid [open $BASE_TEST_DIR/$ws_stat(current_test)/Run_list.tcl w]
    puts $fileid "set Run_list {$Run_list}"
    close $fileid
  }
  cd $starting_dir
  restoreReduce
  set ws_stat(re_reduce) 0
  set ws_stat(reduce_custom) 0
  return 
}

############################################################################
#
# To replace parameters changed during doReduce 
#
############################################################################

proc restoreReduce { } {

  global wsParam wlData wlCalibrate ws_stat wsMLMParams
  
  set wsParam(tiltRemFlag) $wsParam(Hold_tiltRemFlag)
  set wsParam(focusRemFlag) $wsParam(Hold_focusRemFlag)
  set wsParam(Lambda) $wsParam(Hold_Lambda)
  unset wsParam(Hold_tiltRemFlag)
  unset wsParam(Hold_focusRemFlag)
  unset wsParam(Hold_Lambda)
  
  set wlData(rootDir) /usr/home/wavescope
  wl_CalSetSaveDir $wlData(rootDir)
  wl_CalSetLoadDir $wlData(rootDir)
  CalLoadRunData $wlCalibrate(saveDir)

  if { [a.cols wlCalibrate(Pupil)] == 1 }  {
    set wlCalibrate(PupilShape) "Rectangular"
  } else {
    set wlCalibrate(PupilShape) "Circular"
  }

  set calData $wlCalibrate(saveDir)/calData.tcl

  if { [file exists $calData] } {
    source $calData
  }
  set ws_stat(mlm) $wsMLMParams(name)
  ws_GetMLMSpec
  Stage_Positions
}


############################################################################
#
# To do the calculations and save the results, if necessary
#
############################################################################
proc calcnsave { img } \
{
  global ws_stat wsRunInfo
  
  upvar $img imgin
  
  update
  if { [LCalcWF imgin] == "Abort" } {
    return "Abort"
  }
  
  if { $ws_stat(save_data) } {
    verify_test
    set ws_stat(current_run) $wsRunInfo(run_name)
    put_arrays $ws_stat(current_run) $ws_stat(current_frame)
    save_arrays $ws_stat(current_frame)
    update
  } else {
    verify_test
    put_arrays $ws_stat(current_run) $ws_stat(current_frame)
    update
    # set the frame to zero for live display beam profile
    set ws_stat(current_frame) 0    
  }

  return
}

############################################################################
#
# proc parse_displist
#
# sets global typel to reflect the test quantities to be calculated
#
############################################################################

proc parse_displist {} \
{
    global ws_stat typel

for { set i 0 } { $i <= 14 } { incr i } { set typel($i) 0 }

if { [lsearch -glob  $ws_stat(disp_list) grad*   ] != -1 } { set typel(0)  1 }
if { [lsearch -glob  $ws_stat(disp_list) opd*    ] != -1 } { set typel(1)  1 }
if { [lsearch -glob  $ws_stat(disp_list) psf*    ] != -1 } { set typel(2)  1 }
if { [lsearch -glob  $ws_stat(disp_list) mtf*    ] != -1 } { set typel(3)  1 }
if { [lsearch -glob  $ws_stat(disp_list) enceng* ] != -1 } { set typel(4)  1 }
if { [lsearch -glob  $ws_stat(disp_list) fring*  ] != -1 } { set typel(5)  1 }
if { [lsearch -glob  $ws_stat(disp_list) beam*   ] != -1 } { set typel(6)  1 }
if { [lsearch -glob  $ws_stat(disp_list) zern*   ] != -1 } { set typel(7)  1 }
if { [lsearch -glob  $ws_stat(disp_list) mono*   ] != -1 } { set typel(8)  1 }
if { [lsearch -glob  $ws_stat(disp_list) seid*   ] != -1 } { set typel(9)  1 }
if { [lsearch -glob  $ws_stat(disp_list) herm*   ] != -1 } { set typel(10) 1 }
if { [lsearch -glob  $ws_stat(disp_list) cheb*   ] != -1 } { set typel(11) 1 }
if { [lsearch -glob  $ws_stat(disp_list) lege*   ] != -1 } { set typel(12) 1 }
if { [lsearch -glob  $ws_stat(disp_list) text_entry ] != -1 } { set typel(13) 1 }
if { [lsearch -glob  $ws_stat(disp_list) ms* ] != -1 } { set typel(14) 1 }

# If computing MTF or ENE, must compute PSF
if { $typel(3) == 1 || $typel(4) == 1 } { set typel(2) 1 }

# If computing Seidels, must compute Zernikes
if {  $typel(9) == 1 } { set typel(7) 1 }

# If computing PSF, MTF, ENE, Fringes, Monomials, Seidels, Chebychev, or
# Legendre, must compute OPD
if { $typel(2) == 1 ||  $typel(3) == 1 || $typel(4) == 1 || $typel(5) == 1 || \
      $typel(8) == 1 || $typel(9) == 1 || $typel(11) == 1|| $typel(12) == 1 } \
   { set typel(1) 1 }

# If computing Hermites, must compute Beam Profile
if { $typel(10) == 1 } { set typel(6) 1 }

# If computing Msquared, must compute Gradient and Opd
if { $typel(14) == 1 } { set typel(1) 1 }

# If computing beam profile, must compute OPD to get mask for calculating RMS.
if { $typel(6) == 1 } { set typel(1) 1 } 

# If computing OPD or Zernikes, must compute Gradient
if { $typel(1) == 1 || $typel(7) == 1 } { set typel(0) 1 }

}

##############################################################################
#
# An improved PSF calculator that scales properly for large OPDs
# Pupil is passed in, rather than using BeamP to allow for several
# choices in PSF calculation
#
##############################################################################

proc CalcPsf { pupil } \
{
    global ws_results wsParam wsMLMParams wlCalibrate

#
# Need to set PSFSize so it doesn't grow
#
    set wsParam(PSFSize) 100
    a.make 0 8 = coef
    set ncol [a.cols $ws_results(Opd)]
    set nrow [a.rows $ws_results(Opd)]
#
# find max Gradient
#
    a.v4tov2v2 $ws_results(Gradient) =  pos grad
    a.max grad = mgrad
    a.v2toxy mgrad = gx gy
    set Grad [expr sqrt([a.ave gx]*[a.ave gx] + [a.ave gy]*[a.ave gy])]
   
#
# Next we see if the gradients are too large ( 8.0 is an arbitrary choice
# and if so,  we interpolate the Opd (and Pupil)
# and fix the PSFSize and MLMSize so we get something
# 
    set lambei [expr $wsParam(Lambda) / 8.0 ]
    set GTest [expr int([expr $Grad / $lambei]) + 1.0 ]
#
# Now we check if the gradients are so large that it will
# take till the heat death of the universe to calculate the PSF
#
    if { $GTest > 20.0 } \
    {
	set limit [expr int([expr $GTest / 20.0]) + 1.0 ]
	set msg "The maximum wavefront gradient is too large \
	to properly represent the PSF! Setting wavelength for \
	PSF to current Lambda * $limit"
	
	if { [wl_PanelsContinueAbort $msg] == "Abort" } {
	    return "Abort"
	}
	
	update
	
	set Lambda [expr $wsParam(Lambda) * $limit]
	set GTest  [expr $GTest  / $limit]
    } \
    else \
    {
	set Lambda $wsParam(Lambda)
    }

    
    if { $GTest > 1.0 } \
    {
	a.repele $GTest coef 0 = coef
	a.repele $GTest coef 5 = coef
	set ncol [expr $ncol * $GTest]
	set nrow [expr $nrow * $GTest]
	a.transform $ws_results(Opd) $ncol $nrow coef = opd
	a.transform $pupil $ncol $nrow coef = Pupil
	update
    } \
    else \
    {
	a.copy $ws_results(Opd) = opd
	a.copy $pupil = Pupil
    }
    
    set mlmSize [expr $wsMLMParams(spacing) / $GTest]
    set wsParam(PSFSize) [expr $wsParam(PSFSize) * [expr sqrt([expr $GTest * $Lambda])]]


#
# finally calc the psf and scale its intensity properly
# a.sum of pupil should equal a.sum of PSF
#
    alg.calc.psf opd Pupil $wsParam(PSFSize) $wsParam(PSFSize) $mlmSize \
     $wlCalibrate(psfScale) $Lambda = ws_results(PSF)
    
    set fact [expr $GTest * $GTest]
    a.div ws_results(PSF) $fact = ws_results(PSF)
    update

    # Calculate a Strehl ratio. This version uses the
    # true pupil SHAPE but not the true pupil illumination!
    # Result is added to psf-id title
    #
    a.make 0 $ncol $nrow = sopd
    a.cut Pupil 0.1 = mask
    set mfact [expr [a.sum ws_results(PSF)] / [a.sum $mask] ]
    a.mul $mask $mfact = fmask
    alg.calc.psf sopd fmask $wsParam(PSFSize) $wsParam(PSFSize) $mlmSize \
	$wlCalibrate(psfScale) $Lambda = PerfPSF

    set cent [expr $wsParam(PSFSize) / 2 ]
    set peak  [a.ave [a.extele $ws_results(PSF) $cent $cent] ]
    set ppeak [a.ave [a.extele PerfPSF $cent $cent] ]
    set ws_results(Strehl) [expr $peak / $ppeak ]
    if { $ws_results(Strehl) > 1.00 } { set ws_results(Strehl) 1.00 }
    update

    return 
}

############################################################################
# This panel is used to stop execution of functions such as Run/Save and
# re-reduction
############################################################################
proc make_stop_panel { msg } {

  global applicationName ws_stat


  if { [winfo exist .wstop] } { destroy .wstop }

  toplevel .wstop 
  wm geometry .wstop +252+32
  wm title .wstop "$applicationName"
    
  update 

  message .wstop.mess -text $msg -width 10c 
    
  button .wstop.ybutton -text Cancel -command { destroy .wstop }
  pack   .wstop.mess .wstop.ybutton -side top -padx 5 -pady 5

  bind .wstop <Destroy> { destroy .wstop }
}

############################################################################
#
# proc set_date
#
# Get the date off the computer on either windows or linux
#
############################################################################
proc set_date { } {

    global ws_stat platform
    
    if { $platform == "windows" } { 
	set ttt [clock seconds]			
	set ws_stat(display_date) [clock format $ttt -format %c]
    } else {
	set ws_stat(display_date) [exec date]
    }

}

#--------------------------------------------------------------------------
# proc ReduceSetupPanel
#
# Creates the Custom Reduce panel for setup.
#--------------------------------------------------------------------------

proc ReduceSetupPanel { } {

  global wlPanel wlCalibrate 

  toplevel    .rsp
  wm title    .rsp "Custom Reduction Options"
  wm geometry .rsp +200+85
  
  # A box for selection of Test Source calibration parameters
  #
  frame .rsp.testsrc -relief ridge -borderwidth 3
  pack  .rsp.testsrc -side top -padx 2m -pady 2m -fill both
  
  label .rsp.testsrc.label -text "Test Source Calibration"
  pack  .rsp.testsrc.label -side top -padx 2m -pady 2m -fill x
  
  frame .rsp.testsrc.frm
  pack  .rsp.testsrc.frm -fill x
  
  frame .rsp.testsrc.frm.left
  pack  .rsp.testsrc.frm.left -anchor w -side left -fill x -expand true
  frame .rsp.testsrc.frm.right
  pack  .rsp.testsrc.frm.right -anchor e -side right -fill x -expand true
  
  checkbutton .rsp.testsrc.frm.left.puploc -text "Test Pupil Location" \
      -variable wlCalibrate(PupilLocFlg) -highlightthickness 0 -anchor w \
      -offvalue "No" -onvalue "Yes" -command { CalTogDepend PupilLocFlg }
  pack .rsp.testsrc.frm.left.puploc -side top -expand true -fill x
  
  checkbutton .rsp.testsrc.frm.right.puplim -text "Subaps in Pupil Only" \
      -variable wlCalibrate(circFlg) -highlightthickness 0 -anchor w \
      -offvalue "No" -onvalue "Yes"
  pack .rsp.testsrc.frm.right.puplim -side top -expand true -fill x

  checkbutton .rsp.testsrc.frm.right.editrect -text "Edit Subapertures" \
      -variable wlCalibrate(EditSubFlg) -highlightthickness 0 -anchor w \
      -offvalue "No" -onvalue "Yes"
  pack .rsp.testsrc.frm.right.editrect -side top -expand true -fill x
  
  if { ![file exists $wlCalibrate(saveDir)/BestTestSpots] } {
      .rsp.testsrc.frm.left.puploc configure -state disabled
      .rsp.testsrc.frm.right.puplim configure -state disabled
      .rsp.testsrc.frm.right.editrect configure -state disabled
      set wlCalibrate(PupilLocFlg) "No"
      set wlCalibrate(circFlg) "No"
      set wlCalibrate(EditSubFlg) "No"
  }
  
  # A box for selection of miscellaneous parameters
  #
  frame .rsp.misc -relief ridge -borderwidth 3
  pack  .rsp.misc -side top -padx 2m -pady 2m -fill both

  # save option
  checkbutton .rsp.misc.save -offvalue 0 -onvalue 1 \
      -text "Save re-reduced data as a new run" \
      -anchor w -variable ws_stat(save_data) \
      -highlightthickness 0
  pack .rsp.misc.save -side top -expand true -fill x
  
  # Create the control buttons at the bottom of the window
  #
  frame   .rsp.action -relief flat
  pack    .rsp.action -side top -padx 1m -pady 1m

  button  .rsp.action.ok -text "  OK  " \
      -command { destroy .rsp; set wlPanel(action) "O.k." }
  button  .rsp.action.cancel -text "Cancel" \
      -command { destroy .rsp; set wlPanel(action) "Cancel" }
  button  .rsp.action.help -text "Help" \
      -command {ShowHelp TestSetup.html}
  pack  .rsp.action.ok .rsp.action.cancel .rsp.action.help \
      -side left -padx 30 -pady 1m -expand 1

  bind .rsp <Destroy> { set wlPanel(action) "Cancel" }

  tkwait variable wlPanel(action)
  
  if { $wlPanel(action) == "Cancel"} {
      return "Abort"
  } else { 
      set wlCalibrate(RefMode) "Use Existing Data"
      set wlCalibrate(CalcAveFlg) "No"
      set wlCalibrate(RefSpotsFlg) "No"
      CalTogDepend RefSpotsFlg
      set wlCalibrate(PupilDataFlg) "No"
      set wlCalibrate(TestSubapFlg) "No"
  }
  return $wlPanel(action)
}

