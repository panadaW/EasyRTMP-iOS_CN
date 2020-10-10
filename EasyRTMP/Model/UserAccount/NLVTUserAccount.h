//
//  NLVTUserAccount.h
//  VTAP
//
//  Created by 王明申 on 2020/1/16.
//  Copyright © 2020 Nebula Link. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

///用户信息
@interface NLVTUserAccount : NSObject

///注册码
@property (nonatomic,strong) NSString *regisCode;

//用户标识
@property (nonatomic, strong) NSString *signId;

//ip
@property (nonatomic, strong) NSString *ip;

//port
@property (nonatomic, strong) NSString *port;



@end

NS_ASSUME_NONNULL_END
