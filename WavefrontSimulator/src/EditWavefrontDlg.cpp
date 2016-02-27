//---------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "EditWavefrontDlg.h"
#include "WavefrontGUI.h"

//---------------------------------------------------------------------
#pragma resource "*.dfm"
TEditWavefrontDialog *EditWavefrontDialog;
//---------------------------------------------------------------------
__fastcall TEditWavefrontDialog::TEditWavefrontDialog(TComponent* AOwner)
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
// called by:  TWavefrontGUIForm::EditWavefrontExecute(TObject *Sender)
//
//---------------------------------------------------------------------
bool __fastcall TEditWavefrontDialog::Execute()
{
   EditWavefrontDialog = new TEditWavefrontDialog(Application);
   bool Result;

   try
   {
      EditWavefrontDialog->WavefrontWidthEditBox->Text =
         WavefrontGUIForm->theWavefrontWidth_mm;
      EditWavefrontDialog->WavefrontROIRadiusEditBox->Text =
         0.5 *WavefrontGUIForm->theWavefrontROIDimension_mm;
      EditWavefrontDialog->WavefrontPupilRadiusEditBox->Text =
         WavefrontGUIForm->theWavefrontPupilRadius_mm ;
      EditWavefrontDialog->WavefrontArrayDimensionEditBox->Text =
         WavefrontGUIForm->theWavefrontArrayDimension ;

      Result = (EditWavefrontDialog->ShowModal() == IDOK );

      WavefrontGUIForm->theWavefrontWidth_mm        =
         EditWavefrontDialog->WavefrontWidthEditBox->Text.ToDouble();
      WavefrontGUIForm->theWavefrontROIDimension_mm =
         2 * EditWavefrontDialog->WavefrontROIRadiusEditBox->Text.ToDouble();
      WavefrontGUIForm->theWavefrontPupilRadius_mm  =
         EditWavefrontDialog->WavefrontPupilRadiusEditBox->Text.ToDouble();
      WavefrontGUIForm->theWavefrontArrayDimension  =
         EditWavefrontDialog->WavefrontArrayDimensionEditBox->Text.ToInt();

   }
   catch(...)
   {
      Result = false;
   }
   EditWavefrontDialog->Free();

   return Result;
}

