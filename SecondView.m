//
//  GLViewController.m
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//  Copyright ___ORGANIZATIONNAME___ ___YEAR___. All rights reserved.
//

#import "SecondView.h"
#import "ConstantsAndMacros.h"
#import "OpenGLCommon.h"
#import "ConstantsAndMacros.h"
//#import "enums.h"
#import "sprites.h"
//#import "gameflow.h"
#import <Foundation/Foundation.h>
#import <CFNetwork/CFNetwork.h>
#import <QuartzCore/QuartzCore.h>

static const int field_name = 0;
static const int field_url = 1;
static const int field_port = 2;
static const int field_description =3;

static const int PROMPT_CLEAR_BUFFER = 0;
static const int PROMPT_DISCONNECT = 1;

static const int TABLE_BBSLIST = 0;
static const int TABLE_BUFFERLIST = 1;

void * refToSelf;

void readCallback (CFReadStreamRef stream, CFStreamEventType event, void *clientCallBackInfo){
	UInt8 buf[8192];
	if (event ==kCFStreamEventHasBytesAvailable)
	{            
		CFIndex bytesRead = CFReadStreamRead(stream, buf, 8192);
		if (bytesRead > 0) {
			NSLog([[NSString alloc] initWithBytes:buf length:bytesRead encoding:NSASCIIStringEncoding]); 
			//[refToSelf STROutLen:buf len:bytesRead]; 
			for (int i=0;i<bytesRead;i++){
				[refToSelf AddBuff:buf[i]];
			}
			//handleBytes(buf, bytesRead);
		}
	}
    if (event==kCFStreamEventErrorOccurred)
	{
		[refToSelf Disconnect];
		CFStreamError error = CFReadStreamGetError(stream);
		NSLog([[NSString alloc] initWithFormat:@"%d",error]);
		CFReadStreamUnscheduleFromRunLoop(stream, CFRunLoopGetCurrent(),
										  kCFRunLoopCommonModes);
		CFReadStreamClose(stream);
		CFRelease(stream);
	}
	if (event==kCFStreamEventEndEncountered)
	{
		[refToSelf Disconnect];
		NSLog(@"Completed.");
		CFReadStreamUnscheduleFromRunLoop(stream, CFRunLoopGetCurrent(),
										  kCFRunLoopCommonModes);
		CFReadStreamClose(stream);
		CFRelease(stream);
    }
	
}


@implementation SecondView
@synthesize glView,termoptsview,configmenuview,bufferview,aboutview,bbseditview,bbslistview;
@synthesize bbsedit_name,bbsedit_url,bbsedit_port,bbsedit_desc;

@synthesize bbslist_table,bufferlist_table;
static const unsigned char CHR_WHITE = 5;
static const unsigned char CHR_RED = 28;
static const unsigned char CHR_BELL = 7;
static const unsigned char CHR_CR = 13;
static const unsigned char CHR_UC = 14;
static const unsigned char CHR_C_D = 17;
static const unsigned char CHR_CLS = 147;

static	int sprite;
static int keybase;
static int timerpos;
static NSString *hostname =@"192.168.188.75";
static NSString *port = @"4000";
static int termoptsparent;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	glView.animationInterval = 1.0 / kRenderingFrequency;
	[glView startAnimation];
	self.hidesBottomBarWhenPushed = YES;
	//uppercase = FALSE;
	cset = 1;
	Connected = FALSE;
	LocalEcho = FALSE;
	shift = FALSE;
	capture = FALSE;
	commodore = FALSE;
	control = FALSE;
	symbol = NO;
	[self InitColors];
	bbslist = [[NSMutableArray alloc] init];
	bufferlist = [[NSMutableArray alloc] init];
	database = [DataBase sharedInstance];
	NSLog(@"init: %d",[database init_database:@"cbmterm.sqlite"]);
	NSLog(@"open: %d",[database open_database]);
	[self load_defaults];
	unsigned char teststr[255];
	sprintf(teststr,"%c%cIcbmtERM %c1.0%c ready\n",CHR_WHITE,CHR_CLS,CHR_RED,CHR_WHITE);// = {5,147,'THIS IS A TEST',13,0};
	[buffer_size setText:@"0 bytes"];	
	inbuffer = [[NSMutableArray alloc] init];
	capturebuffer = [[NSMutableArray alloc] init];
	timerpos = 0;
	timer =[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
	//init for bbsedit
	oldurl = [[NSMutableString alloc] init];
	oldport = [[NSMutableString alloc] init];
	[self STROut:teststr];
	[super viewDidLoad];
	refToSelf = self;
	
}


- (void)drawView:(UIView *)theView
{
	int colr;
	int base;
	if (cset==0){
		base = 0;
	} else {
		base = 255;
	};
	if (reverse){
		base = base + 128;
	};
    glColor4f(0.0, 0.0, 0.0, 1.0);
	glClear(GL_COLOR_BUFFER_BIT );
	for (int r=0;r<25;r++){
		for (int c=0;c<40;c++){
			colr = screen[r].column[c].color;
			DrawImageColor(sprite,c*8,r*8,(cset*256)+screen[r].column[c].value,colors[colr].red,colors[colr].green,colors[colr].blue);
		}
	}
}

-(void)setupView:(GLView*)view
{
	CGRect rect = view.bounds; 
	glViewport(0, 0, rect.size.width, rect.size.height);  
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrthof(0, rect.size.width, rect.size.height, 0, -1,1);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	
	glClearColor(0.0, 0.0, 0.0, 1.0);
	// Turn necessary features on
	
	NSLog(@"enter gameflow");
	//
	//	[gameflow init];
	sprite = LoadTexture([[NSBundle mainBundle] pathForResource:@"c64font" ofType:@"png"], 8, 8);
	keybase = LoadTexture([[NSBundle mainBundle] pathForResource:@"iCBMTerm" ofType:@"png"],512,256);
}

