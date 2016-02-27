//---------------------------------------------------------------------------
// ComputeOmegaMatrix.c
//
// Computes Omega Matrix and its eigenvalues & eigenvectors to determine
// the stability of a particular membrane configuration.  See Formal
// Stability Calculation write-up.
//
// plk 03/16/2005
//---------------------------------------------------------------------------
#include "ComputeOmegaMatrix.h"
#include "BesselJZeros.h"
#include "MatrixUtils.h"
#include "MatrixA.h"
#include "Eigenfunc.h"
#include "Membrane.h"
#include "NR.h"
#include "NRUTIL.H"

#include <stdio.h>
#include <conio.h>
#include <math.h>


float **gOmega;
float **gEigenVector;
float  *gEigenValue;

extern double gMembraneTension_NByM;      // tension = stress * thickness
extern double gMembraneRadius_mm;
extern int gNumberOfEigenFunctions;

extern double **gMatrixA;

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
// NOTE:  Must call procedure ComputegMatrixASum() prior to calling this
// procedure!!
//
// plk 4/18/2005
//---------------------------------------------------------------------------
void ComputeOmegaMatrix()
{
   int i,j;
   int ii,jj;
   float theDiag_MKS;
   float theTen_MKS;
   float theRad_MKS;
   float theMatrixA;


   gOmega = matrix(1,gNumberOfEigenFunctions, \
                    1,gNumberOfEigenFunctions);
   gEigenValue = vector(1,gNumberOfEigenFunctions);
   gEigenVector = matrix(1,gNumberOfEigenFunctions, \
                    1,gNumberOfEigenFunctions);



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

           // Compute matrix A elements using continuous functions,
           // numerical integration.
           // theMatrixA = (float) RealMatrixA(i,j);

           // Compute matrix A elements using summation over electrodes
           // of the electrode array.
            theMatrixA = (float) RealMatrixASum(i,j);

           // Use previously computed value of MatrixA.  See
           // ComputegMatrixASum() for method of computation.
           //theMatrixA = (float) gMatrixA[i][j];

           gOmega[ii][jj] = theDiag_MKS*KroneckerDelta(i,j) - theMatrixA;
        }
   }

   
   return;
}







float KroneckerDelta(int i, int j)
{
  if (i==j) return 1;
  else return 0;
}





