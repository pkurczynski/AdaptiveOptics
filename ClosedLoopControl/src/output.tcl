#Programme to take an initial directory, and recursively copy all
#binary files within it's subdirectories into ascii files stored in a
#single directory.

#usage: output initdir outdir
#for example:
#output c:/usr/data/tests/opd_only c:/hdyson/Incoming/data_ascii/

#hdyson, 6th November 03

proc output { InitDir Outdir } {

#    set Outdir [ file join $InitDir "data_ascii" ]

    if { [file isdirectory $Outdir]==0 } {
	file mkdir $Outdir
    }
    
    OutputFiles $InitDir $Outdir
    
}

proc OutputFiles { startDir endDir} {
#this function modified version of FindFile, see p116, Brent Welch
    
    set pwd [pwd]
    if [catch { cd $startDir } err] {
	puts stderr $err
	return
    }
    foreach match [ glob -nocomplain -- * ] {
	puts stdout [file join $startDir $match ]
	if [ file isdirectory $match] {
	    OutputFiles [file join $startDir $match ] $endDir
	} else {
	    fileConvert [file join $startDir $match ] $endDir
	}
    }
    cd $pwd
}

proc fileConvert { binfile endDir} {
    
    if [catch {a.load $binfile = temp } err ] {
	puts stderr $err
	return
    } else {
	set components [file split $binfile]
	set length [llength $components]
	set length [expr {$length-2} ]
	set description [lindex $components $length ]
	set length [expr {$length-1} ]
	set runname [lindex $components $length ]
	set tempfile [list $description $runname [file tail $binfile ] ]
	set textfile [join $tempfile _ ]
	append textfile .txt
	puts stderr "Textfile = $textfile"
	if [ regexp -nocase {opd.*} $textfile ] {
	    set temprows [a.rows temp]
	    set tempcols [a.cols temp]
	    puts stdout " Converted: Rows = $temprows Cols = $tempcols"
	    a.saveasc temp [file join  $endDir $textfile ]
	} elseif [ regexp -nocase {psf.*} $textfile ] {
	    set temprows [a.rows temp]
	    set tempcols [a.cols temp]
	    puts stdout " Converted: Rows = $temprows Cols = $tempcols"
	    a.saveasc temp [file join  $endDir $textfile ]
	} else {
	    puts stdout " Skipped"
	}
    }
}

##################################################
#
#ps_ routines added 15th March 04. Intended for use with
#'poke_sequence' routine from dm_panels_bmc.tcl ONLY!  These files
#DELETE the original data (to save space, since one poke_sequence data
#set ~0.5GB in size, and Poke_sequence is due to be modified to
#generate multiple data sets), and ONLY saves the ASCII-fied optical
#path difference files!  
#
#Might be an idea to back-port code for copying to gigabytes into standard output routine?
#
#hdyson @lucent.com
#

proc ps_output { InitDir Outdir Deflection } {

#    set Outdir [ file join $InitDir "data_ascii" ]

    if { [file isdirectory $Outdir]==0 } {
	file mkdir $Outdir
    }
    
    ps_OutputFiles $InitDir $Outdir $Deflection

#    ps_copy $Outdir [ file nativename //gigabytes/home2/ghi/hdyson/Wavescope_Data/. Deflection ]
}

proc ps_OutputFiles { startDir endDir deflection } {
#this function modified version of FindFile, see p116, Brent Welch
    
    set pwd [pwd]
    if [catch { cd $startDir } err] {
	puts stderr $err
	return
    }
    foreach match [ glob -nocomplain -- * ] {
	puts stdout [file join $startDir $match ]
	if [ file isdirectory $match] {
	    puts stdout "directory Match: $match"
	    if [ regexp -nocase {.*data_for_.*} $match ] {
		puts stdout "filtered 1 Match: $match"
#		if [regexp -nocase {.*opds.*} $match ] {
#		    puts stdout "filtered 2 Match: $match"
		    ps_OutputFiles [file join $startDir $match ] $endDir $deflection
#		}
	    }
	    if [regexp -nocase {.*opds.*} $match ] {
		    puts stdout "filtered 2 Match: $match"
		    ps_OutputFiles [file join $startDir $match ] $endDir $deflection
	    }
	} else {
	    puts stdout "non-directory Match: $match"
	    if [ regexp -nocase {000[123]} $match ] {
		puts stdout "filtered 3 Match: $match"
		ps_fileConvert [file join $startDir $match ] $endDir
	    }
	}
	if [ regexp -nocase {.*tcl} $match ] {
	     ;
	} else {
	    file delete -force $match
	}
    }
    cd $pwd
}

proc ps_fileConvert { binfile endDir} {
    
    if [catch {a.load $binfile = temp } err ] {
	puts stderr $err
	return
    } else {
	set components [file split $binfile]
	set length [llength $components]
	set length [expr {$length-2} ]
	set description [lindex $components $length ]
	set length [expr {$length-1} ]
	set runname [lindex $components $length ]
	set tempfile [list $description $runname [file tail $binfile ] ]
	set textfile [join $tempfile _ ]
	append textfile .txt
	puts stderr "Textfile = $textfile"
#	if [ regexp -nocase {opd.*} $textfile ] {
	    set temprows [a.rows temp]
	    set tempcols [a.cols temp]
	    puts stdout " Converted: Rows = $temprows Cols = $tempcols"
	    a.saveasc temp [file join  $endDir $textfile ]
# 	} elseif [ regexp -nocase {psf.*} $textfile ] {
# 	    set temprows [a.rows temp]
# 	    set tempcols [a.cols temp]
# 	    puts stdout " Converted: Rows = $temprows Cols = $tempcols"
# 	    a.saveasc temp [file join  $endDir $textfile ]
#	} else {
#	    puts stdout " Skipped"
#	}
    }
}

proc ps_copy { indir outdir Deflection } {

    file copy $indir [ file join $outdir "Automated_" $Deflection ]

#     if [catch { cd $startDir } err] {
# 	puts stderr $err
# 	return
#     }
#     foreach match [ glob -nocomplain -- * ] {
# 	file copy $match $outdir
#     }
}