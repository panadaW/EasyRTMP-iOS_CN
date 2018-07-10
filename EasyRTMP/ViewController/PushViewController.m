//
//  ViewController.m
//  EasyCapture
//
//  Created by lyy on 9/7/18.
//  Copyright © 2018 lyy. All rights reserved.
//

#import "PushViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreTelephony/CTCellularData.h>
#import "ResolutionViewController.h"
#import "SettingViewController.h"
#import "InfoViewController.h"
#import "NoNetNotifieViewController.h"
#import "URLTool.h"
#import "CameraEncoder.h"

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
@property (weak, nonatomic) IBOutlet UIButton *recordBtn;
@property (weak, nonatomic) IBOutlet UIButton *settingBtn;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@property (nonatomic, strong) CameraEncoder *encoder;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *prev;

@end

@implementation PushViewController

- (instancetype) initWithStoryboard {
    return [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"PushViewController"];
}

#pragma mark - init

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // UI
    [self setUI];
    
    // 推流器
    self.encoder = [[CameraEncoder alloc] init];
    self.encoder.delegate = self;
    [self.encoder initCameraWithOutputSize:CGSizeMake(HRGScreenWidth, HRGScreenHeight)];
    self.encoder.previewLayer.frame = CGRectMake(0, 0, HRGScreenWidth, HRGScreenHeight);
    [self.contentView.layer addSublayer:self.encoder.previewLayer];
    
    self.prev = self.encoder.previewLayer;
    [[self.prev connection] setVideoOrientation:AVCaptureVideoOrientationPortrait];
    self.prev.frame = CGRectMake(0, 0, HRGScreenWidth, HRGScreenHeight);
    
    self.encoder.previewLayer.hidden = NO;
    [self.encoder startCapture];
    [self.encoder changeCameraStatus];
    
    // 根据应用生命周期的通知来设置推流器
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(someMethod:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(someMethod:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    self.statusLabel.text = [NSString stringWithFormat:@"断开链接\n%@", [URLTool gainURL]];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = YES;
    
    // 设置窗口亮度大小  范围是0.1 - 1.0
    [[UIScreen mainScreen] setBrightness:0.8];
    // 设置屏幕常亮
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    [self.resolutionBtn setTitle:[NSString stringWithFormat:@"分辨率：%@", [URLTool gainResolition]] forState:UIControlStateNormal];
    
    // TODO
    
    CGSize size = CGSizeMake(HRGScreenWidth, HRGScreenHeight);
    int bt = (int)(size.width * size.height * 20 * 2 * 0.04f);
    if (size.width >= 1920 || size.height >= 1920) {
        bt *= 0.3;
    } else if (size.width >= 1280 || size.height >= 1280) {
        bt *= 0.4;
    } else if (size.width >= 720 || size.height >= 720) {
        bt *= 0.6;
    }
    
    // @"帧率:20 码率:100Kbps"
    self.bitrateLabel.text = [NSString stringWithFormat:@"码率:%.0fKbps", bt / 1000.0];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    self.navigationController.navigationBarHidden = NO;
}

#pragma mark - UI

- (void)setUI {
    self.topViewMarginTop.constant = HRGBarHeight + 10;
    self.mainViewWidth.constant = HRGScreenWidth;
    self.mainViewHeight.constant = HRGScreenHeight;
    
    [self.resolutionBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
    [self.resolutionBtn setTitleColor:UIColorFromRGB(ThemeColor) forState:UIControlStateHighlighted];
    [self.infoBtn setImage:[UIImage imageNamed:@"version"] forState:UIControlStateNormal];
    [self.infoBtn setImage:[UIImage imageNamed:@"version_click"] forState:UIControlStateHighlighted];
    [self.settingBtn setImage:[UIImage imageNamed:@"tab_setting"] forState:UIControlStateNormal];
    [self.settingBtn setImage:[UIImage imageNamed:@"tab_setting_click"] forState:UIControlStateHighlighted];
    [self.settingBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
    [self.settingBtn setTitleColor:UIColorFromRGB(ThemeColor) forState:UIControlStateHighlighted];
    
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
    
    [self.pushBtn setImageEdgeInsets:UIEdgeInsetsMake(-20, 20, 0, 0)];
    [self.pushBtn setTitleEdgeInsets:UIEdgeInsetsMake(24, -32, 0, 0)];
    [self.recordBtn setImageEdgeInsets:UIEdgeInsetsMake(-20, 20, 0, 0)];
    [self.recordBtn setTitleEdgeInsets:UIEdgeInsetsMake(24, -32, 0, 0)];
    [self.settingBtn setImageEdgeInsets:UIEdgeInsetsMake(-20, 20, 0, 0)];
    [self.settingBtn setTitleEdgeInsets:UIEdgeInsetsMake(24, -32, 0, 0)];
}

- (BOOL)prefersStatusBarHidden {
    if (self.screenBtn.selected) {
        return YES;
    } else {
        return NO;
    }
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
        }
    }
}

#pragma mark - SetDelegate

// 设置页面修改了分辨率后的操作
- (void)setFinish {
    [self.encoder changeCameraStatus];
}

#pragma mark - EasyResolutionDelegate

- (void)onSelecedesolution:(NSInteger)resolutionNo {
    [self.encoder swapResolution];
    [self.resolutionBtn setTitle:[NSString stringWithFormat:@"分辨率：%@", [URLTool gainResolition]] forState:UIControlStateNormal];
}

#pragma mark - ConnectDelegate

- (void)getConnectStatus:(NSString *)status isFist:(int)tag {
    if (tag == 1) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                self.statusLabel.text = [NSString stringWithFormat:@"%@", status];
            });
        });
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *url = [URLTool gainURL];
                self.statusLabel.text = [NSString stringWithFormat:@"%@\n%@", status, url];
                
                if ([status isEqualToString:@"推流中"]) {
                    self.pushBtn.selected = YES;
                    self.settingBtn.enabled = NO;
                    self.infoBtn.enabled = NO;
                    self.resolutionBtn.enabled = NO;
                    self.reverseBtn.enabled = NO;
                    self.screenBtn.enabled = NO;
                } else {
                    self.pushBtn.selected = NO;
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
//    dispatch_async(dispatch_get_main_queue(), ^{
//        NSString *t = [NSString stringWithFormat:@"  %dKB/s", length / 1024];
//        [_rateBtn setTitle:t forState:UIControlStateNormal];
//    });
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
    self.reverseBtn.selected = !self.reverseBtn.selected;
    [self.encoder swapFrontAndBackCameras];
}

