//
//  LocalPhotos.h
//  Go Angel
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "AppDelegate.h"
#import "CoreDataWrapper.h"
#import "AccountDataWrapper.h"

@interface LocalLibrary : NSObject {
  AccountDataWrapper *account;
  ALAssetsLibrary *assetLibrary;
  
  // lock to make asset library loading syncrounous
  NSConditionLock* readLock;
}

@property (nonatomic, strong) CoreDataWrapper *dataWrapper;
@property (nonatomic, strong) NSMutableArray *allowedAlbums;

// callback to call when photo gets added to core data
@property (nonatomic, copy) void(^addCallback)();

- (void) loadLocalImages: (BOOL) parseAll;
- (void) loadLocalImages: (BOOL) parseAll addCallback: (void (^) ()) addCallback;
- (void) loadAllowedAlbums;
- (void) registerForNotifications;
- (void) unRegisterForNotifications;

@end
