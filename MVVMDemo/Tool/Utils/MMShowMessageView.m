//
//  MMShowMessageView.m
//  MVVMDemo
//
//  Created by Insomnia on 2019/1/17.
//  Copyright © 2019 Insomnia. All rights reserved.
//

#import "MMShowMessageView.h"

#import <MMProgressHUD.h>

@interface MMShowMessageView ()
@end

@implementation MMShowMessageView
+ (void)showErrorWithMessage:(NSString *)message {
    [MMProgressHUD setPresentationStyle:MMProgressHUDPresentationStyleSwingRight];
    [MMProgressHUD setDisplayStyle:MMProgressHUDDisplayStyleBordered];
    [MMProgressHUD dismissWithError:nil title:message afterDelay:2.0];
}

+ (void)showSuccessWithMessage:(NSString *)message {
    [MMProgressHUD setPresentationStyle:MMProgressHUDPresentationStyleSwingRight];
    [MMProgressHUD setDisplayStyle:MMProgressHUDDisplayStyleBordered];
    [MMProgressHUD dismissWithSuccess:nil title:message afterDelay:2.0];
}

+ (void)showStatusWithMessage:(NSString *)message {
    [MMProgressHUD setPresentationStyle:MMProgressHUDPresentationStyleExpand];
    [MMProgressHUD showWithTitle:nil status:message];
}

+ (void)dismissSuccessView:(NSString *)message {
    [MMProgressHUD dismissWithSuccess:message];
}

+ (void)dismissErrorView:(NSString *)message {
    [MMProgressHUD dismissWithError:message];
}

@end
