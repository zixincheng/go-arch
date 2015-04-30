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
#import "CoreDataWrapper.h"
#import "Reachability.h"
#import "Coinsorter.h"
#import "NetWorkCheck.h"

@class Coinsorter;
@class NetWorkCheck;
@class UploadPhotosTask;

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    NSString *relinkUserId;
}

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) AccountDataWrapper *account;

@property (strong, nonatomic) CoreDataWrapper *dataWrapper;

@property (strong, nonatomic) Coinsorter *coinsorter;

@property (strong, nonatomic) NetWorkCheck *netWorkCheck;

@property (strong, nonatomic) UploadPhotosTask *uploadTask;
// media loader and image cache
@property (nonatomic, strong) MediaLoader *mediaLoader;

@property (nonatomic, copy) void(^backgroundTransferCompletionHandler)();

@property (nonatomic, strong) createDefaultAlbum *defaultAlbum;

@end
