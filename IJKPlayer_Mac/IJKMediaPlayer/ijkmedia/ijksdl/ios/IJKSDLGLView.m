/*
 * IJKSDLGLView.m
 *
 * Copyright (c) 2013 Bilibili
 * Copyright (c) 2013 Zhang Rui <bbcallen@gmail.com>
 *
 * based on https://github.com/kolyvan/kxmovie
 *
 * This file is part of ijkPlayer.
 *
 * ijkPlayer is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * ijkPlayer is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with ijkPlayer; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

#import "IJKSDLGLView.h"
#include "ijksdl/ijksdl_timer.h"
#include "ijksdl/ios/ijksdl_ios.h"
#include "ijksdl/ijksdl_gles2.h"
#include <OpenGL/gl3.h>
#include <OpenGL/glu.h>
#include <OpenGL/OpenGL.h>

#import "AppDelegate.h"


typedef NS_ENUM(NSInteger, IJKSDLGLViewApplicationState) {
    IJKSDLGLViewApplicationUnknownState = 0,
    IJKSDLGLViewApplicationForegroundState = 1,
    IJKSDLGLViewApplicationBackgroundState = 2
};

// attribute index for normal vertex program
enum
{
    ATTRIB_VERTEX,
    ATTRIB_COLOR
};

// attribute index for texture program
enum
{
    ATTRIB_TEXVERTEX,
    ATTRIB_TEXCOORD
};

@interface IJKSDLGLView()
@property(atomic,strong) NSRecursiveLock *glActiveLock;
@property(atomic) BOOL glActivePaused;
@end

@implementation IJKSDLGLView {
    NSOpenGLContext *_context;

    GLint           _backingWidth;
    GLint           _backingHeight;

    int             _frameCount;
    
    int64_t         _lastFrameTime;

    IJK_GLES2_Renderer *_renderer;
    int                 _rendererGravity;

    BOOL            _isRenderBufferInvalidated;

    int             _tryLockErrorCount;
    BOOL            _didSetupGL;
    BOOL            _didStopGL;
    BOOL            _didLockedDueToMovedToWindow;
    BOOL            _shouldLockWhileBeingMovedToWindow;
    NSMutableArray *_registeredNotifications;

    IJKSDLGLViewApplicationState _applicationState;
}

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _tryLockErrorCount = 0;
        _shouldLockWhileBeingMovedToWindow = YES;
        self.glActiveLock = [[NSRecursiveLock alloc] init];
        _registeredNotifications = [[NSMutableArray alloc] init];
        [self registerApplicationObservers];

        _didSetupGL = NO;
        [self setupGLOnce];

    }

    return self;
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow{
    
    if (!_shouldLockWhileBeingMovedToWindow) {
        [super viewWillMoveToWindow:newWindow];
        return;
    }
    if (newWindow && !_didLockedDueToMovedToWindow) {
        [self lockGLActive];
        _didLockedDueToMovedToWindow = YES;
    }
    [super viewWillMoveToWindow:newWindow];
}

//- (void)willMoveToWindow:(UIWindow *)newWindow
//{
//    if (!_shouldLockWhileBeingMovedToWindow) {
//        [super willMoveToWindow:newWindow];
//        return;
//    }
//    if (newWindow && !_didLockedDueToMovedToWindow) {
//        [self lockGLActive];
//        _didLockedDueToMovedToWindow = YES;
//    }
//    [super willMoveToWindow:newWindow];
//}

- (void)viewDidMoveToWindow{
    
    [super viewDidMoveToWindow];
    if (self.window && _didLockedDueToMovedToWindow) {
        [self unlockGLActive];
        _didLockedDueToMovedToWindow = NO;
    }
}

//- (void)didMoveToWindow
//{
//    [super didMoveToWindow];
//    if (self.window && _didLockedDueToMovedToWindow) {
//        [self unlockGLActive];
//        _didLockedDueToMovedToWindow = NO;
//    }
//}




- (BOOL)setupEAGLContext:(NSOpenGLContext *)context
{
    GLint swapInt = 1;
    [_context setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
    

    return YES;
}

- (BOOL)setupGL
{
    if (_didSetupGL)
        return YES;

//    if ([self isApplicationActive] == NO)
//        return NO;
    
    NSOpenGLPixelFormatAttribute attrs[] =
    {
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAOpenGLProfile,
        NSOpenGLProfileVersion4_1Core,
        
        NSOpenGLPFAMultisample,
        NSOpenGLPFASampleBuffers,NSOpenGLPFAAllRenderers,
        NSOpenGLPFASamples,(NSOpenGLPixelFormatAttribute)4,
        0
    };
    
    NSOpenGLPixelFormat *pf = [[NSOpenGLPixelFormat alloc]initWithAttributes:attrs];
    if(!pf){
        NSLog(@"No OpenGL pixel format");
        return NO;
    }
    
    
    NSOpenGLContext *context = [[NSOpenGLContext alloc]initWithFormat:pf shareContext:nil];
    if(!context){
        NSLog(@"No OpenGL context");
        return NO;
    }
    
    [self setPixelFormat:pf];
    [self setOpenGLContext:context];


    _scaleFactor = [[NSScreen mainScreen] backingScaleFactor];
    if (_scaleFactor < 0.1f)
        _scaleFactor = 1.0f;

    
    _context = [self openGLContext];
    if (_context == nil) {
        NSLog(@"failed to setup openGLContext\n");
        return NO;
    }

    NSOpenGLContext *prevContext = [NSOpenGLContext currentContext];
    [_context makeCurrentContext];
    
    _didSetupGL = NO;
    if ([self setupEAGLContext:_context]) {
        NSLog(@"OK setup GL\n");
        _didSetupGL = YES;
    }

    [prevContext makeCurrentContext];
    
    return _didSetupGL;
}

- (BOOL)setupGLOnce
{
    if (_didSetupGL)
        return YES;

    if ([self isApplicationActive] == NO)
        return NO;

    if (![self tryLockGLActive])
        return NO;

    BOOL didSetupGL = [self setupGL];
    [self unlockGLActive];
    return didSetupGL;
}

- (BOOL)isApplicationActive
{
    return YES;
//    switch (_applicationState) {
//        case IJKSDLGLViewApplicationForegroundState:
//            return YES;
//        case IJKSDLGLViewApplicationBackgroundState:
//            return NO;
//        default: {
//            UIApplicationState appState = [UIApplication sharedApplication].applicationState;
//            switch (appState) {
//                case UIApplicationStateActive:
//                    return YES;
//                case UIApplicationStateInactive:
//                case UIApplicationStateBackground:
//                default:
//                    return NO;
//            }
//        }
//    }
}

- (void)dealloc
{
    [self lockGLActive];

    _didStopGL = YES;

    NSOpenGLContext *prevContext = [NSOpenGLContext currentContext];
    [_context makeCurrentContext];
    
    IJK_GLES2_Renderer_reset(_renderer);
    IJK_GLES2_Renderer_freeP(&_renderer);

    
    glBindVertexArray(0);                   // Detach any vertex array object
    glBindBuffer(GL_ARRAY_BUFFER, 0);       // Detach any buffer object
    
    

    
    [self clearGLContext];
    
    
    glFinish();

    [prevContext makeCurrentContext];

    
    
    
    _context = nil;

    [self unregisterApplicationObservers];

    [self unlockGLActive];
}



- (void)setScaleFactor:(CGFloat)scaleFactor
{
    _scaleFactor = scaleFactor;
    [self invalidateRenderBuffer];
 
}

- (void)viewWillDraw{
    
    [super viewWillDraw];
    CGRect selfFrame = self.frame;
    CGRect newFrame  = selfFrame;
    
    newFrame.size.width   = selfFrame.size.width * 1 / 3;
    newFrame.origin.x     = selfFrame.size.width * 2 / 3;
    
    newFrame.size.height  = selfFrame.size.height * 8 / 8;
    newFrame.origin.y    += selfFrame.size.height * 0 / 8;
    
    [self invalidateRenderBuffer];
}

- (void)setLayerContentsPlacement:(NSViewLayerContentsPlacement)layerContentsPlacement{
    
    [super setLayerContentsPlacement:layerContentsPlacement];
    
    switch (layerContentsPlacement) {
//        case NSViewLayerContentsPlacementScaleProportionallyToFill:
//            _rendererGravity = IJK_GLES2_GRAVITY_RESIZE;
//            break;
        case NSViewLayerContentsPlacementScaleProportionallyToFit:
            _rendererGravity = IJK_GLES2_GRAVITY_RESIZE_ASPECT;
            break;
        case NSViewLayerContentsPlacementScaleProportionallyToFill:
            _rendererGravity = IJK_GLES2_GRAVITY_RESIZE_ASPECT_FILL;
            break;
        default:
            _rendererGravity = IJK_GLES2_GRAVITY_RESIZE_ASPECT;
            break;
    }
    [self invalidateRenderBuffer];
}

- (BOOL)setupRenderer: (SDL_VoutOverlay *) overlay
{
    if (overlay == nil)
        return _renderer != nil;

    if (!IJK_GLES2_Renderer_isValid(_renderer) ||
        !IJK_GLES2_Renderer_isFormat(_renderer, overlay->format)) {
        IJK_GLES2_Renderer_reset(_renderer);
        IJK_GLES2_Renderer_freeP(&_renderer);
        overlay->usr_data = (__bridge void *)(_context);
        _renderer = IJK_GLES2_Renderer_create(overlay);
        
        if (!IJK_GLES2_Renderer_isValid(_renderer))
            return NO;

        if (!IJK_GLES2_Renderer_use(_renderer))
            return NO;
        
        IJK_GLES2_Renderer_setGravity(_renderer, _rendererGravity, _backingWidth, _backingHeight);
        
    }

    return YES;
}

- (void)invalidateRenderBuffer
{
    NSLog(@"invalidateRenderBuffer\n");
    [self lockGLActive];

    _isRenderBufferInvalidated = YES;

    if ([[NSThread currentThread] isMainThread]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            if (_isRenderBufferInvalidated)
                [self display:nil];
        });
    } else {
        [self display:nil];
    }

    [self unlockGLActive];
}

- (void)display: (SDL_VoutOverlay *) overlay
{
    if (![self setupGLOnce])
        return;

    if (![self tryLockGLActive]) {
        if (0 == (_tryLockErrorCount % 100)) {
            NSLog(@"IJKSDLGLView:display: unable to tryLock GL active: %d\n", _tryLockErrorCount);
        }
        _tryLockErrorCount++;
        return;
    }

    _tryLockErrorCount = 0;
    if (_context && !_didStopGL) {
        NSOpenGLContext *prevContext = [NSOpenGLContext currentContext];
        [_context makeCurrentContext];
        [self displayInternal:overlay];
        [prevContext makeCurrentContext];
    }

    [self unlockGLActive];
}

// NOTE: overlay could be NULl
- (void)displayInternal: (SDL_VoutOverlay *) overlay
{

    if (![self setupRenderer:overlay]) {
        if (!overlay && !_renderer) {
            NSLog(@"IJKSDLGLView: setupDisplay not ready\n");
        } else {
            NSLog(@"IJKSDLGLView: setupDisplay failed\n");
        }
        return;
    }

  //  [self.layer setContentsScale:_scaleFactor];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // 在主线程中执行 UI 操作
        _backingWidth = self.frame.size.width * _scaleFactor;
        _backingHeight = self.frame.size.height * _scaleFactor;

    });

//    _backingWidth = self.frame.size.width * _scaleFactor;
//    _backingHeight = self.frame.size.height * _scaleFactor;
    
    if (_isRenderBufferInvalidated) {
        NSLog(@"IJKSDLGLView: renderbufferStorage fromDrawable\n");
        _isRenderBufferInvalidated = NO;
        IJK_GLES2_Renderer_setGravity(_renderer, _rendererGravity, _backingWidth, _backingHeight);
    }
    glViewport(0, 0, _backingWidth, _backingHeight);
    glClearColor(0.f, 0.f, 0.f, 1.f);
    IJK_GLES2_Renderer_bind_vao(_renderer);
    
    //add xuan Aug 14 2023 set the value to overlay
    //from myDelegate as soon as value are changed
    //shader for render will change thru the uniform var in shader file
    //which name is yuv420sp
    //see renderer.m also
    dispatch_async(dispatch_get_main_queue(), ^{
        // Access the UIApplication delegate here
        AppDelegate *myDelegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];
        // Do something with the appDelegate
        overlay->mobile_res = myDelegate.mobile_res;
        overlay->screenWidth =myDelegate.screenWidth;
        overlay->screenHeight =myDelegate.screenHeight;
        
        overlay->diff_x = myDelegate.diff_x;
        overlay->lenswidth = myDelegate.lenswidth;
        overlay->rate_y = myDelegate.rate_y;
        overlay->xtimes = myDelegate.xtimes;
        overlay->ytimes = myDelegate.ytimes;
        overlay->rate   = myDelegate.rate;
        overlay->_test  = myDelegate._test;
        overlay->brightness = myDelegate.brightness;
        overlay->contrast = myDelegate.contrast;
        overlay->saturation = myDelegate.saturation;
    });
    
    

    if (!IJK_GLES2_Renderer_renderOverlay(_renderer, overlay))
        ALOGE("[EGL] IJK_GLES2_render failed\n");

    CGLFlushDrawable([_context CGLContextObj]);

    int64_t current = (int64_t)SDL_GetTickHR();
    int64_t delta   = (current > _lastFrameTime) ? current - _lastFrameTime : 0;
    if (delta <= 0) {
        _lastFrameTime = current;
    } else if (delta >= 1000) {
        _fps = ((CGFloat)_frameCount) * 1000 / delta;
        _frameCount = 0;
        _lastFrameTime = current;
    } else {
        _frameCount++;
    }
}

#pragma mark AppDelegate

- (void) lockGLActive
{
    [self.glActiveLock lock];
}

- (void) unlockGLActive
{
    [self.glActiveLock unlock];
}

- (BOOL) tryLockGLActive
{
    if (![self.glActiveLock tryLock])
        return NO;

    /*-
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive &&
        [UIApplication sharedApplication].applicationState != UIApplicationStateInactive) {
        [self.appLock unlock];
        return NO;
    }
     */

    if (self.glActivePaused) {
        [self.glActiveLock unlock];
        return NO;
    }
    
    return YES;
}

