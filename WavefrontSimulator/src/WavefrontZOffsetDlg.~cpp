//---------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "WavefrontZOffsetDlg.h"
//--------------------------------------------------------------------- 
#pragma resource "*.dfm"
TWavefrontZOffsetDialog *WavefrontZOffsetDialog;
//---------------------------------------------------------------------
__fastcall TWavefrontZOffsetDialog::TWavefrontZOffsetDialog(TComponent* AOwner)
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
// called by:  TWavefrontGUIForm::WavefrontZOffsetExecute(TObject *Sender)
//
//---------------------------------------------------------------------
bool __fastcall TWavefrontZOffsetDialog::Execute()
{
   WavefrontZOffsetDialog = new TWavefrontZOffsetDialog(Application);
   bool Result;

   try
   {
      WavefrontZOffsetDialog->WavefrontZOffsetEditBox->Text =
         WavefrontGUIForm->theWavefrontZOffset_um;

      Result = (WavefrontZOffsetDialog->ShowModal() == IDOK );

      WavefrontGUIForm->theWavefrontZOffset_um     =
         WavefrontZOffsetDialog->WavefrontZOffsetEditBox->Text.ToDouble();
      
   }
   catch(...)
   {
      Result = false;
   }
   WavefrontZOffsetDialog->Free();

   return Result;
}

