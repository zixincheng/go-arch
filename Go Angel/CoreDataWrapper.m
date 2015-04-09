
//  CoreDataWrapper.m
//  Go Arch
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
  [object setValue:photo.thumbOnServer forKey:@"thumbOnServer"];
  [object setValue:photo.fullOnServer forKey:@"fullOnServer"];
  [object setValue:photo.dateCreated forKeyPath:DATE_CREATED];
  [object setValue:photo.dateUploaded forKey:DATE_UPLOADED];
  [object setValue:photo.fileName forKey:FILE_NAME];
  [object setValue:photo.isVideo forKey:@"isVideo"];
  [object setValue:photo.tag forKey:@"tag"];
  [object setValue:photo.thumbnailName forKey:@"thumbnailName"];
    
  //object = [self relationLocation:photo.location object:object];
   // NSLog(@"obj %@",object);
  //[object setValue:location forKey:@"location"];

  
  if (photo.remoteID != nil) {
    [object setValue:[NSString stringWithFormat:@"%@", photo.remoteID] forKey:REMOTE_ID];
  }
  
  return object;
}

- (void) deletePhotos:(CSPhoto *) photo {
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    [context performBlock: ^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:PHOTO];
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"(%K = %@)", IMAGE_URL, photo.imageURL];
        [request setPredicate:pred];

        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dateCreated"
                                                                       ascending:YES];
        [request setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];

        NSError *err;
        NSArray *result = [context executeFetchRequest:request error:&err];

        if (result == nil) {
            NSLog(@"error with core data request");
            abort();
        }
        //for (NSIndexPath *itemPath  in itemPaths) {
        [context deleteObject:result[0]];
        //}
        [context save:nil];
    }];

}

-(void) updatePhotoTag: (NSString *) tag photoId: (NSString *) photoid photo:(CSPhoto *) photo{
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    if (photoid !=nil) {
        [context performBlock: ^{
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:PHOTO];
            
            NSPredicate *pred = [NSPredicate predicateWithFormat:@"(%K = %@)", REMOTE_ID, photoid];
            [request setPredicate:pred];
            
            
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dateCreated"
                                                                           ascending:YES];
            [request setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];

            
            NSError *err;
            NSArray *result = [context executeFetchRequest:request error:&err];
            
            if (result == nil) {
                NSLog(@"error with core data request");
                abort();
            }

            NSManagedObject *photoObj;
            if (result.count == 0) {
                //photoObj = [NSEntityDescription insertNewObjectForEntityForName:PHOTO inManagedObjectContext:context];
            }else {
                photoObj = result[0];
                CSPhoto *p = [self getPhotoFromObject:photoObj];

                if ([p.tag isEqualToString:tag] || (p.tag == nil && tag == nil)) {
                    NSLog(@"dont update tag");
                } else {
                    [photoObj setValue:tag forKey:@"tag"];
                      NSLog(@"update tag");
                    
                    NSArray *objects =
                    [NSArray arrayWithObjects:p.imageURL, nil];
                    NSArray *keys = [NSArray
                                     arrayWithObjects:IMAGE_URL, nil];
                    NSDictionary *photoDic =
                    [NSDictionary dictionaryWithObjects:objects forKeys:keys];
                
                    [context save:nil];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"tagStored" object:nil userInfo:photoDic];
                }
            }
        }];
    } else {
        [context performBlock: ^{
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:PHOTO];
            
            NSPredicate *pred = [NSPredicate predicateWithFormat:@"(%K = %@)", IMAGE_URL, photo.imageURL];
            [request setPredicate:pred];
            
            
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:DATE_CREATED ascending:YES];
            [request setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];

            
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
                CSPhoto *p = [self getPhotoFromObject:photoObj];
                
                if ([p.tag isEqualToString:tag] || (p.tag == nil && tag == nil)) {
                    NSLog(@"dont update tag");
                } else {
                    [photoObj setValue:tag forKey:@"tag"];
                    NSLog(@"update tag");
                    
                    NSArray *objects =
                    [NSArray arrayWithObjects:p.imageURL, nil];
                    NSArray *keys = [NSArray
                                     arrayWithObjects:IMAGE_URL, nil];
                    NSDictionary *photoDic =
                    [NSDictionary dictionaryWithObjects:objects forKeys:keys];
                    
                    [context save:nil];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"tagStored" object:nil userInfo:photoDic];
                }
            }
        }];

    }
    
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
    photoObj = [self relationLocation:photo.location object:photoObj];

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
          // save context to updated other threads
          [context save:nil];
          NSArray *objects =
          [NSArray arrayWithObjects:photo.imageURL, nil];
          NSArray *keys = [NSArray
                           arrayWithObjects:IMAGE_URL, nil];
          NSDictionary *photoDic =
          [NSDictionary dictionaryWithObjects:objects forKeys:keys];
          
          NSLog(@"added new photo to core data");
          [[NSNotificationCenter defaultCenter] postNotificationName:@"addNewPhoto" object:nil userInfo:photoDic];
          
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
  p.thumbOnServer= [object valueForKey:@"thumbOnServer"];
  p.fullOnServer= [object valueForKey:@"fullOnServer"];
  p.imageURL     = [object valueForKey:IMAGE_URL];
  p.thumbURL     = [object valueForKey:THUMB_URL];
  p.dateUploaded = [object valueForKey:DATE_UPLOADED];
  p.dateCreated  = [object valueForKey:DATE_CREATED];
  p.remoteID     = [object valueForKey:REMOTE_ID];
  p.fileName     = [object valueForKey:FILE_NAME];
  p.isVideo      = [object valueForKey:@"isVideo"];
  p.tag          = [object valueForKey:@"tag"];
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
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(%K = %@) AND (%K = %@) AND (%K = %@) AND (%K = %@)", DEVICE_ID, deviceId, PHOTO_UNIT, location.unit, PHOTO_NAME, location.sublocation, PHOTO_CITY, location.city];
    [request setPredicate:pred];
    // set sort
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:DATE_CREATED ascending:YES];
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
        NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:DATE_CREATED ascending:YES];
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

