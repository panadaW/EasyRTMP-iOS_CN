//
//  ViewController.m
//  EasyCapture
//
//  Created by leo on 9/7/18.
//  Copyright © 2018 leo. All rights reserved.
//

#import "PushViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreTelephony/CTCellularData.h>
#import "ResolutionViewController.h"
#import "SettingViewController.h"
#import "InfoViewController.h"
#import "NetNotifieViewController.h"
#import "URLTool.h"
#import "CameraEncoder.h"
#import <ReplayKit/ReplayKit.h>
#import "WHToast.h"
#import "NLVTPostRequest.h"
#import "NLVTUserArchiver.h"
#import "MSRegisCodeModel.h"
#import "MJExtension.h"
#import "UUIDTool.h"

API_AVAILABLE(ios(12.0))
@interface PushViewController ()<SetDelegate, EasyResolutionDelegate, ConnectDelegate>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topViewMarginTop;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mainViewWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mainViewHeight;

@property (weak, nonatomic) IBOutlet UILabel *bitrateLabel;
@property (weak, nonatomic) IBOutlet UIButton *resolutionBtn;
@property (weak, nonatomic) IBOutlet UIButton *reverseBtn;
@property (weak, nonatomic) IBOutlet UIButton *screenBtn;
@property (weak, nonatomic) IBOutlet UIButton *infoBtn;
@property (weak, nonatomic) IBOutlet UIButton *pushBtn;
@property (weak, nonatomic) IBOutlet UIButton *pushScreenBtn;
@property (weak, nonatomic) IBOutlet UIButton *recordBtn;
@property (weak, nonatomic) IBOutlet UIButton *settingBtn;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIView *btnView;

@property (weak, nonatomic) IBOutlet UIView *alertView;
@property (weak, nonatomic) IBOutlet UITextField *regisTextfield;
@property (weak, nonatomic) IBOutlet UIView *regisAlert;


@property (nonatomic, strong) CameraEncoder *encoder;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *prev;

@property (nonatomic, strong) RPSystemBroadcastPickerView *broadPickerView;

//黑屏
@property (nonatomic, strong) UIView *backGroundView;
@property (nonatomic) BOOL statusHiden;
@end

@implementation PushViewController

