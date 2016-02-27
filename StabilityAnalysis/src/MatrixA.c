//---------------------------------------------------------------------------
// MatrixA.c                                  C Program file
//
// methods for a MatrixA class implementation.
//
//
// plk 03/08/2005
//---------------------------------------------------------------------------
#include "MatrixA.h"
#include "Membrane.h"
#include "ElectrodeArray.h"
#include "BesselJZeros.h"
#include "Eigenfunc.h"
#include "NR.h"
#include "NRUTIL.H"
#include <math.h>
#include <stdio.h>

#define FUNC(x) ((*func)(x))
#define EPS 1.0e-5
#define JMAX 20

//fractional accuracy of integration
double gEPS = 1.0E-3;

int gMatrixAActiveRow;
int gMatrixAActiveCol;

double **gMatrixA;

extern double gMembraneRadius_mm;
extern double gMembraneTension_NByM;      // tension = stress * thickness
extern double gMembraneRadius_mm;


extern double gVoltageT_V;    // Transp. electrode voltage
extern double gVoltageA_V;    // Array electrode voltage
extern double gDistT_um;      // Transp. electr -- membr. dist.
extern double gDistA_um;      // Electr. array -- membr. dist.

extern int gNumberOfEigenFunctions;
extern double (*gMembraneShape)(double, double);

extern int      gNumElectrodes;
extern float  **gElectrodeVoltage;
extern float   gElectrodeWidth_um;
extern float   gElectrodeSpc_um;



//---------------------------------------------------------------------------
// ComputeMatrixA
//
// Computes A matrix elements using numerical integration of the
// eigenfunctions multiplied by the electrostatic weight function.
//
// called by:  main()
//
// plk 3/10/2005
//---------------------------------------------------------------------------
void ComputeMatrixA(double **outMatrixA)
{
   int i,j;


   // realMatrixA is indexed 0...N-1
   for(i=0;i<=gNumberOfEigenFunctions-1;i++)
   {
        for(j=0;j<=gNumberOfEigenFunctions-1;j++)
        {

           outMatrixA[i][j] = RealMatrixA(i,j);
        }
   }

}

//---------------------------------------------------------------------------
// ComputeMatrixASum
//
// Computes A matrix elements using summation over the electrodes of the
// array.
//
// called by:  main()
//
// plk 3/10/2005
//---------------------------------------------------------------------------

void ComputeMatrixASum(double **outMatrixASum)
{

   int i,j;


   // realMatrixA is indexed 0...N-1
   for(i=0;i<=gNumberOfEigenFunctions-1;i++)
   {
        for(j=0;j<=gNumberOfEigenFunctions-1;j++)
        {

           outMatrixASum[i][j] = RealMatrixASum(i,j);
        }
   }

}



//---------------------------------------------------------------------------
// ComputeMatrixASum
//
// Computes A matrix elements using summation over the electrodes of the
// array.  This version of the procedure stores the result in the "global"
// array gMatrixA.
//
// called by:  main()
//
// plk 3/10/2005
//---------------------------------------------------------------------------
void ComputegMatrixASum()
{

   int i,j;

   gMatrixA = dmatrix(0,gNumberOfEigenFunctions-1, \
                    0,gNumberOfEigenFunctions-1);

   // realMatrixA is indexed 0...N-1
   for(i=0;i<gNumberOfEigenFunctions-1;i++)
   {
        for(j=0;j<gNumberOfEigenFunctions-1;j++)
        {

           gMatrixA[i][j] = RealMatrixASum(i,j);
        }
   }

}









