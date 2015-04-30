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
    photoObj = [self relationAlbum:photo.album object:photoObj];

    [context save:nil];
  }];
}


- (BOOL) addPhotoArray:(NSArray *)photoArray {
    
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    
    __block BOOL added = NO;
    __block int count = photoArray.count;
    [context performBlockAndWait:^{
        for (CSPhoto *photo in photoArray) {
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
                
                newPhoto = [self relationAlbum:photo.album object:newPhoto];
                // save context to updated other threads
                [context save:nil];
                NSArray *objects =
                [NSArray arrayWithObjects:photo.imageURL, nil];
                NSArray *keys = [NSArray
                                 arrayWithObjects:IMAGE_URL, nil];
                NSDictionary *photoDic =
                [NSDictionary dictionaryWithObjects:objects forKeys:keys];
                
                NSLog(@"added new photo to core data");
                //[[NSNotificationCenter defaultCenter] postNotificationName:@"addNewPhoto" object:nil userInfo:photoDic];
                count --;
                if (count == 0) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"addNewPhoto" object:nil];
                }
                
                added = YES;
            }else {
                NSLog(@"photo already in core data");
            }

        }
            }];
    return added;
}


- (BOOL) addPhoto:(CSPhoto *)photo {
  
  NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    NSLog(@"photo objectid %@",photo.album.objectId);
  __block BOOL added = NO;
  
  //[context performBlockAndWait:^{
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
          
          newPhoto = [self relationAlbum:photo.album object:newPhoto];
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
  //}];
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
  NSManagedObject *albumObj = [object valueForKey:@"album"];
  p.album =  [self getAlbumFromObject:albumObj];
  p.thumbnailName = [object valueForKey:@"thumbnailName"];
  return p;
}

- (NSMutableArray *)getPhotosWithAlbum: (NSString *) deviceId album:(CSAlbum *)album{
  NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
  __block NSMutableArray *arr = [[NSMutableArray alloc] init];
  
  [context performBlockAndWait: ^{

    NSURL *url = [NSURL URLWithString:album.objectId];
    NSManagedObjectID *objectID = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation:url];
    NSManagedObject *albumObj = [context objectWithID:objectID];
    NSSet *phs = [albumObj valueForKey:@"photo"];


    NSArray *array = [phs allObjects];
    
    if (phs == nil) {
      NSLog(@"error with core data request");
      abort();
    }
    
    // add all of the photo objects to the local photo list
    for (int i =0; i < [array count]; i++) {
      NSManagedObject *p = array[i];
      [arr addObject:[self getPhotoFromObject:p]];
    }
  }];
  
  return arr;
}

