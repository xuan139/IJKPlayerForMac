//
//  ViewController.m
//  digiradio
//
//  Created by lijiaxi on 7/9/23.
//

#import "ViewController.h"
#import "MyTableViewCell.h"
#import "voiceTableViewCell.h"
#import <AVFoundation/AVFoundation.h>
#import <CFNetwork/CFNetwork.h>
#import <CoreFoundation/CoreFoundation.h>
#import <UIKit/UIKit.h>
#import  <netinet/in.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <ifaddrs.h>

#import "CommonUtils.h"

@interface ViewController ()<NSStreamDelegate,AVAudioRecorderDelegate,UISearchBarDelegate,UITextFieldDelegate>
@property (strong, nonatomic) UILabel *msgLabel;
@property (nonatomic, strong) NSURL *outputFileURL;
@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, assign) CFSocketRef socket;
@property (nonatomic, strong) AVAudioRecorder *audioRecorder;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *listItems;

@property (nonatomic, strong) NSMutableArray *messages; // Array to store Message objects
@property (nonatomic, strong) CommonUtils * utils;

@end

static NSMutableData *totalData = nil;
static uint32_t sentLength = 0;
static uint8_t flag = 0x00;
//
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initialView];
    [self setupServerSocket];
    // 初始化全局变量
    [self initialGlobalVariable];
    
    
    // 注册键盘弹出和收起的通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

