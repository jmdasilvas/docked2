
#import "Celestial/AVSystemController.h"
#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBStatusBarController.h>
#import <SpringBoard/SBIconController.h>


//#include <CydiaSubstrate.h>
#include <substrate.h>

#include "mouse_msgs.h"
#import "../libactivator/libactivator.h"
#include "calibration.h"

#include <stdio.h>   /* Standard input/output definitions */
#include <string.h>  /* String function definitions */
#include <unistd.h>  /* UNIX standard function definitions */
#include <fcntl.h>   /* File control definitions */
#include <errno.h>   /* Error number definitions */
#include <termios.h> /* POSIX terminal control definitions */
#import <sys/sysctl.h>
#include <sys/ioctl.h>

#ifndef kCFCoreFoundationVersionNumber_iOS_4_0
#define kCFCoreFoundationVersionNumber_iOS_4_0 550.32
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_6_0
#define kCFCoreFoundationVersionNumber_iOS_6_0 793.00
#endif


extern int Cal_State;

static AVSystemController *_avs;
static bool wasconected=false;
static struct termios term;
static bool readThreadOut=false;
static NSLock *lock_;
static bool videooutChange=false;
// Screen res
//static float screen_width = 0, screen_height = 0;
//static float retina_factor = 1.0f;

// Define button values
#define BUTTON_LOCK 0x02
#define BUTTON_MENU 0x04
static char buttonLock = BUTTON_LOCK;
static char buttonHome = BUTTON_MENU;
static BOOL swapButtons = NO;
static BOOL swapXY = NO;
static BOOL calibratePref = YES;
static BOOL calibratePrefu = YES;

#define APP_ID "com.jmdasilvas.cariphone2"
#define springBoardApp (SpringBoard *)[UIApplication sharedApplication]

#import <stdio.h>
#import <stdlib.h>
#import <unistd.h>

MSClassHook(SBStatusBarController)

@class LAActivator;
static LAActivator *activator;
static BOOL showPointer = NO;
static BOOL showIcon = YES;
static BOOL bypass = NO;
static NSString *PassCode = @"";


NSMutableArray *displayStacks = nil;

// Display stack names
#define SBWPreActivateDisplayStack        [displayStacks objectAtIndex:0]
#define SBWActiveDisplayStack             [displayStacks objectAtIndex:1]
#define SBWSuspendingDisplayStack         [displayStacks objectAtIndex:2]
#define SBWSuspendedEventOnlyDisplayStack [displayStacks objectAtIndex:3]



// iOS 6.0+
@interface BKSWorkspace : NSObject
- (id)topApplication;
@end
@interface SBAlertManager : NSObject @end
@interface SBWorkspaceTransaction : NSObject @end
@interface SBToAppWorkspaceTransaction : SBWorkspaceTransaction @end
@interface SBAppToAppWorkspaceTransaction : SBToAppWorkspaceTransaction
- (id)initWithWorkspace:(id)workspace alertManager:(id)manager from:(id)from to:(id)to;
@end

@interface SBWorkspace : NSObject
@property(readonly, assign, nonatomic) SBAlertManager *alertManager;
@property(readonly, assign, nonatomic) BKSWorkspace *bksWorkspace;
@property(retain, nonatomic) SBWorkspaceTransaction *currentTransaction;
- (id)_applicationForBundleIdentifier:(id)bundleIdentifier frontmost:(BOOL)frontmost;
@end

//=============================================================================


static SBWorkspace *workspace$ = nil;

@interface UIScreen (fourZeroAndLater)
@property(nonatomic,readonly) CGFloat scale;
@end




// NOTE: This is needed to prevent a compiler warning
@interface SpringBoard (Backgrounder)
- (void)setBackgroundingEnabled:(BOOL)enabled forDisplayIdentifier:(NSString *)identifier;
@end

@interface SpringBoard (docked2)
- (void) docked2_beginCalibration;
@end

//==============================================================================

@interface docked2Activator : NSObject <LAListener>
@end

@implementation docked2Activator

