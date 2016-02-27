//---------------------------------------------------------------------------
// Eigenfunc.h
//
//
// plk 03/07/2005
//---------------------------------------------------------------------------
#ifndef EIGENFUNC_H
#define EIGENFUNC_H



void Eigenfunc(int inJIndex,\
               double inR_MKS, \
               double inPhi_Rad, \
               double *outMagn_MKS, \
               double *outPhase_Rad);


void ComputeEigenProductMatrix();
double EPMatrixElement(int inJRow, int inJCol);
double EPIntegrandRF(double inR_MKS);

void PrintEigenfuncR(int inIndex, \
                     double inRL, \
                     double inRH, \
                     double inPhi, \
                     int inNum);

void SaveEigenfuncR(int inIndex, \
                     double inRL, \
                     double inRH, \
                     double inPhi, \
                     int inNum);

#endif

 