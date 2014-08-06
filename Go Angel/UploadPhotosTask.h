//
//  UploadPhotosTask.h
//  Go Angel
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "CSPhoto.h"
#import "CoreDataWrapper.h"
#import "AppDelegate.h"

@interface UploadPhotosTask : NSObject <NSURLSessionTaskDelegate> {
  ALAssetsLibrary *assetLibrary;
  
  // lock to make asset library loading syncrounous
  NSConditionLock* readLock;
}

- (id) initWithWrapper: (CoreDataWrapper *) wrap;
- (void) uploadPhotoArray: (NSMutableArray *) photos upCallback: (void (^) ()) upCallback;

// url session
@property (nonatomic, strong) NSURLSession *session;

// callback to call after each photo gets uploaded
@property (nonatomic, copy) void(^upCallback)();

// array of photos currently being uploaded
@property (nonatomic) NSMutableArray *uploadingPhotos;
// need reference to a data wrapper so we can change photo state when we download, upload, etc.
@property CoreDataWrapper *dataWrapper;

@end
