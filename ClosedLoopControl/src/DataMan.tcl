#####################################################################
# datamanager
#
# archive and restore utility 
#####################################################################

#--------------------------------------------------------------------
# proc data_manager (called by wsGUI.tcl, calls data_box, Mount and
# Unmount
#
# Main entry point, sets mode of operation 
#--------------------------------------------------------------------
proc data_manager {data_mode {device_type NO_DEVICE} } {
   global BASE_DATA_DIR mount_point source_dir dest_dir option_list Test_list
   global platform

   set CWD [pwd]

   if ![string compare $platform "windows"] {
	# Let the user select the drive
	set mount_point [set_drive_letter]
	if { $mount_point == "" } { 
		unset mount_point
		return 
	}
   } else {
	set mountpoints(unix_jaz) /jaz
	set mountpoints(unix_zip) /zip
	set mountpoints(unix_floppy) /floppy
	set mount_point $mountpoints(${platform}_${device_type})
   }

   # set both source and destination directories base on data_mode
   switch $data_mode {
	archive {
	   set source_dir $BASE_DATA_DIR/TESTS
	   set dest_dir $mount_point
	   set option_list $Test_list
	}
	restore {
	   set source_dir $mount_point
	   set dest_dir $BASE_DATA_DIR/TESTS
	   set option_list ""
	}
   }

   if ![ string compare $platform "windows" ] {
	data_box $data_mode $device_type
   } else {

	set hostname [exec /bin/hostname]
	switch $hostname {
	   amber {
		set jaz_device sdb
		set zip_device sdc
	   }
	   default {
		set jaz_device sda
		set zip_device sdb
	   }
	}

	# Specific to disk media
	if [Mount] {
	   dialog "Mount of $mount_point media failed"
	   return
	} else {
	   data_box $data_mode $device_type
	}

        cd $CWD

	# Specific to disk media
	if [Umount] {
	   dialog "Unmount of $mount_point media failed"
	   return
	} else {
	   switch $device_type {
		jaz {
		   if [catch {exec jaztool /dev/${jaz_device} eject} result] {
			dialog "The Jaz cartridge failed to eject"
		   } 
		}
	   	zip {
	      	   if [catch {exec ziptool /dev/${zip_device} eject} result] { 
	 		dialog "The Zip cartridge failed to eject"
		   }
	        }
	   }
	}

   }

   if ![string compare $data_mode "restore"] { 
	set_test_list 
   }

   unset mount_point
   cd $CWD; unset CWD
   return
}


