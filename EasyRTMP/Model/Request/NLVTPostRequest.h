//
//  NLVTPostRequest.h
//  VTAP
//
//  Created by 王明申 on 2020/1/2.
//  Copyright © 2020 Nebula Link. All rights reserved.
//

#import "NLVTBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLVTPostRequest : NLVTBaseRequest

/// 注册码认证
/// @param param 请求参数
/// @param progress 进度block
/// @param finish 请求完成block
/// @param failed 请求失败block
+ (instancetype)regisCodeRequestWithParam:(NLVTRequestParam *)param
                requestProgress:(RequestProgressBlock)progress
                  requestFinish:(RequestFinishBlock)finish
                  requestFailed:(RequestFailedBlock)failed;

/// 获取key值
/// @param param 请求参数
/// @param progress 进度block
/// @param finish 请求完成block
/// @param failed 请求失败block
+ (instancetype)appKeyRequestWithParam:(NLVTRequestParam *)param
                requestProgress:(RequestProgressBlock)progress
                  requestFinish:(RequestFinishBlock)finish
                  requestFailed:(RequestFailedBlock)failed;

/// 上报唯一标识
/// @param param 请求参数
/// @param progress 进度block
/// @param finish 请求完成block
/// @param failed 请求失败block
+ (instancetype)imeiRequestWithParam:(NLVTRequestParam *)param
                requestProgress:(RequestProgressBlock)progress
                  requestFinish:(RequestFinishBlock)finish
                  requestFailed:(RequestFailedBlock)failed;

@end

NS_ASSUME_NONNULL_END
