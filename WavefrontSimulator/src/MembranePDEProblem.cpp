//---------------------------------------------------------------------------
// <Membrane>PDEproblem.cpp                           C++ class
//
// This class approximates a solution to Poisson's Equation
// on a the square region [0,ROIDimension_mm] x [0,ROIDimension_mm] given boundary conditions.
// Boundary conditions take the form of specified values of the function
// on the boundaries (Dirichlet's Problem)
//
// Numerical solution is performed using Gauss-Seidel iteration.  See
// Boundary Value Problems by David Powers, Chapter 7 for method.
//
// Uses class:  Graphics3d.h   ( accessed via pointer ioGraphicsCanvas )
//
// plk
// 01/12/2001
//---------------------------------------------------------------------------
#include <fstream.h>
#include <iostream.h>
#include <vcl.h>
#include <math.h>

#include "MembranePDEProblem.h"
#include "Graphics3d.h"
#include "NumRecipes.h"

MembranePDEProblem *theMembranePDEProblem;

//----------------------------------------------------------------------------
// MembranePDEProblem()
//
// Default Constructor.  Sets NON-MKS properties to zero.  Does
// not allocate arrays for SolutionData etc.
//
// called by:  MembraneInverseProblem()
//----------------------------------------------------------------------------
MembranePDEProblem::MembranePDEProblem()
{

   EntireSolutionDataFileName="MembranePDE_EntireSolution.txt";
   ROISolutionDataFileName="MembranePDE_ROISolution.txt";

   Stress_MPa          = 0;
   Thickness_um        = 0;
   GapDistance_um      = 0;
   Width_mm            = 0;
   Bias_V              = 0;
   TopElectrode_V      = 0;
   TopElectrodeDistance_um = 20;

   ArrayDimension      = 0;

   ROIDimension_mm     = 0;   // width of region of integration in x,y plane

   MeshSize_mm         = 0;        // step size in x,y

   DesiredFractionalError = 0;   //fractional error for iterative solution

   TotalIterations     = 0;

   // pointer to the StaticTextBox where the peak deflection information
   // will be displayed, after the problem is solved.
   // PeakDeflectionTextBox = ???;

   // pointer to the StaticText box where solution error will
   // be displayed on the GUI
   // SolutionErrorTextBox = ???;

   // Pointer to StaticText box where Total number of iterations
   // will be displayed on GUI
   // TotalIterationsTextBox = ????;

}


//----------------------------------------------------------------------------
// MembranePDEProblem()
//
// Sets up a membrane with specified stress, thickness, Gap distance,
// width.
//
// called by: TForm1::TForm1()
//
//----------------------------------------------------------------------------

MembranePDEProblem::MembranePDEProblem(TEdit       *inStress,
                                       TEdit       *inThickness,
                                       TEdit       *inGapDistance,
                                       TEdit       *inWidth,
                                       TEdit       *inBiasVoltage,
                                       TStaticText *inPeakDeflectionTextBox,
                                       TEdit       *inVoltage,
                                       TEdit       *inArrayDimension,
                                       TEdit       *inElectrodeXCenter,
                                       TEdit       *inElectrodeYCenter,
                                       TEdit       *inElectrodeXWidth,
                                       TEdit       *inElectrodeYWidth,
                                       TStaticText *outMeshSize_mm,
                                       TStaticText *inSolutionErrorTextBox,
                                       TStaticText *inTotalIterationsTextBox)
{

   double theElectrodeVoltage;
   double theElectrodeXCenter_mm;
   double theElectrodeYCenter_mm;
   double theElectrodeXWidth_mm;
   double theElectrodeYWidth_mm;
   //double XL,YL,XH,YH;


   Stress_MPa          = inStress->Text.ToDouble();
   Thickness_um        = inThickness->Text.ToDouble();
   GapDistance_um      = inGapDistance->Text.ToDouble();
   Width_mm            = inWidth->Text.ToDouble();
   Bias_V              = inBiasVoltage->Text.ToDouble();
   TopElectrode_V      = 0;
   TopElectrodeDistance_um = 20;
   ArrayDimension      = inArrayDimension->Text.ToInt();

   theElectrodeVoltage = inVoltage->Text.ToDouble();
   theElectrodeXCenter_mm = inElectrodeXCenter->Text.ToDouble();
   theElectrodeYCenter_mm = inElectrodeYCenter->Text.ToDouble();
   theElectrodeXWidth_mm = inElectrodeXWidth->Text.ToDouble();
   theElectrodeYWidth_mm = inElectrodeYWidth->Text.ToDouble();

   //XL = theElectrodeXCenter_mm - theElectrodeXWidth_mm/2;
   //XH = XL + theElectrodeXWidth_mm;
   //YL = theElectrodeYCenter_mm - theElectrodeYWidth_mm/2;
   //YH = YL + theElectrodeYWidth_mm;

   // pointer to the StaticTextBox where the peak deflection information
   // will be displayed, after the problem is solved.
   PeakDeflectionTextBox = inPeakDeflectionTextBox;

   EntireSolutionDataFileName="MembranePDE_EntireSolution.txt";
   ROISolutionDataFileName="MembranePDE_ROISolution.txt";

   ROIDimension_mm = Width_mm;   // width of region of integration in x,y plane

   MeshSize_mm = ROIDimension_mm / ArrayDimension;        // step size in x,y
   outMeshSize_mm->Caption=FormatFloat("0.00",MeshSize_mm);

   DesiredFractionalError = 1e-5;   //fractional error for iterative solution

   // pointer to the StaticText box where solution error will
   // be displayed on the GUI
   SolutionErrorTextBox = inSolutionErrorTextBox;

   // Pointer to StaticText box where Total number of iterations
   // will be displayed on GUI
   TotalIterationsTextBox = inTotalIterationsTextBox;
   TotalIterations = -1;

   InitializeMKSParamsAndDataArrays();


   SetBias();
   SetBoundaryConditions();

   SetHexActuator(theElectrodeXCenter_mm,
                  theElectrodeYCenter_mm,
                  theElectrodeXWidth_mm,
                  theElectrodeVoltage);
}



