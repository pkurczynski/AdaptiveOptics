//---------------------------------------------------------------------------
#ifndef ABERRATEDWAVEFRONT_H
#define ABERRATEDWAVEFRONT_H

#include "Wavefront.h"
#include "ZOffsetZernikePolynomial.h"
#include "ExteriorPolynomial.h"


#define  NUMBEROFZERNIKES  66

//---------------------------------------------------------------------------
class AberratedWavefront : public Wavefront
{
  private:

    double                      AberrationCoefficient_um[NUMBEROFZERNIKES];
    ZOffsetZernikePolynomial    Zernike[NUMBEROFZERNIKES];
    ExteriorPolynomial          Exterior[NUMBEROFZERNIKES];

    void                ConstructZernikeExpansion();
    void                ConstructExteriorExpansion();

    void                ComputeExteriorPatchFunctions();


  public:
     AberratedWavefront();
     
     AberratedWavefront(double inWavefrontWidth_mm,
                        int    inArrayDimension,
                        double inROIDimension_mm,
                        double inPupilRadius_mm,
                        double inZOffset_um,
                        double *inAberrationCoeff);


     ~AberratedWavefront();
};

extern AberratedWavefront *theAberratedWavefront;

#endif
 