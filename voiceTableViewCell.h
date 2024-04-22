//
//  voiceTableViewCell.h
//  infinityRadio
//
//  Created by lijiaxi on 7/22/23.
//

#ifndef voiceTableViewCell_h
#define voiceTableViewCell_h


#endif /* voiceTableViewCell_h */
//#import <UIKit/UIKit.h>
//
//@interface voiceTableViewCell : UITableViewCell
//
//@property (nonatomic, strong) UILabel *myLabel;
//@property (nonatomic, strong) UIImageView *myImageView;
//@property (nonatomic, strong) UIButton *myButton; // Add this line
//
//@end

// voiceTableViewCell.h
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>


@interface voiceTableViewCell : UITableViewCell

@property (nonatomic, strong) UILabel *myLabel;
@property (nonatomic, strong) UIImageView *myImageView;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UIButton *myButton;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

// Custom setter methods
- (void)setLabelText:(NSString *)text;
- (void)setImage:(UIImage *)image;
- (void)setButtonTitle:(NSString *)title;


@end

