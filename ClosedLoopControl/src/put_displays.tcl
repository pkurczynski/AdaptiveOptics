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
# FILE: put_displays.tcl
# 
# DESCRIPTION:	
#   The procedures in this file support placing and drawing in the various
#   data displays.
# 
# $Id: put_displays.tcl,v 1.69 2000/09/01 17:55:49 herb Exp $
# 
#--------------------------------------------------------------------------


# ****************************************************************************
#
#  proc put_image_id { }
#  
# ****************************************************************************
proc put_image_id { } {

    global image_id_arr
    global image_id

# First check that this file exists - if so then source it

    id.new image_id
    id.set.wh image_id $image_id_arr(width) $image_id_arr(height)
    id.set.xy image_id $image_id_arr(xpos) $image_id_arr(ypos)
    id.set.colormap image_id $image_id_arr(colormap)
    id.set.interp image_id $image_id_arr(interp)
    id.set.ncolors image_id $image_id_arr(ncolors)
    id.set.title image_id Spots
}
# ****************************************************************************
#
#  proc put_grad_vd { }
#  
# ****************************************************************************
proc put_grad_vd { } {

    global grad_vd_arr
    global grad_vd

# First check that this file exists - if so then source it

    vd.new grad_vd
    vd.set.wh grad_vd $grad_vd_arr(width) $grad_vd_arr(height)
    vd.set.xy grad_vd $grad_vd_arr(xpos) $grad_vd_arr(ypos)
    vd.set.title grad_vd Gradients
}

# ****************************************************************************
#
#  proc put_opd_id { }
#  
# ****************************************************************************
proc put_opd_id { } {

    global opd_id_arr
    global opd_id

# First check that this file exists - if so then source it

    id.new opd_id
    id.set.wh opd_id $opd_id_arr(width) $opd_id_arr(height)
    id.set.xy opd_id $opd_id_arr(xpos) $opd_id_arr(ypos)
    id.set.colormap opd_id $opd_id_arr(colormap)
    id.set.interp opd_id $opd_id_arr(interp)
    id.set.ncolors opd_id $opd_id_arr(ncolors)
    id.set.title opd_id Opd
}

# ****************************************************************************
#
#  proc put_opd_wd { }
#  
# ****************************************************************************
proc put_opd_wd { } {

    global opd_wd_arr
    global opd_wd

# First check that this file exists - if so then source it

    wd.new opd_wd
    wd.set.wh opd_wd $opd_wd_arr(width) $opd_wd_arr(height)
    wd.set.xy opd_wd $opd_wd_arr(xpos) $opd_wd_arr(ypos)
    wd.set.title opd_wd Opd
    wd.set.type opd_wd $opd_wd_arr(type)
    wd.set.hide opd_wd $opd_wd_arr(hide)
    wd.set.pers opd_wd $opd_wd_arr(pers)
    wd.set.color opd_wd $opd_wd_arr(color)
}

# ****************************************************************************
#
#  proc put_psf_id { }
#  
# ****************************************************************************
proc put_psf_id { } {

    global psf_id_arr
    global psf_id

# First check that this file exists - if so then source it

    id.new psf_id
    id.set.wh psf_id $psf_id_arr(width) $psf_id_arr(height)
    id.set.xy psf_id $psf_id_arr(xpos) $psf_id_arr(ypos)
    id.set.colormap psf_id $psf_id_arr(colormap)
    id.set.interp psf_id $psf_id_arr(interp)
    id.set.ncolors psf_id $psf_id_arr(ncolors)
    id.set.title psf_id "Normalized PSF"
    

}

# ****************************************************************************
#
#  proc put_psf_wd { }
#  
# ****************************************************************************
proc put_psf_wd { } {

    global psf_wd_arr
    global psf_wd

# First check that this file exists - if so then source it

    wd.new psf_wd
    wd.set.wh psf_wd $psf_wd_arr(width) $psf_wd_arr(height)
    wd.set.xy psf_wd $psf_wd_arr(xpos) $psf_wd_arr(ypos)
    wd.set.title psf_wd "Normalized PSF"
    wd.set.type psf_wd $psf_wd_arr(type)
    wd.set.hide psf_wd $psf_wd_arr(hide)
    wd.set.pers psf_wd $psf_wd_arr(pers)
    wd.set.color psf_wd $psf_wd_arr(color)

}

# ****************************************************************************
#
#  proc put_mtf_pd { }
#  
# ****************************************************************************
proc put_mtf_pd { } {

    global mtf_pd_arr
    global mtf_pd

# First check that this file exists - if so then source it

    pd.new mtf_pd
    pd.set.wh mtf_pd $mtf_pd_arr(width) $mtf_pd_arr(height)
    pd.set.xy mtf_pd $mtf_pd_arr(xpos) $mtf_pd_arr(ypos)
    pd.set.color mtf_pd $mtf_pd_arr(color)
    pd.set.grid mtf_pd $mtf_pd_arr(grid)
    pd.set.line mtf_pd $mtf_pd_arr(line)
    pd.set.type mtf_pd $mtf_pd_arr(type)
    pd.set.title mtf_pd MTF

}

