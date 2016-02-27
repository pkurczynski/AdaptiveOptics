//----------------------------------------------------------------------------
#ifndef EditMembraneDlgH
#define EditMembraneDlgH
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
class TEditMembraneDialog : public TForm
{
__published:        
	TButton *OKBtn;
	TButton *CancelBtn;
        TGroupBox *GroupBox5;
        TStaticText *StaticText16;
        TStaticText *StaticText17;
        TStaticText *StaticText18;
        TEdit *MembraneStressEditBox;
        TEdit *MembraneThicknessEditBox;
        TEdit *MembraneGapDistanceEditBox;
        TEdit *MembraneTopElectrode_VEditBox;
        TStaticText *StaticText1;
        TEdit *MembraneTopElectrodeGapDistanceEditBox;
        TStaticText *StaticText2;
private:
public:
	virtual __fastcall TEditMembraneDialog(TComponent* AOwner);
        bool __fastcall Execute();
};
//----------------------------------------------------------------------------
extern PACKAGE TEditMembraneDialog *EditMembraneDialog;
//----------------------------------------------------------------------------
#endif    
