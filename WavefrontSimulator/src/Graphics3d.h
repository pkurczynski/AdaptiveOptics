//---------------------------------------------------------------------------
// Graphics3d.h                                   C++ Header file
//
// This class implements a four + two parameter, 3D graphics system.
// The viewer is located at coordinates (r, theta, phi) in 3d space,
// and the viewer looks at the origin of the 3d coordinate system.
//
// In addition, the origin of coordinates may be offset within the
// graphics window by specifying Xoffset, Yoffset in screen/pixel units
//
// plk
// 01/12/2001
//---------------------------------------------------------------------------

#ifndef Graphics3dH
#define Graphics3dH

#include <vcl.h>

#define PI 3.1415926

class Graphics3d
{
   private:

        double r;                         // radial coordinate of viewer
        double theta;                     // azimuthal coordinate of viewer
        double phi;                       // polar coordinate of viewer

        double dview;        // dist. to center of projection (set empirically)
        double tview[4][4];
        double cop_vect[3];

        int WindowHeight;                // dimensions of Paintbox
        int WindowWidth;                 // drawing canvas

        int Xoffset;                    // x,y offset of view origin
        int Yoffset;                    // in screen (pixel) coordinates
                                        // NOTE:  Xoffset = 0 at upper left
        // of drawing canvas and increases to the right.  Yoffset = 0 at
        // upper left of canvas and increases downwards.




        TCanvas *theCanvas;             // pointer to drawing canvas

   public:


       Graphics3d(double inR, double inTheta, double inPhi,
                int inWindowWidth, int inWindowHeight,
                int inXoffset, int inYoffset, TCanvas *inCanvas);
       void SetPenColor(TColor inColor);
       void SetCanvas(TCanvas *inCanvas);
       void ViewSetup(double inR, double inTheta, double inPhi);
       void moveto_3d(double xw, double yw, double zw);
       void lineto_3d(double xw, double yw, double zw);

};

extern Graphics3d *theGraphics3d;


#endif