MembranePDEProblem::~MembranePDEProblem()
{
   // destroy the MembranePDEProblem

}



//--------------------------------------------------------------------------
// InitializeMKSParamsAndDataArrays()
//
// called by:  MembranePDEproblem()
//
//--------------------------------------------------------------------------
void MembranePDEProblem::InitializeMKSParamsAndDataArrays()
{

   // membrane and simulation parameters, in MKS units
   MeshSize_MKS = MeshSize_mm *1e-3;
   MembraneTension_MKS = ( Stress_MPa * 1e6)*( Thickness_um* 1e-6 );
   GapDistance_MKS = GapDistance_um*1e-6;
   Width_MKS = Width_mm *1e-3;
   TopElectrodeDistance_MKS = TopElectrodeDistance_um * 1e-6;


   SolutionData_Graph=matrix(0,ArrayDimension,0,ArrayDimension);
   rhs_Graph=matrix(0,ArrayDimension,0,ArrayDimension);
   ElectrodeVoltage_Graph=matrix(0,ArrayDimension,0,ArrayDimension);



   SolutionData=matrix(0,ArrayDimension,0,ArrayDimension);
   rhs=matrix(0,ArrayDimension,0,ArrayDimension);
   ElectrodeVoltage=matrix(0,ArrayDimension,0,ArrayDimension);

   for (int i=0;i<=ArrayDimension;i++)
   {
      for (int j=0;j<=ArrayDimension;j++)
      {
         SolutionData[i][j]=0;
	 rhs[i][j]=0;
         ElectrodeVoltage[i][j]=0;
         SolutionData_Graph[i][j]=0;
	 rhs_Graph[i][j]=0;
         ElectrodeVoltage_Graph[i][j]=0;

      }
   }


}


//--------------------------------------------------------------------------
// SetBoundaryConditions()
//
// Sets the boundary conditions of the MembranePDEProblem.  Dirichlet
// conditions --> value of the unknown function is zero on the boundary.
//
// called by: (all constructors),
//
//---------------------------------------------------------------------------
void MembranePDEProblem::SetBoundaryConditions()
{

   /*boundary conditions: SolutionData[i][j] --> z(i,j) on screen */

   for (int i=0;i<=ArrayDimension;i++)
   {

      SolutionData[0][i]=0;
      SolutionData[ArrayDimension][i]=0;
      SolutionData[i][0]=0;

   }


}

//----------------------------------------------------------------------------
// SetActuator()
//
// Simulates a rectangular actuator bounded by the specified coordinate
// pairs (XL,YL) ... (XH,YH) to a voltage specified by inVoltage.  Sets
// appropriate elements of the rhs array from the Poisson equation to
// the values specified by the Poisson equation.  rhs array is in MKS units.
//
// Parameter            Units
//-----------           -----
// inXL ... inYH        mm
// inVoltage_MKS        Volts
//
// called by: MembranePDEProblem::MembranePDEProblem()
//
//----------------------------------------------------------------------------
void MembranePDEProblem::SetActuator(double inXL,
                                     double inYL,
                                     double inXH,
                                     double inYH,
                                     double inVoltage_MKS)
{

   int iL = XValueToRowIndex(inXL);
   int jL = YValueToColumnIndex(inYL);
   int iH = XValueToRowIndex(inXH);
   int jH = YValueToColumnIndex(inYH);


   double thePressure_MKS = (0.5*E_zero*inVoltage_MKS*inVoltage_MKS)/
                           (GapDistance_MKS*GapDistance_MKS);
   double theRHSFactor_MKS = -1 * thePressure_MKS / MembraneTension_MKS;

   // set appropriate elements of the rhs array to the value corresponding
   // to the rhs of the Poisson equation for the membrane.  Other elements
   // of the rhs array are set to zero in the class constructor.
   for (int i=iL; i<=iH; i++)
   {
      for (int j=jL; j<=jH; j++)
      {
         rhs[i][j] = theRHSFactor_MKS;
         ElectrodeVoltage[i][j] = inVoltage_MKS;
      }
   }


}


