//---------------------------------------------------------------------------
// ElectrodeArray.c
//
//
//---------------------------------------------------------------------------
#include "ElectrodeArray_v1.h"
#include "MatrixUtils.h"
#include "Membrane.h"
#include <stdio.h>
#include <math.h>


float    gElectrodeWidth_um;
float    gElectrodeSpc_um;
int      gNumElectrodes;
float  **gElectrodeVoltage;    // N X 2 array [0...N-1][0-1]


extern double (*gMembraneShape)(double, double);
extern double gMembraneTension_NByM;      // tension = stress * thickness
extern double gVoltageT_V;    // Transp. electrode voltage
extern double gVoltageA_V;    // Array electrode voltage
extern double gDistT_um;      // Transp. electr -- membr. dist.
extern double gDistA_um;      // Electr. array -- membr. dist.

void ElectrodeArray()
{
   int k;

   gElectrodeWidth_um   = 275.0;
   gElectrodeSpc_um     = 5.0;

   gNumElectrodes       = 2918; // must equal row dimension of
                                // ElectrodeAndSpacerLookUp in
                                // ElectrodeArray.h

   // set ElectrodeVoltage array.  1'st element in each row is the
   // index number for correspondence with the ElectrodeAndSpacerLookUp and
   // Wire List table.  2'nd element in each row is the voltage in V.
   // gElectrodeVoltage[0...N-1][0,1]
   gElectrodeVoltage = dmatrix(0,gNumElectrodes-1,0,1);
   for (k=0;k<gNumElectrodes;k++)
   {

      gElectrodeVoltage[k][0] = (float) ElectrodeAndSpacerLookUp[k][0];
      gElectrodeVoltage[k][1] = 0.0;

   }

   ComputeElectrodeVoltage();

   return;
}


//---------------------------------------------------------------------------
// ComputeElectrodeVoltage()
//
// Computes voltage on each electrode in the array required to produced
// the current membrane shape. Voltage is computed by solving the
// Membrane equilibrium equation at each point on the surface:
//
//                           e_0 * V_a^2       e_0 * V_t^2
//  -T * laplacian(xi)  =    -----------   -   -----------
//                          2(d_A - xi)^2      (d_t + xi)^2
//
//  solving the above equation for V_a^2 leads to:
//
//            2(d_a - xi)^2        e_0* V_t^2
//  V_a^2  =  ------------  * (   -----------      - T * laplacian(xi)   )
//                e_0             (d_t + xi)^2
//
//
//                                         V_t^2           T * laplacian(xi)
//  V_a    = sqrt(2)*(d_a - xi)* sqrt(  -----------   -  -------------------  )
//                                      (d_t + xi)^2             e_0
//
//
// the factor in ( ) above must be non-negative for V_a to be physical.
// This restriction places a lower limit on V_t for a given xi (membrane
// shape).
//
// If the current xi (membrane shape) and V_t combination yields a
// negative square root for V_a, then the function returns with an
// error message.
//
// Otherwise, the function computes V_a for each electrode in the array
// by evaluating the above equation at the r, phi coordinate of the
// corresponding electrode array center.
//
// The 0'th column of gElectrodeVoltage[][] is used to find the WireList
// index number of each electrode.  Then the r,phi coordinates of the
// electrode are computed from the ElectrodeAndSpacerLookUp table.  The voltage
// is stored in the 1st column of gElectrodeVoltage[][]
//
// called by: ElectrodeArray()
//
// plk 3/21/2005
//---------------------------------------------------------------------------
void ComputeElectrodeVoltage()
{
  int    k;
  int    theIndex;
  double theR_MKS;
  double thePhi_Rad;
  double theSqrtTerm;
  double theVtTerm;
  double theD2Term;
  double theDaFactor;
  double theNumer;
  double theDenom;
  double theVoltage;
  double e_0 = 8.85E-12;

  for (k=0;k<gNumElectrodes;k++)
  {
       theIndex = (int) gElectrodeVoltage[k][0];
       theR_MKS = (double) ERCenter_MKS(theIndex);
       thePhi_Rad = (double) EPhiCenter_rad(theIndex);

       theDaFactor=gDistA_um*1e-6 - gMembraneShape(theR_MKS,thePhi_Rad);
       theDaFactor*=sqrt(2);
       theDaFactor=theDaFactor;

       theDenom = gDistT_um*1e-6 + gMembraneShape(theR_MKS,thePhi_Rad);
       theDenom *= theDenom;
       theVtTerm = gVoltageT_V*gVoltageT_V/theDenom;

       theD2Term = Del2Expansion_MKS(theR_MKS,thePhi_Rad);
       theD2Term *= gMembraneTension_NByM/e_0;

       theSqrtTerm = theVtTerm - theD2Term;

       if (theSqrtTerm < 0)
       {
          //LogMessage("--- ComputeElectrodeVoltage:  Vt too low! Aborting...---");
          printf("   Electrode %d    theSqrtTerm = %f\n",k,theSqrtTerm);
          theVoltage = 0.0;
       }
       else
       {
          theVoltage = theDaFactor*sqrt(theSqrtTerm);
       }


       gElectrodeVoltage[k][1] = (float)theVoltage;
  }

  return;
}


