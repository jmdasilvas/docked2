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


#pragma once

#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import "objc/runtime.h"
#include <dlfcn.h>
#include "mouse_msgs.h"

#define CICLESDOWN  10
#define			N 	4 // number of reference points for calibration 


#ifdef __cplusplus
extern "C" {
#endif 

 	

int orientation();
void InitCoeficients();
void Do_Calibration(int x,int y); // do calibration for point 
void DoCalibrationLoop(int x,int y);
void Get_Calibration_Coefficient();  // calculate the coefficients for calibration
void BeginCalibration();
int Get_Cal_State();
int GetX_Calibrate();
int GetY_Calibrate();


#ifdef __cplusplus
}
#endif 