+ (void)cargar
{
    static docked2Activator *listener = nil;
    NSLog(@"*****************************VAMOS A CARGAR docked2Activator");
    if (listener == nil) {
        // Create LastApp's event listener and register it with libactivator
        listener = [[docked2Activator alloc] init];
        [[LAActivator sharedInstance] registerListener:listener forName:@APP_ID];
        NSLog(@"*****************************listener %@",listener);
        
    }
}

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event
{
    SpringBoard *springBoard = (SpringBoard *)[UIApplication sharedApplication];
    [springBoard docked2_beginCalibration];

    // Prevent the default OS implementation
    event.handled = YES;
}

@end

//==============================================================================



@interface IconStuff : NSObject {
}

+ (void) removeStatusBarItem;
+ (void) addStatusBarItem;
+ (void) ActivatorButton:(int)button;
+ (void) TurnToRight;
+ (BOOL) AnyAppOnFront;


@end
 
@implementation IconStuff 


+ (void) TurnToRight {


	[[UIDevice currentDevice] setOrientation:UIInterfaceOrientationLandscapeRight ];
	[[UIDevice currentDevice] setOrientation:UIInterfaceOrientationLandscapeLeft ];

	[UIApplication sharedApplication].statusBarOrientation = UIInterfaceOrientationLandscapeRight;
	
}


+ (void) removeStatusBarItem {
  if ($SBStatusBarController != nil)
  	[[$SBStatusBarController sharedStatusBarController] removeStatusBarItem:@"cariphone"];
  else
    [[UIApplication sharedApplication] removeStatusBarImageNamed:@"cariphone"];
}

+ (void) addStatusBarItem {
  if ($SBStatusBarController != nil)
  	[[$SBStatusBarController sharedStatusBarController] addStatusBarItem:@"cariphone"];
  else
  	[[UIApplication sharedApplication] addStatusBarImageNamed:@"cariphone"];
}
 
+ (BOOL) AnyAppOnFront
{

  //ACTUALIZADO PARA ios6
  SBApplication *currentApplication = nil;

  if (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_6_0) {
    currentApplication = [SBWActiveDisplayStack topApplication];
  }
  else {
    currentApplication = [workspace$.bksWorkspace topApplication];
  }

  if (currentApplication)
    return YES;
  else
      return NO;


} 

+ (void)ActivatorButton:(int)button
{

	// libactivator
	if (activator) {
		NSString *eventName = nil;
		switch (button) {
			case 1:
				eventName = @"ve.jmdasilvas.cariphone.btn01";
				break;
			case 2:
				eventName = @"ve.jmdasilvas.cariphone.btn02";
				break;
			case 3:
				eventName = @"ve.jmdasilvas.cariphone.btn03";
				break;
			case 4:
				eventName = @"ve.jmdasilvas.cariphone.btn04";
				break;
			case 5:
				eventName = @"ve.jmdasilvas.cariphone.btn05";
				break;

			default:
				break;
		}
		LAEvent *event = nil;
		if (eventName) {
			Class laEventClass = objc_getClass("LAEvent");
			NSString *currentMode = [activator currentEventMode];
			event = [[[laEventClass alloc] initWithName:eventName mode:currentMode] autorelease];
		} else {
			// NSLog(@"Activator other button %u", button);
		}
		if (event) {
			// NSLog(@"Activator event %@", eventName);
			[activator sendEventToListener:event];
		} else {
			// NSLog(@"event creation failed");
		}
	}

}


@end


