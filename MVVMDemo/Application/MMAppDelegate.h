//
// Created by Insomnia on 2019/1/7.
// Copyright (c) 2019 Insomnia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RealReachability.h>

@interface MMAppDelegate :UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
 /**
  *
  */
 @property(assign, nonatomic, readonly) ReachabilityStatus NetWorkStatus;
@end