//---------------------------------------------------------------------------
// Wavefront.cpp                                Class implementation file
//
//
// plk 4/15/2003
//---------------------------------------------------------------------------
#include <math.h>
#include "Wavefront.h"
#include "Graphics3d.h"


//----------------------------------------------------------------------------
// Wavefront()
//
// Default constructor for Wavefront class.
//
// Width_mm = 10
// ArrayDimension = 100
//
// called by:
//
//----------------------------------------------------------------------------
Wavefront::Wavefront()
{
   double theWidth_mm = 10;
   int    theArrayDimension = 100;


   Wavelength_nm = 685;
   Wavelength_MKS = 1e-9 * Wavelength_nm;

   Width_mm = theWidth_mm;
   Width_MKS = 1e-3 * theWidth_mm;

   ArrayDimension = theArrayDimension;

   PupilRadius_mm = 5.0;

   ROIDimension_mm = Width_mm;
   MeshSize_mm = ROIDimension_mm / ArrayDimension;  // step size in x,y
   MeshSize_MKS = MeshSize_mm *1e-3;

   PupilDataFileName = "WavefrontPupilData.txt";
   EntireDataFileName ="WavefrontEntireData.txt";
   ROIDataFileName ="WavefrontROIData.txt";


   Phase_rad   = matrix(0,ArrayDimension,0,ArrayDimension);
   Phase_um    = matrix(0,ArrayDimension,0,ArrayDimension);
   Phase_Graph = matrix(0,ArrayDimension,0,ArrayDimension);
   for (int i=0;i<ArrayDimension;i++)
   {
      for (int j=0;j<ArrayDimension;j++)
      {
         Phase_rad[i][j] = 0.0;
         Phase_um[i][j] = 0.0;
         Phase_Graph[i][j] = 0.0;
      }
   }


}


//----------------------------------------------------------------------------
// Wavefront()
//
// Class constructor.
//
// called by: TForm1::TForm1()
//            TForm1::Reset_theMembranePDEproblemAndWavefront()
//
//----------------------------------------------------------------------------
Wavefront::Wavefront(double      inWidth_mm,
                     int         inArrayDimension)
{
   Wavelength_nm = 500;
   Wavelength_MKS = 1e-9 * Wavelength_nm;

   Width_mm = inWidth_mm;
   Width_MKS = 1e-3 * inWidth_mm;

   ArrayDimension = inArrayDimension;

   PupilRadius_mm = 5.0;

   ROIDimension_mm = Width_mm;
   MeshSize_mm = Width_mm / ArrayDimension;  // step size in x,y
   MeshSize_MKS = MeshSize_mm *1e-3;

   PupilDataFileName = "WavefrontPupilData.txt";
   EntireDataFileName ="WavefrontEntireData.txt";
   ROIDataFileName ="WavefrontROIData.txt";


   Phase_rad   = matrix(0,ArrayDimension,0,ArrayDimension);
   Phase_Graph = matrix(0,ArrayDimension,0,ArrayDimension);
   for (int i=0;i<ArrayDimension;i++)
   {
      for (int j=0;j<ArrayDimension;j++)
      {
         Phase_rad[i][j] = 0.0;
         Phase_um [i][j] = 0.0;
         Phase_Graph[i][j] = 0.0;
      }
   }


}


//----------------------------------------------------------------------------
// Wavefront()
//
// Class constructor.
//
// called by: AberratedWavefront::AberratedWavefront()
//
//----------------------------------------------------------------------------

Wavefront::Wavefront(double inWidth_mm,
                     int    inROIDimension_mm,
                     double inPupilRadius_mm,
                     double inArrayDimension)
{
   Wavelength_nm = 685;
   Wavelength_MKS = 1e-9 * Wavelength_nm;

   Width_mm = inWidth_mm;
   Width_MKS = 1e-3 * inWidth_mm;

   ROIDimension_mm = inROIDimension_mm;
   PupilRadius_mm = inPupilRadius_mm;

   ArrayDimension = inArrayDimension;

   MeshSize_mm = Width_mm / ArrayDimension;  // step size in x,y
   MeshSize_MKS = MeshSize_mm *1e-3;

   PupilDataFileName =  "WavefrontPupilData.txt";
   EntireDataFileName = "WavefrontEntireData.txt";
   ROIDataFileName =    "WavefrontROIData.txt";


   Phase_rad   = matrix(0,ArrayDimension,0,ArrayDimension);
   Phase_um    = matrix(0,ArrayDimension,0,ArrayDimension);
   Phase_Graph = matrix(0,ArrayDimension,0,ArrayDimension);
   for (int i=0;i<ArrayDimension;i++)
   {
      for (int j=0;j<ArrayDimension;j++)
      {
         Phase_rad[i][j] = 0.0;
         Phase_um[i][j]  = 0.0;
         Phase_Graph[i][j] = 0.0;
      }
   }

}

