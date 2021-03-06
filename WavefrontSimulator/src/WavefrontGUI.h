//---------------------------------------------------------------------------

#ifndef WavefrontGUIH
#define WavefrontGUIH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include <ExtCtrls.hpp>
#include <ActnList.hpp>
#include <Menus.hpp>
#include <ComCtrls.hpp>
#include <vcl.h>
#include "conio.h"
#include "Wavefront.h"
#include "AberratedWavefront.h"
#include "Graphics3d.h"
#include "MembraneInverseProblem.h"
#include "EditWavefrontDlg.h"
#include "EditMembraneDlg.h"
#include "EditBiasLensDlg.h"
#include "WavefrontZOffsetDlg.h"
#include "ZCoeffTable.h"
#include "Lens.h"
#include <Dialogs.hpp>
//---------------------------------------------------------------------------
class TWavefrontGUIForm : public TForm
{
__published:	// IDE-managed Components
        TMainMenu *MainMenu1;
        TMenuItem *File1;
        TMenuItem *New1;
        TMenuItem *Solve1;
        TMenuItem *Exit1;
        TActionList *ActionList1;
        TAction *FileNew;
        TAction *FileSave;
        TAction *FileExit;
        TMenuItem *Optics1;
        TMenuItem *Simulation;
        TGroupBox *GroupBox6;
        TPaintBox *WavefrontPaintBox;
        TMemo *Memo1;
        TGroupBox *GroupBox4;
        TPaintBox *MembranePaintBox;
        TGroupBox *GroupBox7;
        TPaintBox *RealElectrodePaintBox;
        TGroupBox *GroupBox8;
        TPaintBox *ImagElectrodePaintBox;
        TAction *RunElectrodeSolver;
        TAction *RunMembraneSolver;
        TMenuItem *MembraneSolver1;
        TGroupBox *GroupBox2;
        TLabel *Label2;
        TLabel *Label1;
        TStaticText *StaticText7;
        TStaticText *StaticText8;
        TStaticText *StaticText9;
        TStaticText *StaticText1;
        TStaticText *StaticText2;
        TStaticText *StaticText3;
        TAction *EditWavefront;
        TAction *EditMembrane;
        TAction *EditBiasLens;
        TMenuItem *Edit1;
        TMenuItem *BiasLens1;
        TMenuItem *Membrane1;
        TMenuItem *Wavefront1;
        TMenuItem *Aberrations1;
        TAction *EditAberrations;
        TAction *WavefrontBias;
        TAction *WavefrontUnBias;
        TMenuItem *Wavefront2;
        TMenuItem *Bias1;
        TMenuItem *UnBias1;
        TAction *FileOpen;
        TMenuItem *Open1;
        TOpenDialog *ZCoeffFileOpenDialog;
        TAction *WavefrontZOffset;
        TMenuItem *ZOffset1;
        


        void __fastcall WavefrontPaintBoxOnPaint(TObject *Sender);
        void __fastcall MembranePaintBoxPaint(TObject *Sender);
        void __fastcall RealElectrodePaintBoxPaint(TObject *Sender);
        void __fastcall ImagElectrodePaintBoxPaint(TObject *Sender);
        void __fastcall Form1MouseMove(TObject *Sender, TShiftState Shift, int X, int Y);
        void __fastcall Button1MouseDown(TObject *Sender, TMouseButton Button, TShiftState Shift, int X, int Y);
        void __fastcall FileNewExecute(TObject *Sender);
        void __fastcall FileExitExecute(TObject *Sender);
        void __fastcall FileSaveExecute(TObject *Sender);
        void __fastcall RunElectrodeSolverExecute(TObject *Sender);
        void __fastcall RunMembraneSolverExecute(TObject *Sender);
        void __fastcall EditWavefrontExecute(TObject *Sender);
        void __fastcall EditMembraneExecute(TObject *Sender);
        void __fastcall EditAberrationsExecute(TObject *Sender);
        void __fastcall EditBiasLensExecute(TObject *Sender);
        void __fastcall WavefrontBiasExecute(TObject *Sender);
        void __fastcall WavefrontUnBiasExecute(TObject *Sender);
        void __fastcall FileOpenExecute(TObject *Sender);
        void __fastcall WavefrontZOffsetExecute(TObject *Sender);



private:

        // User declarations
        void Initialize_Graphics();
        void Reset_Wavefront();

public:
        double  theWavefrontWidth_mm;
        double  theWavefrontROIDimension_mm;
        double  theWavefrontPupilRadius_mm;
        int     theWavefrontArrayDimension;

        double theMembraneStress_MPa;
        double theMembraneThickness_um;
        double theMembraneGapDistance_um;
        double theMembraneTopElectrode_V;
        double theMembraneTopElectrodeDistance_um;

        // NUMBEROFZERNIKES is set in AberratedWavefront.h
        double  theAberrationCoeff[NUMBEROFZERNIKES];

        bool    theWavefrontIsBiased;
        double  theLensFocalLength_mm;

        double  theWavefrontZOffset_um;

        // these pointer declarations are made here because
        // pointer declarations in the respective class definition
        // files are not suitable for this program.
        // global scope.  Place in form?


        Lens                    *theLens;
        AberratedWavefront      *theWavefront;
        MembraneInverseProblem  *theMembraneInverseProblem;
        Graphics3d              *theWavefrontCanvas;
        Graphics3d              *theMembraneCanvas;
        Graphics3d              *theRealElectrodeVoltageCanvas;
        Graphics3d              *theImagElectrodeVoltageCanvas;


        int StartX, StartY;
        double ViewR, ViewTheta, ViewPhi;


	// User declarations
        __fastcall TWavefrontGUIForm(TComponent* Owner);

};
//---------------------------------------------------------------------------
extern PACKAGE TWavefrontGUIForm *WavefrontGUIForm;
//---------------------------------------------------------------------------
#endif
