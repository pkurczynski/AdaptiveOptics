//---------------------------------------------------------------------------
// MembraneInverseProblem.h                            C++ Header file
//
// MembraneInverseProblem takes as input a Wavefront that one desires to
// reproduce with a membrane mirror, and it computes the electrode
// voltage distribution (on the lower, actuating electrode plane) necessary
// to reproduce this desired shape.
//
// The desired membrane mirror shape is computed by dividing the wavefront
// phase, expressed as a physical distance, by two at each grid point in
// the simulation. This is accomplished in the class constructor.
//
// The electrode voltage distribution is computed by feeding this desired
// membrane shape into the lhs of the Poisson equation for the membrane:
//
//            Laplacian( xi ) =   - Pressure / Tension
//
// where xi is the membrane shape.  At each grid point, xi is a physical
// distance representing the deformation of the membrane from its uncharged,
// flat position ).  Computation of the lhs allows one to solve for the
// electrostatic pressure distribution experienced by the membrane.  From
// this pressure distribution, the electrode voltages are computed using:
//
//            Pressure = 1/2 * E_zero *  V^2  / dist^2
//
// Where V is the desired voltage at each grid point, and dist is the
// distance from the membrane to the actuating electrode ( dist = d_0 - xi
// for the lower, actuating electrode plane ).
//
//
// In general the electrode voltage distribution is a complex number.
// Imaginary voltages correspond to regions where the electrodes must "push"
// on the membrane in order to produce the desired deformation.  Since this
// is impossible, the voltage is physically unrealizable.
//
// A membrane shape that can be reproduced by a physically realizable electrode
// voltages will have electrode voltages that are entirely real numbers.
// Real and imaginary electrode voltages are stored within this class and
// can be graphed or saved to a file for importing into MS Excel etc.
//
// See also Wavefront class definition and MembranePDEproblem class definition.
//
// version 2
// plk 4/28/2003
//---------------------------------------------------------------------------
#ifndef MembraneInverseProblemH
#define MembraneInverseProblemH
#include "MembranePDEProblem.h"
#include "Graphics3d.h"
#include "Wavefront.h"


class MembraneInverseProblem : public MembranePDEProblem
{
   private:

      AnsiString ImagElectrodeFileName;
      AnsiString RealElectrodeFileName;

      double   InvertedMembraneSign;

      double   **RealElectrodeVoltage;
      double   **ImagElectrodeVoltage;
      double   **RealElectrodeVoltage_Graph;
      double   **ImagElectrodeVoltage_Graph;

      void     ComputeElectrodeVoltagesFromPoissonEquation();
      void     WriteHeaderDataToFile(AnsiString inFileName);
      void     AppendArrayDataToFile(AnsiString   inFileName,
                                     double     **inArrayData);

   public:

      MembraneInverseProblem(Wavefront *inWavefront,
                             double     inMembraneStress_MPa,
                             double     inMembraneThickness_um,
                             double     inMembraneGapDistance_um,
                             double     inMembraneTopElectrode_V,
                             double     inMembraneTopElectrodeDistance_um);

      ~MembraneInverseProblem();

      void ScaleDataForGraphicsDisplay();
      void DisplayRealElectrodeVoltage(Graphics3d *ioGraphicsCanvas);
      void DisplayImagElectrodeVoltage(Graphics3d *ioGraphicsCanvas);
      void WriteElectrodeDataToFile();
      void SetRHS();

};

extern MembraneInverseProblem *theMembraneInverseProblem;

#endif
