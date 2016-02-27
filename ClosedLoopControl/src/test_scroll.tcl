# ==============================
#
# demo
#
# ==============================

toplevel .dm

 if {[catch {package require Scrolledframe}]} \
     {
 	source [file join [file dirname [info script]] scrolledframe.tcl]
 	package require Scrolledframe
	 namespace import ::scrolledframe::scrolledframe
     }
 scrolledframe .dm.sf -height 600 -width 600 \
     -xscroll {.dm.hs set} -yscroll {.dm.vs set} 
 scrollbar .dm.vs -command {.dm.sf yview}
 scrollbar .dm.hs -command {.dm.sf xview} -orient horizontal
 grid .dm.sf -row 0 -column 0 -sticky nsew
 grid .dm.vs -row 0 -column 1 -sticky ns
 grid .dm.hs -row 1 -column 0 -sticky ew
 grid rowconfigure .dm 0 -weight 1
 grid columnconfigure .dm 0 -weight 1
 set f .dm.sf.scrolled
  set ACT_LINE_LENGTH 37
  set ht 1
  set bd 1

  for { set y 0 } { $y < $ACT_LINE_LENGTH } { incr y } {
      frame $f.acts$y
      pack  $f.acts$y
      for { set x 0 } { $x < $ACT_LINE_LENGTH } { incr x } {
 	 puts stdout "$x $y"
  	set bnum [expr $y * $ACT_LINE_LENGTH + $x + 1]
  	checkbutton $f.acts$y.$bnum -textvariable "" -width 3 \
  	    -height $ht -bd $bd -variable selected($bnum) -command SetAct
  	#      checkbutton .f.acts$y.$bnum -textvariable acts($bnum) -width 3 \
  	    #          -height $ht -bd $bd -variable selected($bnum) -command SetAct
  	pack        $f.acts$y.$bnum -side left
      }
  }

# if {[catch {package require Scrolledframe}]} \
#     {
# 	source [file join [file dirname [info script]] scrolledframe.tcl]
# 	package require Scrolledframe
#     }
# namespace import ::scrolledframe::scrolledframe
# scrolledframe .sf -height 150 -width 100 \
#     -xscroll {.hs set} -yscroll {.vs set}
# scrollbar .vs -command {.sf yview}
# scrollbar .hs -command {.sf xview} -orient horizontal
# grid .sf -row 0 -column 0 -sticky nsew
# grid .vs -row 0 -column 1 -sticky ns
# grid .hs -row 1 -column 0 -sticky ew
# grid rowconfigure . 0 -weight 1
# grid columnconfigure . 0 -weight 1
# set f .sf.scrolled
# foreach i {0 1 2 3 4 5 6 7 8 9} \
#     {
# 	label $f.l$i -text "Hi! I'm the scrolled label $i" -relief groove
# 	pack $f.l$i -padx 10 -pady 2
#     }