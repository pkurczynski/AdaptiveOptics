//----------------------------------------------------------------------------
#ifndef WavefrontZOffsetDlgH
#define WavefrontZOffsetDlgH
//----------------------------------------------------------------------------
#include <vcl\System.hpp>
#include <vcl\Windows.hpp>
#include <vcl\SysUtils.hpp>
#include <vcl\Classes.hpp>
#include <vcl\Graphics.hpp>
#include <vcl\StdCtrls.hpp>
#include <vcl\Forms.hpp>
#include <vcl\Controls.hpp>
#include <vcl\Buttons.hpp>
#include <vcl\ExtCtrls.hpp>

#include "WavefrontGUI.h"
//----------------------------------------------------------------------------
class TWavefrontZOffsetDialog : public TForm
{
__published:        
	TButton *OKBtn;
	TButton *CancelBtn;
	TBevel *Bevel1;
        TEdit *WavefrontZOffsetEditBox;
        TStaticText *StaticText1;
        TStaticText *StaticText2;
        TStaticText *StaticText3;
private:
public:
	virtual __fastcall TWavefrontZOffsetDialog(TComponent* AOwner);
        bool __fastcall TWavefrontZOffsetDialog::Execute();

};
//----------------------------------------------------------------------------
extern PACKAGE TWavefrontZOffsetDialog *WavefrontZOffsetDialog;
//----------------------------------------------------------------------------
#endif    