#--------------------------------------------------------------------
# proc data_box (called by data_manager, calls List* and Data* routines
# identified in the bindings
#
# Used to build list of data to be archive/restore
#--------------------------------------------------------------------
proc data_box {data_mode device_type} {
   global avail_space top source_dir option_list dest_dir platform

   # option list is set to Test_list when in archive mode
   if ![string compare $data_mode "restore"] {
      set option_list ""

      if ![ string compare $platform "windows"] {
	set dir_ok [catch {cd $source_dir}]
	if { $dir_ok } {
	    dialog "$source_dir is not ready"
	    cancel_data
	}
      } else {
            cd $source_dir
      }

      set b [ glob -nocomplain * ]
      foreach c $b {
	lappend option_list [string trim $c]
      }

   }

   if ![ string compare $platform "unix" ] {
      set avail_space [exec df -k $dest_dir | awk "\$1 ~ /dev/ {print \$4}"]
   }

   #puts stdout $avail_space 
   #
   # Verify that the source directory is not empty
   #
   if {[llength $option_list] <= 0} { 
        dialog "No files in source directory."
        return
   } else {

   	toplevel .dm
   	wm title .dm "Data Manager"
	wm geometry .dm +350+250
   	grab .dm
   	set top .dm.top
   	set bottom .dm.bottom

   	frame $top 
   	frame $bottom 
   	pack $top -side top
   	pack $bottom -side bottom
   	label $top.label1 -text "[string toupper $data_mode] MODE"

	if ![string compare $platform "unix"] {
	if ![string compare $data_mode archive] {
	   label $top.label2 -text "Available Space on $device_type:  \
		$avail_space Kbytes"
	} else {
	   label $top.label2 -text "Available Space on Hard Drive:  \
		$avail_space Kbytes"
	}
	}

   	pack $top.label1 -side top -padx 2m -pady 2m
	if ![string compare $platform "unix"] {
	   pack $top.label2 -side top -anchor w -padx 2m -pady 2m
	}
   	button $bottom.cancel -text Cancel -command { cancel_data }
   	button $bottom.ok -text Ok -command { destroy .dm ; prep_data }
   	pack $bottom.ok $bottom.cancel -side left -padx 2m -pady 2m

   	foreach side { left right } { frame $top.$side
	   pack $top.$side -side $side

	   listbox $top.$side.list -yscrollcommand [list $top.$side.scroll set]
	   scrollbar $top.$side.scroll -orient vertical \
		-command [list $top.$side.list yview]


	   if ![string compare $side left] {
	      label $top.$side.label -text "Data for $data_mode"
	   } else {
	      label $top.$side.label -text "Selected Data"
	   }

   	pack $top.$side.label -fill x -side top -anchor w
   	pack $top.$side.list -side left
   	pack $top.$side.scroll -fill y -side right
   	}

   	bind $top.left.list <ButtonPress-1> {ListSelectStart %W %y}
   	bind $top.left.list <B1-Motion> {ListSelectExtend %W %y}
   	bind $top.left.list <ButtonRelease-1> \
	   [list DataSelectEnd %W %y $top.right.list]

   	bind $top.right.list <ButtonPress-1> {ListSelectStart %W %y}
   	bind $top.right.list <B1-Motion> {ListSelectExtend %W %y}
   	bind $top.right.list <ButtonRelease-1> {DataDeleteEnd %W %y}

   	foreach item $option_list {
	   $top.left.list insert end $item
   	}
   	tkwait window .dm
   }   
}

#--------------------------------------------------------------------
# proc Mount (called by data_manager)
#
# Used to mount the archive/restore disk media
#--------------------------------------------------------------------
proc Mount { } {
   global mount_point
   set status_code [ catch {exec mount /$mount_point} ]

   # The Zip drives are so slow that the status_code gets set to a "1"
   # prematurely.  In most cases, the /zip file system DID mount.
   if ![ string compare $mount_point "/zip" ] {
	set status_code [ catch {exec df | grep -q $mount_point} ]
   }

   return $status_code
}

#--------------------------------------------------------------------
# proc Umount (called by data_manager)
#
# Used to unmount the archive/restore disk media
#--------------------------------------------------------------------
proc Umount { } {
   global mount_point 
   set status_code [ catch {exec umount /$mount_point} ]
   return $status_code
}

