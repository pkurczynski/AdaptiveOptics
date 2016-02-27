//---------------------------------------------------------------------------
// SAValidate.c
//
// Computes Omega Matrix and its eigenvalues & eigenvectors to determine
// the stability of a particular membrane configuration.  See Formal
// Stability Calculation write-up.
//
// Version 4
// plk 05/12/2005
//---------------------------------------------------------------------------
#include <stdio.h>
#include <conio.h>
#include <math.h>

#pragma hdrstop

#include "SAValidate.h"
#include "ComputeOmegaMatrix.h"
#include "MatrixUtils.h"
#include "MatrixA.h"
#include "BesselJZeros.h"
#include "Eigenfunc.h"
#include "Membrane.h"
#include "NR.h"
#include "NRUTIL.H"
#include "ElectrodeArray.h"
//---------------------------------------------------------------------------


extern int       gNumberOfEigenFunctions;
extern int       gNumElectrodes;
extern double    gPeakDeformation_um;
extern float   **gOmega;
extern double  **gMatrixA;
extern float   **gEigenVector;
extern float    *gEigenValue;
extern double  (*gMembraneShape)(double, double);
extern float   **gElectrodeVoltage;
extern float   **gElectrodeVoltageMap;
extern int       gMapDim;
extern float  **gElectrodePosition_MKS;
extern double    gVoltageA_V;
extern double    gVoltageT_V;
extern double    gDistT_um;
extern double    gDistA_um;

extern float gElectrodeWidth_um;
extern float gElectrodeSpc_um;
extern int   gNumElectrodes;



#pragma argsused
int main(int argc, char* argv[])
{
   char theMessage[100];
   float theTest;

   OpenLogFile();
   LogMessage("SAValidate.exe  Version 4");

   Membrane();
   ElectrodeArray();
   //LogSimParams();


#if 0
   LogMessage("Index    X_um    Y_um   Electrode?");
   LogFMatrix(gElectrodePosition_MKS,\
                0,gNumElectrodes-1,\
                0,3,\
                "ElectrodePosition_MKS");
#endif



#if 0
    //---------------------------------------------
    // TEST MEMBRANE SHAPE AS EXPANSION IN EIGENFUNCTIONS
    //---------------------------------------------
    TestMembraneExpansion(0,0.0075,30);
#endif



#if 0
    //---------------------------------------------
    // TEST COMPUTATION OF ELECTROSTATIC WEIGHT FN.
    //---------------------------------------------
    printf("Test Electrostatic Weight Fns:\n");
    TestElectrostaticWeightFn(0,0.0075,30);

#endif



#if 0
    //---------------------------------------------
    // TEST MATRIXA COMPUTATION AND MEMBRANE
    // EIGENFUNCTION ORTHONORMALITY.
    //---------------------------------------------
    TestMatrixAComputation();
    TestMembraneEigenfunctions();
#endif


#if 0
        LogMessage("--- BEGIN Stability Computation --- ");
        gVoltageT_V = 10.0;
        gPeakDeformation_um = -1.0;
        LogSimParams();
        SetMembraneShape_BesselJZero();
        ComputeElectrodeVoltage();

        //---------------------------------------------
        // TEST MEMBRANE SHAPE AS EXPANSION IN EIGENFUNCTIONS
        //---------------------------------------------
        TestMembraneExpansion(0,0.0075,25);



        // CURRENT ELECTRODE VOLTAGE MAP
        LogFMatrix(gElectrodeVoltageMap, \
                    0,gMapDim-1,\
                    0,gMapDim-1,\
                    "Electrode Voltage Map");

        RunStabilityComputation();
        TestStabilityMatrixEigenvectors();
        printf("\n\nMinimum Eigenvalue:  %f\n\n",gEigenValue[1]);
        LogMessage("--- END Stability Computation --- ");

#endif


#if 1
        LogMessage("--- BEGIN Stability Computation --- ");
        gVoltageT_V = 10.0;
        gVoltageA_V = 9999;
        gDistT_um = 75;
        gDistA_um = 75;

        gPeakDeformation_um = 0.0;
        LogSimParams();

        DoPeakDefVariationExpt(-8,8,1);
#endif


#if 0
        LogMessage("--- BEGIN TE Voltage Variation Stability Computation --- ");

        // these parameters used for simulation to compare
        // with vision science wavefront.  See \Data\05-23-2005\
        gVoltageT_V = 150.0;
        gVoltageA_V = 9999;
        gDistT_um = 125;
        gDistA_um = 125;
        gPeakDeformation_um = 3.4;
        LogSimParams();

        DoTEVoltageVariationExpt(50,200,50);

#endif


#if 0
        LogMessage("--- BEGIN Stability Computation --- ");
        gVoltageT_V = 75.0;
        gVoltageA_V = 9999;
        gDistT_um = 75;
        gDistA_um = 75;
        LogSimParams();

        DoEigenfuncAmplVariationExpt(1,-5E-8,5e-8,2.5e-8);
#endif



#if 0
        LogMessage("--- BEGIN Gap Dist Variation Stability Computation --- ");

        
        gVoltageT_V = 75.0;
        gVoltageA_V = 9999;
        gDistT_um = 30;
        gDistA_um = 30;
        SetMembraneShape_Eigenfunc(1,2.5E-8);
        LogSimParams();

        DoGapDistanceVariationExpt(30,80,10);

#endif



#if 0
        TestSmallAmplitudeStability(0,30,0,30,20);
#endif


#if 0
   theTest=GetDeviceStability();
   printf("theTest=%f\n",theTest);
#endif



   printf("\nDone!\n");
   while (!kbhit());
   getch();
   return 0;
}
//---------------------------------------------------------------------------


