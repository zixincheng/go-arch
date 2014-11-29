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
            self.didAlbumCreated = success;
    }];
}

- (void) setDefaultAlbum{
    assetAlbumLibrary = [[ALAssetsLibrary alloc] init];
    defaults = [NSUserDefaults standardUserDefaults];
    
    __block BOOL found = NO;
    //find wanted album and set as a default album
    ALAssetsLibraryGroupsEnumerationResultsBlock
    assetGroupEnumerator = ^(ALAssetsGroup *group, BOOL *stop){
        if (group) {
            NSString *albumName = [group valueForProperty:ALAssetsGroupPropertyName];
            NSString *albumUrl = [group valueForProperty:ALAssetsGroupPropertyURL];
            if ([SAVE_PHOTO_ALBUM isEqualToString:albumName]) {
                NSMutableArray *arr = [[NSMutableArray alloc] init];
                [arr addObject:[albumUrl description]];
                NSLog(@"found album %@", SAVE_PHOTO_ALBUM);
                [defaults setValue:arr forKey:ALBUMS];
                *stop = YES;
                found = YES;
            }
        } else { // not found, create the album
            if (found)
                return;
            NSLog(@"album not found, try making album");
            if (!self.didAlbumCreated) {
                [self createAlbum];
            }
            [self setDefaultAlbum];
        }
    };
    
    [assetAlbumLibrary enumerateGroupsWithTypes:ALAssetsGroupAlbum
                           usingBlock:assetGroupEnumerator
                         failureBlock:^(NSError *error) {
                             NSLog(@"album access denied");
                         }];
}

@end

