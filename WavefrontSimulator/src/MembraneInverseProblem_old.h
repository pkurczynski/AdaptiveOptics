//---------------------------------------------------------------------------
// MembraneInverseProblem.h                                    C++ Header file
//
// Class definition for the the MembraneInverseProblem class.   
//
// See also Wavefront class definition and MembranePDEProblem class definition.
//
// version 1
// plk 4/28/2003
//---------------------------------------------------------------------------
#ifndef MembraneInverseProblemH
#define MembraneInverseProblemH
#include "Graphics3d.h"
#include "Wavefront.h"


class MembraneInverseProblem
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

      MembraneInverseProblem(Wavefront *inWavefront);
      ~MembraneInverseProblem();

      void Reflect(Wavefront *ioWavefront);



};

extern MembraneInverseProblem *theMembraneInverseProblem;

#endif
