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
# FILE: Main.tcl
# 
# DESCRIPTION:	
#   Main entry/exit points for the wavescope system
# 
# $Id: Main.tcl,v 1.15 1999/02/11 16:42:26 herb Exp $
# 
#--------------------------------------------------------------------------


#--------------------------------------------------------------------------
# proc wavescope
# 
# Main entry point into wavescope
#--------------------------------------------------------------------------

proc wavescope {} \
{
    global applicationName platform

   
    # 
    # Initialize the application name
    #
    if { ![info exist applicationName] } { set applicationName "WaveScope" }

    PanelsInit
    
    WaveScope:popup
}


#---------------------------------------------------------------------------
# proc wl_FindLibFile
#
# Search for a named file using the paths in auto_path. If the file is
# found it is returned as the value of the procedure. "" is returned if the
# file is not found.
#---------------------------------------------------------------------------

proc wl_FindLibFile { file } \
{
    global auto_path

    foreach dir $auto_path {
	if { [file exists $dir/$file] } {
	    return $dir/$file
	}
    }

    return ""
}


#---------------------------------------------------------------------------
# proc wl_LoadResourceFile
#
# Load an X (Tk) resource file
#---------------------------------------------------------------------------

proc wl_LoadResourceFile { file } \
{
    if { [file exists $file] } {
	if { [catch {option readfile $file startupFile} msg] } {
	    puts stderr "error in app default file $file: $msg"
	    puts stderr "ignoring $file"
	}
    }
}