//---------------------------------------------------------------------------
// TestSmallAmplitudeStability()
//
// Tests the small amplitude stability of the membrane device over a range
// of (constant) array voltagse and transparent electrode voltages.
// Membrane deformation is set to 0 um.  Voltage is set to an arbitrary
// value; therefore the simulation is self consistent only for cases
// where Va^2/da^3 = Vt^2/dt^3.
//
// called by:  main()
//
// plk 4/18/2005
//---------------------------------------------------------------------------
void TestSmallAmplitudeStability(float inVaLow_V, \
                                 float inVaHigh_V, \
                                 float inVtLow_V, \
                                 float inVtHigh_V,
                                 int   inNumGridPoints)
{
   int   i,j;
   float theXV, theYV;
   float theVaMeshSize_V;
   float theVtMeshSize_V;

   float **theResult;

   LogMessage("---Test Small Amplitude Stability---");

   gPeakDeformation_um = 0.0;
   SetMembraneShape_BesselJZero();

   // top row and left column of this matrix will have the
   // independent variables Va^2/da^3 and Vt^2/dt^3
   // Remaining array elements will have the minimum
   // eigenvalue of each simulation.
   //
   theResult=matrix(0,inNumGridPoints,\
                    0,inNumGridPoints);

   theVaMeshSize_V = (inVaHigh_V - inVaLow_V)/(inNumGridPoints-1);
   theVtMeshSize_V = (inVtHigh_V - inVtLow_V)/(inNumGridPoints-1);

   for(i=0;i<=inNumGridPoints;i++)
   {
       gVoltageT_V = inVtLow_V+(i-1)*theVtMeshSize_V;

       theYV = pow(gVoltageT_V,2)/pow(gDistT_um,3);

       for (j=0;j<=inNumGridPoints;j++)
       {

          gVoltageA_V = inVaLow_V+(j-1)*theVaMeshSize_V;
          theXV = pow(gVoltageA_V,2)/pow(gDistA_um,3);

          // top row ... column labels
          if (i == 0)
          {
             //theResult[i][j] = j;
             theResult[i][j] = theXV;
          }
          else
          {
             // left column ... row labels
             if (j == 0)
             {
                //theResult[i][j] = i;
                theResult[i][j] = theYV;
             }

             // data
             else
             {
                SetElectrodeArrayVoltage(gVoltageA_V);
                LogSimParams();
                theResult[i][j] = GetDeviceStability();
             }
          }
       }
   }

   LogMessage("TE varies down a column; EA varies across a row");
   LogFMatrix(theResult,\
              0,inNumGridPoints,\
              0,inNumGridPoints,\
              "Result");

   LogMessage("---End Test Small Amplitude Stability---");
}



//---------------------------------------------------------------------------
// GetDeviceStability
//
// Returns the minimum eigenvalue of the stability matrix for the
// current device.   If this eigenvalue is greater than zero, the
// device is stable.  If the minimum eigenvalue is less than zero,
// the device is unstable.
//
// called by:  TestSmallAmplitudeStability()
//
// plk 4/18/2005
//---------------------------------------------------------------------------
float GetDeviceStability()
{
   RunFastStabilityComputation();
   return gEigenValue[1];
}



//---------------------------------------------------------------------------
// RunStabilityComputation
//
// Computes the Alpha and Omega matrices for a given device configuration.
// Writes the matrices and eigenvalues, eigenvectors to the log file and
// the console display.
//
// called by:  main()
//
// plk 4/1/2005
//---------------------------------------------------------------------------
void RunStabilityComputation()
{
        int      theDim;
        float  **theOmega;
        double **theMatrixA;
        double **theMatrixASum;



        theOmega = matrix(1,gNumberOfEigenFunctions, \
                    1,gNumberOfEigenFunctions);
        theMatrixA = dmatrix(0,gNumberOfEigenFunctions-1, \
                    0,gNumberOfEigenFunctions-1);
        theMatrixASum = dmatrix(0,gNumberOfEigenFunctions-1, \
                    0,gNumberOfEigenFunctions-1);


        //---------------------------------------------
        // COMPUTE MATRIXA WITH INTEGRAL
        //---------------------------------------------

        ComputeMatrixA(theMatrixA);
        LogDMatrix(theMatrixA,\
                     0,gNumberOfEigenFunctions-1,\
                     0,gNumberOfEigenFunctions-1,\
                     "MatrixA (Integral)");


        //---------------------------------------------
        // COMPUTE MATRIXA AS SUM OVER ELECTRODE PIXELS
        //---------------------------------------------

        //ComputeMatrixASum(theMatrixASum);
        ComputegMatrixASum();
        LogDMatrix(gMatrixA,\
                     0,gNumberOfEigenFunctions-1,\
                     0,gNumberOfEigenFunctions-1,\
                     "gMatrixA (Discrete Sum)");


        //---------------------------------------------
        // OMEGA MATRIX GENERATION
        //---------------------------------------------

        ComputeOmegaMatrix();
        LogFMatrix(gOmega,\
        1,gNumberOfEigenFunctions,\
        1,gNumberOfEigenFunctions,\
        "Omega Matrix (Discrete Sum)");


        //---------------------------------------------
        // OMEGA MATRIX DIAGONALIZATION, EIGENVALUES
        //---------------------------------------------

        CopyFMatrix(gOmega,theOmega, \
                    1,gNumberOfEigenFunctions,\
                    1,gNumberOfEigenFunctions);

        theDim = gNumberOfEigenFunctions;
        DiagonalizeFMatrix(theOmega,theDim,gEigenValue,gEigenVector);


        //---------------------------------------------
        // DISPLAY OMEGA EIGENVALUES, EIGENVECTORS
        //---------------------------------------------

        LogFVector(gEigenValue,1,theDim,"Omega Matrix -- Eigenvalues");

        LogFMatrix(gEigenVector, \
                     1, theDim, \
                     1, theDim, \
                     "Omega Matrix -- Eigenvectors");

        return;

}