//----------------------------------------------------------------------------
// ScaleDataForGraphicsDisplay()
//
// Populates the arrays that are used in the graphics display.  Scales
// quantities so that they are reasonable values to display in the
// graphics window.
//
// This method also changes the Phase_rad data array by subtracting
// an offset.  See ScaleDataForGraphicsDisplay() for details
//
// Quantity      Scale Factor     Offset         Units
// --------      ------------     ------         -----
// Phase_Graph      * 0.1       PhaseAtCenter    Radians X 10
// Phase_rad          1         PhaseAtCenter    Radians
//
// called by:  Display()
//
//----------------------------------------------------------------------------
void Wavefront::ScaleDataForGraphicsDisplay()
{

   for (int i=0;i<=ArrayDimension;i++)
   {
      for (int j=0;j<=ArrayDimension;j++)
      {
         Phase_Graph[i][j] =  Phase_rad[i][j] / 10.0;
      }
   }

}


//----------------------------------------------------------------------------
// DisplayPhase()
//
// Displays the wavefront on the graphics window.  Points within the
// optical pupil are drawn in red.  Points outside the optical pupil
// are either not displayed, or drawn in green.
//
// NOTE: array indexing is 0...N (inclusive).  This is not a mistake!
// There is no memory leak because numerical recipes routine matrix()
// allocates memory from 0...N inclusive.  This indexing convention is
// carried over from MembranePDEproblem, and it facilitates graphics
// operations.
//
// called by:  TForm1::PaintBox2OnPaint()
//
//----------------------------------------------------------------------------
void Wavefront::DisplayPhase(Graphics3d *ioGraphicsCanvas)
{
   double x;
   double y;

   ScaleDataForGraphicsDisplay();






   for (int i=0;i<=ArrayDimension;i++)
   {
      x=i*MeshSize_mm;
      for (int j=0;j<ArrayDimension;j++)
      {
         y=j*MeshSize_mm;
         if (PointIsWithinROI(i,j))
         {
           if (PointIsWithinPupil(i,j))
              ioGraphicsCanvas->SetPenColor(clRed);
           else
              ioGraphicsCanvas->SetPenColor(clLtGray);
           ioGraphicsCanvas->moveto_3d(x,y,Phase_Graph[i][j]);
	   y=(j+1)*MeshSize_mm;
           ioGraphicsCanvas->lineto_3d(x,y,Phase_Graph[i][j+1]);
         }
      }
      y=0;
   }
   for (int j=0;j<=ArrayDimension;j++)
   {
      y=j*MeshSize_mm;
      for (int i=0;i<ArrayDimension;i++)
      {
         x=i*MeshSize_mm;
         if (PointIsWithinROI(i,j))
         {
            if (PointIsWithinPupil(i,j))
                ioGraphicsCanvas->SetPenColor(clRed);
            else
                ioGraphicsCanvas->SetPenColor(clLtGray);

            ioGraphicsCanvas->moveto_3d(x,y,Phase_Graph[i][j]);

	    x=(i+1)*MeshSize_mm;
            ioGraphicsCanvas->lineto_3d(x,y,Phase_Graph[i+1][j]);
         }
      }
      x=0;
   }


}


