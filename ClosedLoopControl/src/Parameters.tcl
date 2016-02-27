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
# FILE: Parameters.tcl
# 
# DESCRIPTION:	
#   Procedures for handling the various parameter values. 
# 
# $Id: Parameters.tcl,v 1.13 1999/09/29 17:02:15 stacy Exp $
# 
#--------------------------------------------------------------------------


#--------------------------------------------------------------------------
# proc ParametersInit
#
# Loads the parameters displayed in the Parameters window from defaults.
#--------------------------------------------------------------------------

proc ParametersInit {} {

  global wsParam LISTS_DIR


  source $LISTS_DIR/parameters.tcl
}


#--------------------------------------------------------------------------
# proc ParametersDefault
#
# Loads the parameters displayed in the Parameters window with default
# values.  Any previous values are lost!
#--------------------------------------------------------------------------

proc ParametersDefault {} {

  global wsParam 


  set wsParam(Lambda) 0.6350		
  set wsParam(tiltRemFlag) "Yes"
  set wsParam(focusRemFlag) "No"
  set wsParam(ZernRatio) 0.0000
  set wsParam(NZerns) 35
  set wsParam(NHerms) 3
  set wsParam(NMons) 3
  set wsParam(Ncheb) 3
  set wsParam(Nleg) 3
}


#--------------------------------------------------------------------------
# proc ParametersSave
#
# Writes out the values in wsParams to a LISTS_DIR file
#--------------------------------------------------------------------------

proc ParametersSave { } {

  global wsParam LISTS_DIR


  if {[winfo exist .wparsetup] } { destroy .wparsetup }

  set fileid [open $LISTS_DIR/parameters.tcl w]
  puts $fileid "set wsParam(Lambda) $wsParam(Lambda)"
  puts $fileid "set wsParam(tiltRemFlag) $wsParam(tiltRemFlag)"
  puts $fileid "set wsParam(focusRemFlag) $wsParam(focusRemFlag)"
  puts $fileid "set wsParam(ZernRatio) $wsParam(ZernRatio)"
  puts $fileid "set wsParam(NZerns) $wsParam(NZerns)"
  puts $fileid "set wsParam(NHerms) $wsParam(NHerms)"
  puts $fileid "set wsParam(NMons) $wsParam(NMons)"
  puts $fileid "set wsParam(Ncheb) $wsParam(Ncheb)"
  puts $fileid "set wsParam(Nleg) $wsParam(Nleg)"
  close $fileid
}


#--------------------------------------------------------------------------
# proc ParametersWin
#
# Fills in the existing panel ($win) created in ParametersSetup with
# the parameter edit controls.
#--------------------------------------------------------------------------

proc ParametersWin { win dummy } {

  global wsParam 


  checkbutton $win.frm01 -text "Enable Tilt Removal" -highlightthickness 0 \
      -variable wsParam(tiltRemFlag) -offvalue "No" -onvalue "Yes"
  pack $win.frm01 -side top -expand 1

  checkbutton $win.frm02 -text "Enable Focus Removal" -highlightthickness 0 \
      -variable wsParam(focusRemFlag) -offvalue "No" -onvalue "Yes"
  pack $win.frm02 -side top -expand 1 -pady 5

  foreach i { Lambda ZernRatio NZerns NMons NHerms Ncheb Nleg } {
    lappend ivalues "wsParam($i)" 
  }

  set msgs { "Lambda (mu):" "Zernike Obscuration ratio:" \
             "Number of Zernikes:" "Number of Monomials:" \
             "Number of Hermites:" "Number of Chebychev:" \
             "Number of Legendre:" }

  for {set i 0} {$i < [llength $ivalues]} {incr i} {
    PanelsBasicEntry2 $win [lindex $msgs $i] [lindex $ivalues $i]
  }
  
  set ivalues ""
  set msgs ""
}


#--------------------------------------------------------------------------
# proc ParametersSetup
#
# Creates the parameters display/modify window.
#--------------------------------------------------------------------------

proc ParametersSetup { } {

  global wlPanel


  set msg "Test Execution Parameters"

  set     blist "\"  OK  \""
  lappend blist "ParametersSave"
  lappend blist "Reload"
  lappend blist "ParametersInit"
  lappend blist "Defaults"
  lappend blist "ParametersDefault"
  lappend blist "Help"
  lappend blist "ShowHelp Params.html"

  PanelsGenericFrame .wparsetup $msg ParametersWin "create" $blist
}


#--------------------------------------------------------------------------
# proc ParamsCalSave
#
# Writes out the calibration values in wsParams to a LISTS_DIR file
#--------------------------------------------------------------------------

