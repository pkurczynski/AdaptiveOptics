//----------------------------------------------------------------------------
#ifndef EditBiasLensDlgH
#define EditBiasLensDlgH
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
class TEditBiasLensDialog : public TForm
{
__published:        
	TButton *OKBtn;
	TButton *CancelBtn;
        TGroupBox *GroupBox1;
        TStaticText *StaticText27;
        TEdit *BiasLensFocalLengthEditBox;
private:
public:
	virtual __fastcall TEditBiasLensDialog(TComponent* AOwner);
        bool __fastcall Execute();
};
//----------------------------------------------------------------------------
extern PACKAGE TEditBiasLensDialog *EditBiasLensDialog;
//----------------------------------------------------------------------------
#endif    
