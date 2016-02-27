# AdaptiveOptics
Un-twinkling the stars, and enabling super-human vision.

Adaptive Optics are systems that correct time-varying distortions in a telescope image that are caused by atmospheric turbulence.  They are also used to correct distortions caused by the lens of the eye in microscopes that study human vision, see e.g. [Kurczynski et al. 2001, Proc. of SPIE 4561 147](http://dx.doi.org/10.1117/12.443108).

As a post doc at Bell Labs, I designed and fabricated devices for adaptive optics (incl. US Patents #6,639,710 and #7,126,742) and  assembled a laboratory adaptive optics system that operated these devices, see e.g. [Kurczynski et al. 2006, Optics Express 14 509](https://www.osapublishing.org/oe/abstract.cfm?uri=oe-14-2-509&origin=search).

The software included here consists of the closed-loop control system (in Tcl/Tk), mathematical stability analysis code (in C) and a wavefront simulation GUI (in C++).  The stability analysis code is generic C and can be compiled and executed on any operating system.  The other projects have specific hardware and operating system dependencies.



