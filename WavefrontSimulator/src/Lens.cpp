//---------------------------------------------------------------------------
// Lens.cpp                        Class implementation file
//
//
// plk 4/16/2003
//---------------------------------------------------------------------------
#include <math.h>
#include "Lens.h"
#include "WavefrontGUI.h"

//----------------------------------------------------------------------------
// Lens()
//
// Creates a Lens object.
//
// called by: TForm1::OpticsSimulationExecute()
//
//----------------------------------------------------------------------------
Lens::Lens(double inFocalLength_mm)
{
   FocalLength_mm = inFocalLength_mm;
   FocalLength_MKS = 1e-3 * inFocalLength_mm;


}

Lens::~Lens()
{

}

//----------------------------------------------------------------------------
// Refract()
//
// Refracts a wavefront, thus simulating transmission of the wavefront
// through the lens.
//
// called by: TForm1::OpticsSimulationExecute()
//
//----------------------------------------------------------------------------
void Lens::Refract(Wavefront *ioWavefront)
{
  double theX_MKS;                      // coordinates of a single point
  double theY_MKS;                      // in the wavefront.
  double theXC_MKS;                     // coordinates of the center of
  double theYC_MKS;                     // the lens & wavefront (optic axis).
  double theRadius_MKS;                 // distance from point to optic axis.
  double theSag_Rad;                    // Sag in radians.
  double theSag_MKS;                    // Sag in meters.

   theXC_MKS = ioWavefront->Width_MKS / 2;
   theYC_MKS = ioWavefront->Width_MKS / 2;

   // NOTE:  Array indexing from 0...N inclusive is intentional!
   // this is for compatibility with MembranePDEproblem arrays, and
   // does not cause a memory leak because of NR routine matrix()
   // which allocates from 0...N inclusive.
   for (int i=0;i<=ioWavefront->ArrayDimension;i++)
   {
      theX_MKS = i*ioWavefront->MeshSize_MKS - theXC_MKS;

      // Formula for the sag (wavefront retardation) as a function
      // of radius from the optic axis can be computed from geometry.
      // f = focal length of lens.
      //
      //    sag =  radius^2 / ( 2 * f )
      //
      for (int j=0;j<=ioWavefront->ArrayDimension;j++)
      {
         theY_MKS = j*ioWavefront->MeshSize_MKS - theYC_MKS;
         theRadius_MKS = sqrt(theX_MKS*theX_MKS + theY_MKS*theY_MKS);
         if (FocalLength_MKS == 0)
         {
            theSag_MKS = 9999;
         } else
         {
            theSag_MKS = theRadius_MKS * theRadius_MKS / (2 * FocalLength_MKS );
         }
         theSag_Rad =( 2*PI / ioWavefront->Wavelength_MKS ) * theSag_MKS;
         ioWavefront->Phase_rad[i][j] += theSag_Rad;
         ioWavefront->Phase_um[i][j] += 1e6 * theSag_MKS;
      }
   }

#ifdef WavefrontGUIH
   AnsiString theGoodNews;
   theGoodNews.sprintf("Lens Focal Length, mm: %5.0f",FocalLength_mm);
   WavefrontGUIForm->Memo1->Lines->Add("Refracted Wavefront.");
   WavefrontGUIForm->Memo1->Lines->Add(theGoodNews);
   WavefrontGUIForm->Memo1->Lines->Add(" ");
#endif

}
