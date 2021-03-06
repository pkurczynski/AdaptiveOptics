//---------------------------------------------------------------------------
// MatrixUtils.c
//
// plk 03/13/2005
//---------------------------------------------------------------------------
#include <time.h>
#include <stdio.h>
#include <dos.h>
#include "MatrixUtils.h"
#include "Membrane.h"
#include "MatrixA.h"
#include "Eigenfunc.h"
#include "NR.h"
#include "NRUTIL.H"

char gLogFileName[] = "LogFile.txt";

extern double gMembraneStress_MPa;
extern double gMembraneThickness_um;
extern double gMembraneTension_NByM;      // tension = stress * thickness
extern double gMembraneRadius_mm;


extern double gVoltageT_V;    // Transp. electrode voltage
extern double gVoltageA_V;    // Array electrode voltage
extern double gDistT_um;      // Transp. electr -- membr. dist.
extern double gDistA_um;      // Electr. array -- membr. dist.

extern double gPeakDeformation_um;
extern double gEPS;           //fractional accuracy of integration

extern int gNumberOfEigenFunctions;







void OpenLogFile()
{
  time_t timer;
  struct tm *tblock;

  FILE *theLogFilePtr;

  if ((theLogFilePtr = fopen(gLogFileName, "wt")) == NULL)
   {
      fprintf(stderr, "OpenLogFile -- Cannot open output file.\n");
      return;
   }

   /* gets time of day */
   timer = time(NULL);

   /* converts date/time to a structure */
   tblock = localtime(&timer);

   fprintf(theLogFilePtr,"Run time: %s\n", asctime(tblock));
   printf("OpenLogFile: -- wrote to file %s\n",gLogFileName);
   fclose(theLogFilePtr);
}




void LogMessage(char *inMessage)
{

   FILE *theLogFilePtr;

   if ((theLogFilePtr = fopen(gLogFileName, "at")) == NULL)
   {
      fprintf(stderr, "LogMessage -- Cannot open output file.\n");
      return;
   }
   fprintf(theLogFilePtr,"%s\n",inMessage);
   printf("LogMessage: %s\n",inMessage);

   fclose(theLogFilePtr);
}




void LogSimParams()
{
  FILE *theLogFilePtr;

  if ((theLogFilePtr = fopen(gLogFileName, "at")) == NULL)
  {
      fprintf(stderr, "LogSimParams -- Cannot open output file.\n");
      return;
  }

   fprintf(theLogFilePtr,"gMembraneStress_MPa     \t%f\n",\
        gMembraneStress_MPa );
   fprintf(theLogFilePtr,"gMembraneThickness_um   \t%f\n",\
        gMembraneThickness_um );
   fprintf(theLogFilePtr,"gMembraneTension_NByM   \t%f\n",\
        gMembraneTension_NByM );
   fprintf(theLogFilePtr,"gMembraneRadius_mm      \t%f\n",\
        gMembraneRadius_mm );
   fprintf(theLogFilePtr,"gVoltageT_V             \t%f\n",\
        gVoltageT_V );
   fprintf(theLogFilePtr,"gVoltageA_V             \t%f\n",\
        gVoltageA_V );
   fprintf(theLogFilePtr,"gDistT_um               \t%f\n",\
        gDistT_um );
   fprintf(theLogFilePtr,"gDistA_um               \t%f\n",\
        gDistA_um  );
   fprintf(theLogFilePtr,"gPeakDeformation_um     \t%f\n",\
        gPeakDeformation_um );


   fprintf(theLogFilePtr,"gEPS                    \t%f\n",gEPS  );


   fprintf(theLogFilePtr,"gNumberOfEigenFunctions \t%d\n",\
        gNumberOfEigenFunctions );

   fprintf(theLogFilePtr,"\n");



   printf("LogSimParams: -- wrote to file %s\n",gLogFileName);
   fclose(theLogFilePtr);
}




void LogFMatrix(float **inMatrix,
                  int inRL,
                  int inRH,
                  int inCL,
                  int inCH,
                char *inMessage)
{
   int i,j;
   FILE *theLogFilePtr;

   if ((theLogFilePtr = fopen(gLogFileName, "at")) == NULL)
   {
      fprintf(stderr, "LogFMatrix -- Cannot open output file.\n");
      return;
   }


   fprintf(theLogFilePtr,"%s\n",inMessage);
   for(i=inRL;i<=inRH;i++)
   {
        for(j=inCL;j<=inCH;j++)
        {
             fprintf(theLogFilePtr,"%7.8f\t",inMatrix[i][j]);
        }
        fprintf(theLogFilePtr,"\n");
   }
   fprintf(theLogFilePtr,"\n");
   fclose(theLogFilePtr);

   printf("%s\n",inMessage);
   PrintFMatrix(inMatrix,inRL,inRH,inCL,inCH);
   printf("LogFMatrix: -- wrote to file %s\n",gLogFileName);

}


