//
//  MMAppDotNetAPIClientl.h
//  MVVMDemo
//
//  Created by Insomnia on 2019/1/13.
//  Copyright © 2019 Insomnia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

@interface MMAppDotNetAPIClient : AFHTTPSessionManager
+ (instancetype)sharedClient;
@end
