//
//  MMServerConfig.h
//  MVVMDemo
//
//  Created by Insomnia on 2019/1/14.
//  Copyright © 2019 Insomnia. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MMServerConfig : NSObject
/*!
 * 设置环境
 * @param value 0: 测试环境, 1: 生产环境
 */
+ (void)setMMConfigEnv:(NSString *)value;

 /*!
  * 获得环境
  * @return 返回环境
  */
+ (NSString *)MMConfigEnv;

/*!
 * 获取服务器地址
 * @return 服务器地址
 */
+ (NSString *)getMMServerAddr;
@end

NS_ASSUME_NONNULL_END
