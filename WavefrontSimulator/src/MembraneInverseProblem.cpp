//---------------------------------------------------------------------------
// MembraneInverseProblem.cpp                        Class implementation file
//
//
// plk 4/28/2003
//---------------------------------------------------------------------------
#include "MembraneInverseProblem.h"
#include "MembranePDEProblem.h"
#include <fstream.h>
#include <iostream.h>
#ifndef PI
#define PI 3.1415926535
#endif


//----------------------------------------------------------------------------
// MembraneInverseProblem()
//
// Creates a membrane mirror with the required shape to produce the
// input Wavefront.
//
// called by: TForm1::TForm1()
//            TForm1::Reset_Wavefront()
//----------------------------------------------------------------------------
MembraneInverseProblem::MembraneInverseProblem(Wavefront *inWavefront,
                             double     inMembraneStress_MPa,
                             double     inMembraneThickness_um,
                             double     inMembraneGapDistance_um,
                             double     inMembraneTopElectrode_V,
                             double     inMembraneTopElectrodeDistance_um)
{
   RealElectrodeFileName = "RealElectrode.txt";
   ImagElectrodeFileName = "ImagElectrode.txt";

   // This is the "sign" in the Poisson Equation, where
   // laplacian(xi) = InvertedMembraneSign * Pressure/Tension
   //
   // Set as follows:  -1 for "correct" problem.  1 for "inverted Membrane."
   // This property is used in SetRHS()
   InvertedMembraneSign = 1;


   ArrayDimension           = inWavefront->ArrayDimension;

   Width_mm                 = inWavefront->Width_mm; // Width of membrane
   ROIDimension_mm          = inWavefront->ROIDimension_mm;
   MeshSize_mm              = inWavefront->MeshSize_mm;

   Stress_MPa               = inMembraneStress_MPa;
   Thickness_um             = inMembraneThickness_um;
   GapDistance_um           = inMembraneGapDistance_um;
   TopElectrode_V           = inMembraneTopElectrode_V;
   TopElectrodeDistance_um  = inMembraneTopElectrodeDistance_um;

   double          theDeformation_MKS;
   double          thePhaseToMKSFactor = inWavefront->Wavelength_MKS/(2*PI);

   RealElectrodeVoltage=matrix(0,ArrayDimension,0,ArrayDimension);
   RealElectrodeVoltage_Graph=matrix(0,ArrayDimension,0,ArrayDimension);
   ImagElectrodeVoltage=matrix(0,ArrayDimension,0,ArrayDimension);
   ImagElectrodeVoltage_Graph=matrix(0,ArrayDimension,0,ArrayDimension);

   // Allocate arrays for solution data etc.
   // this method defined in MembranePDEProblem
   InitializeMKSParamsAndDataArrays();


   // note 0...N inclusive indexing scheme is intentional, and
   // in keeping with numerical recipes matrix definition and
   // other class libraries within this project.  This will not
   // cause a memory leak.
   for (int i=0;i<=ArrayDimension;i++)
   {
      for (int j=0;j<=ArrayDimension;j++)
      {
         //initialize these arrays
         RealElectrodeVoltage[i][j]=0;
         RealElectrodeVoltage_Graph[i][j]=0;
         ImagElectrodeVoltage[i][j]=0;
         ImagElectrodeVoltage_Graph[i][j]=0;

         // set SolutionData to the deformation appropriate
         // to generate the input wavefront.
         //
         // factor 0.5 b/c phase shift is TWICE the mechanical
         // deformation of the membrane, due to double pass reflection
         theDeformation_MKS = 0.5*thePhaseToMKSFactor*
                                        inWavefront->Phase_rad[i][j];
         SolutionData[i][j] = theDeformation_MKS;
      }
   }

   ComputeElectrodeVoltagesFromPoissonEquation();
}



MembraneInverseProblem::~MembraneInverseProblem()
{

}



