//
//  voiceTableViewCell.m
//  infinityRadio
//
//  Created by lijiaxi on 7/22/23.
//

#import <Foundation/Foundation.h>
#import "voiceTableViewCell.h"
#import "ViewController.h"

@implementation voiceTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // 初始化UIImageView
        self.iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(16, 8, 32, 32)];
        UIImage *iconImage = [UIImage imageNamed:@"icon.png"];
        self.iconImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.iconImageView.image = iconImage;

        [self.contentView addSubview:self.iconImageView];

        self.myImageView = [[UIImageView alloc] initWithFrame:CGRectMake(48, 28, 200, 160)];
        UIImage *image = [UIImage imageNamed:@"audio.png"]; // 使用图像名称加载图像
        self.myImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.myImageView.image = image;
        [self.contentView addSubview:self.myImageView];
        
        self.myButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        // 设置按钮的位置和大小
        self.myButton.frame = CGRectMake(280, 48, 50, 50);
        [self.myButton setTitle:@"Play" forState:UIControlStateNormal];
        [self.myButton addTarget:self action:@selector(sendButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.myButton];
    }
    return self;
}


- (void)setLabelText:(NSString *)text {
    self.myLabel.text = text;
}

- (void)setImage:(UIImage *)image {
    self.myImageView.image = image;
}

- (void)setButtonTitle:(NSString *)title {
    [self.myButton setTitle:title forState:UIControlStateNormal];
//    [self.myButton addTarget:self action:@selector(myButtonTapped) forControlEvents:UIControlEventTouchUpInside];
}

- (void)sendButtonTapped{
    // ... existing button tap handler code ...
    NSURL *videoUrl = [NSURL URLWithString:self.textLabel.text];
    [self playvoice:videoUrl];
}

#pragma mark - playvoice
- (void)playvoice:(NSURL *) fileURL{
    
    NSError *error = nil;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
    if (self.audioPlayer) {
        // Set up audio session (if needed)
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        // Prepare the audio player for playback
        if ([self.audioPlayer prepareToPlay])
        {
            // Start playing the audio
            NSLog(@"Playing");
            [self.audioPlayer play];
            
        } else {
            NSLog(@"Failed to prepare AVAudioPlayer for playback.");
        }
    }
    else
    {
        NSLog(@"Failed to initialize AVAudioPlayer: %@", error);
    }
}

@end

