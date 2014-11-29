//
//  createDefaultAlbum.h
//  Go Angel
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
    NSUserDefaults *defaults;
}

- (void) createAlbum;
- (void) setDefaultAlbum;
@property(nonatomic,assign) BOOL didAlbumCreated;
@end