int ERow(int inWireListIndex)
{
   // inWireListIndex - 1  b/c array is indexed from 0...N-1, but
   // WireListIndex runs from 1...N
   return ElectrodeAndSpacerLookUp[inWireListIndex-1][1];
}

int ECol(int inWireListIndex)
{
   // inWireListIndex - 1  b/c array is indexed from 0...N-1, but
   // WireListIndex runs from 1...N
   return ElectrodeAndSpacerLookUp[inWireListIndex-1][2];
}


//---------------------------------------------------------------------------
// EXCenter_MKS
//
// Returns the X coordinate of the center of the electrode pixel referenced
// by inWireListIndex, in MKS units (m).
//
// Electrode array coordinates have the center aligned with the physical
// center of the array.  Positive X values are toward the chip "North" side.
// Positive Y values are toward the chip "East" side.
//
// plk 03/18/2005
//---------------------------------------------------------------------------
float EXCenter_MKS(int inWireListIndex)
{
   int theColNum;
   float theYCenter_um;
   float thePitch_um;
   float theSign;
   int theColDist;

   thePitch_um= gElectrodeWidth_um + gElectrodeSpc_um;

   // element [][1] of lookup table is the row number --> X coordinate
   theColNum = ElectrodeAndSpacerLookUp[inWireListIndex-1][1];
   theColDist = abs(theColNum);
   theSign = theColNum/theColDist;


   theYCenter_um = theSign*((theColDist-1)*thePitch_um + 0.5*thePitch_um);


   return theYCenter_um * 1.0E-6;

}


//---------------------------------------------------------------------------
// EYCenter_MKS
//
// Returns the Y coordinate of the center of the electrode pixel referenced
// by inWireListIndex, in MKS units (m).
//
// Electrode array coordinates have the center aligned with the physical
// center of the array.  Positive X values are toward the chip "North" side.
// Positive Y values are toward the chip "East" side.
//
// plk 03/18/2005
//---------------------------------------------------------------------------
float EYCenter_MKS(int inWireListIndex)
{
   int theColNum;
   float theYCenter_um;
   float thePitch_um;
   float theSign;
   int theColDist;

   thePitch_um= gElectrodeWidth_um + gElectrodeSpc_um;
   theColNum = ElectrodeAndSpacerLookUp[inWireListIndex-1][2];
   theColDist = abs(theColNum);
   theSign = theColNum/theColDist;


   theYCenter_um = theSign*((theColDist-1)*thePitch_um + 0.5*thePitch_um);


   return theYCenter_um * 1.0E-6;

}


