//
// Created by Insomnia on 2019/1/7.
// Copyright (c) 2019 Insomnia. All rights reserved.
//

#import "MMAppDelegate.h"
#import "MMFoldingTabBarControllerConfig.h"
#import "IQKeyboardManager.h"

@interface MMAppDelegate ()

@end

@implementation MMAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [self setRootViewController];
    [self configurationIQKeyboard];
    [self configurationNetWorkStatus];

    return YES;
}


- (void)setRootViewController {
    self.window = [UIWindow new];
    self.window.frame = [UIScreen mainScreen].bounds;
    /*
     
     */
    MMFoldingTabBarControllerConfig *tabBarControllerConfig = [MMFoldingTabBarControllerConfig new];
    [self.window setRootViewController:tabBarControllerConfig.foldingTabBarController];

    [self.window makeKeyAndVisible];
}


- (void)configurationIQKeyboard {
    IQKeyboardManager *manager = [IQKeyboardManager sharedManager];
    manager.shouldResignOnTouchOutside = true;
    manager.shouldToolbarUsesTextFieldTintColor = true;
    manager.enableAutoToolbar = false;
}

- (void)configurationNetWorkStatus {
    [GLobalRealReachability startNotifier];
    RAC(self, NetWorkStatus) = [[[[[NSNotificationCenter defaultCenter]
            rac_addObserverForName:kRealReachabilityChangedNotification
                            object:nil]
            map:^id(NSNotification *noti) {
                return @([noti.object currentReachabilityStatus]);
            }] startWith:@([GLobalRealReachability
            currentReachabilityStatus])]
            distinctUntilChanged];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}
@end