#pragma mark - keyborad show/hide/dismiss
- (void)keyboardWillShow:(NSNotification *)notification {
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardFrame = [self.view convertRect:keyboardFrame fromView:nil];
    
    // 计算需要上移的距离
    CGFloat moveDistance = CGRectGetMaxY(self.textMsg.frame) - CGRectGetMinY(keyboardFrame);
    
    // 移动视图
    [UIView animateWithDuration:0.3 animations:^{
        self.view.transform = CGAffineTransformMakeTranslation(0, -moveDistance);
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    // 恢复原始位置
    [UIView animateWithDuration:0.3 animations:^{
        self.view.transform = CGAffineTransformIdentity;
    }];
}
// Method to dismiss the keyboard
- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

#pragma mark - initialGlobalVariable
- (void)initialGlobalVariable{
    if (!totalData) {
        totalData = [NSMutableData data];
    }
    sentLength = 0;
    flag = 0x00;
}

- (void)resetGlobalVariable{
    [totalData setLength:0] ;
    sentLength = 0;
    flag = 0x00;
}

#pragma mark - initialButtons
- (void)enableButtons{
    [self.sendButton setEnabled:YES];
    [self.openAlbumButton setEnabled:YES];
    [self.openVoiceButton setEnabled:YES];
    [self.showlogsButton setEnabled:YES];
}

- (void)disableButtons{
    [self.sendButton setEnabled:NO];
    [self.openAlbumButton setEnabled:NO];
    [self.openVoiceButton setEnabled:NO];
    [self.showlogsButton setEnabled:NO];
}

#pragma mark - initialView
- (void)initialView{
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tapGesture];
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 80, self.view.frame.size.width, 44)];
    self.searchBar.delegate = self;
    [self.view addSubview:self.searchBar];
    
    
    self.openAlbumButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *plusImage = [UIImage imageNamed:@"plus.png"];
    [self.openAlbumButton setImage:plusImage forState:UIControlStateNormal];
    self.openAlbumButton.frame = CGRectMake(10, screenHeight-150, 40, 40);
    [self.openAlbumButton setTitle:@"Image" forState:UIControlStateNormal];
    [self.openAlbumButton addTarget:self action:@selector(openAlbumButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.openAlbumButton setEnabled:NO];
    [self.view addSubview:self.openAlbumButton];
    
    
    self.openVoiceButton = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *voiceImage = [UIImage imageNamed:@"voice.png"];
    [self.openVoiceButton setImage:voiceImage forState:UIControlStateNormal];
    self.openVoiceButton.frame = CGRectMake(90, screenHeight-150, 40, 40);
    [self.openVoiceButton setTitle:@"Voice" forState:UIControlStateNormal];
    [self.openVoiceButton addTarget:self action:@selector(openVoiceButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.openVoiceButton setEnabled:NO];
    [self.view addSubview:self.openVoiceButton];
    
    // Create the button
    self.showlogsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *logsImage = [UIImage imageNamed:@"history.png"];
    [self.showlogsButton setImage:logsImage forState:UIControlStateNormal];
    self.showlogsButton.frame = CGRectMake(170, screenHeight-150,40, 40);
    [self.showlogsButton setTitle:@"LOGS" forState:UIControlStateNormal];
    [self.showlogsButton addTarget:self action:@selector(showlogsButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.showlogsButton];
    // Create the button
    
    // Create the button
    self.sendButton = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *sendImage = [UIImage imageNamed:@"send.png"];
    [self.sendButton setImage:sendImage forState:UIControlStateNormal];
    self.sendButton.frame = CGRectMake(350, screenHeight-100, 40, 40);
    [self.sendButton setTitle:@"Send" forState:UIControlStateNormal];
    [self.sendButton addTarget:self action:@selector(sendButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.sendButton setEnabled:NO];
    [self.view addSubview:self.sendButton];
    

    
    self.exitButton = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *exitImage = [UIImage imageNamed:@"quit.png"];
    [self.exitButton setImage:exitImage forState:UIControlStateNormal];
    self.exitButton.frame = CGRectMake(screenWidth-60, 40, 30, 30);
    [self.exitButton setTitle:@"Quit" forState:UIControlStateNormal];
    [self.exitButton addTarget:self action:@selector(exitButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.exitButton];
    
    self.textFieldSendMax = [[UITextField alloc] initWithFrame:CGRectMake(300, screenHeight-150, 80, 50)];
    self.textFieldSendMax.borderStyle = UITextBorderStyleRoundedRect;
    self.textFieldSendMax.placeholder = @"Max";
    self.textFieldSendMax.text = @"512";
    [self.view addSubview:self.textFieldSendMax];
    
    // Create the first text field
    self.textFieldInternal = [[UITextField alloc] initWithFrame:CGRectMake(360, screenHeight-150, 50, 50)];
    self.textFieldInternal.borderStyle = UITextBorderStyleRoundedRect;
    self.textFieldInternal.placeholder = @"Send internal l.0";
    self.textFieldInternal.text = @"0.05";
    [self.view addSubview:self.textFieldInternal];
    
    
    // Assuming textField1 and textField2 are IBOutlet properties connected to your text fields in Interface Builder
    self.textFieldSendMax.delegate = self;
    self.textFieldInternal.delegate = self;
    
    
    // 确保密码输入模式关闭（允许粘贴操作）
    self.textMsg.secureTextEntry = NO;
    [self.view addSubview:self.textMsg];
    // Create the  text field
    self.textMsg = [[UITextField alloc] initWithFrame:CGRectMake(10,screenHeight-100,screenWidth-120, 40)];
    self.textMsg.borderStyle = UITextBorderStyleRoundedRect;
    self.textMsg.placeholder = @"send your message here";
    self.textMsg.text = @"hello,typing";
    // 允许编辑和粘贴操作
    self.textMsg.allowsEditingTextAttributes = YES;
    
    // 确保密码输入模式关闭（允许粘贴操作）
    self.textMsg.secureTextEntry = NO;
    [self.view addSubview:self.textMsg];
    
    self.listItems = [[NSMutableArray alloc] init];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 130, screenWidth - 10, screenHeight - 300)];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.userInteractionEnabled = YES;
    //    self.tableView.allowsSelection = YES; // 确保选择模式是默认值
    
    [self.view addSubview:self.tableView];
    UITapGestureRecognizer *_tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    _tapGesture.numberOfTapsRequired = 1;
    [self.tableView addGestureRecognizer:_tapGesture];
    
    [self.tableView registerClass:[MyTableViewCell class] forCellReuseIdentifier:@"MyCell"];
    [self.tableView registerClass:[voiceTableViewCell class] forCellReuseIdentifier:@"voiceCell"];
    
    UIImage *image = [UIImage imageNamed:@"radio.png"];
    [self addImagetoView:@"Start..." imagePara:image];
    
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == self.textFieldSendMax) {
        // The first text field is being edited, so we'll dismiss the keyboard for the second text field
        [self.textFieldInternal resignFirstResponder];
    } else if (textField == self.textFieldInternal) {
        // The second text field is being edited, so we'll dismiss the keyboard for the first text field
        [self.textFieldSendMax resignFirstResponder];
    }
}


- (void)handleTap:(UITapGestureRecognizer *)gestureRecognizer {
    CGPoint location = [gestureRecognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    
    if (indexPath) {
        // 调用 tableView:didSelectRowAtIndexPath: 方法，模拟点击行为
        [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
    }
}

#pragma mark - getDocumentDirectory
-(NSArray*)getDocumentDirectory{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;

    // Get the contents of the directory
    NSArray *directoryContents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:&error];
    if (error) {
        // Handle the error if any
        NSLog(@"Error reading directory contents: %@", error.localizedDescription);
        return @[];
    } else {
        
        return directoryContents;
    }
}



#pragma mark - ButtonTapped
- (void)openAlbumButtonTapped{
    [self printMessage:@"Begin pick image"];
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (void)openVoiceButtonTapped{
    [self initialaudioRecorder];
}

- (void)showlogsButtonTapped {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    
    // Get the contents of the directory
    NSArray *directoryContents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:&error];


    if (error) {
        NSLog(@"Error reading directory contents: %@", error.localizedDescription);
    } else {
        // Enumerate the files in the directory
        for (NSString *file in directoryContents) {
            NSString *filePath = [documentsDirectory stringByAppendingPathComponent:file];
            NSString *fileExtension = [filePath pathExtension];
            NSURL *fileURL = [NSURL fileURLWithPath:filePath];
            
            if ([fileExtension isEqualToString:@"jpg"]) {
                [self addImagetoView:@"imglog" imagePara:[UIImage imageWithData:[NSData dataWithContentsOfURL:fileURL]]];
            }
            else if ([fileExtension isEqualToString:@"caf"]){
                NSData *data = [NSData dataWithContentsOfURL:fileURL];
                [self addVoiceMsgtoView:@"audiolog" voicePara:data];
            }
            else if ([fileExtension isEqualToString:@"dat"]){
                
                NSError *error;
                NSString *fileContents = [NSString stringWithContentsOfFile:filePath
                                                                   encoding:NSUTF8StringEncoding
                                                                      error:&error];
                
                if (fileContents) {
                    NSString *prefixedContents = [NSString stringWithFormat:@"msglog: %@", fileContents];
                    [self printMessage:prefixedContents];
                } else{
                    NSLog(@"Error reading file: %@", error.localizedDescription);
                }
            }
        }
    }
    
}

- (void)exitButtonTapped {
    // 调用函数清除 NSUserDefaults 中指定键名的数据
    
    // 创建 UIAlertController
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Quit?" message:@"Are you sure？" preferredStyle:UIAlertControllerStyleAlert];
    
    // 添加确认按钮
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        // 在这里处理用户点击确认后的操作，比如退出应用
        [self printMessage:@"remove history..."];
        [self clearAllUserDefaults];
        exit(0);
    }];
    [alertController addAction:confirmAction];
    
    // 添加取消按钮
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancelAction];
    
    // 显示 UIAlertController
    [self presentViewController:alertController animated:YES completion:nil];
    
    
}

