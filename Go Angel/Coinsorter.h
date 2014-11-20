//
//  Coinsorter.h
//  Go Angel
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "CSDevice.h"
#import "CSPhoto.h"
#import "CSStorage.h"
#import "AccountDataWrapper.h"
#import "CoreDataWrapper.h"
#import "AppDelegate.h"
#import "SSKeychain.h"
#import "UploadPhotosTask.h"
#import <AssetsLibrary/AssetsLibrary.h>


// wrapper for calling the api
// this class makes api calls, parses the responses,
// and sends back the data in the format we need

@interface Coinsorter : NSObject <NSURLSessionDelegate> {
  AccountDataWrapper *account;
  UIBackgroundTaskIdentifier bgTask;
  UploadPhotosTask *uploadTask;
}

- (id) initWithWrapper: (CoreDataWrapper *) wrap;

- (void) getDevices: (void (^) (NSMutableArray *devices)) callback;
- (void) getStorages: (void (^) (NSMutableArray *storages)) callback;
- (void) getToken: (NSString *) ip pass: (NSString *) pass callback: (void (^) (NSDictionary *authData)) callback;
- (void) getPhotos: (int) lastId callback: (void (^) (NSMutableArray *devices)) callback;
- (void) uploadPhotos: (NSMutableArray *) photos upCallback: (void (^) ()) upCallback;
- (void) updateDevice;
- (void) pingServer: (void (^) (BOOL connected)) connectCallback;
- (void) getSid: (NSString *) ip infoCallback: (void (^) (NSData *data)) infoCallback;

// need reference to a data wrapper so we can change photo state when we download, upload, etc.
@property CoreDataWrapper *dataWrapper;

@end
