//
//  URLTool.m
//  EasyRTMP
//
//  Created by mac on 2018/7/9.
//  Copyright © 2018年 phylony. All rights reserved.
//

#import "URLTool.h"
#import "X264Encoder.h"

static NSString *ConfigUrlKey = @"ConfigUrl";
static NSString *ResolitionKey = @"resolition";
static NSString *OnlyAudioKey = @"OnlyAudioKey";
static NSString *X264Encoder1 = @"X264Encoder1";
static NSString *activeDay = @"activeDay";

static NSString *ExtensionSuiteName = @"group.com.rtmp";

@implementation URLTool

#pragma mark - url

+ (void) saveURL:(NSString *)url {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:url forKey:ConfigUrlKey];
    [defaults synchronize];
    
    [[[NSUserDefaults alloc] initWithSuiteName:ExtensionSuiteName] setValue:url forKey:ConfigUrlKey];
}

+ (NSString *) gainURL {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *url = [defaults objectForKey:ConfigUrlKey];
    // 设置默认url
    if (!url || [url isEqualToString:@""] || [url containsString:@"www.easydss"] || [url containsString:@"cloud.easydarwin"]) {
        //rtmp://172.31.79.45:10085/hls/W01?sign=HGsl4uzGR
        url = @"rtmp://live-push.bilivideo.com/live-bvc/?streamname=live_396731842_81355915&key=2a1cf08b6ec73a01a16c9fa9d8feed10";
    }

    return url;
}

#pragma mark - resolition

+ (void) saveResolition:(NSString *)resolition {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:resolition forKey:ResolitionKey];
    [defaults synchronize];
}

+ (NSString *)gainResolition {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *resolition = [defaults objectForKey:ResolitionKey];
    
    // 设置默认分辨率
    if (!resolition || [resolition isEqualToString:@""]) {
        [self saveResolition:@"720*1280"];
    }
    
    return resolition;
}

#pragma mark - only audio

+ (void) saveOnlyAudio:(BOOL) isAudio {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:isAudio forKey:OnlyAudioKey];
    [defaults synchronize];
}

+ (BOOL) gainOnlyAudio {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:OnlyAudioKey];
}

#pragma mark - 编码方式：是否是X264软编码

+ (void) saveX264Enxoder:(BOOL) value {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:value forKey:X264Encoder1];
    [defaults synchronize];
}

+ (BOOL) gainX264Enxoder {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:X264Encoder1];
}

+ (CGFloat) getX264EnxoderRate {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    X264Encoder *encode = [defaults objectForKey:X264Encoder1];
    return encode.frameRate;
}

#pragma mark - key有效期

+ (void) setActiveDay:(int)value {
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:activeDay];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (int) activeDay {
    return (int)[[NSUserDefaults standardUserDefaults] integerForKey:activeDay];
}

@end