void LogFVector(float *inVector,
                int inRL,
                int inRH,
                char *inMessage)
{
   int i;
   FILE *theLogFilePtr;

   if ((theLogFilePtr = fopen(gLogFileName, "at")) == NULL)
   {
      fprintf(stderr, "LogFVector -- Cannot open output file.\n");
      return;
   }


   fprintf(theLogFilePtr,"%s\n",inMessage);

   fprintf(theLogFilePtr,"\n");
   for(i=inRL;i<=inRH;i++)
   {
        fprintf(theLogFilePtr,"%f\n",inVector[i]);
   }
   fprintf(theLogFilePtr,"\n");
   fclose(theLogFilePtr);

   printf("%s\n",inMessage);
   PrintFVector(inVector,inRL,inRH);

   printf("LogFVector: -- wrote to file %s\n",gLogFileName);


}



void LogDVector(double *inVector,
                int inRL,
                int inRH,
                char *inMessage)
{
   int i;
   FILE *theLogFilePtr;

   if ((theLogFilePtr = fopen(gLogFileName, "at")) == NULL)
   {
      fprintf(stderr, "LogDVector -- Cannot open output file.\n");
      return;
   }


   fprintf(theLogFilePtr,"%s\n",inMessage);

   fprintf(theLogFilePtr,"\n");
   for(i=inRL;i<=inRH;i++)
   {
        fprintf(theLogFilePtr,"%1.9f\n",inVector[i]);
   }
   fprintf(theLogFilePtr,"\n");
   fclose(theLogFilePtr);

   printf("%s\n",inMessage);
   PrintDVector(inVector,inRL,inRH);
   printf("LogDVector: -- wrote to file %s\n",gLogFileName);


}


void LogDMatrix(double **inMatrix,
                  int inRL,
                  int inRH,
                  int inCL,
                  int inCH,
                char *inMessage)
{
   int i,j;
   FILE *theLogFilePtr;

   if ((theLogFilePtr = fopen(gLogFileName, "at")) == NULL)
   {
      fprintf(stderr, "LogDMatrix -- Cannot open output file.\n");
      return;
   }


   fprintf(theLogFilePtr,"%s\n",inMessage);
   for(i=inRL;i<=inRH;i++)
   {
        for(j=inCL;j<=inCH;j++)
        {
             fprintf(theLogFilePtr,"%7.3f\t",inMatrix[i][j]);
        }
        fprintf(theLogFilePtr,"\n");
   }
   fprintf(theLogFilePtr,"\n");
   fclose(theLogFilePtr);

   printf("%s\n",inMessage);
   PrintDMatrix(inMatrix,inRL,inRH,inCL,inCH);
   printf("LogDMatrix: -- wrote to file %s\n",gLogFileName);

}



//---------------------------------------------------------------------------
// CopyFVectorToMatrixRow
//
// writes an FVector to a specified row of a Matrix
//
//---------------------------------------------------------------------------
CopyFVectorToMatrixRow(float *inVector, \
                    int inRL, \
                    int inRH, \
                    float **inMatrix, \
                    int inRow)
{

   int i;

   for(i=inRL;i<=inRH;i++)
   {
        inMatrix[inRow][i]=inVector[i];
   }

}


CopyFVectorToMatrixCol(float *inVector, \
                    int inRL, \
                    int inRH, \
                    float **inMatrix, \
                    int inCol)
{

   int i;

   for(i=inRL;i<=inRH;i++)
   {
        inMatrix[i][inCol]=inVector[i];
   }

}


void PrintFMatrix(float **inMatrix,
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
             printf("%7.5f\t",inMatrix[i][j]);
        }
        printf("\n");
   }
   printf("\n");

}


void PrintDMatrix(double **inMatrix,
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


void CopyFMatrix(float **inSource, float **outTarget, \
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


void TransposeFMatrix(float **inSource, float **outTarget, \
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


void MultiplyFMatrix(float **inA, float **inB, float **outResult, \
                  int inRLA, int inRHA, int inCLA, int inCHA, \
                  int inRLB, int inRHB, int inCLB, int inCHB)
{

   int i,j,k;

   if ((inCHA-inCLA) != (inRHB-inRLB))
        nrerror("Error in MultiplyFMatrix:  Incompatible matrices");

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
void DiagonalizeFMatrix(float **inMatrix, \
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
   CopyFMatrix(inMatrix,outEigenVector,\
                1,inDim,\
                1,inDim);
   //----------------------------------------------------------


}


void PrintFVector(float *inVector, int inRL, int inRH)
{

   int i;
   printf("\n");
   for(i=inRL;i<=inRH;i++)
   {
        printf("%f\n",inVector[i]);
   }
   printf("\n");

}


void PrintDVector(double *inVector, int inRL, int inRH)
{

   int i;
   printf("\n");
   for(i=inRL;i<=inRH;i++)
   {
        printf("%f\n",inVector[i]);
   }
   printf("\n");

}


void SaveFMatrix(float **inMatrix,\
                 int inRL, int inRH, \
                 int inCL, int inCH, \
                 char *inFileName)
{
   int i,j;

   FILE *theSaveFile;


   if ((theSaveFile = fopen(inFileName, "wt")) == NULL)
   {
      fprintf(stderr, "SaveFMatrix: Cannot open output file.\n");
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

   fprintf(stderr, "\nSaveFMatrix: Saved data to file %s.\n\n", inFileName);
   fclose(theSaveFile);

}




void SaveDMatrix(double **inMatrix,\
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


 