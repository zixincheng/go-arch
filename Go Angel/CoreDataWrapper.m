
//  CoreDataWrapper.m
//  Go Angel
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import "CoreDataWrapper.h"

@implementation CoreDataWrapper

#pragma mark -
#pragma mark Device fucntions
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

#pragma mark -
#pragma mark Photo functions

- (NSManagedObject *) setObjectValues: (CSPhoto *) photo object: (NSManagedObject *) object {
  [object setValue:photo.imageURL forKey:IMAGE_URL];
  [object setValue:photo.thumbURL forKey:THUMB_URL];
  [object setValue:photo.deviceId forKey:DEVICE_ID];
  [object setValue:photo.onServer forKey:ON_SERVER];
  [object setValue:photo.dateCreated forKeyPath:DATE_CREATED];
  [object setValue:photo.dateUploaded forKey:DATE_UPLOADED];
  [object setValue:photo.fileName forKey:FILE_NAME];
  [object setValue:photo.isVideo forKey:@"isVideo"];
  [object setValue:photo.tag forKey:@"tag"];
  [object setValue:photo.cover forKey:@"cover"];
  [object setValue:photo.thumbnailName forKey:@"thumbnailName"];
    
  //object = [self relationLocation:photo.location object:object];
   // NSLog(@"obj %@",object);
  //[object setValue:location forKey:@"location"];

  
  if (photo.remoteID != nil) {
    [object setValue:[NSString stringWithFormat:@"%@", photo.remoteID] forKey:REMOTE_ID];
  }
  
  return object;
}

- (void) deletePhotos:(NSArray *) itemPaths {
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    [context performBlock: ^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:PHOTO];

        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dateCreated"
                                                                       ascending:NO];
        [request setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];

        NSError *err;
        NSArray *result = [context executeFetchRequest:request error:&err];

        if (result == nil) {
            NSLog(@"error with core data request");
            abort();
        }
        for (NSIndexPath *itemPath  in itemPaths) {
            [context deleteObject:[result objectAtIndex:itemPath.row]];
        }
        [context save:nil];
    }];

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
    
    NSManagedObject *photoObj;
    if (result.count == 0) {
      photoObj = [NSEntityDescription insertNewObjectForEntityForName:PHOTO inManagedObjectContext:context];
    }else {
      photoObj = result[0];
    }
    
    photoObj = [self setObjectValues:photo object:photoObj];

    [context save:nil];
  }];
}

- (BOOL) addPhoto:(CSPhoto *)photo {
  
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
      NSManagedObject *newPhoto = [NSEntityDescription insertNewObjectForEntityForName:PHOTO inManagedObjectContext:context];
       // NSManagedObject *location = [self relationLocation:photo.location];
      //  NSLog(@"obj %@",location);
      newPhoto = [self setObjectValues:photo object:newPhoto];

      newPhoto = [self relationLocation:photo.location object:newPhoto];

        NSLog(@"obj %@",newPhoto);
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

- (CSPhoto *) getPhotoFromObject: (NSManagedObject *) object {
  CSPhoto *p     = [[CSPhoto alloc] init];

  p.deviceId     = [object valueForKey:DEVICE_ID];
  p.onServer     = [object valueForKey:ON_SERVER];
  p.imageURL     = [object valueForKey:IMAGE_URL];
  p.thumbURL     = [object valueForKey:THUMB_URL];
  p.dateUploaded = [object valueForKey:DATE_UPLOADED];
  p.dateCreated  = [object valueForKey:DATE_CREATED];
  p.remoteID     = [object valueForKey:REMOTE_ID];
  p.fileName     = [object valueForKey:FILE_NAME];
  p.isVideo      = [object valueForKey:@"isVideo"];
  p.tag          = [object valueForKey:@"tag"];
  p.cover        = [object valueForKey:@"cover"];
  NSManagedObject *locationObj = [object valueForKey:@"location"];
  p.location =  [self getLocationFromObject:locationObj];
  p.thumbnailName = [object valueForKey:@"thumbnailName"];
  return p;
}

- (NSMutableArray *)getPhotosWithLocation: (NSString *) deviceId location:(CSLocation *)location{
  NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
  __block NSMutableArray *arr = [[NSMutableArray alloc] init];
  
  [context performBlockAndWait: ^{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:PHOTO];
   // [request setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObjects:@"Location", nil]];
    
    // set query
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(%K = %@) AND (%K = %@) AND (%K = %@) AND (%K = %@)", DEVICE_ID, deviceId, PHOTO_UNIT, location.unit, PHOTO_NAME, location.name, PHOTO_CITY, location.city];
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
      [arr addObject:[self getPhotoFromObject:p]];
    }
  }];
  
  return arr;
}

