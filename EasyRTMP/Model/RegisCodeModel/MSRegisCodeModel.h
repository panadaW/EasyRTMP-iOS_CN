//
//  MSRegisCodeModel.h
//  EasyRTMP
//
//  Created by 王明申 on 2020/7/26.
//  Copyright © 2020 phylony. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MSRegisCodeModel : NSObject

///注册码
@property (nonatomic,strong) NSString *RegisCode;

@property (nonatomic, strong) NSString *isImei;

@property (nonatomic, strong) NSString *Imei;

@property (nonatomic, strong) NSString *SoftwareId;

@property (nonatomic, strong) NSString *SoftwareType;

@property (nonatomic, strong) NSString *RegisCodeState;

#pragma mark 

@end

NS_ASSUME_NONNULL_END
