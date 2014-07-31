
//  coreDataWrapper.m
//  coinsorter-ios
//
//  Created by Jake Runzer on 7/15/14.
//  Copyright (c) 2014 Jake Runzer. All rights reserved.
//

#import "CoreDataWrapper.h"

#define PHOTO @"Photo"
#define DEVICE @"Device"

@implementation CoreDataWrapper

- (void) addUpdateDevice:(CSDevice *)device {
  NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
  
  [context performBlockAndWait: ^{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:DEVICE inManagedObjectContext:context];
    [request setEntity:entityDesc];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(remoteId = %@)", device.remoteId];
    [request setPredicate:pred];
    
    NSError *err;
    NSArray *result = [context executeFetchRequest:request error:&err];
    
    NSAssert(![NSThread isMainThread], @"MAIN THREAD WHEN USING DB!!!");
    
    if (result == nil) {
      NSLog(@"error with core data request");
      abort();
    }
    
    NSManagedObject *photoObj;
    
    if (result.count == 0) {
      photoObj = [NSEntityDescription insertNewObjectForEntityForName:DEVICE inManagedObjectContext:context];
      NSLog(@"created new device");
    }else {
      photoObj = result[0];
      NSLog(@"updated device - %@", device.deviceName);
    }
    
    [photoObj setValue:device.deviceName forKey:@"deviceName"];
    [photoObj setValue:device.remoteId forKey:@"remoteId"];
    
    [context save:nil];
    
  }];
}

- (CSDevice *) getDevice:(NSString *)cid {
  NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
  CSDevice *device = [[CSDevice alloc] init];
  
  [context performBlockAndWait: ^{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:DEVICE];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(remoteId = %@)", cid];
    [request setPredicate:pred];
    
    NSError *error;
    NSArray *result = [context executeFetchRequest:request error:&error];
    
    if (result == nil) {
      NSLog(@"error with core data");
      abort();
    }
    
    if (result.count > 0) {
      NSManagedObject *obj = result[0];
      
      device.remoteId = cid;
      device.deviceName = [obj valueForKey:@"deviceName"];
    }
  }];
  
  return device;
}

- (NSMutableArray *) getAllDevices {
  NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
  __block NSMutableArray *arr = [[NSMutableArray alloc] init];
  
  [context performBlockAndWait: ^{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:DEVICE];
    
    NSArray*dvs = [context executeFetchRequest:request error:nil];
    
    if (dvs == nil) {
      NSLog(@"error with core data request");
      abort();
    }
    
    // add all of the photo objects to the local photo list
    for (int i = 0; i < [dvs count]; i++) {
      NSManagedObject *d = dvs[i];
      CSDevice *device = [[CSDevice alloc] init];
      device.deviceName = [d valueForKey:@"deviceName"];
      device.remoteId = [d valueForKey:@"remoteId"];

      [arr addObject:device];
    }
  }];
  NSLog(@"returning array of size %d", arr.count);
  
  return arr;
}

- (void) addUpdatePhoto:(CSPhoto *)photo {
  
  NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
  
  [context performBlock: ^{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:PHOTO];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(imageURL = %@)", photo.imageURL];
    [request setPredicate:pred];
    
    NSError *err;
    NSArray *result = [context executeFetchRequest:request error:&err];
    
    if (result == nil) {
      NSLog(@"error with core data request");
      abort();
    }
    
    NSManagedObjectContext *photoObj;
    if (result.count == 0) {
      photoObj = [NSEntityDescription insertNewObjectForEntityForName:PHOTO inManagedObjectContext:context];
    }else {
      photoObj = result[0];
    }
    
    [photoObj setValue:photo.imageURL forKey:@"imageURL"];
    [photoObj setValue:photo.thumbURL forKey:@"thumbURL"];
    [photoObj setValue:photo.deviceId forKey:@"deviceId"];
    [photoObj setValue:photo.onServer forKey:@"onServer"];
    
    if (photo.remoteID != nil) {
      [photoObj setValue:photo.remoteID forKey:@"remoteId"];
    }
    
    [context save:nil];
  }];
}

