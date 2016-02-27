//---------------------------------------------------------------------------
#include "ComputeOmegaMatrix.h"
#include "MatrixA.h"
#include "BesselJZeros.h"
#include "Eigenfunc.h"
#include "Membrane.h"
#include "NR.h"

#include <stdio.h>
#include <conio.h>
#include <math.h>



#pragma hdrstop

//---------------------------------------------------------------------------



#pragma argsused
int main(int argc, char* argv[])
{
        int theDim;
        int theIndex;
        float theR;
        float thePhi;
        float theMagn;
        float thePhase;

        float **theOmega;

        float **theEigenVector_T;
        float **theMatrixProduct;
        float **theSimilarMatrix;
        double **theEPMatrix;

        int theN, theV, theJ;
        float theX_vn;

        float theRL, theRH;
        int theNum;


#if 0

        //---------------------------------------------
        // OMEGA MATRIX GENERATION
        //---------------------------------------------


        theOmega = matrix(1,gNumberOfEigenFunctions, \
                    1,gNumberOfEigenFunctions);

        gOmega = matrix(1,gNumberOfEigenFunctions, \
                    1,gNumberOfEigenFunctions);

        gEigenValue = vector(1,gNumberOfEigenFunctions);

        gEigenVector = matrix(1,gNumberOfEigenFunctions, \
                    1,gNumberOfEigenFunctions);


        ComputeOmegaMatrix(gOmega);

#endif

#if 0

        //---------------------------------------------
        // OMEGA MATRIX FOR TEST DIAGONALIZATION:   2x2
        //---------------------------------------------

        gNumberOfEigenFunctions = 2;

        gEigenValue = vector(1,gNumberOfEigenFunctions);
        gEigenVector = matrix(1,gNumberOfEigenFunctions, \
                    1,gNumberOfEigenFunctions);


        theOmega = matrix(1,gNumberOfEigenFunctions, \
                    1,gNumberOfEigenFunctions);

        gOmega = matrix(1,gNumberOfEigenFunctions, \
                    1,gNumberOfEigenFunctions);


        gOmega[1][1] = 1.0;
        gOmega[1][2] = 1.0;

        gOmega[2][1] = 1.0;
        gOmega[2][2] = 1.0;

        //---------------------------------------------
        // Eigenvalues of this matrix are:  0,2
        //
        // Eigenvectors of this matrix are:
        // x_l=0  =  1/sqrt(2)     x_l=2    1/sqrt(2)
        //          -1/sqrt(2)              1/sqrt(2)
        //
        //---------------------------------------------

#endif


#if 0

        //---------------------------------------------
        // OMEGA MATRIX FOR TEST DIAGONALIZATION:   3x3
        //---------------------------------------------

        gNumberOfEigenFunctions = 3;

        theOmega = matrix(1,gNumberOfEigenFunctions, \
                    1,gNumberOfEigenFunctions);

        gOmega = matrix(1,gNumberOfEigenFunctions, \
                    1,gNumberOfEigenFunctions);

        gEigenValue = vector(1,gNumberOfEigenFunctions);
        gEigenVector = matrix(1,gNumberOfEigenFunctions, \
                    1,gNumberOfEigenFunctions);


        gOmega[1][1] = 3.0;
        gOmega[1][2] = 4.0;
        gOmega[1][3] = -1.0;

        gOmega[2][1] = 4.0;
        gOmega[2][2] = 3.0;
        gOmega[2][3] = 1.0;

        gOmega[3][1] = -1.0;
        gOmega[3][2] = 1.0;
        gOmega[3][3] = 1.0;

        //---------------------------------------------
        // Eigenvalues of this matrix are:
        //  L1 = 7, L2 = sqrt(3), L3 = -sqrt(3)
        //
        //  where sqrt(3) = 1.732
        //
        // Eigenvectors of this matrix are:
        // x_L1  =  0.707  x_L2 = -0.325  x_L3 =  0.628
        //          0.707          0.325         -0.628
        //          0.000          0.888          0.460
        //
        //---------------------------------------------

#endif


#if 0

        //---------------------------------------------
        // OMEGA MATRIX DIAGONALIZATION, EIGENVALUES
        //---------------------------------------------


        CopyDMatrix(gOmega,theOmega, \
                    1,gNumberOfEigenFunctions,\
                    1,gNumberOfEigenFunctions);


        printf("gOmega Matrix:\n");
        PrintDMatrix(gOmega,\
                     1,gNumberOfEigenFunctions,\
                     1,gNumberOfEigenFunctions);


        SaveDMatrix(gOmega,\
                    1,gNumberOfEigenFunctions,
                    1,gNumberOfEigenFunctions,
                    "OmegaMatrix.txt");


        theDim = gNumberOfEigenFunctions;
        DiagonalizeMatrix(theOmega,theDim,gEigenValue,gEigenVector);

        //---------------------------------------------
        // DISPLAY OMEGA EIGENVALUES, EIGENVECTORS
        //---------------------------------------------

        printf("\nOmega Matrix -- Eigenvalues:\n");
        PrintDVector(gEigenValue,1,theDim);

        printf("\nOmega Matrix -- Eigenvectors:\n");
        PrintDMatrix(gEigenVector, \
                     1, theDim, \
                     1, theDim);

#endif

#if 0

        //---------------------------------------------
        // TEST OMEGA EIGENVECTOR ORTHONORMALITY
        //---------------------------------------------
        theEigenVector_T = matrix(1,theDim, \
                                   1,theDim);

        theMatrixProduct = matrix(1,theDim, \
                                   1,theDim);

        TransposeDMatrix(gEigenVector,theEigenVector_T, \
                         1, theDim, \
                         1, theDim);

        MultiplyDMatrix(gEigenVector,theEigenVector_T, theMatrixProduct,\
                         1, theDim, 1, theDim, \
                         1, theDim, 1, theDim);

        printf("Product Matrix (Omega Eigenvectors):  E*E^T\n\n");
        PrintDMatrix(theMatrixProduct, \
                     1, theDim, \
                     1, theDim);

#endif

#if 0
        //---------------------------------------------
        // TEST BESSEL FUNCTION ZERO LOOKUP TABLE
        //---------------------------------------------

        // look up a zero of a Bessel Function;
        // print the result.
        theV=4;
        theN=5;
        theJ=BesselJIndex(theV, theN);
        theX_vn=BesselJZero(theJ);
        printf("theX_vn = %4.3f\n",theX_vn);
#endif


#if 0
        //---------------------------------------------
        // TEST MEMBRANE EIGENFUNCTION GENERATION
        //---------------------------------------------

        // Evaluate a particular eigenfunction, indexed
        // by its j-value, at a specified r, phi coordinates.
        theIndex=2;
        theR=0.002;
        thePhi=0;
        Eigenfunc(theIndex,theR,thePhi,&theMagn,&thePhase);
        printf("theMagn = %4.2f\n",theMagn);

#endif

#if 1
        //---------------------------------------------
        // TEST MEMBRANE EIGENFUNCTIONS ORTHONORMALITY
        //---------------------------------------------
        theEPMatrix = dmatrix(1,gNumberOfEigenFunctions, \
                    1,gNumberOfEigenFunctions);
        ComputeEPMatrix(theEPMatrix);

        printf("EigenProduct Matrix:\n");
        PrintDoubleMatrix(theEPMatrix,\
                     1,gNumberOfEigenFunctions,\
                     1,gNumberOfEigenFunctions);


        SaveDoubleMatrix(theEPMatrix,\
                    1,gNumberOfEigenFunctions,
                    1,gNumberOfEigenFunctions,
                    "EigenProductMatrix.txt");
#endif

#if 0
        //---------------------------------------------
        // TEST MEMBRANE EIGENFUNCTIONS OVER A RANGE
        //---------------------------------------------

        // print out, save a particular eigenfunction,
        // indexed by its j-value.
        theIndex=3;
        thePhi=0.0;
        theRL=0.0;
        theRH=0.0080;
        theNum=20;
        PrintEigenfuncR(theIndex,theRL,theRH,thePhi,theNum);
        SaveEigenfuncR(theIndex,theRL,theRH,thePhi,theNum);
#endif

#if 0
        //-----------------------------------------------
        // TEST MEMBRANE SHAPE FN, MATRIX ELEM. INTEGRAND
        //-----------------------------------------------

        // print out membrane deformation for various values
        // of independent variable.
        theRL=0;
        theRH=(gMembraneRadius_mm+0.10*gMembraneRadius_mm)*1e-3;
        printf("r, mm\t\tdeformation, um\tWeightFn, MKS\tR-Integrand\n");
        for (theR=theRL; theR<=theRH; theR+=theRH/20)
        {
             printf("%f\t%f\t%f\t%f\n",\
                        theR*1e3,\
                        ParabolicDeformation_MKS(theR)*1e6, \
                        WeightFn_MKS(theR), \
                        AIntegrandRF(theR) );
        }
#endif

        printf("\nDone!\n");
        while (!kbhit());
        getch();
        return 0;
}
//---------------------------------------------------------------------------