- (void)sendButtonTapped {
    // Button tap action implementation
    if (self.textMsg.text.length > 0) {
        NSString *msg = self.textMsg.text;
        [self sendMsg:msg];
        NSString *combinedString = [NSString stringWithFormat:@"%s %@", "Me send out : ", msg];
        [self addMessagetoView:combinedString numberParameter:0];
        self.textMsg.text = @"";
        [self.textMsg resignFirstResponder];
    } else {
        [self printMessage: @"Msg is empty"];
    }
}

- (void)sendMsg:(NSString *)msg {
    const char *output = msg.UTF8String;
    uint8_t prefix = 0x03;
    NSMutableData *data = [NSMutableData dataWithBytes:&prefix length:1];
    [data appendBytes:output length:strlen(output)];
    [self.outputStream write:[data bytes] maxLength:[data length]];
    NSString *tmpfile = [self generateUniqueFileName:@".dat"];
    [self saveFileNametoDocumentsDirectory:data filePath:tmpfile];
}


#pragma mark - UITableViewDataSource Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // 获取选中行的数据
    id item = self.listItems[indexPath.row]; // 获取数据源数组中的元素
    if ([item isKindOfClass:[NSString class]]) {
        NSString *selectedItem = self.listItems[indexPath.row];
        
        // 创建 UIAlertController
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Details"
                                                                                 message:selectedItem
                                                                          preferredStyle:UIAlertControllerStyleActionSheet];
        
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            // Code to be executed when the cancel action is tapped
            [self dismissKeyboard];
            // Add your custom code here
        }];
        
        [alertController addAction:cancelAction];

        // 显示弹出框
        [self presentViewController:alertController animated:YES completion:nil];
        
    }
    else{
        [self dismissKeyboard];
    }
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    id item = self.listItems[indexPath.row]; // 获取数据源数组中的元素
    if ([item isKindOfClass:[NSString class]]) {
        return 44.0;
    }
    else if ([item isKindOfClass:[UIImage class]]) {
        return 400.0;
    }
    else if ([item isKindOfClass:[NSURL class]]) {
        return 200.0;
    }
    else {
        return 44.0;
    }
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.listItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //    imageData
    
    id item = self.listItems[indexPath.row]; // 获取数据源数组中的元素
    if ([item isKindOfClass:[NSString class]]) {
        // 如果是字符串类型，显示文本内容
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        }
        
        NSString *itemText = self.listItems[indexPath.row];
        cell.textLabel.text = itemText;
        [self resetGlobalVariable];
        return cell;
        
    }
    else if ([item isKindOfClass:[UIImage class]]) {
        MyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MyCell"];
        if (cell == nil) {
            cell = [[MyTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:@"MyCell"];
        }
        
        CGFloat maxSize = 300.0;

        // Access the shared instance
        CommonUtils *utils = [CommonUtils sharedInstance];
        cell.imageView.image = [utils resizeImage:(UIImage *)self.listItems[indexPath.row] toMaxSize:maxSize];

        [self resetGlobalVariable];
        return cell;
    }
    else if ([item isKindOfClass:[NSURL class]]){
        // 如果是字符串类型，显示文本内容
        voiceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"voiceCell"];
        
        if (cell == nil) {
            cell = [[voiceTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"voiceCell"];
        }
        NSURL *fileURL = self.listItems[indexPath.row];
        cell.textLabel.text = fileURL.absoluteString;
        cell.textLabel.textColor = [UIColor clearColor];
        cell.myImageView.image =  [UIImage imageNamed:@"audio.png"]; // 使用图像名称加载图像
        [self resetGlobalVariable];
        
        return cell;
    }
    
    else
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        }
        cell.textLabel.text = @"Unknown";
        [self resetGlobalVariable];
        return cell;
    }
}
#pragma mark - initialaudioRecorder
- (void)initialaudioRecorder{
    
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (granted) {
            // Configure TCP socket connection (Replace with your socket setup code)
            // ...
            // Configure audio session for recording
            AVAudioSession *audioSession = [AVAudioSession sharedInstance];
            [audioSession setCategory:AVAudioSessionCategoryRecord error:nil];
            [audioSession setActive:YES error:nil];
            
            // Create URL for the audio file
            NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
            NSString *audioFileName = @"recording.m4a";
            self.outputFileURL = [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:audioFileName]];
            
            // Set up audio recording settings and create AVAudioRecorder instance
            NSDictionary *settings = @{
                AVFormatIDKey: @(kAudioFormatMPEG4AAC),
                AVSampleRateKey: @(22050.0),
                AVNumberOfChannelsKey: @(1),
                AVLinearPCMBitDepthKey: @(8),
            };
            NSError *error = nil;
            self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:self.outputFileURL settings:settings error:&error];
            if (error) {
                NSLog(@"Error creating audio recorder: %@", error.localizedDescription);
            } else {
                self.audioRecorder.delegate = self;
            }
        }
    }];
    
    if (![self.audioRecorder isRecording]) {
        // Start recording
        [self.audioRecorder recordForDuration:5.0];
        [self printMessage:@"Record start...5 seconds ,pls speak"];
        [self disableButtons];
    }
    
}
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    if (flag) {
        NSURL *outputFileURL = recorder.url;
        NSData *audioData = [NSData dataWithContentsOfURL:outputFileURL];
        [self sendAudioDataOverSocket:audioData];
        
    } else {
        [self printMessage:@"Recording fail."];
        
    }
}


