# AdaptiveOptics
Un-twinkling the stars, and enabling super-human vision.

Adaptive Optics are systems that correct time-varying distortions in a telescope image that are caused by atmospheric turbulence.  They are also used to correct distortions caused by the lens of the eye in microscopes that study human vision.

My research at Bell Labs included design and fabrication of devices for adaptive optics (incl. US Patents #6,639,710 and #7,126,742) and the assembly of a laboratory adaptive optics system that operated these devices (e.g. Kurczynski et al. 2005, Optics Express).

The software included here consists of the closed-loop control system (in Tcl/Tk), mathematical stability analysis code (written in C with a C++ programming style) and a wavefront simulation GUI written in C++.  The stability analysis code is generic C and can be compiled and executed on any operating system.  The other projects have specific hardware and operating system dependencies.



