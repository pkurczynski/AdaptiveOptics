//---------------------------------------------------------------------------
// Lens.h                                        C++ Header file
//
// A Lens class is used to simulate a bias lens used to remove wavefront
// curvature in a pre-biased MembraneMirror.  An input Wavefront class
// is Refract()'ed by the Lens to yield an output Wavefront that has
// had its phase adjusted by a quadratic function of the distance from
// the optic axis.  
//
//---------------------------------------------------------------------------
#ifndef LensH
#define LensH
#include "Wavefront.h"


class Lens
{
   private:
      double     FocalLength_mm;
      double     FocalLength_MKS;

   public:

      Lens(double inFocalLength_mm);
      ~Lens();

      void Refract(Wavefront *ioWavefront);
};

extern Lens *theLens;

#endif


