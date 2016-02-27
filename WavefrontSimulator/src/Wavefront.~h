//---------------------------------------------------------------------------
// Wavefront.h                                        C++ Header file
//
// Class definition for the the Wavefront class.  Wavefront class contains
// intensity and phase data for a wavefront of specified width, and at
// specified wavelength.  Graphics canvas is included for display on the
// graphics3d window.
//
// Modifications:
//
// 4/25/2003 plk        Added methods X(), Y(), etc. to get coordinates
//                      of a point from array Row, Column indices
//
// 4/25/2003 plk        Added DisplayXYPlane()
//
// 4/27/2003 plk        Added constructor with ROIDimension, PupilRadius
//                      parameters.
//
// plk 4/17/2003
//---------------------------------------------------------------------------
#ifndef WavefrontH
#define WavefrontH
#include <fstream.h>
#include <iostream.h>
#include "Graphics3d.h"


class Wavefront
{
  protected:

   AnsiString PupilDataFileName;
   AnsiString EntireDataFileName;
   AnsiString ROIDataFileName;


   void     ScaleDataForGraphicsDisplay();
   double   ComputePhaseOffset();
   int      XValueToRowIndex(double inXValue_mm);
   int      YValueToColumnIndex(double inXValue_mm);
   bool     PointIsWithinPupil(int inRowIndex, int inColumnIndex);
   bool     PointIsWithinROI(int inRowIndex, int inColumnIndex);

   double **matrix(int nrl, int nrh, int ncl, int nch);


  public:

   int          ArrayDimension;         // arrays from 0...ArrayDimension - 1

   double       ROIDimension_mm;
   double       PupilRadius_mm;

   double       Width_mm;               // spatial extent of the wavefront
   double       Width_MKS;

   double       MeshSize_mm;
   double       MeshSize_MKS;


   double       Wavelength_nm;
   double       Wavelength_MKS;

   double     **Phase_rad;
   double     **Phase_um;
   double     **Phase_Graph;


   Wavefront();

   Wavefront(double   inWidth_mm,
             int      inArrayDimension);

   Wavefront(double inWidth_mm,
             int    inROIDimension_mm,
             double inPupilRadius_mm,
             double inArrayDimension);


   void DisplayPhase(Graphics3d *ioGraphicsCanvas);
   void DisplayXYPlane(Graphics3d *ioGraphicsCanvas);
   void WriteEntirePhaseDataToFile();
   void WritePhaseDataWithinPupilToFile();
   void WritePhaseDataWithinROIToFile();


   // Get coordinates of specified array element
   //     relative to center of wavefront
   double XRel_mm(int inRow, int inColumn)
         { return inRow*MeshSize_mm - Width_mm/2;}
   double YRel_mm(int inRow, int inColumn)
         { return inColumn*MeshSize_mm - Width_mm/2;}
   double R_mm(int inRow, int inColumn);
   double Theta_rad(int inRow, int inColumn);

   // Scaled, dimensionless radial coordinate.  R_scaled = r/r_pupil
   double R_scaled(int inRow, int inColumn)
         { return R_mm(inRow, inColumn)/PupilRadius_mm;}

};

//extern Wavefront *theWavefront;

//---------------------------------------------------------------------------
#endif