- (void)sendAudioDataOverSocket:(NSData *)audioData {
    
    // 将 sendDataOverSocket 放到后台线程执行
    [self disableButtons];
    [self printMessage:@"Voice is sending...wait"];
    NSInteger segmentSize = [self.textFieldSendMax.text integerValue]-1;
    double internalvalue = [self.textFieldInternal.text doubleValue];

    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [self sendDataOverSocket:audioData withFlag:0x02 toOutputStream:self.outputStream segmentSize:(segmentSize) internalvalue:internalvalue];

        // 在任务完成后，将 addImagetoView 放回主线程执行
        dispatch_async(dispatch_get_main_queue(), ^{
            [self addVoiceMsgtoView:@"Me sent voice" voicePara:audioData];
            [self enableButtons];
            
        });
        
    });
    [self dismissViewControllerAnimated:YES completion:nil];
    
}
#pragma mark - saveNSdataToDocumentsDirectory Methods
- (NSString*)saveFileNametoDocumentsDirectory:(NSData*)nsdata filePath:(NSString *)filePath{
    
    NSData *tmpData = [[NSData alloc] initWithData:nsdata];
    
    if (filePath == nil || filePath.length == 0) {
        return @"";
    }
    @try {
 
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths firstObject];
        
        //    NSString *uniqueFileName = [self generateUniqueFileName : filetype];
        NSString *savefilePath = [documentsDirectory stringByAppendingPathComponent:filePath];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSMutableArray *savedFilePaths = [[userDefaults objectForKey:@"SavedFilePaths"] mutableCopy];
        if (!savedFilePaths) {
            savedFilePaths = [NSMutableArray array];
        }
        BOOL success = [tmpData writeToFile:savefilePath atomically:YES];
        if (success){
            [savedFilePaths addObject:savefilePath];
        }
        
        // 保存更新后的文件路径数组到 UserDefaults
        [userDefaults setObject:savedFilePaths forKey:@"SavedFilePaths"];
        [userDefaults synchronize];
        NSLog(@"save path: %@", savefilePath);
        return savefilePath;
    }
    @catch (NSException *exception) {
        NSLog(@"Caught exception: %@", exception);
    }
    @finally {

    }
}

- (NSString *)generateUniqueFileName:(NSString *)filetype {
    // 使用时间戳生成唯一文件名
    
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    NSString *tmpfileName = [NSString stringWithFormat:@"file_%.0f", timeStamp];
    // 将filetype直接拼接到tmpfileName中，得到最终的fileName
    NSString *fileName = [tmpfileName stringByAppendingString:filetype];
    NSLog(@"%@", fileName);
    return fileName;
    
}

