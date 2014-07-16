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

- (CSPhoto *) getPhoto:(NSURL *)url {
    NSString *urlString = [url absoluteString];
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(imageURL = %@)", urlString];
    [request setPredicate:pred];
    
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
        NSManagedObject *newPhoto = [NSEntityDescription insertNewObjectForEntityForName:@"Photo" inManagedObjectContext:context];
        
        [newPhoto setValue:[photo.imageURL absoluteString] forKey:@"imageURL"];
        [newPhoto setValue:photo.deviceId forKey:@"deviceId"];
        
        [appDelegate saveContext];
        
//        NSLog(@"added new photo to core data");
    }else {
//        NSLog(@"photo already exists in core data");
    }
}

//- (NSMutableArray *)getPhotos: (NSString *) deviceId {
//    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
//    NSManagedObjectContext *context = [appDelegate managedObjectContext];
//    NSFetchRequest *request = [[NSFetchRequest alloc] init];
//
//    NSMutableArray *arr = [[NSMutableArray alloc] init];
//
//    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Photo" inManagedObjectContext:context];
//    request = [[NSFetchRequest alloc] init];
//    [request setEntity:entityDesc];
//
//    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(deviceId = %@)", deviceId];
//    [request setPredicate:pred];
//
//    NSError *error;
//    NSArray *phs = [context executeFetchRequest:request error:&error];
//
//    if (phs == nil) {
//        NSLog(@"error with core data request");
//        abort();
//    }
//
//    // add all of the photo objects to the local photo list
//    NSManagedObject *p;
//    for (int i =0; i < [phs count]; i++) {
//        p = phs[i];
//        CSPhoto *photo = [[CSPhoto alloc] init];
//        photo.deviceId = [p valueForKey:@"deviceId"];
//
//        NSURL *url = [NSURL URLWithString:[p valueForKey:@"imageURL"]];
//
//        [_assetLibrary assetForURL:url
//                       resultBlock:^(ALAsset *asset) {
//                           if (asset) {
//                               photo.photoObject = [MWPhoto photoWithURL:asset.defaultRepresentation.url];
//                               photo.thumbObject = [MWPhoto photoWithImage:[UIImage imageWithCGImage:asset.thumbnail]];
//                           }
//                       }
//                      failureBlock:^(NSError *error){
//                          NSLog(@"operation was not successfull!");
//                      }];
//
//        photo.imageURL = url;
//        [arr addObject:photo];
//    }
//
//    NSLog(@"returning all photos");
//    return arr;
//}


//// add photo to core data
//- (void)addPhoto: (ALAsset *)asset setCompareArray: (NSMutableArray *)arr {
//    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
//    NSManagedObjectContext *context = [appDelegate managedObjectContext];
//
//    // add photo to core data
//    NSURL *url = [[asset defaultRepresentation] url];
//    NSString *urlString = [url absoluteString];
//    NSString *localDeviceId = @"1";
//
//    //    NSLog([NSString stringWithFormat:@"size is %lu", (unsigned long)arr.count]);
//
//    BOOL alreadyAdded = NO;
//
//    for (int i=0;i<arr.count;i++) {
//        CSPhoto *ph = arr[i];
//
//        if ([urlString isEqualToString:[ph.imageURL absoluteString]]) {
//            alreadyAdded = YES;
//            break;
//        }
//    }
//
//    if (!alreadyAdded) {
//        @synchronized(localPhotos) {
//            CSPhoto *photo = [[CSPhoto alloc] init];
//
//            photo.photoObject = [MWPhoto photoWithURL:url];
//            photo.thumbObject = [MWPhoto photoWithImage:[UIImage imageWithCGImage:asset.thumbnail]];
//
//            photo.imageURL = url;
//            photo.deviceId = localDeviceId;
//
//            [arr addObject:photo];
//
//            NSLog(@"creating new photo object");
//
//            NSManagedObject *newPhoto = [NSEntityDescription insertNewObjectForEntityForName:@"Photo" inManagedObjectContext:context];
//
//            [newPhoto setValue:[photo.imageURL absoluteString] forKey:@"imageURL"];
//            [newPhoto setValue:photo.deviceId forKey:@"deviceId"];
//
//            NSError *error;
//            [context save:&error];
//        }
//    }else {
//        //        NSLog(@"photo already exists in core data");
//        ;
//    }
//}


@end