# ****************************************************************************
#
#  proc put_enceng_pd { }
#  
# ****************************************************************************
proc put_enceng_pd { } {

    global enceng_pd_arr
    global enceng_pd

    pd.new enceng_pd
    pd.set.wh enceng_pd $enceng_pd_arr(width) $enceng_pd_arr(height)
    pd.set.xy enceng_pd $enceng_pd_arr(xpos) $enceng_pd_arr(ypos)
    pd.set.color enceng_pd $enceng_pd_arr(color)
    pd.set.grid enceng_pd $enceng_pd_arr(grid)
    pd.set.line enceng_pd $enceng_pd_arr(line)
    pd.set.type enceng_pd $enceng_pd_arr(type)
    pd.set.title enceng_pd "Encircled Energy"

}

# ****************************************************************************
#
#  proc put_fringes_id { }
#  
# ****************************************************************************
proc put_fringes_id { } {

    global fringes_id_arr
    global fringes_id
    global platform

# First check that this file exists - if so then source it

    id.new fringes_id
    id.set.wh fringes_id $fringes_id_arr(width) $fringes_id_arr(height)
    id.set.xy fringes_id $fringes_id_arr(xpos) $fringes_id_arr(ypos)
    id.set.colormap fringes_id $fringes_id_arr(colormap)
    id.set.interp fringes_id $fringes_id_arr(interp)
    id.set.ncolors fringes_id $fringes_id_arr(ncolors)
    id.set.title fringes_id Fringes
    if { $platform == "windows" } {
	id.set.text.align fringes_id -1 -1
	id.set.text.coords fringes_id 0
 	id.set.text fringes_id "Synthetic Fringe" 30 15
    }
}

# ****************************************************************************
#
#  proc put_beam_profile { }
#  
# ****************************************************************************
proc put_beam_profile { } {

    global bp_arr
    global SlSt
    global platform

# First check that this file exists - if so then source it

    set SlSt(id_title) "Beam Intensity"
    set SlSt(pd_title) "Beam Intensity Cuts"
    
    foreach type {id pd} {
	
	${type}.new SlSt($type)
	${type}.set.wh $SlSt($type) \
	    $bp_arr(${type}_width) $bp_arr(${type}_height)
	${type}.set.xy $SlSt($type) \
	    $bp_arr(${type}_xpos) $bp_arr(${type}_ypos)
	${type}.set.title $SlSt($type) $SlSt(${type}_title)

	if { $type == "id" } {
	    id.set.colormap $SlSt(id) $bp_arr(${type}_colormap)
	    id.set.interp $SlSt(id) $bp_arr(${type}_interp)
	    id.set.ncolors $SlSt(id) $bp_arr(${type}_ncolors)
 	    if { $platform == "windows" } {
		id.set.over.coords $SlSt(id) 1
	    }
        	id.set.over.width $SlSt(id) 1
	} else {
	    pd.set.grid $SlSt(pd) $bp_arr(${type}_grid)
	    pd.set.line $SlSt(pd) $bp_arr(${type}_line)
	    pd.set.type $SlSt(pd) $bp_arr(${type}_type)
	}
    }

}

# ****************************************************************************
#
#  proc save_arrays { fnum }
#  Takes as argument the frame number for a specific test/run.
#  Saves all arrays in ws_results to corresponding directory in
#  ws_stat(rundir).
#
# ****************************************************************************
proc save_arrays { fnum } {

    global ws_stat ws_results wsRunInfo platform Test_types

#   Have to parse num to be 0001 etc
    set frame_num [fix_fnum $fnum]

    foreach array_name [array names ws_results] {
	update
	if { $array_name != "Text" } { 
	    # Check if first frame - if so then create dirs
	    if { ![string compare $frame_num 0001] } {
		if {([catch {a.info ws_results($array_name)} result]) \
			&& ($array_name!="Strehl")} {
		    set fileid [open $ws_stat(rundir)/Run_Info.tcl a]
		    puts $fileid \
		      "set ws_results($array_name) {$ws_results($array_name)}"
		    close $fileid
		} else {
		    if { $platform == "windows" } {
			file mkdir $ws_stat(rundir)/${array_name}s
		    } else {
			exec mkdir $ws_stat(rundir)/${array_name}s
		    }
		}
	    }
	    if {([catch {a.info ws_results($array_name)} result]) \
		    && ($array_name!="Strehl")} {
	    } else { 
		a.save $ws_results($array_name) \
		    $ws_stat(rundir)/${array_name}s/$frame_num
	    }
	} else {
	    
	    set fileid [open $ws_stat(rundir)/Run_Info.tcl a]
	    puts $fileid "set ws_results(Text) {$ws_results(Text)}"
	    set ivalues ""
	    if { $platform == "windows" } {
		set ttt [clock seconds]
		set wsRunInfo(date) [clock format $ttt -format %c]
	    } else {
		set wsRunInfo(date) [exec date]
	    }
	    foreach i { user_name run_name date } {
		puts $fileid "set wsRunInfo($i) {$wsRunInfo($i)}"
	    }
	    close $fileid
	}
	update
    }
    
}