- (void)clearAllUserDefaults {
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    // 删除名为 "SavedFilePath" 的键及其对应的数据
    [userDefaults removeObjectForKey:@"SavedFilePaths"];
    
    // 使用 synchronize 方法确保立即保存更改
    [userDefaults synchronize];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    
    NSError *error;
    NSArray *fileList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:&error];
    
    if (error) {
        // Handle the error
        NSLog(@"Error accessing directory contents: %@", error.localizedDescription);
    } else {
        for (NSString *file in fileList) {
            NSString *filePath = [documentsDirectory stringByAppendingPathComponent:file];
            NSError *removeError;
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:&removeError];
            
            if (removeError) {
                // Handle the error
                NSLog(@"Error removing file %@: %@", file, removeError.localizedDescription);
            } else {
                NSLog(@"File %@ removed successfully.", file);
            }
        }
    }
    
}

#pragma mark - UIImagePickerControllerDelegate Methods
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    UIImage *selectedImage = info[UIImagePickerControllerOriginalImage];
    NSData *imageData = UIImageJPEGRepresentation(selectedImage, 0.1);
    
    NSInteger segmentSize = [self.textFieldSendMax.text integerValue]-1;
    double internalvalue = [self.textFieldInternal.text doubleValue];

    // 将 sendDataOverSocket 放到后台线程执行
    [self disableButtons];
    [self printMessage:@"Image is sending...wait"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [self sendDataOverSocket:imageData withFlag:0x01 toOutputStream:self.outputStream segmentSize:(segmentSize) internalvalue:internalvalue];
        // 在任务完成后，将 addImagetoView 放回主线程执行
        dispatch_async(dispatch_get_main_queue(), ^{
            [self addImagetoView:@"Me sent image" imagePara:selectedImage];
            [self enableButtons];
            
        });
        
    });
    
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark - generateformattedTime
- (NSString*)generateformattedTime{
    NSDate *currentDate = [NSDate date];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSUInteger units = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitNanosecond;
    NSDateComponents *components = [calendar components:units fromDate:currentDate];
    
    NSString *formattedTime = [NSString stringWithFormat:@"%02ld:%02ld:%02ld",
                               //                               (long)components.year,
                               //                               (long)components.month,
                               //                               (long)components.day,
                               (long)components.hour,
                               (long)components.minute,
                               (long)components.second];
    
    return formattedTime;
    
}
#pragma mark - addVoiceMsgtoView
- (void)playVoice:(NSURL *) fileURL{
    // Initialize the AVAudioPlayer with the file URL
    NSError *error = nil;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
    //                // Check if initialization succeeded
    if (self.audioPlayer) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        if ([self.audioPlayer prepareToPlay])
        {
            NSString *urlString = [fileURL absoluteString];
            [self addMessagetoView:@"Playing" numberParameter:0];
            [self printMessage:urlString];
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

- (NSURL *)saveAudioFile:(NSData *)voicePara{
    // 创建并返回一个 NSString 对象
    NSString *tmpfile = [self generateUniqueFileName:@".caf"];
    NSString *audioFilePath = [self saveFileNametoDocumentsDirectory:voicePara filePath:tmpfile];
    NSURL *fileURL = [NSURL fileURLWithPath:audioFilePath];
    return fileURL;
}


- (void)addVoiceMsgtoView:(NSString *)stringParameter voicePara:(NSData *)voicePara {
    
    NSString *formattedTime = [self generateformattedTime];
    NSURL *fileURL = [self saveAudioFile:voicePara];
    [self playVoice:fileURL];
    
    NSString *logString = [NSString stringWithFormat:@"%@: %@", formattedTime,stringParameter];
    [self.listItems addObject:logString];
    [self refreshTableView:self.tableView];
    [self.listItems addObject:fileURL];
    [self refreshTableView:self.tableView];
}

- (NSURL *)saveImageFile:(UIImage *)imagePara{
    // Set the compression quality for JPEG representation (0.0 to 1.0)
    // Convert UIImage to JPEG format NSData with the specified compression quality
    NSData *jpegImageData = UIImageJPEGRepresentation(imagePara, 1.0);
    NSString *tmpfile = [self generateUniqueFileName:@".jpg"];
    NSString *imageFilePath = [self saveFileNametoDocumentsDirectory:jpegImageData filePath:tmpfile];
    NSURL *fileURL = [NSURL fileURLWithPath:imageFilePath];
    return fileURL;
}
- (void)addImagetoView:(NSString *)stringParameter imagePara:(UIImage *)imagePara {
    
    NSString *formattedTime = [self generateformattedTime];
    NSURL *fileURL = [self saveImageFile:imagePara];
    NSData *imageData = [NSData dataWithContentsOfURL:fileURL];
    UIImage *image = [UIImage imageWithData:imageData];
    
    
    NSString *logString = [NSString stringWithFormat:@"%@: %@: %@", formattedTime,stringParameter,[fileURL absoluteString]];
    [self.listItems addObject:logString];
    [self refreshTableView:self.tableView];
    [self.listItems addObject:image];
    [self refreshTableView:self.tableView];
}

#pragma mark - refreshTableView
- (void)refreshTableView:(UITableView *)uiTableView{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [uiTableView reloadData];
        NSInteger lastSection = uiTableView.numberOfSections - 1;
        NSInteger lastRow = [uiTableView numberOfRowsInSection:lastSection] - 1;
        NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:lastRow inSection:lastSection];
        [uiTableView scrollToRowAtIndexPath:lastIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    });
}
#pragma mark - print message