#--------------------------------------------------------------------
# proc DataSelectEnd
#
# This procedure displays items selected from the left listbox in the 
# right listbox
#--------------------------------------------------------------------
proc DataSelectEnd { w y dst } {
   global avail_space source_dir source_list dest_dir dest_list total_size
   global platform

   set pwd [pwd]
   if ![ string compare $platform "windows"] {
	set dir_ok [catch {cd $dest_dir}]
	if { $dir_ok } {
	    dialog "$dest_dir is not ready"
	    cancel_data
	}
   } else {	
   	cd $dest_dir
   }

   # Are there any files in the destination directory?
   set check_conflict [llength [glob -nocomplain * ]]
   cd $pwd

   $w select set anchor [$w nearest $y]
   foreach i [$w curselection] {
 	if [info exists item] { unset item }

        set item [$w get $i]
	set a [list $item]
	#puts stdout "$a"

	#set size [exec du -sk $source_dir/$item | awk "{print \$1}"]
	set size [ expr [directory_size $source_dir/$item] / 1000 ]

	if ![info exists total_size] { set total_size 0 }

	set size_check [expr $total_size + $size]

	if ![string compare $platform "unix"] {
	if { $size_check > $avail_space } { 
	   dialog "Insufficient space on $dest_dir for $item" 
	   continue 
	}
	}
 
           if [info exists source_list] {
	      # avoid multiple selections of the same item
              if { [lsearch -exact $source_list $item] < 0 } {
                $dst insert end $item
                lappend source_list $item
		set total_size [expr $total_size + $size]
		if [info exists dest_list] { lappend dest_list $item } 
              } else {
                dialog "$item is already selected"
		continue
              }
           } else {
		# initialize source_list
                $dst insert end $item
                set source_list $a
		set total_size $size
           }
	# compare selections against contents of destination directory and 
	# address any duplicate file/directory names
	if { $check_conflict } {
	   if [file exists $dest_dir/$item] { handle_duplicate $a }
	}
	#$puts stdout "Total Size: $total_size"
   }
   #puts stdout $source_list
}

#
# proc DataDeleteEnd
#
# This procedure removes items from the right listbox
#
proc DataDeleteEnd { w y } {
   global source_dir source_list dest_list total_size

   $w select set anchor [$w nearest $y]
   foreach i [lsort -decreasing [$w curselection]] {
	set item [$w get $i]
        $w delete $i

	if [info exists dest_list] {
	   set original_name [lindex $source_list $i]
	   #set size [exec du -sk $source_dir/$original_name | awk "{print \$1}"]
	   set size [ expr [directory_size $source_dir/$original_name] / 1000 ]
	} else {
	   #set size  [exec du -sk $source_dir/$item | awk "{print \$1}"]
	   set size [ expr [directory_size $source_dir/$item] / 1000 ]
	}

        set source_list [lreplace $source_list $i $i]
	if [info exists dest_list] {
	   set dest_list [lreplace $dest_list $i $i]
	}

	set total_size [expr $total_size - $size]
	#puts stdout "Total Size: $total_size"	
   } 
   #puts stdout $source_list
}

#--------------------------------------------------------------------
# proc handle_duplicate (called by DataSelectEnd, calls execute_choice)
#
# Provide a list of options to handle duplicate file/directory names
#--------------------------------------------------------------------
proc handle_duplicate {duplicate_name} {
   global mount_point source_dir choice 

   toplevel .dup
   wm title .dup "ACTION REQUIRED"
   wm geometry .dup +360+320
   grab .dup
   frame .dup.top
   frame .dup.bottom
   pack .dup.top -side top
   pack .dup.bottom -side bottom

   frame .dup.top.left 
   frame .dup.top.right
   pack .dup.top.left -side left
   pack .dup.top.right -side right

   label .dup.top.left.label -text "Duplicate name detected for $duplicate_name"
   pack .dup.top.left.label 

   # set the default option for handling duplicates
   set choice skip
   foreach selection {skip overwrite rename} {
	radiobutton .dup.top.right.$selection -text $selection \
	   -variable choice \
	   -value $selection
	pack .dup.top.right.$selection -anchor w -side top
   }
   button .dup.bottom.ok -text OK -command "execute_choice $duplicate_name"
   pack .dup.bottom.ok -side bottom
}

#--------------------------------------------------------------------
# proc execute_choice (called by handle_duplicate, calls overwrite_item,
# skip_item or rename_item)
#
# Executes procedure corresponding to choice selected in handle_duplicate
#--------------------------------------------------------------------
proc execute_choice {duplicate_name} {
   global choice

   if { [winfo exists .dup] } { destroy .dup } 
   ${choice}_item $duplicate_name
}

