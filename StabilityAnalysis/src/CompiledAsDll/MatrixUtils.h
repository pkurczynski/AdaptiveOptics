//---------------------------------------------------------------------------
// MatrixUtils.h
//
// plk 03/13/2005
//---------------------------------------------------------------------------
#ifndef MATRIXUTILS_H
#define MATRIXUTILS_H


void OpenLogFile();
void LogMessage(char *inMessage);
void LogSimParams();


void LogFMatrix(float **inMatrix,
                  int inRL,
                  int inRH,
                  int inCL,
                  int inCH,
                char *inMessage);


void LogDMatrix(double **inMatrix,
                  int inRL,
                  int inRH,
                  int inCL,
                  int inCH,
                char *inMessage);

void LogFVector(float *inVector,
                int inRL,
                int inRH,
                char *inMessage);


void LogDVector(double *inVector,
                int inRL,
                int inRH,
                char *inMessage);

CopyFVectorToMatrixRow(float *inVector, \
                    int inRL, \
                    int inRH, \
                    float **inMatrix, \
                    int inRow);
CopyFVectorToMatrixCol(float *inVector, \
                    int inRL, \
                    int inRH, \
                    float **inMatrix, \
                    int inCol);


void PrintFMatrix(float **inMatrix, int inRL, int inRH, int inCL, int inCH);
void PrintDMatrix(double **inMatrix,
                  int inRL,
                  int inRH,
                  int inCL,
                  int inCH);

void PrintFVector(float *inVector, int inRL, int inRH);
void PrintDVector(double *inVector, int inRL, int inRH);
void SaveFMatrix(float **inMatrix,\
            int inRL, int inRH, \
            int inCL, int inCH, \
            char *inFileName);

void SaveDMatrix(double **inMatrix,\
            int inRL, int inRH, \
            int inCL, int inCH, \
            char *inFileName);

void CopyFMatrix(float **inSource, float **outTarget, \
                  int inRL,
                  int inRH,
                  int inCL,
                  int inCH);
void TransposeFMatrix(float **inSource, float **outTarget, \
                  int inRL,
                  int inRH,
                  int inCL,
                  int inCH);

void MultiplyFMatrix(float **inA, float **inB, float **outResult, \
                  int inRLA, int inRHA, int inCLA, int inCHA, \
                  int inRLB, int inRHB, int inCLB, int inCHB);

                  
void DiagonalizeFMatrix(float **inMatrix, \
                       int inDim, \
                       float *outEigenValue, \
                       float **outEigenVector);



#endif