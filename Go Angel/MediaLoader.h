//
//  MediaLoader.h
//  Go Arch
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "CSPhoto.h"

@import Photos;


// class to load images into a uiimage view
// it should handle all caching and locations for you

// TODO: FIX CACHING

@interface MediaLoader : NSObject

@property (strong, nonatomic) NSCache *imageCache;

- (void) loadThumbnail: (CSPhoto *) photo completionHandler: (void (^) (UIImage *image)) completionHandler;
- (void) loadFullScreenImage: (CSPhoto *) photo completionHandler: (void (^) (UIImage *image)) completionHandler;
- (void) loadFullResImage: (CSPhoto *) photo completionHandler: (void (^) (UIImage *image)) completionHandler;

@end