#--------------------------------------------------------------------
# proc overwrite_item (called by handle_duplicate)
#
# If item is to be overwritten on destination, the item is added to
# the destination list (if it exists).
#--------------------------------------------------------------------
proc overwrite_item {duplicate_name} {
   global dest_list

   if ![info exists dest_list] {
	set dest_list $duplicate_name
   }

   refresh_selections
}

#--------------------------------------------------------------------
# proc rename_item (called by handle_duplicate)
#
# Rename file/directory name on destination directory 
#--------------------------------------------------------------------
proc rename_item {duplicate_name} {
   global mount_point source_dir source_list dest_dir dest_list prompt

   if ![info exists dest_list] {
	set dest_list $source_list
   }

   #
   # Verify that the new file name does not already exist
   #
   set true 1
   while {$true} {
	set new_name \
	[enter_val "Enter a new name for $duplicate_name" not_pw 20 "RENAME SELECTION"]
	if { $prompt(ok) } {
	   # Ok button clicked
	   if  ![string compare $new_name ""] {
	      dialog "You must enter a valid name"
	      continue
	   }
	} else {
	   # cancel button clicked
	   skip_item $duplicate_name
	   return
	}
	set i [ file exists $source_dir/$new_name ] 
	if { $i } {
	   dialog "$new_name already exists on $source_dir"
	   continue
	}
	set i [ file exists $dest_dir/$new_name ] 
	if { $i } {
	   dialog "$new_name already exists on $dest_dir"
	   continue
	}
	set i [lsearch -exact $dest_list $new_name]
	if { $i >= 0 } {
	   dialog "$new_name has already been used to rename an item"
	   continue
	}
	break
   }

   #
   # Determine the element to change
   #
   set i [lsearch -exact $source_list $duplicate_name]
   set dest_list [lreplace $dest_list $i $i $new_name]
   unset new_name
   refresh_selections
}

#--------------------------------------------------------------------
# proc skip_item (called by  handle_duplicate)
#
# Remove a duplicate file/directory name from the source list
#--------------------------------------------------------------------
proc skip_item {duplicate_name} {
   global mount_point source_list dest_list 

   if ![info exists dest_list] {
        set dest_list $source_list
   }

   #puts stdout "Removing $duplicate_name from $mount_point list"
   set i [lsearch -exact $source_list $duplicate_name]
   set source_list [lreplace $source_list $i $i] 

   #
   # Remove the corresponding element from the destination list (if it exists)
   #
   if [info exists dest_list] {
	set dest_list [lreplace $dest_list $i $i]
   }

   refresh_selections
}

#--------------------------------------------------------------------
# proc refresh_selections
#
# updates the selection list as it changes
#--------------------------------------------------------------------
proc refresh_selections { } {
   global top source_list dest_list

   $top.right.list delete 0 end

   if [info exists dest_list] {
	set which_list $dest_list
   } else {
	set which_list $source_list
   }

   foreach item $which_list {
	$top.right.list insert end $item
   }	
}

