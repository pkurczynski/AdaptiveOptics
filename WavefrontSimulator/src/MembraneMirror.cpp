//---------------------------------------------------------------------------
// MembraneMirror.cpp                        Class implementation file
//
//
// plk 4/28/2003
//---------------------------------------------------------------------------
#include "MembraneMirror.h"

#ifndef PI
#define PI 3.1415926535
#endif


//----------------------------------------------------------------------------
// MembraneMirror()
//
// Creates a membrane mirror with the required shape to produce the
// input Wavefront.
//
// called by:
//----------------------------------------------------------------------------
MembraneMirror::MembraneMirror(Wavefront *inWavefront)
{

   ArrayDimension  = inWavefront->ArrayDimension;

   Width_mm        = inWavefront->Width_mm; // Width of membrane, Units: mm
   Width_MKS       = inWavefront->Width_MKS;// Width of square membrane, units: m

   ROIDimension_mm = inWavefront->ROIDimension_mm;  // length of x,y,z axes
                                                   //(in 3d coords)

   MeshSize_mm     = inWavefront->MeshSize_mm;    // mesh size (in 3d coords)
   MeshSize_MKS    = inWavefront->MeshSize_MKS;   // mesh size in MKS,units:  m


   // initialize the membrane mirror deformation to be
   // the same as the solution of the corresponding MembranePDEproblem
   Deformation_MKS = matrix(0,ArrayDimension,0,ArrayDimension);

   double          theDeformation_MKS;
   double          thePhaseToMKSFactor = inWavefront->Wavelength_MKS/(2*PI);

   // note 0...N inclusive indexing scheme is intentional, and
   // in keeping with numerical recipes matrix definition and
   // other class libraries within this project.  This will not
   // cause a memory leak.
   for (int i=0;i<=ArrayDimension;i++)
   {
      for (int j=0;j<=ArrayDimension;j++)
      {
         theDeformation_MKS = thePhaseToMKSFactor*inWavefront->Phase_rad[i][j];
         Deformation_MKS[i][j] = theDeformation_MKS;
      }
   }




}



MembraneMirror::~MembraneMirror()
{

}



//----------------------------------------------------------------------------
// Reflect()
//
// Simulates reflecting a wavefront from the membrane mirror.
// The phase at each point in the reflected wavefront is twice
// the membrane deformation, and scaled to modulo 2*PI at the
// given wavefront wavelength.
//
// called by:  TForm1::OpticsSimulationExecute()
//
//----------------------------------------------------------------------------
void MembraneMirror::Reflect(Wavefront *ioWavefront)
{
   double thePhsConvert = 2*PI/ioWavefront->Wavelength_MKS;

   for (int i=0;i<ArrayDimension;i++)
   {
      for (int j=0;j<ArrayDimension;j++)
      {
         ioWavefront->Phase_rad[i][j]= 2*thePhsConvert*Deformation_MKS[i][j];

      }
   }



}




double **MembraneMirror::matrix(int nrl, int nrh, int ncl, int nch)
{
   int i;
   double **m;
   m=(double **) malloc((unsigned) (nrh-nrl+1)*sizeof(double*));
   m-=nrl;
   for (i=nrl;i<=nrh;i++)   {
      m[i]=(double *) malloc((unsigned) (nch-ncl+1)*sizeof(double));
      m[i]-=ncl;
   }
   return m;
}


