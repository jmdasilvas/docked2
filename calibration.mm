/* code swiped from
 * MMSE-Based Multipoint Calibration Algorithm 
 * for Touch Screen Applications 
 * by Ning Jia
 *
 * AN-1021 APPLICATION NOTE
 * ADVANCE DEVICES
 *
 * http://www.analog.com/static/imported-files/application_notes/AN-1021.pdf
 *
*/
 
//-----------------------------------------------------------------------------------------
//------------------------------CALIBRACION------------------------------------------------
//-----------------------------------------------------------------------------------------

#include "calibration.h"

static int Cal_State=0;
static int ciclos=0;
static float screen_width = 0, screen_height = 0;	

static bool hubotecla=false;
//static BOOL tempCursorShow;

static int 		Px,Py; 																	//mousecoordinates after calibration
static double 	KX1, KX2, KX3, KY1, KY2, KY3;  					// coefficients for calibration algorithm
static float 	KX1_0=2, KX2_0=1, KX3_0=0, KY1_0=1, KY2_0=1, KY3_0=0;  	// coefficients for calibration algorithm
static float 	KX1_1=2, KX2_1=1, KX3_1=0, KY1_1=1, KY2_1=1, KY3_1=0;  	// coefficients for calibration algorithm
static float 	ReferencePoint[N][2]; 												// ideal position of reference points 
static float 	SamplePoint[N][2]; 

#define SBSERVPATH  "/System/Library/PrivateFrameworks/SpringBoardServices.framework/SpringBoardServices"
int orientation()
{
	//1 portrait
	//2 landscape homeButton left
	//3 landscape homeButton right
	//4 portrait homeButton UP
    mach_port_t *port;
    void *lib = dlopen(SBSERVPATH, RTLD_LAZY);
    int (*SBSSpringBoardServerPort)() = (int (*)())dlsym(lib, "SBSSpringBoardServerPort");
	 port = (mach_port_t *)SBSSpringBoardServerPort();
    dlclose(lib); 
	 void *(*SBGetInterfaceOrientation)(mach_port_t *port, int *result) = (void *(*)(mach_port_t *, int *))dlsym(lib, "SBGetInterfaceOrientation"); 
	 int o=-1;
	 SBGetInterfaceOrientation(port,&o); 
	 return o;
}


void InitCoeficients() {

		KX1=2;
		KX2=1;
		KX3=0;
		KY1=1; 
		KY2=1;
		KY3=0;

		CGRect rect = [[UIScreen mainScreen] bounds];
		screen_width = rect.size.width;
		screen_height = rect.size.height;
		float xr,yr;
		xr=rect.size.height;
		yr=rect.size.width;

		NSUserDefaults *Cals = [NSUserDefaults standardUserDefaults];
		KX1_0 = [Cals floatForKey:@"KX1_0"];
		KX2_0 = [Cals floatForKey:@"KX2_0"];   
		KX3_0 = [Cals floatForKey:@"KX3_0"];
		KY1_0 = [Cals floatForKey:@"KY1_0"];
		KY2_0 = [Cals floatForKey:@"KY2_0"];   
		KY3_0 = [Cals floatForKey:@"KY3_0"];   

		KX1_1 = [Cals floatForKey:@"KX1_1"];
		KX2_1 = [Cals floatForKey:@"KX2_1"];   
		KX3_1 = [Cals floatForKey:@"KX3_1"];
		KY1_1 = [Cals floatForKey:@"KY1_1"];
		KY2_1 = [Cals floatForKey:@"KY2_1"];   
		KY3_1 = [Cals floatForKey:@"KY3_1"]; 

		//if (KX1 == 0)
		//	Cal_State=1;

		NSLog(@"************************FIRST CALIBRATIONS LOADED KX1_0 %f  KX1_1 %f",KX1_0,KX1_1);
}

void Do_Calibration(int x,int y) // do calibration for point 
{ 

	static bool NoCalibrate=true;
	if (NoCalibrate)
	{
		NSLog(@"************************LOAD FIRST CALIBRATIONS");
		InitCoeficients();
		NoCalibrate=false;
	}

	if (orientation()==1) //portrait
	{
		Px=(int)(KX1_1 * x + KX2_1 * y + KX3_1 + 0.5);  
		Py=(int)(KY1_1 * x + KY2_1 * y + KY3_1 + 0.5);  

/*
		if (Px>screen_width)
			Px=screen_width;
		if (Py>screen_height)
			Py=screen_height;  
			*/
	}
	else 	if (orientation()==3)
	{
		Px=(int)(KX1_0 * x + KX2_0 * y + KX3_0 + 0.5);  
		Py=(int)(KY1_0 * x + KY2_0 * y + KY3_0 + 0.5); 
		/*  
		if (Py>screen_width)
			Py=screen_width;
		if (Px>screen_height)
			Px=screen_height;  		
			*/ 
	}
} 