- (void)dealloc 
{
	[bbslist release];
	[glView release];
    [super dealloc];
}

-(void) AddBuff:(unsigned char)temp {
	NSNumber *value = [[NSNumber alloc] initWithUnsignedChar:temp];
	[inbuffer addObject:value];
	[value release];
	
	if (capture) {
		value = [[NSNumber alloc] initWithUnsignedChar:temp];
		[capturebuffer addObject:value];
		[value release];
	}
	[buffer_size setText:[NSString stringWithFormat:@"%d bytes",[capturebuffer count]]];	
}



-(void)onTimer:(NSTimer *)theTimer{
	if ([inbuffer count]>0){
		[self ChrOut:[(NSNumber *)[inbuffer objectAtIndex:0] unsignedCharValue] ];
		[inbuffer removeObjectAtIndex:0];
	}
}

-(void)InitColors{
	//BLACK ($00)
	colors[0].red = 0.0;
	colors[0].green = 0.0;
	colors[0].blue = 0.0;
	
	//WHITE ($01)
	colors[1].red = 1.0;
	colors[1].green = 1.0;
	colors[1].blue = 1.0;
	
	//RED ($02)
	colors[2].red = 1.0;
	colors[2].green = 0.0;
	colors[2].blue = 0.0;
	
	//CYAN ($03)
	colors[3].red = 0.0;
	colors[3].green = 1.0;
	colors[3].blue = 1.0;
	
	//PURPLE ($04)
	colors[4].red = 1.0;
	colors[4].green = 0.0;
	colors[4].blue = 1.0;
	
	//GREEN ($05)
	colors[5].red = 0.0;
	colors[5].green = 0.5;
	colors[5].blue = 0.0;
	
	//BLUE ($06)
	colors[6].red = 0.0;
	colors[6].green = 0.0;
	colors[6].blue = 0.5;
	
	//YELLOW ($07)
	colors[7].red = 1.0;
	colors[7].green = 1.0;
	colors[7].blue = 0.0;
	
	//ORANGE ($08)
	colors[8].red = 1.0;
	colors[8].green = 0.5;
	colors[8].blue = 0.0;
	
	//BROWN ($09)
	colors[9].red = 0.5;
	colors[9].green = 0.25;
	colors[9].blue = 0.0;
	
	//PINK ($0A)
	colors[10].red = 1.0;
	colors[10].green = 0.5;
	colors[10].blue = 0.5;
	
	//DARK GREY ($0B)
	colors[11].red = 0.25;
	colors[11].green = 0.25;
	colors[11].blue = 0.25;
	
	//MED GREY ($0C)
	colors[12].red = 0.5;
	colors[12].green = 0.5;
	colors[12].blue = 0.5;
	
	//LIGHT GREEN ($0D)
	colors[13].red = 0.5;
	colors[13].green = 1.0;
	colors[13].blue = 0.5;
	
	//LIGHT BLUE ($0E)
	colors[14].red = 0.5;
	colors[14].green = 0.5;
	colors[14].blue = 1.0;
	
	//LIGHT GREY ($0F)
	colors[15].red = 0.75;
	colors[15].green = 0.75;
	colors[15].blue = 0.75;
}		
	
	
-(IBAction) felch{
	[self ScrollAllUp];
}

-(void)ChrOutSend:(unsigned char)chr{
	[self SendTextToSocket:[NSString stringWithFormat:@"%c",chr]];
	//	[self SendByteToSocket:chr];
	if (LocalEcho)[self ChrOut: chr];
}

-(void)ChrOut:(unsigned char)chr{
	//	IF CursorOn THEN BEGIN
	//	CursorOn := FALSE;
	//	Screen[CursorPos.X+(CursorPos.Y*40)] := Screen[CursorPos.X+(CursorPos.Y*40)]-128;
	//	END;
	switch (chr) {
		case 5:
			cursor.color = 1; //WHITE
			break;
		case 7:
			//Play bell sound
			break;
		case 13:
			//Carriage return
			[self CR_CR];
			break;
		case 14:
			//uppercase = NO; //Set Lowercase
			cset=1;
			break;
		case 17:
			//Cursor Down
			[self CR_D];
			break;
		case 18:
			reverse = YES; //Reverse On
			break;
		case 19: //Home
			[self CR_HOME];
			break;
		case 20: //DEL
			[self CR_DEL];
			break;
		case 28: //Color Red
			cursor.color = 2;
			break;
		case 29:
			[self CR_R];
			break;
		case 30: //Color Green
			cursor.color = 5;
			break;
		case 31: //Color Blue
			cursor.color = 6;
			break;
		case 129: //Color Orange
			cursor.color = 8;
			break;
		case 142: //SetUC;
			//uppercase = YES;
			cset = 0;
			break;
		case 144: //Color Black
			cursor.color = 0;
			break;
		case 145:
			[self CR_U];
			break;
		case 146:  //Reverse Off
			reverse = NO;
			break;
		case 147:
			[self CLSCN];
			break;
		case 149: //Color Brown
			cursor.color = 9;
			break;
		case 150: //Color Pink
			cursor.color = 10;
			break;
		case 151: //Color Dark Grey
			cursor.color = 11;
			break;
		case 152: //Color Medium Grey
			cursor.color = 12;
			break;
		case 153: //Color Light Green
			cursor.color = 13;
			break;
		case 154: //Color Light Blue
			cursor.color = 14;
			break;
		case 155: //Color Light Grey
			cursor.color = 15;
			break;
		case 156: //Color Purple
			cursor.color = 4;
			break;
		case 157: //Cursor Left
			[self CR_L];
			break;
		case 158: //Color Yellow
			cursor.color = 7;
			break;
		case 159: //Color Cyan
			cursor.color = 3;
			break;
		case 191:
			[self ScrnOut:127];
			break;
		case 255:
			[self ScrnOut:94];
			break;
		default:
			if ((chr>=32)&&(chr<64)) [self ScrnOut:chr];
			if ((chr>=64)&&(chr<95)) [self ScrnOut:chr-64];
			if ((chr>=96)&&(chr<127)) [self ScrnOut:chr-32];
			if ((chr>=160)&&(chr<191)) [self ScrnOut:chr-64];
			if ((chr>=192)&&(chr<254)) [self ScrnOut:chr-128];
			break;
	}
	
	//	//  95: ScrnOut(31);
	//	//  160: ScrnOut(32);
	//	//  192: ScrnOut(63);
//	Timer3.Enabled := TRUE;
	
}

