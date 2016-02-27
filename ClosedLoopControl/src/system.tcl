proc timezone { } {

    global LISTS_DIR ws_stat
    source $LISTS_DIR/Time_list.tcl
    set tzone [ListBox .timezone $Time_list "Selected Timezone: " tz]

	if { $tzone } {
	   puts $ws_stat(tz)
	   exec /usr/local/bin/tz $ws_stat(tz)
	} else {
	   puts "no timezone selected"
	}
}


proc format_jaz { } {

   set hostname [exec /bin/hostname]
   switch $hostname {
	amber {
	   set jaz_device sdb
	}
	default {
	   set jaz_device sda
	}
   }
   puts stdout "$jaz_device"

   set format_script /tmp/formatjaz
   set output [open $format_script w 0755]

   if ![catch {eval exec jaztool /dev/$jaz_device status}] {

      set partition_table [exec jazinfo]

      # instructions to remove any/all partitions (Tools disk has none)
      puts $output "#!/bin/sh"
      puts $output "${jaz_device}fdisk << _END_FDISK_"
      if [string compare $partition_table ""] {
      	foreach partition [split $partition_table] {
	   puts $output "d"
	   puts $output "[string range $partition 8 8]" 
      	}
      }

      # instructions to create a partition on the Jaz cartridge
      puts $output "n"
      puts $output "p"
      puts $output "4"
      puts $output "1"
      puts $output "1021"
      puts $output "t"
      puts $output "4"
      puts $output "6"
      puts $output "w"
      puts $output "_END_FDISK_"

      close $output

      if ![string compare [wl_PanelsYesNo "Continue with Format"] Yes] {
	# execute the script generated and create a filesyste on cartridge
	wl_PanelsWait .waitwindow "Formatting..."
	update

	exec sh $format_script
	exec rm $format_script

	if [catch {eval exec mformat j:}] {
	   if [winfo exists .waitwindow] { destroy .waitwindow }
	   dialog "Format Failed"
	   return
        } else { 
  	   if [winfo exists .waitwindow] { destroy .waitwindow }
	}

      } else {
	dialog "Formatting Cancelled"
      }

   } else {
      dialog "No Jaz cartridge loaded"
   }
}