- (instancetype) initWithStoryboard {
    return [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"PushViewController"];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.regisAlert.layer.borderColor = [UIColor whiteColor].CGColor;
    self.regisAlert.layer.cornerRadius = 4;
    self.regisAlert.layer.borderWidth = 1;
}
#pragma mark - init

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveKeySucess:) name:@"saveKeySucess" object:nil];
    // UI
    [self setUI];
    NLVTUserAccount *account = [[NLVTUserArchiver shareInstance] readUserAccount];
    if (!account || account.regisCode.length == 0) {
        self.alertView.hidden = NO;
        self.regisAlert.hidden = NO;
    }else {
        self.regisAlert.hidden = YES;
        [self regisCode:account.regisCode];//验证注册码
    }
    
    self.prev = self.encoder.previewLayer;
    [[self.prev connection] setVideoOrientation:AVCaptureVideoOrientationPortrait];
    self.prev.frame = CGRectMake(0, 0, EasyScreenWidth, EasyScreenHeight);
    
    self.encoder.previewLayer.hidden = NO;
    [self.encoder startCapture];
    [self.encoder changeCameraStatus:[URLTool gainOnlyAudio]];
    
    // 根据应用生命周期的通知来设置推流器
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(someMethod:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(someMethod:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    self.statusLabel.text = [NSString stringWithFormat:@"断开链接",nil];
//    [self changeScreen:self.screenBtn];//切换竖屏
    
    if (@available(iOS 12.0, *)) {
        CGFloat w = EasyScreenWidth / 4;
        _broadPickerView = [[RPSystemBroadcastPickerView alloc] initWithFrame:CGRectMake(w-10, 0, w, 49)];
        _broadPickerView.preferredExtension = @"org.easydarwin.easydarwinrtmp.EasyScreenLive";
        [self.btnView insertSubview:_broadPickerView belowSubview:_pushScreenBtn];
    } else {
        // Fallback on earlier versions
    }
}

- (void)alertTextFieldDidChange:(UITextField *)sender
{
    UIAlertController *alertController = (UIAlertController *)self.presentedViewController;
    if (alertController)
    {
        UITextField *login = alertController.textFields.firstObject;
        UIAlertAction *okAction = alertController.actions.lastObject;
        okAction.enabled = login.text.length > 0;
    }
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = YES;
    
    // 设置窗口亮度大小  范围是0.1 - 1.0
    [[UIScreen mainScreen] setBrightness:0.8];
    // 设置屏幕常亮
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    [self.resolutionBtn setTitle:[NSString stringWithFormat:@"分辨率：%@", [URLTool gainResolition]] forState:UIControlStateNormal];
    
    self.bitrateLabel.text = [NSString stringWithFormat:@"码率：0Kbps"];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.navigationController.navigationBarHidden = NO;
    
    [self.encoder stopCamera];
    self.recordBtn.selected = NO;// 到后台则停止录像
}


- (IBAction)regisAction:(UIButton *)sender {
    [self regisCode:self.regisTextfield.text];
}

#pragma mark -request
- (void)regisCode:(NSString *)regisCode {
    NSMutableDictionary *header = [NSMutableDictionary dictionary];
    [header setObject:regisCode forKey:@"regisCode"];
    [header setObject:@"SJJK_IOS_CN" forKey:@"softwareId"];
    [header setObject:@"mb" forKey:@"softwareType"];
    NLVTRequestParam *param = [NLVTRequestParam paramWithDictionary:header];
    [NLVTPostRequest regisCodeRequestWithParam:param requestProgress:^(NSProgress * _Nonnull progress) {

    } requestFinish:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        BOOL hidden = NO;
        NSString *Result = responseObject[@"Result"];
        if ([Result isEqualToString:@"ok"]) {
            NSArray *dicArray = responseObject[@"Model"];
            NSArray *modelArray = [MSRegisCodeModel mj_objectArrayWithKeyValuesArray:dicArray];
            if (modelArray.count > 0) {
                MSRegisCodeModel *model = modelArray[0];
                if ([model.RegisCodeState isEqualToString:@"正常"]) {
                    if (model.Imei.length > 0) {
                       NSString *uuid = [UUIDTool getUUIDInKeychain];
                        if (![uuid isEqualToString:model.Imei]) {
                            [self showAlert:@"该注册码不允许在此手机上使用" abort:NO];
                        }else {
                            self.alertView.hidden = YES;
                            self.regisAlert.hidden = YES;
                            NLVTUserAccount *account = [[NLVTUserArchiver shareInstance] readUserAccount];
                            if (!account) account = [[NLVTUserAccount alloc] init];
                            account.regisCode = model.RegisCode;
                            if (account.signId.length == 0) account.signId = @"";
                            if (account.ip.length == 0) account.ip = @"58.49.46.179";
                            if (account.port.length == 0) account.port = @"10085";
                            [[NLVTUserArchiver shareInstance] saveUserAccount:account];
                            hidden = YES;
                        }
                    }else {
                        if ([model.isImei isEqualToString:@"1"]) {
                            NSString *uuid = [UUIDTool getUUIDInKeychain];
                            [self sedImei:uuid regisCode:model.RegisCode];
                        }
                    }
                    
                }else {
                    hidden = YES;
                    [self showAlert:model.RegisCodeState abort:YES];
                }
            }else {
                [self showAlert:@"当前注册码不存在" abort:NO];
            }
        }
        self.alertView.hidden = hidden;
        self.regisAlert.hidden = hidden;
        
    } requestFailed:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {

    }];
}

- (void)sedImei:(NSString *)uuid regisCode:(NSString *)regisCode {
    NSMutableDictionary *header = [NSMutableDictionary dictionary];
    [header setObject:uuid forKey:@"imei"];
    [header setObject:regisCode forKey:@"regisCode"];
    [header setObject:@"mb" forKey:@"softType"];
    NLVTRequestParam *param = [NLVTRequestParam paramWithDictionary:header];
    [NLVTPostRequest imeiRequestWithParam:param requestProgress:^(NSProgress * _Nonnull progress) {
        
    } requestFinish:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        NSString *Result = responseObject[@"Result"];
        if ([Result isEqualToString:@"ok"]) {
            self.alertView.hidden = YES;
            self.regisAlert.hidden = YES;
            NLVTUserAccount *account = [[NLVTUserArchiver shareInstance] readUserAccount];
            if (!account) account = [[NLVTUserAccount alloc] init];
            account.regisCode = regisCode;
            if (account.signId.length == 0) account.signId = @"";
            if (account.ip.length == 0) account.ip = @"58.49.46.179";
            if (account.port.length == 0) account.port = @"10085";
            [[NLVTUserArchiver shareInstance] saveUserAccount:account];
        }
    } requestFailed:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        
    }];
}