-(void) ScrnOut:(int)value {
	int temp;
	if (reverse){
		temp = value+128; 
	} else {
		temp=value;
	}
	screen[cursor.position.r].column[cursor.position.c].value = temp;
	screen[cursor.position.r].column[cursor.position.c].color = cursor.color;
	[self CR_R];
}

-(void)CR_D{
	if (cursor.position.r <24){
		cursor.position.r++;
	} else {
		[self ScrollAllUp];
	}
//EnableRedraw;
}

-(void) CR_L{
	if (cursor.position.c>0){
		cursor.position.c--;
	} else {
		if (cursor.position.r>0){
			cursor.position.c =39;
			cursor.position.r--;
		}
	}
//EnableRedraw;
}

-(void) CR_R{
	if (cursor.position.c <39){
		cursor.position.c++;
	} else {
		if (cursor.position.r <24){
			cursor.position.c = 0;
			cursor.position.r++;
		} else {
			[self ScrollAllUp];
			cursor.position.c =0;
			cursor.position.r=24;
		}
	}
//EnableRedraw;
}

-(void) CR_U{
	if (cursor.position.r > 0) cursor.position.r--;
//EnableRedraw;
}

-(void) ScrollAllUp{
	for (int i=1;i<25;i++){
		screen[i-1] = screen[i];
	}
	[self CLR_ROW:24];
//EnableRedraw;
}

-(void)CLR_ROW:(int)r{
	for (int i=0;i<40;i++){
		screen[r].column[i].value=32;
		screen[r].column[i].color = cursor.color;
	}
}

-(void) CLSCN{
	for (int i=0;i<25;i++){
		[self CLR_ROW:i];
	}
	[self CR_HOME];
//EnableRedraw;
}

//-(char[])ASC2PET:(char[])s{
//function TForm1.ASC2PET(s:string):string;	
//var i: integer;
//t: string;
//begin
//t := s;
//FOR i := 1 to Length(s) DO BEGIN
//IF Pos(t[i],UCL) > 0 THEN t[i] := LCL[Pos(t[i],UCL)] ELSE
//IF Pos(t[i],LCL) > 0 THEN t[i] := UCL[Pos(t[i],LCL)] ELSE
//IF t[i] = #8 THEN t[i] := #20;// ELSE
////    IF t[i] =  THEN t[i] := #17;
//END;
//ASC2PET := t;
//end;
//}

//procedure TForm1.STROut(s: string);
//var i : integer;
//begin
//FOR i := 1 to Length(s) DO BEGIN
//[self ChrOut:s[i]);
//END;
//end;

-(void) STROut:(unsigned char[]) s{
	//	NSString *temp = [[NSString alloc] initWithCString:s];
	for (int i=0;i<255;i++){
		if (s[i]==0)break;
		[self ChrOut:s[i]];
	}
}

-(void) STROutLen:(unsigned char[]) s len:(int)len{
	//	NSString *temp = [[NSString alloc] initWithCString:s];
	for (int i=0;i<len;i++){
//		if (s[i]==0)break;
		[self ChrOut:s[i]];
	}
}

-(void) CR_DEL{
	[self CR_L];
	[self ScrnOut:32];
	[self CR_L];
//EnableRedraw;
}

-(void) CR_CR{
	[self CR_D];
	reverse = NO;
	cursor.position.c = 0;
//EnableRedraw;
}

//procedure TForm1.CR_HOME;
-(void) CR_HOME{
	cursor.position.c = 0;
	cursor.position.r = 0;
//EnableRedraw;
}

-(void)CRSR_ON{
//	screen[cursor.position.r].column[cursor.position.c]
}

