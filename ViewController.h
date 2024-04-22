//
//  ViewController.h
//  infinityRadio
//
//  Created by lijiaxi on 7/9/23.
//

#import <UIKit/UIKit.h>
@interface ViewController : UIViewController <UITableViewDataSource ,UITableViewDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) UITextField *textMsg;

@property (nonatomic, strong) UITextField *textFieldSendMax;
@property (nonatomic, strong) UITextField *textFieldsReceiveMax;
@property (nonatomic, strong) UITextField *textFieldInternal;


@property (nonatomic, strong) UIButton *showlogsButton;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) UIButton *exitButton;
@property (nonatomic, strong) UIButton *saveConfigButton;


@property (nonatomic, strong) UIButton *openAlbumButton;
@property (nonatomic, strong) UIButton *openVoiceButton;
@property (nonatomic, strong) UISearchBar *searchBar;

@end