//---------------------------------------------------------------------------
// ComputeOmegaMatrix
//
// The Omega matrix is defined in the formal stability calculation write
// up as the matrix in the second variation of the energy equation.  This
// matrix is diagonalized and/or its eigenvalues approximated to ascertain
// the stability of the membrane configuration.
//                         X_j
//   Omega_jj'     =   T  ----- Delta_jj'  -  A_jj'
//                         R^2
//
//  T = membrane tension; X_j = Zero_J of Bessel function (See BesselJZeros.h)
//  Delta_ij = Kronecker Delta, A_ij = Matrix Element (See MatrixA.h)
//
// plk 3/10/2005
//---------------------------------------------------------------------------
void ComputeOmegaMatrix(float **outOmega)
{
   int i,j;
   int ii,jj;
   float theDiag_MKS;
   float theTen_MKS;
   float theRad_MKS;

   theTen_MKS = gMembraneTension_NByM;
   theRad_MKS = gMembraneRadius_mm * 1e-3;


   // realMatrixA is indexed 0...N-1, but gOmega must
   // be indexed 1...N for later NR routines.  Therefore
   // use i-->ii; j-->jj indices to remap this matrix.
   for(ii=1;ii<=gNumberOfEigenFunctions;ii++)
   {
        for(jj=1;jj<=gNumberOfEigenFunctions;jj++)
        {
           //DEBUG
           //printf("ComputeOmegaMatrix: Omega[%d][%d]\n\n",i,j);
           i=ii-1;
           j=jj-1;
           theDiag_MKS = \
             theTen_MKS*BesselJZero(j)*BesselJZero(j)/(theRad_MKS*theRad_MKS);

           outOmega[ii][jj] = theDiag_MKS*KroneckerDelta(i,j) - \
                              RealMatrixA(i,j);
        }
   }

}