-(IBAction) keypress:(id)sender{
	switch ([(UIButton *)sender tag]) {
		case 0:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'1'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'!'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:129];//Color Orange
			if ((!shift)&&(!commodore)&&(control)&&(!symbol)) [self ChrOutSend:144];//Color Black
			break;
		case 1:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'2'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'"'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:149];//Color Brown
			if ((!shift)&&(!commodore)&&(control)&&(!symbol)) [self ChrOutSend:5];  //Color White
			break;
		case 2:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'3'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'#'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:150]; //Color Pink
			if ((!shift)&&(!commodore)&&(control)&&(!symbol)) [self ChrOutSend:144]; //Color Red
			break;
		case 3:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'4'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'$'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:151]; //Color Dark Grey
			if ((!shift)&&(!commodore)&&(control)&&(!symbol)) [self ChrOutSend:159]; //Color Cyan
			break;
		case 4:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'5'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'%'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:152]; //Color Medium Grey
			if ((!shift)&&(!commodore)&&(control)&&(!symbol)) [self ChrOutSend:156]; //Color Purple
			break;
		case 5:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'6'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'&'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:153]; //Color Light Green
			if ((!shift)&&(!commodore)&&(control)&&(!symbol)) [self ChrOutSend:40]; //Color Green
			break;
		case 6:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'7'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'\''];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:154]; //Color Light Blue
			if ((!shift)&&(!commodore)&&(control)&&(!symbol)) [self ChrOutSend:31]; //Color Blue
			break;
		case 7:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'8'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'('];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:155]; //Color Light Grey
			if ((!shift)&&(!commodore)&&(control)&&(!symbol)) [self ChrOutSend:158]; //Color Yellow
			break;
		case 8:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'9'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:')'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:18]; //Reverse On
			if ((!shift)&&(!commodore)&&(control)&&(!symbol)) [self ChrOutSend:18]; //Reverse On
			break;
		case 9:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'0'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'0'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:146]; //Reverse Off
			if ((!shift)&&(!commodore)&&(control)&&(!symbol)) [self ChrOutSend:156]; //Reverse Off
			break;
		case 10:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'Q'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'q'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:171]; 
			if ((!shift)&&(!commodore)&&(!control)&&(symbol)) [self ChrOutSend:'-'];
			break;
		case 11:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'W'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'w'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:179]; 
			if ((!shift)&&(!commodore)&&(!control)&&(symbol)) [self ChrOutSend:'='];
			break;
		case 12:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'E'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'e'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:177]; 
			if ((!shift)&&(!commodore)&&(!control)&&(symbol)) [self ChrOutSend:'+'];
			break;
		case 13:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'R'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'q'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:178]; 
			if ((!shift)&&(!commodore)&&(!control)&&(symbol)) [self ChrOutSend:'['];
			break;
		case 14:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'T'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'t'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:163]; 
			if ((!shift)&&(!commodore)&&(!control)&&(symbol)) [self ChrOutSend:']'];
			break;
		case 15:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'Y'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'y'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:183]; 
			if ((!shift)&&(!commodore)&&(!control)&&(symbol)) [self ChrOutSend:94];			
			break;
		case 16:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'U'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'u'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:184]; 
			if ((!shift)&&(!commodore)&&(!control)&&(symbol)) [self ChrOutSend:64];
			break;
		case 17:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'I'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'i'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:162]; 
			if ((!shift)&&(!commodore)&&(!control)&&(symbol)) [self ChrOutSend:95];
			break;
		case 18:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'O'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'o'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:185]; 
			if ((!shift)&&(!commodore)&&(!control)&&(symbol)) [self ChrOutSend:255];
			break;
		case 19:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'P'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'p'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:175]; 
			if ((!shift)&&(!commodore)&&(!control)&&(symbol)) [self ChrOutSend:59];
			break;
		case 20:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'A'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'a'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:176]; 
			if ((!shift)&&(!commodore)&&(!control)&&(symbol)) [self ChrOutSend:':'];
			break;
		case 21:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'S'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'s'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:174]; 
			if ((!shift)&&(!commodore)&&(!control)&&(symbol)) [self ChrOutSend:','];
			break;
		case 22:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'D'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'d'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:172]; 
			if ((!shift)&&(!commodore)&&(!control)&&(symbol)) [self ChrOutSend:'.'];
			break;
		case 23:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'F'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'f'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:187]; 
			if ((!shift)&&(!commodore)&&(!control)&&(symbol)) [self ChrOutSend:'/'];
			break;
		case 24:
///////////////////////////////////
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'G'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'g'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:165]; 
			if ((!shift)&&(!commodore)&&(!control)&&(symbol)) [self ChrOutSend:'<'];
			break;
		case 25:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'H'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'h'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:180]; 
			if ((!shift)&&(!commodore)&&(!control)&&(symbol)) [self ChrOutSend:'>'];
			break;
		case 26:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'J'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'j'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:181]; 
			if ((!shift)&&(!commodore)&&(!control)&&(symbol)) [self ChrOutSend:'?'];
			break;
		case 27:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'K'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'k'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:161]; 
			if ((!shift)&&(!commodore)&&(!control)&&(symbol)) [self ChrOutSend:'*'];
			break;
		case 28:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'L'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'l'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:182]; 
			break;
		case 29:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'Z'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'z'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:173]; 
			break;
		case 30:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'X'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'x'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:189]; 
			break;
		case 31:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'C'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'c'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:188]; 
			break;
		case 32:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'V'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'v'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:190]; 
			break;
		case 33:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'B'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'b'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:191]; 
			break;
		case 34:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'N'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'n'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:170]; 
			break;
		case 35:
			if ((!shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'M'];
			if ((shift)&&(!commodore)&&(!control)&&(!symbol)) [self ChrOutSend:'m'];
			if ((!shift)&&(commodore)&&(!control)&&(!symbol)) [self ChrOutSend:167]; 
			break;
		case 37:
			[self ChrOutSend:' '];
			break;
		default:
			break;
	}
}

-(IBAction) keypress_shift{
	shift = YES;
	if (commodore) cset = (cset ^ 1);
	[self HideShowKeys];
}
-(IBAction) keypress_commodore{
	commodore = YES;
	if (shift) cset = (cset ^ 1);
	[self HideShowKeys];
}

-(IBAction) keypress_ctrl{
	control = YES;
	[self HideShowKeys];
}
-(IBAction) keypress_symbl{
	symbol = YES;
	[self HideShowKeys];
}
-(IBAction) keyup_shift{
	shift = NO;
	[self HideShowKeys];
}
-(IBAction) keyup_commodore{
	commodore = NO;
	[self HideShowKeys];
}
-(IBAction) keyup_ctrl{
	control = NO;
	[self HideShowKeys];
}
-(IBAction) keyup_symbl{
//		[self connect];
	symbol = NO;
	[self HideShowKeys];
}

-(IBAction) keypress_home{
	if ((shift)||(commodore)){
		[self ChrOutSend:147];
	} else {
		[self ChrOutSend:19];
	}
}

