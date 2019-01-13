//
//  MMAppDotNetAPIClientl.m
//  MVVMDemo
//
//  Created by Insomnia on 2019/1/13.
//  Copyright © 2019 Insomnia. All rights reserved.
//

#import "MMAppDotNetAPIClient.h"


@implementation MMAppDotNetAPIClient

+ (instancetype)sharedClient {

  static MMAppDotNetAPIClient *_sharedClient = nil;
  static dispatch_once_t once;
  dispatch_once(&once, ^ {
      _sharedClient = [MMAppDotNetAPIClient new];
      _sharedClient.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
  });

  return _sharedClient;
}

@end