- (void)toggleGLPaused:(BOOL)paused
{
    [self lockGLActive];
    if (!self.glActivePaused && paused) {
        if (_context != nil) {
            NSOpenGLContext *prevContext = [NSOpenGLContext currentContext];
            [_context makeCurrentContext];
            glFinish();
            [prevContext makeCurrentContext];
        }
    }
    self.glActivePaused = paused;
    [self unlockGLActive];
}

- (void)registerApplicationObservers
{

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground)
                                                 name:NSApplicationWillBecomeActiveNotification
                                               object:nil];
    [_registeredNotifications addObject:NSApplicationWillBecomeActiveNotification];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive)
                                                 name:NSApplicationDidBecomeActiveNotification
                                               object:nil];
    [_registeredNotifications addObject:NSApplicationDidBecomeActiveNotification];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive)
                                                 name:NSApplicationWillResignActiveNotification
                                               object:nil];
    [_registeredNotifications addObject:NSApplicationWillResignActiveNotification];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground)
                                                 name:NSApplicationDidFinishLaunchingNotification
                                               object:nil];
    [_registeredNotifications addObject:NSApplicationDidFinishLaunchingNotification];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillTerminate)
                                                 name:NSApplicationWillTerminateNotification
                                               object:nil];
    [_registeredNotifications addObject:NSApplicationWillTerminateNotification];
}

