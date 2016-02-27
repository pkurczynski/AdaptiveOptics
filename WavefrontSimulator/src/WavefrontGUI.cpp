//---------------------------------------------------------------------------
#include "WavefrontGUI.h"

#pragma hdrstop
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma resource "*.dfm"
TWavefrontGUIForm *WavefrontGUIForm;

//---------------------------------------------------------------------------
__fastcall TWavefrontGUIForm::TWavefrontGUIForm(TComponent* Owner)
        : TForm(Owner)
{

  // Default values of simulation parameters.
  // Loaded on program execution.

  theWavefrontWidth_mm          = 20;
  theWavefrontROIDimension_mm   = 20;    // Must be > 2*PupilRadius or div0!
  theWavefrontPupilRadius_mm    =  5;
  theWavefrontArrayDimension    = 50;

  theMembraneStress_MPa         = 10;
  theMembraneThickness_um       = 1;
  theMembraneGapDistance_um     = 20;
  theMembraneTopElectrode_V     = 0;
  theMembraneTopElectrodeDistance_um = 20;

  // default aberration coefficients.
  // all array elements are initialized
  // to zero by default.
  theAberrationCoeff[4]         = 5;

  theWavefrontIsBiased          = false;
  theLensFocalLength_mm         = 5000;

  theWavefrontZOffset_um        = 0;

  ViewR                         = 60;
  ViewTheta                     = 60;
  ViewPhi                       = 70;

  Memo1->Lines->Add("Loaded Default Simulation Parameters:");

  StaticText7->Caption=FormatFloat("0.00",ViewR);
  StaticText8->Caption=(AnsiString) ViewTheta;
  StaticText9->Caption=(AnsiString) ViewPhi;

  Initialize_Graphics();

  theWavefront = new AberratedWavefront(theWavefrontWidth_mm,
                                         theWavefrontArrayDimension,
                                         theWavefrontROIDimension_mm,
                                         theWavefrontPupilRadius_mm,
                                         theWavefrontZOffset_um,
                                         theAberrationCoeff);


  theMembraneInverseProblem = new MembraneInverseProblem(theWavefront,
                                        theMembraneStress_MPa,
                                        theMembraneThickness_um,
                                        theMembraneGapDistance_um,
                                        theMembraneTopElectrode_V,
                                        theMembraneTopElectrodeDistance_um);

  Memo1->Lines->Add("Constructed, solved default problem.");
  Memo1->Lines->Add(" ");

}
//---------------------------------------------------------------------------




void __fastcall TWavefrontGUIForm::Button1MouseDown(TObject *Sender,
                                         TMouseButton Button,
                                         TShiftState Shift,
                                         int X,
                                         int Y)
{
  StartX = X;
  StartY = Y;

}


void __fastcall TWavefrontGUIForm::Form1MouseMove(TObject *Sender,
                                       TShiftState Shift,
                                       int X,
                                       int Y)
{

   if (Shift.Contains(ssLeft)) // make sure button is down
   {
      double NewTheta = ViewTheta + (StartX - X);
      double NewPhi = ViewPhi + (StartY - Y);
      StaticText8->Caption = (AnsiString) NewTheta;
      StaticText9->Caption = (AnsiString) NewPhi;
      theWavefrontCanvas->ViewSetup(ViewR,NewTheta, NewPhi);
      theMembraneCanvas->ViewSetup(ViewR,NewTheta, NewPhi);
      theRealElectrodeVoltageCanvas->ViewSetup(ViewR,NewTheta, NewPhi);
      theImagElectrodeVoltageCanvas->ViewSetup(ViewR,NewTheta, NewPhi);

   }

   if (Shift.Contains(ssRight)) // make sure button is down
   {
      ViewR += 0.01*(StartY - Y);
      StaticText7->Caption = FormatFloat("0.00",ViewR);
      theWavefrontCanvas->ViewSetup(ViewR,ViewTheta, ViewPhi);
      theMembraneCanvas->ViewSetup(ViewR,ViewTheta, ViewPhi);
      theRealElectrodeVoltageCanvas->ViewSetup(ViewR,ViewTheta, ViewPhi);
      theImagElectrodeVoltageCanvas->ViewSetup(ViewR,ViewTheta, ViewPhi);

   }

   WavefrontPaintBox->Canvas->FloodFill(ClientWidth/8,
                                        ClientHeight/8,
                                        clBlack,
                                        fsBorder);
   WavefrontPaintBoxOnPaint(Sender);

   MembranePaintBox->Canvas->FloodFill(ClientWidth/8,
                                       ClientHeight/8,
                                       clBlack,
                                       fsBorder);
   MembranePaintBoxPaint(Sender);

   RealElectrodePaintBox->Canvas->FloodFill(ClientWidth/8,
                                            ClientHeight/8,
                                            clBlack,
                                            fsBorder);
   RealElectrodePaintBoxPaint(Sender);

   ImagElectrodePaintBox->Canvas->FloodFill(ClientWidth/8,
                                            ClientHeight/8,
                                            clBlack,
                                            fsBorder);
   ImagElectrodePaintBoxPaint(Sender);

}