proc ParamsCalSave { } {

  global wsParam LISTS_DIR


  if {[winfo exist .wparamcal] } { destroy .wparamcal }
  ParamsCalSet

  set fileid [open $LISTS_DIR/calParams.tcl w]
  puts $fileid "set wsParam(minPix) $wsParam(minPix)"
  puts $fileid "set wsParam(edgeWidth) $wsParam(edgeWidth)"
  puts $fileid "set wsParam(minBright) $wsParam(minBright)"
  close $fileid
}


#--------------------------------------------------------------------------
# proc ParamsCalGet
#
# Sets global Tcl variables from our internal (C) code
#--------------------------------------------------------------------------

proc ParamsCalGet { } {

  global wsParam


  alg.rects.edge.width  = wsParam(edgeWidth)
  alg.rects.frac.bright = wsParam(minBright)
  alg.rects.min.pixs    = wsParam(minPix)
}


#--------------------------------------------------------------------------
# proc ParamsCalSet
#
# Sets internal (C) code variables from global Tcl
#--------------------------------------------------------------------------

proc ParamsCalSet { } {

  global wsParam


  alg.rects.edge.width  $wsParam(edgeWidth)
  alg.rects.frac.bright $wsParam(minBright)
  alg.rects.min.pixs    $wsParam(minPix)
}


#--------------------------------------------------------------------------
# proc ParamsCalInit
#
# Loads the parameters displayed in the Calibration Parameters window
# from defaults.
#--------------------------------------------------------------------------

proc ParamsCalInit {} {

  global wsParam LISTS_DIR


  source $LISTS_DIR/calParams.tcl
  ParamsCalSet
}


#--------------------------------------------------------------------------
# proc ParamsCalDefault
#
# Loads the parameters displayed in the Calibration Parameters window with
# default values.  Any previous values are lost!
#--------------------------------------------------------------------------

proc ParamsCalDefault {} {

  global wsParam 


  set wsParam(minPix) 3
  set wsParam(edgeWidth) 6
  set wsParam(minBright) 0.3
  ParamsCalSet
}


#--------------------------------------------------------------------------
# proc ParamsCalWin
#
# Fills the an existing panel ($win) created in ParamsCalSetup with
# the parameter edit controls.
#--------------------------------------------------------------------------

proc ParamsCalWin { win dummy } {

  global wsParam 


  foreach i { edgeWidth minPix minBright } {
    lappend ivalues "wsParam($i)" 
  }

  set msgs { "Edge width:" "Minimum Number of Pixels:" \
            "Minimum Fractional Brightness:" }

  for {set i 0} {$i < [llength $ivalues]} {incr i} {
    PanelsBasicEntry2 $win [lindex $msgs $i] [lindex $ivalues $i]
  }
  
  set ivalues ""
  set msgs ""
}


#--------------------------------------------------------------------------
# proc ParamsCalSetup
#
# Creates the calibration parameters display/modify window.
#--------------------------------------------------------------------------

proc ParamsCalSetup { } {

  global wlPanel


  ParamsCalGet

  set msg "Calibration Parameters"

  set     blist "\"  OK  \""
  lappend blist "ParamsCalSave"
  lappend blist "Reload"
  lappend blist "ParamsCalInit"
  lappend blist "Defaults"
  lappend blist "ParamsCalDefault"
  lappend blist "Help"
  lappend blist "ShowHelp ParamsCal.html"

  PanelsGenericFrame .wparamcal $msg ParamsCalWin "create" $blist

  ParamsCalSet 
}


#---------------------------------------------------------------------------
# proc ws_GetMLMSpec
#
# Extracts the spacing, type, and focal length from the MLM name.
# 
# wsMLMParams(name) = name
# wsMLMParams(type) = S or H
# wsMLMParams(spacing) = MLM spacing in microns
# wsMLMParams(fl) = MLM focal length in mm
#---------------------------------------------------------------------------

proc ws_GetMLMSpec { } {

  global wsMLMParams ws_stat

  
  set wsMLMParams(name) $ws_stat(mlm)
  
  set wsMLMParams(spacing) [lindex [split $ws_stat(mlm) _] 0]
  scan $wsMLMParams(spacing) %d wsMLMParams(spacing)
  set wsMLMParams(type) [lindex [split $ws_stat(mlm) _] 1]
  set wsMLMParams(fl) [lindex [split $ws_stat(mlm) _] 2]
  scan $wsMLMParams(fl) %d wsMLMParams(fl)
}  