- (void)showAlert:(NSString *)message abort:(BOOL)isabort {

    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:message message:nil preferredStyle:UIAlertControllerStyleAlert];
   
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        if (isabort) abort();
    }];
    [alertController addAction:action];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - UI

- (void)setUI {
    self.topViewMarginTop.constant = EasyBarHeight + 10;
    self.mainViewWidth.constant = EasyScreenWidth;
    self.mainViewHeight.constant = EasyScreenHeight;
    
    [self.resolutionBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
    [self.resolutionBtn setTitleColor:UIColorFromRGB(ThemeColor) forState:UIControlStateHighlighted];
    [self.infoBtn setImage:[UIImage imageNamed:@"version"] forState:UIControlStateNormal];
    [self.infoBtn setImage:[UIImage imageNamed:@"version_click"] forState:UIControlStateHighlighted];
    [self.settingBtn setImage:[UIImage imageNamed:@"tab_setting"] forState:UIControlStateNormal];
    [self.settingBtn setImage:[UIImage imageNamed:@"tab_setting_click"] forState:UIControlStateHighlighted];
    [self.settingBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
    [self.settingBtn setTitleColor:UIColorFromRGB(ThemeColor) forState:UIControlStateHighlighted];
    [self.pushScreenBtn setImage:[UIImage imageNamed:@"push_screen"] forState:UIControlStateNormal];
    [self.pushScreenBtn setImage:[UIImage imageNamed:@"push_screen_click"] forState:UIControlStateHighlighted];
    [self.pushScreenBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
    [self.pushScreenBtn setTitleColor:UIColorFromRGB(ThemeColor) forState:UIControlStateHighlighted];
    
    [self.reverseBtn setImage:[UIImage imageNamed:@"reverse"] forState:UIControlStateNormal];
    [self.reverseBtn setImage:[UIImage imageNamed:@"reverse_click"] forState:UIControlStateSelected];
    [self.screenBtn setImage:[UIImage imageNamed:@"screen"] forState:UIControlStateNormal];
    [self.screenBtn setImage:[UIImage imageNamed:@"screen_click"] forState:UIControlStateSelected];
    [self.pushBtn setImage:[UIImage imageNamed:@"tab_push"] forState:UIControlStateNormal];
    [self.pushBtn setImage:[UIImage imageNamed:@"tab_push_click"] forState:UIControlStateSelected];
    [self.pushBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
    [self.pushBtn setTitleColor:UIColorFromRGB(ThemeColor) forState:UIControlStateSelected];
    [self.recordBtn setImage:[UIImage imageNamed:@"tab_record"] forState:UIControlStateNormal];
    [self.recordBtn setImage:[UIImage imageNamed:@"tab_record_click"] forState:UIControlStateSelected];
    [self.recordBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
    [self.recordBtn setTitleColor:UIColorFromRGB(ThemeColor) forState:UIControlStateSelected];
    
    [self.pushBtn setImageEdgeInsets:UIEdgeInsetsMake(-20, 30, 0, 0)];
    [self.pushBtn setTitleEdgeInsets:UIEdgeInsetsMake(24, -22, 0, 0)];
    [self.pushScreenBtn setImageEdgeInsets:UIEdgeInsetsMake(-20, 28, 0, 0)];
    [self.pushScreenBtn setTitleEdgeInsets:UIEdgeInsetsMake(24, -30, 0, 0)];
    [self.recordBtn setImageEdgeInsets:UIEdgeInsetsMake(-20, 30, 0, 0)];
    [self.recordBtn setTitleEdgeInsets:UIEdgeInsetsMake(24, -22, 0, 0)];
    [self.settingBtn setImageEdgeInsets:UIEdgeInsetsMake(-20, 30, 0, 0)];
    [self.settingBtn setTitleEdgeInsets:UIEdgeInsetsMake(24, -22, 0, 0)];
}

- (BOOL)prefersStatusBarHidden {
    return self.statusHiden;
}

#pragma mark - 处理通知

- (void)someMethod:(NSNotification *)sender {
    if ([sender.name isEqualToString:UIApplicationDidBecomeActiveNotification]) {
        if (self.pushBtn.selected && self.encoder) {
            dispatch_queue_t queue = dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL);
            dispatch_async(queue, ^{
                [self.encoder startCamera:[URLTool gainURL]];
            });
        }
    } else {
        if (self.pushBtn.selected && self.encoder) {
            [self.encoder stopCamera];
            self.recordBtn.selected = NO;// 到后台则停止录像
        }
    }
}

#pragma mark - SetDelegate

// 设置页面修改了分辨率后的操作
- (void)setFinish {
    [self.encoder changeCameraStatus:[URLTool gainOnlyAudio]];
}

#pragma mark - EasyResolutionDelegate

- (void)onSelecedesolution:(NSInteger)resolutionNo {
    [self.encoder swapResolution:[self captureSessionPreset]];
    
    NSString *resolution = [URLTool gainResolition];
    NSArray *resolutionArray = [resolution componentsSeparatedByString:@"*"];
    int width = [resolutionArray[0] intValue];
    int height = [resolutionArray[1] intValue];
    if (self.screenBtn.selected) {
        // 横屏推流
        self.encoder.orientation = AVCaptureVideoOrientationLandscapeRight;
        self.encoder.outputSize = CGSizeMake(height, width);
    } else {
        // 竖屏推流
        self.encoder.orientation = AVCaptureVideoOrientationPortrait;
        self.encoder.outputSize = CGSizeMake(width, height);
    }
    
    [self.resolutionBtn setTitle:[NSString stringWithFormat:@"分辨率：%@", [URLTool gainResolition]] forState:UIControlStateNormal];
}

#pragma mark - private method

- (AVCaptureSessionPreset) captureSessionPreset {
    NSString *resolution = [URLTool gainResolition];
    if ([resolution isEqualToString:@"288*352"]) {
        return AVCaptureSessionPreset352x288;
    } else if ([resolution isEqualToString:@"480*640"]) {
        return AVCaptureSessionPreset640x480;
    } else if ([resolution isEqualToString:@"720*1280"]) {
        return AVCaptureSessionPreset1280x720;
    } else if ([resolution isEqualToString:@"1080*1920"]) {
        return AVCaptureSessionPreset1920x1080;
    } else {
        return AVCaptureSessionPreset1280x720;
    }
}

- (CGSize) captureSessionSize {
    NSString *resolution = [URLTool gainResolition];
    if ([resolution isEqualToString:@"288*352"]) {
        return CGSizeMake(288, 352);
    } else if ([resolution isEqualToString:@"480*640"]) {
        return CGSizeMake(480, 640);
    } else if ([resolution isEqualToString:@"720*1280"]) {
        return CGSizeMake(720, 1280);
    } else if ([resolution isEqualToString:@"1080*1920"]) {
        return CGSizeMake(1080, 1920);
    } else {
        return CGSizeMake(720, 1280);
    }
}

#pragma mark - ConnectDelegate

- (void)getConnectStatus:(NSString *)status isFist:(int)tag {
    if (![status isEqualToString:@"连接中"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.pushBtn.userInteractionEnabled = YES;
            self.settingBtn.userInteractionEnabled = YES;
            self.recordBtn.userInteractionEnabled = YES;
            self.reverseBtn.userInteractionEnabled = YES;
            self.screenBtn.userInteractionEnabled = YES;
        });
    }
    if (tag == 1) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                self.statusLabel.text = [NSString stringWithFormat:@"%@", status];
            });
        });
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
//                NSString *url = [URLTool gainURL];
                self.statusLabel.text = [NSString stringWithFormat:@"%@", status];
                
                if ([status isEqualToString:@"推流中"]) {
                    self.pushBtn.selected = YES;
                    self.settingBtn.enabled = NO;
                    self.infoBtn.enabled = NO;
                    self.resolutionBtn.enabled = NO;
                    self.reverseBtn.enabled = NO;
                    self.screenBtn.enabled = NO;
                } else {
//                    self.pushBtn.selected = NO;
                    self.settingBtn.enabled = YES;
                    self.infoBtn.enabled = YES;
                    self.resolutionBtn.enabled = YES;
                    self.reverseBtn.enabled = YES;
                    self.screenBtn.enabled = YES;
                }
            });
        });
    }
}