//------------------------------PREFERENCES------------------------------------------------
static void loadPreferences()
{
  NSArray *keys = [NSArray arrayWithObjects:@"showPointer", @"showIcon", @"swapButtons", @"swapXY", @"calibratePref", @"passCode" ,nil];
    NSDictionary *dict = (NSDictionary *)CFPreferencesCopyMultiple((CFArrayRef)keys, CFSTR(APP_ID),
        kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    if (dict) {

	

        NSArray *values = [dict objectsForKeys:keys notFoundMarker:[NSNull null]];
	
	NSLog(@"*****************************loadPreferences  values %@",values);


        id obj = [values objectAtIndex:0];
        if ([obj isKindOfClass:[NSNumber class]])
            showPointer = [obj boolValue];

	if ([values count]>1)
	{
	    obj = [values objectAtIndex:1];
	    if ([obj isKindOfClass:[NSNumber class]])
	       showIcon = [obj boolValue];
	}

	if ([values count]>2)
	{
	    obj = [values objectAtIndex:2];
	    if ([obj isKindOfClass:[NSNumber class]])
	       swapButtons = [obj boolValue];           
	}

  if ([values count]>3)
  {
      obj = [values objectAtIndex:3];
      if ([obj isKindOfClass:[NSNumber class]])
         swapXY = [obj boolValue];           
  }

  if ([values count]>4)
  {
      obj = [values objectAtIndex:4];
      if ([obj isKindOfClass:[NSNumber class]])
         calibratePref = [obj boolValue];           
  }

	if ([values count]>5)
	{
	        PassCode = [values objectAtIndex:5];
	        //if ([obj isKindOfClass:[NSString class]])
	        //    PassCode = [obj stringValue];
		NSLog(@"*****************************PassCode preferences %@",PassCode);
	}

        [dict release];
    }
} 

static void reloadPreferences(CFNotificationCenterRef center, void *observer,
    CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	// NOTE: Must synchronize preferences from disk
	CFPreferencesAppSynchronize(CFSTR(APP_ID));
	loadPreferences();

  if (calibratePref == YES && calibratePrefu == NO)
  {
     BeginCalibration();
     NSLog(@"*****************************Cal_State %i",Get_Cal_State());
  }
  calibratePrefu = calibratePref;



	  if (showIcon == YES) {
      if (wasconected == YES)
	  	  [IconStuff performSelectorOnMainThread:@selector(addStatusBarItem) withObject:nil waitUntilDone:YES];
    }
	  else {
		  [IconStuff performSelectorOnMainThread:@selector(removeStatusBarItem) withObject:nil waitUntilDone:YES];
    }
  
	mouseCursorShow(showPointer);

     if (swapButtons  == YES) {
        buttonLock = BUTTON_MENU;
        buttonHome = BUTTON_LOCK;
    } else {
        buttonHome = BUTTON_MENU;
        buttonLock = BUTTON_LOCK;
    } 

}
//------------------------------PREFERENCES------------------------------------------------



//------------------------------SERIAL PORT------------------------------------------------
static int InitConn(int speed)
{
	unsigned int    blahnull = 0;
	unsigned int    handshake = TIOCM_DTR | TIOCM_RTS | TIOCM_CTS | TIOCM_DSR;
	int             fd = open("/dev/tty.iap", O_RDWR | 0x20000 | O_NOCTTY);

	if (fd == -1) {
		fprintf(stderr, "%i(%s)\n", errno, strerror(errno));
		exit(1);
	}
	ioctl(fd, 0x2000740D);
	fcntl(fd, 4, 0);
	tcgetattr(fd, &term);

	ioctl(fd, 0x8004540A, &blahnull);
	cfsetspeed(&term, speed);
	cfmakeraw(&term);
	term.c_cc[VMIN] = 0;
	term.c_cc[VTIME] = 5;

	term.c_cflag = (term.c_cflag & ~CSIZE) | CS8;
	term.c_cflag &= ~PARENB;
	term.c_lflag &= ~ECHO;

	if(tcsetattr(fd, TCSANOW, &term) == -1)
	    fprintf(stderr,"TCSANOW error!\n");

	ioctl(fd, TIOCSDTR);
	ioctl(fd, TIOCCDTR);
	ioctl(fd, TIOCMSET, &handshake);

	return fd;
}

static void CloseConn(int fd)
{ 
	tcdrain(fd);
	//tcsetattr(fd, TCSANOW, &gOriginalTTYAttrs);
	close(fd);
}


static int converter(int huns, int tens, int ones)
{
    if (huns)
        huns =(huns - 48)*100;

    if (tens)
        tens =(tens - 48)*10;
        
    if (ones)
        ones = ones -48;
    return huns+tens+ones;
}

//--------------------------------------------------------------------------------
//--------------------------------------------------------------------------------



static void tvOutAvailabilityChanged(CFNotificationCenterRef center, void *observer,
    CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	videooutChange=true;
	//NSLog(@"HUBO videooutChange");

}







//==============================================================================



%hook SBDisplayStack %group GFirmware_LT_60

- (id)init
{
    id stack = %orig;
    [displayStacks addObject:stack];
    return stack;
}

- (void)dealloc
{
    [displayStacks removeObject:self];
    %orig;
}

%end %end

//==============================================================================




static id scheduledTransaction$ = nil;

%hook SBWorkspace %group GFirmware_GTE_60

- (id)init
{
    self = %orig;
    if (self != nil) {
        workspace$ = [self retain];
    }
    return self;
}

- (void)dealloc
{
    if (workspace$ == self) {
        [workspace$ release];
        workspace$ = nil;
    }
    %orig;
}

- (void)transactionDidFinish:(id)transaction success:(BOOL)success
{
    %orig;

    if (scheduledTransaction$ != nil) {
        [self setCurrentTransaction:scheduledTransaction$];
        [scheduledTransaction$ release];
        scheduledTransaction$ = nil;
    }
}

%end %end


@interface UIApplication (libstatusbar)
- (void) addStatusBarImageNamed: (NSString*) name removeOnExit: (BOOL) remove;
- (void) addStatusBarImageNamed: (NSString*) name;
- (void) removeStatusBarImageNamed: (NSString*) name;
@end



%hook SBSlidingAlertDisplay

-(void)animateToShowingDeviceLockFinished
{

	%log;
	%orig;

	if(bypass){
		SBDeviceLockView *SBDevLockView = MSHookIvar<SBDeviceLockView*>(self, "_deviceLockView");
		if (SBDevLockView &&  [PassCode length] == 4)
		{
			SBDevLockView.passcode=PassCode;
			[SBDevLockView  notifyDelegateThatPasscodeWasEntered];
		}
	}

	//NSLog(@"**********************************animateToShowingDeviceLockFinished");	
	

}
-(void)animateToHidingDeviceLockFinished
{

	NSLog(@"**********************************animateToHidingDeviceLockFinished");	
	%orig;

}

-(void)deviceLockViewPasscodeEntered:(id)entered
{
	%log;
	NSLog(@"**********************************deviceLockViewPasscodeEntered");
	%orig;
}

%end


@interface SpringBoard (dockedInternal)
- (BOOL) ExitAppIfAny;
@end


static BOOL canInvoke()
{
    // Should not invoke if either lock screen or power-off screen is active
    SBAwayController *awayCont = [objc_getClass("SBAwayController") sharedAwayController];
    return !([awayCont isLocked]
            || [awayCont isMakingEmergencyCall]
            || [(SBIconController *)[objc_getClass("SBIconController") sharedInstance] isEditing]
            || [(SBPowerDownController *)[objc_getClass("SBPowerDownController") sharedInstance] isOrderedFront]);
}


%hook SpringBoard


-(void)applicationDidFinishLaunching:(id)application {

    // NOTE: SpringBoard creates four stacks at startup
    // NOTE: Must create array before calling original implementation
    displayStacks = [[NSMutableArray alloc] initWithCapacity:4];

    %orig;
	//get screen res
    
    /*
    	CGRect rect = [[UIScreen mainScreen] bounds];
    	screen_width = rect.size.width;
    	screen_height = rect.size.height;

	NSLog(@"*********************************screen  x: %f y: %f ",screen_width,screen_height); 
*/

    	// handle retina devices (checks for iOS4.x)

  /*
	if([[UIScreen mainScreen] respondsToSelector:NSSelectorFromString(@"scale")])
		retina_factor = [UIScreen mainScreen].scale;	

  screen_width *= retina_factor;
  screen_height *= retina_factor;
	NSLog(@"*******************************screen  x: %f y: %f ",screen_width,screen_height); 
*/


	loadPreferences();



	[IconStuff performSelectorOnMainThread:@selector(removeStatusBarItem) withObject:nil waitUntilDone:YES];

	mouseCursorShow(showPointer);

  if (swapButtons  == YES) {
    buttonLock = BUTTON_MENU;
    buttonHome = BUTTON_LOCK;
  } 
  else 
  {
    buttonHome = BUTTON_MENU;
    buttonLock = BUTTON_LOCK;
  }
  

	lock_ = [[NSLock alloc] init];

	_avs = [AVSystemController sharedAVSystemController];
	 [[NSNotificationCenter defaultCenter] addObserver:self 
    		selector:@selector(routeChange2:) 
  		name:@"AVSystemController_ActiveAudioRouteDidChangeNotification"
  		object:_avs];


	// Listen for changes in TV-out availablity
	// NOTE: Credit goes to Erica Sadun for finding this notification.
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
	NULL, tvOutAvailabilityChanged, CFSTR("com.apple.iapd.videoout.SettingsChanged"), NULL, 0);


	// Add observer for changes made to preferences
	CFNotificationCenterAddObserver(
		CFNotificationCenterGetDarwinNotifyCenter(),
		NULL, reloadPreferences, CFSTR(APP_ID"-settings"),
		NULL, 0);

  // load libActivator
  dlopen("/usr/lib/libactivator.dylib", RTLD_LAZY);
  activator = [objc_getClass("LAActivator") sharedInstance];


    // NOTE: This library should only be loaded for SpringBoard
  NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
  if ([identifier isEqualToString:@"com.apple.springboard"]) {
    NSLog(@"*********************************identifier  %@",identifier); 
    [docked2Activator cargar];
  }


}




