//
//  MediaLoader.m
//  Go Arch
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import "MediaLoader.h"

#define IMAGE_LOCAL 1
#define IMAGE_REMOTE 2

@implementation MediaLoader

- (id)init {
  self = [super init];

  self.imageCache = [[NSCache alloc] init];

  return self;
}

- (UIImage *)getErrorPhoto {
  return nil;
}

- (int)getTypePhoto:(NSURL *)url {

  // check the type of url
  if ([[[url scheme] lowercaseString] isEqualToString:@"assets-library"]) {
    return IMAGE_LOCAL;
  } else if ([url isFileURL]) {
    return IMAGE_REMOTE;
  } else {
    //NSLog(@"Photo Url is Invalid!");
    //return -1;
    return IMAGE_REMOTE;
  }
}


- (void) loadFullScreenImage:(CSPhoto *)photo completionHandler:(void (^)(UIImage *))completionHandler {
  [self loadFullImage:photo fullRes:NO completionHandler:completionHandler];
}

- (void) loadFullResImage:(CSPhoto *)photo completionHandler:(void (^)(UIImage *))completionHandler {
  [self loadFullImage:photo fullRes:YES completionHandler:completionHandler];
}

// full screen image with async callback
// loaded uiimage passed to completionHandler when finished
- (void)loadFullImage:(CSPhoto *)photo fullRes:(BOOL) fullRes
    completionHandler:(void (^)(UIImage *))completionHandler {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
      NSString *documentsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/"];
      NSString *fullPathImage = [documentsPath stringByAppendingPathComponent:photo.imageURL];
      NSString *fullThumbVideo = [documentsPath stringByAppendingPathComponent:photo.thumbURL];

      NSString *newUrl =[ @"file://"stringByAppendingString:fullPathImage];
      NSURL *url = [NSURL URLWithString:newUrl];
      
      
      int type = [self getTypePhoto:url];

      //    NSLog(@"loading %@", [url absoluteString]);

      if (type == IMAGE_LOCAL) {

        // load image with phimagemanager
        
        PHFetchResult *result =
            [PHAsset fetchAssetsWithALAssetURLs:[NSArray arrayWithObject:url]
                                        options:nil];
        [result enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx,
                                             BOOL *stop) {
          
          PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
          options.synchronous = NO;

          // only use the resolution of the screen instead of the full quality image
          CGFloat width = [UIScreen mainScreen].bounds.size.width;
          CGFloat height = [UIScreen mainScreen].bounds.size.height;

          CGSize targetSize = CGSizeMake(width, height);
          
          if (fullRes) {
            targetSize = PHImageManagerMaximumSize;
          }
          
            [[PHImageManager defaultManager]
                requestImageForAsset:asset
                          targetSize:targetSize
                         contentMode:PHImageContentModeDefault
                             options:options
                       resultHandler:^(UIImage *image, NSDictionary *info){

                         completionHandler(image);
                       }];
        }];

//        // load the photo with asset library
//        // Load from asset library async
//        @try {
//          ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
//          [assetLibrary assetForURL:url
//              resultBlock:^(ALAsset *asset) {
//                  ALAssetRepresentation *rep = [asset defaultRepresentation];
//
//                  // Retrieve the image orientation from the ALAsset
//                  UIImageOrientation orientation = UIImageOrientationUp;
//                  NSNumber *orientationValue =
//                      [asset valueForProperty:ALAssetPropertyOrientation];
//                  if (orientationValue != nil) {
//                    orientation = [orientationValue intValue];
//                  }
//                  CGFloat scale = 1;
//
//                  CGImageRef iref = [rep fullScreenImage];
//                  if (iref) {
//                    // correct the image orientation when we upload it
//                    UIImage *image = [UIImage imageWithCGImage:iref];
//                    completionHandler(image);
//                  }
//              }
//              failureBlock:^(NSError *error) {
//                  NSLog(@"Photo from asset library error: %@", error);
//              }];
//        }
//        @catch (NSException *exception) {
//          NSLog(@"Photo from asset library error: %@", exception);
//        }

      } else if (type == IMAGE_REMOTE) {
        // try to get image from cache first

        UIImage *image;
        NSData *data = [_imageCache objectForKey:fullPathImage];

        if (data != nil) {
          image = [UIImage imageWithData:data];
          completionHandler(image);
        } else {
          // load the photo directly from path
          @try {
              if ([photo.isVideo isEqualToString:@"1"]) {
                  url = [NSURL URLWithString:fullThumbVideo];
              } else {
                  if (fullRes) {
                  url = [NSURL URLWithString:fullPathImage];
                  } else {
                  url = [NSURL URLWithString:fullThumbVideo];
                  }
              }
            image = [UIImage imageWithContentsOfFile:url.path];
            if (image) {
              // cache the image for future use
              NSData *data = UIImageJPEGRepresentation(image, 1.0);
              [_imageCache setObject:data forKey:url.path];

              completionHandler(image);
            }
          }
          @catch (NSException *exception) {
            NSLog(@"Error loading photo from path: %@", url.path);
            completionHandler([self getErrorPhoto]);
          }
        }
      } else {
        completionHandler([self getErrorPhoto]);
      }
  });
}

