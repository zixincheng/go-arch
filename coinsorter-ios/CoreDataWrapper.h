//
//  coreDataWrapper.h
//  coinsorter-ios
//
//  Created by Jake Runzer on 7/15/14.
//  Copyright (c) 2014 Jake Runzer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "AppDelegate.h"
#import "CSDevice.h"
#import "CSPhoto.h"

@interface CoreDataWrapper : NSObject {
    // required for loading assets synchronously
    NSConditionLock *albumReadLock;
    
    dispatch_queue_t dbInsertQueue;
    dispatch_queue_t dbFetchQueue;
}

- (void) addPhoto: (CSPhoto *) photo asset: (ALAsset *) asset;
- (void) addPhoto: (CSPhoto *) photo;
- (void) addDevice: (CSDevice *) device;
- (void) addUpdatePhoto: (CSPhoto *) photo;
- (void) addUpdateDevice: (CSDevice *) device;
- (NSMutableArray *) getAllPhotos;
- (NSMutableArray *) getAllDevices;
- (NSMutableArray *) getPhotos: (NSString *) deviceId;
- (NSMutableArray *) getPhotosToUpload;
- (CSPhoto *) getPhoto: (NSURL *) url;
- (CSDevice *) getDevice: (NSString *) cid;
- (NSString *) getLatestId;

@end
