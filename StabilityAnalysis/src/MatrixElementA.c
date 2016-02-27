//---------------------------------------------------------------------------
// MatrixElementA.c                                  C Program file
//
// methods for a MatrixElementA class implementation.
//
// called by:
// plk 03/08/2005
//---------------------------------------------------------------------------
#include "MatrixElementA.h"
#include "BesselJZeros.h"
#include "Eigenfunc.h"
#include "Membrane.h"
#include "NR.h"



//---------------------------------------------------------------------------
// RealMatrixElementA
//
// Use this
// called by: ComputeOmegaMatrix
// plk 03/07/2005
//---------------------------------------------------------------------------
//double RealMatrixElementA(int inJRow, int inJCol)
double RealMatrixElementA()
{
   double theReturnValue;
   theReturnValue = 1.0;
#if 0
   int theRowVIndex;
   int theColVIndex;

   double theRFactor;
   double thePhiFactor;
   double theMagn;
   double thePhase;
   double PI = 3.1415926535;

   double (*theFunc)(double);

   // set variables, function pointer for NR integration
   // routine (used to evaluate radial integral).
   theFunc = AIntegrandRF;
   gMatrixAActiveRow = inJRow;
   gMatrixAActiveCol = inJCol;

   // set v indices for use in phi integration.
   theRowVIndex = BesselVIndex(inJRow);
   theColVIndex = BesselVIndex(inJCol);

   // Assuming Weight function is independent of phi, then the
   // angular integration is computed analytically.  Because of
   // orthogonality of the angular functions, matrix elements
   // with v_row != v_column are zero.
   if (theRowVIndex == theColVIndex)
        thePhiFactor = 2*PI;
   else
   {
        thePhiFactor = 0.0;
        theMagn = 0.0;
        return theMagn;
   }

   //DEBUG
   //dump(theFunc,0,gMembraneRadius_mm,10);

   theRFactor=0;
   // Perform radial integration using NR routine...Romberg integration.
   //theRFactor = qromb(theFunc,0,gMembraneRadius_mm);

   // for the case of azimuthally symmetric weight function, the
   // matrix element is a real number.
   theMagn = theRFactor * thePhiFactor;
   thePhase = 0;

   return theMagn;
#endif
   return theReturnValue;
}



//---------------------------------------------------------------------------
// AIntegrandRF
//
// Computes the radial factor of the integrand of the matrix element "A."
// calculations. This function assumes that the weight function is
// independent of the phi coordinate, and therefore the integral is
// only over the radial coordinate.  This function will be called by
// the 1D-integration routine to compute the radial integral
// of the matrix element.
//
// arguments:  inR    the current value of the radial coordinate
//
// uses global variables:
//
//             gMatrixAActiveRow   the row index of the current matrix element
//             gMatrixAActiveCol   the col index of the current matrix element
//
// called by:  MatrixElementA (implicitly, through NR integration routine).
//
// plk 03/07/2005
//---------------------------------------------------------------------------
double AIntegrandRF(double inR)
{


   double theRowEigenMagn;
   double theRowEigenPhase;

   double theColEigenMagn;
   double theColEigenPhase;

   double theEigenProduct;
   double theAIntegrandRF;
   double theArbitraryPhi;

   // compute magnitude, phase of each eigenfunction at the current
   // r coordinate.  Because only the magnitudes are used in this
   // function, the input phi value is arbitrary.
   theArbitraryPhi=0;
   Eigenfunc(gMatrixAActiveRow, \
             inR, \
             theArbitraryPhi, \
             &theRowEigenMagn, \
             &theRowEigenPhase);

   Eigenfunc(gMatrixAActiveCol, \
             inR, \
             theArbitraryPhi, \
             &theColEigenMagn, \
             &theColEigenPhase);

   theEigenProduct = theRowEigenMagn*theColEigenMagn;


   theAIntegrandRF = WeightFn(inR)*theEigenProduct;

   return theAIntegrandRF;

}


//---------------------------------------------------------------------------
// dump
//
// DEBUG function.  Prints several values of the function specified
// by the function pointer argument, within the specified range of
// the independent variable [inRL,inRH], inNum sample points.
//
// called by: RealMatrixElementA
//
// plk 03/08/2005
//---------------------------------------------------------------------------

void dump(double (*inFunc)(double),double inRL,double inRH, double inNum)
{

   double theR;
   double theDR;
   double theMagn;
   double thePhase;

   theDR=(inRH-inRL)/inNum;

   //printf("Eigenfunction %d\n",inIndex);
   //printf("Phi=%f\n",inPhi);
   //printf("r\t\tmagn\t\tphase\n");
   for (theR=inRL; theR<=inRH; theR+=theDR)
   {
        theMagn = (*inFunc)(theR);
        printf("%f\t%f\n",theR,theMagn);
   }
   printf("\n\n");
   
}

//---------------------------------------------------------------------------
// WeightFn
//
// Computes a weight function for the product of eigenfunctions in the
// matrix element computation.
//
// called by:  AIntegrandRF
//
// plk 3/8/2005
//---------------------------------------------------------------------------
double WeightFn(double inR)
{
  return 1.0;
}