// 推流速度
- (void) sendPacketFrameLength:(unsigned int)length {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.bitrateLabel.text = [NSString stringWithFormat:@"码率：%dKB/s", length / 1024];
//        self.bitrateLabel.text = [NSString stringWithFormat:@"码率：%dkbps", length / 1024];
    });
}

#pragma mark - click event

// 分辨率
- (IBAction)resolution:(id)sender {
    if (self.encoder.running) {
        return;
    }
    
    ResolutionViewController *controller = [[ResolutionViewController alloc] init];
    controller.delegate = self;
    controller.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:controller animated:YES completion:nil];
}

// 切换前后摄像头
- (IBAction)reverse:(id)sender {
    if ([self.statusLabel.text isEqualToString:@"连接中"]) return;
    self.reverseBtn.selected = !self.reverseBtn.selected;
    [self.encoder swapFrontAndBackCameras];
}

// 横竖屏
- (IBAction)changeScreen:(id)sender {
    if ([self.statusLabel.text isEqualToString:@"连接中"]) return;
    self.screenBtn.selected = !self.screenBtn.selected;
    
    NSString *resolution = [URLTool gainResolition];
    NSArray *resolutionArray = [resolution componentsSeparatedByString:@"*"];
    int width = [resolutionArray[0] intValue];
    int height = [resolutionArray[1] intValue];
    
    if (self.screenBtn.selected) {
        // UI 横屏
        self.mainViewWidth.constant = EasyScreenHeight;
        self.mainViewHeight.constant = EasyScreenWidth;
        self.mainView.transform = CGAffineTransformMakeRotation(M_PI_2);
        [self.mainView updateConstraintsIfNeeded];
        [self.mainView layoutIfNeeded];
        
        // 横屏推流
        self.encoder.orientation = AVCaptureVideoOrientationLandscapeRight;
        self.encoder.outputSize = CGSizeMake(height, width);
    } else {
        // UI 竖屏
        self.mainViewWidth.constant = EasyScreenWidth;
        self.mainViewHeight.constant = EasyScreenHeight;
        self.mainView.transform = CGAffineTransformIdentity;
        [self.mainView updateConstraintsIfNeeded];
        [self.mainView layoutIfNeeded];
        
        // 竖屏推流
        self.encoder.orientation = AVCaptureVideoOrientationPortrait;
        self.encoder.outputSize = CGSizeMake(width, height);
    }
    
    // 状态栏
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [self prefersStatusBarHidden];
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }
}

