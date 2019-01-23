//
//  SecondView.h
//  Term
//
//  Created by Oliver VieBrooks on 8/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLView.h"
#import <CFNetwork/CFNetwork.h>
#import "DataBase.h"

struct pos{
	unsigned char r;
	unsigned char c;
};
typedef struct pos pos;

struct crsr{
	pos position;
	unsigned char color;
	BOOL flash;
	BOOL on;
};
typedef struct crsr crsr;

struct colori {
	float red;
	float green;
	float blue;
};
typedef struct colori colori;
struct character {
	unsigned char value;
	unsigned char color;
};
typedef struct character character;
struct row { 
	character column[40]; 
};
typedef struct row row;

//struct bbs {
//	NSMutableString *name;
//	NSMutableString *url;
//	NSMutableString *port;
//	NSMutableString *description;
//};
//typedef struct bbs bbs;

@interface SecondView : UIViewController <GLViewDelegate>
{
	//Views
	IBOutlet GLView *glView;
	IBOutlet UIView *termoptsview;
	IBOutlet UIView *configmenuview;
	IBOutlet UIView *bufferview;
	IBOutlet UIView *aboutview;
	IBOutlet UIView *bbslistview;
	IBOutlet UIView *bbseditview;
	IBOutlet UIView *mainview;
	
	//Terminal mode image sets
	IBOutlet UIImageView *num_nums;
	IBOutlet UIImageView *num_syms;
	IBOutlet UIImageView *num_cmdr;
	IBOutlet UIImageView *num_ctrl;
	IBOutlet UIImageView *let_lowr;
	IBOutlet UIImageView *let_uppr;
	IBOutlet UIImageView *let_cmdr;
	IBOutlet UIImageView *let_shft;
	IBOutlet UIImageView *let_syms;
	IBOutlet UIImageView *connect;
	IBOutlet UIImageView *disconnect;
	//Call Button
	IBOutlet UIButton *callbutton;
	
	IBOutlet UIButton *button_scrollup;
	IBOutlet UIButton *button_scrolldown;
		
	//Controls on Terminal Settings Page
	IBOutlet UISwitch *localecho_switch;
	IBOutlet UISegmentedControl *baudemulation_seg;
	IBOutlet UISwitch *capture_switch;
	
	//Controls on BBS Edit Page
	IBOutlet UITextField *bbsedit_name;
	IBOutlet UITextField *bbsedit_url;
	IBOutlet UITextField *bbsedit_port;
	IBOutlet UITextField *bbsedit_desc;
	
	//Controls on buffer list page
	IBOutlet UITableView *bufferlist_table;
	IBOutlet UIButton *bufferlist_cancelbutton;
	IBOutlet UIButton *bufferlist_savebutton;
	IBOutlet UIButton *bufferlist_delbutton;
	IBOutlet UITextField *bufferlist_textfield;
	IBOutlet UILabel *bufferlist_label;
	
	//Controls on BBS List Page	
	IBOutlet UITableView *bbslist_table;
	
	IBOutlet UIButton *button;

	//Controls on Buffer Menu Page
	IBOutlet UILabel *buffer_size;

	//Terminal mode variables
	row screen[25];
	colori colors[16];
	crsr cursor;
	BOOL uppercase;
	BOOL reverse;
	BOOL shift;
	BOOL commodore;
	BOOL control;
	BOOL symbol;
	BOOL Connected;
	unsigned char cset;
	
	BOOL newbbs;
	
	NSMutableString *oldurl;
	NSMutableString *oldport;
	
	//Settings
	int baud;
	BOOL capture;
	BOOL LocalEcho;
	BOOL bufferbuttonmode;
	
	//Database singleton
	DataBase *database;
	
	//Baud emulation timer
	NSTimer *timer;
	
	//Arrays
	NSMutableArray *inbuffer;
	NSMutableArray *bbslist;
	NSMutableArray *bufferlist;
	NSMutableArray *capturebuffer;
	NSMutableArray *reviewbuffer;
}

//Views
@property (nonatomic,retain) IBOutlet GLView *glView;
@property (nonatomic,retain) IBOutlet UIView *termoptsview;
@property (nonatomic,retain) IBOutlet UIView *configmenuview;
@property (nonatomic,retain) IBOutlet UIView *bufferview;
@property (nonatomic,retain) IBOutlet UIView *aboutview;
@property (nonatomic,retain) IBOutlet UIView *bbslistview;
@property (nonatomic,retain) IBOutlet UIView *bbseditview;
@property (nonatomic,retain) IBOutlet UIView *mainview;

