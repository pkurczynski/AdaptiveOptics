//----------------------------------------------------------------------------
#ifndef EditAberrationsDlgH
#define EditAberrationsDlgH
//----------------------------------------------------------------------------
#include <vcl\ExtCtrls.hpp>
#include <vcl\Buttons.hpp>
#include <vcl\StdCtrls.hpp>
#include <vcl\Controls.hpp>
#include <vcl\Forms.hpp>
#include <vcl\Graphics.hpp>
#include <vcl\Classes.hpp>
#include <vcl\SysUtils.hpp>
#include <vcl\Windows.hpp>
#include <vcl\System.hpp>

#include "WavefrontGUI.h"
#include <Db.hpp>
#include <DBTables.hpp>
//----------------------------------------------------------------------------
class TEditAberrationsDialog : public TForm
{
__published:
	TButton *OKBtn;
	TButton *CancelBtn;
        TGroupBox *GroupBox3;
        TEdit *AberrationConstantEditBox;
        TEdit *AberrationTipEditBox;
        TEdit *AberrationTiltEditBox;
        TEdit *AberrationDefocusEditBox;
        TStaticText *StaticText6;
        TStaticText *StaticText10;
        TStaticText *StaticText11;
        TStaticText *StaticText12;
        TEdit *AberrationAstigmatismEditBox;
        TStaticText *StaticText13;
        TDataSource *DataSource1;
        TTable *ZernikeCoefficientsTable;
private:
public:
	virtual __fastcall TEditAberrationsDialog(TComponent* AOwner);
        bool __fastcall Execute();
};
//----------------------------------------------------------------------------
extern PACKAGE TEditAberrationsDialog *EditAberrationsDialog;
//----------------------------------------------------------------------------
#endif    
