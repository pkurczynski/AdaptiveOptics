# StabilityAnalysis

Mathematical analysis of the stability of a membrane deformable mirror device.

Membrane deformable mirrors with a top, transparent electrode have a limited range of stability.  Beyond a certain threhold operating voltage, the membrane would snap down to its control electrode and stop functioning.

To understand this behavior, we modeled the device analytically and implemented the resulting equations for a variety of numerical simulations.  Our approach was to formulate an expression for the electrostatic energy of the system in terms of the membrane deformation.  We use a variational approach to determine the equilibrium deformation and analyze its stability.  This required decomposing the membrane deformation into an expansion of eigenfunctions, and also diagonalizing a stability tensor.  Stable device opeartion then imposes requirements on the associated eigenvalues.  Details are found in Kurczynski et al. 2005 Applied Optics.  

We implemented the equations in a C/C++ program to study the behavior of various design configurations.  The main program is SAValidate.c.  The other .c files in the /src folder perform various functions involved in the stability analysis.  This code is just hard-core numerical analysis, with a command line interface.   It is written in C, but with a C++ programming style.