//---------------------------------------------------------------------------
// RealMatrixA
//
// Computes the matrix element A_jj' from the stability calculation write-up.
// This matrix is in general Hermitian.  For the special case of the
// electrostatic weight function, F, being independent of phi, the matrix
// elements are real.  Orthogonality of the phi basis functions is used
// to compute the phi integral automatically.  Numerical integration is
// used to compute the radial integral.  The matrix element is given by:
//
//                ^
//               |
//    A_jj'   =  | F(xi) * zeta_j(r,phi) * zeta_j'(r,phi)  r dr dphi
//               |
//              ^
//
// xi = MembraneDeformation(r,phi) --> xi(r) in this function.
//
// zeta_j, _j' are the eigenfunctions of the membrane.  F is the electrostatic
// weight function (see below, also Formal Stability Calculation write up).
//
// called by: ComputeOmegaMatrix
// plk 03/10/2005
//---------------------------------------------------------------------------
double RealMatrixA(int inJRow, int inJCol)
{

   int theRowVIndex;
   int theColVIndex;

   double theRFactor;
   double thePhiFactor;
   double theMagn;
   double thePhase;
   double theMembraneRadius_MKS;
   double PI = 3.1415926535;

   double (*theFunc)(double);

   theRFactor   = 1.0;
   thePhiFactor = 1.0;

   // set variables, function pointer for NR integration
   // routine (used to evaluate radial integral).
   theFunc = AIntegrandRF;
   //theFunc = TestIntegrand;
   gMatrixAActiveRow = inJRow;
   gMatrixAActiveCol = inJCol;

   // set v indices for use in phi integration.
   theRowVIndex = BesselVIndex(inJRow);
   theColVIndex = BesselVIndex(inJCol);

   // Assuming Weight function is independent of phi, then the
   // angular integration is computed analytically.  Because of
   // orthogonality of the angular functions, matrix elements
   // with v_row != v_column are zero.
   if (theRowVIndex == theColVIndex)
        thePhiFactor = 2*PI;
   else
   {
        thePhiFactor = 0.0;
        theMagn = 0.0;
        return theMagn;
   }


   //------------------------------------------------------
   //radial integration:
   //------------------------------------------------------

   theMembraneRadius_MKS = gMembraneRadius_mm*1.0e-3;

   //DEBUG
   //dump(theFunc,0,theMembraneRadius_MKS,20);

   // Trapezoidal Rule Integrator.
   theRFactor = qtrap(theFunc,0,theMembraneRadius_MKS);

   // In order for this routine to work, you will probably
   // have to change all double's to doubles, and make sure
   // that <math.h> is explicitly included in order to avoid
   // problems with fabs() and maybe other math functions.
   //
   // Romberg Integrator.
   //theRFactor = qromb(theFunc,0,theMembraneRadius_MKS);
   //------------------------------------------------------



   // for the case of azimuthally symmetric weight function, the
   // matrix element is a real number.
   theMagn = theRFactor * thePhiFactor;
   thePhase = 0;

   return theMagn;



}