- (void)printMessage:(NSString *)stringParameter{
    NSString *formattedTime = [self generateformattedTime];
    NSString *msgString = [NSString stringWithFormat:@"%@: %@", formattedTime,stringParameter];
    [self.listItems addObject:msgString];
    [self refreshTableView:self.tableView];
}


- (void)addMessagetoView:(NSString *)stringParameter numberParameter:(NSUInteger)numberParameter {
    NSString *length = [NSString stringWithFormat:@"%ld", (long)numberParameter];
    NSString *formattedTime = [self generateformattedTime];
    
    NSData *txtdata = [stringParameter dataUsingEncoding:NSUTF8StringEncoding];
    NSString *tmpfile = [self generateUniqueFileName:@".dat"];
    NSString *txtFilePath = [self saveFileNametoDocumentsDirectory:txtdata filePath:tmpfile];

    if (numberParameter==0){
//        NSString *lengthString = [NSString stringWithFormat:@"%@", stringParameter];
        NSString *lengthString = [NSString stringWithFormat:@"%@: %@ : %@", formattedTime,stringParameter,txtFilePath];
        
        [self.listItems addObject:lengthString];
    }
    else {
        NSString *lengthString = [NSString stringWithFormat:@"%@: %@ : %@ : %@", formattedTime,stringParameter,txtFilePath,length];
        [self.listItems addObject:lengthString];
    }
    NSLog(@"%@: %@ : %@", formattedTime,stringParameter, length);
    [self refreshTableView:self.tableView];
}

#pragma mark - socket
- (void)sendDataWithPrefix:(NSData *)prefixData restOfData:(NSData *)restData toOutputStream:(NSOutputStream *)outputStream segmentSize:(NSInteger) segmentSize internalvalue:(double) internalvalue {
    // Send the first 5 bytes separately
    NSInteger bytesWritten = [outputStream write:prefixData.bytes maxLength:prefixData.length];
       
    if (bytesWritten < 0) {
        // Handle the error
        NSLog(@"Error writing to output stream: %@", outputStream.streamError.localizedDescription);
        return;
    }

    // Send the rest of the data in chunks
    NSUInteger totalBytesToSend = restData.length;
    NSUInteger chunkSize = (NSUInteger)segmentSize;
    NSUInteger offset = 0;

    while (offset < totalBytesToSend) {
        NSUInteger remainingBytes = totalBytesToSend - offset;
        NSUInteger bytesToSend = MIN(chunkSize, remainingBytes);

        // Get the chunk of data to send
        NSRange range = NSMakeRange(offset, bytesToSend);
        NSData *chunkData = [restData subdataWithRange:range];

        // Write the chunk data to the output stream
        bytesWritten = [outputStream write:chunkData.bytes maxLength:chunkData.length];

        if (bytesWritten < 0) {
            // Handle the error
            NSLog(@"Error writing to output stream: %@", outputStream.streamError.localizedDescription);
            break;
        }

        // Update the offset to send the next chunk
        [NSThread sleepForTimeInterval:internalvalue]; // 100 milliseconds
        offset += bytesWritten;
    }

    // Ensure all data is flushed to the output stream
//    [outputStream close];
}


- (void)sendDataOverSocket:(NSData *)socketData withFlag:(uint8_t)flag toOutputStream:(NSOutputStream *)outputStream segmentSize:(NSInteger) segmentSize internalvalue:(double) internalvalue{

    if ([outputStream hasSpaceAvailable]) {
        
        NSUInteger dataLength = [socketData length];
        uint8_t *finalBytes = malloc(5 * sizeof(uint8_t));
        // Convert imageLength to two bytes
        uint32_t lengthBytes = (uint32_t)dataLength;
        finalBytes[0] = flag;
        finalBytes[1] = (lengthBytes >> 24) & 0xFF;
        finalBytes[2] = (lengthBytes >> 16) & 0xFF;
        finalBytes[3] = (lengthBytes >> 8) & 0xFF;
        finalBytes[4] = lengthBytes & 0xFF;
        NSData *lendata = [NSData dataWithBytes:finalBytes length:5];
        
        [self sendDataWithPrefix:lendata restOfData:socketData toOutputStream:outputStream segmentSize:segmentSize internalvalue:internalvalue ];
    }
}