-(IBAction) keypress_del{
	if((shift)||(commodore)){
	} else {
		[self ChrOutSend:20];
	}

}

-(IBAction) keypress_enter{
	[self ChrOutSend: 13];
//	[self SendByteToSocket:13];
//	[self SendByteToSocket:10];
}

-(IBAction) keypress_up{
	[self ChrOutSend:145];
}
-(IBAction) keypress_dn{
	[self ChrOutSend:17];
}
-(IBAction) keypress_lt{
	[self ChrOutSend:157];
}
-(IBAction) keypress_rt{
	[self ChrOutSend:29];
}
-(IBAction) keypress_connect{
	if (!Connected){
		[self ConnectToHost];
	} else {
		[self Disconnect];
	}
}

-(void)ConnectToHost //:(NSString *)hostname Port:(NSString *)port
{
	
	CFHostRef hostRef = CFHostCreateWithName(kCFAllocatorDefault, (CFStringRef)hostname);
	CFStreamCreatePairWithSocketToCFHost(kCFAllocatorDefault, hostRef, [port intValue], &readStream, &writeStream);
	
	CFStreamClientContext readContext = {0, NULL,NULL,NULL,NULL};
	CFOptionFlags readEvents = kCFStreamEventHasBytesAvailable | kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered;
	if (CFReadStreamSetClient(readStream, readEvents, readCallback, &readContext))
	{
		CFReadStreamScheduleWithRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
	};
	
	if (!CFReadStreamOpen(readStream)) 
	{
		CFStreamError readErr = CFReadStreamGetError(readStream);
		if (readErr.error !=0) 
		{
			[self SetCallButton:NO];

			Connected = NO;
			//An error has occurred.
			NSLog([[NSString alloc] initWithFormat:@"%d", strerror(readErr.error)]);
		}
	} else {
		Connected = YES;
		[self SetCallButton:YES];
		CFWriteStreamOpen(writeStream);
		CFRunLoopRun();
//		[[connectbutton titleLabel] setText:@"Disconnect"];
//		statuslabel.text = @"Connected";
		
	}
}

-(void) SetCallButton:(BOOL)connected
{
	if (connected){
		[disconnect setHidden:NO];
		[connect setHidden:YES];
	} else {
		[disconnect setHidden:YES];
		[connect setHidden:NO];
	}
}

-(void) HideShowKeys{
	//Numbers
	if (control){
		num_nums.hidden = YES;
		num_syms.hidden = YES;
		num_cmdr.hidden = YES;
		num_ctrl.hidden = NO;
		let_lowr.hidden = YES;
		let_uppr.hidden = YES;
		let_cmdr.hidden = YES;
		let_shft.hidden = YES;
		let_syms.hidden = YES;
	} else {
		if (commodore) {
			num_nums.hidden = YES;
			num_syms.hidden = YES;
			num_cmdr.hidden = NO;
			num_ctrl.hidden = YES;
			let_lowr.hidden = YES;
			let_uppr.hidden = YES;
			let_cmdr.hidden = NO;
			let_shft.hidden = YES;
			let_syms.hidden = YES;
		} else {
			if (symbol){
				num_nums.hidden = NO;
				num_syms.hidden = YES;
				num_cmdr.hidden = YES;
				num_ctrl.hidden = YES;
				let_lowr.hidden = YES;
				let_uppr.hidden = YES;
				let_cmdr.hidden = YES;
				let_shft.hidden = YES;
				let_syms.hidden = NO;				
			} else {
				if (shift) {
					num_nums.hidden = YES;
					num_syms.hidden = NO;
					num_cmdr.hidden = YES;
					num_ctrl.hidden = YES;
					let_cmdr.hidden = YES;
					let_syms.hidden = YES;
					if (cset==0){
						let_lowr.hidden = YES;
						let_uppr.hidden = YES;				
						let_shft.hidden = NO;
					} else {
						let_lowr.hidden = YES;
						let_uppr.hidden = NO;				
						let_shft.hidden = YES;
					}
				} else {
					num_nums.hidden = NO;
					num_syms.hidden = YES;
					num_cmdr.hidden = YES;
					num_ctrl.hidden = YES;
					let_syms.hidden = YES;
					if (cset==0){
						let_lowr.hidden = YES;
						let_uppr.hidden = NO;				
						let_shft.hidden = YES;
					} else {
						let_lowr.hidden = NO;
						let_uppr.hidden = YES;				
						let_shft.hidden = YES;
					}
					let_cmdr.hidden = YES;
				}
			}
		}
	}
	
	
}
//-(IBAction) sendbutton_click{
//	[inputfield resignFirstResponder];
//	[self SendTextToSocket:inputfield.text];
//}
-(void) SendByteToSocket:(unsigned char *)chr{
	if (Connected) [self SendTextToSocket:[NSString stringWithFormat:@"%c",chr]];
}

-(void) SendTextToSocket:(NSString *)text {
	if (Connected){
		NSString *tempstr;
		tempstr = [[NSString alloc] initWithFormat:@"%@\n",text];
		CFWriteStreamWrite(writeStream,(UInt8 *)[tempstr UTF8String],strlen([tempstr UTF8String]));
		[tempstr release];
	}
}

-(void) Disconnect{
	[self ShowMessage:@"Disconnected." WithTitle:@"Notice"];
	Connected = NO; 
	[self SetCallButton:NO];
	CFWriteStreamClose(writeStream);
	CFReadStreamClose(readStream);
}

-(void) ShowMessage:(NSString *)message WithTitle:(NSString *)title{
	UIAlertView *popup = [[UIAlertView alloc] initWithTitle:title
													message:message
												   delegate:self
										  cancelButtonTitle:@"Ok"
										  otherButtonTitles:nil];
	
	[popup show];
	[popup release];
}