- (CSPhoto *)getPhoto: (NSString *) imageURL{
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    __block CSPhoto *photo = [[CSPhoto alloc] init];
    
    [context performBlockAndWait: ^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:PHOTO];
        
        // set query
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"(%K = %@)",IMAGE_URL,imageURL];
        [request setPredicate:pred];
        // set sort
        NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:DATE_CREATED ascending:YES];
        NSArray *descriptors = [[NSArray alloc] initWithObjects:sort, nil];
        [request setSortDescriptors: descriptors];
        
        NSArray *phs = [context executeFetchRequest:request error:nil];
        
        
        
        if (phs == nil) {
            NSLog(@"error with core data request");
            abort();
        }
        
        // add all of the photo objects to the local photo list
        if (phs.count == 0) {
            photo = nil;
        } else {
            NSManagedObject *p = phs[0];
            photo = [self getPhotoFromObject:p];
        }
    }];
    
    return photo;
}

- (CSPhoto *)getCoverPhoto: (NSString *) deviceId location:(CSLocation *)location{
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    __block CSPhoto *coverPhoto = [[CSPhoto alloc] init];
    
    [context performBlockAndWait: ^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:PHOTO];
        
        // set query
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"(%K = %@) AND (%K = %@) AND (%K = %@) AND (%K = %@) AND (%K = %@)", DEVICE_ID, deviceId, PHOTO_UNIT, location.unit, PHOTO_NAME, location.sublocation, PHOTO_CITY, location.city,IMAGE_URL,location.album.coverImage];
        [request setPredicate:pred];
        // set sort
        NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:DATE_CREATED ascending:YES];
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
        photoOnServer = photo.thumbOnServer;
    }];
    return photoOnServer;
}
     
