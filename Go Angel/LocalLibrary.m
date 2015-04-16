//
//  LocalPhotos.m
//  Go Arch
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import "LocalLibrary.h"

@implementation LocalLibrary

- (id) init {
  self = [super init];
  
  self.dataWrapper = [[CoreDataWrapper alloc] init];
  AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
  account = appDelegate.account;
  
  self.allowedAlbums = [[NSMutableArray alloc] init];
  self.defaultAlbum = [[createDefaultAlbum alloc]init];
  assetAlbumLibrary = [[ALAssetsLibrary alloc] init];
  
  [self loadAllowedAlbums];
  
  return self;
}

// register for photo library notifications
- (void) registerForNotifications {
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(assetChanged:) name:ALAssetsLibraryChangedNotification object:assetAlbumLibrary];
}

- (void) unRegisterForNotifications {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:ALAssetsLibraryChangedNotification object:nil];
}

#pragma mark - Load Local Images

// get the allowed albums from user defaults and load into array
- (void) loadAllowedAlbums {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  
  allPhotosSeleceted = [defaults boolForKey:ALL_PHOTOS];
  
  [self.allowedAlbums removeAllObjects];
  NSMutableArray *arr = [defaults mutableArrayValueForKey:ALBUMS];
  for (NSString *name in arr) {
    [self.allowedAlbums addObject:name];
  }
}

// checks if the given url is one the user wants photos from
// returns YES if it is
- (BOOL) urlIsAllowed: (NSString *) url {
  for (NSString *u in self.allowedAlbums) {
    if ([u isEqualToString:[url description]]) {
      return YES;
    }
  }
  return NO;
}

// checks if the given albums name is a selected album
- (BOOL) albumsIsAllowed: (NSString *) name {
  if (allPhotosSeleceted) return YES;
  for (NSString *n in self.allowedAlbums) {
    if ([n isEqualToString:[name description]]) {
      return YES;
    }
  }
  return NO;
}

// called when an asset in the photo library changes
- (void) assetChanged: (NSNotification *) notification {
  [self loadLocalImages:NO];
}

// add alasset to core data
- (CSPhoto *) addAsset: (ALAsset *) asset videoFlag:(BOOL) videoFlag location:(CSLocation *)location{
  NSURL *url = asset.defaultRepresentation.url;
  
  // create photo object
  CSPhoto *photo =[[CSPhoto alloc] init];
  photo.imageURL = url.absoluteString;
  photo.deviceId = account.cid;
  photo.thumbOnServer = @"0";
  photo.fullOnServer = @"0";
    if (videoFlag) {
        photo.isVideo = @"1";
    } else {
        photo.isVideo = @"0";
    }
  // add data to photo
  NSDate *date = [asset valueForProperty:ALAssetPropertyDate];
  photo.dateCreated = date;
  
  // add data to photo obj
  NSString *name = asset.defaultRepresentation.filename;
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsPath = [paths objectAtIndex:0];
  NSString *filePath = [documentsPath stringByAppendingString:[NSString stringWithFormat:@"/thumb-%@", name]];
  
  photo.thumbURL = filePath;
  //photo.location = location;
  
  // add photo to db
  BOOL added = [self.dataWrapper addPhoto:photo];
  if (added) {
    if (self.addCallback != nil) {
      self.addCallback();
    }
  }
    return photo;
}

// add phasset to core data
- (CSPhoto *) addPhoto: (PHAsset *) asset {
  CSPhoto *photo = [[CSPhoto alloc] init];
  
  photo.deviceId = account.cid;
  photo.thumbOnServer = @"0";
  photo.fullOnServer = @"0";
  photo.dateCreated = asset.creationDate;
  
  // add photo to core data
  BOOL added = [self.dataWrapper addPhoto: photo];
  if (added) {
    if (self.addCallback != nil) {
      self.addCallback();
    }
  }
  
  return photo;
}

- (void)thisImage:(UIImage *)image hasBeenSavedInPhotoAlbumWithError:(NSError *)error usingContextInfo:(void*)ctxInfo {
  if (error) {
    // Do anything needed to handle the error or display it to the user
  } else {
    // .... do anything you want here to handle
    // .... when the image has been saved in the photo album
    [self loadLocalImages:NO];
  }
}

- (void) loadLocalImages:(BOOL)parseAll addCallback:(void (^)())addCallback {
  self.addCallback = addCallback;
  [self loadLocalImages:parseAll];
}