# ****************************************************************************
#
#  proc put_arrays { }
#  added scale overlays to PSF and OPD
#  
# ****************************************************************************
proc put_arrays { run_name fnum } {

    global ws_stat ws_results Disp_types Text_types wsMLMParams
    global text_id wsParam wlCalibrate SlSt wsRunInfo platform 

    set frame_num [fix_fnum $fnum]

    foreach item $ws_stat(disp_list) {

	update
	set array_name [get_arrayname $item]

	# Do this part only if in Disp_types
	foreach type $Disp_types {

	    if { ![string compare $item $type] } {

		set dlist [get_dlist $item]
		set dtype [lindex $dlist 0]

		global $item
		update
		
		if { $ws_stat(save_data) } {
		    set finfo "$fnum/$ws_stat(num_frames)"
		    $dtype.set.title $item "$run_name $array_name \
			    $finfo $ws_stat(display_date)"
		} else {
		    $dtype.set.title $item "$run_name $array_name \
			    $ws_stat(display_date)"
		}

		if { ![string compare $type "mtf_pd"] } {
		    get_mtf_pd_array
		} elseif { ![string compare $type "enceng_pd"] } {
		    set enesiz [a.cols $ws_results($array_name) ]
		    a.tilt $enesiz 0  $wlCalibrate(psfScale) = enescale
		    $dtype.set.xy.array $item $enescale \
			    $ws_results($array_name)
		    if { $platform == "windows" } {
			$dtype.label.xy $item "Radius (microradians)" "Fractional Encircled Energy"
		    } else {
	                    $dtype.label.xy $item "Radius (microradians)" "Frac. En."
		    }
		} elseif { ![string compare $type "psf_wd"] }  {
		    set Sval [a.ext $ws_results(Strehl)]
		    set Sval [format %8.4f $Sval]
		    if { $platform == "windows" } {
			wd.set.display $item 0
			$dtype.set.array $item $ws_results(PSF) \
			  $wlCalibrate(psfScale)
		    } else {
			# normalize PSF
			set max [a.max ws_results(PSF)]
			a.max ws_results(PSF) = norm
			a.div ws_results(PSF) norm = ws_results(PSF)
			$dtype.set.array $item $ws_results(PSF) \
			  $wlCalibrate(psfScale) $Sval
		    }
		    if { [info exists wlCalibrate(psfScale)]  && \
			    [info exists wsParam(PSFSize)] } {
			wd.set.axes $item PSF $wlCalibrate(psfScale) \
				$wsParam(PSFSize) $Sval 
		    } else {
			wd.set.axes $item NONE
		    }
		    if { $platform == "windows" } {
			wd.set.display $item 1
		    }
		} elseif { ![string compare $type "psf_id"] } {
		    set max [a.max ws_results(PSF)]
		    if { $max > 1.0 } { 
			a.max ws_results(PSF) = norm
    			a.div ws_results(PSF) norm = ws_results(PSF)
		    }
		    if {[info exists ws_results(Strehl)]} {
			set Sval [a.ext $ws_results(Strehl)]
			set Sval [format %8.4f $Sval]
			$dtype.set.array $item $ws_results($array_name) \
			  $wlCalibrate(psfScale) $Sval
			psfover $item
			if { $platform == "windows" } { 
			    $dtype.set.text.coords $item 0
			    $dtype.set.text.align $item -1 1
			    $dtype.set.text.color $item 1.0 1.0 0.3
			    $dtype.set.text $item "Strehl Ratio = $Sval" 10 10
			}
		    } else { 
			$dtype.set.array $item $ws_results($array_name) \
				$wlCalibrate(psfScale) 
			psfover $item
			if { $platform == "windows" } { 
			    $dtype.set.text.coords $item 0
			    $dtype.set.text.align $item -1 1
			    $dtype.set.text.color $item 1.0 1.0 0.3
			}
		    }			
		} elseif { ![string compare $type "opd_id"] } {
		    # compute peak-to-valley and rms
		    set rms\
			[a.rmsmask $ws_results($array_name) \
			     $ws_results(Mask)]
		    set rms [format %8.4f $rms]
		    $dtype.set.array $item $ws_results($array_name) $rms
		    opdover $item 
		    if { $platform == "windows" } {
			set min [a.min $ws_results($array_name)]
			set max [a.max $ws_results($array_name)]
			set pv [expr $max - $min]
			set pv [format %8.4f $pv]
			$dtype.set.text.coords $item 0
			$dtype.set.text.align $item -1 1
			$dtype.set.text.color $item 1.0 1.0 0.3
			$dtype.set.text $item "PV  = $pv microns" 10 10
			$dtype.set.text $item "RMS = $rms microns" 10 25  
		    } 
		    if { [info exist ws_results(Mask)] } {
		        $dtype.set.stat.mask $item ws_results(Mask)
		    } else {
			$dtype.set.stat $item
		    }
		} elseif { ![string compare $type "fringes_id"] } {
		    if { [info exists ws_results(Mask)] } {
			set rms\
				[a.rmsmask $ws_results(Opd) $ws_results(Mask)]
		    } else { 
			set rms [a.rms $ws_results(Opd)]
		    }
		    set rms [format %8.4f $rms]
		    $dtype.set.array $item $ws_results($array_name) $rms  
		    opdover $item
		    if { $platform == "windows" } {
			$dtype.set.text.coords $item 0
			$dtype.set.text.align $item -1 1
			$dtype.set.text.color $item 1.0 1.0 0.3
		 	$dtype.set.text fringes_id "Synthetic Fringe" 30 10
			$dtype.set.text $item "RMS = $rms microns" 10 25
		    }
		} elseif { ![string compare $type "grad_vd"] } {
		    if { $platform != "windows" } {
		      vectover $item 
		    }
	            $dtype.set.array $item $ws_results($array_name)
		    if { $platform == "windows" } {
		      vectoverwin $item 
		    }
		} elseif { ![string compare $type "opd_wd"] }  {
		    if { [info exists wsMLMParams(spacing)] } {
			if { [info exists ws_results(Mask)] } {
			    set rms\
				[a.rmsmask $ws_results($array_name)\
				     $ws_results(Mask)]
			} else {
			    set rms [a.rms $ws_results($array_name)]
			}
			set rms [format %8.4f $rms]
			set ws_stat(rms) $rms
			if { $platform == "windows" } { 
			    wd.set.display $item 0
			    $dtype.set.array $item $ws_results($array_name)
			    wd.set.axes $item OPD $wsMLMParams(spacing) \
				    $rms
			    wd.set.display $item 1
			} else {
			    $dtype.set.array $item \
				    $ws_results($array_name) $rms
			    wd.set.axes $item OPD $wsMLMParams(spacing)
			}
		    } else {
			$dtype.set.array $item $ws_results($array_name)
			wd.set.axes $item NONE
		    }
		    if { [info exist ws_results(Mask)] } {
			$dtype.set.stat.mask $item ws_results(Mask)
		    } else {
			$dtype.set.stat $item
		    }
		} else {
		    # Image display
		    if { [info exists ws_results(AveImage)] } {  
   		        $dtype.set.array $item $ws_results(Ave$array_name)
   		    } else {
   		        $dtype.set.array $item $ws_results($array_name)
   		    }
 		    if { $platform == "windows"  } { 
			set min [a.min $ws_results($array_name)]
			set max [a.max $ws_results($array_name)]
			set min [format %7.1f $min]
			set max [format %7.1f $max]
			id.clr.text $item
			id.set.text.coords $item 0
			id.set.text.align $item -1 1
			id.set.text.color $item 1.0 1.0 0.3
			id.set.text $item "Min = $min  ADU" 10 10
			id.set.text $item "Max = $max  ADU" 10 25
		    }
		}
	    }
	}
	
	# Spec_type beam_profile
	
	if { ![string compare $item "beam_profile"] } {
	    
	    update
	    set SlSt(id_title) "Intensity"
	    set SlSt(pd_title) "Cuts"
	    
	    foreach type {id pd} {
		if { $ws_stat(save_data) } {
		    set finfo "$fnum/$ws_stat(num_frames)"
		    ${type}.set.title $SlSt($type) \
			"$run_name $SlSt(${type}_title) $finfo\
			    $ws_stat(display_date)"
		} else {	
		    ${type}.set.title $SlSt($type) \
			"$run_name $SlSt(${type}_title) $ws_stat(display_date)"
		}
	    }
	    if { [info exists ws_results(Mask)] } {
		set min [a.minmask $ws_results(BeamP) $ws_results(Mask)]
		set max [a.maxmask $ws_results(BeamP) $ws_results(Mask)]
	    } else {
		set min [a.min $ws_results(BeamP)]
		set max [a.max $ws_results(BeamP)]
	    }
	    set min [format %7.1f $min]
	    set max [format %7.1f $max]
	    if { $platform == "windows"  } { 
		id.clr.text SlSt(id)
		id.set.text.coords SlSt(id) 0
		id.set.text.align SlSt(id) -1 1
		id.set.text.color SlSt(id) 1.0 1.0 0.3
		id.set.text SlSt(id) "Min = $min  ADU" 10 10
		id.set.text SlSt(id) "Max = $max  ADU" 10 25
	    }

	    # first frame of a multi-frame test or not a multi-frame test
	    if { ($ws_stat(current_frame) == 1) && ($ws_stat(replay) == 0) } {
		sliceInit $ws_results(BeamP)
		pd.clr.arrays $SlSt(pd)
		if { [info exist ws_results(Mask)] } {
		    id.set.stat.mask SlSt(id) ws_results(Mask)
		} else {
		    id.set.stat SlSt(id)
		}
	    } else {
		sliceGet segments
		sliceShow $ws_results(BeamP) $segments
		if { [info exist ws_results(Mask)] } {
		    id.set.stat.mask SlSt(id) ws_results(Mask)
		} else {
		    id.set.stat SlSt(id)
		}
	    }
	}

	foreach type $Text_types {
	    
	    update
	    if { ![string compare $item $type] } {


		if { $ws_stat(save_data) } {
		    set finfo "$fnum/$ws_stat(num_frames)"
		    wm title .$item "$run_name $array_name $finfo\
                                    $ws_stat(display_date)"
		} else {
		    wm title .$item "$run_name $array_name\
                                    $ws_stat(display_date)"
		}
		
		if { [string compare $type "text_entry"] } {
		  if { ![info exists ws_results($array_name)] } {
		    set ws_results($array_name) "Data does not exist."
		  }
		  if { $type == "msquared" } {
                    if {[catch {a.info ws_results($array_name)} result] } {
			set ms $ws_results($array_name)
		    } else {
		        set ms [a.ave $ws_results($array_name)]
		    }
		    UpdateTextPanel $text_id($item) $ms $fnum
		  } else {
		    text_update $text_id($item) $ws_results($array_name)\
		      $fnum
		  }
		} else {
		    foreach i { user_name run_name date } {
			set temp $wsRunInfo($i)
			.text_entry.wsRunInfo($i).entry delete 0 end
			.text_entry.wsRunInfo($i).entry insert 0 $temp
		    }
		    .text_entry.frm.txt delete 1.0 end
		    .text_entry.frm.txt insert 1.0 $ws_results(Text)
		}
		
	    }
	}
    }
}