- (NSMutableArray *) getPhotosToUpload {
  NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
  __block NSMutableArray *arr = [[NSMutableArray alloc] init];
  
  [context performBlockAndWait: ^{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:PHOTO];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(%K = %@)",THUMB_ON_SERVER, @"0"];
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
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(%K = %@)", THUMB_ON_SERVER, @"0"];
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
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"(%K = %@) AND (%K = %@)",DEVICE_ID,deviceId, THUMB_ON_SERVER, @"1"];
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

- (int) getFullImageCountUnUploaded {
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    
    __block int unUploaded = 0;
    
    [context performBlockAndWait: ^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:PHOTO];
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"(%K = %@)", FULL_ON_SERVER, @"0"];
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

- (int) getFullImageCountUploaded:(NSString *) deviceId  {
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    
    __block int uploaded = 0;
    
    [context performBlockAndWait: ^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:PHOTO];
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"(%K = %@) AND (%K = %@)",DEVICE_ID,deviceId, FULL_ON_SERVER, @"1"];
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

- (NSMutableArray *) getFullSizePhotosToUpload {
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    __block NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    [context performBlockAndWait: ^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:PHOTO];
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"(%K = %@)",FULL_ON_SERVER, @"0"];
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

- (NSString *) getLatestId {
  NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
  __block NSString *latestId = @"-1";
  
  [context performBlockAndWait: ^{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:PHOTO];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(%K = %@)", THUMB_ON_SERVER, @"1"];
    [request setPredicate:pred];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:REMOTE_ID ascending:YES];
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
        //logObj = [self setLogValues:log object:logObj];
        
        [context save:nil];
        
    }];
}

#pragma mark -
#pragma mark Location functions


// uses the the location.objectUri to lookup object and update to latest values in cslocation
- (void) updateLocation:(CSLocation *)location album:(CSAlbum *)album {
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    
    [context performBlockAndWait:^{
        NSURL *url = [NSURL URLWithString:location.objectUri];
        NSManagedObjectID *objectID = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation:url];
        NSManagedObject *obj = [context objectWithID:objectID];
        
        if (obj == nil) {
            NSLog(@"there is no object with that id");
            return;
        }
        
        [obj setValue:location.country forKey:COUNTRY];
        [obj setValue:location.countryCode forKey:COUNTRYCODE];
        [obj setValue:location.city forKey:CITY];
        [obj setValue:location.province forKey:PROVINCE];
        [obj setValue:location.unit forKey:UNIT];
        [obj setValue:location.sublocation forKey:SUBLOCATION];
        [obj setValue:location.longitude forKey:LONG];
        [obj setValue:location.latitude forKey:LAT];
        [obj setValue:location.postCode forKey:POSTALCODE];
        
        NSManagedObject *meta = [self updateAlbum:obj album:album];
        
        [obj setValue:meta forKey:@"metaData"];
        
        [context save: nil];
        
        NSLog(@"updated location object in db");
    }];
}

- (void) addLocation:(CSLocation *)location album :(CSAlbum *) album{
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    
    [context performBlockAndWait: ^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:LOCATION];
        
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"(%K = %@ AND %K = %@ AND %K = %@)",UNIT,location.unit,CITY,location.city,SUBLOCATION,location.sublocation];
        [request setPredicate:pred];
        

        NSArray *result = [context executeFetchRequest:request error:nil];
        
        
        if (result == nil) {
            NSLog(@"error with core data request");
            abort();
        }
        NSManagedObject *locationObj;
        
        if (result.count == 0) {
            locationObj = [NSEntityDescription insertNewObjectForEntityForName:LOCATION inManagedObjectContext:context];
            NSLog(@"created new Location");
        }else {
            locationObj = result[0];
            NSLog(@"updated Location - %@", location.sublocation);
        }

        [locationObj setValue:location.country forKey:COUNTRY];
        [locationObj setValue:location.countryCode forKey:COUNTRYCODE];
        [locationObj setValue:location.city forKey:CITY];
        [locationObj setValue:location.province forKey:PROVINCE];
        [locationObj setValue:location.unit forKey:UNIT];
        [locationObj setValue:location.sublocation forKey:SUBLOCATION];
        [locationObj setValue:location.longitude forKey:LONG];
        [locationObj setValue:location.latitude forKey:LAT];
        [locationObj setValue:location.postCode forKey:POSTALCODE];
        
        NSManagedObject *meta =[self updateAlbum:locationObj album:album];
        
        [locationObj setValue:meta forKey:@"metaData"];

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
    location.sublocation = [object valueForKey:SUBLOCATION];
    location.longitude = [object valueForKey:LONG];
    location.latitude = [object valueForKey:LAT];
    location.postCode = [object valueForKey:POSTALCODE];
    NSManagedObject *locationMetaObj = [object valueForKey:@"metaData"];
    location.album =  [self getLocationMetaFromObject:locationMetaObj];

    // store nsmanagedobject uri into location
    location.objectUri = [[[object objectID] URIRepresentation] absoluteString];
  
    return location;
}

