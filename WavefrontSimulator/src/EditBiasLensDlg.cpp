//---------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop
#include "WavefrontGUI.h"
#include "EditBiasLensDlg.h"
//--------------------------------------------------------------------- 
#pragma resource "*.dfm"
TEditBiasLensDialog *EditBiasLensDialog;
//---------------------------------------------------------------------
__fastcall TEditBiasLensDialog::TEditBiasLensDialog(TComponent* AOwner)
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
// called by:  TBiasLensGUIForm::EditBiasLensExecute(TObject *Sender)
//
//---------------------------------------------------------------------
bool __fastcall TEditBiasLensDialog::Execute()
{
   EditBiasLensDialog = new TEditBiasLensDialog(Application);
   bool Result;

   try
   {
      EditBiasLensDialog->BiasLensFocalLengthEditBox->Text =
         WavefrontGUIForm->theLensFocalLength_mm;

      Result = (EditBiasLensDialog->ShowModal() == IDOK );

      WavefrontGUIForm->theLensFocalLength_mm        =
         EditBiasLensDialog->BiasLensFocalLengthEditBox->Text.ToDouble();

   }
   catch(...)
   {
      Result = false;
   }
   EditBiasLensDialog->Free();

   return Result;
}

