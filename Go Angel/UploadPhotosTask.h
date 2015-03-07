//
//  UploadPhotosTask.h
//  Go Arch
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>
#import "CSPhoto.h"
#import "CoreDataWrapper.h"
#import "AppDelegate.h"


// custom class to just handle the photo upload
// used by the coinsorter class
// needed to be split up because we need custom delegate methods

@interface UploadPhotosTask : NSObject <NSURLSessionTaskDelegate> {
  ALAssetsLibrary *assetLibrary;
  
  // lock to make asset library loading syncrounous
  NSConditionLock* readLock;
}

- (id) initWithWrapper: (CoreDataWrapper *) wrap;
//- (void) uploadPhotoArray: (NSMutableArray *) photos upCallback: (void (^) ()) upCallback;

// url session
@property (nonatomic, strong) NSURLSession *session;

// callback to call after each photo gets uploaded
@property (nonatomic, copy) void(^upCallback)();

@property (nonatomic, copy) void(^fullPhotoCallback)();


// array of photos currently being uploaded
@property (nonatomic) NSMutableArray *uploadingPhotos;
// need reference to a data wrapper so we can change photo state when we download, upload, etc.
@property CoreDataWrapper *dataWrapper;

//- (void)uploadVideoThumb:(NSMutableArray *)photo upCallback:(void (^)())upCallback;
- (void)uploadPhotoThumb:(NSMutableArray *)photos upCallback:(void (^)())upCallback;

-(void)uploadOnePhoto:(CSPhoto *)p upCallback:(void (^)())upCallback;
- (void)uploadOneThumb:(CSPhoto *)photo upCallback:(void (^)())upCallback;

@end