//---------------------------------------------------------------------------
// ERCenter_MKS
//
// Returns the R coordinate of the center of the electrode pixel referenced
// by inWireListIndex, in MKS units (m).
//
// Electrode array coordinates have the center aligned with the physical
// center of the array.  Positive X values are toward the chip "North" side.
// Positive Y values are toward the chip "East" side.
//
// plk 03/18/2005
//---------------------------------------------------------------------------
float ERCenter_MKS(int inWireListIndex)
{
   float theX_MKS;
   float theY_MKS;
   float theR_MKS;

   theX_MKS = EXCenter_MKS(inWireListIndex);
   theY_MKS = EYCenter_MKS(inWireListIndex);

   theR_MKS = sqrt(theX_MKS*theX_MKS + theY_MKS*theY_MKS);

   return theR_MKS;

}


//---------------------------------------------------------------------------
// EPhiCenter_rad
//
// Returns the phi coordinate of the center of the electrode pixel referenced
// by inWireListIndex, in radians (-pi ... pi).
//
// Electrode array coordinates have the center aligned with the physical
// center of the array.  Positive X values are toward the chip "North" side.
// Positive Y values are toward the chip "East" side.
//
// plk 03/18/2005
//---------------------------------------------------------------------------
float EPhiCenter_rad(int inWireListIndex)
{
   float theX_MKS;
   float theY_MKS;
   float thePhi_rad;

   theX_MKS = EXCenter_MKS(inWireListIndex);
   theY_MKS = EYCenter_MKS(inWireListIndex);

   thePhi_rad = atan2(theY_MKS,theX_MKS);

   return thePhi_rad;

}


//---------------------------------------------------------------------------
// EIndex
//
// returns the index number corresponding to a given electrode, specified
// by its (physical) row, col numbers in the lookup table ElectrodeAndSpacerLookUp
//
// NOTE: Row, Col numbers do not have zero values in the WireListLookUp
// table. If the function is passed with argument values of 0 then it
// will return the index corresponding to a ground connection.
//
// plk 03/18/2005
//---------------------------------------------------------------------------
int EIndex(int inRow, int inCol)
{
   int i;
   int theIndex;

   for (i=0;i<gNumElectrodes;i++)
   {

      if (ElectrodeAndSpacerLookUp[i][1] == inRow)
      {
         if (ElectrodeAndSpacerLookUp[i][2] == inCol)
         {
            theIndex = ElectrodeAndSpacerLookUp[i][0];
            return theIndex;
         }
      }
   }

   // if row,column were not in the electrode array, then
   // (arbitrarily) return the index corresponding to a ground
   // connection.
    fprintf(stderr, \
       " ---EIndex: could not find electrode row=%d col=%d ---\n",inRow,inCol);
    fprintf(stderr, "\t returning gnd connection 1022.\n");
   return 1022;

}



//---------------------------------------------------------------------------
// ElectrodeVoltage()
//
// returns the index number corresponding to a given electrode, specified
// by its (physical) row, col numbers in the lookup table ElectrodeAndSpacerLookUp
//
// NOTE: Row, Col numbers do not have zero values in the WireListLookUp
// table. If the function is passed with argument values of 0 then it
// will return the index corresponding to a ground connection.
//
// plk 03/18/2005
//---------------------------------------------------------------------------
float ElectrodeVoltage(int inIndex)
{
   int i;
   int theIndex;
   float theVoltage;

   for (i=0;i<gNumElectrodes;i++)
   {

      if (gElectrodeVoltage[i][0] == inIndex)
      {
            theVoltage = gElectrodeVoltage[i][1];
            return theVoltage;
      }
   }

   // if inIndex does not correspond to any electrode
   // in the array/database, return an error code.

   fprintf(stderr, \
        " ---ElectrodeVoltage:  could not find electrode %d ---\n",inIndex);
   return 9999.;

}




