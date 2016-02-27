###################################################################
# IO.tcl
#
# Wavelab I/O functions
#
# $Id: IO.tcl,v 1.1 1997/06/02 19:47:35 stacy Exp $
#
###################################################################

#
# The following general user functions are defined in this file:
#
#	wl_Load		Load a FITS format file
#	wl_Save		Save to a FITS format file
#

#--------------------------------------------------------------------
# proc wl_Load
#
# Load a file named by $file into the variable named by $dest. Check for
# exceptional return conditions
#--------------------------------------------------------------------

proc wl_Load { file dest } \
{
    upvar $dest u_dest

    if { [catch { a.load $file = u_dest } msg] } \
	{ wl_PanelsMsg $msg; return "Failed" }

}

#----------------------------------------------------------------
# proc wl_Save
#
# Save the array $src to a file named by $file. Check for exceptional
# return conditions
#----------------------------------------------------------------

proc wl_Save { src file } \
{
    if { [catch { a.save $src $file } msg] } {
	#
	# Due to the way a.save checks for array names if $src is
	# not defined we will get the message:
	#	illegal character `<first letter of $src>`
	#	at line 1 character 1
	#
	if { [string match "illegal character *" $msg] } {
	    wl_PanelsMsg "invalid variable/array name: $src"
	} else {
	    wl_PanelsMsg $msg
	}
    }
}