%new(@@:)
- (void) routeChange2: (NSNotification *) notification
{

	[self performSelector:@selector(retardedCheck) withObject:nil afterDelay:0.5f];
}



%new(@@:)
- (void)retardedCheck
{


	//is not iapd notification then return
	if (!videooutChange)
		return;

	

	Class UIMoviePlayerController = objc_getClass("UIMoviePlayerController");
	id movieController = [UIMoviePlayerController alloc];	
	if ([movieController videoOutActive])
	{
		NSLog(@"*********************************CONNECTED CONNECTED CONNECTED CONNECTED CONNECTED CONNECTED ");
		if (!wasconected)
		{



			//is device locked?
      Class SBAwayController = objc_getClass("SBAwayController");
			id awayController = [SBAwayController sharedAwayController];
			
			float delay=1.0f;

			//ENABLE bypass the passcode lock  
			bypass = YES;

      if ([awayController isLocked] )//&& ![awayController isPasswordProtected])
			{
				  [awayController attemptUnlock];
          //[awayController setDeviceLocked:NO]; not in ios6
          [awayController unlockWithSound:NO]; 
				  delay=2.0f; //device is locked get a little bit more time
	
			}
			

			//show icon in status bar
			if (showIcon == YES)
				[IconStuff performSelectorOnMainThread:@selector(addStatusBarItem) withObject:nil waitUntilDone:YES];

			//if any app runnig exit first
      //[self performSelector:@selector(ExitAppIfAny) withObject:nil afterDelay:delay];
      //if ([self ExitAppIfAny]) delay+=1;

      //if any app runnig exit first
      if ([IconStuff AnyAppOnFront])
      {
        [self performSelector:@selector(homeButton) withObject:nil afterDelay:delay];
        delay+=1.0f;
      }


			//We are in homescreen now then rotate to left (SBRotator 5 have to be installed)
      [self performSelector:@selector(lockRot) withObject:nil afterDelay:delay+0.5f];

			//launch application choose in Activator
			[self performSelector:@selector(activateApplication) withObject:nil afterDelay:delay+1.0f];
      wasconected=true;


		}
      
    
     

	}
	else
	{
		NSLog(@"*********************************OFF OFF OFF OFF OFF OFF");
		if (wasconected)
		{

			if (showIcon == YES)
				[IconStuff performSelectorOnMainThread:@selector(removeStatusBarItem) withObject:nil waitUntilDone:YES];

      float delay=0.5f;

   		[self performSelector:@selector(unlockRot) withObject:nil afterDelay:delay];


			
			//[self performSelector:@selector(ExitAppIfAny) withObject:nil afterDelay:1.0f];

      if ([IconStuff AnyAppOnFront])
      {
        [self performSelector:@selector(homeButton) withObject:nil afterDelay:delay];
        delay+=1.0f;
      }


			[self performSelector:@selector(sleepButton) withObject:nil afterDelay:delay + 2.0f];
                	 
			wasconected=false;

			//DISABLE bypass the passcode lock  
			bypass = NO;


		}


	}

	videooutChange=false;

	[movieController dealloc];


}