- (NSMutableArray *)getThumbsToUploadWithAlbum: (NSString *) deviceId album:(CSAlbum *)album{
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    __block NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    [context performBlockAndWait: ^{
        
        NSURL *url = [NSURL URLWithString:album.objectId];
        NSManagedObjectID *objectID = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation:url];
        NSManagedObject *albumObj = [context objectWithID:objectID];
        NSSet *phs = [albumObj valueForKey:@"photo"];
        
        
        NSArray *array = [phs allObjects];
        
        
        
        if (phs == nil) {
            NSLog(@"error with core data request");
            abort();
        }
        
        // add all of the photo objects to the local photo list
        for (int i =0; i < [array count]; i++) {
            NSManagedObject *p = array[i];
            CSPhoto *photo = [self getPhotoFromObject:p];
            if ([photo.thumbOnServer isEqualToString:@"0"]) {
                [arr addObject:photo];
            }
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

- (CSPhoto *)getCoverPhoto: (NSString *) deviceId album:(CSAlbum *)album{
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    __block CSPhoto *coverPhoto = [[CSPhoto alloc] init];
    if (album.coverImage == nil) {
        return nil;
    }
    
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:PHOTO];
        
        // set query
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"(%K = %@) AND (%K = %@)", DEVICE_ID, deviceId, REMOTE_ID, album.coverImage];
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
#pragma mark Create Album functions

- (void) addAlbum:(CSAlbum *) album {
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    
    [context performBlockAndWait: ^{

        NSManagedObject *albumObj = [NSEntityDescription insertNewObjectForEntityForName:ALBUM inManagedObjectContext:context];
     
        [albumObj setValue:album.name forKey:NAME];
        [albumObj setValue:album.albumDescritpion forKey:DESCRIPTION];
        [albumObj setValue:album.albumId forKey:ALBUMID];
        [albumObj setValue:album.coverImage forKey:COVERIMAGE];
        [albumObj setValue:album.version forKey:@"version"];
        
        // store nsmanagedobject uri into location
        //album.objectId = [[[albumObj objectID] URIRepresentation] absoluteString];
        //[albumObj setValue:album.objectId forKey:@"objectId"];
        NSManagedObject *entryObj = [albumObj valueForKey:@"entry"];
        entryObj = [self setEntryObject:album entryObj:entryObj];
        
        [albumObj setValue:entryObj forKey:@"entry"];

        [context save:nil];

        album.objectId = [[[albumObj objectID] URIRepresentation] absoluteString];
    }];
}

-(NSManagedObject *) setEntryObject:(CSAlbum *) album entryObj :(NSManagedObject *) entryObj{
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];

    if (entryObj == nil) {
        entryObj = [NSEntityDescription insertNewObjectForEntityForName:ENTRY inManagedObjectContext:context];
    }

    [entryObj setValue:album.entry.bed forKey:BED];
    [entryObj setValue:album.entry.tag forKey:TAG];
    [entryObj setValue:album.entry.type forKey:TYPE];
    [entryObj setValue:album.entry.price forKey:PRICE];
    [entryObj setValue:album.entry.listing forKey:LISTING];
    [entryObj setValue:album.entry.yearBuilt forKey:YEARBUILT];
    [entryObj setValue:album.entry.landSqft forKey:LANDSQFT];
    [entryObj setValue:album.entry.bath forKey:BATH];
    [entryObj setValue:album.entry.buildingSqft forKey:BUILDINGSQFT];
    [entryObj setValue:album.entry.mls forKey:MLS];
    
    
    NSManagedObject * locationObj = [entryObj valueForKey:@"locationEntry"];
    locationObj= [self setLocationObject:album locationObj:locationObj];
    
    [entryObj setValue:locationObj forKey:@"locationEntry"];
    
    [context save:nil];
    return entryObj;
}


-(NSManagedObject *) setLocationObject:(CSAlbum *) album locationObj: (NSManagedObject *) locationObj{
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];

    if (locationObj == nil) {
        locationObj = [NSEntityDescription insertNewObjectForEntityForName:LOCATION inManagedObjectContext:context];
    }

    [locationObj setValue:album.entry.location.country forKey:COUNTRY];
    [locationObj setValue:album.entry.location.countryCode forKey:COUNTRYCODE];
    [locationObj setValue:album.entry.location.city forKey:CITY];
    [locationObj setValue:album.entry.location.province forKey:PROVINCE];
    [locationObj setValue:album.entry.location.unit forKey:UNIT];
    [locationObj setValue:album.entry.location.sublocation forKey:SUBLOCATION];
    [locationObj setValue:album.entry.location.longitude forKey:LONG];
    [locationObj setValue:album.entry.location.latitude forKey:LAT];
    [locationObj setValue:album.entry.location.postCode forKey:POSTALCODE];
    [locationObj setValue:album.entry.location.altitude forKey:ALTITUDE];
    
    [context save:nil];
    return locationObj;
}

#pragma mark -
#pragma mark Update Album functions

- (void) updateAlbum:(CSAlbum *)album {
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    
        NSURL *url = [NSURL URLWithString:album.objectId];
        NSManagedObject *albumObj;

        if (album.albumId == nil) {
            NSManagedObjectID *objectID = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation:url];
            albumObj = [context objectWithID:objectID];
        } else {
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:ALBUM];
            
            NSPredicate *pred = [NSPredicate predicateWithFormat:@"(%K = %@)",ALBUMID,album.albumId];
            [request setPredicate:pred];
            
            
            NSArray *result = [context executeFetchRequest:request error:nil];
            
            if (result.count == 0) {
                NSURL *url = [NSURL URLWithString:album.objectId];
                if (url !=nil) {
                    NSManagedObjectID *objectID = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation:url];
                    albumObj = [context objectWithID:objectID];
                } else{
                    return;
                }

            } else {
            albumObj = [result objectAtIndex:0];
            }
        }
        if (albumObj == nil) {
            NSLog(@"error with core data request");
            return;
        }
        
        [albumObj setValue:album.name forKey:NAME];
        [albumObj setValue:album.albumDescritpion forKey:DESCRIPTION];
        [albumObj setValue:album.albumId forKey:ALBUMID];
        [albumObj setValue:album.coverImage forKey:COVERIMAGE];
        [albumObj setValue:album.version forKey:@"version"];
    
         NSManagedObject *entryObj = [albumObj valueForKey:ENTRY];
        
        entryObj = [self setEntryObject:album entryObj:entryObj];
        [albumObj setValue:entryObj forKey:@"entry"];
         
        [context save:nil];
        NSLog(@"updated album object in db");
}