//Page Control
-(void)switchtopage:(int)page{
	CATransition *transition = [CATransition animation];
	transition.duration = 0.75;
	transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	transition.type = kCATransitionPush;
	if (page==6){
		transition.subtype = kCATransitionFromLeft;
	} else {
		transition.subtype = kCATransitionFromRight;
	}
//	transitioning = YES;
	transition.delegate = self;
	[self.view.layer addAnimation:transition forKey:nil];
	if (page==0){ //Main View
		glView.hidden = YES;
		termoptsview.hidden = YES;	
		configmenuview.hidden = YES;	
		bufferview.hidden = YES;	
		aboutview.hidden = YES;	
		bbslistview.hidden = YES;	
		bbseditview.hidden = YES;	
		mainview.hidden = NO;
	} 
	if (page==1){ //BBS List View
		glView.hidden = YES;
		termoptsview.hidden = YES;	
		configmenuview.hidden = YES;	
		bufferview.hidden = YES;	
		aboutview.hidden = YES;	
		bbslistview.hidden = NO;	
		bbseditview.hidden = YES;	
		mainview.hidden = YES;
	} 
	if (page==2){ //BBS Edit View
		glView.hidden = YES;
		termoptsview.hidden = YES;	
		configmenuview.hidden = YES;	
		bufferview.hidden = YES;	
		aboutview.hidden = YES;	
		bbslistview.hidden = YES;	
		bbseditview.hidden = NO;	
		mainview.hidden = YES;
	} 
	if (page==3){ //Term Opts View
		glView.hidden = YES;
		termoptsview.hidden = NO;	
		configmenuview.hidden = YES;	
		bufferview.hidden = YES;	
		aboutview.hidden = YES;	
		bbslistview.hidden = YES;	
		bbseditview.hidden = YES;	
		mainview.hidden = YES;
	} 
	if (page==4){ //Buffer List View
		glView.hidden = YES;
		termoptsview.hidden = YES;	
		configmenuview.hidden = NO;	
		bufferview.hidden = YES;	
		aboutview.hidden = YES;	
		bbslistview.hidden = YES;	
		bbseditview.hidden = YES;	
		mainview.hidden = YES;
	} 
	if (page==5){ //Buffer View
		glView.hidden = YES;
		termoptsview.hidden = YES;	
		configmenuview.hidden = YES;	
		bufferview.hidden = NO;	
		aboutview.hidden = YES;	
		bbslistview.hidden = YES;	
		bbseditview.hidden = YES;	
		mainview.hidden = YES;
	} 
	if (page==6){ //GL View
		glView.hidden = NO;
		termoptsview.hidden = YES;	
		configmenuview.hidden = YES;	
		bufferview.hidden = YES;	
		aboutview.hidden = YES;	
		bbslistview.hidden = YES;	
		bbseditview.hidden = YES;	
		mainview.hidden = YES;
	} 
	if (page==7){ //About View
		glView.hidden = YES;
		termoptsview.hidden = YES;	
		configmenuview.hidden = YES;	
		bufferview.hidden = YES;	
		aboutview.hidden = NO;	
		bbslistview.hidden = YES;	
		bbseditview.hidden = YES;	
		mainview.hidden = YES;
	} 
	
}

//Page Control Actions
-(IBAction) goto_main{
	[self switchtopage:0];
}

-(IBAction) goto_bbslist{
	[self load_bbslist];
	[bbslist_table reloadData];
	[self switchtopage:1];
}

-(IBAction) goto_bbsedit{
	[self switchtopage:2];
}

-(IBAction) goto_termopts{
	[baudemulation_seg setSelectedSegmentIndex:baud];
	[localecho_switch setOn:LocalEcho];
	[self switchtopage:3];
}

-(IBAction) goto_buffopts{
	[self switchtopage:5];
}

-(IBAction) goto_term{
	[self switchtopage:6];
}

-(IBAction) goto_about{
	[self switchtopage:7];
}

//Main menu Actions
-(IBAction) main_termopts_click{
	termoptsparent = 0;
	[self goto_termopts];
}

//In-Term Actions
-(IBAction) term_termopts_click{
	termoptsparent = 6;
	[self goto_termopts];
}

//Terminal Options Actions
-(IBAction) termopts_done{
	//Save baud emulation
	[database SetDefaults:@"Baud" value:[NSString stringWithFormat:@"%d",[baudemulation_seg selectedSegmentIndex]]];
	[self baudrate:[baudemulation_seg selectedSegmentIndex]];
	//Save localecho setting
	[database SetDefaults:@"LocalEcho" value:[NSString stringWithFormat:@"%d",[localecho_switch isOn]]];
	LocalEcho = [localecho_switch isOn];
	[self switchtopage:termoptsparent];
}
-(void) load_defaults{
	[self baudrate:[[database GetDefaults:@"Baud"] longLongValue]];
	LocalEcho = [[database GetDefaults:@"LocalEcho"] boolValue];
	[self load_bbslist];
}

-(void) load_bbslist{
	//Load BBSList
	[bbslist removeAllObjects];
	if ([database query:@"SELECT name,url,port,description FROM bbs"]){
		while (![database bEOF]){
			NSMutableString *bbsentry = [[NSMutableString alloc] initWithFormat:@"%@|%@|%@|%@",
										 [database get_string:field_name],
										 [database get_string:field_url],
										 [database get_string:field_port],
										 [database get_string:field_description]
										 ];
			[bbslist addObject:bbsentry];
			[bbsentry release];
			[database next_record];
		}
	}
}