//---------------------------------------------------------------------------
// DiagonalizeMatrix
//
// Diagonalize a real, symmetric matrix of dimension [1...inDim] by
// computing the eigenvalues and eigenvectors.
//
// Input matrix is destroyed by this routine.
//
// Eigenvalues are sorted in descending order, and stored in output
// array; corresponding Eigenvectors are stored in an output matrix.
// Output arrays must be allocated to the proper dimension prior to
// calling this routine, arrays are addressed using NR convention
// [1...N].
//
// This procedure uses either Jacobi rotation or QL reduction to
// compute the eigenvalues/eigenvectors.  Comment out the appropriate
// section of code for the un-favored algorithm.
//
// plk 3/10/2005
//---------------------------------------------------------------------------
void DiagonalizeMatrix(float **inMatrix, \
                       int inDim, \
                       float *outEigenValue, \
                       float **outEigenVector)
{
   int nrot;
   float *theE;



   //-----------------------------------------------------------
   // Jacobi rotation algorithm
   //
   //jacobi(inMatrix,inDim,outEigenValue,outEigenVector,&nrot);
   //eigsrt(outEigenValue,outEigenVector,inDim);
   //-----------------------------------------------------------


   //-----------------------------------------------------------
   // QL reduction algorithm
   //
   theE = vector(1,inDim);
   tred2(inMatrix, inDim, outEigenValue, theE);
   tqli(outEigenValue,theE,inDim,inMatrix);
   CopyDMatrix(inMatrix,outEigenVector,\
                1,inDim,\
                1,inDim);
   //----------------------------------------------------------


}



float KroneckerDelta(int i, int j)
{
  if (i==j) return 1;
  else return 0;
}