// 横竖屏
- (IBAction)changeScreen:(id)sender {
    self.screenBtn.selected = !self.screenBtn.selected;
    
    NSString *resolution = [URLTool gainResolition];
    NSArray *resolutionArray = [resolution componentsSeparatedByString:@"*"];
    int width = [resolutionArray[0] intValue];
    int height = [resolutionArray[1] intValue];

    if (self.screenBtn.selected) {
        // UI 横屏
        self.mainViewWidth.constant = HRGScreenHeight;
        self.mainViewHeight.constant = HRGScreenWidth;
        self.mainView.transform = CGAffineTransformMakeRotation(M_PI_2);
        [self.mainView updateConstraintsIfNeeded];
        [self.mainView layoutIfNeeded];
        
        // 横屏推流
        self.encoder.orientation = AVCaptureVideoOrientationLandscapeRight;
        self.encoder.outputSize = CGSizeMake(height, width);
    } else {
        // UI 竖屏
        self.mainViewWidth.constant = HRGScreenWidth;
        self.mainViewHeight.constant = HRGScreenHeight;
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

// 推送
- (IBAction)push:(id)sender {
    __weak typeof(self)weakSelf = self;
    CTCellularData *cellularData = [[CTCellularData alloc]init];
    cellularData.cellularDataRestrictionDidUpdateNotifier = ^(CTCellularDataRestrictedState state) {
        // 获取联网状态
        switch (state) {
            case kCTCellularDataRestricted:
                NSLog(@"Restricrted");
//                [weakSelf showAuthorityView];
                break;
            case kCTCellularDataNotRestricted:
                NSLog(@"Not Restricted");
                break;
            case kCTCellularDataRestrictedStateUnknown: {
                [weakSelf showAuthorityView];
                return;
            }
                break;
            default:
                break;
        };
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
        
        [self.encoder stopCamera];
    }
}

// 录像
- (IBAction)record:(id)sender {
    self.recordBtn.selected = !self.recordBtn.selected;
    
    // TODO
}

// 设置
- (IBAction)setting:(id)sender {
    if (self.encoder.running) {
        return;
    }
    
    SettingViewController *controller = [[SettingViewController alloc] initWithStoryboard];
    controller.delegate = self;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)showAuthorityView {
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NoNetNotifieViewController *vc = [[NoNetNotifieViewController alloc] init];
            [weakSelf presentViewController:vc animated:YES completion:nil];
        });
    });
}

@end