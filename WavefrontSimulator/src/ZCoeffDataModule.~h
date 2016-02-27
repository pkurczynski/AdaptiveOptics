//----------------------------------------------------------------------------
#ifndef ZCoeffDataModuleH
#define ZCoeffDataModuleH
//----------------------------------------------------------------------------
#include <SysUtils.hpp>
#include <Windows.hpp>
#include <Classes.hpp>
#include <Graphics.hpp>
#include <Controls.hpp>
#include <Forms.hpp>
#include <Dialogs.hpp>
#include <DB.hpp>
#include <DBTables.hpp>
#include <Db.hpp>
#include "ZCoeffTable.h"
//----------------------------------------------------------------------------
class TZernikeCoeffDataModule : public TDataModule
{
__published:
        TFloatField *ZCoeffTableJINDEX;
        TFloatField *ZCoeffTableCOEFFICIEN;
        TStringField *ZCoeffTableNAME;
        TDataSource *ZCoeffDataSource;
        TTable *ZCoeffTable;
	void __fastcall DataModuleCreate(TObject *Sender);
        void __fastcall ZCoeffTableBeforeClose(TDataSet *DataSet);
private:
	// private declarations
public:
	// public declarations
	__fastcall TZernikeCoeffDataModule(TComponent *Owner);
};
//----------------------------------------------------------------------------
extern TZernikeCoeffDataModule *ZernikeCoeffDataModule;
//----------------------------------------------------------------------------
#endif