void Get_Calibration_Coefficient()  // calculate the coefficients for calibration 
	//algorithm: KX1, KX2, KX3, KY1, KY2, KY3 
{ 
	int i; 
	int Points=N; 
	double a[3],b[3],c[3],d[3],k; 
	if(Points<3) 
	{ 
		return;  
	} 
	else 
	{ 
		if(Points==3) 
		{ 
			for(i=0; i<Points; i++) 
			{ 
				a[i]=(double)(SamplePoint[i][0]); 
				b[i]=(double)(SamplePoint[i][1]); 
				c[i]=(double)(ReferencePoint[i][0]); 
				d[i]=(double)(ReferencePoint[i][1]); 
			}   
		} 
		else if(Points>3) 
		{ 
			for(i=0; i<3; i++)  
			{ 
				a[i]=0; 
				b[i]=0; 
				c[i]=0; 
				d[i]=0; 
			} 
			for(i=0; i<Points; i++)  //AN-1021  Application Note Rev. 0 | Page 10 of 12 
			{ 
				a[2]=a[2]+(double)(SamplePoint[i][0]); 
				b[2]=b[2]+(double)(SamplePoint[i][1]); 
				c[2]=c[2]+(double)(ReferencePoint[i][0]); 
				d[2]=d[2]+(double)(ReferencePoint[i][1]); 
				a[0]=a[0]+(double)(SamplePoint[i][0])*(double)(SamplePoint[i][0]); 
				a[1]=a[1]+(double)(SamplePoint[i][0])*(double)(SamplePoint[i][1]); 
				b[0]=a[1]; 
				b[1]=b[1]+(double)(SamplePoint[i][1])*(double)(SamplePoint[i][1]); 
				c[0]=c[0]+(double)(SamplePoint[i][0])*(double)(ReferencePoint[i][0]); 
				c[1]=c[1]+(double)(SamplePoint[i][1])*(double)(ReferencePoint[i][0]); 
				d[0]=d[0]+(double)(SamplePoint[i][0])*(double)(ReferencePoint[i][1]); 
				d[1]=d[1]+(double)(SamplePoint[i][1])*(double)(ReferencePoint[i][1]); 
			} 
			a[0]=a[0]/a[2]; 
			a[1]=a[1]/b[2];  
			b[0]=b[0]/a[2]; 
			b[1]=b[1]/b[2];  
			c[0]=c[0]/a[2]; 
			c[1]=c[1]/b[2]; 
			d[0]=d[0]/a[2]; 
			d[1]=d[1]/b[2]; 
			a[2]=a[2]/Points; 
			b[2]=b[2]/Points; 
			c[2]=c[2]/Points; 
			d[2]=d[2]/Points; 
		} 
		k=(a[0]-a[2])*(b[1]-b[2])-(a[1]-a[2])*(b[0]-b[2]); 
		KX1=((c[0]-c[2])*(b[1]-b[2])-(c[1]-c[2])*(b[0]-b[2]))/k; 
		KX2=((c[1]-c[2])*(a[0]-a[2])-(c[0]-c[2])*(a[1]-a[2]))/k; 
		KX3=(b[0]*(a[2]*c[1]-a[1]*c[2])+b[1]*(a[0]*c[2]-a[2]*c[0])+b[2]*(a[1]*c[0]- a[0]*c[1]))/k; 
		KY1=((d[0]-d[2])*(b[1]-b[2])-(d[1]-d[2])*(b[0]-b[2]))/k; 
		KY2=((d[1]-d[2])*(a[0]-a[2])-(d[0]-d[2])*(a[1]-a[2]))/k; 
		KY3=(b[0]*(a[2]*d[1]-a[1]*d[2])+b[1]*(a[0]*d[2]-a[2]*d[0])+b[2]*(a[1]*d[0]- a[0]*d[1]))/k; 
		//return Points;   
		//
		if (orientation()==1) //portrait
		{
			KX1_1 = KX1;
			KX2_1 = KX2;
			KX3_1 = KX3;
			KY1_1 = KY1;
			KY2_1 = KY2;
			KY3_1 = KY3;	
		}
		else 	if (orientation()==3)
		{
			KX1_0 = KX1;
			KX2_0 = KX2;
			KX3_0 = KX3;
			KY1_0 = KY1;
			KY2_0 = KY2;
			KY3_0 = KY3;	
		}
	} 
}


