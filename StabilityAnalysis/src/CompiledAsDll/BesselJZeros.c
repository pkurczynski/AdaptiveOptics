#include "BesselJZeros.h"
#include "NR.h"

//---------------------------------------------------------------------------
// BesselJIndex
//
// returns the "J" index value for a given Bessel function order, v,
// and zero number, n.  J index is 0...53 for 54 Bessel function zeros.
//
// plk 3/7/2005
//---------------------------------------------------------------------------
int BesselJIndex(int inV, int inN)
{
   return 9*inV+inN-1;
}


int BesselVIndex(int inJ)
{
   return BesselJZerosLookUp[inJ][1];
}

int BesselNIndex(int inJ)
{
   return BesselJZerosLookUp[inJ][2];
}


//---------------------------------------------------------------------------
// BesselJZero
//
// returns the zero corresponding to the Bessel "J" index; "J" index
// combines both the Bessel function order, v, and the zero number, n.
// See BesselJIndex() for details.
//
// plk 3/7/2005
//---------------------------------------------------------------------------
float BesselJZero(int inJ)
{
   return BesselJZerosLookUp[inJ][3];
}


float BesselJn(int inIndex, float inR)
{
  float theReal;

  switch (inIndex)
     {
       case 0:
           theReal = bessj0( (float)inR);
           break;

       case 1:
           theReal = bessj1( (float)inR);
           break;

       default:
           theReal = bessj(inIndex,(float) inR);
           break;
     }

  return theReal;
}

