//
//  MMServerConfig.m
//  MVVMDemo
//
//  Created by Insomnia on 2019/1/14.
//  Copyright © 2019 Insomnia. All rights reserved.
//

#import "MMServerConfig.h"
static NSString *MMConfigEnv; //环境参数 0: 测试环境 1: 生产环境
@implementation MMServerConfig

+ (void)setMMConfigEnv:(NSString *)value {
    MMConfigEnv = value;
}

+ (NSString *)MMConfigEnv {
    return MMConfigEnv;
}

+ (NSString *)getMMServerAddr {
    if ([MMConfigEnv isEqualToString:@"0"]) {
        return MMURL_Test;
    } else {
        return MMURL;
    }
}

@end