void DoCalibrationLoop(int x,int y)
{

	//NSLog(@"**ciclos=%i Cal_State=%i",ciclos,Cal_State);
	if (Cal_State)
	{

		ciclos++;

		switch(Cal_State)
		{
			case 1:
				if (ciclos>(CICLESDOWN*5) )
				{
					ciclos=0;
					SamplePoint[0][0]       = x;	
					SamplePoint[0][1]       = y;	

					//COLOCAR CURSOR EN POSICION DOS
					ReferencePoint[1][0]    = screen_height * 0.1;
					ReferencePoint[1][1]    = screen_width  * 0.1;                                  
					mouseSendEvent((int)ReferencePoint[1][1] ,(int)ReferencePoint[1][0],0x00);   
					Cal_State++;

					NSLog(@"**PRIMER PUNTO OBTENIDO X=%i Y=%i",x,y);
				}

				break;
			case 2:
				if (ciclos>(CICLESDOWN*5))
				{
					ciclos=0;
					SamplePoint[1][0]       = x;	
					SamplePoint[1][1]       = y;	

					//COLOCAR CURSOR EN POSICION DOS
					ReferencePoint[2][0]    = screen_height * 0.9;
					ReferencePoint[2][1]    = screen_width  * 0.9;                                  
					mouseSendEvent((int)ReferencePoint[2][1] ,(int)ReferencePoint[2][0],0x00);   
					Cal_State++;

					NSLog(@"**SEGUNDO PUNTO OBTENIDO X=%i Y=%i",x,y);
				}                                      
				break;
			case 3:
				if (ciclos>(CICLESDOWN*5) )
				{
					ciclos=0;
					SamplePoint[2][0]       = x;	
					SamplePoint[2][1]       = y;	

					//COLOCAR CURSOR EN POSICION DOS
					ReferencePoint[3][0]    = screen_height * 0.9;
					ReferencePoint[3][1]    = screen_width  * 0.1;                                  
					mouseSendEvent((int)ReferencePoint[3][1] ,(int)ReferencePoint[3][0],0x00);   
					Cal_State++;

					NSLog(@"**TERCER PUNTO OBTENIDO X=%i Y=%i",x,y);
				}                                      
				break;      
			case 4:
				if (ciclos>(CICLESDOWN*5) )
				{
					ciclos=0;
					SamplePoint[3][0]       = x;	
					SamplePoint[3][1]       = y;	

					Cal_State++;
					mouseSendEvent((int)(screen_height * 0.5) ,(int)(screen_width * 0.5),0x00);  


					NSLog(@"**CUARTO PUNTO OBTENIDO X=%i Y=%i",x,y);

					Get_Calibration_Coefficient();
					NSUserDefaults *Cals = [NSUserDefaults standardUserDefaults];							
					if (orientation() == 1 )
					{
						// saving a float
						[Cals setFloat:KX1 forKey:@"KX1_1"];
						[Cals setFloat:KX2 forKey:@"KX2_1"];    
						[Cals setFloat:KX3 forKey:@"KX3_1"];    
						[Cals setFloat:KY1 forKey:@"KY1_1"];    
						[Cals setFloat:KY2 forKey:@"KY2_1"];    
						[Cals setFloat:KY3 forKey:@"KY3_1"];

						[Cals synchronize];

						KX1_1=KX1;
						KX2_1=KX2;																	
						KX3_1=KX3;								
						KY1_1=KY1;
						KY2_1=KY2;								
						KY3_1=KY3;							

						NSLog(@"************************CALIBRATIONS SAVED orientation 1");					

					}
					else if (orientation() == 3 )
					{
						// saving a float
						[Cals setFloat:KX1 forKey:@"KX1_0"];
						[Cals setFloat:KX2 forKey:@"KX2_0"];    
						[Cals setFloat:KX3 forKey:@"KX3_0"];    
						[Cals setFloat:KY1 forKey:@"KY1_0"];    
						[Cals setFloat:KY2 forKey:@"KY2_0"];    
						[Cals setFloat:KY3 forKey:@"KY3_0"];

						[Cals synchronize];

						KX1_0=KX1;
						KX2_0=KX2;																	
						KX3_0=KX3;								
						KY1_0=KY1;
						KY2_0=KY2;								
						KY3_0=KY3;								

						NSLog(@"************************CALIBRATIONS SAVED orientation 3");										

					}
					NSLog(@"*********************************Calibracion  KX1=%f, KX2=%f, KX3=%f, KY1=%f, KY2=%f, KY3=%f",KX1,KX2,KX3,KY1,KY2,KY3); 
				}                                      
				break;   
			case 5:
				if (ciclos>(CICLESDOWN*2) )
				{
					Cal_State=0;
					//[GpsThread showHideCursor:tempCursorShow];
				}

				break;
			default:
				break;
		}


	}






	//CALIBRACION-----------------------------------------------------------------
}


void BeginCalibration()
{
	Cal_State=1;
	//COLOCAR CURSOR EN POSICION UNO
	ReferencePoint[0][0]    = screen_height * 0.1;
	ReferencePoint[0][1]    = screen_width  * 0.9;                                  
	mouseSendEvent((int)ReferencePoint[0][1] ,(int)ReferencePoint[0][0],0x00);

}
int Get_Cal_State()
{
	return Cal_State;
}
int GetX_Calibrate()
{
	return Px;

}
int GetY_Calibrate()
{
	return Py;

}