# ****************************************************************************
#
#  proc reset_displays { }
#
#  Resets geometry of displays for current test.
#  If a run is current, resets that data.
#  
# ****************************************************************************

proc reset_displays { } {

    global ws_stat BASE_TEST_DIR wlCalibrate 

    if { $ws_stat(current_test) == "" } { 
	return
    }

    put_test
    
    if {[info exists ws_stat(current_run)]} {
	set dir $BASE_TEST_DIR/$ws_stat(current_test)/$ws_stat(current_run)
	if {[info exists wlCalibrate(PupilShape)]} {
   	    set wlCalibrate(Hold_Shape) $wlCalibrate(PupilShape)
      	} else {
  	    set wlCalibrate(Hold_Shape) NULL
    	}	
	if { [file exists $dir/Run_Info.tcl] } {
	    set fileid [open $dir/Run_Info.tcl r]
	    set data [read $fileid]
 	    if { [lsearch $data wlCalibrate(PupilShape)] != -1 } {
		set pupil \
	      [lindex $data [expr [lsearch $data wlCalibrate(PupilShape)] + 1]]
		set wlCalibrate(PupilShape) $pupil
	    } else {
		set wlCalibrate(PupilShape) "Circular"
	    }
	    close $fileid
	} 
	if { $ws_stat(current_run) == "Re-Reduce" } { 
   	    set wlCalibrate(PupilShape) $ws_stat(reduce_shape)
  	} 	

	put_arrays $ws_stat(current_run) $ws_stat(current_frame)

	if { ![string compare $wlCalibrate(Hold_Shape) "NULL"] } {
      	    set wlCalibrate(PupilShape) $wlCalibrate(Hold_Shape)
	    unset wlCalibrate(Hold_Shape) 
  	}

    }
}

