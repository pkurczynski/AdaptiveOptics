//---------------------------------------------------------------------------
// MembraneMirror.h                                    C++ Header file
//
// Class definition for the the MembraneMirror class.   A membrane mirror
// simulates reflection of a Wavefront from a membrane with a shape that
// has been determined by a MembranePDEproblem.  In essence, this class
// implements the phase shift that occurs to a Wavefront upon being reflected
// by the membrane.
//
// See also Wavefront class definition and MembranePDEproblem class definition.
//
// version 2
// plk 4/28/2003
//---------------------------------------------------------------------------
#ifndef MembraneMirrorH
#define MembraneMirrorH
#include "Graphics3d.h"
#include "Wavefront.h"


class MembraneMirror
{
   private:
      int          ArrayDimension;
      double     **Deformation_MKS;
      double       Width_mm;             // Width of membrane, Units: mm
      double       Width_MKS;            // Width of square membrane, units: m

      double       ROIDimension_mm;      // length of x,y,z axes (in 3d coords)

      double       MeshSize_mm;          // mesh size (in 3d coords)
      double       MeshSize_MKS;         // mesh size in MKS,  units:  m

      double **matrix(int nrl, int nrh, int ncl, int nch);

   public:

      MembraneMirror(Wavefront *inWavefront);
      ~MembraneMirror();

      void Reflect(Wavefront *ioWavefront);



};

extern MembraneMirror *theMembraneMirror;

#endif
