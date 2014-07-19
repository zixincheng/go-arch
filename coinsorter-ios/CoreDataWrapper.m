
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

- (id) init {
    dbInsertQueue = dispatch_queue_create("com.acdgo.dbinsertqueue.com", DISPATCH_QUEUE_SERIAL);
    dbFetchQueue = dispatch_queue_create("com.acdgo.dbfetchqueue.com", DISPATCH_QUEUE_SERIAL);
    
    return self;
}

- (void) addUpdateDevice:(CSDevice *)device {
    
    dispatch_async(dbInsertQueue, ^ {
        NSString *cidString = device.remoteId;
        
        AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        NSManagedObjectContext *context = [appDelegate managedObjectContext];
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        
        NSEntityDescription *entityDesc = [NSEntityDescription entityForName:DEVICE inManagedObjectContext:context];
        [request setEntity:entityDesc];
        
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"(remoteId = %@)", cidString];
        [request setPredicate:pred];
        
        NSError *err;
        NSArray *result = [context executeFetchRequest:request error:&err];
        
        NSAssert(![NSThread isMainThread], @"MAIN THREAD WHEN USING DB!!!");
        
        if (result == nil) {
            NSLog(@"error with core data request");
            abort();
        }
        
        if (result.count == 0) {
            NSManagedObject *newPhoto = [NSEntityDescription insertNewObjectForEntityForName:DEVICE inManagedObjectContext:context];
            
            [newPhoto setValue:device.deviceName forKey:@"deviceName"];
            [newPhoto setValue:device.remoteId forKey:@"remoteId"];
            
            [appDelegate saveContext];
            
            NSLog(@"created new device");
        }else {
            NSManagedObjectContext *updatePhoto = result[0];
            
            [updatePhoto setValue:device.deviceName forKey:@"deviceName"];
            [updatePhoto setValue:device.remoteId forKey:@"remoteId"];
            
            [appDelegate saveContext];
            
            NSLog(@"updated device - %@", device.deviceName);
        }
        
    });
}

- (CSDevice *) getDevice:(NSString *)cid {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(remoteId = %@)", cid];
    [request setPredicate:pred];
    
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:DEVICE inManagedObjectContext:context];
    [request setEntity:entityDesc];
    
    NSError *err;
    NSArray *result = [context executeFetchRequest:request error:&err];
    
    if (result == nil) {
        NSLog(@"error with core data");
        abort();
    }
    
    if (result.count > 0) {
        NSManagedObject *obj = result[0];
        
        CSDevice *device = [[CSDevice alloc] init];
        device.remoteId = cid;
        device.deviceName = [obj valueForKey:@"deviceName"];
        
        return device;
    }else {
        return nil;
    }
}

- (void) addPhoto:(CSPhoto *)photo asset:(ALAsset *) asset {
    dispatch_async(dbInsertQueue, ^ {
        AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        NSManagedObjectContext *context = [appDelegate managedObjectContext];
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entityDesc = [NSEntityDescription entityForName:PHOTO inManagedObjectContext:context];
        [request setEntity:entityDesc];
        
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"(imageURL = %@)", photo.imageURL];
        [request setPredicate:pred];
        
        NSError *err;
        NSArray *result = [context executeFetchRequest:request error:&err];
        
        if (result == nil) {
            NSLog(@"error with core data request");
            abort();
        }
        
        if (result.count == 0) {
            NSManagedObjectContext *newPhoto = [NSEntityDescription insertNewObjectForEntityForName:PHOTO inManagedObjectContext:context];
            
            [newPhoto setValue:photo.imageURL forKey:@"imageURL"];
            [newPhoto setValue:photo.thumbURL forKey:@"thumbURL"];
            [newPhoto setValue:photo.deviceId forKey:@"deviceId"];
            [newPhoto setValue:photo.onServer forKey:@"onServer"];
            
            if (photo.remoteID != nil) {
                [newPhoto setValue:photo.remoteID forKey:@"remoteId"];
            }
            
            
            [appDelegate saveContext];
            
            if (asset != nil) {
                // we save the thumbnail to app documents folder
                // now we can easily use later without asset library
                UIImage *thumb = [UIImage imageWithCGImage:asset.thumbnail];
                NSData *data = UIImagePNGRepresentation(thumb);
                [data writeToFile:photo.thumbURL atomically:YES];
                
                photo.thumbURL = [[NSURL fileURLWithPath:photo.thumbURL] absoluteString];
                
                NSLog(@"will save thumbnail to %@", photo.thumbURL);
            }else {
                NSLog(@"asset was null");
            }
            
            NSLog(@"added new photo to core data");
        }else {
            //        NSLog(@"photo already exists in core data");
        }
        
    });
}

- (void) addPhoto:(CSPhoto *)photo {
    [self addPhoto:photo asset:nil];
}