//---------------------------------------------------------------------------
// PaintBox coordinate system (screen coordinates within the GUI window)
//
// (0,0)              . . .           (ClientWidth,0)
//
//   .                                      .
//   .                                      .
//   .                                      .
//
// (0, ClientHeight)   . . .    (ClientWidth, ClientHeight)
//---------------------------------------------------------------------------
void __fastcall TWavefrontGUIForm::WavefrontPaintBoxOnPaint(TObject *Sender)
{

  // this is where you paint the picture
  //theWavefront->DisplayXYPlane(theWavefrontCanvas);
  theWavefront->DisplayPhase(theWavefrontCanvas);

}
//---------------------------------------------------------------------------



void __fastcall TWavefrontGUIForm::MembranePaintBoxPaint(TObject *Sender)
{
        theMembraneInverseProblem->ScaleDataForGraphicsDisplay();
        theMembraneInverseProblem->DisplaySolution(theMembraneCanvas);

}
//---------------------------------------------------------------------------


void __fastcall TWavefrontGUIForm::RealElectrodePaintBoxPaint(TObject *Sender)
{
       // theMembraneInverseProblem->ScaleDataForGraphicsDisplay();
        theMembraneInverseProblem->
                DisplayRealElectrodeVoltage(theRealElectrodeVoltageCanvas);
        //theMembraneInverseProblem->DisplayImagElectrodeVoltage(theRealElectrodeVoltageCanvas);
}
//---------------------------------------------------------------------------



void __fastcall TWavefrontGUIForm::ImagElectrodePaintBoxPaint(TObject *Sender)
{
       // theMembraneInverseProblem->ScaleDataForGraphicsDisplay();
        theMembraneInverseProblem->
                DisplayImagElectrodeVoltage(theImagElectrodeVoltageCanvas);
}
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
// Reset_Wavefront()
//
// deletes an existing MembranePDEproblem and re-creates it with
// updated parameters taken from the graphics window.
//
// This method and the TForm::TForm() constructor are the only methods
// that call the MembranePDEproblem::MembranePDEproblem() constructor.
//
// called by:
//             TWavefrontGUIForm::RunElectrodeSolverExecute()
//             TWavefrontGUIForm::FileNewExecute()
//
//---------------------------------------------------------------------------
void TWavefrontGUIForm::Reset_Wavefront()
{

   // theWavefront and theMembraneInverseProblem have not been
   // allocated on first call to this method.   However, compiler
   // doesn't seem to mind 'delete'-ing them anyways.  plk 5/1/2003

   delete theWavefront;
   delete theMembraneInverseProblem;

   theWavefront = new AberratedWavefront(theWavefrontWidth_mm,
                                         theWavefrontArrayDimension,
                                         theWavefrontROIDimension_mm,
                                         theWavefrontPupilRadius_mm,
                                         theWavefrontZOffset_um,
                                         theAberrationCoeff);
   Memo1->Lines->Add("Created Aberrated Wavefront.");
   Memo1->Lines->Add(" ");

   if (theWavefrontIsBiased)
        WavefrontBiasExecute(this);

   theMembraneInverseProblem = new MembraneInverseProblem(theWavefront,
                                        theMembraneStress_MPa,
                                        theMembraneThickness_um,
                                        theMembraneGapDistance_um,
                                        theMembraneTopElectrode_V,
                                        theMembraneTopElectrodeDistance_um);
   Memo1->Lines->Add("Solved Electrode Voltages.");
   Memo1->Lines->Add(" ");


}

