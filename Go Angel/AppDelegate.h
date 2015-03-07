//
//  AppDelegate.h
//  Go Arch
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import <UIKit/UIKit.h>
#import "AccountDataWrapper.h"
#import "MediaLoader.h"
#import "createDefaultAlbum.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) AccountDataWrapper *account;

// media loader and image cache
@property (nonatomic, strong) MediaLoader *mediaLoader;

@property (nonatomic, copy) void(^backgroundTransferCompletionHandler)();

@property (nonatomic, strong) createDefaultAlbum *defaultAlbum;

@end
