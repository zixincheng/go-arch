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
#import "AppDelegate.h"

@interface UploadPhotosTask : NSObject <NSURLSessionTaskDelegate> {
  ALAssetsLibrary *assetLibrary;
  
  NSConditionLock* readLock;
}

@property (nonatomic) NSMutableArray *uploadingPhotos;

- (void) uploadPhotoArray: (NSMutableArray *) photos;

@end