//---------------------------------------------------------------------------
// RunFastStabilityComputation
//
// Computes the Alpha and Omega matrices for a given device configuration.
// Writes the matrices and eigenvalues, eigenvectors to the log file and
// the console display.
//
// called by:  GetDeviceStability()
//
// plk 4/1/2005
//---------------------------------------------------------------------------
void RunFastStabilityComputation()
{
        int      theDim;
        float  **theOmega;
        double **theMatrixA;
        double **theMatrixASum;



        theOmega = matrix(1,gNumberOfEigenFunctions, \
                    1,gNumberOfEigenFunctions);
        theMatrixA = dmatrix(0,gNumberOfEigenFunctions-1, \
                    0,gNumberOfEigenFunctions-1);
        theMatrixASum = dmatrix(0,gNumberOfEigenFunctions-1, \
                    0,gNumberOfEigenFunctions-1);

#if 0
        //---------------------------------------------
        // COMPUTE MATRIXA WITH INTEGRAL
        //---------------------------------------------

        ComputeMatrixA(theMatrixA);
        LogDMatrix(theMatrixA,\
                     0,gNumberOfEigenFunctions-1,\
                     0,gNumberOfEigenFunctions-1,\
                     "MatrixA (Integral)");


        //---------------------------------------------
        // COMPUTE MATRIXA AS SUM OVER ELECTRODE PIXELS
        //---------------------------------------------

        //ComputeMatrixASum(theMatrixASum);
        ComputegMatrixASum();
        LogDMatrix(gMatrixA,\
                     0,gNumberOfEigenFunctions-1,\
                     0,gNumberOfEigenFunctions-1,\
                     "gMatrixA (Discrete Sum)");

#endif
        //---------------------------------------------
        // OMEGA MATRIX GENERATION
        //---------------------------------------------
        //ComputegMatrixASum();
        ComputeOmegaMatrix();
        LogFMatrix(gOmega,\
        1,gNumberOfEigenFunctions,\
        1,gNumberOfEigenFunctions,\
        "Omega Matrix (Discrete Sum)");


        //---------------------------------------------
        // OMEGA MATRIX DIAGONALIZATION, EIGENVALUES
        //---------------------------------------------

        CopyFMatrix(gOmega,theOmega, \
                    1,gNumberOfEigenFunctions,\
                    1,gNumberOfEigenFunctions);

        theDim = gNumberOfEigenFunctions;
        DiagonalizeFMatrix(theOmega,theDim,gEigenValue,gEigenVector);


        //---------------------------------------------
        // DISPLAY OMEGA EIGENVALUES, EIGENVECTORS
        //---------------------------------------------

        LogFVector(gEigenValue,1,theDim,"Omega Matrix -- Eigenvalues");


#if 0
        LogFMatrix(gEigenVector, \
                     1, theDim, \
                     1, theDim, \
                     "Omega Matrix -- Eigenvectors");
#endif

        return;

}


//---------------------------------------------------------------------------
// TestStabilityMatrixEigenvectors
//
// Computes the matrix product of Omega eigenvectors.  Result should be
// an identity matrix since the Omega eigenvectors are orthonormal.
//
// Must have previously executed ComputeOmegaMatrix() before calling
// this procedure.
//
// called by: main()
//
// plk 4/1/2005
//---------------------------------------------------------------------------
void TestStabilityMatrixEigenvectors()
{
        int theDim;
        float **theEigenVector_T;
        float **theMatrixProduct;

        theDim = gNumberOfEigenFunctions;
        theEigenVector_T = matrix(1,theDim, \
                                   1,theDim);

        theMatrixProduct = matrix(1,theDim, \
                                   1,theDim);

        TransposeFMatrix(gEigenVector,theEigenVector_T, \
                         1, theDim, \
                         1, theDim);

        MultiplyFMatrix(gEigenVector,theEigenVector_T, theMatrixProduct,\
                         1, theDim, 1, theDim, \
                         1, theDim, 1, theDim);

        LogFMatrix(theMatrixProduct,\
                     1,gNumberOfEigenFunctions,\
                     1,gNumberOfEigenFunctions,\
                     "Product Matrix (Omega Eigenvectors):  E*E^T");

        return;
}



//---------------------------------------------------------------------------
// TestMatrixAComputation
//
// Tests matrixA computation by computing this matrix with both continuous
// integral and discrete sum over electrodes.  For 0 peak deformation, the
// results of both of these computations should be the same, and the
// resulting matrix should be diagonal.  This procedure sets all electrodes
// pixels of the array that are underneath the membrane to the voltage
// gVoltageA_V used in the integral MatrixA calculation.  This procedure
// simulates the integral calculation which assumes the entire electrode
// array underneath the membrane is at a single voltage.
//
// Discrepancies between the integral and discrete MatrixA compuations
// may arise because the discrete computation, has a relatively large
// "patch" size due to the finite electrode pixel width, 275 um for the
// typical array.
//
// called by:  main()
//
// plk 4/1/2005
//---------------------------------------------------------------------------
void TestMatrixAComputation()
{

    double **theMatrixA;
    double **theMatrixASum;

    theMatrixA = dmatrix(0,gNumberOfEigenFunctions-1, \
                    0,gNumberOfEigenFunctions-1);
    theMatrixASum = dmatrix(0,gNumberOfEigenFunctions-1, \
                    0,gNumberOfEigenFunctions-1);


    LogMessage("--- BEGIN Test MatrixA Computation ---");

    gVoltageA_V = 1.0;
    gVoltageT_V = 1.0;
    gPeakDeformation_um = 0.0;
    LogSimParams();
    SetMembraneShape_BesselJZero();


    // set all electrodes of the array to the voltage
    // value used in computation of the (integral) MatrixA
    // NOTE ElectrodeArray is not used in the integral
    // MatrixA computation, but only for the discrete MatrixA
    SetElectrodeArrayVoltage(gVoltageA_V);
    LogFMatrix(gElectrodeVoltageMap, \
                    0,gMapDim-1,\
                    0,gMapDim-1,\
                    "Electrode Voltage Map");


    // Compute the integral MatrixA
    ComputeMatrixA(theMatrixA);
    LogDMatrix(theMatrixA,\
                     0,gNumberOfEigenFunctions-1,\
                     0,gNumberOfEigenFunctions-1,\
                     "MatrixA (Integral)");

    // Compute the discrete MatrixA
    ComputeMatrixASum(theMatrixASum);
    LogDMatrix(theMatrixASum,\
                     0,gNumberOfEigenFunctions-1,\
                     0,gNumberOfEigenFunctions-1,\
                     "MatrixA (Sum)");

    LogMessage("--- above matrices should be identical, diagonal ---");
    LogMessage("--- END of Test MatrixA Computation ---");

    return;
}