- (void)setupServerSocket {

//    [self addMessagetoView:@"Begin setup TCP Server." numberParameter:0];

    CFSocketContext socketContext = {0, (__bridge void *)(self), NULL, NULL, NULL};
    self.socket = CFSocketCreate(
        kCFAllocatorDefault,
        PF_INET, // or PF_INET6 for IPv6 support
        SOCK_STREAM,
        IPPROTO_TCP,
        kCFSocketAcceptCallBack,
        socketAcceptCallback,
        &socketContext
    );
    
    if (self.socket == NULL) {
        [self printMessage:@"Failed to create socket."];

        return;
    }
    
    int reuse = 1;
    setsockopt(
        CFSocketGetNative(self.socket),
        SOL_SOCKET,
        SO_REUSEADDR,
        (const void *)&reuse,
        sizeof(int)
    );
    

    struct sockaddr_in serverAddress;
    memset(&serverAddress, 0, sizeof(serverAddress));
    serverAddress.sin_len = sizeof(serverAddress);
    serverAddress.sin_family = AF_INET;
    serverAddress.sin_port = htons(5000); // Choose your desired port
    
    NSString *localIPAddress = [self getLocalIPAddress];
    NSLog(@"%@", localIPAddress);
    if (localIPAddress) {
        
        const char *addressCString = [localIPAddress UTF8String];
        if (inet_aton(addressCString, &serverAddress.sin_addr) == 0) {
            NSLog(@"Invalid server address");
            // Handle error condition
        }
    } else {
        NSLog(@"Unable to retrieve local IP address");
    }

    CFDataRef addressData = CFDataCreate(
        kCFAllocatorDefault,
        (const UInt8 *)&serverAddress,
        sizeof(serverAddress)
    );
    
    if (CFSocketSetAddress(self.socket, addressData) != kCFSocketSuccess) {
        [self printMessage:@"Failed to bind to addres."];
        CFRelease(self.socket);
        self.socket = NULL;
        return;
    }
    
    CFRunLoopSourceRef socketSource = CFSocketCreateRunLoopSource(
        kCFAllocatorDefault,
        self.socket,
        0
    );
    
    CFRunLoopAddSource(
        CFRunLoopGetCurrent(),
        socketSource,
        kCFRunLoopDefaultMode
    );
    
//    [self addMessagetoView:@"Tcp server succes." numberParameter:0];
    
    CFRelease(addressData);
    CFRelease(socketSource);
    [self printMessage:@"Tcp server succes"];
}

- (NSString *)getLocalIPAddress {
    NSString *address = nil;
    
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp = NULL;
    int success = getifaddrs(&interfaces);
    
    if (success == 0) {
        temp = interfaces;
        while (temp != NULL) {
            if (temp->ifa_addr->sa_family == AF_INET) {
                if ([[NSString stringWithUTF8String:temp->ifa_name] isEqualToString:@"en0"]) {
                    struct sockaddr_in *addr = (struct sockaddr_in *)temp->ifa_addr;
                    char *ipAddress = inet_ntoa(addr->sin_addr);
                    address = [NSString stringWithUTF8String:ipAddress];
                    break;
                }
            }
            temp = temp->ifa_next;
        }
    }
    
    freeifaddrs(interfaces);
    
    return address;
}

