//
//  AppDelegate.h
//  Go Angel
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import <UIKit/UIKit.h>
#import "AccountDataWrapper.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong) AccountDataWrapper *account;

@property (nonatomic, copy) void(^backgroundTransferCompletionHandler)();

@end
