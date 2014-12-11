//
//  createDefaultAlbum.m
//  Go Angel
//
//  Created by Xing Qiao on 2014-11-27.
//  Copyright (c) 2014 acdGO Software Ltd. All rights reserved.
//

#import "createDefaultAlbum.h"

@implementation createDefaultAlbum

- (void) createAlbum{
    // create a new album
    PHPhotoLibrary* photoLibrary = [PHPhotoLibrary sharedPhotoLibrary];
    
    __block PHObjectPlaceholder* newPHAssetCollection;
    [photoLibrary performChanges:^{
        PHAssetCollectionChangeRequest* createRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:SAVE_PHOTO_ALBUM];
        newPHAssetCollection = createRequest.placeholderForCreatedAssetCollection;
    } completionHandler:^(BOOL success, NSError *error) {
    }];
}

- (void) setDefaultAlbum{
    assetAlbumLibrary = [[ALAssetsLibrary alloc] init];
    __block BOOL found = NO;
    
    //check album group, create Go Angel album if not found
    ALAssetsLibraryGroupsEnumerationResultsBlock
    assetGroupEnumerator = ^(ALAssetsGroup *group, BOOL *stop){
        if (group) {
            NSString *albumName = [group valueForProperty:ALAssetsGroupPropertyName];
            if ([SAVE_PHOTO_ALBUM isEqualToString:albumName]) {
                NSLog(@"find default album: %@", SAVE_PHOTO_ALBUM);
                *stop = YES;
                found = YES;
            }
        } else {
            if (found)
                return;
            
            NSLog(@"album not found, create the %@ album",SAVE_PHOTO_ALBUM);
            [self createAlbum];
        }
    };
    
    [assetAlbumLibrary enumerateGroupsWithTypes:ALAssetsGroupAlbum
                           usingBlock:assetGroupEnumerator
                         failureBlock:^(NSError *error) {
                             NSLog(@"album access denied");
                         }];
}

@end

