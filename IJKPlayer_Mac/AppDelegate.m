//
//  AppDelegate.m
//  IJKPlayer_Mac
//
//  Created by mini on 2017/6/2.
//  Copyright © 2017年 mini. All rights reserved.
//

#import "AppDelegate.h"
#import "EventSendManager.h"
@interface AppDelegate ()
@property (nonatomic,weak)EventSendManager *menuManager;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    
    NSScreen *mainScreen = [NSScreen mainScreen];
    NSSize pixelSize = mainScreen.frame.size;

    CGFloat screenWidthPixels = pixelSize.width;
    CGFloat screenHeightPixels = pixelSize.height;

    self.mobile_res = screenWidthPixels;
    self.screenWidth = screenWidthPixels;
    self.screenHeight = screenHeightPixels;
    self.xtimes = 0.5;
    self.ytimes = 1.0;
    self.diff_x = 0.01;
    self.diff_y = 0.0;
    self.lenswidth = 0.01;
    self.rate_y = 0.0;
    self.rate   = 0.56;
    self._test = 1;
    self.brightness = 0.1;
    self.contrast = 1.0;
    self.saturation=1.0;
    
    self.menuManager = [EventSendManager shareManager];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}
- (IBAction)openFileClick:(NSMenuItem *)sender {
    if(self.menuManager.openFileBlock){
        self.menuManager.openFileBlock(sender);
    }
}
- (IBAction)openNetworkClick:(NSMenuItem *)sender {
    if(self.menuManager.openNetworkBlock){
        self.menuManager.openNetworkBlock(sender);
    }
}


@end
