//----------------------------------------------------------------------------
// ZOffsetZernikePolynomial.h               C++ class implementation file
//
// Implements a ZernikePolynomial that has been shifted up or down,
// so that it no longer has zero mean value.
//
// plk 5/3/2003
//----------------------------------------------------------------------------
#include "ZOffsetZernikePolynomial.h"

//----------------------------------------------------------------------------
// ZOffsetZernikePolynomial()
//
// default constructor.
//
// called by:
//----------------------------------------------------------------------------
ZOffsetZernikePolynomial::ZOffsetZernikePolynomial()
{
   ZOffset_um = 0;

}

ZOffsetZernikePolynomial::~ZOffsetZernikePolynomial()
{

}

//----------------------------------------------------------------------------
// Evaluate()
//
// Over-rides the ZernikePolynomial Evaluate method.  Incorporates the
// vertical offset into the ZernikePolynomial.
//
// called by: AberratedWavefront::ComputeExteriorPatchFunctions()
//----------------------------------------------------------------------------
double ZOffsetZernikePolynomial::Evaluate(const double inR)
{
   double theOutputValue_um;

   theOutputValue_um = ZernikePolynomial::Evaluate(inR);

   theOutputValue_um += ZOffset_um;

   return theOutputValue_um;

}




//----------------------------------------------------------------------------
// Evaluate()
//
// Over-rides the ZernikePolynomial Evaluate method.  Incorporates the
// vertical offset into the ZernikePolynomial.
//
// called by: AberratedWavefront::ConstructExteriorExpansion()
//----------------------------------------------------------------------------
double ZOffsetZernikePolynomial::Evaluate(const double inR,
                                          const double inTheta)
{
   double theOutputValue_um;

   theOutputValue_um = ZernikePolynomial::Evaluate(inR,inTheta);

   theOutputValue_um += ZOffset_um;

   return theOutputValue_um;

}