- (CSPhoto *) getPhoto:(NSURL *)url {
    NSString *urlString = [url absoluteString];
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(imageURL = %@)", urlString];
    [request setPredicate:pred];
    
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:PHOTO inManagedObjectContext:context];
    [request setEntity:entityDesc];
    
    NSError *err;
    NSArray *result = [context executeFetchRequest:request error:&err];
    
    if (result == nil) {
        NSLog(@"error with core data request");
        abort();
    }
    
    if (result.count > 0) {
        NSManagedObject *obj = result[0];
        
        CSPhoto *photo = [[CSPhoto alloc] init];
        photo.deviceId = [obj valueForKey:@"deviceId"];
        
        NSString *imageURL = [obj valueForKey:@"imageURL"];
        NSString *thumbURL = [obj valueForKey:@"thumbURL"];
        
        //        ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
        //        [assetLibrary assetForURL:url resultBlock:^(ALAsset *asset) {
        //            if (asset) {
        //                photo.photoObject = [MWPhoto photoWithURL:asset.defaultRepresentation.url];
        //                photo.thumbObject = [MWPhoto photoWithImage:[UIImage imageWithCGImage:asset.thumbnail]];
        //            }
        //        }
        //                     failureBlock:^(NSError *error){
        //                         NSLog(@"operation was not successfull!");
        //                     }];
        photo.photoObject = [MWPhoto photoWithURL:[NSURL URLWithString:photo.imageURL]];
        photo.thumbObject = [MWPhoto photoWithURL:[NSURL URLWithString:photo.thumbURL]];
        
        photo.imageURL = imageURL;
        photo.thumbURL = thumbURL;
        
        return photo;
    }else {
        return nil;
    }
}

- (NSMutableArray *)getPhotos: (NSString *) deviceId {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Photo" inManagedObjectContext:context];
    request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    
    //    NSAssert(![NSThread isMainThread], @"MAIN THREAD WHEN CALLING DB!!!!!");
    
    NSPredicate *pred;
    if (deviceId != nil) {
        pred = [NSPredicate predicateWithFormat:@"(deviceId = %@)", deviceId];
    }else {
        NSLog(@"the device id provided cannot be nil");
        abort();
    }
    [request setPredicate:pred];
    
    NSError *error;
    NSArray *phs = [context executeFetchRequest:request error:&error];
    
    if (phs == nil) {
        NSLog(@"error with core data request");
        abort();
    }
    
    // add all of the photo objects to the local photo list
    NSManagedObject *p;
    for (int i =0; i < [phs count]; i++) {
        p = phs[i];
        CSPhoto *photo = [[CSPhoto alloc] init];
        photo.deviceId = [p valueForKey:@"deviceId"];
        photo.onServer = [p valueForKey:@"onServer"];
        
        NSString *imageURL = [p valueForKey:@"imageURL"];
        NSString *thumbURL = [p valueForKey:@"thumbURL"];
        
        photo.imageURL = imageURL;
        photo.thumbURL = thumbURL;
        
        photo.photoObject = [MWPhoto photoWithURL:[NSURL URLWithString:photo.imageURL]];
        photo.thumbObject = [MWPhoto photoWithURL:[NSURL fileURLWithPath:photo.thumbURL]];
        
        [arr addObject:photo];
    }
    
    NSLog(@"returning all photos for %@", deviceId);
    return arr;
}

- (NSMutableArray *) getPhotosToUpload {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Photo" inManagedObjectContext:context];
    request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    
    //    NSAssert(![NSThread isMainThread], @"MAIN THREAD WHEN CALLING DB!!!!!");
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(onServer = %@)", @"0"];
    [request setPredicate:pred];
    
    NSError *error;
    NSArray *phs = [context executeFetchRequest:request error:&error];
    
    if (phs == nil) {
        NSLog(@"error with core data request");
        abort();
    }
    
    // add all of the photo objects to the local photo list
    NSManagedObject *p;
    for (int i =0; i < [phs count]; i++) {
        p = phs[i];
        CSPhoto *photo = [[CSPhoto alloc] init];
        photo.deviceId = [p valueForKey:@"deviceId"];
        photo.onServer = [p valueForKey:@"onServer"];
        
        NSString *imageURL = [p valueForKey:@"imageURL"];
        NSString *thumbURL = [p valueForKey:@"thumbURL"];
        
        photo.imageURL = imageURL;
        photo.thumbURL = thumbURL;
        
        photo.photoObject = [MWPhoto photoWithURL:[NSURL URLWithString:photo.imageURL]];
        photo.thumbObject = [MWPhoto photoWithURL:[NSURL fileURLWithPath:photo.thumbURL]];
        
        [arr addObject:photo];
    }
    
    return arr;
}

- (NSString *) getLatestId {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(onServer = %@)", @"1"];
    [request setPredicate:pred];
    
    [request setFetchLimit:1];
    
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:PHOTO inManagedObjectContext:context];
    [request setEntity:entityDesc];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"remoteId" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [request setSortDescriptors:sortDescriptors];
    
    NSError *err;
    NSArray *result = [context executeFetchRequest:request error:&err];
    
    if (result == nil) {
        NSLog(@"error with core data request");
        abort();
    }
    
    if (result.count > 0) {
        NSManagedObject *obj = result[0];
        
        NSString *latestId = [obj valueForKey:@"remoteId"];
        
        return latestId;
    }else {
        return @"-1";
    }
}


@end
