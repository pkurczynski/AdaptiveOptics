 if {[catch {package require Scrolledframe}]} \
     {
 	source [file join [file dirname [info script]] scrolledframe.tcl]
 	package require Scrolledframe
     }
 namespace import ::scrolledframe::scrolledframe
 scrolledframe .sf -height 150 -width 100 \
     -xscroll {.hs set} -yscroll {.vs set}
 scrollbar .vs -command {.sf yview}
 scrollbar .hs -command {.sf xview} -orient horizontal
 grid .sf -row 0 -column 0 -sticky nsew
 grid .vs -row 0 -column 1 -sticky ns
 grid .hs -row 1 -column 0 -sticky ew
 grid rowconfigure . 0 -weight 1
 grid columnconfigure . 0 -weight 1
 set f .sf.scrolled
 foreach i {0 1 2 3 4 5 6 7 8 9} \
     {
 	label $f.l$i -text "Hi! I'm the scrolled label $i" -relief groove
 	pack $f.l$i -padx 10 -pady 2
     }