# ****************************************************************************
#
#  proc remove_displays { }
#
#  Remove all displays that are open
#  
# ****************************************************************************
proc remove_displays { } {

    global Disp_types Text_types
    global SlSt bp_arr ws_stat

    foreach item $Disp_types {
	global $item
	global ${item}_arr
    }
    foreach item $Text_types {
	global ${item}_id
    }

    # check for open window displays - destroy them if they exist
    # Disp_types
    foreach item $Disp_types {

	set dlist [get_dlist $item]
	
	set dtype [lindex $dlist 0]
	if { ![catch {$dtype.sync $item}] } {
	    # check that window still exists - if it does destroy.
	    unset $item
	}
    }
    # Spec_type beam_profile
    foreach type {id pd} {
	
	if { ![catch ${type}.sync SlSt($type)] } {
	    # check that window still exists - if it does destroy.
	    unset SlSt($type)
	}
    }
    # Text_Types
    foreach item $Text_types {
	if { [winfo exists .$item] } {
	    # check that window still exists - if it does destroy.
	    destroy .$item
	}
    }

    # check for display arrays - unset them if they exist
    foreach item $Disp_types {
	if { [info exists ${item}_arr] } {
	    unset ${item}_arr
	}
    }
    # Spec_type beam_profile
    if { [info exists bp_arr] } {
	unset bp_arr
    }


    # Check for replay data panel - destroy if it exists
    if {[winfo exists .rp]} {destroy .rp}
    # Check for live display panel - destroy if it exists
    if {[winfo exists .dtl]} {destroy .dtl}

    set ws_stat(current_test) ""
}


# ****************************************************************************
#
#  proc get_arrayname { disp_item }
#
#  From current disp_list item returns display array name
#  
# ****************************************************************************

proc get_arrayname { disp_item } {

    if {[lsearch -glob  $disp_item image* ] != -1} {set name Image}
    if {[lsearch -glob  $disp_item grad* ] != -1} {set name Gradient}
    if {[lsearch -glob  $disp_item opd*  ] != -1} {set name Opd}
    if {[lsearch -glob  $disp_item psf*  ] != -1} {set name PSF}
    if {[lsearch -glob  $disp_item mtf*  ] != -1} {set name MTF}
    if {[lsearch -glob  $disp_item enceng* ] != -1} {set name ENE}
    if {[lsearch -glob  $disp_item fring*] != -1} {set name Fringe}
    if {[lsearch -glob  $disp_item beam* ] != -1} {set name Beamp}
    if {[lsearch -glob  $disp_item ms* ] != -1} {set name Msquared}
    if {[lsearch -glob  $disp_item zern* ] != -1} {set name Zernike}
    if {[lsearch -glob  $disp_item mono* ] != -1} {set name Monomial}
    if {[lsearch -glob  $disp_item seid* ] != -1} {set name Seidel}
    if {[lsearch -glob  $disp_item herm* ] != -1} {set name Hermite}
    if {[lsearch -glob  $disp_item cheb* ] != -1} {set name Chebychev}
    if {[lsearch -glob  $disp_item lege* ] != -1} {set name Legendre}
    if {[lsearch -glob  $disp_item text* ] != -1} {set name "Text Entry"}
    
    return $name
}