// load all the local photos from allowed albums to core data
- (void) loadLocalImages: (BOOL) parseAll {
  
  // PHOTO FRAMEWORK METHOD - TODO: FInd wat to get disk url for PHAsset
//  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    
//    // the latest date that is stored in the user defaults
//    NSDate *latestStored = [defaults objectForKey:DATE];
//    
//    // this is the new latest date that we will set after
//    // getting all of the photos
//    __block NSDate *newLatest = [latestStored copy];
//    
//    PHFetchOptions *userAlbumsOptions = [PHFetchOptions new];
//
//    NSLog(@"\n\n\n");
//    
//    // TODO: Fix when All Photos is selected, cannot first go through collections
//    
//    NSMutableArray *parrAlbums = [NSMutableArray array];
//    for (NSString *name in self.allowedAlbums) {
//      [parrAlbums addObject:[NSPredicate predicateWithFormat:@"title == %@", name]];
//      NSLog(@"ALLOWED ALBUM IS %@", name);
//    }
//    NSPredicate *compoundpredAlbums = [NSCompoundPredicate orPredicateWithSubpredicates:parrAlbums];
//    userAlbumsOptions.predicate = compoundpredAlbums;
//    
//    PHFetchResult *userAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:userAlbumsOptions];
//    
//    [userAlbums enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop) {
//      PHFetchOptions *onlyImagesOptions = [PHFetchOptions new];
//      
//      NSMutableArray *parrPhotos = [NSMutableArray array];
//      [parrPhotos addObject:[NSPredicate predicateWithFormat:@"mediaType = %i", PHAssetMediaTypeImage]];
//      
//      // only add date predicate if we don't want to parse all photos
//      if (!parseAll && latestStored != nil) [parrPhotos addObject:[NSPredicate predicateWithFormat:@"creationDate > %@", latestStored]];
//      NSPredicate *compoundpredPhotos = [NSCompoundPredicate andPredicateWithSubpredicates:parrPhotos];
//      onlyImagesOptions.predicate = compoundpredPhotos;
//      
//      PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:collection options:onlyImagesOptions];
//      
//      NSLog(@"GETTING PHOTOS AFTER %@", latestStored);
//      
//      NSLog(@"ALBUM: %@", collection.localizedTitle);
//      [result enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
//        NSLog(@"\tPHOTO DATE: %@ LATEST STORED DATE: %@", asset.creationDate, latestStored);
//
//        // store the latest date back into the defaults
//        NSComparisonResult result;
//        if (newLatest != nil) {
//          result = [newLatest compare:asset.creationDate];
//          if (result == NSOrderedAscending) {
//            newLatest = asset.creationDate;
//            [defaults setObject:newLatest forKey:DATE];
//            [defaults synchronize];
//          }
//        }else {
//          newLatest = asset.creationDate;
//          [defaults setObject:newLatest forKey:DATE];
//          [defaults synchronize];
//        }
//        
//        [self addPhoto:asset];
//      }];
//    }];
//    
//    NSLog(@"\n\n\n");
//  });
  
  
  
  
  // Run in the background as it takes a while to get all assets from the library
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // the latest date that is stored in the user defaults
    NSDate *latestStored = [defaults objectForKey:DATE];
    
    // the actual latest date from the assets
    // this may be newer than the one stored in the defaults
    // and on first run, this is the only thing that will be change
    __block NSDate *latestAsset;
    
    // Process assets
    void (^assetEnumerator)(ALAsset *, NSUInteger, BOOL *) = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
      if (result != nil) {
        if ([[result valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]) {
          NSURL *url = result.defaultRepresentation.url;
          NSDate *date = [result valueForProperty:ALAssetPropertyDate];
          
          // var to hold date comparison result
          NSComparisonResult result;
          
          if (latestAsset != nil) {
            result = [latestAsset compare:date];
            
            // the current asset date is newer
            if (result == NSOrderedAscending) {
              latestAsset = date;
              // store the latest date in defaults
              [defaults setObject:latestAsset forKey:DATE];
              [defaults synchronize];
            }
          }else {
            latestAsset = date;
            // store the latest date in defaults
            [defaults setObject:latestAsset forKey:DATE];
            [defaults synchronize];
          }
          
          // if you want to stop parsing after we know there are
          // no older ones
          if (!parseAll) {
            // if the latest stored date is there
            if (latestStored != nil) {
              result = [latestStored compare:date];
              
              // if current asset date is older than store date,
              // than stop enumerator
              if (result == NSOrderedDescending || result == NSOrderedSame) {
                *stop = YES;
                return;
              }
            }
          }
          
          //          [defaults setValue:date forKey:[NSString stringWithFormat:@"%@-%@", DATE, ]]
          
          // async call to load the asset from asset library
          [assetAlbumLibrary assetForURL:url
                         resultBlock:^(ALAsset *asset) {
                           if (asset) {
                              // [self addAsset:asset videoFlag:NO];
                           }
                         }
                        failureBlock:^(NSError *error){
                          NSLog(@"operation was not successfull!");
                        }];
        }
      }
    };
    
    // Process groups
    void (^ assetGroupEnumerator) (ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop) {
      if (group != nil) {
        NSString *groupName = [group valueForProperty:ALAssetsGroupPropertyName];
        NSString *groupUrl = [group valueForProperty:ALAssetsGroupPropertyURL];

        // only get pictures from the allowed albums
        if ([self albumsIsAllowed:groupName]) {
          [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:assetEnumerator];
        }
      }
    };
    
    // Process!
    [assetAlbumLibrary enumerateGroupsWithTypes:ALAssetsGroupAll
                                     usingBlock:assetGroupEnumerator
                                   failureBlock:^(NSError *error) {
                                     NSLog(@"There is an error");
                                   }];
    //        localPhotos = locals;
    NSLog(@"finished loading local photos");
  });
}
- (void) saveVideo: (NSURL *)moviePath location: (CSLocation *)location {
    
    __weak LocalLibrary *se = self;
    __block BOOL found = NO;
    
    ALAssetsLibraryGroupsEnumerationResultsBlock
    assetGroupEnumerator = ^(ALAssetsGroup *group, BOOL *stop){
        if (group) {
            NSString *albumName = [group valueForProperty:ALAssetsGroupPropertyName];
            if ([SAVE_PHOTO_ALBUM isEqualToString:albumName]) {
                self.didAlbumCreated = NO; //reset checking album flag
                //save image
                [assetAlbumLibrary writeVideoAtPathToSavedPhotosAlbum:moviePath completionBlock:^(NSURL *assetURL, NSError *error) {
                    //then get the image asseturl
                    NSLog(@"%@",assetURL);
                    [assetAlbumLibrary assetForURL:assetURL
                                       resultBlock:^(ALAsset *asset) {
                                           //put it into our album
                                           [group addAsset:asset];
                                           [se loadLocalImages:NO];
                                           bool didPhotoAddIntoAlbum = [group addAsset:asset];
                                           // add image to core data after saving into album
                                           if (didPhotoAddIntoAlbum) {
                                               CSPhoto *p = [self addAsset:asset videoFlag:YES location:location];
                                           }
                                       } failureBlock:^(NSError *error) {
                                           NSLog(@"%@", error);
                                       }];
                }];
                *stop = YES;
                found = YES;
            }
        } else {
            if (found)
                return;
            
            // not found Go Arch album, create the album
            if (!self.didAlbumCreated) {
                NSLog(@"album not found, try making album");
                [self.defaultAlbum createAlbum];
                self.didAlbumCreated = YES;
            }
            //recall saveImage function after new album exist
            [self saveVideo: (NSURL *)moviePath location:location];
        }
    };
    
    [assetAlbumLibrary enumerateGroupsWithTypes:ALAssetsGroupAlbum
                                     usingBlock:assetGroupEnumerator
                                   failureBlock:^(NSError *error) {
                                       NSLog(@"album access denied");
                                   }];

}
- (void) saveImage:(UIImage *)image metadata:(NSDictionary *)metadata location: (CSLocation *)location {
    __weak LocalLibrary *se = self;
    __block BOOL found = NO;

    ALAssetsLibraryGroupsEnumerationResultsBlock
    assetGroupEnumerator = ^(ALAssetsGroup *group, BOOL *stop){
        if (group) {
            NSString *albumName = [group valueForProperty:ALAssetsGroupPropertyName];
            if ([SAVE_PHOTO_ALBUM isEqualToString:albumName]) {
                self.didAlbumCreated = NO; //reset checking album flag
                //save image
                [assetAlbumLibrary writeImageDataToSavedPhotosAlbum:UIImageJPEGRepresentation(image, 100) metadata:metadata
                                               completionBlock:^(NSURL *assetURL, NSError *error) {
                                                   
                                                   //then get the image asseturl
                                                   [assetAlbumLibrary assetForURL:assetURL
                                                                 resultBlock:^(ALAsset *asset) {
                                                                     //put it into our album
                                                                     [group addAsset:asset];
                                                                     [se loadLocalImages:NO];
                                                                     bool didPhotoAddIntoAlbum = [group addAsset:asset];
                                                                     // add image to core data after saving into album
                                                                     if (didPhotoAddIntoAlbum) {
                                                                         CSPhoto *p = [self addAsset:asset videoFlag:NO location:location];
                                                                     }
                                                                 } failureBlock:^(NSError *error) {
                                                                     NSLog(@"%@", error);
                                                    }];
                }];
                *stop = YES;
                found = YES;
            }
        } else {
            if (found)
                return;
            
           // not found Go Arch album, create the album
            if (!self.didAlbumCreated) {
                 NSLog(@"album not found, try making album");
                [self.defaultAlbum createAlbum];
                self.didAlbumCreated = YES;
            }
            //recall saveImage function after new album exist
            [self saveImage:image metadata:metadata location: (CSLocation *)location];
        }
    };
    
    [assetAlbumLibrary enumerateGroupsWithTypes:ALAssetsGroupAlbum
                                     usingBlock:assetGroupEnumerator
                                   failureBlock:^(NSError *error) {
                                       NSLog(@"album access denied");
                                   }];
 
}

@end