-(CSAlbum *)getLocationMetaFromObject: (NSManagedObject *) object {
    CSAlbum *album = [[CSAlbum alloc]init];

    album.bed = [object valueForKey:BED];
    album.tag = [object valueForKey:TAG];
    album.type = [object valueForKey:TYPE];
    album.price = [object valueForKey:PRICE];
    album.listing = [object valueForKey:LISTING];
    album.yearBuilt = [object valueForKey:YEARBUILT];
    album.landSqft = [object valueForKey:LANDSQFT];
    album.bath = [object valueForKey:BATH];
    album.buildingSqft = [object valueForKey:BUILDINGSQFT];
    album.mls = [object valueForKey:MLS];
    album.albumDescritpion = [object valueForKey:DESCRIPTION];
    album.albumId = [object valueForKey:ALBUMID];
    album.name = [object valueForKey:NAME];
    album.coverImage = [object valueForKey:COVERIMAGE];
    
    return album;
    
}

- (NSManagedObject *) relationLocation: (CSLocation *) location object:(NSManagedObject *) object {
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];

        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:LOCATION];
        
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"(%K = %@ AND %K = %@ AND %K = %@)",UNIT,location.unit,CITY,location.city,SUBLOCATION,location.sublocation];
        [request setPredicate:pred];
        
        NSError *err;
        NSArray *result = [context executeFetchRequest:request error:&err];
        
        if (result == nil) {
            NSLog(@"error with core data request");
            abort();
        }
        
        NSManagedObject* resultObj = result[0];
        [object setValue:resultObj forKey:@"location"];
    return object;
}

- (NSMutableArray *) getLocations{
    
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    __block NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    [context performBlockAndWait: ^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:LOCATION];
        
        // set sort
        NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:SUBLOCATION ascending:YES];
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

-(NSMutableArray *)filterLocations: (NSMutableDictionary *)filterInfo {
    
    NSPredicate *predicate = [self getPredicate:filterInfo];
    
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    __block NSMutableArray *arr = [[NSMutableArray alloc]init];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:LOCATION];
        
    NSPredicate *pred =predicate;
        //[NSPredicate predicateWithFormat:@"(metaData.bed = %@ AND )",bedRoom];
        
    [request setPredicate:pred];
        // set sort
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:SUBLOCATION ascending:YES];
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
    
    return arr;
}

