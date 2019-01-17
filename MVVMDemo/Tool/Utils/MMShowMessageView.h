//
//  MMShowMessageView.h
//  MVVMDemo
//
//  Created by Insomnia on 2019/1/17.
//  Copyright © 2019 Insomnia. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MMShowMessageView : NSObject
/**
 *  展示错误信息
 *
 *  @param message 信息内容
 */
+ (void)showErrorWithMessage:(NSString *)message;
/**
 *  展示成功信息
 *
 *  @param message 信息内容
 */
+ (void)showSuccessWithMessage:(NSString *)message;
/**
 *  展示提交状态
 *
 *  @param message 信息内容
 */
+ (void)showStatusWithMessage:(NSString *)message;
/**
 *  隐藏弹出框
 */
+ (void)dismissSuccessView:(NSString *)message;
+ (void)dismissErrorView:(NSString *)message;
@end

NS_ASSUME_NONNULL_END