-(void) baudrate:(int)rate{
	baud = rate;
	[timer invalidate];
	switch (rate) {
		case 0: //300
			timer =[NSTimer scheduledTimerWithTimeInterval:0.024 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];			
			break;
		case 1: //1200
			timer =[NSTimer scheduledTimerWithTimeInterval:0.006 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];			
			break;
		case 2: //2400
			timer =[NSTimer scheduledTimerWithTimeInterval:0.003 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];			
			break;
		case 3: //No Limit
			timer =[NSTimer scheduledTimerWithTimeInterval:0.0001 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];			
			break;
		default:
			break;
	}
}


#pragma mark -
#pragma mark TableView-Specific Routines
//TABLEVIEW-SPECIFIC ROUTINES========================================================================================+>>


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
		return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if ([tableView tag]==TABLE_BBSLIST)
	{
		return [bbslist count];
	}
	if ([tableView tag]==TABLE_BUFFERLIST)
	{
		return [bufferlist count];
	}
	return 0;
}

-(UITableViewCellAccessoryType)tableView:(UITableView *)tableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath
{
	if ([tableView tag]==TABLE_BBSLIST)
	{
		return UITableViewCellAccessoryDetailDisclosureButton;
	}
	if ([tableView tag]==TABLE_BUFFERLIST)
	{
		return UITableViewCellAccessoryNone;
	}
	return UITableViewCellAccessoryNone;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *identity = @"ListingCell";
	UITableViewCell *cell;
NS_DURING
	if ([tableView tag]==TABLE_BBSLIST)
	{
		cell = [self.bbslist_table dequeueReusableCellWithIdentifier:identity];
		if(cell == nil)
		{
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle  reuseIdentifier:identity] autorelease];
		}
		NSMutableArray *temparray = (NSMutableArray *)[(NSString *)[bbslist objectAtIndex:indexPath.row] componentsSeparatedByString:@"|"];
		[cell.textLabel setText:[temparray objectAtIndex:0]];
	}	
	if ([tableView tag]==TABLE_BUFFERLIST)
	{
		cell = [self.bufferlist_table dequeueReusableCellWithIdentifier:identity];
		if(cell == nil)
		{
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle  reuseIdentifier:identity] autorelease];
		}
		NSMutableArray *temparray = (NSMutableArray *)[(NSString *)[bufferlist objectAtIndex:indexPath.row] componentsSeparatedByString:@"|"];
		[cell.textLabel setText:[temparray objectAtIndex:1]];
	}	
	NS_HANDLER
	NSLog(@"Exception in categoryView::tableView::cellForRowAtIndexPath");
NS_ENDHANDLER
	return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath
{
	if ([tableView tag]==TABLE_BBSLIST)
	{
		NSMutableArray *temparray = (NSMutableArray *)[(NSString *)[bbslist objectAtIndex:indexPath.row] componentsSeparatedByString:@"|"];
		hostname = [temparray objectAtIndex:field_url];
		port = [temparray objectAtIndex:field_port];
		[self goto_term];
		[self ConnectToHost];
	}
}
-(void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	if ([tableView tag]==TABLE_BBSLIST)
	{
		//Edit 
		newbbs = NO;
		//get details
		NSMutableArray *temparray = (NSMutableArray *)[(NSMutableString *)[bbslist objectAtIndex:indexPath.row] componentsSeparatedByString:@"|"];
		oldurl = [[NSMutableString stringWithFormat:@"%@",[temparray objectAtIndex:field_url] ] copy]; 
		oldport = [[NSMutableString stringWithFormat:@"%@",[temparray objectAtIndex:field_port] ] copy]; 
		NSLog(@"Old URL: %@",oldurl);
		NSLog(@"Old PORT: %@",oldport);
		[bbsedit_name setText:[temparray objectAtIndex:field_name] ];
		[bbsedit_url  setText:[temparray objectAtIndex:field_url] ];
		[bbsedit_port setText:[temparray objectAtIndex:field_port] ];
		[bbsedit_desc setText:[temparray objectAtIndex:field_description]];
		[self goto_bbsedit];
	}
}

-(IBAction) bbsedit_save_click
{
	//Save as new or old?
	if (!newbbs){
		NSLog(@"Old URL: %@",oldurl);
		NSLog(@"Old PORT: %@",oldport);
		[database execute_sql:[NSString stringWithFormat:@"DELETE FROM bbs where url='%@' and port='%@'",oldurl,oldport]];
	}
	[database execute_sql:[NSString stringWithFormat:@"INSERT INTO bbs (name,url,port,description) VALUES ('%@','%@','%@','%@')",[database SQLString:[bbsedit_name text]],[bbsedit_url text],[bbsedit_port text],[database SQLString:[bbsedit_desc text]]]];
	newbbs = NO;
	[self goto_bbslist];
}

-(IBAction) bbsedit_cancel_click
{
	[self goto_bbslist];
}

-(IBAction) bbslist_new
{
	newbbs = YES;
	[bbsedit_name setText:@"" ];
	[bbsedit_url  setText:@"" ];
	[bbsedit_port setText:@"" ];
	[bbsedit_desc setText:@""];
	[self goto_bbsedit];
}
-(IBAction) bbslist_del
{
	//Save as new or old?
	if (!newbbs){
		NSLog(@"Old URL: %@",oldurl);
		NSLog(@"Old PORT: %@",oldport);
		[database execute_sql:[NSString stringWithFormat:@"DELETE FROM bbs where url='%@' and port='%@'",oldurl,oldport]];
	}
	[self goto_bbslist];
	
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if ([textField tag]==100){
		[bbsedit_url becomeFirstResponder];
	}
	if ([textField tag]==101) [bbsedit_port becomeFirstResponder];
	if ([textField tag]==102) [bbsedit_desc becomeFirstResponder];
	[textField resignFirstResponder];
	return NO;
}