//----------------------------------------------------------------------------
// DisplayXYPlane()
//
// Draws a blue network of grid lines in the XY plane for reference.
//
// called by:  WavefrontGUI::WavefrontPaintBoxOnPaint()
//
//----------------------------------------------------------------------------
void Wavefront::DisplayXYPlane(Graphics3d *ioGraphicsCanvas)
{
   // draw grid lines on xy plane

   ioGraphicsCanvas->SetPenColor(clNavy);
   for (double x=MeshSize_mm;x<=ROIDimension_mm;x=x+MeshSize_mm)
   {

      ioGraphicsCanvas->moveto_3d(x,0,0);
      ioGraphicsCanvas->lineto_3d(x,ROIDimension_mm,0);

   }
   for (double y=MeshSize_mm;y<=ROIDimension_mm;y+=MeshSize_mm)
   {

       ioGraphicsCanvas->moveto_3d(0,y,0);
       ioGraphicsCanvas->lineto_3d(ROIDimension_mm,y,0);

   }

   // draw graph lines
   ioGraphicsCanvas->moveto_3d(ROIDimension_mm,0,0);
   ioGraphicsCanvas->lineto_3d(0,0,0);
   ioGraphicsCanvas->lineto_3d(0,ROIDimension_mm,0);
   //ioGraphicsCanvas->moveto_3d(0,0,0);
   //ioGraphicsCanvas->lineto_3d(0,0,ROIDimension_mm);

}



//----------------------------------------------------------------------------
// ComputePhaseOffset()
//
// computes a constant phase offset to subtract from the wavefront.
// Offset is the current phase of the wavefront center (optic axis)
//
// called by:  nobody
//
//----------------------------------------------------------------------------
double Wavefront::ComputePhaseOffset()
{
   int theCenterRow = XValueToRowIndex(Width_mm/2);
   int theCenterColumn = YValueToColumnIndex(Width_mm/2);

   double thePhaseOffSet_rad = Phase_rad[theCenterRow][theCenterColumn];


   return thePhaseOffSet_rad;



}




//---------------------------------------------------------------------------
// WriteEntirePhaseDataToFile
//
// Writes the solution matrix to a text file, compatible with loading
// into Microsoft Excel, or other utilities
//
// file format:
//
// (Header information)
//
//                            <--(j index / y value, mm)-->
//    (i index)     0                    1            2       3 ...
//  (x value,mm)    0                   0.03         0.06    0.09 ...
//     0   0   phase_rad(0,0)    phase_rad(0,1)
//     1  0.03 phase_rad(1,0)         ...
//
//
// called by: TWavefrontGUIForm::FileSaveExecute()
//
//---------------------------------------------------------------------------
void Wavefront::WriteEntirePhaseDataToFile()
{

   fstream iofile(EntireDataFileName.c_str(), ios::out);

   if (iofile.fail())
   {
      // trap file I/O error here
   }
   else
   {
      iofile << "File Name: " << EntireDataFileName << '\n';
      iofile << "ROI Dimension, mm: " << ROIDimension_mm << '\n';
      iofile << "Pupil Radius, mm: " << PupilRadius_mm << '\n';
      iofile << "Array Dimension: " << ArrayDimension << '\n';
      iofile << "Width, mm: " << Width_mm << '\n';
      iofile << "Mesh Size, mm: " << MeshSize_mm << '\n';
      iofile << "Wavelength, nm: " << Wavelength_nm << '\n';

      iofile << "Phase Data, micrometers (below)" << '\n';

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

         // one row of data
         for (int j=0;j<=ArrayDimension;j++)
         {
            iofile << Phase_um[i][j] << '\t';
         }
         // end one row of data
         iofile << endl;
      }

   }
   iofile.close();

}



