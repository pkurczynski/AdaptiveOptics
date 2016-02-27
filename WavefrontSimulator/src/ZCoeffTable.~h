//----------------------------------------------------------------------------
#ifndef ZCoeffTableH
#define ZCoeffTableH
//----------------------------------------------------------------------------
#include <SysUtils.hpp>
#include <Windows.hpp>
#include <Messages.hpp>
#include <Classes.hpp>
#include <Graphics.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include <DBCtrls.hpp>
#include <DB.hpp>
#include <DBGrids.hpp>
#include <ExtCtrls.hpp>
#include <Grids.hpp>

#include "WavefrontGUI.h"
#include "ZCoeffDataModule.h"

//----------------------------------------------------------------------------
class TZCoeffTableForm : public TForm
{
__published:
	TDBGrid *DBGrid1;
	TDBNavigator *DBNavigator;
	TPanel *Panel1;
	TPanel *Panel2;
private:
	// private declarations
public:
	// public declarations
	__fastcall TZCoeffTableForm(TComponent *Owner);
        void ReadDataFromFile();
        
};
//----------------------------------------------------------------------------
extern TZCoeffTableForm *ZCoeffTableForm;
//----------------------------------------------------------------------------
#endif