//---------------------------------------------------------------------------
// TestMembraneEigenfunctions
//
// Computes product of membrane eigenfunction matrix:  EP * EP^T.
// Membrane eigenfunctions are orthonormal, therefore this product matrix
// should be an identity matrix.
//
// called by:
//
// plk 4/1/2005
//---------------------------------------------------------------------------
void TestMembraneEigenfunctions()
{
        double **theEPMatrix;

        LogMessage("--- Test Membrane Eigenfunctions ---");

        theEPMatrix = dmatrix(1,gNumberOfEigenFunctions, \
                    1,gNumberOfEigenFunctions);
        ComputeEPMatrix(theEPMatrix);

        LogDMatrix(theEPMatrix,\
                    1,gNumberOfEigenFunctions,
                    1,gNumberOfEigenFunctions,
                    "Product Matrix (Membrane Eigenfunctions) E*E^T");

        LogMessage("---Above matrix should be an identity matrix---");

}



//---------------------------------------------------------------------------
// DoPeakDefVariationExpt
//
// Varies peak deformation
// between specified limits, stepping specified amount.  Simulation
// computes Omega matrix eigenvalues for stability determination at
// each value of the membrane peak deformation, as well as ancillary
// test and validation data.  Simulated membrane is deformed to a
// BesselJZero function.  Electrode voltages are computed in a self-
// consistent manner.
//
// called by:  main()
//
// plk 3/29/2005
//---------------------------------------------------------------------------
void DoPeakDefVariationExpt(double inL_um, double inH_um, double inStep_um)
{
   int theDim;

   float **theOmega;
   double **theMatrixA;
   double **theMatrixASum;
   float  **theOmegaResult;
   float **theEigenVector_T;
   float **theMatrixProduct;
   float **theSimilarMatrix;
   double **theEPMatrix;
   float   *thePeakDefResult;

   double thePeakDef_um;

   int   theResultRow;
   int   theMaxNumberOfSimulations;

   char theMessage[100];



   theOmega = matrix(1,gNumberOfEigenFunctions, \
                    1,gNumberOfEigenFunctions);
   theMatrixA = dmatrix(0,gNumberOfEigenFunctions-1, \
                    0,gNumberOfEigenFunctions-1);
   theMatrixASum = dmatrix(0,gNumberOfEigenFunctions-1, \
                    0,gNumberOfEigenFunctions-1);


   theMaxNumberOfSimulations = 200;
   theOmegaResult = matrix(0,theMaxNumberOfSimulations, \
                    0,gNumberOfEigenFunctions);
   thePeakDefResult = vector(0,theMaxNumberOfSimulations);

   LogMessage("--- Begin Vary-Peak-Deformation Simulation --- ");

   theResultRow = 1;
   for (thePeakDef_um=inL_um;thePeakDef_um<=inH_um;thePeakDef_um+=inStep_um)
   {

        // store peak defs for print out to result matrix
        thePeakDefResult[theResultRow] = thePeakDef_um;

        gPeakDeformation_um = thePeakDef_um;
        sprintf(theMessage,"Peak Deformation:  %7.2f um\n",gPeakDeformation_um);
        LogMessage(theMessage);
        SetMembraneShape_BesselJThree();

        ComputeElectrodeVoltage();


        //---------------------------------------------
        // PRINT, LOG ELECTRODE MAP...ALL VOLTAGES
        //---------------------------------------------
        LogFMatrix(gElectrodeVoltageMap, \
                    0,gMapDim-1,\
                    0,gMapDim-1,\
                    "Electrode Voltage Map");

        //---------------------------------------------
        // PRINT, LOG MEMBRANE SHAPE:  RADIAL FN.
        //---------------------------------------------

        TestMembraneExpansion(0,0.0075,25);


        //---------------------------------------------
        // OMEGA, MATRIXA GENERATION
        //---------------------------------------------

        ComputeOmegaMatrix(gOmega);
        ComputeMatrixASum(theMatrixASum);

        //---------------------------------------------
        // PRINT, LOG MATRIXA: DISCRETE VERSION
        //---------------------------------------------
        LogDMatrix(theMatrixASum,\
                     0,gNumberOfEigenFunctions-1,\
                     0,gNumberOfEigenFunctions-1,\
                     "MatrixASum (discr.)");


        //---------------------------------------------
        // PRINT, LOG OMEGA MATRIX
        //---------------------------------------------

        CopyFMatrix(gOmega,theOmega, \
                    1,gNumberOfEigenFunctions,\
                    1,gNumberOfEigenFunctions);



        LogFMatrix(gOmega,\
                     1,gNumberOfEigenFunctions,\
                     1,gNumberOfEigenFunctions,\
                     "Omega Matrix");


        //---------------------------------------------
        // OMEGA MATRIX DIAGONALIZATION, EIGENVALUES
        //---------------------------------------------

        theDim = gNumberOfEigenFunctions;
        DiagonalizeFMatrix(theOmega,theDim,gEigenValue,gEigenVector);

        //---------------------------------------------
        // DISPLAY OMEGA EIGENVALUES, EIGENVECTORS
        //---------------------------------------------

        LogFVector(gEigenValue,1,theDim,"Omega Matrix -- Eigenvalues");

        // copy current eigenvalues to the Result matrix for print out
        // at end of simulation
        CopyFVectorToMatrixRow(gEigenValue,1,theDim,theOmegaResult,theResultRow);

        LogFMatrix(gEigenVector, \
                     1, theDim, \
                     1, theDim, \
                     "Omega Matrix -- Eigenvectors");


        //---------------------------------------------
        // TEST OMEGA EIGENVECTOR ORTHONORMALITY
        //---------------------------------------------
        theEigenVector_T = matrix(1,theDim, \
                                   1,theDim);

        theMatrixProduct = matrix(1,theDim, \
                                   1,theDim);

        TransposeFMatrix(gEigenVector,theEigenVector_T, \
                         1, theDim, \
                         1, theDim);

        MultiplyFMatrix(gEigenVector,theEigenVector_T, theMatrixProduct,\
                         1, theDim, 1, theDim, \
                         1, theDim, 1, theDim);


        LogFMatrix(theMatrixProduct,\
                     1,gNumberOfEigenFunctions,\
                     1,gNumberOfEigenFunctions,\
                     "Product Matrix (Omega Eigenvectors):  E*E^T");


        //---------------------------------------------
        // TEST MEMBRANE EIGENFUNCTIONS ORTHONORMALITY
        //---------------------------------------------
        theEPMatrix = dmatrix(1,gNumberOfEigenFunctions, \
                    1,gNumberOfEigenFunctions);
        ComputeEPMatrix(theEPMatrix);


        LogDMatrix(theEPMatrix,\
                    1,gNumberOfEigenFunctions,
                    1,gNumberOfEigenFunctions,
                    "Product Matrix (Membrane Eigenfunctions) E*E^T");

        // row index for eigenvalue result matrix
        theResultRow++;

   } // end for loop

   // copy peak defs. (indep. variable) to result matrix, column 0.
   CopyFVectorToMatrixCol(thePeakDefResult,1,theResultRow-1,theOmegaResult,0);



   LogFMatrix(theOmegaResult,\
        1,theResultRow,\
        0,gNumberOfEigenFunctions,\
        "Omega Eigenvalues:  Summary");


   return;
}