// load thumbnail async with callback
// loaded uiimage passed to completionHandler when finished
- (void)loadThumbnail:(CSPhoto *)photo
    completionHandler:(void (^)(UIImage *))completionHandler {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    NSString *documentsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/"];
      NSString *fullPath = [documentsPath stringByAppendingPathComponent:photo.thumbURL];
      NSString *newUrl =[ @"file://"stringByAppendingString:fullPath];
      NSURL *url = [NSURL URLWithString:newUrl];
      int type = [self getTypePhoto:url];

      //    NSLog(@"loading %@", [url absoluteString]);

      if (type == IMAGE_LOCAL) {
        // load the image from the phimagemanager
        
        // WHEN LOADING THE THUMBNAILS, IT SEEMS TO BE BETTER NOT TO USE THE PHIMAGEMANAGER
        // AND CONTINUING USING THE ASSET LIBRARY
//        PHFetchResult *result =
//        [PHAsset fetchAssetsWithALAssetURLs:[NSArray arrayWithObject:url]
//                                    options:nil];
//        [result enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx,
//                                             BOOL *stop) {
//          
//          PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
//          options.synchronous = NO;
//          
//          [[PHImageManager defaultManager]
//           requestImageForAsset:asset
//           targetSize:CGSizeMake(SQUARE_THUMB_SIZE, SQUARE_THUMB_SIZE)
//           contentMode:PHImageContentModeAspectFill
//           options:options
//           resultHandler:^(UIImage *image, NSDictionary *info){
//             
//             completionHandler(image);
//           }];
//        }];

        
        // load the photo with asset library
        // Load from asset library async
        @try {
          ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
          [assetLibrary assetForURL:url
              resultBlock:^(ALAsset *asset) {
                  CGImageRef iref = [asset thumbnail];

                  // TODO: check if the image exists (the user could of deleted
                  // it from photo library)
                  if (iref) {
                    UIImage *image = [UIImage imageWithCGImage:iref];
                    completionHandler(image);
                  }
              }
              failureBlock:^(NSError *error) {
                  NSLog(@"Photo from asset library error: %@", error);
              }];
        }
        @catch (NSException *exception) {
          NSLog(@"Photo from asset library error: %@", exception);
        }

      } else if (type == IMAGE_REMOTE) {

        // check if image data is in cache
        UIImage *image;
        NSData *data = [_imageCache objectForKey:url.path];
        if (data != nil) {
          image = [UIImage imageWithData:data];
          completionHandler(image);
        } else {

          // load the photo directly from path
          @try {
            url = [NSURL URLWithString:fullPath];

            UIImage *image = [UIImage imageWithContentsOfFile:fullPath];

            if (image) {

              // save image to cache
              NSData *data = UIImageJPEGRepresentation(image, 0.6);
              [_imageCache setObject:data forKey:url.path];

              completionHandler(image);
            }
          }
          @catch (NSException *exception) {
            NSLog(@"Error loading photo from path: %@", photo.thumbURL);
            completionHandler([self getErrorPhoto]);
          }
        }
      } else {
        completionHandler([self getErrorPhoto]);
      }
  });
}

@end
