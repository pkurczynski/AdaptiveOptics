# ClosedLoopControl

Software to control an adaptive system in closed loop.  

To operate an adaptive optics system, control software receives and interprets signals from a wavefront sensor and uses this information to command the deformable mirror to flatten the optical wavefront.  Our system updated the optical wavefront many times a second.

The control software was written in Tcl/Tk, starting from software provided by the wavefront sensor manufacturer (an open loop, GUI-based system).  Substantial code was built on this foundation.  The deformable mirror was commanded by custom D/A conversion boards that were built on a VME electronics standard.  The control software commanded these VME boards, which delivered voltages to the deformable mirror.  For more information, see [Kurczynski et al. 2005, Proc. SPIE 5719 155](http://dx.doi.org/10.1117/12.593234).