//---------------------------------------------------------------------------
// DoTEVoltageVariationExpt
//
// Varies peak deformation
// between specified limits, stepping specified amount.  Simulation
// computes Omega matrix eigenvalues for stability determination at
// each value of the membrane peak deformation, as well as ancillary
// test and validation data.  Simulated membrane is deformed to a
// BesselJZero function.  Electrode voltages are computed in a self-
// consistent manner.
//
// called by:  main()
//
// plk 3/29/2005
//---------------------------------------------------------------------------
void DoTEVoltageVariationExpt(double inL_V, double inH_V, double inStep_V)
{
   int theDim;

   float **theOmega;
   double **theMatrixA;
   double **theMatrixASum;
   float  **theOmegaResult;
   float **theEigenVector_T;
   float **theMatrixProduct;
   float **theSimilarMatrix;
   double **theEPMatrix;
   float   *thePeakDefResult;

   double theVt_V;

   int   theResultRow;
   int   theMaxNumberOfSimulations;

   char theMessage[100];



   theOmega = matrix(1,gNumberOfEigenFunctions, \
                    1,gNumberOfEigenFunctions);
   theMatrixA = dmatrix(0,gNumberOfEigenFunctions-1, \
                    0,gNumberOfEigenFunctions-1);
   theMatrixASum = dmatrix(0,gNumberOfEigenFunctions-1, \
                    0,gNumberOfEigenFunctions-1);


   theMaxNumberOfSimulations = 200;
   theOmegaResult = matrix(0,theMaxNumberOfSimulations, \
                    0,gNumberOfEigenFunctions);
   thePeakDefResult = vector(0,theMaxNumberOfSimulations);

   sprintf(theMessage,"Peak Deformation:  %7.2f um\n",gPeakDeformation_um);
   LogMessage(theMessage);


   // set the current membrane shape.  gPeakDeformation_um must have
   // been set previously, in calling procedure.
   SetMembraneShape_BesselJZero();



   LogMessage("--- Begin Vary-T.E. Voltage Simulation --- ");

   theResultRow = 1;
   for (theVt_V=inL_V;theVt_V<=inH_V;theVt_V+=inStep_V)
   {

        sprintf(theMessage,"T.E. Voltage:  %7.2f V\n",theVt_V);
        LogMessage(theMessage);

        // store peak defs for print out to result matrix
        thePeakDefResult[theResultRow] = theVt_V;


        // Array voltage required to produce the membrane shape
        // with the current transparent electrode voltage.
        gVoltageT_V = theVt_V;
        ComputeElectrodeVoltage();


        //---------------------------------------------
        // PRINT, LOG ELECTRODE MAP...ALL VOLTAGES
        //---------------------------------------------
        LogFMatrix(gElectrodeVoltageMap, \
                    0,gMapDim-1,\
                    0,gMapDim-1,\
                    "Electrode Voltage Map");

        //---------------------------------------------
        // PRINT, LOG MEMBRANE SHAPE:  RADIAL FN.
        //---------------------------------------------

        TestMembraneExpansion(0,0.0075,25);


        //---------------------------------------------
        // OMEGA, MATRIXA GENERATION
        //---------------------------------------------

        ComputeOmegaMatrix(gOmega);
        ComputeMatrixASum(theMatrixASum);

        //---------------------------------------------
        // PRINT, LOG MATRIXA: DISCRETE VERSION
        //---------------------------------------------
        LogDMatrix(theMatrixASum,\
                     0,gNumberOfEigenFunctions-1,\
                     0,gNumberOfEigenFunctions-1,\
                     "MatrixASum (discr.)");


        //---------------------------------------------
        // PRINT, LOG OMEGA MATRIX
        //---------------------------------------------

        CopyFMatrix(gOmega,theOmega, \
                    1,gNumberOfEigenFunctions,\
                    1,gNumberOfEigenFunctions);



        LogFMatrix(gOmega,\
                     1,gNumberOfEigenFunctions,\
                     1,gNumberOfEigenFunctions,\
                     "Omega Matrix");


        //---------------------------------------------
        // OMEGA MATRIX DIAGONALIZATION, EIGENVALUES
        //---------------------------------------------

        theDim = gNumberOfEigenFunctions;
        DiagonalizeFMatrix(theOmega,theDim,gEigenValue,gEigenVector);

        //---------------------------------------------
        // DISPLAY OMEGA EIGENVALUES, EIGENVECTORS
        //---------------------------------------------

        LogFVector(gEigenValue,1,theDim,"Omega Matrix -- Eigenvalues");

        // copy current eigenvalues to the Result matrix for print out
        // at end of simulation
        CopyFVectorToMatrixRow(gEigenValue,1,theDim,theOmegaResult,theResultRow);

        LogFMatrix(gEigenVector, \
                     1, theDim, \
                     1, theDim, \
                     "Omega Matrix -- Eigenvectors");


        //---------------------------------------------
        // TEST OMEGA EIGENVECTOR ORTHONORMALITY
        //---------------------------------------------
        theEigenVector_T = matrix(1,theDim, \
                                   1,theDim);

        theMatrixProduct = matrix(1,theDim, \
                                   1,theDim);

        TransposeFMatrix(gEigenVector,theEigenVector_T, \
                         1, theDim, \
                         1, theDim);

        MultiplyFMatrix(gEigenVector,theEigenVector_T, theMatrixProduct,\
                         1, theDim, 1, theDim, \
                         1, theDim, 1, theDim);


        LogFMatrix(theMatrixProduct,\
                     1,gNumberOfEigenFunctions,\
                     1,gNumberOfEigenFunctions,\
                     "Product Matrix (Omega Eigenvectors):  E*E^T");


        //---------------------------------------------
        // TEST MEMBRANE EIGENFUNCTIONS ORTHONORMALITY
        //---------------------------------------------
        theEPMatrix = dmatrix(1,gNumberOfEigenFunctions, \
                    1,gNumberOfEigenFunctions);
        ComputeEPMatrix(theEPMatrix);


        LogDMatrix(theEPMatrix,\
                    1,gNumberOfEigenFunctions,
                    1,gNumberOfEigenFunctions,
                    "Product Matrix (Membrane Eigenfunctions) E*E^T");

        // row index for eigenvalue result matrix
        theResultRow++;

   } // end for loop

   // copy peak defs. (indep. variable) to result matrix, column 0.
   CopyFVectorToMatrixCol(thePeakDefResult,1,theResultRow-1,theOmegaResult,0);



   LogFMatrix(theOmegaResult,\
        1,theResultRow,\
        0,gNumberOfEigenFunctions,\
        "Omega Eigenvalues:  Summary");


   return;
}


