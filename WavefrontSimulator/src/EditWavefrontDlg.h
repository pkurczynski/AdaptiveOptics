//----------------------------------------------------------------------------
#ifndef EditWavefrontDlgH
#define EditWavefrontDlgH
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
//----------------------------------------------------------------------------
class TEditWavefrontDialog : public TForm
{
__published:        
	TButton *OKBtn;
	TButton *CancelBtn;
	TBevel *Bevel1;
        TGroupBox *GroupBox1;
        TEdit *WavefrontWidthEditBox;
        TEdit *WavefrontArrayDimensionEditBox;
        TStaticText *StaticText4;
        TStaticText *StaticText5;
        TEdit *WavefrontROIRadiusEditBox;
        TStaticText *StaticText14;
        TEdit *WavefrontPupilRadiusEditBox;
        TStaticText *StaticText15;
private:
public:
	virtual __fastcall TEditWavefrontDialog(TComponent* AOwner);
        bool __fastcall Execute();
};
//----------------------------------------------------------------------------
extern PACKAGE TEditWavefrontDialog *EditWavefrontDialog;
//----------------------------------------------------------------------------
#endif    