#--------------------------------------------------------------------
# proc prep_data
#
# Prepare everything in source list for copy to its destination
#--------------------------------------------------------------------
proc prep_data { } {
   global mount_point source_dir source_list dest_dir dest_list done
   global platform

   if ![info exists source_list] {
	dialog "No files selected, exiting data manager."
	return
   }

   if { [llength $source_list] == 0 } {
	dialog "No files selected, exiting data manager."
	return
   }

   wl_PanelsWait .waitwindow "Copying Files..."
   update

   if ![info exists dest_list] {
      	foreach source_name $source_list {
	   cd $source_dir
	   set status_code [copy_files $source_name]
		if {$status_code} {
		   dialog "copy of $source_name to $dest_dir failed."
		} else {
		   #puts "copy of $source_name to $dest_dir succeeded."
		}
         }
   } else {
      # there must be the same number of elements in both lists
      if { [llength $source_list] == [llength $dest_list] } {
	foreach dest_name $dest_list {
	   if [file exists $dest_dir/$dest_name] { 
		#puts stdout "removing $dest_dir/$dest_name before write"
	 	if ![ string compare $platform "windows" ] {
		   set status_code \
			[ catch {file delete -force $dest_dir/$dest_name} ]
		} else {
		   set status_code [ catch {exec rm -rf $dest_dir/$dest_name} ]
		}
	   if { $status_code } {
		dialog "Failed remove $dest_dir/$dest_name"
	   }
	   }
	}
   	set i 0
	foreach source_name $source_list {
	cd $source_dir

	#
	# Get the corresponding name in the destination name list
	#
	set dest_name [lindex $dest_list $i]

	   if ![string compare $source_name $dest_name] { 
		set status_code [copy_files $source_name]
           } else {
		set status_code [copy_files $source_name $dest_name]
	   }

	if {$status_code} {
	   dialog "copy of $source_name to $dest_name failed."
	} else {
	   #puts stdout "copy of $source_name to $dest_name succeeded."
	}
	incr i
	}
	unset dest_list
      }
   }
   if [winfo exists .waitwindow] { destroy .waitwindow }
   unset source_list
}

#--------------------------------------------------------------------
# proc copy_files
#
# Copies source to destination
#--------------------------------------------------------------------
proc copy_files { from_name {to_name DEFAULT_TARGET} } {
global mount_point source_dir dest_dir platform

   cd $source_dir

   if ![string compare $to_name DEFAULT_TARGET] {
     if ![ string compare $platform "windows" ] {
	set status_code [catch {file copy $from_name $dest_dir}]
     } else {
   	set status_code [catch {exec cp -Rf $from_name $dest_dir}]
     }

   } else {
     if ![ string compare $platform "windows" ] {
	set status_code [catch {file copy $from_name $dest_dir/$to_name}] 
     } else {
	set status_code [catch {exec cp -Rf $from_name $dest_dir/$to_name}] 
     }

   }

   if {$status_code == 0} {
	if ![string compare $to_name "DEFAULT_TARGET"] {
	   set to_name $from_name
	}
	set source_size [directory_size $source_dir/$from_name]
	set dest_size [directory_size $dest_dir/$to_name] 
	set status_code [string compare "$source_size" "$dest_size"] 
   }

   return $status_code
}

#--------------------------------------------------------------------
# proc cancel_data
#
# unsets variables upon exit
#--------------------------------------------------------------------
proc cancel_data { } {
global option_list source_list dest_list

   foreach list {option source dest} {
	if [info exists ${list}_list] {
	   unset ${list}_list
	}
   }

   if [winfo exists .dm] { destroy .dm }
}

#--------------------------------------------------------------------
# proc directory_size
#
# calculates the size of a directory including subdirectories
#--------------------------------------------------------------------
proc directory_size {directory_path} {

   set CWD [pwd]
   set size 0

   if [ file isdirectory $directory_path ] {
	cd $directory_path
   } else {
	puts "Not a directory:  $directory_path"
	return
   }

   set file_list [glob -nocomplain *]
   if [string compare $file_list ""] {

	foreach filename $file_list {

	   set file_type [file type $directory_path/$filename]

	   switch $file_type {
		directory {
		   set size [expr $size + \
			[directory_size $directory_path/$filename]]
		}
		file {
		   set size [expr $size + \
			[file size $directory_path/$filename]]
		}
	   }

   	}
   }

   cd $directory_path

   cd $CWD; unset CWD
   # size returned is in bytes
   return $size
}

#--------------------------------------------------------------------
# proc set_drive_letter
#
#--------------------------------------------------------------------
proc set_drive_letter { } {

   global drive_list

   set volume_list [file volume]

   foreach d $volume_list {

	if [string compare $d "c:/"] {
	   lappend drive_list [string trim $d /]
	}
   }
   if {[catch {set drive [ListBox .letter $drive_list]} res]} {
	set drive ""
	}
   unset drive_list
   return $drive
}