//----------------------------------------------------------------------------
// ComputeElectrodeVoltagesFromPoissonEquation()
//
// Computes the Electrode Voltages necessary to reproduce the current
// membrane shape, as stored in MembranePDEProblem::SolutionData[][].
// By computing the laplacian of the known membrane shape, the Poisson
// equation directly yields the electrostatic pressure, and hence the
// electrode voltage as a function of position in the plane of the membrane.
//
// Real electrode voltages are physically realizable.  Imaginary electrode
// voltages are not.
//
// Incorporates transparent/top electrode set to a constant voltage.
//
// See notes:  ComputeElectrodeVoltagesFromPoissonEquation 5/5/2003
// in looseleaf binder:
//
// called by: MembraneInverseProblem::MembraneInverseProblem()
//
//----------------------------------------------------------------------------

void MembraneInverseProblem::ComputeElectrodeVoltagesFromPoissonEquation()
{

   double theD2ByDx2;
   double theD2ByDy2;

   // note 0...N inclusive indexing scheme is intentional, and
   // in keeping with numerical recipes matrix definition and
   // other class libraries within this project.  This will not
   // cause a memory leak.

   // Compute Laplacian of all points in the interior of SolutionData.
   // Set the rhs array to these Laplacian values.
   // Points on the boundary will have rhs[][] = 0 by default.
   for (int i=1;i<ArrayDimension;i++)
   {
      for (int j=1;j<ArrayDimension;j++)
      {
         theD2ByDx2 = (SolutionData[i+1][j] -
                       2*SolutionData[i][j] +
                       SolutionData[i-1][j]  )/(MeshSize_MKS*MeshSize_MKS);

         theD2ByDy2 = (SolutionData[i][j+1] -
                       2*SolutionData[i][j] +
                       SolutionData[i][j-1]  )/(MeshSize_MKS*MeshSize_MKS);

         rhs[i][j] = theD2ByDx2 + theD2ByDy2;
      }
   }


   // Compute the ElectrodeVoltage distribution corresopnding to
   // the just computed rhs[][] array

   double theV2;
   double theD2;
   double theDeflection_MKS;
   double theTopDeflection_MKS;
   double theDT2;
   double theVT2;
   double the2TByE0 = 2*MembraneTension_MKS / E_zero;

   // note 0...N inclusive indexing scheme is intentional, and
   // in keeping with numerical recipes matrix definition and
   // other class libraries within this project.  This will not
   // cause a memory leak.
   for (int i=0;i<=ArrayDimension;i++)
   {
      for (int j=0;j<=ArrayDimension;j++)
      {
          theDeflection_MKS = GapDistance_MKS - SolutionData[i][j];
          theD2 = theDeflection_MKS * theDeflection_MKS;
          theTopDeflection_MKS = TopElectrodeDistance_MKS + SolutionData[i][j];
          theDT2 = theTopDeflection_MKS * theTopDeflection_MKS;
          theVT2 = TopElectrode_V * TopElectrode_V;

          theV2 =  theD2* ( the2TByE0*rhs[i][j] + theVT2/theDT2 );

          if (theV2 >=0)
          {
             RealElectrodeVoltage[i][j] = sqrt(theV2);
             ImagElectrodeVoltage[i][j] = 0;
          }
          else
          {
             ImagElectrodeVoltage[i][j] = sqrt( fabs(theV2) );
             RealElectrodeVoltage[i][j] = 0;
          }

          // this is the real part of the Electrode Voltage;
          // Data property of the MembranePDEProblem class.
          ElectrodeVoltage[i][j] = RealElectrodeVoltage[i][j];
      }
   }



}

