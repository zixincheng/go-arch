
//  CoreDataWrapper.m
//  Go Angel
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import "CoreDataWrapper.h"

@implementation CoreDataWrapper

- (void) addUpdateDevice:(CSDevice *)device {
  NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
  
  [context performBlockAndWait: ^{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:DEVICE inManagedObjectContext:context];
    [request setEntity:entityDesc];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(%K = %@)", REMOTE_ID, device.remoteId];
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
    
    [photoObj setValue:device.deviceName forKey:DEVICE_NAME];
    [photoObj setValue:device.remoteId forKey:@"remoteId"];
    
    [context save:nil];
    
  }];
}

- (CSDevice *) getDevice:(NSString *)cid {
  NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
  CSDevice *device = [[CSDevice alloc] init];
  
  [context performBlockAndWait: ^{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:DEVICE];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(%K = %@)", REMOTE_ID, cid];
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
      device.deviceName = [obj valueForKey:DEVICE_NAME];
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
      device.deviceName = [d valueForKey:DEVICE_NAME];
      device.remoteId = [d valueForKey:REMOTE_ID];

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
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(%K = %@)", IMAGE_URL, photo.imageURL];
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
    
    [photoObj setValue:photo.imageURL forKey:IMAGE_URL];
    [photoObj setValue:photo.thumbURL forKey:THUMB_URL];
    [photoObj setValue:photo.deviceId forKey:DEVICE_ID];
    [photoObj setValue:photo.onServer forKey:ON_SERVER];
    
    if (photo.remoteID != nil) {
      [photoObj setValue:photo.remoteID forKey:REMOTE_ID];
    }
    
    [context save:nil];
  }];
}

- (BOOL) addPhoto:(CSPhoto *)photo asset:(ALAsset *) asset {
  
  NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
  
  __block BOOL added = NO;
  
  [context performBlockAndWait:^{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:PHOTO];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(%K = %@)", IMAGE_URL, photo.imageURL];
    [request setPredicate:pred];
    
    NSArray *results = [context executeFetchRequest:request error:nil];
    
    if (results == nil) {
      NSLog(@"error with core data request");
      abort();
    }
    
    if (results.count == 0) {
      NSManagedObjectContext *newPhoto = [NSEntityDescription insertNewObjectForEntityForName:PHOTO inManagedObjectContext:context];
      
      if (asset != nil) {
        
        // TODO : Check file type and save as that
        
        // we save the thumbnail to app documents folder
        // now we can easily use later without asset library
        UIImage *thumb = [UIImage imageWithCGImage:asset.thumbnail];
        NSData *data = UIImageJPEGRepresentation(thumb, 80);
        [data writeToFile:photo.thumbURL atomically:YES];
        
        photo.thumbURL = [[NSURL fileURLWithPath:photo.thumbURL] absoluteString];;
        
        NSLog(@"will save thumbnail to %@", photo.thumbURL);
      }
      
      [newPhoto setValue:photo.imageURL forKey:IMAGE_URL];
      [newPhoto setValue:photo.thumbURL forKey:THUMB_URL];
      [newPhoto setValue:photo.deviceId forKey:DEVICE_ID];
      [newPhoto setValue:photo.onServer forKey:ON_SERVER];
      [newPhoto setValue:photo.dateCreated forKeyPath:DATE_CREATED];
      
      if (photo.remoteID != nil) {
        [newPhoto setValue:photo.remoteID forKey:REMOTE_ID];
      }
      
      // save context to updated other threads
      [context save:nil];
      
      NSLog(@"added new photo to core data");
      added = YES;
    }else {
      NSLog(@"photo already in core data");
    }
  }];
  return added;
}

- (BOOL) addPhoto:(CSPhoto *)photo {
   return [self addPhoto:photo asset:nil];
}

- (NSMutableArray *)getPhotos: (NSString *) deviceId {
  NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
  __block NSMutableArray *arr = [[NSMutableArray alloc] init];
  
  [context performBlockAndWait: ^{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:PHOTO];
    
    // set query
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(%K = %@)", DEVICE_ID, deviceId];
    [request setPredicate:pred];
    
    // set sort
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:DATE_CREATED ascending:NO];
    NSArray *descriptors = [[NSArray alloc] initWithObjects:sort, nil];
    [request setSortDescriptors: descriptors];
    
    NSArray*phs = [context executeFetchRequest:request error:nil];
    
    if (phs == nil) {
      NSLog(@"error with core data request");
      abort();
    }
    
    // add all of the photo objects to the local photo list
    for (int i =0; i < [phs count]; i++) {
      NSManagedObject *p = phs[i];
      CSPhoto *photo = [[CSPhoto alloc] init];
      photo.deviceId = [p valueForKey:DEVICE_ID];
      photo.onServer = [p valueForKey:ON_SERVER];
      
      NSString *imageURL = [p valueForKey:IMAGE_URL];
      NSString *thumbURL = [p valueForKey:THUMB_URL];
      
      photo.dateCreated = (NSDate *) [p valueForKey:DATE_CREATED];
      
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
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(%K = %@)", ON_SERVER, @"0"];
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
      photo.deviceId = [p valueForKey:DEVICE_ID];
      photo.onServer = [p valueForKey:ON_SERVER];
      
      NSString *imageURL = [p valueForKey:IMAGE_URL];
      NSString *thumbURL = [p valueForKey:THUMB_URL];
      
      photo.dateCreated = (NSDate *) [p valueForKey:DATE_CREATED];
      
      photo.imageURL = imageURL;
      photo.thumbURL = thumbURL;
      
      photo.photoObject = [MWPhoto photoWithURL:[NSURL URLWithString:photo.imageURL]];
      photo.thumbObject = [MWPhoto photoWithURL:[NSURL URLWithString:photo.thumbURL]];
      
      [arr addObject:photo];
    }
  }];
  
  return arr;
}

- (int) getCountUnUploaded {
  NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
  
  __block int unUploaded = 0;
  
  [context performBlockAndWait: ^{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:PHOTO];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(%K = %@)", ON_SERVER, @"0"];
    [request setPredicate:pred];
    
    NSArray*phs = [context executeFetchRequest:request error:nil];
    
    if (phs == nil) {
      NSLog(@"error with core data request");
      abort();
    }
    
    // get count of unuploaded photos
    unUploaded = phs.count;
  }];
  
  return unUploaded;
}

- (NSString *) getLatestId {
  NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
  __block NSString *latestId = @"-1";
  
  [context performBlockAndWait: ^{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:PHOTO];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(%K = %@)", ON_SERVER, @"1"];
    [request setPredicate:pred];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:REMOTE_ID ascending:NO];
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
      
      latestId = [obj valueForKey:REMOTE_ID];
      
      // make sure latest id is not 0
      if ([[latestId description] isEqualToString:@"0"]) {
        latestId = @"-1";
      }
    }
  }];
  
  return latestId;
}

@end