//Buffer Menu Actions
-(IBAction) buffer_save_click{
	bufferbuttonmode = YES;
	[bufferlist_label setText:@"Enter A Filename"];
	[bufferlist_label setFrame:CGRectMake(0, 160, 320, 24)];
	[bufferlist_textfield setFrame:CGRectMake(20, 184, 280, 31)];
	[bufferlist_table setHidden:YES];
	[bufferlist_textfield setHidden:NO];
	[bufferlist_savebutton setTitle:@"Save" forState:UIControlStateNormal];
	[bufferlist_savebutton setTitle:@"Save" forState:UIControlStateDisabled];
	[bufferlist_savebutton setTitle:@"Save" forState:UIControlStateHighlighted];
	[bufferlist_delbutton setHidden:YES];
	[self switchtopage:4];
}

-(IBAction) buffer_load_click{
	bufferbuttonmode = NO;
	[bufferlist_label setText:@"Select Buffer To Load"];
	[bufferlist_label setFrame:CGRectMake(0, 73, 320, 24)];
	[bufferlist_table setHidden:NO];

	[bufferlist_textfield setFrame:CGRectMake(20, 284, 280, 31)];
	[bufferlist_textfield setHidden:YES];
	[bufferlist_savebutton setTitle:@"Load" forState:UIControlStateNormal];
	[bufferlist_savebutton setTitle:@"Load" forState:UIControlStateDisabled];
	[bufferlist_savebutton setTitle:@"Load" forState:UIControlStateHighlighted];
	[bufferlist_delbutton setHidden:YES];
	[self switchtopage:4];
}

-(IBAction) buffer_clear_click{
	UIAlertView *popup = [[UIAlertView alloc] initWithTitle:@"Clear Buffer"
													message:@"Are you sure?"
												   delegate:self
										  cancelButtonTitle:@"No"
										  otherButtonTitles:@"Yes",nil];
	[popup setTag:PROMPT_CLEAR_BUFFER];
	[popup show];
	[popup release];
	[buffer_size setText:@"0 bytes"];
	
}

-(void)bufferlist_fillbufferlist
{
	[bufferlist removeAllObjects];
	[database query:@"SELECT created,title FROM buffers ORDER BY title"];
	while (![database bEOF]) {
		NSMutableString *buffentry = [[NSMutableString alloc] initWithFormat:@"%@|%@",
									 [database get_string:0],
									 [database get_string:1]
									 ];
		[bufferlist addObject:buffentry];
		[buffentry release];
		[database next_record];
	}
	[bufferlist_table reloadData];
}

-(IBAction) buffer_send_click
{
	
}

-(IBAction) buffer_email_click{ //Currently used for "Manage Buffers"
	[bufferlist_label setText:@"Managing Saved Buffers"];
	[bufferlist_label setFrame:CGRectMake(0, 73, 320, 24)];
	[bufferlist_table setHidden:NO];
	[bufferlist_textfield setHidden:YES];
	[bufferlist_delbutton setHidden:NO];
	[bufferlist_savebutton setTitle:@"Load" forState:UIControlStateNormal];
	[bufferlist_savebutton setTitle:@"Load" forState:UIControlStateDisabled];
	[bufferlist_savebutton setTitle:@"Load" forState:UIControlStateHighlighted];
	[self bufferlist_fillbufferlist];
	[self switchtopage:4];	 
}

-(IBAction) buffer_review_click{

}

-(IBAction) bufferlist_saveclick{
	if (bufferbuttonmode){
		NSMutableString *buffstr = [[NSMutableString alloc] init];
		for (int i=0; i<[capturebuffer count]; i++) {
			buffstr = [buffstr stringByAppendingFormat:@"%c",[[capturebuffer objectAtIndex:i] charValue]];
		}
		[database execute_sql:[NSString stringWithFormat:@"INSERT INTO buffers (created,title,buff)VALUES ('2009-08-13 11:11:11','%@','%@')",[bufferlist_textfield text],[database SQLString:buffstr]]];
		//[buffstr release];
	} else { //Load Buffer
		NSMutableArray *temparray = (NSMutableArray *)[
		 (NSString *)[bufferlist objectAtIndex:
					  [[bufferlist_table indexPathForSelectedRow] row]
					  ] componentsSeparatedByString:@"|"];
		NSString *tempstr = [temparray objectAtIndex:1];
		[database query:[NSString stringWithFormat:@"SELECT buff FROM buffers WHERE title = '%@'",tempstr]];
		[capturebuffer removeAllObjects];
		NSString *tempstring = [database get_string:0];
		char *tempcstring = [tempstring UTF8String];
//		NSMutableArray *tempchars = [[database get_string:0] componentsSeparatedByString:@""];
		for (int i=0; i<[tempstring lengthOfBytesUsingEncoding:NSUTF8StringEncoding]; i++) {
			[capturebuffer addObject:[[NSNumber alloc] initWithChar:tempcstring[i]]];
		}
	}
}

-(IBAction) bufferlist_delclick{
	
}

-(IBAction) bufferlist_cancelclick{
	[self switchtopage:5];
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (alertView.tag == PROMPT_CLEAR_BUFFER){
		if (buttonIndex == 1)
		{
			[capturebuffer removeAllObjects];
		}
	}
}



-(IBAction) toggle_capture{
	capture = [capture_switch isOn];
}

-(IBAction) bbsedit_port_edit{
	[bbseditview setFrame:CGRectMake(0, -100, 320, 480)];
}
-(IBAction) bbsedit_port_exit{
	[bbseditview setFrame:CGRectMake(0, 0, 320, 480)];	
}
-(IBAction) bbsedit_desc_edit{
	[bbseditview setFrame:CGRectMake(0, -100, 320, 480)];
}
-(IBAction) bbsedit_desc_exit{
	[bbseditview setFrame:CGRectMake(0, 0, 320, 480)];
}


@end
