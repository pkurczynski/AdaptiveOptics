//----------------------------------------------------------------------------
// ZShifedZernikePolynomial.h               C++ class implementation file
//
// Implements a ZernikePolynomial that has been shifted up or down,
// so that it no longer has zero mean value.
//
// plk 5/3/2003
//----------------------------------------------------------------------------
#include "ZernikePolynomial.h"
#include "ZShiftedZernikePolynomial.h"

//----------------------------------------------------------------------------
// ZShiftedZernikePolynomial()
//
// default constructor.
//
// called by:
//----------------------------------------------------------------------------
ZShiftedZernikePolynomial::ZShiftedZernikePolynomial()
{
   ZShift_um = 0;

}