//---------------------------------------------------------------------------
// DoGapDistanceVariationExpt
//
// Varies gap distance
// between specified limits, stepping specified amount.  Simulation
// computes Omega matrix eigenvalues for stability determination at
// each value of the membrane peak deformation, as well as ancillary
// test and validation data.  Simulated membrane is deformed to a
// BesselJZero function.  Electrode voltages are computed in a self-
// consistent manner.
//
// called by:  main()
//
// plk 5/31/2005
//---------------------------------------------------------------------------
void DoGapDistanceVariationExpt(double inL_um, double inH_um, double inStep_um)
{
   int theDim;

   float  **theOmegaResult;
   float **theEigenVector_T;
   float   *thePeakDefResult;

   double theGapDist_um;

   int   theResultRow;
   int   theMaxNumberOfSimulations;

   char theMessage[100];




   theDim = gNumberOfEigenFunctions;
   theMaxNumberOfSimulations = 200;

   theOmegaResult = matrix(0,theMaxNumberOfSimulations, \
                    0,gNumberOfEigenFunctions);
   thePeakDefResult = vector(0,theMaxNumberOfSimulations);

   LogMessage("--- Begin Gap Distance Simulation --- ");

   theResultRow = 1;
   for (theGapDist_um=inL_um;theGapDist_um<=inH_um;theGapDist_um+=inStep_um)
   {

        // store peak defs for print out to result matrix
        thePeakDefResult[theResultRow] = theGapDist_um;



        // set global variables of the current simulation
        gDistT_um = theGapDist_um;
        gDistA_um = theGapDist_um;

        sprintf(theMessage,"Gap Distance:  %7.2f um\n",theGapDist_um);
        LogMessage(theMessage);

        SetMembraneShape_Eigenfunc(1,2.5E-8);
        LogSimParams();

        DoDeviceStabilityAnalysis();

        // copy current eigenvalues to the Result
        // matrix for print out at end of simulation
        CopyFVectorToMatrixRow(gEigenValue,1,theDim,theOmegaResult,theResultRow);

        // row index for eigenvalue result matrix
        theResultRow++;

   }

   // copy peak defs. (indep. variable) to result matrix, column 0.
   CopyFVectorToMatrixCol(thePeakDefResult,1,theResultRow-1,theOmegaResult,0);



   LogFMatrix(theOmegaResult,\
        1,theResultRow,\
        0,gNumberOfEigenFunctions,\
        "Omega Eigenvalues:  Summary");


   return;
}