- (void) addPhoto:(CSPhoto *)photo asset:(ALAsset *) asset {
  
  NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
  
  [context performBlock:^{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:PHOTO];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(imageURL = %@)", photo.imageURL];
    [request setPredicate:pred];
    
    NSArray *results = [context executeFetchRequest:request error:nil];
    
    if (results == nil) {
      NSLog(@"error with core data request");
      abort();
    }
    
    if (results.count == 0) {
      NSManagedObjectContext *newPhoto = [NSEntityDescription insertNewObjectForEntityForName:PHOTO inManagedObjectContext:context];
      
      if (asset != nil) {
        // we save the thumbnail to app documents folder
        // now we can easily use later without asset library
        UIImage *thumb = [UIImage imageWithCGImage:asset.thumbnail];
        NSData *data = UIImagePNGRepresentation(thumb);
        [data writeToFile:photo.thumbURL atomically:YES];
        
        photo.thumbURL = [[NSURL fileURLWithPath:photo.thumbURL] absoluteString];;
        
        NSLog(@"will save thumbnail to %@", photo.thumbURL);
      }
      
      [newPhoto setValue:photo.imageURL forKey:@"imageURL"];
      [newPhoto setValue:photo.thumbURL forKey:@"thumbURL"];
      [newPhoto setValue:photo.deviceId forKey:@"deviceId"];
      [newPhoto setValue:photo.onServer forKey:@"onServer"];
      [newPhoto setValue:photo.dateCreated forKeyPath:@"dateCreated"];
      
      if (photo.remoteID != nil) {
        [newPhoto setValue:photo.remoteID forKey:@"remoteId"];
      }
      
      
      [context save:nil];
      
      NSLog(@"added new photo to core data");
    }else {
      NSLog(@"photo already in core data");
    }
  }];
}

- (void) addPhoto:(CSPhoto *)photo {
  [self addPhoto:photo asset:nil];
}

- (NSMutableArray *)getPhotos: (NSString *) deviceId {
  NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
  __block NSMutableArray *arr = [[NSMutableArray alloc] init];
  
  [context performBlockAndWait: ^{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:PHOTO];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(deviceId = %@)", deviceId];
    [request setPredicate:pred];
    
    NSArray*phs = [context executeFetchRequest:request error:nil];
    
    if (phs == nil) {
      NSLog(@"error with core data request");
      abort();
    }
    
    // add all of the photo objects to the local photo list
    for (int i =0; i < [phs count]; i++) {
      NSManagedObject *p = phs[i];
      CSPhoto *photo = [[CSPhoto alloc] init];
      photo.deviceId = [p valueForKey:@"deviceId"];
      photo.onServer = [p valueForKey:@"onServer"];
      
      NSString *imageURL = [p valueForKey:@"imageURL"];
      NSString *thumbURL = [p valueForKey:@"thumbURL"];
      
      photo.dateCreated = (NSDate *) [p valueForKey:@"dateCreated"];
      
      photo.imageURL = imageURL;
      photo.thumbURL = thumbURL;
      
      photo.photoObject = [MWPhoto photoWithURL:[NSURL URLWithString:photo.imageURL]];
      photo.thumbObject = [MWPhoto photoWithURL:[NSURL URLWithString:photo.thumbURL]];
      
      [arr addObject:photo];
    }
  }];
  
  return arr;
}

- (NSMutableArray *) getPhotosToUpload {
  NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
  __block NSMutableArray *arr = [[NSMutableArray alloc] init];
  
  [context performBlockAndWait: ^{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:PHOTO];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(onServer = %@)", @"0"];
    [request setPredicate:pred];
    
    NSArray*phs = [context executeFetchRequest:request error:nil];
    
    if (phs == nil) {
      NSLog(@"error with core data request");
      abort();
    }
    
    // add all of the photo objects to the local photo list
    for (int i =0; i < [phs count]; i++) {
      NSManagedObject *p = phs[i];
      CSPhoto *photo = [[CSPhoto alloc] init];
      photo.deviceId = [p valueForKey:@"deviceId"];
      photo.onServer = [p valueForKey:@"onServer"];
      
      NSString *imageURL = [p valueForKey:@"imageURL"];
      NSString *thumbURL = [p valueForKey:@"thumbURL"];
      
      photo.dateCreated = (NSDate *) [p valueForKey:@"dateCreated"];
      
      photo.imageURL = imageURL;
      photo.thumbURL = thumbURL;
      
      photo.photoObject = [MWPhoto photoWithURL:[NSURL URLWithString:photo.imageURL]];
      photo.thumbObject = [MWPhoto photoWithURL:[NSURL URLWithString:photo.thumbURL]];
      
      [arr addObject:photo];
    }
  }];
  
  return arr;
}

- (NSString *) getLatestId {
  NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
  __block NSString *latestId = @"-1";
  
  [context performBlockAndWait: ^{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:PHOTO];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(onServer = %@)", @"1"];
    [request setPredicate:pred];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"remoteId" ascending:NO];
    NSArray *descriptors = [[NSArray alloc] initWithObjects:sort, nil];
    [request setSortDescriptors: descriptors];
    
    NSError *error;
    NSArray *result = [context executeFetchRequest:request error:&error];
    
    if (result == nil) {
      NSLog(@"error with core data");
      abort();
    }
    
    if (result.count > 0) {
      NSManagedObject *obj = result[0];
      
      latestId = [obj valueForKey:@"remoteId"];
    }
  }];
  
  return latestId;
}

@end
