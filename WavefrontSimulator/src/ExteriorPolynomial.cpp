//----------------------------------------------------------------------------
// ExteriorPolynomial.cpp
//
// Implementation of the ExteriorPolynomial class.  See ExteriorPolynomial.h
//
// plk 4/23/2003
//----------------------------------------------------------------------------
#include "ExteriorPolynomial.h"
#include <math.h>



//----------------------------------------------------------------------------
// ExteriorPolynomial()
//
//
// called by:
//
//-----------------------------------------------------------------------------
ExteriorPolynomial::ExteriorPolynomial()
{
   NumberOfRadialTerms = MAXEXTERIORPOLYNOMIALDEGREE;

   for (int i=0;i<NumberOfRadialTerms;i++)
      RadialCoefficient[i] = 0;

   AzimuthalFrequency = 0;
}


ExteriorPolynomial::~ExteriorPolynomial()
{

}



//----------------------------------------------------------------------------
// SetCubicRadialPolynomial()
//
// computes the radial polynomial that connects the ZernikePolynomial
// to the outer radius of the exterior region, matching value
// and slope to the ZernikePolynomial at the inner boundary
// and zero value and slope at the outer boundary.
//
// called by:  AberratedWavefront::ComputeExteriorPatchFunctions()
//----------------------------------------------------------------------------
void ExteriorPolynomial::SetCubicRadialPolynomial(double inValueAtInnerRadius,
                                             double inDerivativeAtInnerRadius,
                                             double inOuterRadius)
{
   NumberOfRadialTerms = 4;

   double P, Q;              // factors in calculation of exterior poly.
   double A, B, C, D;        // coefficients of exterior polynomial
   double R, R2, R3, Denom;

   R = inOuterRadius;
   R2 = pow(R,2);
   R3 = pow(R,3);
   Denom = pow(-1+R,3);

   P = inValueAtInnerRadius;
   Q = inDerivativeAtInnerRadius;

   A = -1*(3*P*R2-Q*R2-P*R3+Q*R3)/Denom;
   B = -1*(-6*P*R+2*Q*R-Q*R2-Q*R3)/Denom;
   C = -1*(3*P-Q+3*P*R-Q*R+2*Q*R2)/Denom;
   D = -1*(-2*P+Q-Q*R)/Denom;

   RadialCoefficient[0] = A;
   RadialCoefficient[1] = B;
   RadialCoefficient[2] = C;
   RadialCoefficient[3] = D;


}


//----------------------------------------------------------------------------
// SetQuadraticRadialPolynomial()
//
// computes the radial polynomial that connects the ZernikePolynomial
// to the outer radius of the exterior region, matching value
// and slope to the ZernikePolynomial at the inner boundary
// and zero value and slope at the outer boundary.
//
// called by:  AberratedWavefront::ComputeExteriorPatchFunctions()
//----------------------------------------------------------------------------
void ExteriorPolynomial::SetQuadraticRadialPolynomial(
                                             double inValueAtInnerRadius,
                                             double inDerivativeAtInnerRadius,
                                             double inOuterRadius)
{

   NumberOfRadialTerms = 3;

   double P, Q;              // factors in calculation of exterior poly.
   double A, B, C;           // coefficients of exterior polynomial
   double R, R2, Denom;

   R = inOuterRadius;
   R2 = pow(R,2);
   Denom = pow(R-1,2);

   P = inValueAtInnerRadius;
   Q = inDerivativeAtInnerRadius;

   A = (P*R2 - Q*R2 - 2*P*R + Q*R)/Denom;
   B = (Q*R2 + 2*P - Q)/Denom;
   C = (-Q*R -P + Q)/Denom;

   RadialCoefficient[0] = A;
   RadialCoefficient[1] = B;
   RadialCoefficient[2] = C;

}


double ExteriorPolynomial::Evaluate(const double inR, const double inTheta)
{

   double theRadialFactor;
   double theAngularFactor;

   // ExteriorPolynomial has the same angular dependence as
   // its corresponding ZernikePolynomial
   if ( AzimuthalFrequency >= 0 )
   {
      theAngularFactor = cos( AzimuthalFrequency * inTheta );
   }
   else
   {
      theAngularFactor = sin( AzimuthalFrequency * inTheta );
   }

   // Radial dependence is a polynomial with coefficients
   // set previously.  Terms are of form:  RadialCoefficient[i]*r^i
   theRadialFactor = 0;
   for (int i=0;i<NumberOfRadialTerms;i++)
   {
      theRadialFactor+=RadialCoefficient[i]*pow(inR,i);
   }


   return theRadialFactor*theAngularFactor;

}