%new(@@:)
- (void)readDataInBackgroundThread
{
  // setup the thread's memory management.  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; 

	char buf[10];
	int count=4;
	int c=0;
	int estado=0;
  int x;
  int y;
	
	//open mouse
	mouseOpen(showPointer);


  

	//open serial port
	int fd = InitConn(19200);
	if(fd>-1)
	{

    NSLog(@"********************ENTRO EN readDataInBackgroundThread SERIAL PORT");

		while ( 1==1 )
		{	

			bool tempout=false;
			[lock_ lock];
				
			tempout=readThreadOut;
			
			[lock_ unlock];
	 

			if (tempout)
				break;

			count--; 
      c=-1;
      read(fd,&c,1);

      if (c != -1)
      {  

				c = c+256;


				if (c == 42)
				{
					if (estado!=0 && estado!=1)
						estado=0;
					estado++;
				}
				else
				{
					if (estado>2)
					{
						buf[estado-2]=c;
						estado++;
						if (estado>=9)
						{
							x = converter(buf[0], buf[1], buf[2]);
							y = converter(buf[3], buf[4], buf[5]);
									

							//NSLog(@"hid injected x: %i y: %i button: %i",x,y,buf[6]);  


 
							if (buf[6])
								buf[6] = buf[6] - 48;

							if (buf[6] == 8)
							{
								[IconStuff ActivatorButton:x];
								//NSLog(@"boton enviado"); 
							}
 							else if (buf[6] == 4)  //HOME  BUTTON
							{
          	    mouseSendEvent(0,0,buttonHome);
								//[IconStuff ActivatorButton:x];
								//NSLog(@"boton enviado"); 
							}             
							else if (x>=0 && y>=0)
							{

								//uint8_t buttonMask;     bits 0-7 are buttons 1-8, 0=up, 1=down
								//if (!SendPointerEvent(client,x, y, buf[6]))
								//	break;								
								//hid_inject_mouse_abs_move(buf[6], x, y);
						    //NSLog(@"hid injected x: %i y: %i button: %i",x,y,buf[6]);
                
                Do_Calibration(x,y);

								//mouseSendEvent(x,y,buf[6]);
                DoCalibrationLoop(x,y);
                if (Get_Cal_State() == 0)
                {
                  //NSLog(@"xCal: %i yCal: %i orientation: %i",GetX_Calibrate(),GetY_Calibrate(),orientation());
                  if (swapXY == YES)
                    mouseSendEvent(GetY_Calibrate(),GetX_Calibrate(),buf[6]);
                  else
                    mouseSendEvent(GetX_Calibrate(),GetY_Calibrate(),buf[6]);                    

                }
								

							}

							estado=0;
							c=32;

							//NSLog(@"screen  x: %f y: %f ",screen_width,screen_height); 

							write(fd,&c,1);

						}

					}
					if (estado==2)
					{
						memset(buf, 0, 10);
						buf[0]=c;
						estado++;
					}


				}

			} //  if (c != -1)
		} //while ( count>0 )
		



		//close serial port
		CloseConn(fd);

		//close mouse
		mouseClose();


	} //if(fd>-1)



  NSLog(@"********************SALIO EN readDataInBackgroundThread SERIAL PORT");
  [pool release];    

}