//----------------------------------------------------------------------------
// SetHexActuator()
//
// Sets a hexagonal shaped electrode at the specified position to
// a specified voltage.
//
// called by: MembranePDEProblem::MembranePDEProblem()
//
//----------------------------------------------------------------------------
void MembranePDEProblem::SetHexActuator(double inXCenter_mm,
                                       double inYCenter_mm,
                                       double inSideLength_mm,
                                       double inVoltage_MKS)
{
   int    theRow, theColumn;
   double theXAbsolute, theYAbsolute;



   double thePressure_MKS = (0.5*E_zero*inVoltage_MKS*inVoltage_MKS)/
                           (GapDistance_MKS*GapDistance_MKS);
   double theRHSFactor_MKS = -1 * thePressure_MKS / MembraneTension_MKS;


   // slopes and intercepts of the diagonal lines that form the
   // top and bottom of the hexagonal electrode.  Diagonal border
   // lines have equations of the form y_rel = m x_rel + b where
   // m = slope = theDiagonalBorder[i][0]
   // b = intercept = theDiagonalBorder[i][1]
   // x_rel , y_rel are coordinates relative to XCenter, YCenter
   double theHexBorder[4][2];
   for (int i=0;i<4;i++)
   {
        theHexBorder[i][0] = 1/sqrt(3);       // slope
        theHexBorder[i][1] = inSideLength_mm;  // intercept
   }
   theHexBorder[0][0] *= -1;
   theHexBorder[2][0] *= -1;
   theHexBorder[2][1] *= -1;
   theHexBorder[3][1] *= -1;



   // loop over x points that are within the x range of the hex electrode
   // rel coordinates are relative to the XCenter, YCenter.
   double thePerpLength_mm = inSideLength_mm*sqrt(3)/2;
   double theStepSize_mm = MeshSize_mm / 2;
   for (double xrel=-thePerpLength_mm;xrel<=thePerpLength_mm;xrel+=theStepSize_mm)
   {
      for (double yrel=-inSideLength_mm;yrel<=inSideLength_mm;yrel+=theStepSize_mm)
      {
         // test the current point to see if it is within the
         // hexagon corresponding to the electrode.
         if ( yrel < theHexBorder[0][0]*xrel + theHexBorder[0][1] &&
              yrel < theHexBorder[1][0]*xrel + theHexBorder[1][1] &&
              yrel >= theHexBorder[2][0]*xrel + theHexBorder[2][1] &&
              yrel >= theHexBorder[3][0]*xrel + theHexBorder[3][1] )
         {
                // convert relative to absolute coordinates,
                // then to row,column index
                theXAbsolute = xrel + inXCenter_mm;
                theYAbsolute = yrel + inYCenter_mm;

                theRow = XValueToRowIndex(theXAbsolute);
                theColumn = YValueToColumnIndex(theYAbsolute);

                // set the appropriate element of voltage, rhs arrays
                // to the desired values.
                ElectrodeVoltage[theRow][theColumn] = inVoltage_MKS;
                rhs[theRow][theColumn]= theRHSFactor_MKS;


         }
      }
   }
}







//----------------------------------------------------------------------------
// SetBias()
//
// Adds a constant, uniform pressure to the membrane.  Simulates applying
// a bias voltage to all actuators underneath the membrane.
//
// Called by:  MembranePDEProblem::MembranePDEProblem()
//
//----------------------------------------------------------------------------
void MembranePDEProblem::SetBias()
{

   double thePressure_MKS = (0.5*E_zero*Bias_V*Bias_V)/
                           (GapDistance_MKS*GapDistance_MKS);
   double theRHSFactor_MKS = -1 * thePressure_MKS / MembraneTension_MKS;

   // set appropriate elements of the rhs array to the value corresponding
   // to the rhs of the Poisson equation for the membrane.  Other elements
   // of the rhs array are set to zero in the class constructor.
   for (int i=1; i<ArrayDimension; i++)
   {
      for (int j=1; j<ArrayDimension; j++)
      {
         rhs[i][j] = theRHSFactor_MKS;
         ElectrodeVoltage[i][j] = Bias_V;
      }
   }

}






//---------------------------------------------------------------------------
// Solve
//
// Solves the Poisson Equation Boundary Value Problem using Gauss-Seidel
// iteration.  See D. Powers, Boundary Value Problems, Ch. 7 for details
// on this method.  See also, Numerical Recipes in C, Ch 17.5 (p. 674).
//
// NOTE: SolutionData are computed in MKS units.
//
//
// Quantity         Units (MKS)
// ------------     -----
// SolutionData       m
// rhs                m^-1
//
//
// called by: TForm1::RunSolveExecute()
//
//---------------------------------------------------------------------------
void MembranePDEProblem::Solve()
{
   double v;
   double righthandside;
   int theMaxNumberOfIterations = 5000;


   //Gauss-Seidel iteration
   for (int count=0;count<theMaxNumberOfIterations;count++)
   {

      for (int i=1;i<ArrayDimension;i++)
      {
	 for (int j=1;j<ArrayDimension;j++)
         {
            righthandside = rhs[i][j];
	    v=SolutionData[i-1][j]+
              SolutionData[i+1][j]+
              SolutionData[i][j-1]+
              SolutionData[i][j+1];

            // See Numerical Recipes 17.5 (p. 674) for modification
            // to include nonzero right hand side of the PDE (Poisson's
            // Equation as opposed to Laplace's Equation

            v = 0.25*v - (MeshSize_MKS*MeshSize_MKS/4)*righthandside;


       	    SolutionData[i][j]=v;
	 }
      }
   }

   TotalIterations = theMaxNumberOfIterations;
   ComputeSolutionStatistics();
}