//---------------------------------------------------------------------------
// Initialize_Graphics()
//
// called by:  TWavefrontGUIForm::TWavefrontGUIForm()
//
//---------------------------------------------------------------------------
void TWavefrontGUIForm::Initialize_Graphics()
{

  int ViewXoffset = 0;
  int ViewYoffset = -20;

  int WavefrontCanvasWidth = WavefrontPaintBox->ClientWidth;
  int WavefrontCanvasHeight = WavefrontPaintBox->ClientHeight;

  int WavefrontCanvasXoffset = 0;
  int WavefrontCanvasYoffset = -20;

  theWavefrontCanvas = new Graphics3d(ViewR,
                                      ViewTheta,
                                      ViewPhi,
                                      WavefrontCanvasWidth,
                                      WavefrontCanvasHeight,
                                      WavefrontCanvasXoffset,
                                      WavefrontCanvasYoffset,
                                      WavefrontPaintBox->Canvas);

  int MembraneCanvasWidth = MembranePaintBox->ClientWidth;
  int MembraneCanvasHeight = MembranePaintBox->ClientHeight;

  int MembraneCanvasXoffset = 0;
  int MembraneCanvasYoffset = -20;

  theMembraneCanvas = new Graphics3d(ViewR,
                                      ViewTheta,
                                      ViewPhi,
                                      MembraneCanvasWidth,
                                      MembraneCanvasHeight,
                                      MembraneCanvasXoffset,
                                      MembraneCanvasYoffset,
                                      MembranePaintBox->Canvas);


  int ElectrodeCanvasWidth = RealElectrodePaintBox->ClientWidth;
  int ElectrodeCanvasHeight = RealElectrodePaintBox->ClientHeight;

  int ElectrodeCanvasXoffset = 0;
  int ElectrodeCanvasYoffset = -20;

  theRealElectrodeVoltageCanvas = new Graphics3d(ViewR,
                                      ViewTheta,
                                      ViewPhi,
                                      ElectrodeCanvasWidth,
                                      ElectrodeCanvasHeight,
                                      ElectrodeCanvasXoffset,
                                      ElectrodeCanvasYoffset,
                                      RealElectrodePaintBox->Canvas);

  ElectrodeCanvasWidth = ImagElectrodePaintBox->ClientWidth;
  ElectrodeCanvasHeight = ImagElectrodePaintBox->ClientHeight;

  ElectrodeCanvasXoffset = 0;
  ElectrodeCanvasYoffset = -20;

  theImagElectrodeVoltageCanvas = new Graphics3d(ViewR,
                                      ViewTheta,
                                      ViewPhi,
                                      ElectrodeCanvasWidth,
                                      ElectrodeCanvasHeight,
                                      ElectrodeCanvasXoffset,
                                      ElectrodeCanvasYoffset,
                                      ImagElectrodePaintBox->Canvas);
}


//---------------------------------------------------------------------------
// FileNewExecute()
//
// Restore the default membrane parameters.  Solve the membrane problem.
//
//---------------------------------------------------------------------------
void __fastcall TWavefrontGUIForm::FileNewExecute(TObject *Sender)
{

   theWavefrontIsBiased = 0;
   Memo1->Clear();
   Reset_Wavefront();

}
//---------------------------------------------------------------------------



void __fastcall TWavefrontGUIForm::FileOpenExecute(TObject *Sender)
{
   if(ZCoeffFileOpenDialog->Execute())
   {

      AnsiString filename = ZCoeffFileOpenDialog->FileName;
   }

}
//---------------------------------------------------------------------------


