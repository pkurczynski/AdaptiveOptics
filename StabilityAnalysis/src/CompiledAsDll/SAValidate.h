//---------------------------------------------------------------------------
// SAValidate.h
//
// Computes Omega Matrix and its eigenvalues & eigenvectors to determine
// the stability of a particular membrane configuration.  See Formal
// Stability Calculation write-up.
//
// plk 03/16/2005
//---------------------------------------------------------------------------
#ifndef SAVALIDATE_H
#define SAVALIDATE_H


void TestSmallAmplitudeStability(float inVaLow_V, \
                                 float inVaHigh_V, \
                                 float inVtLow_V, \
                                 float inVtHigh_V,
                                 int   inNumGridPoints);

                                 
int Ping();
int Createdevice();

float GetDeviceStability();
void RunStabilityComputation();
void RunFastStabilityComputation();
void TestStabilityMatrixEigenvectors();
void TestMatrixAComputation();
void TestMembraneEigenfunctions();

void DoPeakDefVariationExpt(double inL_um, double inH_um, double inStep_um);



#endif

