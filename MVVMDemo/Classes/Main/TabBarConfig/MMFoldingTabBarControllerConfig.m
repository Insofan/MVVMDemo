//
//  MMFoldingTabBarControllerConfig.m
//  MVVMDemo
//
//  Created by Insomnia on 2019/1/7.
//  Copyright © 2019 Insomnia. All rights reserved.
//

#import "MMFoldingTabBarControllerConfig.h"
#import "MMCityTravelNotesViewController.h"
#import "MMFindViewController.h"
@interface MMFoldingTabBarControllerConfig()
@property (nonatomic, strong, readwrite) YALFoldingTabBarController *foldingTabBarController;

//@property (strong, nonatomic) ;

@end

@implementation MMFoldingTabBarControllerConfig

- (YALFoldingTabBarController *)foldingTabBarController {
     /**
      * 使用懒加载宏
      */
    return MM_LAZY(_foldingTabBarController, ({
        YALFoldingTabBarController *tabBarVc = [YALFoldingTabBarController new];
        tabBarVc.viewControllers = [self viewControllersForController];
        [self customFoldingTabBarAppearance:tabBarVc];
        tabBarVc;
    }));
}

/**
  * 添加vc arr
  */
- (NSArray *)viewControllersForController {
    MMCityTravelNotesViewController *firVc = [MMCityTravelNotesViewController new];
    MMFindViewController *secVc = [MMFindViewController new];
    NSArray *vcArr = @[
                       firVc,
                       secVc
                       ];
    
    return vcArr;
}
/**
  * 设置图标等
  */
- (void)customFoldingTabBarAppearance:(YALFoldingTabBarController *)tabBarVc {
    YALTabBarItem *item1 = [[YALTabBarItem alloc] initWithItemImage:[UIImage imageNamed:@"nearby_icon"]
                                                      leftItemImage:nil
                                                     rightItemImage:nil];
    
    
    YALTabBarItem *item2 = [[YALTabBarItem alloc] initWithItemImage:[UIImage imageNamed:@"profile_icon"]
                                                      leftItemImage:nil
                                                     rightItemImage:nil];
    
    tabBarVc.leftBarItems = @[item1, item2];
    
    
//    YALTabBarItem *item3 = [[YALTabBarItem alloc] initWithItemImage:[UIImage imageNamed:@"chats_icon"]
//                                                      leftItemImage:nil
//                                                     rightItemImage:nil];
//
//
//    YALTabBarItem *item4 = [[YALTabBarItem alloc] initWithItemImage:[UIImage imageNamed:@"settings_icon"]
//                                                      leftItemImage:nil
//                                                     rightItemImage:nil];
//
//    tabBarVc.rightBarItems = @[item3, item4];
    
    tabBarVc.centerButtonImage = [UIImage imageNamed:@"plus_icon"];
    
    tabBarVc.selectedIndex = 0;
    
    
    tabBarVc.tabBarView.extraTabBarItemHeight = YALExtraTabBarItemsDefaultHeight;
    tabBarVc.tabBarView.offsetForExtraTabBarItems = YALForExtraTabBarItemsDefaultOffset;
    tabBarVc.tabBarView.tabBarColor = [UIColor hx_colorWithRGBNumber:80 green:189 blue:203];
    tabBarVc.tabBarViewHeight = YALTabBarViewDefaultHeight;
//    tabBarVc.tabBarView.tabBarViewEdgeInsets = UIEdgeInsetsMake(-15.0f, 15.0f, 10.0f, 15.0f);
//    tabBarVc.tabBarView.tabBarItemsEdgeInsets = UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f);
    tabBarVc.tabBarView.tabBarViewEdgeInsets = UIEdgeInsetsMake(-15.0f, 15.0f, 10.0f, 15.0f);
    tabBarVc.tabBarView.tabBarItemsEdgeInsets = UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f);
}
@end
