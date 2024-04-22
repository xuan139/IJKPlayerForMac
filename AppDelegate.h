//
//  AppDelegate.h
//  infinityRadio
//
//  Created by lijiaxi on 7/9/23.
//

#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>


//@interface AppDelegate : UIResponder <UIApplicationDelegate>

@interface AppDelegate : UIResponder <UIApplicationDelegate, UNUserNotificationCenterDelegate>
@property (strong, nonatomic) UIWindow *window;


@end

