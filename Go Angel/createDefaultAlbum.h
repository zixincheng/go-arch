//
//  createDefaultAlbum.h
//  Go Arch
//
//  Created by Xing Qiao on 2014-11-27.
//  Copyright (c) 2014 acdGO Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@import Photos;

@interface createDefaultAlbum : NSObject
{
    ALAssetsLibrary *assetAlbumLibrary;
}

- (void) createAlbum;
- (void) setDefaultAlbum;

@end
