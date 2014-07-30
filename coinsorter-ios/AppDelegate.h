//
//  AppDelegate.h
//  coinsorter-ios
//
//  Created by Jake Runzer on 7/11/14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AccountDataWrapper.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong) AccountDataWrapper *account;

@property (nonatomic, copy) void(^backgroundTransferCompletionHandler)();

@end