//---------------------------------------------------------------------------
// RealMatrixASum
//
// Computes the matrix element A_jj' from the stability calculation write-up.
// This matrix is in general Hermitian.  For the special case of the
// electrostatic weight function, F, being independent of phi, the matrix
// elements are real.  The matrix element is given by:
//
//
//               N-1
//    A_jj'   =  Sum F(xi) * zeta_j(r,phi) * zeta_j'(r,phi)  DS_k
//               k=0
//
//
// xi = MembraneDeformation(r,phi) --> xi(r) in this function.
//
// zeta_j, _j' are the eigenfunctions of the membrane.  F is the electrostatic
// weight function (see below, also Formal Stability Calculation write up).
//
// called by: ComputeOmegaMatrix
// plk 03/10/2005
//---------------------------------------------------------------------------
double RealMatrixASum(int inJRow, int inJCol)
{
   
   int    k;
   int    theIndex;

   double theRowEigenMagn;
   double theRowEigenPhase;

   double theColEigenMagn;
   double theColEigenPhase;

   double theEigenProductMagn;
   double theEigenProductPhase;

   double theVoltage;
   double theR_MKS;
   double thePhi_Rad;
   double theFFactor_MKS;

   double theElectrodeWidth_MKS;
   double theElectrodeSpc_MKS;
   double theElectrodeArea_MKS;

   double theSummandMagn_MKS;
   double theSummandPhase_Rad;
   double theSummandReal_MKS;
   double theSummandImag_MKS;

   double theSumReal_MKS;
   double theSumImag_MKS;


   gMatrixAActiveRow = inJRow;
   gMatrixAActiveCol = inJCol;


   theElectrodeWidth_MKS = (double) gElectrodeWidth_um*1e-6;
   theElectrodeSpc_MKS = (double) gElectrodeSpc_um*1e-6;
   theElectrodeArea_MKS = theElectrodeWidth_MKS+theElectrodeSpc_MKS;
   theElectrodeArea_MKS *= theElectrodeArea_MKS;


   theSumReal_MKS = 0.0;
   theSumImag_MKS = 0.0;


   // sum over all electrodes in the array...approximation
   // to surface integral over the membrane.
   for (k=0;k<gNumElectrodes;k++)
   {
       theIndex = (int) gElectrodeVoltage[k][0];
       theVoltage = (double) ElectrodeVoltage(theIndex);

       theR_MKS = (double) ERCenter_MKS(theIndex);
       thePhi_Rad = (double) EPhiCenter_rad(theIndex);


       // compute magnitude, phase of each eigenfunction
       // at the current electrode position.
       Eigenfunc(gMatrixAActiveRow, \
             theR_MKS, \
             thePhi_Rad, \
             &theRowEigenMagn, \
             &theRowEigenPhase);

       Eigenfunc(gMatrixAActiveCol, \
             theR_MKS, \
             thePhi_Rad, \
             &theColEigenMagn, \
             &theColEigenPhase);

       theEigenProductMagn = theRowEigenMagn*theColEigenMagn;

       // minus sign below because matrix element is product
       // of eigenfunction * complex conjugate (eigenfunction)
       theEigenProductPhase = theRowEigenPhase - theColEigenPhase;



       // compute electrostatic weight function
       theFFactor_MKS = WeightFnForSum_MKS(theR_MKS,thePhi_Rad,theVoltage);

       // DEBUG
       //printf("%f\t%f\n",theFFactor_MKS,theVoltage);


       // DEBUG
       //theFFactor_MKS = 1.0;


       // Summand is a complex number with Magn given below and
       // phase given by EigenProductPhase.  Convert complex number
       // to rectangular format to compute the sum
       theSummandMagn_MKS =  theEigenProductMagn * \
                             theFFactor_MKS * \
                             theElectrodeArea_MKS;

       theSummandPhase_Rad = theEigenProductPhase;

       theSummandReal_MKS = theSummandMagn_MKS*cos(theSummandPhase_Rad);

       theSummandImag_MKS = theSummandMagn_MKS*sin(theSummandPhase_Rad);

       theSumReal_MKS+=theSummandReal_MKS;
       theSumImag_MKS+=theSummandImag_MKS;

    }

    if ( fabs(theSumImag_MKS) > 100)
    {
       printf("--- RealMatrixASum:  Warning! Imaginary component = %f ---\n",\
                theSumImag_MKS);
    }

    return theSumReal_MKS;


}