//---------------------------------------------------------------------------
// SolveBySOR()
//
// Implements the Numerical Recipes SOR code for solving the Poisson equation
// Uses SOR.C as well as NRUTIL.C routines
//
// called by: TForm1::RunSolveSORExecute()
//---------------------------------------------------------------------------
void MembranePDEProblem::SolveBySOR()
{
   double **a, **b, **c, **d, **e, **f;
   double rjac;

   a=dmatrix(0,ArrayDimension,0,ArrayDimension);
   b=dmatrix(0,ArrayDimension,0,ArrayDimension);
   c=dmatrix(0,ArrayDimension,0,ArrayDimension);
   d=dmatrix(0,ArrayDimension,0,ArrayDimension);
   e=dmatrix(0,ArrayDimension,0,ArrayDimension);
   f=dmatrix(0,ArrayDimension,0,ArrayDimension);

   // note peculiar 0...n array index convention.  In keeping with
   // NR, these arrays will only use 1...n indexed elements.  0 elements
   // are for consistency with the rest of this code.  0 elements will
   // be ignored in this solution (set to zero).
   for (int i=0;i<=ArrayDimension;i++)
   {
      for (int j=0;j<=ArrayDimension;j++)
      {

         // coeffs. of NR Eq. 17.5.25 pg. 678
         a[i][j] =  1;
         b[i][j] =  1;
         c[i][j] =  1;
         d[i][j] =  1;
         e[i][j] = -4;

         // this corrects an omission from Numerical Recipes!
         // NR algorithm implemented as a "black box" for the
         // Poisson problem is equivalent to using f[i][j] = rhs[i][j].
         // THIS IS WRONG!  (e.g. compare units--rhs has units of 1/m
         // in MKS).  The constant of proportionality between
         // f[i][j] and rhs[i][j] is alluded to on pg. 678 in reference
         // to NR Eq. 17.5.25, but is not explicitly mentioned.
         // The correct constant of proportionality can be found
         // by considering the finite difference scheme for the
         // Poisson equation, and deriving NR Eq. 17.5.25.  See
         // for example NR Eq. 17.5.5 on pg. 674 for finite difference
         // scheme for Poisson equation as part of discussion of
         // Jacobi's method.
         // plk 4/9/2003
         f[i][j] = (MeshSize_MKS*MeshSize_MKS)* rhs[i][j];
      }
   }


   // implement NR eq. 17.5.24 p. 678 for the rho_jacobi parameter.
   // NOTE "J" = "L" = ArrayDimension; "DeltaX" = "DeltaY" = MeshSize_MKS
   double theArg = PI/ArrayDimension;
   rjac = cos(theArg);

   sor(a,b,c,d,e,f,SolutionData,ArrayDimension,rjac);

   ComputeSolutionStatistics();
}








//---------------------------------------------------------------------------
// SolveByADI()
//
// Implements the Numerical Recipes ADI code for solving the Poisson equation
// Uses ADI.C as well as NRUTIL.C routines
//
// called by: TForm1::RunSolveADIExecute()
//
//---------------------------------------------------------------------------
void MembranePDEProblem::SolveByADI()
{
   double **a, **b, **c, **d, **e, **f, **g;
   double alpha, beta, eps;
   int jmax, k;

   a=dmatrix(0,ArrayDimension,0,ArrayDimension);
   b=dmatrix(0,ArrayDimension,0,ArrayDimension);
   c=dmatrix(0,ArrayDimension,0,ArrayDimension);
   d=dmatrix(0,ArrayDimension,0,ArrayDimension);
   e=dmatrix(0,ArrayDimension,0,ArrayDimension);
   f=dmatrix(0,ArrayDimension,0,ArrayDimension);
   g=dmatrix(0,ArrayDimension,0,ArrayDimension);


   // note peculiar 0...n array index convention.  In keeping with
   // NR, these arrays will only use 1...n indexed elements.  0 elements
   // are for consistency with the rest of this code.  0 elements will
   // be ignored in this solution (set to zero).
   for (int i=0;i<=ArrayDimension;i++)
   {
      for (int j=0;j<=ArrayDimension;j++)
      {
         // coeffs. of NR Eq. 17.6.22 pg. 685, taken from
         // NR Eq. 17.6.10 pg. 682.

         a[i][j] = -1;
         b[i][j] =  2;
         c[i][j] = -1;
         d[i][j] = -1;
         e[i][j] =  2;
         f[i][j] = -1;

         // this corrects an omission from Numerical Recipes!!
         // See note above in SolveBySOR()
         // plk 4/9/2003
         g[i][j] = (MeshSize_MKS*MeshSize_MKS)* rhs[i][j];
      }
   }

   // Number of sub-iterations in adi() is 2^k
   // Optimum values of k are taken from
   // k_opt ~ ln(4*ArrayDimension/PI)
   //
   // See NR pg. 685
   //
   // ArrayDimension         k_opt
   // --------------         -----
   //      25                 3
   //      50                 4
   //     100                 5
   //     200                 6
   //     500                 6

   k=4;

   // Bounds on the eigenvalues of the Poisson problem
   // on a square grid with Dirichlet boundary conditions.
   // See NR Eq. 17.6.20 pg. 684.
   alpha = 2 * ( 1 - cos((double)(PI/ArrayDimension)) );
   beta  = 2 * ( 1 - cos( (double)((ArrayDimension - 1)*PI/ArrayDimension) ) );

  // alpha = 0.0;
  // beta  = 4.0;

   eps = 1e-5;

   adi(a,b,c,d,e,f,g,SolutionData,ArrayDimension,k,alpha,beta,eps);

   ComputeSolutionStatistics();
}