// 关于
- (IBAction)info:(id)sender {
    if (self.encoder.running) {
        return;
    }

    InfoViewController *controller = [[InfoViewController alloc] initWithStoryboard];
    [self basePushViewController:controller];
}

- (void)resetPushBtn {
    self.pushBtn.userInteractionEnabled = YES;
}
// 推送
- (IBAction)push:(id)sender {
    int activeDay = [URLTool activeDay];
    if (activeDay <= 0) {
        [self showAlert:@"推流认证失败！" abort:YES];
        return;
    }
    self.pushBtn.userInteractionEnabled = NO;
    self.settingBtn.userInteractionEnabled = NO;
    self.recordBtn.userInteractionEnabled = NO;
    self.recordBtn.selected = NO;// 停止录像
    [self.encoder stopRecord];
    self.reverseBtn.userInteractionEnabled = NO;
    self.screenBtn.userInteractionEnabled = NO;
//    [self performSelector:@selector(resetPushBtn) withObject:self afterDelay:15];
    // 获取联网状态
    __weak typeof(self)weakSelf = self;
    CTCellularData *cellularData = [[CTCellularData alloc] init];
    cellularData.cellularDataRestrictionDidUpdateNotifier = ^(CTCellularDataRestrictedState state) {
        if (state == kCTCellularDataRestricted || state == kCTCellularDataRestrictedStateUnknown) {
            [self.encoder stopCamera];
            [weakSelf showAuthorityView];
            return ;
        }
    };
    
    self.pushBtn.selected = !self.pushBtn.selected;
    if (self.pushBtn.selected) {
        self.settingBtn.enabled = NO;
        self.infoBtn.enabled = NO;
        
        dispatch_queue_t queue = dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL);
        dispatch_async(queue, ^{
            [self.encoder startCamera:[URLTool gainURL]];
        });
    } else {
        self.settingBtn.enabled = YES;
        self.infoBtn.enabled = YES;
        
        dispatch_queue_t queue = dispatch_queue_create("stopCamera", DISPATCH_QUEUE_SERIAL);
        dispatch_async(queue, ^{
            [self.encoder stopCamera];
        });
    }
}