//---------------------------------------------------------------------------
// DoEigenfuncAmplVariationExpt
//
// Varies peak deformation
// between specified limits, stepping specified amount.  Simulation
// computes Omega matrix eigenvalues for stability determination at
// each value of the membrane peak deformation, as well as ancillary
// test and validation data.  Simulated membrane is deformed to a
// BesselJZero function.  Electrode voltages are computed in a self-
// consistent manner.
//
// called by:  main()
//
// plk 3/29/2005
//---------------------------------------------------------------------------
void DoEigenfuncAmplVariationExpt(int inJ, double inL_um, double inH_um, double inStep_um)
{
   int theDim;

   float **theOmega;
   double **theMatrixA;
   double **theMatrixASum;
   float  **theOmegaResult;
   float **theEigenVector_T;
   float **theMatrixProduct;
   float **theSimilarMatrix;
   double **theEPMatrix;
   float   *thePeakDefResult;

   double theCoeffValue_units;

   int   theResultRow;
   int   theMaxNumberOfSimulations;

   char theMessage[100];


   LogMessage("--- Begin EigenfuncAmplVariationExpt --- ");


   theOmega = matrix(1,gNumberOfEigenFunctions, \
                    1,gNumberOfEigenFunctions);
   theMatrixA = dmatrix(0,gNumberOfEigenFunctions-1, \
                    0,gNumberOfEigenFunctions-1);
   theMatrixASum = dmatrix(0,gNumberOfEigenFunctions-1, \
                    0,gNumberOfEigenFunctions-1);


   theMaxNumberOfSimulations = 200;
   theOmegaResult = matrix(0,theMaxNumberOfSimulations, \
                    0,gNumberOfEigenFunctions);
   thePeakDefResult = vector(0,theMaxNumberOfSimulations);


   theResultRow = 1;
   for (theCoeffValue_units=inL_um;
        theCoeffValue_units<=inH_um;
        theCoeffValue_units+=inStep_um)
   {


        // store peak defs for print out to result matrix
        thePeakDefResult[theResultRow] = theCoeffValue_units;

        sprintf(theMessage,"Eigenfunction J=%d Value:  %7.2f um\n", \
                inJ, theCoeffValue_units);
        LogMessage(theMessage);

        SetMembraneShape_Eigenfunc(inJ,theCoeffValue_units);
        ComputeElectrodeVoltage();


        //---------------------------------------------
        // PRINT, LOG ELECTRODE MAP...ALL VOLTAGES
        //---------------------------------------------
        LogFMatrix(gElectrodeVoltageMap, \
                    0,gMapDim-1,\
                    0,gMapDim-1,\
                    "Electrode Voltage Map");

        //---------------------------------------------
        // PRINT, LOG MEMBRANE SHAPE:  RADIAL FN.
        //---------------------------------------------

        TestMembraneExpansion(0,0.0075,25);


        //---------------------------------------------
        // OMEGA, MATRIXA GENERATION
        //---------------------------------------------

        ComputeOmegaMatrix(gOmega);
        ComputeMatrixASum(theMatrixASum);

        //---------------------------------------------
        // PRINT, LOG MATRIXA: DISCRETE VERSION
        //---------------------------------------------
        LogDMatrix(theMatrixASum,\
                     0,gNumberOfEigenFunctions-1,\
                     0,gNumberOfEigenFunctions-1,\
                     "MatrixASum (discr.)");


        //---------------------------------------------
        // PRINT, LOG OMEGA MATRIX
        //---------------------------------------------

        CopyFMatrix(gOmega,theOmega, \
                    1,gNumberOfEigenFunctions,\
                    1,gNumberOfEigenFunctions);



        LogFMatrix(gOmega,\
                     1,gNumberOfEigenFunctions,\
                     1,gNumberOfEigenFunctions,\
                     "Omega Matrix");


        //---------------------------------------------
        // OMEGA MATRIX DIAGONALIZATION, EIGENVALUES
        //---------------------------------------------

        theDim = gNumberOfEigenFunctions;
        DiagonalizeFMatrix(theOmega,theDim,gEigenValue,gEigenVector);

        //---------------------------------------------
        // DISPLAY OMEGA EIGENVALUES, EIGENVECTORS
        //---------------------------------------------

        LogFVector(gEigenValue,1,theDim,"Omega Matrix -- Eigenvalues");

        // copy current eigenvalues to the Result matrix for print out
        // at end of simulation
        CopyFVectorToMatrixRow(gEigenValue,1,theDim,theOmegaResult,theResultRow);

        LogFMatrix(gEigenVector, \
                     1, theDim, \
                     1, theDim, \
                     "Omega Matrix -- Eigenvectors");


        //---------------------------------------------
        // TEST OMEGA EIGENVECTOR ORTHONORMALITY
        //---------------------------------------------
        theEigenVector_T = matrix(1,theDim, \
                                   1,theDim);

        theMatrixProduct = matrix(1,theDim, \
                                   1,theDim);

        TransposeFMatrix(gEigenVector,theEigenVector_T, \
                         1, theDim, \
                         1, theDim);

        MultiplyFMatrix(gEigenVector,theEigenVector_T, theMatrixProduct,\
                         1, theDim, 1, theDim, \
                         1, theDim, 1, theDim);


        LogFMatrix(theMatrixProduct,\
                     1,gNumberOfEigenFunctions,\
                     1,gNumberOfEigenFunctions,\
                     "Product Matrix (Omega Eigenvectors):  E*E^T");


        //---------------------------------------------
        // TEST MEMBRANE EIGENFUNCTIONS ORTHONORMALITY
        //---------------------------------------------
        theEPMatrix = dmatrix(1,gNumberOfEigenFunctions, \
                    1,gNumberOfEigenFunctions);
        ComputeEPMatrix(theEPMatrix);


        LogDMatrix(theEPMatrix,\
                    1,gNumberOfEigenFunctions,
                    1,gNumberOfEigenFunctions,
                    "Product Matrix (Membrane Eigenfunctions) E*E^T");

        // row index for eigenvalue result matrix
        theResultRow++;

   } // end for loop

   // copy peak defs. (indep. variable) to result matrix, column 0.
   CopyFVectorToMatrixCol(thePeakDefResult,1,theResultRow-1,theOmegaResult,0);



   LogFMatrix(theOmegaResult,\
        1,theResultRow,\
        0,gNumberOfEigenFunctions,\
        "Omega Eigenvalues:  Summary");


   return;
}










