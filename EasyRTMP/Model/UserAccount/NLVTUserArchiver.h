//
//  NLVTUserArchiver.h
//  VTAP
//
//  Created by 王明申 on 2020/1/19.
//  Copyright © 2020 Nebula Link. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NLVTUserAccount.h"

NS_ASSUME_NONNULL_BEGIN

///用户数据存储工具
@interface NLVTUserArchiver : NSObject

///实例化
+ (instancetype)shareInstance;

///存储当前用户数据
- (BOOL)saveUserAccount:(NLVTUserAccount *)userAccount;

///读取当前用户数据
- (NLVTUserAccount *)readUserAccount;

///清空当前用户数据
- (BOOL)clearUserAccount;

///存储key
- (BOOL)saveKey:(NSString *)key;

///读取key
- (NSString *)readUserAKey;

///清空key
- (BOOL)clearKey;

@end

NS_ASSUME_NONNULL_END
