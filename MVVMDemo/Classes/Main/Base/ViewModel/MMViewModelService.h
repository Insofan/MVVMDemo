//
//  MMViewModelService.h
//  MVVMDemo
//
//  Created by Insomnia on 2019/1/11.
//  Copyright © 2019 Insomnia. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "MMViewModelProtocolImpl.h"

@protocol MMViewModelService <NSObject>
// 获取首页服务
- (id <MMViewModelProtocolImpl>)getCityTravelService;
// 获取首页详情服务
- (id <MMViewModelProtocolImpl>)getCityTravelDetailService;
// 获取发现服务
- (id <MMViewModelProtocolImpl>)getFindService;
// 获取探索视频服务
- (id <MMViewModelProtocolImpl>)getExploreMoreService;

// 获取web服务
- (id <MMViewModelProtocolImpl>)getWebService;
@end