//---------------------------------------------------------------------------
// WritePhaseDataWithinPupilToFile
//
// Writes the wavefront phase data to a text file, compatible with loading
// into Microsoft Excel, or other utilities
//
// file format:
//
// (Header information)
//
//                            <--(j index / y value, mm)-->
//    (i index)     0                    1            2       3 ...
//  (x value,mm)    0                   0.03         0.06    0.09 ...
//     0   0   phase_rad(0,0)    phase_rad(0,1)
//     1  0.03 phase_rad(1,0)         ...
//
//
// called by: TForm1::FileSaveExecute()
//
//---------------------------------------------------------------------------
void Wavefront::WritePhaseDataWithinPupilToFile()
{

   double thePhase_um;

   fstream iofile(PupilDataFileName.c_str(), ios::out);

   if (iofile.fail())
   {
      // trap file I/O error here
   }
   else
   {
      iofile << "File Name: " << PupilDataFileName << '\n';
      iofile << "ROI Dimension, mm: " << ROIDimension_mm << '\n';
      iofile << "Pupil Radius, mm: " << PupilRadius_mm << '\n';
      iofile << "Array Dimension: " << ArrayDimension << '\n';
      iofile << "Width, mm: " << Width_mm << '\n';
      iofile << "Mesh Size, mm: " << MeshSize_mm << '\n';
      iofile << "Wavelength, nm: " << Wavelength_nm << '\n';

      iofile << "Phase Data, in micrometers (below)" << '\n';

      // column index of center of wavefront (optic axis)
      int theJC = YValueToColumnIndex(Width_mm/2);

       // write row index to file (column header #1)

      double theLowPupilValue_mm = Width_mm/2 - PupilRadius_mm;
      double theHighPupilValue_mm = Width_mm/2 + PupilRadius_mm;

      int theLowRowIndex = XValueToRowIndex(theLowPupilValue_mm);
      int theHighRowIndex = XValueToRowIndex(theHighPupilValue_mm);
      int theLowColumnIndex = YValueToColumnIndex(theLowPupilValue_mm);
      int theHighColumnIndex = YValueToColumnIndex(theHighPupilValue_mm);

      // write 2 rows of column headings for the data.
      // 1st row contains integer array index values for each column
      for (int i=theLowRowIndex-2;i<=theHighRowIndex;i++)
      {
         iofile << i << '\t';
      }
      iofile << endl;

      // 2nd row contains the X-value corresponding to each column
      for (int i=theLowRowIndex-2;i<=theHighRowIndex;i++)
      {
        iofile << i*MeshSize_mm << '\t';
      }
      iofile << endl;


      // write solution to a file as a matrix of numbers
      for (int i=theLowRowIndex;i<=theHighRowIndex;i++)
      {

        // populate header column with index, and y-value
        // corresponding to each row.
        iofile << i << '\t' << i*MeshSize_mm << '\t';
        // one row of data
        for (int j=theLowColumnIndex;j<=theHighColumnIndex;j++)
        {
           // thePhase_um = 1e6 * Phase_rad[i][j] * Wavelength_MKS / ( 2* PI);
           if (PointIsWithinPupil(i,j))
           {
              iofile << Phase_um[i][j] << '\t';
           }
           else
           {
              iofile << "0" << '\t';
           }

        }
        // end one row of data
        iofile << endl;

      }

   }
   iofile.close();

}



//---------------------------------------------------------------------------
// WritePhaseDataWithinROIToFile
//
// Writes the wavefront phase data to a text file, compatible with loading
// into Microsoft Excel, or other utilities
//
// file format:
//
// (Header information)
//
//                            <--(j index / y value, mm)-->
//    (i index)     0                    1            2       3 ...
//  (x value,mm)    0                   0.03         0.06    0.09 ...
//     0   0   phase_rad(0,0)    phase_rad(0,1)
//     1  0.03 phase_rad(1,0)         ...
//
//
// called by: TForm1::FileSaveExecute()
//
//---------------------------------------------------------------------------
void Wavefront::WritePhaseDataWithinROIToFile()
{

   double thePhase_um;

   fstream iofile(ROIDataFileName.c_str(), ios::out);

   if (iofile.fail())
   {
      // trap file I/O error here
   }
   else
   {
      iofile << "File Name: " << ROIDataFileName << '\n';
      iofile << "ROI Dimension, mm: " << ROIDimension_mm << '\n';
      iofile << "Pupil Radius, mm: " << PupilRadius_mm << '\n';
      iofile << "Array Dimension: " << ArrayDimension << '\n';
      iofile << "Width, mm: " << Width_mm << '\n';
      iofile << "Mesh Size, mm: " << MeshSize_mm << '\n';
      iofile << "Wavelength, nm: " << Wavelength_nm << '\n';

      iofile << "Phase Data, in radians (below)" << '\n';

      // column index of center of wavefront (optic axis)
      int theJC = YValueToColumnIndex(Width_mm/2);

       // write row index to file (column header #1)

      double theLowPupilValue_mm = Width_mm/2 - PupilRadius_mm;
      double theHighPupilValue_mm = Width_mm/2 + PupilRadius_mm;

      int theLowRowIndex = XValueToRowIndex(theLowPupilValue_mm);
      int theHighRowIndex = XValueToRowIndex(theHighPupilValue_mm);
      int theLowColumnIndex = YValueToColumnIndex(theLowPupilValue_mm);
      int theHighColumnIndex = YValueToColumnIndex(theHighPupilValue_mm);

      // write 2 rows of column headings for the data.
      // 1st row contains integer array index values for each column
      for (int i=theLowRowIndex-2;i<=theHighRowIndex;i++)
      {
         iofile << i << '\t';
      }
      iofile << endl;

      // 2nd row contains the X-value corresponding to each column
      for (int i=theLowRowIndex-2;i<=theHighRowIndex;i++)
      {
        iofile << i*MeshSize_mm << '\t';
      }
      iofile << endl;


      // write solution to a file as a matrix of numbers
      for (int i=theLowRowIndex;i<=theHighRowIndex;i++)
      {

        // populate header column with index, and y-value
        // corresponding to each row.
        iofile << i << '\t' << i*MeshSize_mm << '\t';
        // one row of data
        for (int j=theLowColumnIndex;j<=theHighColumnIndex;j++)
        {
           // thePhase_um = 1e6 * Phase_rad[i][j] * Wavelength_MKS / ( 2* PI);
           if (PointIsWithinROI(i,j))
           {
              iofile << Phase_rad[i][j] << '\t';
           }
           else
           {
              iofile << "0" << '\t';
           }

        }
        // end one row of data
        iofile << endl;

      }

   }
   iofile.close();

}



