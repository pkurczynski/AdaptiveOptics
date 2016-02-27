# StabilityAnalysis

Mathematical analysis of the stability of a membrane deformable mirror device.

Membrane deformable mirrors with a top, transparent electrode have a limited range of stability.  Beyond a threhold operating voltage, the membrane snaps down to a control electrode and stops functioning.

To understand this behavior, we modeled a device analytically and implemented the resulting equations for a variety of numerical simulations.  We formulated an expression for the electrostatic energy of the system in terms of the membrane deformation, and used variational principles to determine the equilibrium deformation and analyze its stability.  This required decomposing the membrane deformation into an expansion of eigenfunctions, and also diagonalizing a stability tensor.  Stable device operation imposed requirements on the associated eigenvalues that translated into allowed ranges of physical device dimensions and operating voltages.  Details are found in Kurczynski et al. 2005 Applied Optics.  

We implemented the equations in a C/C++ program to study the behavior of various design configurations.  The main program is SAValidate.c.  The other .c files in the /src folder are dependencies.  This program consists solely of numerical analysis and has a simple, command line interface.   It is written in C with a C++ programming style.