//---------------------------------------------------------------------------
// SolveByIteration()
//
// Solves the full nonlinear Poisson problem using an iterative procedure.
// The 0'th order problme is solved, and the solution is fed into the
// right hand side of the Poisson equation.  The 0'th order Poisson problem
// is then solved again...
//
// called by:  TForm1::RunIterativeSolverExecute()
//
//---------------------------------------------------------------------------
void MembranePDEProblem::SolveByIteration()
{
   int      theMaxNumberOfIterations = 10;
   double   a,b,c,d,e,f;
   double   theDist_MKS;
   double   theVV;
   double   theDenom;
   double   theStartError_MKS;
   double   theRHSTerm;
   double   theResidual;
   double **theTempSolution;

   // coeffs for finite differencing of Poisson equation; for
   // error computation.  Seen NR. Eq. 17.5.25 pg. 678 and note
   // in SolveBySOR() concerning f
   a=1;
   b=1;
   c=1;
   d=1;
   e=-4;
   f=MeshSize_MKS*MeshSize_MKS;


   // compute starting error, assuming trial solution is 0 everywhere,
   // and coefficient matrix for computing error.  See NOTE below
   // in Error computation.
   theStartError_MKS = 0;
   for (int i=1;i<ArrayDimension;i++)
   {
         for (int j=1;j<ArrayDimension;j++)
         {
            theStartError_MKS += fabs( rhs[i][j] );
         }
   }



   theTempSolution = matrix(0,ArrayDimension,0,ArrayDimension);
   for (int i=0;i<=ArrayDimension;i++)
   {
      for (int j=0;j<=ArrayDimension;j++)
      {
         theTempSolution[i][j]=0;
      }
   }

   // MAIN ITERATION LOOP:  Maximum Number of Iterations set above.
   for (int k=0;k<theMaxNumberOfIterations;k++)
   {

      // set rhs array to adjust membrane-electrode distance at each
      // point for the previous iterate of the membrane deflection
      for (int i=0;i<=ArrayDimension;i++)
      {
         for (int j=0;j<=ArrayDimension;j++)
         {
            theDist_MKS= GapDistance_MKS - theTempSolution[i][j];
            theDenom = 2*MembraneTension_MKS*theDist_MKS*theDist_MKS;
            theVV =  ElectrodeVoltage[i][j]*ElectrodeVoltage[i][j];
            rhs[i][j]=-1 * E_zero * theVV  / theDenom;

         }
      }

      // solve the membrane problem using the updated membrane-electrode
      // distances.  (0'th order Poisson problem is solved here)
      SolveByADI();

      // store the new solution data for the next iteration
      for (int i=0;i<=ArrayDimension;i++)
      {
         for (int j=0;j<=ArrayDimension;j++)
         {
            theTempSolution[i][j] = SolutionData[i][j];
         }
      }

#if 0
      // compute the error by calculating  (del^2 xi - rhs) --> 0
      // for finite differencing of Poisson equation, see NR. Eq. 17.5.25
      // on pg. 678, and the IMPORTANT note in SolveBySOR() about the
      // f coefficient.
      ActualSolutionError_MKS=0.0;
      for (int i=1;i<ArrayDimension;i++)
      {
         for (int j=1;j<ArrayDimension;j++)
         {
            theVV = ElectrodeVoltage[i][j]*ElectrodeVoltage[i][j];
            theDist_MKS = GapDistance_MKS - SolutionData[i][j];
            theDenom = 2*MembraneTension_MKS*theDist_MKS*theDist_MKS;
            theRHSTerm = E_zero*theVV/theDenom;
            theResidual = a*SolutionData[i+1][j]+
                          b*SolutionData[i-1][j]+
                          c*SolutionData[i][j+1]+
                          d*SolutionData[i][j-1]+
                          e*SolutionData[i][j]  -
                          f*theRHSTerm;
            ActualSolutionError_MKS += fabs(theResidual);
         }
      }

      // if the error is small enough, display it on the GUI and quit iteration
      if ( k > 0 &&
           ActualSolutionError_MKS < DesiredFractionalError*theStartError_MKS)
      {
         TotalIterations = k+1;
         ComputeSolutionStatistics();
         return;
      }
#endif

   }

   TotalIterations = theMaxNumberOfIterations;
   ActualSolutionError_MKS=9999;
   ComputeSolutionStatistics();
}
//---------------------------------------------------------------------------