#pragma mark -
#pragma mark Get Album functions

- (NSMutableArray *) getAllAlbums{
    
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    __block NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    [context performBlockAndWait: ^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:ALBUM];
        
        // set sort
        NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:NAME ascending:YES];
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
            [arr addObject:[self getAlbumFromObject:locationObj]];
        }
    }];
    
    return arr;
}

- (CSAlbum *) getSingleAlbum:(CSAlbum *)album{
    __block CSAlbum *returnAlbum = [[CSAlbum alloc]init];
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    NSURL *url = [NSURL URLWithString:album.objectId];
    NSManagedObjectID *objectID = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation:url];
    NSManagedObject *albumObj = [context objectWithID:objectID];
        
    if (albumObj == nil) {
        NSLog(@"error with core data request");
        abort();
    } else {
        returnAlbum = [self getAlbumFromObject:albumObj];
    }
    [context save:nil];
    
    return returnAlbum;
}

- (CSAlbum *) getAlbumFromObject: (NSManagedObject *) object {
    CSAlbum *album     = [[CSAlbum alloc] init];
    album.albumDescritpion = [object valueForKey:DESCRIPTION];
    album.albumId = [object valueForKey:ALBUMID];
    album.name = [object valueForKey:NAME];
    album.coverImage = [object valueForKey:COVERIMAGE];
    album.version = [object valueForKey:@"version"];
    album.objectId = [[[object objectID] URIRepresentation] absoluteString];
    NSManagedObject *entryObjcet = [object valueForKey:@"entry"];
    album.entry =  [self getEntryFromObject:entryObjcet];

    
    return album;
}

-(CSEntry *)getEntryFromObject: (NSManagedObject *) object {
    CSEntry *entry = [[CSEntry alloc]init];
    
    entry.bed = [object valueForKey:BED];
    entry.tag = [object valueForKey:TAG];
    entry.type = [object valueForKey:TYPE];
    entry.price = [object valueForKey:PRICE];
    entry.listing = [object valueForKey:LISTING];
    entry.yearBuilt = [object valueForKey:YEARBUILT];
    entry.landSqft = [object valueForKey:LANDSQFT];
    entry.bath = [object valueForKey:BATH];
    entry.buildingSqft = [object valueForKey:BUILDINGSQFT];
    entry.mls = [object valueForKey:MLS];
    
    NSManagedObject *entryObjcet = [object valueForKey:@"locationEntry"];
    entry.location =  [self getLocationFromObject:entryObjcet];
    
    return entry;
    
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
    location.altitude = [object valueForKey:ALTITUDE];
    location.postCode = [object valueForKey:POSTALCODE];
    
    // store nsmanagedobject uri into location
    location.objectUri = [[[object objectID] URIRepresentation] absoluteString];
    
    return location;
}


#pragma mark -
#pragma mark Delete Album functions

- (void) deleteAlbum:(CSAlbum *) album {
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    [context performBlock: ^{
        NSURL *url = [NSURL URLWithString:album.objectId];
        NSManagedObjectID *objectID = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation:url];
        NSManagedObject *albumObj = [context objectWithID:objectID];
        
        if (albumObj == nil) {
            NSLog(@"error with core data request");
            abort();
        } else {
            [context deleteObject:albumObj];
        }
        [context save:nil];
    }];
    
}

/*####################
####################
####################
####################
*/
#pragma mark -
#pragma mark Location functions