void PrintDMatrix(float **inMatrix,
                  int inRL,
                  int inRH,
                  int inCL,
                  int inCH)
{

   int i,j;


   printf("\n");
   for(i=inRL;i<=inRH;i++)
   {
        for(j=inCL;j<=inCH;j++)
        {
             printf("%7.3f\t",inMatrix[i][j]);
        }
        printf("\n");
   }
   printf("\n");

}


void PrintDoubleMatrix(double **inMatrix,
                  int inRL,
                  int inRH,
                  int inCL,
                  int inCH)
{

   int i,j;


   printf("\n");
   for(i=inRL;i<=inRH;i++)
   {
        for(j=inCL;j<=inCH;j++)
        {
             printf("%7.3f\t",inMatrix[i][j]);
        }
        printf("\n");
   }
   printf("\n");

}


void CopyDMatrix(float **inSource, float **outTarget, \
                  int inRL,
                  int inRH,
                  int inCL,
                  int inCH)
{

   int i,j;

   for(i=inRL;i<=inRH;i++)
   {
        for(j=inCL;j<=inCH;j++)
        {
             outTarget[i][j]=inSource[i][j];
        }
   }

}


TransposeDMatrix(float **inSource, float **outTarget, \
                  int inRL,
                  int inRH,
                  int inCL,
                  int inCH)
{

   int i,j;

   for(i=inRL;i<=inRH;i++)
   {
        for(j=inCL;j<=inCH;j++)
        {
             outTarget[j][i]=inSource[i][j];
        }
   }

}


MultiplyDMatrix(float **inA, float **inB, float **outResult, \
                  int inRLA, int inRHA, int inCLA, int inCHA, \
                  int inRLB, int inRHB, int inCLB, int inCHB)
{

   int i,j,k;

   if ((inCHA-inCLA) != (inRHB-inRLB))
        nrerror("Error in MultiplyDMatrix:  Incompatible matrices");

   for(i=inRLA;i<=inRHA;i++)
   {
        for(j=inCLB;j<=inCHB;j++)
        {
           outResult[i][j]=0;
           for (k=inCLA;k<=inCHA;k++)
           {
             outResult[i][j]+=inA[i][k]*inB[k][j];
           }
        }
   }

}

void PrintDVector(float *inVector, int inRL, int inRH)
{

   int i;
   printf("\n");
   for(i=inRL;i<=inRH;i++)
   {
        printf("%f\n",inVector[i]);
   }
   printf("\n");

}



void SaveDMatrix(float **inMatrix,\
                 int inRL, int inRH, \
                 int inCL, int inCH, \
                 char *inFileName)
{
   int i,j;

   FILE *theSaveFile;


   if ((theSaveFile = fopen(inFileName, "wt")) == NULL)
   {
      fprintf(stderr, "SaveDMatrix: Cannot open output file.\n");
      return;
   }

   fprintf(theSaveFile,"\n");
   for(i=inRL;i<=inRH;i++)
   {
        for(j=inCL;j<=inCH;j++)
        {
             fprintf(theSaveFile, "%f\t",inMatrix[i][j]);
        }
        fprintf(theSaveFile, "\n");
   }
   fprintf(theSaveFile,"\n");

   fprintf(stderr, "\nSaveDMatrix: Saved data to file %s.\n\n", inFileName);
   fclose(theSaveFile);

}



void SaveDoubleMatrix(double **inMatrix,\
                 int inRL, int inRH, \
                 int inCL, int inCH, \
                 char *inFileName)
{
   int i,j;

   FILE *theSaveFile;


   if ((theSaveFile = fopen(inFileName, "wt")) == NULL)
   {
      fprintf(stderr, "SaveDoubleMatrix: Cannot open output file.\n");
      return;
   }

   fprintf(theSaveFile,"\n");
   for(i=inRL;i<=inRH;i++)
   {
        for(j=inCL;j<=inCH;j++)
        {
             fprintf(theSaveFile, "%f\t",inMatrix[i][j]);
        }
        fprintf(theSaveFile, "\n");
   }
   fprintf(theSaveFile,"\n");

   fprintf(stderr, "\nSaveDoubleMatrix: Saved data to file %s.\n\n", inFileName);
   fclose(theSaveFile);

}