//---------------------------------------------------------------------------
// ScaleDataForGraphicsDisplay()
//
// Scales solution data and rhs data for ease of plotting by the graphics
// functions.
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
void MembranePDEProblem::ScaleDataForGraphicsDisplay()
{

   // Convert SolutionData to micron units.
   for (int i=1;i<ArrayDimension;i++)
   {
	 for (int j=1;j<ArrayDimension;j++)
         {
              SolutionData_Graph[i][j]=1e6*SolutionData[i][j];
              rhs_Graph[i][j]=0.1*rhs[i][j];
              ElectrodeVoltage_Graph[i][j]=(-0.01)*ElectrodeVoltage[i][j];
	 }
   }

}



//---------------------------------------------------------------------------
// DisplaySolution
//
// Display's the solution matrix for the PDE Boundry Value Problem.
// Displays a MeshSize_mm graph in 3D, with coordinate axes and a reference
// grid, of the same resolution as the SolutionData array, on the xy plane
// for reference.
//
// argument:  ioGraphicsCanvas      the graphics canvas for displaying
//                                  the solution.  Should have already
//                                  been initialized with a particular
//                                  view coordinate system, and other
//                                  parameters.
// called by: TForm1::PaintBox1OnPaint
//
//---------------------------------------------------------------------------
void MembranePDEProblem::DisplaySolution(Graphics3d *ioGraphicsCanvas)
{

   // draw 3D MeshSize_mm graph of solution

   double x;
   double y;
   for (int i=0;i<=ArrayDimension;i++)
   {
      for (int j=0;j<ArrayDimension;j++)
      {
	 x=i*MeshSize_mm;
         y=j*MeshSize_mm;
         ioGraphicsCanvas->moveto_3d(x,y,SolutionData_Graph[i][j]);
         if (PointIsWithinROI(i,j))
         {
#if 0
           if (PointIsWithinPupil(i,j))
              ioGraphicsCanvas->SetPenColor(clRed);
           else
#endif
              ioGraphicsCanvas->SetPenColor(clGreen);

         } else
              ioGraphicsCanvas->SetPenColor(clLtGray);
         y=(j+1)*MeshSize_mm;
         ioGraphicsCanvas->lineto_3d(x,y,SolutionData_Graph[i][j+1]);
      }
      y=0;
   }
   for (int j=0;j<=ArrayDimension;j++)
   {
      for (int i=0;i<ArrayDimension;i++)
      {
	 x=i*MeshSize_mm;
         y=j*MeshSize_mm;
         ioGraphicsCanvas->moveto_3d(x,y,SolutionData_Graph[i][j]);
         if (PointIsWithinROI(i,j))
         {
#if 0
           if (PointIsWithinPupil(i,j))
              ioGraphicsCanvas->SetPenColor(clRed);
           else
#endif
              ioGraphicsCanvas->SetPenColor(clGreen);
         } else
              ioGraphicsCanvas->SetPenColor(clLtGray);

	 x=(i+1)*MeshSize_mm;
         ioGraphicsCanvas->lineto_3d(x,y,SolutionData_Graph[i+1][j]);

      }
      x=0;
   }
}


//---------------------------------------------------------------------------
// DisplayRightHandSide
//
// Displays the right hand side matrix of the Poisson Problem to be solved
//
// argument:  ioGraphicsCanvas      the graphics canvas for displaying
//                                  the solution.  Should have already
//                                  been initialized with a particular
//                                  view coordinate system, and other
//                                  parameters.
// called by: TForm1::PaintBox1OnPaint
//
//---------------------------------------------------------------------------
void MembranePDEProblem::DisplayRightHandSide(Graphics3d *ioGraphicsCanvas)
{

   ioGraphicsCanvas->SetPenColor(clNavy);


   double x;
   double y;
   for (int i=0;i<=ArrayDimension;i++)
   {
      for (int j=0;j<ArrayDimension;j++)
      {
	 x=i*MeshSize_mm;
         y=j*MeshSize_mm;
         ioGraphicsCanvas->moveto_3d(x,y,rhs_Graph[i][j]);

	 y=(j+1)*MeshSize_mm;
         ioGraphicsCanvas->lineto_3d(x,y,rhs_Graph[i][j+1]);
      }
      y=0;
   }
   for (int j=0;j<=ArrayDimension;j++)
   {
      for (int i=0;i<ArrayDimension;i++)
      {
	 x=i*MeshSize_mm;
         y=j*MeshSize_mm;
         ioGraphicsCanvas->moveto_3d(x,y,rhs_Graph[i][j]);

	 x=(i+1)*MeshSize_mm;
         ioGraphicsCanvas->lineto_3d(x,y,rhs_Graph[i+1][j]);

      }
      x=0;
   }

}