- (void)unregisterApplicationObservers
{
    for (NSString *name in _registeredNotifications) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:name
                                                      object:nil];
    }
}

- (void)applicationWillEnterForeground
{
   // NSLog(@"IJKSDLGLView:applicationWillEnterForeground: %d", (int)[UIApplication sharedApplication].applicationState);
    _applicationState = IJKSDLGLViewApplicationForegroundState;
    //[self toggleGLPaused:NO];
}

- (void)applicationDidBecomeActive
{
   // NSLog(@"IJKSDLGLView:applicationDidBecomeActive: %d", (int)[UIApplication sharedApplication].applicationState);
    //[self toggleGLPaused:NO];
}

- (void)applicationWillResignActive
{
    //NSLog(@"IJKSDLGLView:applicationWillResignActive: %d", (int)[UIApplication sharedApplication].applicationState);
    //[self toggleGLPaused:YES];
}

- (void)applicationDidEnterBackground
{
    //NSLog(@"IJKSDLGLView:applicationDidEnterBackground: %d", (int)[UIApplication sharedApplication].applicationState);
    _applicationState = IJKSDLGLViewApplicationBackgroundState;
   // [self toggleGLPaused:YES];
}

- (void)applicationWillTerminate
{
    //NSLog(@"IJKSDLGLView:applicationWillTerminate: %d", (int)[UIApplication sharedApplication].applicationState);
    [self toggleGLPaused:YES];
}

