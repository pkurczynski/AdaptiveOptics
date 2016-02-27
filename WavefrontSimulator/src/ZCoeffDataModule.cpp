//----------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop

#include "ZCoeffDataModule.h"
//----------------------------------------------------------------------------
#pragma resource "*.dfm"
TZernikeCoeffDataModule *ZernikeCoeffDataModule;
//----------------------------------------------------------------------------
__fastcall TZernikeCoeffDataModule::TZernikeCoeffDataModule(TComponent *Owner)
	: TDataModule(Owner)
{
}
//----------------------------------------------------------------------------
void __fastcall TZernikeCoeffDataModule::DataModuleCreate(TObject *Sender)
{

	ZCoeffTable->Open();
        ZCoeffTableForm->ReadDataFromFile();

}
//----------------------------------------------------------------------------


void __fastcall TZernikeCoeffDataModule::ZCoeffTableBeforeClose(
      TDataSet *DataSet)
{
       ZCoeffTableForm->ReadDataFromFile();
}
//---------------------------------------------------------------------------