//---------------------------------------------------------------------------
// DisplayElectrodeVoltage
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
void MembranePDEProblem::DisplayElectrodeVoltage(Graphics3d *ioGraphicsCanvas)
{

   ioGraphicsCanvas->SetPenColor(clNavy);


   double x;
   double y;
   for (int i=0;i<=ArrayDimension;i++)
   {
      for (int j=0;j<ArrayDimension;j++)
      {
	 x=i*MeshSize_mm;
         y=j*MeshSize_mm;
         ioGraphicsCanvas->moveto_3d(x,y,ElectrodeVoltage_Graph[i][j]);

	 y=(j+1)*MeshSize_mm;
         ioGraphicsCanvas->lineto_3d(x,y,ElectrodeVoltage_Graph[i][j+1]);
      }
      y=0;
   }
   for (int j=0;j<=ArrayDimension;j++)
   {
      for (int i=0;i<ArrayDimension;i++)
      {
	 x=i*MeshSize_mm;
         y=j*MeshSize_mm;
         ioGraphicsCanvas->moveto_3d(x,y,ElectrodeVoltage_Graph[i][j]);

	 x=(i+1)*MeshSize_mm;
         ioGraphicsCanvas->lineto_3d(x,y,ElectrodeVoltage_Graph[i+1][j]);

      }
      x=0;
   }

}


//---------------------------------------------------------------------------
// WriteEntireSolutionDataToFile
//
// Writes the solution matrix to a text file, compatible with loading
// into Microsoft Excel, or other utilities
//
// NOTE: SolutionData_Graph is written to file.  Units: microns
//
// file format:
//
// (Header information)
//                            <--(j index / y value, mm)-->
//    (i index)     0                    1            2       3 ...
//  (x value,mm)    0                   0.03         0.06    0.09 ...
//     0   0   SolutionData_Graph(0,0)  (0,1)
//     1  0.03    (1,0)         ...
//

// called by: TWavefrontGUIForm::FileSaveExecute()
//
//---------------------------------------------------------------------------
void MembranePDEProblem::WriteEntireSolutionDataToFile()
{

   fstream iofile(EntireSolutionDataFileName.c_str(), ios::out);

   if (iofile.fail())
   {
      // trap file I/O error here
   }
   else
   {
      iofile << "File Name: " << EntireSolutionDataFileName << '\n';
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

      iofile << "Membrane Deflection data, um (below) " << '\n';

      // write row index to file (column header #1)
      for (int i=-2;i<=ArrayDimension;i++)
      {
          iofile << i << '\t';
      }
      iofile << endl;

      for (int i=-1;i<=ArrayDimension;i++)
      {
          iofile << i*MeshSize_mm << '\t';
      }
      iofile << endl;

      // write solution to a file as a matrix of numbers
      for (int i=0;i<=ArrayDimension;i++)
      {
         iofile << i << '\t' << i*MeshSize_mm << '\t';
         for (int j=0;j<=ArrayDimension;j++)
         {
            iofile << SolutionData_Graph[i][j] << '\t';
         }
         iofile << endl;
      }

   }
   iofile.close();

}


//---------------------------------------------------------------------------
// WriteEntireSolutionDataToFile
//
// Writes the solution matrix to a text file, compatible with loading
// into Microsoft Excel, or other utilities
//
// NOTE: SolutionData_Graph is written to file.  Units: microns
//
// file format:
//
// (Header information)
//                            <--(j index / y value, mm)-->
//    (i index)     0                    1            2       3 ...
//  (x value,mm)    0                   0.03         0.06    0.09 ...
//     0   0   SolutionData_Graph(0,0)  (0,1)
//     1  0.03    (1,0)         ...
//

// called by: TWavefrontGUIForm::FileSaveExecute()
//
//---------------------------------------------------------------------------
void MembranePDEProblem::WriteROISolutionDataToFile()
{

   fstream iofile(ROISolutionDataFileName.c_str(), ios::out);

   if (iofile.fail())
   {
      // trap file I/O error here
   }
   else
   {
      iofile << "File Name: " << ROISolutionDataFileName << '\n';
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

      iofile << "Membrane Deflection data, um (below) " << '\n';

      // write row index to file (column header #1)
      for (int i=-2;i<=ArrayDimension;i++)
      {
          iofile << i << '\t';
      }
      iofile << endl;

      for (int i=-1;i<=ArrayDimension;i++)
      {
          iofile << i*MeshSize_mm << '\t';
      }
      iofile << endl;

      // write solution to a file as a matrix of numbers
      for (int i=0;i<=ArrayDimension;i++)
      {
         iofile << i << '\t' << i*MeshSize_mm << '\t';
         for (int j=0;j<=ArrayDimension;j++)
         {
            if (PointIsWithinROI(i,j))
            {
               iofile << SolutionData_Graph[i][j] << '\t';
            }
            else
            {
               iofile << "0" << '\t';
            }

         }
         iofile << endl;
      }

   }
   iofile.close();

}

