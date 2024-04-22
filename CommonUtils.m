//
//  CommonUtils.m
//  infinityRadio
//
//  Created by lijiaxi on 7/28/23.
//

#import <Foundation/Foundation.h>

// CommonUtils.m

#import "CommonUtils.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@implementation CommonUtils

#pragma mark - resizeImage Methods
- (UIImage *)resizeImage:(UIImage *)image toMaxSize:(CGFloat)maxSize {
    CGSize originalSize = image.size;
    CGFloat aspectRatio = originalSize.width / originalSize.height;
    CGFloat newWidth, newHeight;
    
    if (aspectRatio > 1) {
        newWidth = maxSize;
        newHeight = maxSize / aspectRatio;
    } else {
        newWidth = maxSize * aspectRatio;
        newHeight = maxSize;
    }
    
    // 开启图形上下文
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(newWidth, newHeight), NO, 0.0);
    
    // 将图片绘制到指定的大小上
    [image drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
    
    // 获取重绘后的图片
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // 关闭图形上下文
    UIGraphicsEndImageContext();
    
    return resizedImage;
}



+ (instancetype)sharedInstance {
    static CommonUtils *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CommonUtils alloc] init];
    });
    return sharedInstance;
}
@end