static void socketAcceptCallback(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
    ViewController *viewController = (__bridge ViewController *)(info);
    
    if (type != kCFSocketAcceptCallBack) {
        return;
    }
    
    CFSocketNativeHandle nativeSocketHandle = *(CFSocketNativeHandle *)data;
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    
    CFStreamCreatePairWithSocket(
        kCFAllocatorDefault,
        nativeSocketHandle,
        &readStream,
        &writeStream
    );
    
    if (readStream && writeStream) {
        CFReadStreamSetProperty(
            readStream,
            kCFStreamPropertyShouldCloseNativeSocket,
            kCFBooleanTrue
        );
        
        CFWriteStreamSetProperty(
            writeStream,
            kCFStreamPropertyShouldCloseNativeSocket,
            kCFBooleanTrue
        );
        
        viewController.inputStream = (__bridge NSInputStream *)(readStream);
        viewController.outputStream = (__bridge NSOutputStream *)(writeStream);
        
        [viewController.inputStream setDelegate:viewController];
        [viewController.outputStream setDelegate:viewController];
        
        [viewController.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [viewController.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        
        [viewController.inputStream open];
        [viewController.outputStream open];
    } else {
        close(nativeSocketHandle);
    }
}
- (void)getClientInfo:(NSInputStream *)inputStream {
    CFSocketNativeHandle socketID = [self getSocketIDFromStream:inputStream];
    NSLog(@"Socket ID: %d", socketID);
    
    struct sockaddr_storage sockAddrStorage;
    socklen_t sockAddrLength = sizeof(sockAddrStorage);
    memset(&sockAddrStorage, 0, sockAddrLength);
    
    if (getpeername(socketID, (struct sockaddr *)&sockAddrStorage, &sockAddrLength) == 0) {
        if (sockAddrStorage.ss_family == AF_INET) {
            struct sockaddr_in *sockAddrIPv4 = (struct sockaddr_in *)&sockAddrStorage;
            char ipAddress[INET_ADDRSTRLEN];
            const char *ipAddressCString = inet_ntop(AF_INET, &(sockAddrIPv4->sin_addr), ipAddress, INET_ADDRSTRLEN);
            
            if (ipAddressCString != NULL) {
                NSString *clientIPAddress = [NSString stringWithUTF8String:ipAddressCString];
                NSLog(@"Client IP Address: %@", clientIPAddress);
            } else {
                NSLog(@"Unable to retrieve client IP address");
            }
        } else if (sockAddrStorage.ss_family == AF_INET6) {
            struct sockaddr_in6 *sockAddrIPv6 = (struct sockaddr_in6 *)&sockAddrStorage;
            char ipAddress[INET6_ADDRSTRLEN];
            const char *ipAddressCString = inet_ntop(AF_INET6, &(sockAddrIPv6->sin6_addr), ipAddress, INET6_ADDRSTRLEN);
            
            if (ipAddressCString != NULL) {
                NSString *clientIPAddress = [NSString stringWithUTF8String:ipAddressCString];
                NSLog(@"Client IP Address: %@", clientIPAddress);
            } else {
                NSLog(@"Unable to retrieve client IP address");
            }
        } else {
            NSLog(@"Unsupported address family");
        }
    } else {
        NSLog(@"Error retrieving client address");
    }
}

- (CFSocketNativeHandle)getSocketIDFromStream:(NSInputStream *)inputStream {
    CFSocketNativeHandle socketID = -1;
    CFDataRef socketData = CFReadStreamCopyProperty((__bridge CFReadStreamRef)inputStream, kCFStreamPropertySocketNativeHandle);
    
    if (socketData != NULL) {
        NSData *socketNSData = (__bridge_transfer NSData *)socketData;
        if (socketNSData.length == sizeof(CFSocketNativeHandle)) {
            [socketNSData getBytes:&socketID length:sizeof(CFSocketNativeHandle)];
        }
    }
    
    return socketID;
}


#pragma mark - <NSStreamDelegate>代理方法
- (void)processData:(NSData *)data {
    // Process received data here
    NSString *receivedString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"Received data: %@", receivedString);
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventNone:
            break;
            
        case NSStreamEventOpenCompleted:
            
            if (aStream == self.inputStream) {
                [self getClientInfo:self.inputStream];
                [self printMessage:@"Client Connected successfully"];
                [self enableButtons];
            }
            
            break;
        case NSStreamEventHasBytesAvailable:
        {
            uint8_t buf[1024];
            NSInteger len = 0;
            NSInputStream *inputStream = (NSInputStream *)aStream;
            NSMutableData *accumulatedData = [NSMutableData data]; //

            [accumulatedData setLength:0];
            while ([inputStream hasBytesAvailable]) {
                len = [inputStream read:buf maxLength:1024];
                if (len > 0) {
                    [accumulatedData appendBytes:buf length:len]; // 重新设置为新的数据
                }
            }
            
            [totalData appendData:accumulatedData];
            
            [NSThread sleepForTimeInterval:0.2]; // 睡眠50毫秒
            
            // Assuming accumulatedData has at least 5 bytes
            uint8_t extractedBytes[5];
            [totalData getBytes:extractedBytes length:5];
            flag = extractedBytes[0];
            
            if (flag == 0x03){
                [totalData replaceBytesInRange:NSMakeRange(0, 1) withBytes:NULL length:0];
                 NSString *convertedString = [[NSString alloc] initWithData:totalData encoding:NSUTF8StringEncoding];
                [self addMessagetoView:convertedString numberParameter:0];
                [accumulatedData setLength:0] ;
                [self resetGlobalVariable];
            }
            else if (flag == 0x01||flag == 0x02){
                sentLength = ((uint32_t)extractedBytes[1] << 24) |
                ((uint32_t)extractedBytes[2] << 16) |
                ((uint32_t)extractedBytes[3] << 8)  |
                extractedBytes[4];
                if (sentLength == totalData.length-5 ){

                    if(flag==0x01)
                    {
                        [totalData replaceBytesInRange:NSMakeRange(0, 5) withBytes:NULL length:0];
                        
                        UIImage *image = [UIImage imageWithData:totalData];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self addImagetoView:@"Received image to me:" imagePara:image];
                        });
                        
                        [accumulatedData setLength:0] ;
                        [self resetGlobalVariable];

                    }
                    else if (flag==0x02){
                        [totalData replaceBytesInRange:NSMakeRange(0, 5) withBytes:NULL length:0];
                        [self addVoiceMsgtoView:@"Received Voice to me" voicePara:totalData];
                        
                        [accumulatedData setLength:0] ;
                        [self resetGlobalVariable];
                    }

                    else {
                        [accumulatedData setLength:0] ;
                        [self resetGlobalVariable];
                    }

                }
            }
            break;
        }
        case NSStreamEventHasSpaceAvailable:
            break;
        case NSStreamEventErrorOccurred:
        {
            [self printMessage:@"Error"];
            [self disableButtons];
            [aStream close];
            [aStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            aStream = nil;

            break;
            
        }
            
        case NSStreamEventEndEncountered:
            
            [self printMessage:@"Client disconnected"];
            
            [self disableButtons];
            
            [aStream close];
            [aStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            aStream = nil;
            break;
            
        default:
            break;
    }
}

@end