# ****************************************************************************
#
#  proc get_mtf_pd_array { }
#
#  Converts mtf 2d array to an xcut and ycut line plots to display to
#  a plot display.
#  
# ****************************************************************************

proc get_mtf_pd_array { } {

    global ws_results mtf_pd wsParam wlCalibrate

    set wsParam(PSFSize) [a.cols ws_results(PSF)]
    
    set mtfScale [expr 1000.0 / ($wsParam(PSFSize) *  $wlCalibrate(psfScale))]  
    pd.set.color mtf_pd yellow
    set row [expr $wsParam(PSFSize) / 4 ]
    a.extrow ws_results(MTF) $row = mtfrow
    a.extcol ws_results(MTF) $row = mtfcol
    a.ext mtfrow $row $row = mtfrow
    a.ext mtfcol $row $row = mtfcol
    a.tilt $row 0.0 $mtfScale = xaxis
    pd.set.xy.array mtf_pd xaxis mtfrow
    pd.set.color mtf_pd yellow
    pd.add.xy.array mtf_pd xaxis mtfcol
    pd.set.color mtf_pd green
    pd.label.xy mtf_pd "Freq. (1/milliradians)" "MTF"
    pd.sync mtf_pd

}


# ****************************************************************************
#
# fix_int
# Remove trailing zeros from wavescope filenames
#
# ****************************************************************************
proc fix_int { number } {
    if { $number == "0000" } {return 0}
    return [string trimleft $number 0]
}


# ****************************************************************************
#
# fix_fnum
# Converts frame number from integer to filename representing that frame
#
# ****************************************************************************
proc fix_fnum { fnum } {

    if { $fnum < 0 } { 
	puts "Illegal filename!"
	return -1
    }
    if { $fnum < 10 } {
	return "000$fnum"
    } 
    if { $fnum < 100  } {
	return "00$fnum"
    } 
    if { $fnum < 1000 } {
	return "0$fnum"
    } 
    if { $fnum < 10000 } {
	return "$fnum"
    } 
	
    puts "frame number is over 10000!"
    puts "Only 4 places are supported!"
    return -1

}

#****************************************************************************
# opdover determines the specific values for on overlay of axis and
# scaling on the opd image display
#****************************************************************************
proc opdover { opdid } {
    global wsMLMParams ws_results platform
    
    set ticintx [expr 1000. / $wsMLMParams(spacing) ]
    set ticinty $ticintx
    set stx 0
    set sty 0
    
    if { $platform == "windows" } { 
	set texoff 5

    } else {
	set texoff 2
    }
    set labstx 0
    set labintx 1
    set labsty 0
    set labinty 1
    set dispnam $opdid
    set disptyp "id"
    set sx [a.cols ws_results(Opd)]
    set ticleny $sx
    set ticnumx [expr floor([expr $sx / $ticintx])]
    set legend "mm at MLM" 
    set sy [a.rows ws_results(Opd)]
    set ticlenx $sy
    set ticnumy [expr floor([expr $sy / $ticinty])]

    drawax  $dispnam $disptyp $stx $sty $ticintx $ticnumx $ticinty $ticnumy \
	$ticlenx $ticleny $texoff $labstx $labintx $labsty $labinty $legend 

}

#****************************************************************************
# maketicy makes the y axis overlay lines in the image and vector displays
# for the scaling
#****************************************************************************
proc maketicy { size locx locy overele } \
{
    upvar $overele ovel
    set st [expr $locx + $size]
    set et $locx 
    a.make "< $st $locy $et $locy >" 1 = ovel
}

#****************************************************************************
# maketicx makes the x axis overlay lines in the image and vector displays
# for the scaling
#****************************************************************************
proc maketicx { size locx locy overele } \
{
    upvar $overele ovel
    set st [expr $locy + $size]
    set et $locy 
    a.make "< $locx $st $locx $et >" 1 = ovel
}


#--------------------------------------------------------------------------
# proc vectoverwin
#
# Determines the specific values for overlays of axis and scaling on the
# Windows NT gradient vector display.
#--------------------------------------------------------------------------

