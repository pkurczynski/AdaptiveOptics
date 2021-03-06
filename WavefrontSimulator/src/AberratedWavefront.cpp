//---------------------------------------------------------------------------
// AberratedWavefront.cpp                       C++ class definition file
//
//---------------------------------------------------------------------------
#include <stdio.h>
#include <math.h>
#include "WavefrontGUI.h"
#include "AberratedWavefront.h"

//---------------------------------------------------------------------------
// AberratedWavefront()
//
// Constructs an AberratedWavefront, which is derived from a Wavefront
// object.
//
// The Wavefront parameters Width_mm, ArrayDimension are arguments to
// this constructor, and are passed to the base Wavefront class using
// an initializer list.  The base class constructor Wavefront(double, int)
// is called thereby creating the Wavefront object with the desired
// parameters Width_mm, ArrayDimension.
//
// called by: TForm1::TForm1()
//            TForm1::Reset_Wavefront()
//
//---------------------------------------------------------------------------
AberratedWavefront::AberratedWavefront(
                                double inWavefrontWidth_mm,
                                int    inArrayDimension,
                                double inROIDimension_mm,
                                double inPupilRadius_mm,
                                double inZOffset_um,
                                double *inAberrationCoeff) :
                                Wavefront(inWavefrontWidth_mm,
                                          inROIDimension_mm,
                                          inPupilRadius_mm,
                                          inArrayDimension)
{

   // initialize AberrationCoefficient_ums.
   // initialize Zernike polynomials: Zernike[i] --> Z(j_value = i)
   for (int i = 0;i<NUMBEROFZERNIKES;i++)
   {
        AberrationCoefficient_um[i] = inAberrationCoeff[i];

        // offset the Zernike's by the Defocus amount, multiplied
        // by the defocus normalization.
        Zernike[i].SetOffset( inZOffset_um );
        Zernike[i].SetIndex(i);
   }

   ComputeExteriorPatchFunctions();
   ConstructExteriorExpansion();

}

//---------------------------------------------------------------------------
// AberratedWavefront()
//
// Default constructor.  Not used.
//---------------------------------------------------------------------------
AberratedWavefront::AberratedWavefront()
{
   AberrationCoefficient_um[0] = 9999;
}

AberratedWavefront::~AberratedWavefront()
{

}


//---------------------------------------------------------------------------
// ConstructZernikeExpansion()
//
// Constructs the phase aberrations of the AberratedWavefront by
// peforming the Zernike expansion.
//
// called by:
//---------------------------------------------------------------------------
void AberratedWavefront::ConstructZernikeExpansion()
{
   double theScaledR;
   double theTheta;

   double theMicronsToRadiansFactor = 1e-6 * (2*PI)/Wavelength_MKS;

   // 0 ... N (inclusive) array indexing convention is NOT A MISTAKE
   // This will not cause a memory leak, because of array allocation
   // in Wavefront class.  See class definition file for details.
   for (int i=0;i<=ArrayDimension;i++)
   {
      for (int j=0;j<=ArrayDimension;j++)
      {

         theScaledR = R_scaled(i,j);
         theTheta = Theta_rad(i,j);
         Phase_rad[i][j] = 0;
         for (int k=0;k<NUMBEROFZERNIKES;k++)
         {

            Phase_rad[i][j] += theMicronsToRadiansFactor *
                                AberrationCoefficient_um[k]*
                                Zernike[k].Evaluate(theScaledR,theTheta);

         }
      }
   }


}



