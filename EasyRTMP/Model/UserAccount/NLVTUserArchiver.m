//
//  NLVTUserArchiver.m
//  VTAP
//
//  Created by 王明申 on 2020/1/19.
//  Copyright © 2020 Nebula Link. All rights reserved.
//

#import "NLVTUserArchiver.h"

#define accountPath [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] //获取Document文件路径
#define accountAppendPath @"userAccount" //用户拼接路径
#define accountFilePath [accountPath stringByAppendingPathComponent:accountAppendPath] //用户数据存储路径

#define keyAppendPath @"userAccountKey" //key拼接路径
#define keyFilePath [accountPath stringByAppendingPathComponent:keyAppendPath] //key数据存储路径

@interface NLVTUserArchiver()<NSCopying,NSMutableCopying>

@end

static NLVTUserArchiver *manager = nil;

@implementation NLVTUserArchiver

///实例化
+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc]init];
    });
    return manager;
}

///存储当前用户数据
- (BOOL)saveUserAccount:(NLVTUserAccount *)userAccount {
    //归档
    if([[NSFileManager defaultManager] fileExistsAtPath:accountFilePath]) {//先将该地址存在的文件删除，再存储。
        NSError *error    = nil;
        if(![[NSFileManager defaultManager] removeItemAtPath:accountFilePath error:&error]) {
            NSLog(@"Cannot remove file: %@", error);
        }
    }
    return [NSKeyedArchiver archiveRootObject:userAccount toFile:accountFilePath];
}

///读取当前用户数据
- (NLVTUserAccount *)readUserAccount {
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    if ([defaultManager isDeletableFileAtPath:accountFilePath]) return [NSKeyedUnarchiver unarchiveObjectWithFile:accountFilePath];
    return nil;
}

///清空当前用户数据
- (BOOL)clearUserAccount {
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    if ([defaultManager isDeletableFileAtPath:accountFilePath]) return [defaultManager removeItemAtPath:accountFilePath error:nil];//删除归档文件
    return NO;
}

///存储key
- (BOOL)saveKey:(NSString *)key {
    //归档
    if([[NSFileManager defaultManager] fileExistsAtPath:keyFilePath]) {//先将该地址存在的文件删除，再存储。
        NSError *error    = nil;
        if(![[NSFileManager defaultManager] removeItemAtPath:keyFilePath error:&error]) {
            NSLog(@"Cannot remove file: %@", error);
        }
    }
    return [NSKeyedArchiver archiveRootObject:key toFile:keyFilePath];
}

///读取key
- (NSString *)readUserAKey {
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    if ([defaultManager isDeletableFileAtPath:keyFilePath]) return [NSKeyedUnarchiver unarchiveObjectWithFile:keyFilePath];
    return nil;
}

///清空key
- (BOOL)clearKey {
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    if ([defaultManager isDeletableFileAtPath:keyFilePath]) return [defaultManager removeItemAtPath:keyFilePath error:nil];//删除归档文件
    return NO;
}


#pragma mark ==============

///重写AllocWithZone,防止调用alloc方法时manager不是同一对象
+ (id)allocWithZone:(struct _NSZone *)zone{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [super allocWithZone:zone];
    });
    return manager;
}

///防止调用了copy，实现NSCopying协议
- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return manager;
}

///防止调用了mutableCopy，实现NSMutableCopying协议
- (nonnull id)mutableCopyWithZone:(nullable NSZone *)zone {
    return manager;
}

@end
