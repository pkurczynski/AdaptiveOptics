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
# FILE: Dark_proc.tcl
# 
# DESCRIPTION:	
#   
# 
# $Id: Dark_proc.tcl,v 1.1 2000/02/29 21:30:44 herb Exp $
# 
#--------------------------------------------------------------------------


#--------------------------------------------------------------------------
# proc Dark_proc
#
# Takes a Dark frame and saves it as Dark in /usr/home/wavescope/Calibration
#--------------------------------------------------------------------------

proc Dark_proc {} {

  fg.grab 15 = Dark
  a.to Dark f = Dark
  a.rebin Dark 1 1 15 = Dark
  a.extpln Dark 0 = Dark
  cd /usr/home/wavescope/Calibration
  a.save Dark Dark
  }

  