//---------------------------------------------------------------------------
// AIntegrandRF
//
// Computes the radial factor of the integrand of the matrix element "A."
// calculations. This function assumes that the weight function is
// independent of the phi coordinate, and therefore the integral is
// only over the radial coordinate.  This function will be called by
// the 1D-integration (Numerical Recipes) routine to compute the radial
// integral of the matrix element.
//
// arguments:  inR    the current value of the radial coordinate (MKS units)
//
// uses global variables:
//
//             gMatrixAActiveRow   the row index of the current matrix element
//             gMatrixAActiveCol   the col index of the current matrix element
//
// called by:  RealMatrixA (implicitly, through NR integration routine).
//
// plk 03/07/2005
//---------------------------------------------------------------------------
double AIntegrandRF(double inR)
{


   double theRowEigenMagn;
   double theRowEigenPhase;

   double theColEigenMagn;
   double theColEigenPhase;

   double theEigenProduct;
   double theAIntegrandRF;
   double theArbitraryPhi;

   // compute magnitude, phase of each eigenfunction at the current
   // r coordinate.  Because only the magnitudes are used in this
   // function, the input phi value is arbitrary.
   theArbitraryPhi=0;
   Eigenfunc(gMatrixAActiveRow, \
             inR, \
             theArbitraryPhi, \
             &theRowEigenMagn, \
             &theRowEigenPhase);

   Eigenfunc(gMatrixAActiveCol, \
             inR, \
             theArbitraryPhi, \
             &theColEigenMagn, \
             &theColEigenPhase);

   theEigenProduct = theRowEigenMagn*theColEigenMagn;

   // multiply by inR_MKS for Jacobian in polar coordinates.
   theAIntegrandRF = WeightFn_MKS(inR)*theEigenProduct*inR;

   // DEBUG
   //theAIntegrandRF = 1.0*theEigenProduct*inR;



   return theAIntegrandRF;

}


double TestIntegrand(double inX)
{
   return 2*inX;
}


double TestWeightFn_MKS(double inX)
{
   return 1.0;
}




//---------------------------------------------------------------------------
// WeightFn_MKS
//
// Computes a weight function for the product of eigenfunctions in the
// matrix element computation. The weight function is the "Electrostatic
// F function" used in calculation write ups.  It depends upon the membrane
// shape function.
//                         e_0 V_A^2           e_0 V_T^2
//         F ( xi )  =    -----------    +    -----------
//                        (d_A - xi)^3        (d_T + xi)^3
//
// d_A, d_T, V_A, V_T  are membrane device parameters (distances voltages)
// and are defined in Membrane.h.  xi is the membrane shape function,
// positive values are toward the electrode array.  Shape function is
// implemented in Membrane.c
//
// NOTE:  Computation of F(xi) agrees to at least 5 places after the decimal
// point with similar computation performed in the Excel spreadsheet:
// FormalStabilityCalculation_v1.xls, for parabolic deformation, with
// peak deformation of 10 um, Voltages = 10V, distances = 30 um.
//
//
// called by:  AIntegrandRF
//
// plk 3/8/2005
//---------------------------------------------------------------------------
double WeightFn_MKS(double inR_MKS)
{
   double e_zero_MKS = 8.85E-12;
   double theDistA_MKS;
   double theDistT_MKS;
   double theFFactA_MKS;
   double theFFactB_MKS;
   double theFFact_MKS;
   double theArbitraryPhi;

   theArbitraryPhi = 0.0;

   theDistA_MKS = gDistA_um*1e-6 - gMembraneShape(inR_MKS, theArbitraryPhi);
   theDistT_MKS = gDistT_um*1e-6 + gMembraneShape(inR_MKS, theArbitraryPhi);


   theFFactA_MKS = e_zero_MKS*gVoltageA_V*gVoltageA_V/pow(theDistA_MKS,3);
   theFFactB_MKS = e_zero_MKS*gVoltageT_V*gVoltageT_V/pow(theDistT_MKS,3);

   theFFact_MKS = theFFactA_MKS + theFFactB_MKS;

  return theFFact_MKS;
}