void __fastcall TWavefrontGUIForm::FileSaveExecute(TObject *Sender)
{

   theWavefront->WritePhaseDataWithinPupilToFile();
   theWavefront->WriteEntirePhaseDataToFile();
   theWavefront->WritePhaseDataWithinROIToFile();

   theMembraneInverseProblem->WriteElectrodeDataToFile();

   theMembraneInverseProblem->WriteEntireSolutionDataToFile();
   theMembraneInverseProblem->WriteROISolutionDataToFile();

}
//---------------------------------------------------------------------------


void __fastcall TWavefrontGUIForm::FileExitExecute(TObject *Sender)
{
   Close();
}
//---------------------------------------------------------------------------



void __fastcall TWavefrontGUIForm::EditWavefrontExecute(TObject *Sender)
{
   if (EditWavefrontDialog->Execute())
   {
   }

}
//---------------------------------------------------------------------------

void __fastcall TWavefrontGUIForm::EditMembraneExecute(TObject *Sender)
{
   if (EditMembraneDialog->Execute())
   {
   }
}

//---------------------------------------------------------------------------
// EditAberrationsExecute()
//
// Display the ZernikeCoefficient table, which was read in from
// the Excel file "ZernikeCoefficients_v1.dbf" on program execution.
// Coefficients from this file are stored in theAberrationCoeff[]
// array for passing to the Wavefront simulator.
//
// Changes to the underlying dBase file are automatically saved when
// the form and Table are closed.
//
// Data is copied from the Table (after user input) before closing
// the data entry window (BeforeClose event of ZCoeffTable).  Therefore
// data table is opened and closed explicitly in this method.
//
// event handler for OnExecute
//---------------------------------------------------------------------------

void __fastcall TWavefrontGUIForm::EditAberrationsExecute(TObject *Sender)
{

    ZCoeffTableForm = new TZCoeffTableForm(this);
    ZernikeCoeffDataModule->ZCoeffTable->Open();
    ZCoeffTableForm->ShowModal();
    ZernikeCoeffDataModule->ZCoeffTable->Close();
    delete ZCoeffTableForm;


}
//---------------------------------------------------------------------------



void __fastcall TWavefrontGUIForm::EditBiasLensExecute(TObject *Sender)
{
   if (EditBiasLensDialog->Execute())
   {
   }
}
//---------------------------------------------------------------------------

void __fastcall TWavefrontGUIForm::WavefrontBiasExecute(TObject *Sender)
{
      //refract wavefront through the bias lens
      theLens = new Lens(theLensFocalLength_mm);
      theLens->Refract(theWavefront);
      delete theLens;

      theWavefrontIsBiased = true;

}
//---------------------------------------------------------------------------

void __fastcall TWavefrontGUIForm::WavefrontUnBiasExecute(TObject *Sender)
{

      //un-refract wavefront through the bias lens
      theLens = new Lens( -1*theLensFocalLength_mm );
      theLens->Refract(theWavefront);
      delete theLens;

      theWavefrontIsBiased = false;

}
//---------------------------------------------------------------------------

void __fastcall TWavefrontGUIForm::WavefrontZOffsetExecute(TObject *Sender)
{
   if (WavefrontZOffsetDialog->Execute())
   {
   }
}
//---------------------------------------------------------------------------


//---------------------------------------------------------------------------
// RunElectrodeSolverExecute()
//
// Computes Membrane surface deformation required to generate the
// current wavefront, and the electrode voltage distribution necessary
// to create the desired membrane shape.
//
//---------------------------------------------------------------------------
void __fastcall TWavefrontGUIForm::RunElectrodeSolverExecute(TObject *Sender)
{
    Reset_Wavefront();

}
//---------------------------------------------------------------------------



//---------------------------------------------------------------------------
// RunMembraneSolverExecute()
//
// Computes Membrane surface deformation required to generate the
// current wavefront, and the electrode voltage distribution necessary
// to create the desired membrane shape.
//
//---------------------------------------------------------------------------
void __fastcall TWavefrontGUIForm::RunMembraneSolverExecute(TObject *Sender)
{

   theMembraneInverseProblem->SetRHS();
   theMembraneInverseProblem->SolveBySOR();

}
//---------------------------------------------------------------------------

