//
//  UploadPhotosTask.h
//  Coinsorter
//
//  Created by Jake Runzer on 7/30/14.
//  Copyright (c) 2014 ACDSystems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "CSPhoto.h"
#import "CoreDataWrapper.h"
#import "AppDelegate.h"

@interface UploadPhotosTask : NSObject <NSURLSessionTaskDelegate> {
  ALAssetsLibrary *assetLibrary;
  
  NSConditionLock* readLock;
}

- (id) initWithWrapper: (CoreDataWrapper *) wrap;

- (void) uploadPhotoArray: (NSMutableArray *) photos;

@property (nonatomic) NSMutableArray *uploadingPhotos;
// need reference to a data wrapper so we can change photo state when we download, upload, etc.
@property CoreDataWrapper *dataWrapper;

@end