//---------------------------------------------------------------------------
// WeightFnForSum_MKS
//
// compute the electrostatic "weight function"
//
//             e_0*V_k^2         e_0*V_T^2
// F_k(xi) =   ---------    +   -----------
//            (d_A - xi)^3      (d_T + xi )^3
//
//
// called by: RealMatrixASum()
// plk 3/28/2005
//---------------------------------------------------------------------------
double WeightFnForSum_MKS(double inR_MKS, \
                          double inPhi_Rad, \
                          double inEVoltage_V)
{
   double theMembrDef_MKS;
   double theDenom_MKS;
   double theArrayTerm_MKS;
   double theVtTerm_MKS;
   double theFFactor_MKS;

   double e_0 = 8.85E-12;


   theMembrDef_MKS = gMembraneShape(inR_MKS,inPhi_Rad);
   theDenom_MKS = gDistA_um*1e-6 - theMembrDef_MKS;
   theDenom_MKS = pow(theDenom_MKS,3);

   theArrayTerm_MKS = e_0*inEVoltage_V*inEVoltage_V/theDenom_MKS;

   theDenom_MKS = gDistT_um*1e-6 + theMembrDef_MKS;
   theDenom_MKS = pow(theDenom_MKS,3);
   theVtTerm_MKS = e_0*gVoltageT_V*gVoltageT_V/theDenom_MKS;

   theFFactor_MKS= theArrayTerm_MKS + theVtTerm_MKS;


   return theFFactor_MKS;
}




//---------------------------------------------------------------------------
// TestElectrostaticWeightFn
//
// DEBUG function.
//
// called by:
//
// plk 03/08/2005
//---------------------------------------------------------------------------
void TestElectrostaticWeightFn(double inRL,double inRH, double inNum)
{
   int i;

   double theR, thePhi_Rad;
   double theR_mm;
   double theDR;
   double theMagn;
   double thePhase;
   double theFCont_MKS;
   double theFDisc_MKS;
   double theArbitraryPhi;
   double **theLogData;


   theArbitraryPhi = 0.0;

   theDR=(inRH-inRL)/(inNum+1);

   theLogData=dmatrix(1,(int)inNum+10,1,3);

   printf("\n\nTestWeightFn\n");
   printf("r_mm\t\tcontinous, mks\tdiscrete, mks\n");

   i=0;
   for (theR=inRL; theR<=(inRH+0.01*inRH); theR+=theDR)
   {

        theR_mm=theR*1e3;
        theFCont_MKS = WeightFn_MKS(theR);
        theFDisc_MKS = WeightFnForSum_MKS(theR,theArbitraryPhi,gVoltageA_V);
        printf("%f\t%1.8f\t%1.8f\n",theR_mm,theFCont_MKS,theFDisc_MKS);

        i++;
        theLogData[i][1]=theR_mm;
        theLogData[i][2]=theFCont_MKS;
        theLogData[i][3]=theFDisc_MKS;
   }
   printf("\n\n");

   LogDMatrix(theLogData,1,i,1,3,\
              "TestWeightFn: r_mm,F(cont)MKS,F(discr)MKS");


}








//---------------------------------------------------------------------------
// ArrayWeightFn_MKS
//
// THIS FUNCTION IS CONCEPTUALLY WRONG!  FORMULA BELOW SHOULD NOT HAVE
// A  SUMMATION OVER ELECTRODES.  plk 3/24/2005
//
// Computes a weight function for the product of eigenfunctions in the
// matrix element computation. The weight function is the "Electrostatic
// F function" used in calculation write ups.  It depends upon the membrane
// shape function.
//                 N-1      e_0 (1/N) V_k^2         e_0 V_T^2
// F ( r,phi)  =  Sum (     ---------------   +   -----------      )
//                k=0        (d_A - xi_k)^3      (d_T + xi_k)^3
//
// d_A, d_T, V_T  are membrane device parameters (distances, voltages)
// and are defined in Membrane.c.  xi is the membrane shape function,
// positive values are toward the electrode array; xi is evaluated at
// the center of each electrode position.  The shape function is
// implemented in Membrane.c  V_k is the voltage on electrode array
// element k.  N is the number of elements in the array.
//
//
// called by:  AIntegrandRF
//
// plk 3/8/2005
//---------------------------------------------------------------------------
double ArrayWeightFn_MKS(double inR_MKS)
{
   int    k;
   int    theIndex;
   double theVoltage;
   double theR_MKS;
   double thePhi_Rad;
   double theMembrDef_MKS;
   double theDenom_MKS;
   double theArrayTerm_MKS;
   double theVtTerm_MKS;
   double theSum;

   double e_0 = 8.85E-12;

   theSum=0.0;
   for (k=0;k<gNumElectrodes;k++)
   {
       theIndex = (int) gElectrodeVoltage[k][0];
       theVoltage = (double) ElectrodeVoltage(theIndex);

       theR_MKS = (double) ERCenter_MKS(theIndex);
       thePhi_Rad = (double) EPhiCenter_rad(theIndex);

       theMembrDef_MKS = gMembraneShape(theR_MKS,thePhi_Rad);
       theDenom_MKS = gDistA_um*1e-6 - theMembrDef_MKS;
       theDenom_MKS = pow(theDenom_MKS,3);

       theArrayTerm_MKS = theVoltage*theVoltage/theDenom_MKS;
       theArrayTerm_MKS *= (e_0/gNumElectrodes);

       theSum+= theArrayTerm_MKS;

       theDenom_MKS = gDistT_um*1e-6 + theMembrDef_MKS;
       theDenom_MKS = pow(theDenom_MKS,3);
       theVtTerm_MKS = e_0*gVoltageT_V*gVoltageT_V/theDenom_MKS;

       theSum+= theVtTerm_MKS;

  }

  return theSum;

}


