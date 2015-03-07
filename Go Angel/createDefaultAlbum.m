//
//  createDefaultAlbum.m
//  Go Arch
//
//  Created by Xing Qiao on 2014-11-27.
//  Copyright (c) 2014 acdGO Software Ltd. All rights reserved.
//

#import "createDefaultAlbum.h"

@implementation createDefaultAlbum

- (void)createAlbum {
  // create a new album
  PHPhotoLibrary *photoLibrary = [PHPhotoLibrary sharedPhotoLibrary];

  __block PHObjectPlaceholder *newPHAssetCollection;
  [photoLibrary performChanges:^{
      PHAssetCollectionChangeRequest *createRequest =
          [PHAssetCollectionChangeRequest
              creationRequestForAssetCollectionWithTitle:SAVE_PHOTO_ALBUM];
      newPHAssetCollection = createRequest.placeholderForCreatedAssetCollection;
  } completionHandler:^(BOOL success, NSError *error){}];
}

- (void)setDefaultAlbum {

  PHFetchOptions *albumFetchOption = [[PHFetchOptions alloc] init];
  albumFetchOption.predicate = [NSPredicate predicateWithFormat:@"title == %@", SAVE_PHOTO_ALBUM];
  PHFetchResult *albumResult = [PHAssetCollection
      fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                            subtype:PHAssetCollectionSubtypeAlbumRegular
                            options:albumFetchOption];

  __block BOOL found = NO;
  [albumResult enumerateObjectsUsingBlock:^(PHAssetCollection *collection,
                                            NSUInteger idx, BOOL *stop) {
    found = YES;
  }];
  
  if (found) {
    NSLog(@"Default Album FOUND");
  } else {
    NSLog(@"Default Album NOT FOUND");
    [self createAlbum];
  }

 }

@end