int Wavefront::XValueToRowIndex(double inXValue_mm)
{

   int theIndex;

   double theXOffset = 0;

   theIndex = (int)( (inXValue_mm-theXOffset)/MeshSize_mm );

   // subscript out of bounds error
   if ( theIndex < 0 || theIndex > ArrayDimension )
        exit(9999);


   return theIndex;

}


int Wavefront::YValueToColumnIndex(double inYValue_mm)
{
   int theIndex;

   double theYOffset = 0;

   theIndex = (int)( (inYValue_mm-theYOffset)/MeshSize_mm );

   // subscript out of bounds error
   if ( theIndex < 0 || theIndex > ArrayDimension )
        exit(9999);

   return theIndex;


}


//--------------------------------------------------------------------------
// PointIsWithinPupil()
//
// return TRUE if the selected point in the wavefront, corresponding
// to (RowIndex, ColumnIndex) is within the current pupil.  The pupil
// is circular, with radius PupilRadius_mm, and is centered within
// the square wavefront.
//
// called by:  DisplayPhase()
//
//--------------------------------------------------------------------------
bool Wavefront::PointIsWithinPupil(int inRowIndex, int inColumnIndex)
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

//--------------------------------------------------------------------------
// PointIsWithinROI()
//
// return TRUE if the selected point in the wavefront, corresponding
// to (RowIndex, ColumnIndex) is within the Region of Interest. Region
// of Interest is circular, centered on the Pupil, with Diameter
// ROIDimension_mm.
//
// called by:  DisplayPhase()
//
//--------------------------------------------------------------------------
bool Wavefront::PointIsWithinROI(int inRowIndex, int inColumnIndex)
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


//--------------------------------------------------------------------------
// R_mm()
//
// Computes radial coordinate of point corresponding to array
// value inRow, inColumn.
//
// Center of pupil is R_mm = 0.
//
//--------------------------------------------------------------------------
double Wavefront::R_mm(int inRow, int inColumn)
{

   return  sqrt(XRel_mm(inRow,inColumn)*XRel_mm(inRow,inColumn) +
                YRel_mm(inRow,inColumn)*YRel_mm(inRow,inColumn) );

}


//--------------------------------------------------------------------------
// Theta_rad()
//
// Computes angular coordinate of point corresponding to array
// value inRow, inColumn.
//
// Center of pupil is R_mm = 0.
//
//--------------------------------------------------------------------------
double Wavefront::Theta_rad(int inRow, int inColumn)
{
   double theXRel_mm = XRel_mm(inRow, inColumn);
   double theYRel_mm = YRel_mm(inRow, inColumn);

    if (theXRel_mm == 0 && theYRel_mm == 0)
    {
        return 0;
    }
    else
    {
        return atan2(theYRel_mm,theXRel_mm);
    }

}


//--------------------------------------------------------------------------
// matrix()
//
// shamelessly lifted from Numerical Recipes
//
// called by:  Wavefront()
//--------------------------------------------------------------------------
double **Wavefront::matrix(int nrl, int nrh, int ncl, int nch)
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