/*
// uses the the location.objectUri to lookup object and update to latest values in cslocation
- (void) updateLocation:(CSLocation *)location album:(CSEntry *)entry {
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
        
        NSManagedObject *meta = [self updateAlbum:obj entry:entry];
        
        [obj setValue:meta forKey:@"metaData"];
        
        [context save: nil];
        
        NSLog(@"updated location object in db");
    }];
}

- (void) addLocation:(CSLocation *)location album :(CSEntry *) entry{
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
        
        NSManagedObject *meta =[self updateAlbum:locationObj entry:entry];
        
        [locationObj setValue:meta forKey:@"entry"];

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
    NSManagedObject *locationMetaObj = [object valueForKey:@"entry"];
    location.entry =  [self getLocationMetaFromObject:locationMetaObj];

    // store nsmanagedobject uri into location
    location.objectUri = [[[object objectID] URIRepresentation] absoluteString];
  
    return location;
}

-(CSEntry *)getLocationMetaFromObject: (NSManagedObject *) object {
    CSEntry *entry = [[CSEntry alloc]init];

    entry.bed = [object valueForKey:BED];
    entry.tag = [object valueForKey:TAG];
    entry.type = [object valueForKey:TYPE];
    entry.price = [object valueForKey:PRICE];
    entry.listing = [object valueForKey:LISTING];
    entry.yearBuilt = [object valueForKey:YEARBUILT];
    entry.landSqft = [object valueForKey:LANDSQFT];
    entry.bath = [object valueForKey:BATH];
    entry.buildingSqft = [object valueForKey:BUILDINGSQFT];
    entry.mls = [object valueForKey:MLS];
    album.albumDescritpion = [object valueForKey:DESCRIPTION];
    album.albumId = [object valueForKey:ALBUMID];
    album.name = [object valueForKey:NAME];
    entry.coverImage = [object valueForKey:COVERIMAGE];
    
    return entry;
    
}

-(CSEntry *)getAlbumFromObject: (NSManagedObject *) object {
    CSEntry *entry = [[CSEntry alloc]init];
    
    entry.bed = [object valueForKey:BED];
    entry.tag = [object valueForKey:TAG];
    entry.type = [object valueForKey:TYPE];
    entry.price = [object valueForKey:PRICE];
    entry.listing = [object valueForKey:LISTING];
    entry.yearBuilt = [object valueForKey:YEARBUILT];
    entry.landSqft = [object valueForKey:LANDSQFT];
    entry.bath = [object valueForKey:BATH];
    entry.buildingSqft = [object valueForKey:BUILDINGSQFT];
    entry.mls = [object valueForKey:MLS];
    album.albumDescritpion = [object valueForKey:DESCRIPTION];
    album.albumId = [object valueForKey:ALBUMID];
    album.name = [object valueForKey:NAME];
    entry.coverImage = [object valueForKey:COVERIMAGE];
    NSManagedObject *locationObj = [object valueForKey:@"Location"];
    entry.location =  [self getLocationFromObject:locationObj];
    
    return entry;
    
}
*/
- (NSManagedObject *) relationAlbum: (CSAlbum *) album object:(NSManagedObject *) object {
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];

    NSURL *url = [NSURL URLWithString:album.objectId];
    NSManagedObjectID *objectID = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation:url];
    NSManagedObject *obj = [context objectWithID:objectID];
        
        if (obj == nil) {
            NSLog(@"error with core data request");
            abort();
        }
    
        [object setValue:obj forKey:@"album"];
    return object;
}
/*
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
*/
-(NSMutableArray *)filterLocations: (NSMutableDictionary *)filterInfo {
    
    NSPredicate *predicate = [self getPredicate:filterInfo];
    
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    __block NSMutableArray *arr = [[NSMutableArray alloc]init];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:ALBUM];
        
    NSPredicate *pred =predicate;
        //[NSPredicate predicateWithFormat:@"(metaData.bed = %@ AND )",bedRoom];
        
    [request setPredicate:pred];
        // set sort
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:NAME ascending:YES];
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
        [arr addObject:[self getAlbumFromObject:locationObj]];
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
        predicateBed = [NSPredicate predicateWithFormat:@"entry.bed > %@",bedRoom];
    } else {
        predicateBed = [NSPredicate predicateWithFormat:@"entry.bed = %@",bedRoom];
    }
    NSPredicate *predicateBath;
    if ([bedRoom integerValue] == 0 || [bedRoom integerValue] == 6) {
        predicateBath = [NSPredicate predicateWithFormat:@"entry.bed > %@",bathRoom];
    } else {
        predicateBath = [NSPredicate predicateWithFormat:@"entry.bed = %@",bathRoom];
    }
    NSPredicate *predicatePrice = [NSPredicate predicateWithFormat:@"entry.price < %@ AND entry.price > %@",priceMax,priceMin];
    
    NSPredicate *predicateHomeSize = [NSPredicate predicateWithFormat:@"entry.buildingSqft >= %@",buildingSize];
    NSPredicate *predicateLotSize = [NSPredicate predicateWithFormat:@"entry.landSqft.integerValue >= %@",landSize];
    NSPredicate *predicateYearBuilt;
    if ([yearBuilt isEqualToString: @"1965"]) {
        predicateYearBuilt = [NSPredicate predicateWithFormat:@"entry.yearBuilt <= %@",yearBuilt];
    } else {
        predicateYearBuilt = [NSPredicate predicateWithFormat:@"entry.yearBuilt > %@",yearBuilt];
    }
    
    NSPredicate *predicateType;
    if ([type isEqualToString:@"Any"]) {
        predicateType = [NSPredicate predicateWithFormat:@"entry.yearBuilt > %@",@"0"];;
    } else {
        predicateType = [NSPredicate predicateWithFormat:@"entry.type = %@",type];
    }
    
    NSPredicate *predicateList;
    if ([listing isEqualToString:@"Any"]) {
        predicateList = [NSPredicate predicateWithFormat:@"entry.yearBuilt > %@",@"0"];
    } else {
        predicateList = [NSPredicate predicateWithFormat:@"entry.listing = %@",listing];
    }
    NSPredicate *pre = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicateBed,predicateBath,predicatePrice,predicateYearBuilt,predicateType,predicateList,predicateHomeSize,predicateLotSize]];
    return pre;
}
/*
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
*/
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
/*
- (NSManagedObject *) updateAlbum:(NSManagedObject*) locationObj entry : (CSEntry *)entry  {
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    NSManagedObject *entryObj;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:ENTRY];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(%K = %@ AND %K = %@ AND %K = %@)",PHOTO_UNIT,entry.location.unit,PHOTO_CITY,entry.location.city,PHOTO_NAME,entry.location.sublocation];
        [request setPredicate:pred];
        
        
    NSArray *result = [context executeFetchRequest:request error:nil];
        
        
    if (result == nil) {
        NSLog(@"error with core data request");
        abort();
    }
        
    if (result.count == 0) {
        entryObj = [NSEntityDescription insertNewObjectForEntityForName:ENTRY inManagedObjectContext:context];
        NSLog(@"created new Album");
    }else {
        entryObj = result[0];
        NSLog(@"updated Album - %@", entry.location.sublocation);
    }

    [entryObj setValue:entry.bed forKey:BED];
    [entryObj setValue:entry.tag forKey:TAG];
    [entryObj setValue:entry.type forKey:TYPE];
    [entryObj setValue:entry.price forKey:PRICE];
    [entryObj setValue:entry.listing forKey:LISTING];
    [entryObj setValue:entry.yearBuilt forKey:YEARBUILT];
    [entryObj setValue:entry.landSqft forKey:LANDSQFT];
    [entryObj setValue:entry.bath forKey:BATH];
    [entryObj setValue:entry.buildingSqft forKey:BUILDINGSQFT];
    [entryObj setValue:entry.mls forKey:MLS];
    [entryObj setValue:entry.coverImage forKey:COVERIMAGE];
    [albumObj setValue:album.name forKey:NAME];
    [albumObj setValue:album.albumDescritpion forKey:DESCRIPTION];
    [albumObj setValue:album.albumId forKey:ALBUMID];
    
        
    [context save:nil];
     return entryObj;
}
*/
- (NSMutableArray *) getAlbumsToUpload {
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    __block NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    [context performBlockAndWait: ^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:ALBUM];
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"(albumId = nil)"];
        [request setPredicate:pred];
        
        NSArray*phs = [context executeFetchRequest:request error:nil];
        
        if (phs == nil) {
            NSLog(@"error with core data request");
            abort();
        }
        
        // add all of the photo objects to the local photo list
        for (int i =0; i < [phs count]; i++) {
            NSManagedObject *p = phs[i];
            [arr addObject:[self getAlbumFromObject:p]];

        }
    }];
    
    return arr;
}

- (NSMutableArray *) getAlbumsAlreadyUploaded {
    NSManagedObjectContext *context = [CoreDataStore privateQueueContext];
    __block NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    [context performBlockAndWait: ^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:ALBUM];
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"(albumId != nil)"];
        [request setPredicate:pred];
        
        NSArray*phs = [context executeFetchRequest:request error:nil];
        
        if (phs == nil) {
            NSLog(@"error with core data request");
            abort();
        }
        
        // add all of the photo objects to the local photo list
        for (int i =0; i < [phs count]; i++) {
            NSManagedObject *p = phs[i];
            [arr addObject:[self getAlbumFromObject:p]];
            
        }
    }];
    
    return arr;
}
/*
- (NSManagedObject *) relationAlbum: (CSLocation *) location object:(NSManagedObject *) object {
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

*/
@end