- (NSMutableArray *)getPhotos: (NSString *) deviceId{
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    __block NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    [context performBlockAndWait: ^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:PHOTO];
        // [request setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObjects:@"Location", nil]];
        
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
            [arr addObject:[self getPhotoFromObject:p]];
        }
    }];
    
    return arr;
}

- (CSPhoto *)getCoverPhoto: (NSString *) deviceId location:(CSLocation *)location{
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    __block CSPhoto *coverPhoto = [[CSPhoto alloc] init];
    
    [context performBlockAndWait: ^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:PHOTO];
        
        // set query
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"(%K = %@) AND (%K = %@) AND (%K = %@) AND (%K = %@) AND (cover = 1)", DEVICE_ID, deviceId, PHOTO_UNIT, location.unit, PHOTO_NAME, location.name, PHOTO_CITY, location.city];
        [request setPredicate:pred];
        // set sort
        NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:DATE_CREATED ascending:NO];
        NSArray *descriptors = [[NSArray alloc] initWithObjects:sort, nil];
        [request setSortDescriptors: descriptors];
        
        NSArray *phs = [context executeFetchRequest:request error:nil];
        
        
        
        if (phs == nil) {
            NSLog(@"error with core data request");
            abort();
        }
        
        // add all of the photo objects to the local photo list
        if (phs.count == 0) {
            coverPhoto = nil;
        } else {
        NSManagedObject *p = phs[0];
        coverPhoto = [self getPhotoFromObject:p];
        }
    }];
    
    return coverPhoto;
}

- (NSString *) getCurrentPhotoOnServerVaule: (NSString *) deviceId CurrentIndex:(int)index{
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    __block CSPhoto *photo;
    __block NSString *photoOnServer;
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
        NSManagedObject *p = phs[index];
        photo = [self getPhotoFromObject:p];
        photoOnServer = photo.onServer;
    }];
    return photoOnServer;
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
      [arr addObject:[self getPhotoFromObject:p]];
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

- (int) getCountUploaded:(NSString *) deviceId  {
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    
    __block int uploaded = 0;
    
    [context performBlockAndWait: ^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:PHOTO];
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"(%K = %@) AND (%K = %@)",DEVICE_ID,deviceId, ON_SERVER, @"1"];
        [request setPredicate:pred];
        
        NSArray*phs = [context executeFetchRequest:request error:nil];
        
        if (phs == nil) {
            NSLog(@"error with core data request");
            abort();
        }
        
        // get count of uploaded photos for specific deviceId on server
        uploaded = phs.count;
    }];
    
    return uploaded;
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

#pragma mark -
#pragma mark Log functions

- (NSManagedObject *) setLogValues: (ActivityHistory *)log object:(NSManagedObject *) message{
    [message setValue:log.activityLog forKey:ACTIVITY_LOG];
    [message setValue:log.timeUpdate forKey:TIME_UPDATE];
    
    return message;
}

- (NSMutableArray *) getLogs{
    
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    __block NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    [context performBlockAndWait: ^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:LOG];
        
        // set sort
        NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:TIME_UPDATE ascending:NO];
        NSArray *descriptors = [[NSArray alloc] initWithObjects:sort, nil];
        [request setSortDescriptors: descriptors];
        
        NSArray *message = [context executeFetchRequest:request error:nil];
        
        if (message == nil) {
            NSLog(@"error with core data request");
            abort();
        }
        
        // add all of the log objects to the local log list
        for (int i =0; i < [message count]; i++) {
            NSManagedObject *logText = message[i];
            [arr addObject:[self getLogFromMessage:logText]];
        }
    }];
    
    return arr;
}

- (ActivityHistory *) getLogFromMessage: (NSManagedObject *) message{
    ActivityHistory *logText = [[ActivityHistory alloc] init];
    logText.activityLog = [message valueForKey:ACTIVITY_LOG];
    logText.timeUpdate = [message valueForKey:TIME_UPDATE];
    return logText;
}

- (void) addUpdateLog:(ActivityHistory *)log{
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    
    [context performBlockAndWait: ^{
        NSManagedObject *logObj;
        
        logObj = [NSEntityDescription insertNewObjectForEntityForName:LOG inManagedObjectContext:context];
        logObj = [self setLogValues:log object:logObj];
        
        [context save:nil];
        
    }];
}

#pragma mark -
#pragma mark Location functions

