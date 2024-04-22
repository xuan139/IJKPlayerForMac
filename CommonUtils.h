//
//  CommonUtils.h
//  infinityRadio
//
//  Created by lijiaxi on 7/28/23.
//

#ifndef CommonUtils_h
#define CommonUtils_h


#endif /* CommonUtils_h */

// CommonUtils.h

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>



@interface CommonUtils : NSObject

+ (instancetype)sharedInstance;
- (UIImage *)resizeImage:(UIImage *)image toMaxSize:(CGFloat)maxSize;


@end

