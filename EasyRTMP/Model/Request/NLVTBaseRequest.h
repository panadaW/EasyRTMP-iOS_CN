//
//  NLVTBaseRequest.h
//  VTAP
//
//  Created by 王明申 on 2020/1/2.
//  Copyright © 2020 Nebula Link. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import "NLVTRequestParam.h"

NS_ASSUME_NONNULL_BEGIN

///请求方法,default=RequestMethodPost
typedef NS_ENUM(NSInteger,RequestMethod) {
    RequestMethodGet = 0,
    RequestMethodPost = 1,
    RequestMethodUploadPost = 2,//上传请求
    RequestMethodPut = 3,
    RequestMethodDelete = 4,
};

///请求方式,default=RequestTypeJson
typedef NS_ENUM(NSInteger,RequestType) {
    RequestTypeJson = 0,
    RequestTypeForm = 1,
};

///响应方式,default=ResponseTypeJson
typedef NS_ENUM(NSInteger,ResponseType) {
    ResponseTypeJson = 0,
    ResponseTypeForm = 1,
};

///请求成功的block
typedef void (^RequestFinishBlock)(NSURLSessionDataTask *task,id responseObject);

///请求失败的block
typedef void (^RequestFailedBlock)(NSURLSessionDataTask *task, NSError * error);

///进度block
 typedef void (^RequestProgressBlock)(NSProgress *progress);

///上传block
typedef void (^RequestUploadDataBlock)(id<AFMultipartFormData> formData);

/**
 网络请求基类
 */

@interface NLVTBaseRequest : NSObject

@property (nonatomic, strong) NSURLSessionTask  *task;

@property (nonatomic,   copy) RequestProgressBlock progressBlock;
@property (nonatomic,   copy) RequestUploadDataBlock uploadBlock;
@property (nonatomic,   copy) RequestFinishBlock finishBlock;
@property (nonatomic,   copy) RequestFailedBlock failedBlock;

///请求的url,最终会和baseUrl拼接
@property (nonatomic, strong) NSString *url;

///baseUrl,最终会和url拼接
@property (nonatomic, strong) NSString *baseUrl;

///baseUrl和url拼接
@property (nonatomic, strong) NSString *totalUrl;

///请求类型
@property (nonatomic) RequestType requestType;

///响应类型
@property (nonatomic) ResponseType responseType;

///请求方法
@property (nonatomic) RequestMethod requestMethod;

///请求头
@property (nonatomic, strong) NSMutableDictionary *header;

///请求参数
@property (nonatomic, strong) NLVTRequestParam *params;

///请求超时的时间
@property (nonatomic) NSTimeInterval timeoutInterval;

#pragma mark - 配置信息
///配置请求方式
- (RequestType)configureRequestType;

///配置响应方式
- (ResponseType)configureResponseType;

///配置请求方法
- (RequestMethod)configureRequestMethod;

///配置baseUrl
- (NSString *)configureBaseUrl;

///配置url
- (NSString *)configureUrl;

///配置请求头
- (NSDictionary *)configureHeader;

///配置请求超时时间,默认30s
- (NSTimeInterval)configureTimeoutInterval;


/// 基本的网络请求
/// @param param 请求参数
/// @param progress 进度block
/// @param finish 请求完成block
/// @param failed 请求失败block
+ (instancetype)requestWithParam:(NLVTRequestParam *)param
                requestProgress:(RequestProgressBlock)progress
                  requestFinish:(RequestFinishBlock)finish
                  requestFailed:(RequestFailedBlock)failed;

/// 上传的网络请求
/// @param param 请求参数
/// @param progress 进度block
/// @param upload 上传block
/// @param finish 请求完成block
/// @param failed 请求失败block
+ (instancetype)requestWithParam:(NLVTRequestParam *)param
                requestProgress:(RequestProgressBlock)progress
                   requestUpload:(RequestUploadDataBlock)upload
                  requestFinish:(RequestFinishBlock)finish
                  requestFailed:(RequestFailedBlock)failed;

@end

NS_ASSUME_NONNULL_END