- (void) addLocation:(CSLocation *)location {
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    
    [context performBlockAndWait: ^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:LOCATION];
        
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"(%K = %@ AND %K = %@ AND %K = %@)",UNIT,location.unit,CITY,location.city,NAME,location.name];
        [request setPredicate:pred];
        

        NSArray *result = [context executeFetchRequest:request error:nil];
        
        
        if (result == nil) {
            NSLog(@"error with core data request");
            abort();
        }
        NSManagedObject *locationObj;
        
        if (result.count == 0) {
            locationObj = [NSEntityDescription insertNewObjectForEntityForName:LOCATION inManagedObjectContext:context];
            NSLog(@"created new device");
        }else {
            locationObj = result[0];
            NSLog(@"updated Location - %@", location.name);
        }

        [locationObj setValue:location.country forKey:COUNTRY];
        [locationObj setValue:location.countryCode forKey:COUNTRYCODE];
        [locationObj setValue:location.city forKey:CITY];
        [locationObj setValue:location.province forKey:PROVINCE];
        [locationObj setValue:location.unit forKey:UNIT];
        [locationObj setValue:location.name forKey:NAME];
        [locationObj setValue:location.longitude forKey:LONG];
        [locationObj setValue:location.latitude forKey:LAT];

        [context save:nil];
        
    }];
}
- (CSLocation *) getLocationFromObject: (NSManagedObject *) object {
    CSLocation *location     = [[CSLocation alloc] init];
    location.country = [object valueForKey:COUNTRY];
    location.countryCode = [object valueForKey:COUNTRYCODE];
    location.city = [object valueForKey:CITY];
    location.province = [object valueForKey:PROVINCE];
    location.unit = [object valueForKey:UNIT];
    location.name = [object valueForKey:NAME];
    location.longitude = [object valueForKey:LONG];
    location.latitude = [object valueForKey:LAT];

    return location;
}

- (NSManagedObject *) relationLocation: (CSLocation *) location object:(NSManagedObject *) object {
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    //[context performBlock: ^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:LOCATION];
        
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"(%K = %@ AND %K = %@ AND %K = %@)",UNIT,location.unit,CITY,location.city,NAME,location.name];
        [request setPredicate:pred];
        
        NSError *err;
        NSArray *result = [context executeFetchRequest:request error:&err];
        
        if (result == nil) {
            NSLog(@"error with core data request");
            abort();
        }
        
        NSManagedObject* resultObj = result[0];
        NSLog(@"result loaction %@",resultObj);
        [object setValue:resultObj forKey:@"location"];
   // }];
    NSLog(@"object loaction %@",object);
    return object;
}

- (NSMutableArray *) getLocations{
    
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    __block NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    [context performBlockAndWait: ^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:LOCATION];
        
        // set sort
        NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:NAME ascending:NO];
        NSArray *descriptors = [[NSArray alloc] initWithObjects:sort, nil];
        [request setSortDescriptors: descriptors];
        
        NSArray *locations = [context executeFetchRequest:request error:nil];
        
        if (locations == nil) {
            NSLog(@"error with core data request");
            abort();
        }
        
        // add all of the log objects to the local log list
        for (int i =0; i < [locations count]; i++) {
            NSManagedObject *locationObj = locations[i];
            [arr addObject:[self getLocationFromObject:locationObj]];
        }
    }];
    
    return arr;
}

- (void) deleteLocation:(CSLocation *) location {
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    [context performBlock: ^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:LOCATION];
        
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"(%K = %@ AND %K = %@ AND %K = %@)",UNIT,location.unit,CITY,location.city,NAME,location.name];
        [request setPredicate:pred];
        
        NSError *err;
        NSArray *result = [context executeFetchRequest:request error:&err];
        
        if (result == nil) {
            NSLog(@"error with core data request");
            abort();
        } else {
        [context deleteObject:result[0]];
        }
        [context save:nil];
    }];
    
}

- (NSMutableArray *) searchLocation: (NSString *) location {
    
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    __block NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    [context performBlockAndWait: ^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:LOCATION];
        
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"(ANY %K CONTAINS[c] %@)",NAME, location];
        [request setPredicate:pred];

        
        // set sort
        NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:NAME ascending:NO];
        NSArray *descriptors = [[NSArray alloc] initWithObjects:sort, nil];
        [request setSortDescriptors: descriptors];
        
        NSArray *locations = [context executeFetchRequest:request error:nil];
        
        if (locations == nil) {
            NSLog(@"error with core data request");
            abort();
        }
        
        // add all of the log objects to the local log list
        for (int i =0; i < [locations count]; i++) {
            NSManagedObject *locationObj = locations[i];
            [arr addObject:[self getLocationFromObject:locationObj]];
        }
    }];
    
    return arr;
}


@end
