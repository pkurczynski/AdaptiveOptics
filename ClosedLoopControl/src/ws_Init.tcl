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
# FILE: ws_Init.tcl
# 
# DESCRIPTION:	
#   Initialization routines.
# 
# $Id: ws_Init.tcl,v 1.41 2001/05/16 22:53:59 herb Exp $
# 
#--------------------------------------------------------------------------

#--------------------------------------------------------------------------
# proc ws_Init
#
# Initializes most of the run-time variables for WaveScope
#--------------------------------------------------------------------------

proc ws_Init { } {

  global BASE_DATA_DIR BASE_TEST_DIR LISTS_DIR
  global ws_stat ws_pw MLM_list Test_list cb_labels
  global Disp_types Text_types Spec_types All_types 
  global wsParam wsdb text_max_pix wlPanel
  global wlCalibrate wsRunInfo dtlStatus wlData
  global env tcl_platform platform calFiles


  set BASE_TEST_DIR $BASE_DATA_DIR/TESTS

  if [ array exists tcl_platform ] {
    set platform $tcl_platform(platform)
  } else {
    set platform unix
  }
    
  if { $platform == "windows" } {
    set os "windows"
  } else {
    set os [exec uname]
  }

  zern.set.type Zygo 0.0
  if { ![array exist wsParam] } {
    set wsParam(PSFSize) 128
  }
  set wsParam(GauSig) 10
  ParametersInit
  ParamsCalInit
  set wlData(rootDir) /usr/home/wavescope
  set wlCalibrate(baseDirName) "Calibration"
  set wlCalibrate(loadDir) "$wlData(rootDir)/$wlCalibrate(baseDirName)"
  set wlCalibrate(saveDir) "$wlData(rootDir)/$wlCalibrate(baseDirName)"
  set dark $wlData(rootDir)/$wlCalibrate(baseDirName)/Dark
  if { [file exists $dark] } {
    a.load $dark = wlCalibrate(Dark)
  }
  
  if { ![array exist ws_stat] } { 
    set ws_stat(mode) Production
    set ws_stat(new_test) False
    set ws_stat(caldir) unset
    set ws_stat(reduce_custom) 0
    set ws_stat(save_data) 0
    set ws_stat(mlm) ""
    set wsRunInfo(user_name) ""
    set wsRunInfo(date) ""
    set wsRunInfo(run_name) ""
    set ws_stat(replay) 0
  }

  if { ![array exist text_max_pix] } {
    set text_max_pix(entry_width) 1078
    set text_max_pix(entry_height) 741
    set text_max_pix(panel_width) 1107
    set text_max_pix(panel_height) 826
  }


  # Source the lists and hardware specific scripts.
  # This sets variables defined in the global scope.
  #
  source $LISTS_DIR/ws_pw.tcl
  source $LISTS_DIR/MLM_list.tcl
  set file [wl_FindLibFile wsGUI.tcl]
  if {$file != ""} {
    source $file
  } else {
    puts "wsGUI.tcl not found in auto_path"
  }

  # Initialize the calibration and hardware specific parameters
  #
  source $LISTS_DIR/defaultPupil.tcl
  source $LISTS_DIR/sensorParams.tcl
  LocalParamsInit
  CalParamsInit

  # Remove the calData file if it exists
  #
  set calData $wlCalibrate(saveDir)/calData
  if { [file exists $calData] } {
    if { $platform == "windows" } {
      file delete $calData
    } else {
      exec /bin/rm -f $calData
    }
  }
  set calFiles {CloserPupilImage FartherPupilImage CloserRefSpots BestRefSpots\
                PupilImage CloserTestSpots BestTestSpots Pupil Centers Params \
                RefRects RefMatches RefPos TestRects TestMatches \
                FinalTestRects FinalRefRects FinalCenters }

  # Determine the Test_list for this machine
  #
  set_test_list

  set Disp_types { image_id grad_vd opd_id opd_wd psf_id psf_wd mtf_pd \
                  enceng_pd fringes_id }
  set Spec_types { beam_profile }
  set Text_types { msquared zernikes seidels monomials hermites chebychev \
                  legendre text_entry }

  set All_types [concat $Disp_types $Spec_types]
  set All_types [concat $All_types $Text_types]

  set cb_labels(image_id) "Spot Image Display"
  set cb_labels(grad_vd) "Gradient Vector Display"
  set cb_labels(opd_id) "OPD Image Display"
  set cb_labels(opd_wd) "OPD Wire Display"
  set cb_labels(psf_id) "PSF Image Display" 
  set cb_labels(psf_wd) "PSF Wire Display"
  set cb_labels(mtf_pd) "MTF Plot Display" 
  set cb_labels(enceng_pd) "Encircled Energy Plot Display" 
  set cb_labels(fringes_id) "Fringes Image Display"
  set cb_labels(beam_profile) "Beam Profile Display"
  set cb_labels(msquared) "M Squared Display"
  set cb_labels(text_entry) "User Text Entry Display" 
  set cb_labels(zernikes) "Zernike Text Display" 
  set cb_labels(monomials) "Monomial Text Display"
  set cb_labels(seidels) "Seidel Text Display"
  set cb_labels(hermites) "Hermite Text Display" 
  set cb_labels(chebychev) "Chebychev Text Display"
  set cb_labels(legendre) "Legendre Text Display"

  set wsdb(exposureList) { 1/60 1/125 1/250 1/500 1/1000 1/2000 1/4000 1/10000 }
  set wsdb(stagePosition) -12000
  set wsdb(testSpotExposure) 1/1000
  set wsdb(testPupilExposure) 1/250
  set wsdb(refSpotExposure) 1/1000
  set wsdb(refPupilExposure) 1/250
  set wsdb(refNonPupilExposure) 1/250
  set wsdb(cameraExposure) 1/1
  set wsdb(realTimeDisplay) false
  set wsdb(font) "-*-courier-bold-r-normal--14-*"

  set wlPanel(fsbIDir) "/"
  set wlPanel(volumes) [file volume]

  set dtlStatus "EXIT"
}


#--------------------------------------------------------------------------
# proc set_test_list
#
# The Test_list is reset after data is restored by the DataManager
#--------------------------------------------------------------------------

proc set_test_list { } {
    global BASE_TEST_DIR Test_list platform

    # determine the Test_list for this machine
    set Test_list ""
    if { $platform == "windows" } {
	set pwd [pwd]
	if [catch {cd $BASE_TEST_DIR} err] \
	    {
		puts stderr $err
		return
	    }
	set t_list [glob * ]
	set s_list [lsort -dictionary $t_list]
    
	foreach x $s_list {
	    lappend Test_list [string trim $x]
	}
	cd $pwd
    } else {	
	set t_list [exec ls -m $BASE_TEST_DIR]
	set s_list [split $t_list ,]
	foreach x $s_list {
	    lappend Test_list [string trim $x]
	}
    }
}