%new
- (void) docked2_beginCalibration
{
    if (!canInvoke()) return;
    BeginCalibration();
    NSLog(@"*****************************Cal_State %i",Get_Cal_State());

}

%new(@@:)
- (void) activateApplication
{


	// libactivator
	if (activator) {
		NSString *eventName = nil;
		eventName = @"ve.jmdasilvas.cariphone.applaunch";
		LAEvent *event = nil;
		if (eventName) 
		{
			Class laEventClass = objc_getClass("LAEvent");
			NSString *currentMode = [activator currentEventMode];
			event = [[[laEventClass alloc] initWithName:eventName mode:currentMode] autorelease];
		} 
		else 
		{
			// NSLog(@"Activator other button %u", button);
		}
		if (event) 
		{
			// NSLog(@"Activator event %@", eventName);
			[activator sendEventToListener:event];
		} 
		else 
		{
			// NSLog(@"event creation failed");
		}	

	}
		



}


%new(@@:)
- (BOOL) ExitAppIfAny
{

	//ACTUALIZADO PARA ios6
	SBApplication *currentApplication = nil;

	if (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_6_0) {
	   currentApplication = [SBWActiveDisplayStack topApplication];
	}
	else {
 	   currentApplication = [workspace$.bksWorkspace topApplication];
	}

	if (currentApplication) {
     NSLog(@"*******************APLICACION ACTUAL ES %@",currentApplication);
 	   [self performSelector:@selector(homeButton) withObject:nil];     
     return YES;
  }
  else {
    return NO;
  }

  


/*
	SBApplication *currentApplication = [SBWActiveDisplayStack topApplication];	 
	if (currentApplication)
		[self performSelector:@selector(homeButton) withObject:nil afterDelay:0.1f];

*/



}


