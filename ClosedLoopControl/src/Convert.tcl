#=================================================================#
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
#=================================================================#

#-----------------------------------------------------------------#
##TCLSRC
## 
## FILE: Convert.tcl
## 
## CONTENTS:
##       Routines for converting one file type to another.
## 
## $Id: Convert.tcl,v 1.2 1997/10/07 21:46:17 herb Exp $
## 
##----------------------------------------------------------------#

proc fits_to_code5 { args } \
{
  set argsc [ llength $args ]
  if { $argsc != 2 } \
  {
    puts "Usage: fits_to_code5 fits_file code5_file"
    puts "      code5_file name prefers .inX where X is 1-9"
  }
  set fits_file [ lindex $args 0 ]
  set code5_file [ lindex $args 1 ]

  puts "Read: $fits_file"
  a.load $fits_file = ffile
  a.info ffile = msg
  puts $msg
  set numcols [ a.cols ffile ]
  a.v2toxy ffile = xrow yrow

  set fp [ open $code5_file w 0644 ]
  puts $fp "CodeV Zernikes data converted from FITS format WaveScope output"
  puts $fp "ZFR $numcols WFR WVL 0.6328 SSZ 1.0"
  puts $fp "! ZYGOZFR"
  puts $fp "! REQ 640 480 0 1 0"

  set yelems [ a.dump yrow ]
  for {set idx 1} {$idx <= $numcols} {incr idx} \
  {
    set zval [ format "%15.8f" [ lindex $yelems $idx ] ]
    puts $fp $zval
  }
  close $fp
  puts "Wrote: $code5_file"
}