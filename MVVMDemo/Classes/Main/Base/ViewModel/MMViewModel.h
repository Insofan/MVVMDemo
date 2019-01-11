//
//  MMViewModel.h
//  MVVMDemo
//
//  Created by Insomnia on 2019/1/10.
//  Copyright © 2019 Insomnia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMViewModelService.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MMNavBarStypeType) {
    kNavBarStyleNormal = 0,
    kNavBarStyleHidden = 1,
};

@interface MMViewModel : NSObject

/**
 * 数据请求
 */
@property(strong, nonatomic, readonly) RACCommand *requestDataCommand;

/**
 * 网络状态
 */
@property(assign, nonatomic) ReachabilityStatus   netWorkStatus;

/**
 * NavBar类型
 */
@property(assign, nonatomic, readonly) MMNavBarStypeType navBarStypeType;

/**
 * 标题
 */
@property(copy, nonatomic, readonly) NSString            *title;

/**
 * viewModel服务
 */
@property(strong, nonatomic, readonly) id <MMViewModelService> services;
@end

NS_ASSUME_NONNULL_END