//---------------------------------------------------------------------------
// SetRHS()
//
// Sets the rhs[][] array of the MembranePDEProblem to match the
// current ElectrodeVoltage[][] array.  Once rhs has been set
// the MembranePDEProblem solver methods can be called.
//
// Uses gap distance set by the GapDistance_MKS property of the
// MembranePDEProblem.  May not be strictly accurate for the non-
// linear, iterative solution.
//
// called by:  TForm1::RunMembraneSolverExecute()
//
//---------------------------------------------------------------------------
void MembraneInverseProblem::SetRHS()
{
   double theV2;
   double theD2;
   double theVT2;
   double theDT2;
   double thePressure_MKS;
   double theTopElectrodePressure_MKS;

   // note 0...N inclusive indexing scheme is intentional, and
   // in keeping with numerical recipes matrix definition and
   // other class libraries within this project.  This will not
   // cause a memory leak.
   for (int i=0;i<=ArrayDimension;i++)
   {
      for (int j=0;j<=ArrayDimension;j++)
      {
           theV2 = ElectrodeVoltage[i][j] * ElectrodeVoltage[i][j];
           theD2 = GapDistance_MKS * GapDistance_MKS;
           thePressure_MKS = 0.5 * E_zero * theV2 / theD2 ;

           theVT2 = TopElectrode_V * TopElectrode_V;

           // assume membrane is equidistant from
           // top and bottom electrode planes.
           // i.e. GapDistance_MKS is defined as
           // the distance from membrane to the
           // bottom electrode plane (not the top).
           theDT2 = GapDistance_MKS * GapDistance_MKS;
           theTopElectrodePressure_MKS = 0.5 * E_zero * theVT2 / theDT2;
           rhs[i][j] = ( InvertedMembraneSign / MembraneTension_MKS ) *
                       ( thePressure_MKS - theTopElectrodePressure_MKS) ;
      }
   }
}



//---------------------------------------------------------------------------
// ScaleDataForGraphicsDisplay()
//
// Scales solution data and rhs data for ease of plotting by the graphics
// functions.  Over-rides MembranePDEProblem::ScaleDataForGraphicsDisplay()
//
// Quantity            Units
// ------------        -----
// SolutionData_Graph    um
// rhs                 (0.1)m^-1
// ElectrodeVoltage    (-0.01)V
//
// called by:  TForm1::TForm1()
//             TForm1::RunSolveExecute()
//             TForm1::RunIterativeSolverExecute()
//
//---------------------------------------------------------------------------
void MembraneInverseProblem::ScaleDataForGraphicsDisplay()
{

   // Convert SolutionData to micron units.
   for (int i=1;i<ArrayDimension;i++)
   {
	 for (int j=1;j<ArrayDimension;j++)
         {
           SolutionData_Graph[i][j]=1e6*SolutionData[i][j];
           rhs_Graph[i][j]=0.1*rhs[i][j];
           ElectrodeVoltage_Graph[i][j]=(-0.01)*ElectrodeVoltage[i][j];
           RealElectrodeVoltage_Graph[i][j]=(-0.01)*RealElectrodeVoltage[i][j];
           ImagElectrodeVoltage_Graph[i][j]=(-0.01)*ImagElectrodeVoltage[i][j];


	 }
   }

}



