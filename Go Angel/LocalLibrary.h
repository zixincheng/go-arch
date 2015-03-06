//
//  LocalPhotos.h
//  Go Arch
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "AppDelegate.h"
#import "CoreDataWrapper.h"
#import "AccountDataWrapper.h"
#import "createDefaultAlbum.h"
#import "CSLocation.h"

// class that manages getting photos from the ios photo library
// it registers for notifications for when the albums changes and
// can parse the entire photo directory, or just get the latest ones

@interface LocalLibrary : NSObject {
  AccountDataWrapper *account;
  ALAssetsLibrary *assetAlbumLibrary;
  
  // lock to make asset library loading syncrounous
  NSConditionLock* readLock;
  
  BOOL allPhotosSeleceted;
}

@property (nonatomic, strong) CoreDataWrapper *dataWrapper;
@property (nonatomic, strong) NSMutableArray *allowedAlbums;
@property (nonatomic, strong) createDefaultAlbum *defaultAlbum;
@property (nonatomic, assign) BOOL didAlbumCreated;
// callback to call when photo gets added to core data
@property (nonatomic, copy) void(^addCallback)();

- (void) loadLocalImages: (BOOL) parseAll;
- (void) loadLocalImages: (BOOL) parseAll addCallback: (void (^) ()) addCallback;
- (void) loadAllowedAlbums;
- (void) saveImage:(UIImage *)image metadata:(NSDictionary *)metadata location: (CSLocation *)location;
- (void) saveVideo: (NSURL *)moviePath location: (CSLocation *)location ;
- (void) registerForNotifications;
- (void) unRegisterForNotifications;

@end
