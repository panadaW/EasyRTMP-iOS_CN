//
//  NLVTBaseRequest.m
//  VTAP
//
//  Created by 王明申 on 2020/1/2.
//  Copyright © 2020 Nebula Link. All rights reserved.
//

#import "NLVTBaseRequest.h"

@interface NLVTBaseRequest()

@end

@implementation NLVTBaseRequest

#pragma mark - 初始化
+ (instancetype)requestWithParam:(NLVTRequestParam *)param
                requestProgress:(RequestProgressBlock)progress
                  requestFinish:(RequestFinishBlock)finish
                   requestFailed:(RequestFailedBlock)failed {
    id request = [[[self class] alloc] initWithParam:param requestProgress:progress requestUpload:nil requestFinish:finish requestFailed:failed];
    [(NLVTBaseRequest *)request beginRequest];
    return request;
}

+ (instancetype)requestWithParam:(NLVTRequestParam *)param
         requestProgress:(RequestProgressBlock)progress
                   requestUpload:(RequestUploadDataBlock)upload
           requestFinish:(RequestFinishBlock)finish
                   requestFailed:(RequestFailedBlock)failed {
    id request = [[[self class] alloc] initWithParam:param requestProgress:progress requestUpload:upload requestFinish:finish requestFailed:failed];
    [(NLVTBaseRequest *)request beginRequest];
    return request;
}

- (instancetype)initWithParam:(NLVTRequestParam *)param
             requestProgress:(RequestProgressBlock)progress
                requestUpload:(RequestUploadDataBlock)upload
               requestFinish:(RequestFinishBlock)finish
               requestFailed:(RequestFailedBlock)failed{
    if (self = [super init]) {
        if (param && [param isKindOfClass:[NLVTRequestParam class]]) _params = param;
        if (progress) _progressBlock = progress;
        if (upload) _uploadBlock = upload;
        if (finish) _finishBlock = finish;
        if (failed) _failedBlock = failed;
    }
    return self;
}

///准备建立连接
- (void)beginRequest {
    //获取baseUrl
    _baseUrl = [self configureBaseUrl];
    //获取url
    _url = [self configureUrl];
    //获取请求类型
    _requestType = [self configureRequestType];
    ///响应类型
    _responseType = [self configureResponseType];
    //获取请求方法
    _requestMethod = [self configureRequestMethod];
    //获取请求头
    NSDictionary *dic = [self configureHeader];
    if (dic && [dic isKindOfClass:[NSDictionary class]]) {
        _header = [NSMutableDictionary dictionaryWithDictionary:dic];
    }else{
        _header = nil;
    }
    //拼接 baseUrl 和 Url
    if ([_baseUrl hasSuffix:@"/"]) _baseUrl = [_baseUrl substringWithRange:NSMakeRange(0, _baseUrl.length - 1)];
    if ([_url hasPrefix:@"/"]) _url = [_url substringWithRange:NSMakeRange(1, _url.length - 1)];
    _totalUrl = [NSString stringWithFormat:@"%@/%@",_baseUrl,_url];
    //请求超时时间
    self.timeoutInterval = [self configureTimeoutInterval];
    self.task = [self sendRequest];
}

///开始连接
- (NSURLSessionTask *)sendRequest {
    AFHTTPSessionManager *sessionManager = [AFHTTPSessionManager manager];
    switch (self.requestType) {
        case RequestTypeForm:{
            sessionManager.requestSerializer = [AFHTTPRequestSerializer serializer];
        }break;
        case RequestTypeJson:{
            sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
        }break;
        default:break;
    }
    switch (self.responseType) {
        case ResponseTypeForm:{
            sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        }break;
        case ResponseTypeJson:{
            sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
        }break;
        default:break;
    }
    sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/soap+xml",@"application/json",@"text/plain",@"text/json", @"text/javascript",@"text/html",nil];
    sessionManager.requestSerializer.timeoutInterval = self.timeoutInterval;
    if (self.header && [self.header isKindOfClass:[NSDictionary class]]) {
        NSArray *keys = self.header.allKeys;
        for (NSString *key in keys) {
            NSString *value = [self.header objectForKey:key];
            [sessionManager.requestSerializer setValue:value
                                    forHTTPHeaderField:key];
        }
    }
    NSString *enUrl = @"";
    enUrl = [self.totalUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    __block NSURLSessionTask *sessionTask = nil;
    if (self.requestMethod == RequestMethodGet) {
        sessionTask = [sessionManager GET:enUrl parameters:self.params.param progress:^(NSProgress * _Nonnull downloadProgress) {
            if (self.progressBlock) self.progressBlock(downloadProgress);
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if (self.finishBlock) self.finishBlock(task, responseObject);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            if (self.failedBlock) self.failedBlock(task, error);
        }];
    }
    if (self.requestMethod == RequestMethodPost) {
        sessionTask = [sessionManager POST:enUrl parameters:self.params.param progress:^(NSProgress * _Nonnull uploadProgress) {
            if (self.progressBlock) self.progressBlock(uploadProgress);
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if (self.finishBlock) self.finishBlock(task, responseObject);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            if (self.failedBlock) self.failedBlock(task, error);
        }];
    }
    if (self.requestMethod == RequestMethodUploadPost) {
        sessionTask = [sessionManager POST:enUrl parameters:self.params.param constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            if (self.uploadBlock) self.uploadBlock(formData);
        } progress:^(NSProgress * _Nonnull uploadProgress) {
            if (self.progressBlock) self.progressBlock(uploadProgress);
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if (self.finishBlock) self.finishBlock(task, responseObject);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            if (self.failedBlock) self.failedBlock(task, error);
        }];
    }
    if (self.requestMethod == RequestMethodPut) {
        sessionTask = [sessionManager PUT:enUrl parameters:self.params.param success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if (self.finishBlock) self.finishBlock(task, responseObject);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            if (self.failedBlock) self.failedBlock(task, error);
        }];
    }
    if (self.requestMethod == RequestMethodDelete) {
        sessionTask = [sessionManager DELETE:enUrl parameters:self.params.param success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if (self.finishBlock) self.finishBlock(task, responseObject);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            if (self.failedBlock) self.failedBlock(task, error);
        }];
    }
    
    return sessionTask;
}

#pragma mark - 配置信息
///配置请求方式
- (RequestType)configureRequestType {
    return RequestTypeJson;
}

///配置响应方式
- (ResponseType)configureResponseType {
    return ResponseTypeJson;
}

///配置请求方法
- (RequestMethod)configureRequestMethod {
    return RequestMethodGet;
}

///配置baseUrl
- (NSString *)configureBaseUrl {
    return @"http://zc.xun365.net/WebService";//云端
}

///配置url
- (NSString *)configureUrl {
    return self.params.url;
}

///配置请求头
- (NSDictionary *)configureHeader {
    return @{};
}

///配置请求超时时间,默认30s
- (NSTimeInterval)configureTimeoutInterval {
    return 30.0;
}

@end
