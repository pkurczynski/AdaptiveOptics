#*****************************************************************************
#*****************************************************************************
proc showrects { rects id } \
{
    upvar $rects rec
    upvar $id idd

    id.clr.over.array idd

    moverects rec over

    id.set.over.coords idd 1
    id.set.over.width idd 0.1
    id.set.over.color idd 0.0 1.0 0.0
    id.set.over.array idd over
}

#*****************************************************************************
# id.set.rect.array is used to determine the rectangles for the spot array
#*****************************************************************************
proc id.set.rect.array { args  } \
{
    set num_args [ llength $args ]

    if { $num_args != 2 } {
	id.set.rect.array.help
	return
    }
    upvar [lindex $args 1] rec
    upvar [lindex $args 0] idd
    
    id.clr.over.array idd
    
    moverects rec over
    
    id.set.over.coords idd 1
    id.set.over.width idd 0.1
    id.set.over.color idd 0.0 1.0 0.0
    id.set.over.array idd over
}	

#*****************************************************************************
# id.set.rect.array.help will display the usage of the id.set.rect.array
# function
#*****************************************************************************
proc id.set.rect.array.help { } { 
    puts " " 
    puts "id.set.rect.array ID PosArray"
    puts " " 
    puts "Sends a specific rect Array to image display window `ID'."
    puts ""
}

#*****************************************************************************
# id.set.color.rect.array displays rectangles in red for editing
#*****************************************************************************
proc id.set.color.rect.array { id rects red green blue } \
{
    upvar $rects rec
    upvar $id idd
    
    moverects rec over
    
    id.set.over.coords idd 1
    id.set.over.width idd 0.1
    id.set.over.color idd $red $green $blue
    id.set.over.array idd over
}

#*****************************************************************************
# id.set.pos.array is used to determine the positions of the subapertures 
#*****************************************************************************
proc id.set.pos.array { args } \
{
    set num_args [ llength $args ]
    
    if { $num_args != 2 } {
	id.set.pos.array.help
	return
    }
    
    upvar [lindex $args 1] cent
    upvar [lindex $args 0] idd
    
    id.clr.over.array idd

    makepos cent over
	
    id.set.over.coords idd 1
    id.set.over.width idd 0.1
    id.set.over.color idd 1.0 0.0 0.0
    id.set.over.array idd over
}

#*****************************************************************************
# id.set.pos.array.help will display the usage of the id.set.pos.array
# function
#*****************************************************************************
proc id.set.pos.array.help { } { 
    puts " " 
    puts "id.set.pos.array ID PosArray"
    puts " " 
    puts "Sends a specific pos Array to image display window `ID'."
    puts ""
}

#*****************************************************************************
# makepos re-orients the position values so they can be properly
# displayed using xd.set.over.array
#*****************************************************************************
proc makepos { centers over } \
{
    upvar $centers ccc
    upvar $over ooo
	
    a.v2toxy ccc = x y
    
    a.add x 3 = xpos
    a.sub x 3 = xneg
    a.add y 3 = ypos
    a.sub y 3 = yneg

    a.merge x yneg x ypos = c1
    a.merge xpos y xneg y = c2
    a.catcol c1 c2 = ooo
}

proc findrects { rects } \
{
    upvar $rects rrr
    
    fg.grab 1 = uuu
    alg.find.rects uuu = rrr
}

proc calib { minmax } \
{
    global trects params centers cid refpos

    set mins [expr int($minmax * 0.7)]
    set maxs [expr int($minmax * 1.4)]
    alg.rects.minmax.sep $mins $maxs
    fg.grab 1 = uuu
    a.sqrt uuu = uuuu
    alg.find.rects uuuu = trects
    a.v4tov2v2 trects = trr tss
    
    a.v2toxy tss = sx sy
    set spacing [a.ave sx]
    a.mul uuu -1 = vvv
    alg.find.params vvv $spacing = params

    alg.fit.spots uuu trects = refpos

    set ypacing [expr [a.ave sy] / 2.0]
    set xpacing [expr $spacing / 2.0]
	
    a.add trr "< $xpacing $ypacing>" = centers
    
    id.new cid
    id.set.array cid uuu
    showrects trects cid
}

proc dopd {} \
{
    global trects params refpos centers opd

    fg.grab 1 = uuu

    alg.fit.spots uuu trects = pos
    a.sub pos refpos = mots
    a.sub mots [a.ave mots] = mots
    a.v2v2tov4 centers mots = vects

    alg.conv.pg.arrays vects params = gxgy mask
    alg.recon.fast gxgy mask = opd
}

proc doit { n } \
{
    global trects params refpos centers opd

    calib 12
    id.new opid

    for { set i 0 } { $i < $n } { incr i } \
	{
	    dopd
	    id.set.array opid opd
	    puts [a.rms opd]
	}	
}

proc doitlite { n } \
{
    global trects params refpos centers opd

	
    id.new opid

    for { set i 0 } { $i < $n } { incr i } \
    {
	dopd
	id.set.array opid opd
    }
}

#*****************************************************************************
# stage.do is used to send the stage commands.  This routine is only for
# Windows NT
#*****************************************************************************
proc stage.do { str } \
{
    global ws_comp
    upvar $str string
    puts $ws_comp $str
    flush $ws_comp
    after 200
    read $ws_comp
}

#*****************************************************************************
# functions to cover commands that are used in the LINUX version
#*****************************************************************************
proc id.get.rect.array { id vvv } {}
proc wd.set.hide { wd uu } {}
proc wd.set.pers { wd uu } {}
proc wd.get.pers { wd eq cc } \
{
    upvar $cc col
    set col 1
}
proc wd.get.hide { wd eq cc } \
{
    upvar $cc col
    set col 1
}

