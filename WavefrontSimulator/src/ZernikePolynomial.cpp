//----------------------------------------------------------------------------
// ZernikePolynomial.cpp
//
// Implementation of the ZernikePolynomial class.  See ZernikePolynomial.h
//
// plk 4/23/2003
//----------------------------------------------------------------------------
#include "ZernikePolynomial.h"
#include <math.h>



//----------------------------------------------------------------------------
// ZernikePolynomial()
//
// creates a ZernikePolynomial.  By default the ZernikePolynomial is
// set to Z_0^0 = Z(j=0) = 1
//
// called by: AberratedWavefront::AberratedWavefront()
//
//-----------------------------------------------------------------------------
ZernikePolynomial::ZernikePolynomial()
{

   SetIndex(0);

}

//----------------------------------------------------------------------------
// ZernikePolynomial()
//
// creates a ZernikePolynomial.  Computes the radial coefficients,
// and populates the RadialPower array so that the class may be used
// to return the values of the specified ZernikePolynomial.
//
//      inIndex              the order of the ZernikePolynomial,
//                           following convention of Thibos et al.
//
// called by:
//
//-----------------------------------------------------------------------------
ZernikePolynomial::ZernikePolynomial(int inIndex)
{

   SetIndex(inIndex);

}


ZernikePolynomial::~ZernikePolynomial()
{

   // destroy the ZernikePolynomial object
}



//----------------------------------------------------------------------------
// ComputeRadialPolynomial()
//
// Populates the arrays containing coefficients and powers of the radial
// polynomial for the specified ZernikePolynomial.
//
// called by:  ZernikePolynomial::SetIndex()
//----------------------------------------------------------------------------
void ZernikePolynomial::ComputeRadialPolynomial()
{

   int n = RadialOrder;
   int m = abs(AzimuthalFrequency);

   // Populate the array of radial polynomials.  These are powers of r,
   // with degree: n, n-2, n-4, ... n-m.  Radial powers are defined as ZERO
   // if the degree of the polynomial is outside of the relevant range
   // for the current ZernikePolynomial
   //
   // this section of code implements the factor with 'r' in the summand of
   // Eq. 2 in R.J. Noll's paper.
   NumberOfRadialTerms=0;
   for (int s=0;s<MAXPOLYNOMIALDEGREE;s++)
   {
        if ( s<= (n-m)/2 )
        {
           RadialPower[s]=n-2*s;
           NumberOfRadialTerms++;
        }
        else
           RadialPower[s]=0;
   }



   // Populate the Radial coefficient array for the ZernikePolynomial.
   // Radial coefficients are products of factorials. Coefficients outside
   // the range of the sum indicated in Eq. 2 of R. J. Noll's paper are
   // set to ZERO
   //
   // This section of code implements the summand, excluding the 'r' factor,
   // in Eq. 2 of R. J. Noll's paper
   double theD;
   for (int s=0;s<MAXPOLYNOMIALDEGREE;s++)
   {
        if (s <= (n-m)/2 )
        {
           theD=factorial(s)*factorial( (n+m)/2 - s )*factorial( (n-m)/2 - s );
           RadialCoefficient[s] = pow(-1,s)*factorial( n-s ) / theD;
        }
        else RadialCoefficient[s]=0;
   }

}



//----------------------------------------------------------------------------
// SetIndex()
//
// Sets the index of a ZernikePolynomial.  Also sets dependent
// quantities: RadialOrder, AzimuthalFrequency, Normalization
//
// called by:
//      ZernikePolynomial()
//
//-----------------------------------------------------------------------------
void ZernikePolynomial::SetIndex(int inIndex)
{
   Index = inIndex;

   // compute n,m from equs. 5, 6 of Thibos paper
   RadialOrder = ceil( (-3 + sqrt(9 + 8 * Index) )/ 2 );
   AzimuthalFrequency = 2 * Index - RadialOrder*(RadialOrder + 2);



   // Normalization convention of Thibos et al. See Equ. 3.
   // This is the same normalization convention as in the
   // paper by Noll, see Eq. 1 of the paper by Noll for comparison.
   if (AzimuthalFrequency == 0)
        Normalization = sqrt( RadialOrder+1 );
   else
        Normalization = sqrt( 2 * (RadialOrder+1) );
   
   //Compute the radial polynomial for the new index.  Afterwards,
   //the Zernike polynomial is ready for use.
   ComputeRadialPolynomial();
}


//-----------------------------------------------------------------------------
// factorial()
//
// returns the factorial of a specified integer.
//
// called by: ZernikePolynomial::ComputeRadialPolynomial()
//-----------------------------------------------------------------------------
long ZernikePolynomial::factorial(long inX)
{
   long result;


   switch (inX)
   {
     case 0:
        result = 1;
        break;
     case 1:
        result = 1;
        break;
     default:
        result=inX;
        do
        {
           result*=(inX-1);
           inX--;
        } while (inX>1);
        break;
   }

   return result;
}


