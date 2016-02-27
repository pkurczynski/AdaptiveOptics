//---------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "EditAberrationsDlg.h"
//---------------------------------------------------------------------
#pragma resource "*.dfm"
TEditAberrationsDialog *EditAberrationsDialog;
//--------------------------------------------------------------------- 
__fastcall TEditAberrationsDialog::TEditAberrationsDialog(TComponent* AOwner)
	: TForm(AOwner)
{
}
//---------------------------------------------------------------------


//---------------------------------------------------------------------
// Execute()
//
// Executes the Dialog box, and sets component data values to their
// user-updated values, if the user clicks "OK."   Frees the dialog
// box after the user closes it.
//
// called by:  TWavefrontGUIForm::EditAberrationsExecute(TObject *Sender)
//
//---------------------------------------------------------------------
bool __fastcall TEditAberrationsDialog::Execute()
{
   EditAberrationsDialog = new TEditAberrationsDialog(Application);
   bool Result;

   try
   {
#if 0


   double  theAberrationConstant = AberrationConstantEditBox->Text.ToDouble();
   double  theAberrationTip = AberrationTipEditBox->Text.ToDouble();
   double  theAberrationTilt = AberrationTiltEditBox->Text.ToDouble();
   double  theAberrationAstigmatism =
                AberrationAstigmatismEditBox->Text.ToDouble();
   double  theAberrationDefocus = AberrationDefocusEditBox->Text.ToDouble()

      EditAberrationsDialog->AberrationsStressEditBox->Text =
         WavefrontGUIForm->theAberrationsStress_MPa;
      EditAberrationsDialog->AberrationsThicknessEditBox->Text =
         WavefrontGUIForm->theAberrationsThickness_um;
      EditAberrationsDialog->AberrationsGapDistanceEditBox->Text =
         WavefrontGUIForm->theAberrationsGapDistance_um ;
#endif

      Result = (EditAberrationsDialog->ShowModal() == IDOK );

     

#if 0
      WavefrontGUIForm->theAberrationsStress_MPa        =
         EditAberrationsDialog->AberrationsStressEditBox->Text.ToDouble();
      WavefrontGUIForm->theAberrationsThickness_um =
         EditAberrationsDialog->AberrationsThicknessEditBox->Text.ToDouble();
      WavefrontGUIForm->theAberrationsGapDistance_um  =
         EditAberrationsDialog->AberrationsGapDistanceEditBox->Text.ToDouble();
#endif
   }
   catch(...)
   {
      Result = false;
   }
   EditAberrationsDialog->Free();

   return Result;
}

