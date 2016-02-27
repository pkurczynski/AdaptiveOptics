# StabilityAnalysis

C code that simulates operation of a deformable mirror for adaptive optics.

I designed and fabricated this device (US Patent #6,639,710) while a post-doc at Bell Labs.  The hardware is described in Kurczynski et al. 2005, Optics Express.  


While operating the device, we encountered problems due to instability:  When operated at moderate voltage, the membrane mirror would snap down to either electrode.  We investigated this behavior using electrostatics and the calculus of variations; the math is worked out in Kurczynski et al. 2005 Applied Optics.  We implemented the equations in a C/C++ program to study the behavior of various design configurations.


The main program is SAValidate.c.  The other .c files in the /src folder perform various functions involved in the stability analysis.  This code is just hard-core numerical analysis, with a command line interface.   It is written in C, but with a C++ programming style.