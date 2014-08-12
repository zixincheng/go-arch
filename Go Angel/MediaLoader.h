//
//  MediaLoader.h
//  Go Angel
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "CSPhoto.h"

@interface MediaLoader : NSObject

@property (strong, nonatomic) NSCache *imageCache;

- (void) loadThumbnail: (CSPhoto *) photo completionHandler: (void (^) (UIImage *image)) completionHandler;
- (void) loadFullImage: (CSPhoto *) photo completionHandler: (void (^) (UIImage *image)) completionHandler;

@end
