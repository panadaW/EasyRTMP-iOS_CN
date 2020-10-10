//
//  NLVTRequestParam.h
//  VTAP
//
//  Created by 王明申 on 2020/1/2.
//  Copyright © 2020 Nebula Link. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

///请求参数
@interface NLVTRequestParam : NSObject

///请求参数
@property (nonatomic, strong)NSDictionary *param;

///请求的url
@property (nonatomic, strong) NSString *url;

/// 初始化
/// @param dic 请求参数
+ (instancetype)paramWithDictionary:(NSDictionary *)dic;
@end

NS_ASSUME_NONNULL_END