%new(@@:)
- (void) lockRot
{


	
	[IconStuff performSelectorOnMainThread:@selector(TurnToRight) withObject:nil waitUntilDone:YES];


	Class SBOrientationLockManager= objc_getClass("SBOrientationLockManager");
	id sbOrientation = [SBOrientationLockManager sharedInstance];
	[sbOrientation unlock];

	[sbOrientation lock];
		
	[lock_ lock];			
	readThreadOut=false;
	[lock_ unlock];


	[NSThread detachNewThreadSelector:@selector(readDataInBackgroundThread) toTarget:self withObject:nil];

}

%new(@@:)
- (void) unlockRot
{


	Class SBOrientationLockManager= objc_getClass("SBOrientationLockManager");
	id sbOrientation = [SBOrientationLockManager sharedInstance];
	[sbOrientation unlock];

	[lock_ lock];			
	readThreadOut=true;
	[lock_ unlock];


}



 
%new(@@:)
- (void) homeButton
{

	//open mouse
	mouseOpen(showPointer);

	mouseSendEvent(0,0,buttonHome);
	mouseSendEvent(0,0,0x00);


  NSLog(@"Send ButtonHOME %u", buttonHome);



	//close mouse
	mouseClose();

}


%new(@@:)
- (void) sleepButton
{

	mouseOpen(showPointer);


	//[springBoardApp powerDown];

	mouseSendEvent(0,0,buttonLock);
	mouseSendEvent(0,0,0x00);

	//close mouse
	mouseClose();


}



- (void) dealloc {
    [_avs dealloc];
    _avs = nil;
    %orig;
}

%end


__attribute__((constructor)) static void init()
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    // NOTE: This library should only be loaded for SpringBoard
    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    if ([identifier isEqualToString:@"com.apple.springboard"]) {
        // Initialize hooks
        %init;

        if (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_6_0) {
            %init(GFirmware_LT_60);
        } else {
            %init(GFirmware_GTE_60);
        }

	/*

        // Load preferences
        loadPreferences();

        // Add observer for changes made to preferences
        CFNotificationCenterAddObserver(
                CFNotificationCenterGetDarwinNotifyCenter(),
                NULL, reloadPreferences, CFSTR(APP_ID"-settings"),
                NULL, 0);

        // Create the libactivator event listener
        [LastAppActivator load];
	*/
        //[docked2Activator load];
    }

    [pool release];
}


