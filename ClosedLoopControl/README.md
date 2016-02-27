# ClosedLoopControl

Software to control an adaptive system in closed loop.  

To operate an adaptive optics system, control software must receive and interpret signals from a wavefront sensor and use this information to command the deformable mirror to flatten the optical wavefront.  Our system operated at about 15 Hz, meaning that the optical wavefront was adjusted with this frequency.

The control software was written in Tcl/Tk, starting from the wavefront sensor control software (an open loop, GUI-based system).  Substantial code was built on this foundation.  The deformable mirror was commanded by custom D/A conversion boards that were built on a VME electronics standard.  The control software commanded these VME boards, which delivered voltages to the deformable mirror.  The hardware and the control algorithm are described in Kurczynski et al. 2005 Applied Optics.