-(NSPredicate *)getPredicate: (NSMutableDictionary *)filterInfo {
    NSNumber *priceMax = [filterInfo objectForKey:@"MaxPrice"];
    NSNumber *priceMin = [filterInfo objectForKey:@"MinPrice"];
    NSNumber *buildingSize = [filterInfo objectForKey:@"homeSize"];
    NSNumber *landSize = [filterInfo objectForKey:@"lotSize"];
    NSString *yearBuilt = [filterInfo objectForKey:@"yearBuilt"];
    NSString *bedRoom = [filterInfo objectForKey:@"bedRoom"];
    NSString *bathRoom = [filterInfo objectForKey:@"bathRoom"];
    NSString *type = [filterInfo objectForKey:@"type"];
    NSString *listing = [filterInfo objectForKey:@"listing"];
    
    NSPredicate *predicateBed;
    if ([bedRoom integerValue] == 0 || [bedRoom integerValue] == 7) {
        predicateBed = [NSPredicate predicateWithFormat:@"metaData.bed > %@",bedRoom];
    } else {
        predicateBed = [NSPredicate predicateWithFormat:@"metaData.bed = %@",bedRoom];
    }
    NSPredicate *predicateBath;
    if ([bedRoom integerValue] == 0 || [bedRoom integerValue] == 6) {
        predicateBath = [NSPredicate predicateWithFormat:@"metaData.bed > %@",bathRoom];
    } else {
        predicateBath = [NSPredicate predicateWithFormat:@"metaData.bed = %@",bathRoom];
    }
    NSPredicate *predicatePrice = [NSPredicate predicateWithFormat:@"metaData.price < %@ AND metaData.price > %@",priceMax,priceMin];
    
    NSPredicate *predicateHomeSize = [NSPredicate predicateWithFormat:@"metaData.buildingSqft > %@",buildingSize];
    NSPredicate *predicateLotSize = [NSPredicate predicateWithFormat:@"metaData.landSqft.integerValue > %@",landSize];
    NSPredicate *predicateYearBuilt;
    if ([yearBuilt isEqualToString: @"1965"]) {
        predicateYearBuilt = [NSPredicate predicateWithFormat:@"metaData.yearBuilt <= %@",yearBuilt];
    } else {
        predicateYearBuilt = [NSPredicate predicateWithFormat:@"metaData.yearBuilt > %@",yearBuilt];
    }
    
    NSPredicate *predicateType;
    if ([type isEqualToString:@"Any"]) {
        predicateType = [NSPredicate predicateWithFormat:@"metaData.yearBuilt > %@",@"0"];;
    } else {
        predicateType = [NSPredicate predicateWithFormat:@"metaData.type = %@",type];
    }
    
    NSPredicate *predicateList;
    if ([listing isEqualToString:@"Any"]) {
        predicateList = [NSPredicate predicateWithFormat:@"metaData.yearBuilt > %@",@"0"];
    } else {
        predicateList = [NSPredicate predicateWithFormat:@"metaData.listing = %@",listing];
    }
    NSPredicate *pre = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicateBed,predicateBath,predicatePrice,predicateYearBuilt,predicateType,predicateList,predicateHomeSize,predicateLotSize]];
    return pre;
}

- (void) deleteLocation:(CSLocation *) location {
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    [context performBlock: ^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:LOCATION];
        
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"(%K = %@ AND %K = %@ AND %K = %@)",UNIT,location.unit,CITY,location.city,SUBLOCATION,location.sublocation];
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
        
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"(ANY %K CONTAINS[c] %@)",SUBLOCATION, location];
        [request setPredicate:pred];

        
        // set sort
        NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:SUBLOCATION ascending:YES];
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

#pragma location metadata functions

- (NSManagedObject *) updateAlbum:(NSManagedObject*) locationObj album : (CSAlbum *)album  {
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    
        NSManagedObject *meta = [NSEntityDescription insertNewObjectForEntityForName:ALBUM inManagedObjectContext:context];
        
        [meta setValue:album.bed forKey:BED];
        [meta setValue:album.tag forKey:TAG];
        [meta setValue:album.type forKey:TYPE];
        [meta setValue:album.price forKey:PRICE];
        [meta setValue:album.listing forKey:LISTING];
        [meta setValue:album.yearBuilt forKey:YEARBUILT];
        [meta setValue:album.landSqft forKey:LANDSQFT];
        [meta setValue:album.bath forKey:BATH];
        [meta setValue:album.buildingSqft forKey:BUILDINGSQFT];
        [meta setValue:album.mls forKey:MLS];
        [meta setValue:album.coverImage forKey:COVERIMAGE];
        [meta setValue:album.name forKey:NAME];
        [meta setValue:album.albumDescritpion forKey:DESCRIPTION];
        [meta setValue:album.albumId forKey:ALBUMID];
    
        
        [context save:nil];
        return meta;
}


@end
