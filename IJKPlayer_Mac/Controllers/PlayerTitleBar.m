//
//  PlayerTitleBar.m
//  IJKPlayer_Mac
//
//  Created by mini on 2017/9/7.
//  Copyright © 2017年 mini. All rights reserved.
//

#import "PlayerTitleBar.h"
#import "CrossAssistTool.h"
#import "MouseButton.h"
#import "AppDelegate.h"

@interface PlayerTitleBar ()

@property (weak) IBOutlet NSTextField *titLabel;


@end

@implementation PlayerTitleBar

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    // 创建一个定时器，每隔 3 秒执行一次 timerFired 方法
    self.timer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];

    
    [self createUI];
    
}


- (void)timerFired:(NSTimer *)timer {
    // 这里放置你想要定时执行的代码
    NSLog(@"Timer fired!");
    self.titLabel.stringValue = [self setTitle];
}

- (void)dealloc {
    // 在视图控制器销毁时，要记得停止定时器
    [self.timer invalidate];
    self.timer = nil;
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

//
//- (void)dealloc{
//
//    [[NSNotificationCenter defaultCenter]removeObserver:self];
//}

- (void)createUI{
    
    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = [NSColor colorWithWhite:0.f alpha:0.75].CGColor;
    
    @weakify(self);

    [[NSNotificationCenter defaultCenter]addObserverForName:MediaPlayerBegin object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        @strongify(self);if(!self)return;
        if(note.userInfo){
            NSString *filename = note.userInfo[MediaPlayerFilenameKey];
            if(filename){
                self.titLabel.stringValue = filename ;
            }
        }
    }];
    
    [[NSNotificationCenter defaultCenter]addObserverForName:MediaPlayerEnd object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        @strongify(self);if(!self)return;
        self.view.hidden = YES;
    }];
    
}

- (void)showBar{
    
    //if(self.view.hidden == NO)return;
    
    self.view.hidden = NO;
    [self.view.superview addSubview:self.view positioned:NSWindowAbove relativeTo:self.view.superview.subviews.lastObject];
}

- (void)hideBar{
    
    //if(self.view.hidden == YES)return;
    self.view.hidden = YES;
}

#pragma mark --- action

- (IBAction)closeWindowClick:(MouseButton *)sender {
    if(self.closeWindowBlock){
        self.closeWindowBlock();
    }
}
- (IBAction)minWindowClick:(MouseButton *)sender {
    if(self.minWindowBlock){
        self.minWindowBlock();
    }
}
- (IBAction)zoomWindowClick:(MouseButton *)sender {
    if(self.zoomWindowBlock){
        self.zoomWindowBlock();
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [sender setCurrntStat:MouseStatExited];
    });
}

- (NSString *)setTitle{
    AppDelegate *myDelegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];
    return [NSString stringWithFormat:@"%@:%@ %@:%@ %@:%@ %@:%@ %@:%@ %@:%@",
    @"Width",[NSNumber numberWithFloat:myDelegate.screenWidth].stringValue ,
    @"Height",[NSNumber numberWithFloat:myDelegate.screenHeight].stringValue ,
    @"SBS",[NSNumber numberWithFloat:myDelegate.diff_x].stringValue ,
    @"Slope",[NSNumber numberWithFloat:myDelegate.rate].stringValue ,
    @"MaskW",[NSNumber numberWithFloat:myDelegate.lenswidth].stringValue,
    @"Eye",[NSNumber numberWithFloat:myDelegate.rate_y].stringValue
    ];
}

@end
