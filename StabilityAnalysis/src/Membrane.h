//---------------------------------------------------------------------------
// Membrane.h
//
// version 2
// plk 05/12/2005
//---------------------------------------------------------------------------
#ifndef MEMBRANE_H
#define MEMBRANE_H


void Membrane();
void InitMembraneShapeCoeffs();
void ResetMembraneShapeCoeffs();
void SetMembraneShape_BesselJZero();
void SetMembraneShape_BesselJOne();
void SetMembraneShape_BesselJTwo();
void SetMembraneShape_BesselJThree();
void SetMembraneShape_Eigenfunc();
double ParabolicDeformation_MKS(double inR_MKS, double inArbitraryPhi);
double ExpansionInEFuncsDeformation_MKS(double inR_MKS, double inPhi_rad);
double Del2Expansion_MKS(double inR_MKS, double inPhi_Rad);
void TestMembraneExpansion(double inRL,double inRH, double inNum);
void TestMembraneShapeAtSelectedElectrodes();

#endif