//
//  MMFoldingTabBarControllerConfig.h
//  MVVMDemo
//
//  Created by Insomnia on 2019/1/7.
//  Copyright © 2019 Insomnia. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <YALFoldingTabBarController.h>
#import <YALTabBarItem.h>
#import <YALAnimatingTabBarConstants.h>
NS_ASSUME_NONNULL_BEGIN

@interface MMFoldingTabBarControllerConfig : NSObject
@property (nonatomic, strong, readonly) YALFoldingTabBarController *foldingTabBarController;
@end

NS_ASSUME_NONNULL_END