int MembranePDEProblem::XValueToRowIndex(double inXValue_mm)
{

   int theIndex;

   double theXOffset = 0;

   theIndex = (int)( (inXValue_mm-theXOffset)/MeshSize_mm );

   // subscript out of bounds error
   if ( theIndex < 0 || theIndex > ArrayDimension )
        exit(9999);


   return theIndex;

}


int MembranePDEProblem::YValueToColumnIndex(double inYValue_mm)
{
   int theIndex;

   double theYOffset = 0;

   theIndex = (int)( (inYValue_mm-theYOffset)/MeshSize_mm );

   // subscript out of bounds error
   if ( theIndex < 0 || theIndex > ArrayDimension )
        exit(9999);

   return theIndex;


}



//---------------------------------------------------------------------------
// ComputeSolutionStatistics()
//
// Computes peak deflection and possibly other data from the solution
//
// called by:   Solve()
//              SolveByADI()
//              SolveByIteration()
//
//---------------------------------------------------------------------------
void MembranePDEProblem::ComputeSolutionStatistics()
{

   // find the maximum membrane deflection, display in text box
   double theCurrentMax_MKS = 0;
   for (int i=0;i<=ArrayDimension;i++)
   {
      for (int j=0;j<ArrayDimension;j++)
      {
            if ( SolutionData[i][j] > theCurrentMax_MKS)
            {
                theCurrentMax_MKS = SolutionData[i][j];
            }
      }
   }
   PeakDeflection_um = theCurrentMax_MKS*1e6;
#if 0
   PeakDeflectionTextBox->Caption = FormatFloat("0.00",PeakDeflection_um);

   SolutionErrorTextBox->Caption =
                        FormatFloat("0.00",ActualSolutionError_MKS*1e5);

   TotalIterationsTextBox->Caption = FormatFloat("0",TotalIterations);
#endif

}

// !!!!!!!!!!!!PupilRadius_mm is not a member of MembranePDEProblem!!!!!!!!!
#if 0

//--------------------------------------------------------------------------
// PointIsWithinPupil()
//
// return TRUE if the selected point in the wavefront, corresponding
// to (RowIndex, ColumnIndex) is within the current pupil.  The pupil
// is circular, with radius PupilRadius_mm, and is centered within
// the square wavefront.
//
// called by:  DisplaySolution()
//
//--------------------------------------------------------------------------
bool MembranePDEProblem::PointIsWithinPupil(int inRowIndex, int inColumnIndex)
{
   double theX_mm, theXRel_mm;
   double theY_mm, theYRel_mm;

   double theXC_mm = Width_mm/2;       // center of wavefront (optic axis)
   double theYC_mm = Width_mm/2;
   double theRadius_mm;


   theX_mm=inRowIndex*MeshSize_mm;
   theXRel_mm = theX_mm-theXC_mm;


   theY_mm=inColumnIndex*MeshSize_mm;
   theYRel_mm = theY_mm - theYC_mm;

   // if point is within the pupil radius, return TRUE.
   // otherwise return FALSE
   theRadius_mm = sqrt(theXRel_mm*theXRel_mm + theYRel_mm*theYRel_mm);
   if (theRadius_mm < PupilRadius_mm)
   {
      return true;
   } else {
      return false;
   }

}

#endif


//--------------------------------------------------------------------------
// PointIsWithinROI()
//
// return TRUE if the selected point in the wavefront, corresponding
// to (RowIndex, ColumnIndex) is within the Region of Interest. Region
// of Interest is circular, centered on the Pupil, with Diameter
// ROIDimension_mm.
//
// called by:  DisplaySolution()
//
//--------------------------------------------------------------------------
bool MembranePDEProblem::PointIsWithinROI(int inRowIndex, int inColumnIndex)
{
   double theX_mm, theXRel_mm;
   double theY_mm, theYRel_mm;

   double theXC_mm = Width_mm/2;       // center of wavefront (optic axis)
   double theYC_mm = Width_mm/2;
   double theRadius_mm;


   theX_mm=inRowIndex*MeshSize_mm;
   theXRel_mm = theX_mm-theXC_mm;


   theY_mm=inColumnIndex*MeshSize_mm;
   theYRel_mm = theY_mm - theYC_mm;

   // if point is within the pupil radius, return TRUE.
   // otherwise return FALSE
   theRadius_mm = sqrt(theXRel_mm*theXRel_mm + theYRel_mm*theYRel_mm);
   if (theRadius_mm < ROIDimension_mm/2 )
   {
      return true;
   } else {
      return false;
   }

}



double **MembranePDEProblem::matrix(int nrl, int nrh, int ncl, int nch)
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







