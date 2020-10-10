//
//  NLVTRequestParam.m
//  VTAP
//
//  Created by 王明申 on 2020/1/2.
//  Copyright © 2020 Nebula Link. All rights reserved.
//

#import "NLVTRequestParam.h"

@implementation NLVTRequestParam

- (instancetype)init {
    self = [super init];
    if (self) {
        _url = @"";
        _param = [[NSDictionary alloc] init];
    }
    return self;
}

/// 初始化
/// @param dic 请求参数
+ (instancetype)paramWithDictionary:(NSDictionary *)dic {
    NLVTRequestParam *param = [[NLVTRequestParam alloc]init];
    param.param = dic;
    return param;
}

@end
