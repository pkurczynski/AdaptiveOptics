//--------------------------------------------------------------------------
// Graphics3d.cpp                                C++ class
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
//--------------------------------------------------------------------------

#include "Graphics3d.h"
#include <math.h>

Graphics3d *theGraphics3d;


//----------------------------------------------------------------------------
// Graphics3d
//
// Constructs a Graphics3d object.
//
// arguments:  inR, inTheta, inPhi
//                      spherical coordinates of viewer  (Theta-azimuthal)
//             inWindowWidth, inWindowHeight
//                      Width, Height of the graphics canvas (eg PaintBox)
//             inXoffset, inYoffset
//                      X,Y offset of the origin of 3d coordinate system
//                      from the center of the graphics canvas (screen/pixel
//                      units).  X increases to the left, and Y increases
//                      downwards.
//----------------------------------------------------------------------------
Graphics3d::Graphics3d(double inR, double inTheta, double inPhi,
        int inWindowWidth, int inWindowHeight,
        int inXoffset, int inYoffset, TCanvas *inCanvas)
{


   r = inR;

   // set the azimuthal angle
   theta = inTheta;

   // set the polar angle
   phi = inPhi;

   WindowHeight = inWindowHeight;
   WindowWidth = inWindowWidth;

   theCanvas = inCanvas;
   Xoffset = inXoffset;
   Yoffset = inYoffset;

   /*distance from center of projection to view origin */
   dview= 500;

   ViewSetup(r,theta,phi);

}

void Graphics3d::SetPenColor(TColor inColor)
{
   theCanvas->Pen->Color=inColor;
}


void Graphics3d::SetCanvas(TCanvas *inCanvas)
{
   theCanvas = inCanvas;
}


//----------------------------------------------------------------------------
// ViewSetup
//
// Establishes a particular 3d Viewing system by setting the tview and
// center of projection vector.
//
// arguments:   inR             Radial coordinate of the viewer
//              inTheta         Azimuthal angle of viewer (degrees)
//              inPhi           Polar angle of view (degrees)
//
// called by:  Graphics3d (constructor)
//----------------------------------------------------------------------------
void Graphics3d::ViewSetup(double inR, double inTheta, double inPhi)
{

   // this is a hack to make things work
   inPhi = 180 - inPhi;

   inPhi*=PI/180;
   inTheta*=PI/180;

   
   //dview,cop_vect[3],tview[4][4] defined externally

   /*view transformation matrix p(world)-->p(view) */
   tview[0][0]=-sin(inTheta);
   tview[0][1]=-cos(inTheta)*cos(inPhi);
   tview[0][2]=-cos(inTheta)*sin(inPhi);
   tview[0][3]=0;
   tview[1][0]=cos(inTheta);
   tview[1][1]=-sin(inTheta)*cos(inPhi);
   tview[1][2]=-sin(inTheta)*sin(inPhi);
   tview[1][3]=0;
   tview[2][0]=0;
   tview[2][1]=sin(inPhi);
   tview[2][2]=-cos(inPhi);
   tview[2][3]=0;
   tview[3][0]=0;
   tview[3][1]=0;
   tview[3][2]=inR;
   tview[3][3]=1;

   /*center of projection vector: r(xcop,ycop,zcop) */
   cop_vect[0]=inR*sin(inPhi)*cos(inTheta);
   cop_vect[1]=inR*sin(inPhi)*sin(inTheta);
   cop_vect[2]=inR*cos(inPhi);
}



void Graphics3d::moveto_3d(double xw, double yw, double zw)
{
   double worldpoint[4];
   double viewpoint[4];
   double xs,ys,denom;
   int i,j,k;

   worldpoint[0]=xw;
   worldpoint[1]=yw;

   // this is a hack to make things work
   worldpoint[2]=-1*zw;

   worldpoint[3]=1;

   /*transform p(world)-->p(view) */
   for (j=0;j<4;j++)   {
      viewpoint[j]=0;
      for (k=0;k<4;k++)   {
	 viewpoint[j]+=worldpoint[k]*tview[k][j];
      }
   }

   /*p(view)-->xs,ys..._lineto_w */
   denom= ((viewpoint[2]/dview)==0) ? .01 : viewpoint[2]/dview;
   xs=viewpoint[0]/denom;
   ys=viewpoint[1]/denom;

   // translate from screen coordinates with 0,0 at center to
   // pixel/window coordinates with 0,0 at upper left

   xs+=(double)(WindowWidth/2);
   ys+=(double)(WindowHeight/2);

   // offset screen coordinates by specified amount to place
   // the origin of view coordinates at a specified screen location
   xs+=Xoffset;
   ys+=Yoffset;

   // substitute appropriate command here to move_to the point (xs,ys)
   theCanvas->MoveTo(xs,ys);

   return;
}


void Graphics3d::lineto_3d(double xw, double yw, double zw)
{
   double worldpoint[4];
   double viewpoint[4];
   double xs,ys,denom;
   int i,j,k;

   worldpoint[0]=xw;
   worldpoint[1]=yw;

   // this is a hack to make things work
   worldpoint[2]=-1*zw;

   worldpoint[3]=1;

   /*transform p(world)-->p(view) */
   for (j=0;j<4;j++)   {
      viewpoint[j]=0;
      for (k=0;k<4;k++)   {
	 viewpoint[j]+=worldpoint[k]*tview[k][j];
      }
   }

   /*p(view)-->xs,ys..._lineto_w */
   denom= ((viewpoint[2]/dview)==0) ? .01 : viewpoint[2]/dview;
   xs=viewpoint[0]/denom;
   ys=viewpoint[1]/denom;


   // translate from screen coordinates with 0,0 at center to
   // pixel/window coordinates with 0,0 at upper left

   xs+=(double)(WindowWidth/2);
   ys+=(double)(WindowHeight/2);

   // offset screen coordinates by specified amount to place
   // the origin of view coordinates at a specified screen location
   xs+=Xoffset;
   ys+=Yoffset;


   // substitute the appropriate command here to _line_to the point (xs,ys)
   theCanvas->LineTo(xs,ys);

   return;
}
 