//---------------------------------------------------------------------------
// DisplayRealElectrodeVoltage
//
// Displays the ElectrodeVoltage matrix of the Poisson Problem to be solved
//
// argument:  ioGraphicsCanvas      the graphics canvas for displaying
//                                  the solution.  Should have already
//                                  been initialized with a particular
//                                  view coordinate system, and other
//                                  parameters.
//
// called by: TForm1::PaintBox1OnPaint
//
//---------------------------------------------------------------------------
void MembraneInverseProblem::DisplayRealElectrodeVoltage(Graphics3d *ioGraphicsCanvas)
{

   // graph real electrode voltage in Green

   double x;
   double y;
   for (int i=0;i<=ArrayDimension;i++)
   {
      for (int j=0;j<ArrayDimension;j++)
      {
	 x=i*MeshSize_mm;
         y=j*MeshSize_mm;
         ioGraphicsCanvas->moveto_3d(x,y,RealElectrodeVoltage_Graph[i][j]);

	 y=(j+1)*MeshSize_mm;
         if ( fabs(RealElectrodeVoltage_Graph[i][j+1]) < 0.001 )
         {
            ioGraphicsCanvas->SetPenColor(clLtGray);
            ioGraphicsCanvas->lineto_3d(x,y,RealElectrodeVoltage_Graph[i][j+1]);
         } else
         {
            ioGraphicsCanvas->SetPenColor(clGreen);
            ioGraphicsCanvas->lineto_3d(x,y,RealElectrodeVoltage_Graph[i][j+1]);
         }

      }
      y=0;
   }
   for (int j=0;j<=ArrayDimension;j++)
   {
      for (int i=0;i<ArrayDimension;i++)
      {
	 x=i*MeshSize_mm;
         y=j*MeshSize_mm;
         ioGraphicsCanvas->moveto_3d(x,y,RealElectrodeVoltage_Graph[i][j]);

	 x=(i+1)*MeshSize_mm;
         ioGraphicsCanvas->lineto_3d(x,y,RealElectrodeVoltage_Graph[i+1][j]);

         if ( fabs(RealElectrodeVoltage_Graph[i+1][j]) < 0.001 )
         {
            ioGraphicsCanvas->SetPenColor(clLtGray);
            ioGraphicsCanvas->lineto_3d(x,y,RealElectrodeVoltage_Graph[i+1][j]);
         } else
         {
            ioGraphicsCanvas->SetPenColor(clGreen);
            ioGraphicsCanvas->lineto_3d(x,y,RealElectrodeVoltage_Graph[i+1][j]);
         }


      }
      x=0;
   }


}



//---------------------------------------------------------------------------
// DisplayImagElectrodeVoltage
//
// Displays the ElectrodeVoltage matrix of the Poisson Problem to be solved
//
// argument:  ioGraphicsCanvas      the graphics canvas for displaying
//                                  the solution.  Should have already
//                                  been initialized with a particular
//                                  view coordinate system, and other
//                                  parameters.
//
// called by: TForm1::PaintBox1OnPaint
//
//---------------------------------------------------------------------------
void MembraneInverseProblem::DisplayImagElectrodeVoltage(Graphics3d *ioGraphicsCanvas)
{



   double x;
   double y;

   // graph imaginary electrode voltage in purple

   for (int i=0;i<=ArrayDimension;i++)
   {
      for (int j=0;j<ArrayDimension;j++)
      {
	 x=i*MeshSize_mm;
         y=j*MeshSize_mm;
         ioGraphicsCanvas->moveto_3d(x,y,ImagElectrodeVoltage_Graph[i][j]);

	 y=(j+1)*MeshSize_mm;
         if ( fabs(ImagElectrodeVoltage_Graph[i][j+1]) < 0.001 )
         {
            ioGraphicsCanvas->SetPenColor(clLtGray);
            ioGraphicsCanvas->lineto_3d(x,y,ImagElectrodeVoltage_Graph[i][j+1]);
         } else
         {
            ioGraphicsCanvas->SetPenColor(clPurple);
            ioGraphicsCanvas->lineto_3d(x,y,ImagElectrodeVoltage_Graph[i][j+1]);
         }
      }
      y=0;
   }
   for (int j=0;j<=ArrayDimension;j++)
   {
      for (int i=0;i<ArrayDimension;i++)
      {
	 x=i*MeshSize_mm;
         y=j*MeshSize_mm;
         ioGraphicsCanvas->moveto_3d(x,y,ImagElectrodeVoltage_Graph[i][j]);

	 x=(i+1)*MeshSize_mm;
         if ( fabs(ImagElectrodeVoltage_Graph[i+1][j]) < 0.001 )
         {
            ioGraphicsCanvas->SetPenColor(clLtGray);
            ioGraphicsCanvas->lineto_3d(x,y,ImagElectrodeVoltage_Graph[i+1][j]);
         } else
         {
            ioGraphicsCanvas->SetPenColor(clPurple);
            ioGraphicsCanvas->lineto_3d(x,y,ImagElectrodeVoltage_Graph[i+1][j]);
         }
      }
      x=0;
   }

}