//Terminal mode images
@property (nonatomic,retain) IBOutlet UIImageView *num_nums;
@property (nonatomic,retain) IBOutlet UIImageView *num_syms;
@property (nonatomic,retain) IBOutlet UIImageView *num_cmdr;
@property (nonatomic,retain) IBOutlet UIImageView *num_ctrl;
@property (nonatomic,retain) IBOutlet UIImageView *let_lowr;
@property (nonatomic,retain) IBOutlet UIImageView *let_uppr;
@property (nonatomic,retain) IBOutlet UIImageView *let_cmdr;
@property (nonatomic,retain) IBOutlet UIImageView *let_shft;
@property (nonatomic,retain) IBOutlet UIImageView *let_syms;
@property (nonatomic,retain) IBOutlet UIImageView *connect;
@property (nonatomic,retain) IBOutlet UIImageView *disconnect;

@property (nonatomic,retain) IBOutlet UIButton *button_scrollup;
@property (nonatomic,retain) IBOutlet UIButton *button_scrolldown;


//Call Button
@property (nonatomic,retain) IBOutlet UIButton *callbutton;

@property (nonatomic,retain) IBOutlet UITextField *bbsedit_name;
@property (nonatomic,retain) IBOutlet UITextField *bbsedit_url;
@property (nonatomic,retain) IBOutlet UITextField *bbsedit_port;
@property (nonatomic,retain) IBOutlet UITextField *bbsedit_desc;

@property (nonatomic,retain) IBOutlet UITableView *bbslist_table;
@property (nonatomic,retain) IBOutlet UIButton *button;

@property (nonatomic,retain)IBOutlet UITableView *bufferlist_table;
@property (nonatomic,retain)IBOutlet UIButton *bufferlist_cancelbutton;
@property (nonatomic,retain)IBOutlet UIButton *bufferlist_savebutton;
@property (nonatomic,retain)IBOutlet UITextField *bufferlist_textfield;
@property (nonatomic,retain)IBOutlet UILabel *bufferlist_label;


//Buffer size display
@property (nonatomic,retain) IBOutlet UILabel *buffer_size;

//CBM Display Routines
-(void) CR_HOME;
-(void) CR_DEL;
-(void) CR_CR;
-(void) CR_U;
-(void) CR_D;
-(void) CR_L;
-(void) CR_R;
-(void) CLSCN;
-(void) STROut:(unsigned char[]) s;
-(void) CLR_ROW:(int)r;
-(void) ChrOut:(unsigned char)chr;
-(void) ScrnOut:(int)value;
-(void) ScrollAllUp;
-(void) InitColors;
-(void) HideShowKeys;

//Terminal mode button actions
-(IBAction) keypress:(id)sender;
-(IBAction) keypress_shift;
-(IBAction) keypress_commodore;
-(IBAction) keypress_ctrl;
-(IBAction) keypress_symbl;
-(IBAction) keyup_shift;
-(IBAction) keyup_commodore;
-(IBAction) keyup_ctrl;
-(IBAction) keyup_symbl;
-(IBAction) keypress_enter;
-(IBAction) keypress_home;
-(IBAction) keypress_del;
-(IBAction) keypress_up;
-(IBAction) keypress_dn;
-(IBAction) keypress_lt;
-(IBAction) keypress_rt;
-(IBAction) keypress_connect;
//-(IBAction) scrollback_up;
//-(IBAction) scrollback_down;

//Main Menu button actions
-(IBAction) main_termopts_click;

//In-Term special button actions
-(IBAction) term_termopts_click;
-(IBAction) toggle_capture;

//BBS List button actions
-(IBAction) bbslist_new;
-(IBAction) bbslist_del;

//Buffer List button actions
-(IBAction) bufferlist_saveclick;
-(IBAction) bufferlist_delclick;
-(IBAction) bufferlist_cancelclick;

//BBS Edit button actions
-(IBAction) bbsedit_save_click;
-(IBAction) bbsedit_cancel_click;

//BBS Edit textfield enter/exits
-(IBAction) bbsedit_port_edit;
-(IBAction) bbsedit_port_exit;
-(IBAction) bbsedit_desc_edit;
-(IBAction) bbsedit_desc_exit;


//Current Buffer menu options
-(IBAction) buffer_save_click;
-(IBAction) buffer_load_click;
-(IBAction) buffer_clear_click;
-(IBAction) buffer_send_click;
-(IBAction) buffer_email_click;
-(IBAction) buffer_review_click;

//Page Control
-(IBAction) goto_termopts;
-(IBAction) goto_bbslist;
-(IBAction) goto_buffopts;
-(IBAction) goto_gototerm;
-(IBAction) goto_main;
-(IBAction) goto_about;

//Communications routines
-(void) SendByteToSocket:(unsigned char *)chr;
-(void) SendTextToSocket:(NSString *)text;
-(void) AddBuff:(unsigned char)buff;
-(void) baudrate:(int)rate;
//TCP Stream refs
CFReadStreamRef readStream;
CFWriteStreamRef writeStream;

//DEBUG
-(IBAction) goto_term;
-(IBAction) termopts_done;

@end