- (IBAction)screenLive:(id)sender {
    if (@available(iOS 12.0, *)) {
        for (UIView *view in _broadPickerView.subviews) {
            if ([view isKindOfClass:[UIButton class]]) {
                [(UIButton*)view sendActionsForControlEvents:UIControlEventTouchDown];
            }
        }
    } else if (@available(iOS 11.0, *)) {
        // TODO 教程
    } else {
        [WHToast showMessage:@"您的手机系统版本低于11.0，无法进行屏幕录制操作，请升级手机系统" duration:2 finishHandler:nil];
    }
}

// 录像
- (IBAction)record:(id)sender {
    if ([self.statusLabel.text isEqualToString:@"连接中"]) return;
    
    self.recordBtn.selected = !self.recordBtn.selected;
    
//    self.pushBtn.selected = NO;
    self.pushBtn.userInteractionEnabled = YES;
    self.reverseBtn.userInteractionEnabled = YES;
    self.screenBtn.userInteractionEnabled = YES;
    
    if (self.recordBtn.selected) {
        [self.encoder startRecord];
    } else {
        [self.encoder stopRecord];
    }
}

// 设置
- (IBAction)setting:(id)sender {
    if ([self.statusLabel.text isEqualToString:@"连接中"]) return;
    if (self.encoder.running) {
        return;
    }
    self.pushBtn.selected = NO;
    self.pushBtn.userInteractionEnabled = YES;
    self.reverseBtn.userInteractionEnabled = YES;
    self.screenBtn.userInteractionEnabled = YES;
    SettingViewController *controller = [[SettingViewController alloc] initWithStoryboard];
    controller.delegate = self;
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - network

- (void)showAuthorityView {
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NetNotifieViewController *vc = [[NetNotifieViewController alloc] initWithStoryboard];
            [weakSelf basePushViewController:vc];
        });
    });
}

//黑屏
- (IBAction)turnAction:(UIButton *)sender {
    if ([self.statusLabel.text isEqualToString:@"连接中"]) return;

    self.statusHiden = YES;
    self.backGroundView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
       UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap)];
      
    [tap setNumberOfTapsRequired:2];
  
    self.backGroundView.backgroundColor = [UIColor blackColor];
       [self.backGroundView addGestureRecognizer:tap];
     
    [[UIApplication sharedApplication].keyWindow addSubview:self.backGroundView];
    // 刷新状态栏
    [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
     
}
- (void)tap {
    self.statusHiden = NO;
    [self.backGroundView removeFromSuperview];
    // 刷新状态栏
    [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
}
#pragma saveKeySucess
- (void)saveKeySucess:(NSNotification *)no {
    //初始化
    // 推流器
    self.encoder = [[CameraEncoder alloc] init];
    self.encoder.delegate = self;
    
    int days = [self.encoder initCameraWithOutputSize:[self captureSessionSize] resolution:[self captureSessionPreset]];
    self.encoder.previewLayer.frame = CGRectMake(0, 0, EasyScreenWidth, EasyScreenHeight);
    self.encoder.orientation = AVCaptureVideoOrientationPortrait;
    [self.contentView.layer addSublayer:self.encoder.previewLayer];
    
    // 保存key有效期
    [URLTool setActiveDay:days];
    if (days >= 9999) {
        [self.infoBtn setImage:[UIImage imageNamed:@"version1"] forState:UIControlStateNormal];
    } else if (days > 0) {
        [self.infoBtn setImage:[UIImage imageNamed:@"version2"] forState:UIControlStateNormal];
    } else {
        [self.infoBtn setImage:[UIImage imageNamed:@"version3"] forState:UIControlStateNormal];
    }
    
    self.prev = self.encoder.previewLayer;
    [[self.prev connection] setVideoOrientation:AVCaptureVideoOrientationPortrait];
    self.prev.frame = CGRectMake(0, 0, EasyScreenWidth, EasyScreenHeight);
    
    self.encoder.previewLayer.hidden = NO;
    [self.encoder startCapture];
    [self.encoder changeCameraStatus:[URLTool gainOnlyAudio]];
    
    [self.resolutionBtn setTitle:[NSString stringWithFormat:@"分辨率：%@", [URLTool gainResolition]] forState:UIControlStateNormal];
}

- (BOOL)prefersHomeIndicatorAutoHidden{
    return YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