//---------------------------------------------------------------------------
// WriteElectrodeVoltagesToFile()
//
//
//
//
//
// called by:
//
//---------------------------------------------------------------------------
void MembraneInverseProblem::WriteElectrodeDataToFile()
{

   WriteHeaderDataToFile(RealElectrodeFileName);
   AppendArrayDataToFile(RealElectrodeFileName,RealElectrodeVoltage);

   WriteHeaderDataToFile(ImagElectrodeFileName);
   AppendArrayDataToFile(ImagElectrodeFileName,ImagElectrodeVoltage);


}


//---------------------------------------------------------------------------
// WriteHeaderDataToFile
//
// Writes the solution matrix to a text file, compatible with loading
// into Microsoft Excel, or other utilities
//
//
// file format:
//
//
// called by: WriteElectrodeDataToFile()
//
//---------------------------------------------------------------------------
void MembraneInverseProblem::WriteHeaderDataToFile(AnsiString inFileName)
{


   fstream iofile(inFileName.c_str(), ios::out);

   if (iofile.fail())
   {
      // trap file I/O error here
   }
   else
   {
      iofile << "File Name: " << inFileName.c_str() << '\n';
      iofile << "Array Dimension: " << ArrayDimension << '\n';
      iofile << "Stress, MPa " << Stress_MPa<< '\n';
      iofile << "Thickness, um " << Thickness_um << '\n';
      iofile << "Gap Distance, um " << GapDistance_um << '\n';
      iofile << "Width, mm " << Width_mm << '\n';
      iofile << "Bias, V " << Bias_V << '\n';
      iofile << "ROIDimension, mm " << ROIDimension_mm << '\n';
      iofile << "Mesh Size, mm " << MeshSize_mm << '\n';
      iofile << "Membrane Tension, MKS " << MembraneTension_MKS << '\n';
      iofile << "Peak Deflection, um " << PeakDeflection_um << '\n';

   }
   iofile.close();




}


//---------------------------------------------------------------------------
// AppendArrayDataToFile
//
// Writes the solution matrix to a text file, compatible with loading
// into Microsoft Excel, or other utilities
//
//
// file format:
//
// (Header information)
//                            <--(j index / y value, mm)-->
//    (i index)     0                    1            2       3 ...
//  (x value,mm)    0                   0.03         0.06    0.09 ...
//     0   0   inArrayData(0,0)        (0,1)
//     1  0.03    (1,0)         ...
//

// called by: WriteElectrodeDataToFile()
//
//---------------------------------------------------------------------------
void MembraneInverseProblem::AppendArrayDataToFile(AnsiString inFileName,
                                                   double  **inArrayData)
{


   // Open file for appending.  Don't overwrite header
   fstream iofile(inFileName.c_str(), ios::app);

   if (iofile.fail())
   {
      // trap file I/O error here
   }
   else
   {


      // write row index to file (column header #1)
      for (int i=-2;i<=ArrayDimension;i++)
      {
          iofile << i << '\t';
      }
      iofile << endl;

      // write y-value to file (column header #2)
      for (int i=-2;i<=ArrayDimension;i++)
      {
          iofile << i*MeshSize_mm << '\t';
      }
      iofile << endl;

      // write solution to a file as a matrix of numbers
      for (int i=0;i<=ArrayDimension;i++)
      {
         // write row headers to file:  i index, x-value
         iofile << i << '\t' << i*MeshSize_mm << '\t';
         for (int j=0;j<=ArrayDimension;j++)
         {
            iofile << inArrayData[i][j] << '\t';
         }
         iofile << endl;
      }
   }
   iofile.close();

}