proc vectoverwin { vectvd } {

  global wsMLMParams wlCalibrate ws_results 


  set pxx [a.ext $wlCalibrate(Params) 0 1 ]
  set pyy [a.ext $wlCalibrate(Params) 3 1 ]
  
  set avgParam [expr $pxx + $pyy ]
  set avgParam [expr $avgParam / 2.0]
#    a.split wlCalibrate(FinalCenters) = gpx gpy
  a.split ws_results(Gradient) = gpx gpy posx posy
  set muperpix [expr $wsMLMParams(spacing) * $avgParam]
  set ticintx [expr 1000.0 /$muperpix] 
  set ticinty $ticintx
  set stx 0
  set sty 0
  
  set texoff 50
  set labstx 0
  set labintx 1
  set labsty 0
  set labinty 1
  set dispnam $vectvd
  set disptyp "vd"
  
  set sx [a.max gpx]
  set ticnumx [expr floor([expr $sx / $ticintx])]
  set legend "mm at MLM" 
  set sy [a.max gpy]
  set ticnumy [expr floor([expr $sy / $ticinty])]
  set ticleny $sx
  set ticlenx $sy
  drawax  $dispnam $disptyp $stx $sty $ticintx $ticnumx $ticinty $ticnumy \
      $ticlenx $ticleny $texoff $labstx $labintx $labsty $labinty $legend 
}


#--------------------------------------------------------------------------
# proc vectover
#
# Determines the parameters for overlays of axis and scaling on the Linux
# gradient vector display.
#--------------------------------------------------------------------------

proc vectover { vectvd } {

  global wsMLMParams wlCalibrate ws_results $vectvd


  set pxx [a.ext $wlCalibrate(Params) 0 1 ]
  set pyy [a.ext $wlCalibrate(Params) 3 1 ]
  set avgParam [expr $pxx + $pyy ]
  set avgParam [expr $avgParam / 2.0]

  set muperpix [expr $wsMLMParams(spacing) * $avgParam]
  set gridSpacing [expr 1000.0 / $muperpix] 

  vd.set.axes $vectvd $gridSpacing

  set legend "mm at MLM" 
  a.split ws_results(Gradient) = gpx gpy posx posy
  set sx [a.max gpx]
  set sy [a.min gpy]
  set lx [expr $sx / 2]
  set ly [expr $sy / 2 ]
  vd.set.text $vectvd $lx $ly $legend
}


#****************************************************************************
# psfover determines the specific values for on overlay of axis and
# scaling on the psf image display
#****************************************************************************
proc psfover { psfid } {

    global wlCalibrate  wsParam platform ws_results
    
    if { $wlCalibrate(psfScale) * $wsParam(PSFSize) < 2000.0 } {
	set ticintx [expr 100 / $wlCalibrate(psfScale) ]
	set ticinty $ticintx
	set stx 0
	set sty 0
	if { $platform == "windows" } { 
	    set texoff 12
	} else { 
	    set texoff 8
	}
	set labstx 0
	set labintx 100
	set labsty 0
	set labinty 100
	set dispnam $psfid
	set disptyp "id"
	set sx [a.cols ws_results(PSF)]
	set ticleny $sx
	set ticnumx [expr floor([expr $sx / $ticintx])]
	set legend "microradians" 
	set sy [a.rows ws_results(PSF)]
	set ticlenx $sy
	set ticnumy [expr floor([expr $sy / $ticinty])]

	drawax  $dispnam $disptyp $stx $sty $ticintx $ticnumx $ticinty \
	    $ticnumy $ticlenx $ticleny $texoff $labstx $labintx $labsty \
	    $labinty $legend 
    } else {
	set ticintx [expr 1000 / $wlCalibrate(psfScale) ]
	set ticinty $ticintx
	set stx 0
	set sty 0
	if { $platform == "windows" } { 
	    set texoff 20
	} else {
	    set texoff 8
	}
	set labstx 0
	set labintx 1000
	set labsty 0
	set labinty 1000
	set dispnam $psfid
	set disptyp "id"
	set sx [a.cols ws_results(PSF)]
	set ticleny $sx
	set ticnumx [expr floor([expr $sx / $ticintx])]
	set legend "microradians" 
	set sy [a.rows ws_results(PSF)]
	set ticlenx $sy
	set ticnumy [expr floor([expr $sy / $ticinty])]

	drawax  $dispnam $disptyp $stx $sty $ticintx $ticnumx $ticinty \
	    $ticnumy $ticlenx $ticleny $texoff $labstx $labintx $labsty \
	    $labinty $legend 
    }
}

# ****************************************************************************
proc makecir { centx centy rad cirar } \
{
    global platform

    upvar $cirar cire

    if { $platform == "windows" } {
	set num 40
    } else {
	set num 100
    }
    
    a.make "< 0 0 0 0 >" $num = cire
    for { set i 0 } { $i < $num } { incr i } {
	set angst [expr (6.28319 / $num) * $i ]
	set angsp [expr (6.28319 / $num) * ( $i + 1 ) ]

	set stx [expr $rad * cos($angst) + $centx]
	set sty [expr $rad * sin($angst) + $centy]
	set spx [expr $rad * cos($angsp) + $centx]
	set spy [expr $rad * sin($angsp) + $centy]

	a.repele "< $stx $sty $spx $spy >" cire $i = cire
    }

}