//---------------------------------------------------------------------------
// dump
//
// DEBUG function.  Prints several values of the function specified
// by the function pointer argument, within the specified range of
// the independent variable [inRL,inRH], inNum sample points.
//
// called by: RealMatrixA
//
// plk 03/08/2005
//---------------------------------------------------------------------------

void dump(double (*inFunc)(double),double inRL,double inRH, double inNum)
{

   double theR;
   double theDR;
   double theMagn;
   double thePhase;
   FILE  *theLogFilePtr;

   theDR=(inRH-inRL)/inNum;

   printf("MatrixA::dump\n");
   printf("Radial integrand\n");
   printf("Matrix Element [%d][%d]\n",gMatrixAActiveRow,gMatrixAActiveCol);

   for (theR=inRL; theR<=inRH; theR+=theDR)
   {
        theMagn = (*inFunc)(theR);
        printf("%f\t%f\n",theR,theMagn);
   }
   printf("\n\n");


   if ((theLogFilePtr = fopen("MatrixALog.txt", "at")) == NULL)
   {
      fprintf(stderr, "MatrixA::dump -- Cannot open output file.\n");
      return;
   }

   fprintf(theLogFilePtr, "Radial integrand\n");
   fprintf(theLogFilePtr, "MatrixA Element [%d][%d]\n", \
                gMatrixAActiveRow, \
                gMatrixAActiveCol);

   for (theR=inRL; theR<=inRH; theR+=theDR)
   {
        theMagn = (*inFunc)(theR);
        fprintf(theLogFilePtr, "%f\t%f\n",theR,theMagn);
   }
   fprintf(theLogFilePtr,"\n\n");
   fclose(theLogFilePtr);

}


double qtrap(double (*func)(double), double a, double b)
{

	int j;

	double s,olds;
        double theErr;
        double theTest;
	void nrerror();



	olds = -1.0e30;
        theErr = gEPS*fabs(olds);
	for (j=1;j<=JMAX;j++) {

		s=trapzd(func,a,b,j);
                theTest=fabs(s-olds);
		if (theTest <= theErr) return s;

		olds=s;
                theErr=gEPS*fabs(olds);

	}

	nrerror("Too many steps in routine QTRAP");

}


double trapzd(double (*func)(double), double a, double b, int n)
{

	double x,tnm,sum,del;

	static double s;

	static int it;

	int j;



	if (n == 1) {

		it=1;

		return (s=0.5*(b-a)*(FUNC(a)+FUNC(b)));

	} else {

		tnm=it;

		del=(b-a)/tnm;

		x=a+0.5*del;

		for (sum=0.0,j=1;j<=it;j++,x+=del) sum += FUNC(x);

		it *= 2;

		s=0.5*(s+(b-a)*sum/tnm);

		return s;

	}

}