//---------------------------------------------------------------------------
// DoDeviceStabilityAnalysis()
//
// Performs stability analysis on the current device & parameters.  Parameters
// are stored as global variables.  Output of stability analysis, as well
// as various checks for consistency & validity are output to the logfile.txt
//
// called by:  DoGapDistanceVariationExpt()
//
// plk 5/31/2005
//---------------------------------------------------------------------------

void DoDeviceStabilityAnalysis()
{
   int theDim;

   float **theOmega;
   double **theMatrixA;
   double **theMatrixASum;
   float **theEigenVector_T;
   float **theMatrixProduct;
   float **theSimilarMatrix;
   double **theEPMatrix;

   char theMessage[100];



   theOmega = matrix(1,gNumberOfEigenFunctions, \
                    1,gNumberOfEigenFunctions);
   theMatrixA = dmatrix(0,gNumberOfEigenFunctions-1, \
                    0,gNumberOfEigenFunctions-1);
   theMatrixASum = dmatrix(0,gNumberOfEigenFunctions-1, \
                    0,gNumberOfEigenFunctions-1);


        // NOTE:  Membrane shape must be set in calling routine.
        ComputeElectrodeVoltage();


        //---------------------------------------------
        // PRINT, LOG ELECTRODE MAP...ALL VOLTAGES
        //---------------------------------------------
        LogFMatrix(gElectrodeVoltageMap, \
                    0,gMapDim-1,\
                    0,gMapDim-1,\
                    "Electrode Voltage Map");

        //---------------------------------------------
        // PRINT, LOG MEMBRANE SHAPE:  RADIAL FN.
        //---------------------------------------------

        TestMembraneExpansion(0,0.0075,25);


        //---------------------------------------------
        // OMEGA, MATRIXA GENERATION
        //---------------------------------------------

        ComputeOmegaMatrix(gOmega);
        ComputeMatrixASum(theMatrixASum);

        //---------------------------------------------
        // PRINT, LOG MATRIXA: DISCRETE VERSION
        //---------------------------------------------
        LogDMatrix(theMatrixASum,\
                     0,gNumberOfEigenFunctions-1,\
                     0,gNumberOfEigenFunctions-1,\
                     "MatrixASum (discr.)");


        //---------------------------------------------
        // PRINT, LOG OMEGA MATRIX
        //---------------------------------------------

        CopyFMatrix(gOmega,theOmega, \
                    1,gNumberOfEigenFunctions,\
                    1,gNumberOfEigenFunctions);



        LogFMatrix(gOmega,\
                     1,gNumberOfEigenFunctions,\
                     1,gNumberOfEigenFunctions,\
                     "Omega Matrix");


        //---------------------------------------------
        // OMEGA MATRIX DIAGONALIZATION, EIGENVALUES
        //---------------------------------------------

        theDim = gNumberOfEigenFunctions;
        DiagonalizeFMatrix(theOmega,theDim,gEigenValue,gEigenVector);

        //---------------------------------------------
        // DISPLAY OMEGA EIGENVALUES, EIGENVECTORS
        //---------------------------------------------

        LogFVector(gEigenValue,1,theDim,"Omega Matrix -- Eigenvalues");


        LogFMatrix(gEigenVector, \
                     1, theDim, \
                     1, theDim, \
                     "Omega Matrix -- Eigenvectors");


        //---------------------------------------------
        // TEST OMEGA EIGENVECTOR ORTHONORMALITY
        //---------------------------------------------
        theEigenVector_T = matrix(1,theDim, \
                                   1,theDim);

        theMatrixProduct = matrix(1,theDim, \
                                   1,theDim);

        TransposeFMatrix(gEigenVector,theEigenVector_T, \
                         1, theDim, \
                         1, theDim);

        MultiplyFMatrix(gEigenVector,theEigenVector_T, theMatrixProduct,\
                         1, theDim, 1, theDim, \
                         1, theDim, 1, theDim);


        LogFMatrix(theMatrixProduct,\
                     1,gNumberOfEigenFunctions,\
                     1,gNumberOfEigenFunctions,\
                     "Product Matrix (Omega Eigenvectors):  E*E^T");


        //---------------------------------------------
        // TEST MEMBRANE EIGENFUNCTIONS ORTHONORMALITY
        //---------------------------------------------
        theEPMatrix = dmatrix(1,gNumberOfEigenFunctions, \
                    1,gNumberOfEigenFunctions);
        ComputeEPMatrix(theEPMatrix);


        LogDMatrix(theEPMatrix,\
                    1,gNumberOfEigenFunctions,
                    1,gNumberOfEigenFunctions,
                    "Product Matrix (Membrane Eigenfunctions) E*E^T");


}