#****************************************************************************
# drawax draws the axis, scaling, and labels for image and vector displays
#****************************************************************************
proc drawax { dispnam disptyp stx sty ticintx ticnumx ticinty ticnumy ticlenx \
	ticleny texoff labstx labintx labsty labinty legend} {
#
# dispnam is name of display
# disptyp is either "id" or "vd"
# stx, sty are the coords of origin
# ticint is tic spacing
# ticnum is number of tics
# ticlen is 1/2 length of tic
# texoff is offset of text from tic
#
# ALL ARE IN DATA COORDS
#
# labst is label value at start
# labint is label increment per tic
#
    global  $dispnam ws_results platform
    
    # Special change to text offset for PSF
    set name [string range $dispnam 0 2]
    if { $name == "psf" } {
      set texyoff [expr $texoff + 5]
      set scale 2.5
    } else {
      set texyoff $texoff
      set scale 2
    }
# Turn off updating to display, clear display, and set colors
    $disptyp.set.display $dispnam 0
    $disptyp.clr.text $dispnam
    $disptyp.clr.over.array $dispnam
    $disptyp.set.text.color $dispnam 1.0 1.0 1.0
    $disptyp.set.over.color $dispnam .6 .6  0
    set tic ""
    
# determine the window size
    $disptyp.get.wh $dispnam = width height 

# determine overlay line segment for the first label on x axis
    set startx $stx
    set starty $sty
    set endx [expr $startx + $ticintx]
    set endy $starty
    a.make "< $startx $starty $endx $endy >" 1 = over
# x-axis
    if { $name == "psf" } { 
	set lengthx 5
	set lengthy $lengthx
    } elseif { $name == "opd" || $name == "fri" } {
	set lengthx 2
	set lengthy $lengthx
    } else { 
	set lengthx 10
	set lengthy $lengthx
    }
    maketicx $ticlenx $startx $starty $tic
    a.catcol over $tic = over
    maketicx $ticlenx [expr $startx + $ticleny] $starty $tic
    a.catcol over $tic = over
    
# determine starting text and location for x axis
    $disptyp.set.over.width  $dispnam 0.1
    if { $platform == "windows" } {
	$disptyp.set.over.coords $dispnam 1
	$disptyp.set.text.coords $dispnam 1
	$disptyp.set.text.align  $dispnam 0 -1
    }
    set legx $startx
    set legy [expr $starty - $texoff]
    set num $labstx
    $disptyp.set.text $dispnam $num $legx $legy 

# determine the middle and last x values
    scan [expr ($ticnumx - 1)/ 2] %d mid
    set last [expr $ticnumx - 1]

# determine all text and overlay locations for x axis
    for { set i 0 } { $i < $ticnumx } { incr i } {   
	maketicx $lengthx $endx $endy $tic
	a.catcol over $tic = over
	set endn [expr $ticlenx - $lengthx]
	maketicx $lengthx $endx $endn $tic
	a.catcol over $tic = over
	set legx $endx
	set legy [expr $endy - $texoff]
	set num [expr $num + $labintx]
	if { ($width < 450) || ( $labintx == 100 ) } { 
	    if { ( $i == $mid ) || ( $i == $last ) } { 
		$disptyp.set.text $dispnam $num $legx $legy 
	    }
	} else {
	    $disptyp.set.text $dispnam $num $legx $legy 
	}
	if { $i != $last }  {
	    set endx [expr $endx + $ticintx]
	}
    }
    
# put up x axis label
    set legx [expr  $endx  / 2.0 ]
    set legy [expr  $starty - $scale * $texoff - 1]
    $disptyp.set.text.color $dispnam 1.0 1.0 0.3
    $disptyp.set.text $dispnam $legend $legx $legy
    $disptyp.set.text.color $dispnam 1.0 1.0 1.0
   
# determine overlay line segment for the first label on y axis
    if { $platform == "windows" } {
	$disptyp.set.text.align  $dispnam 0 0
    }
    set startx $stx
    set starty $sty
    set endy [expr $starty + $ticinty]
    set endx $startx
# y-axis
    maketicy $ticleny $startx $starty $tic
    a.catcol over $tic = over
    maketicy $ticleny $startx [expr $starty + $ticlenx] $tic
    a.catcol over $tic = over
 
# determine starting text and location for y axis
    set legy $starty
    set legx [expr $startx - $texyoff]
    set num $labsty
    $disptyp.set.text $dispnam $num $legx $legy 

# determine the middle and last y values
    scan [expr ($ticnumy - 1)/ 2] %d mid
    set last [expr $ticnumy - 1]

# determine all text and overlay locations for y axis
    for { set i 0 } { $i < $ticnumy } { incr i } {   
	maketicy $lengthy $endx $endy $tic
	a.catcol over $tic = over
	set endn [expr $ticleny - $lengthy]
	maketicy $lengthy $endn $endy $tic
	a.catcol over $tic = over
	set legy $endy
	set legx [expr $endx - $texyoff]
	set num [expr $num + $labinty]
	if { $height < 400 } { 
	    if { ( $i == $mid ) || ( $i == $last ) } { 
		$disptyp.set.text $dispnam $num $legx $legy 
	    }
	} else {
	    $disptyp.set.text $dispnam $num $legx $legy 
	}
	if { $i != $last }  {
	    set endy [expr $endy + $ticinty]
	}
    }
    
# put up grid and then display all text and overlays
#
    $disptyp.set.over.array $dispnam over
    $disptyp.set.display $dispnam 1
}




