//
//  LocalPhotos.m
//  Coinsorter
//
//  Created by Jake Runzer on 7/31/14.
//  Copyright (c) 2014 acdGO. All rights reserved.
//

#import "LocalLibrary.h"

#define ALBUMS @"albums"
#define DATE @"date"

@implementation LocalLibrary

- (id) init {
  self = [super init];
  
  self.dataWrapper = [[CoreDataWrapper alloc] init];
  AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
  account = appDelegate.account;
  
  self.allowedAlbums = [[NSMutableArray alloc] init];
  assetLibrary = [[ALAssetsLibrary alloc] init];
  
  return self;
}

// register for photo library notifications
- (void) registerForNotifications {
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(assetChanged:) name:ALAssetsLibraryChangedNotification object:assetLibrary];
}

- (void) unRegisterForNotifications {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:ALAssetsLibraryChangedNotification object:nil];
}

#pragma mark - Load Local Images


// get the allowed albums from user defaults and load into array
- (void) loadAllowedAlbums {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  
  [self.allowedAlbums removeAllObjects];
  NSMutableArray *arr = [defaults mutableArrayValueForKey:ALBUMS];
  for (NSString *url in arr) {
    [self.allowedAlbums addObject:url];
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

// called when an asset in the photo library changes
- (void) assetChanged: (NSNotification *) notification {
  [self loadLocalImages:NO];
}

// add asset to core data
- (void) addAsset: (ALAsset *) asset {
  NSURL *url = asset.defaultRepresentation.url;
  
  // create photo object
  CSPhoto *photo =[[CSPhoto alloc] init];
  photo.imageURL = url.absoluteString;
  photo.deviceId = account.cid;
  photo.onServer = @"0";
  
  // add data to photo
  NSDate *date = [asset valueForProperty:ALAssetPropertyDate];
  photo.dateCreated = date;
  
  // add data to photo obj
  NSString *name = asset.defaultRepresentation.filename;
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsPath = [paths objectAtIndex:0];
  NSString *filePath = [documentsPath stringByAppendingString:[NSString stringWithFormat:@"/thumb-%@", name]];
  
  photo.thumbURL = filePath;
  
  // add photo to db
  [self.dataWrapper addPhoto:photo asset:asset];
}

// load all the local photos from allowed albums to core data
- (void) loadLocalImages: (BOOL) parseAll {
  
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
          [assetLibrary assetForURL:url
                         resultBlock:^(ALAsset *asset) {
                           if (asset) {
                             [self addAsset:asset];
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
        if ([self urlIsAllowed:groupUrl]) {
          [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:assetEnumerator];
        }
      }
    };
    
    // Process!
    [assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll
                                     usingBlock:assetGroupEnumerator
                                   failureBlock:^(NSError *error) {
                                     NSLog(@"There is an error");
                                   }];
    //        localPhotos = locals;
    NSLog(@"finished loading local photos");
  });
}

@end