#pragma mark snapshot

- (NSImage*)snapshot
{
    [self lockGLActive];

//    UIImage *image = [self snapshotInternal];

    [self unlockGLActive];

    return nil;//image;
}

- (NSImage*)snapshotInternal
{
//    if (isIOS7OrLater()) {
//        return [self snapshotInternalOnIOS7AndLater];
//    } else {
//        return [self snapshotInternalOnIOS6AndBefore];
//    }
    return nil;
}

//- (NSImage*)snapshotInternalOnIOS7AndLater
//{
//    if (CGSizeEqualToSize(self.bounds.size, CGSizeZero)) {
//        return nil;
//    }
//    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0);
//    // Render our snapshot into the image context
//    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:NO];
//
//    // Grab the image from the context
//    UIImage *complexViewImage = UIGraphicsGetImageFromCurrentImageContext();
//    // Finish using the context
//    UIGraphicsEndImageContext();
//
//    return complexViewImage;
//}

//- (UIImage*)snapshotInternalOnIOS6AndBefore
//{
//    EAGLContext *prevContext = [EAGLContext currentContext];
//    [EAGLContext setCurrentContext:_context];
//
//    GLint backingWidth, backingHeight;
//
//    // Bind the color renderbuffer used to render the OpenGL ES view
//    // If your application only creates a single color renderbuffer which is already bound at this point,
//    // this call is redundant, but it is needed if you're dealing with multiple renderbuffers.
//    // Note, replace "viewRenderbuffer" with the actual name of the renderbuffer object defined in your class.
//    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
//
//    // Get the size of the backing CAEAGLLayer
//    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
//    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
//
//    NSInteger x = 0, y = 0, width = backingWidth, height = backingHeight;
//    NSInteger dataLength = width * height * 4;
//    GLubyte *data = (GLubyte*)malloc(dataLength * sizeof(GLubyte));
//
//    // Read pixel data from the framebuffer
//    glPixelStorei(GL_PACK_ALIGNMENT, 4);
//    glReadPixels((int)x, (int)y, (int)width, (int)height, GL_RGBA, GL_UNSIGNED_BYTE, data);
//
//    // Create a CGImage with the pixel data
//    // If your OpenGL ES content is opaque, use kCGImageAlphaNoneSkipLast to ignore the alpha channel
//    // otherwise, use kCGImageAlphaPremultipliedLast
//    CGDataProviderRef ref = CGDataProviderCreateWithData(NULL, data, dataLength, NULL);
//    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
//    CGImageRef iref = CGImageCreate(width, height, 8, 32, width * 4, colorspace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast,
//                                    ref, NULL, true, kCGRenderingIntentDefault);
//
//    [EAGLContext setCurrentContext:prevContext];
//
//    // OpenGL ES measures data in PIXELS
//    // Create a graphics context with the target size measured in POINTS
//    UIGraphicsBeginImageContext(CGSizeMake(width, height));
//
//    CGContextRef cgcontext = UIGraphicsGetCurrentContext();
//    // UIKit coordinate system is upside down to GL/Quartz coordinate system
//    // Flip the CGImage by rendering it to the flipped bitmap context
//    // The size of the destination area is measured in POINTS
//    CGContextSetBlendMode(cgcontext, kCGBlendModeCopy);
//    CGContextDrawImage(cgcontext, CGRectMake(0.0, 0.0, width, height), iref);
//
//    // Retrieve the UIImage from the current context
//    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//
//    // Clean up
//    free(data);
//    CFRelease(ref);
//    CFRelease(colorspace);
//    CGImageRelease(iref);
//
//    return image;
//}

#pragma mark IJKFFHudController
- (void)setHudValue:(NSString *)value forKey:(NSString *)key
{
//    if ([[NSThread currentThread] isMainThread]) {
//        [_hudViewController setHudValue:value forKey:key];
//    } else {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self setHudValue:value forKey:key];
//        });
//    }
}

- (void)setShouldLockWhileBeingMovedToWindow:(BOOL)shouldLockWhileBeingMovedToWindow
{
    _shouldLockWhileBeingMovedToWindow = shouldLockWhileBeingMovedToWindow;
}

- (void)setShouldShowHudView:(BOOL)shouldShowHudView
{
   // _hudViewController.tableView.hidden = !shouldShowHudView;
}

- (BOOL)shouldShowHudView
{
    return NO;// !_hudViewController.tableView.hidden;
}

@end
