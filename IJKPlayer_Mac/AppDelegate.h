//
//  AppDelegate.h
//  IJKPlayer_Mac
//
//  Created by mini on 2017/6/2.
//  Copyright © 2017年 mini. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, assign) float mobile_res;
@property (nonatomic, assign) float screenWidth;
@property (nonatomic, assign) float screenHeight;
@property (nonatomic, assign) float diff_x;
@property (nonatomic, assign) float diff_y;
@property (nonatomic, assign) float lenswidth;
@property (nonatomic, assign) float rate_y;
@property (nonatomic, assign) float xtimes;     //x坐标
@property (nonatomic, assign) float ytimes;     //y坐标
@property (nonatomic, assign) float rate;
@property (nonatomic, assign) int _test;
@property (nonatomic, assign) float brightness;
@property (nonatomic, assign) float contrast;
@property (nonatomic, assign) float saturation;

@end

