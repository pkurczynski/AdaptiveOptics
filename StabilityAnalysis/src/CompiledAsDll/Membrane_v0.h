//---------------------------------------------------------------------------
// Membrane.h
//
//
// plk 03/07/2005
//---------------------------------------------------------------------------
#ifndef MEMBRANE_H
#define MEMBRANE_H


double gMembraneStress_MPa    = 3.0;
double gMembraneThickness_um  = 1.0;
double gMembraneTension_NByM  = 3.0;      // tension = stress * thickness
double gMembraneRadius_mm     = 7.5;


double gVoltageT_V             = 10.0;    // Transp. electrode voltage
double gVoltageA_V             = 10.0;    // Array electrode voltage
double gDistT_um               = 30.0;    // Transp. electr -- membr. dist.
double gDistA_um               = 30.0;    // Electr. array -- membr. dist.

double gPeakDeformation_um     =  0.0;

double ParabolicDeformation_MKS(double inR_MKS);

#endif