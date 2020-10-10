//
//  NLVTPostRequest.m
//  VTAP
//
//  Created by 王明申 on 2020/1/2.
//  Copyright © 2020 Nebula Link. All rights reserved.
//

#import "NLVTPostRequest.h"
#import "NLVTUserArchiver.h"

@implementation NLVTPostRequest

+ (instancetype)regisCodeRequestWithParam:(NLVTRequestParam *)param
                           requestProgress:(RequestProgressBlock)progress
                             requestFinish:(RequestFinishBlock)finish
                             requestFailed:(RequestFailedBlock)failed {
    param.url = @"/SoftWare.asmx/GetRegisCodeInfo_NoPhoneMessage";
    return [self requestWithParam:param requestProgress:progress requestFinish:finish requestFailed:failed];
}


+ (instancetype)appKeyRequestWithParam:(NLVTRequestParam *)param
                requestProgress:(RequestProgressBlock)progress
                  requestFinish:(RequestFinishBlock)finish
                         requestFailed:(RequestFailedBlock)failed {
    param.url = @"/SoftWare.asmx/GetAllSoftWareInfo";
    return [self requestWithParam:param requestProgress:progress requestFinish:finish requestFailed:failed];
}

/// 上报唯一标识
/// @param param 请求参数
/// @param progress 进度block
/// @param finish 请求完成block
/// @param failed 请求失败block
+ (instancetype)imeiRequestWithParam:(NLVTRequestParam *)param
                requestProgress:(RequestProgressBlock)progress
                  requestFinish:(RequestFinishBlock)finish
                       requestFailed:(RequestFailedBlock)failed {
    param.url = @"/RegisCode.asmx/SetRegiCodeImei";
    return [self requestWithParam:param requestProgress:progress requestFinish:finish requestFailed:failed];
                       }

///配置请求方式
- (RequestType)configureRequestType {
    return RequestTypeForm;
}

@end
