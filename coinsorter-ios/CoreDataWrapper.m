//
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

enum {
    WDASSETURL_PENDINGREADS = 1,
    WDASSETURL_ALLFINISHED = 0
};

- (void) addUpdateDevice:(CSDevice *)device {
    
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
        
        NSURL *url = [NSURL URLWithString:[obj valueForKey:@"imageURL"]];
        
        ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
        [assetLibrary assetForURL:url resultBlock:^(ALAsset *asset) {
            if (asset) {
                photo.photoObject = [MWPhoto photoWithURL:asset.defaultRepresentation.url];
                photo.thumbObject = [MWPhoto photoWithImage:[UIImage imageWithCGImage:asset.thumbnail]];
            }
        }
                     failureBlock:^(NSError *error){
                         NSLog(@"operation was not successfull!");
                     }];
        
        photo.imageURL = url;
        
        return photo;
    }else {
        return nil;
    }
}

- (void) addPhoto:(CSPhoto *)photo {
    NSString *urlString = [photo.imageURL absoluteString];
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    
    [context lock];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:PHOTO inManagedObjectContext:context];
    [request setEntity:entityDesc];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(imageURL = %@)", urlString];
    [request setPredicate:pred];
    
    NSError *err;
    NSArray *result = [context executeFetchRequest:request error:&err];
    
    if (result == nil) {
        NSLog(@"error with core data request");
        abort();
    }
    
    if (result.count == 0) {
        NSManagedObject *newPhoto = [NSEntityDescription insertNewObjectForEntityForName:PHOTO inManagedObjectContext:context];
        
        [newPhoto setValue:[photo.imageURL absoluteString] forKey:@"imageURL"];
        [newPhoto setValue:photo.deviceId forKey:@"deviceId"];
        
        [appDelegate saveContext];
        
//        NSLog(@"added new photo to core data");
    }else {
//        NSLog(@"photo already exists in core data");
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

    NSAssert(![NSThread isMainThread], @"MAIN THREAD WHEN CALLING DB!!!!!");
    
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

        NSURL *url = [NSURL URLWithString:[p valueForKey:@"imageURL"]];
        
        albumReadLock = [[NSConditionLock alloc] initWithCondition:WDASSETURL_PENDINGREADS];
        
        ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
        [assetLibrary assetForURL:url
                       resultBlock:^(ALAsset *asset) {
                           if (asset != nil) {
                               
                               photo.photoObject = [MWPhoto photoWithURL:asset.defaultRepresentation.url];
                               photo.thumbObject = [MWPhoto photoWithImage:[UIImage imageWithCGImage:asset.thumbnail]];
                           }
                           
                           [albumReadLock lock];
                           [albumReadLock unlockWithCondition:WDASSETURL_ALLFINISHED];
                       }
                     failureBlock:^(NSError *error){
                         NSLog(@"operation was not successfull!");
                         
                         [albumReadLock lock];
                         [albumReadLock unlockWithCondition:WDASSETURL_ALLFINISHED];
                     }];

        [albumReadLock lockWhenCondition:WDASSETURL_ALLFINISHED];
        [albumReadLock unlock];
        
        photo.imageURL = url;
        [arr addObject:photo];
    }

    NSLog(@"returning all photos for %@", deviceId);
    return arr;
}


@end