//---------------------------------------------------------------------------
// ConstructExteriorExpansion()
//
// Constructs the phase aberrations of the AberratedWavefront by
// peforming the Zernike expansion also adds the Exterior expansion.
//
// called by:  AberratedWavefront()
//---------------------------------------------------------------------------
void AberratedWavefront::ConstructExteriorExpansion()
{
   double theScaledR;
   double theTheta;

   double theMicronsToRadiansFactor = 1e-6 * (2*PI)/Wavelength_MKS;

   // 0 ... N (inclusive) array indexing convention is NOT A MISTAKE
   // This will not cause a memory leak, because of array allocation
   // in Wavefront class.  See class definition file for details.
   for (int i=0;i<=ArrayDimension;i++)
   {
      for (int j=0;j<=ArrayDimension;j++)
      {

         theScaledR = R_scaled(i,j);
         theTheta = Theta_rad(i,j);
         Phase_um[i][j] = 0;
         Phase_rad[i][j] = 0;
         if (PointIsWithinPupil(i,j))
         {
            for (int k=0;k<NUMBEROFZERNIKES;k++)
            {


               Phase_rad[i][j] += theMicronsToRadiansFactor *
                                AberrationCoefficient_um[k]*
                                Zernike[k].Evaluate(theScaledR,theTheta);

               Phase_um[i][j] += AberrationCoefficient_um[k]*
                              Zernike[k].Evaluate(theScaledR,theTheta);

            }
         }
         else if (PointIsWithinROI(i,j))
         {
            for (int k=0;k<NUMBEROFZERNIKES;k++)
            {


               Phase_rad[i][j] += theMicronsToRadiansFactor *
                                AberrationCoefficient_um[k]*
                                Exterior[k].Evaluate(theScaledR,theTheta);


               Phase_um[i][j] += AberrationCoefficient_um[k]*
                                Exterior[k].Evaluate(theScaledR,theTheta);

            }
         }
      }
   }


}


//---------------------------------------------------------------------------
// ComputeExteriorPatchFunctions()
//
// Constructs the phase aberrations of the AberratedWavefront by
// peforming the Zernike expansion.
//
// called by:  AberratedWavefront()
//---------------------------------------------------------------------------
void AberratedWavefront::ComputeExteriorPatchFunctions()
{
   char   theBuffer[80];

   double theZernikeValueAtPupil;
   double theZernikeDerivativeAtPupil;
   double theZernikeFrequency;

   double theRadiusOfExteriorRegion;

   // scaled outer radius, where Wavefront is at zero phase.
   // In units of the pupil radius.
   theRadiusOfExteriorRegion = (ROIDimension_mm/2)/PupilRadius_mm;

   for (int i=0;i<NUMBEROFZERNIKES;i++)
   {
        theZernikeFrequency = Zernike[i].GetAzimuthalFrequency();

        // values of the Zernike polynomial on the inner boundary
        // of the Exterior region (R = 1, where R = RCoord_mm / PupilRadius_mm)
        theZernikeValueAtPupil = Zernike[i].Evaluate(1);
        theZernikeDerivativeAtPupil = Zernike[i].RadialDerivative(1);

        // compute the radial polynomial that connects the ZernikePolynomial
        // to the outer radius of the exterior region, matching value
        // and slope to the ZernikePolynomial at the inner boundary
        // and zero value and slope at the outer boundary.
        Exterior[i].SetQuadraticRadialPolynomial(theZernikeValueAtPupil,
                                        theZernikeDerivativeAtPupil,
                                        theRadiusOfExteriorRegion);

        // ExteriorPolynomials have the same azimuthal frequency
        // (theta dependence) as their corresponding ZernikePolynomial
        Exterior[i].SetAzimuthalFrequency(theZernikeFrequency);
    }


#ifdef WavefrontGUIH
   WavefrontGUIForm->Memo1->Lines->Add("Using Quadratic ExteriorPolynomials");
   WavefrontGUIForm->Memo1->Lines->Add(" ");
#endif


#if 0
   for (int i=0;i<NUMBEROFZERNIKES;i++)
   {

     theRadialDerivative = Exterior[i].Evaluate(theRadiusOfExteriorRegion,0);
     sprintf(theBuffer,"%d \t %f \t %f\n",i,theZe,AberrationCoefficient_um[i]);
     MemoBox->Lines->Add(theBuffer);

   }
#endif


}