//----------------------------------------------------------------------------
// Evaluate()
//
//
// Evaluates only the radial factor, including Normalization and sign,
// of the specified ZernikePolynomial at a specified point.
//
//
// arguments:  inR      the radial coordinate, 0...1
//
// return value:
//             the value of the radial component of the ZernikePolynomial
//             at the specified r value
//
// called by:  AberratedWavefront::ComputeExteriorPatchFunctions()
//
//----------------------------------------------------------------------------
double ZernikePolynomial::Evaluate(const double inR)
{
   double theRadialFactor;

    // evaluate the sum in Eq. 2 of R. J. Noll's paper
   theRadialFactor=0;
   if (inR==0 && AzimuthalFrequency == 0)
   {
      // special case: cannot compute pow(0,0) below
      theRadialFactor = RadialCoefficient[NumberOfRadialTerms-1];
   }
   else if (inR==0 && AzimuthalFrequency != 0)
   {
      theRadialFactor = 0;
   }
   else
   {
      for (int i=0;i<NumberOfRadialTerms;i++)
      {
         theRadialFactor+=RadialCoefficient[i]*pow(inR,RadialPower[i]);
      }
   }

   double theSign;
   if (AzimuthalFrequency >= 0)
        theSign = 1;
   else
        theSign = -1;


   return theSign*Normalization*theRadialFactor;

}



//----------------------------------------------------------------------------
// Evaluate()
//
//
// Evaluates the specified ZernikePolynomial at a specified point.
//
// angular factor is determined from Eq. 1 of paper
// by Thibos et al.
//
// arguments:  inR      the radial coordinate, 0...1
//             inTheta  the angular coordinate in radians, 0...2PI
//
// return value:
//             the value of the ZernikePolynomial at the specified point
//
// called by:  AberratedWavefront::ConstructZernikeExpansion()
//
//----------------------------------------------------------------------------
double ZernikePolynomial::Evaluate(const double inR, const double inTheta)
{
   double theRadialFactor;
   double theAngularFactor;

   if ( AzimuthalFrequency > 0 )
   {
      theAngularFactor = cos( AzimuthalFrequency * inTheta );
   }
   else if ( AzimuthalFrequency < 0 )
   {
      theAngularFactor = sin( AzimuthalFrequency * inTheta );
   }
   else if ( AzimuthalFrequency == 0 )
   {
      theAngularFactor = 1;
   }


    // evaluate the sum in Eq. 2 of R. J. Noll's paper
   theRadialFactor=0;
   if (inR==0 && AzimuthalFrequency == 0)
   {
      // special case: cannot compute pow(0,0) below
      theRadialFactor = RadialCoefficient[NumberOfRadialTerms-1];
   }
   else if (inR==0 && AzimuthalFrequency != 0)
   {
      theRadialFactor = 0;
   }
   else
   {
      for (int i=0;i<NumberOfRadialTerms;i++)
      {
         theRadialFactor+=RadialCoefficient[i]*pow(inR,RadialPower[i]);
      }
   }

   double theSign;
   if (AzimuthalFrequency >= 0)
        theSign = 1;
   else
        theSign = -1;


   return theSign*Normalization*theRadialFactor*theAngularFactor;

}


//----------------------------------------------------------------------------
// RadialDerivative()
//
//
// Evaluates the radial partial derivative of the ZernikePolynomial at a
// specified point.
//
//
// arguments:  inR      the radial coordinate, 0...1
//             inTheta  the angular coordinate in radians, 0...2PI
//
// return value:
//             ONLY the radial component of the radial derivative of the
//             ZernikePolynomial at the specified point
//
// called by:  AberratedWavefront::ComputeExteriorPatchFunctions()
//
//----------------------------------------------------------------------------
double ZernikePolynomial::RadialDerivative(const double inR)
{

   double theRadialFactor;

   // evaluate the derivative of the r polynomial using
   // elementary calculus.
   theRadialFactor=0;
   for (int i=0;i<NumberOfRadialTerms;i++)
   {
      if (RadialPower[i] > 1)
      {
         theRadialFactor+=RadialCoefficient[i]*RadialPower[i]*
                          pow(inR, RadialPower[i]-1 );
      }
      if (RadialPower[i] == 1)
        theRadialFactor+=RadialCoefficient[i];
   }

   return Normalization*theRadialFactor;

}


//----------------------------------------------------------------------------
// RadialDerivative()
//
//
// Evaluates the radial partial derivative of the ZernikePolynomial at a
// specified point.
//
//
// arguments:  inR      the radial coordinate, 0...1
//             inTheta  the angular coordinate in radians, 0...2PI
//
// return value:
//             the radial derivative of the ZernikePolynomial at the
//             specified point
//
// called by:
//
//----------------------------------------------------------------------------
double ZernikePolynomial::RadialDerivative(const double inR,
                                           const double inTheta)
{
   double theRadialFactor;
   double theAngularFactor;


   // same angular factor as the ZernikePolynomial itself
   if ( AzimuthalFrequency > 0 )
   {
      theAngularFactor = cos( AzimuthalFrequency * inTheta );
   }
   else if ( AzimuthalFrequency < 0 )
   {
      theAngularFactor = sin( AzimuthalFrequency * inTheta );
   }
   else if ( AzimuthalFrequency == 0 )
   {
      theAngularFactor = 1;
   }


   // evaluate the derivative of the r polynomial using
   // elementary calculus.
   theRadialFactor=0;
   for (int i=0;i<NumberOfRadialTerms;i++)
   {
      if (RadialPower[i] > 1)
      {
         theRadialFactor+=RadialCoefficient[i]*RadialPower[i]*
                          pow(inR, RadialPower[i]-1 );
      }
      if (RadialPower[i] == 1)
        theRadialFactor+=RadialCoefficient[i];

   }


   return Normalization*theRadialFactor*theAngularFactor;

}


