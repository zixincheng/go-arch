//
//  UploadFunctions.m
//  Go Arch
//
//  Created by zcheng on 2015-03-24.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "UploadFunctions.h"


@implementation UploadFunctions

- (id) init {
    self = [super init];
    appDelegate = [[UIApplication sharedApplication] delegate];
    self.dataWrapper = appDelegate.dataWrapper;
    account = appDelegate.account;
    self.coinsorter = appDelegate.coinsorter;
    self.networkStatus = appDelegate.netWorkCheck;
    defaults = [NSUserDefaults standardUserDefaults];
    
    
    return self;
}
- (void) onePhotoThumbToApi:(CSPhoto *)photo networkStatus:(NSString *)networkStatus{
    __block int currentthumbnailUploaded = 0;
    __block int currentFullPhotoUploaded = 0;
    BOOL upload3G = [defaults boolForKey:UPLOAD_3G];
    BOOL deleteRaw = [defaults boolForKey:DELETE_RAW];
    //upload photo thumb no matter under 3g or wifi
    if ([photo.thumbOnServer isEqualToString:@"0"]) {
        [self.coinsorter uploadOneThumb:photo upCallback:^(CSPhoto *p){
            NSLog(@"remote id %@", p.remoteID );
            if (p.tag != nil) {
                [self.coinsorter updateMeta:p entity:@"tag" value:p.tag];
                NSLog(@"updating the tags");
            }
            currentthumbnailUploaded += 1;
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
                
            });
            // if it is under wifi, upload RAW image
            if ([networkStatus isEqualToString:WIFIEXTERNAL] || [networkStatus isEqualToString:WIFILOCAL]) {
                [self.coinsorter uploadOnePhoto:p upCallback:^{
                    currentFullPhotoUploaded +=1;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
                        
                    });
                    if (deleteRaw) {
                        [self deleteRawPhotoFromFile:photo];
                        NSLog(@"delete full res image");
                    }
                    NSLog(@"upload full res image");
                }];
            }
            // if it is under 3g and option is ture, then upload RAW image
            else {
                if (upload3G) {
                    [self.coinsorter uploadOnePhoto:p upCallback:^{
                        currentFullPhotoUploaded +=1;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
                        });
                        NSLog(@"upload full res image using 3G");
                        if (deleteRaw) {
                            [self deleteRawPhotoFromFile:photo];
                            NSLog(@"delete full res image");
                        }
                    }];
                }
                // if it is unser 3g and option is false, don't upload RAW image
                else {
                    NSLog(@"dont upload full res because it using 3g");
                }
            }
        }];
    } else if([photo.thumbOnServer isEqualToString:@"1"] && [photo.fullOnServer isEqualToString:@"0"]){
        if ([networkStatus isEqualToString:WIFIEXTERNAL] || [networkStatus isEqualToString:WIFILOCAL]) {
            [self.coinsorter uploadOnePhoto:photo upCallback:^{
                currentFullPhotoUploaded +=1;
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
                    
                });
                
                NSLog(@"upload full res image");
                if (deleteRaw) {
                    [self deleteRawPhotoFromFile:photo];
                    NSLog(@"delete full res image");
                }
            }];
        }
        // if it is under 3g and option is ture, then upload RAW image
        else {
            if (upload3G) {
                [self.coinsorter uploadOnePhoto:photo upCallback:^{
                    currentFullPhotoUploaded +=1;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
                    });
                    NSLog(@"upload full res image using 3G");
                    if (deleteRaw) {
                        [self deleteRawPhotoFromFile:photo];
                        NSLog(@"delete full res image");
                    }
                }];
            }
            // if it is unser 3g and option is false, don't upload RAW image
            else {
                NSLog(@"dont upload full res because it using 3g");
            }
        }

    }

}
- (void) uploadPhotosToApi:(NSString *)networkStatus {
    // Always upload thumbnails - maybe turn this into a pref later
    NSMutableArray *thumbPhotos = [self.dataWrapper getPhotosToUpload];
    
    // Are there RAW photos/videos to upload?
    NSMutableArray *fullPhotos = [self.dataWrapper getFullSizePhotosToUpload];

    int unUploadedFullPhotos = [appDelegate.dataWrapper getFullImageCountUnUploaded];
    
    BOOL upload3G = [defaults boolForKey:UPLOAD_3G];
    NSLog(@"unupload full image %d",unUploadedFullPhotos);

    if (thumbPhotos.count > 0) {
        //upload all thumbnail no matter what condition
        NSLog(@"there are %lu thumbnails to upload", (unsigned long)thumbPhotos.count);
        [self.coinsorter uploadPhotoThumb:thumbPhotos upCallback:^(CSPhoto *p) {
            
            NSLog(@"removete id %@", p.remoteID );
            if (p.tag != nil) {
                [self.coinsorter updateMeta:p entity:@"tag" value:p.tag];
                NSLog(@"updating the tags");
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
            });
            
            //upload RAW photo if it is under wifi
            if ([networkStatus isEqualToString:WIFIEXTERNAL] || [networkStatus isEqualToString:WIFILOCAL]) {
                [self.coinsorter uploadOnePhoto:p upCallback:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
                    });
                    NSLog(@"upload full res image");
                }];
            }
            // if it is under 3g, check 3g condition to decide if upload RAW photo
            else {
                if (upload3G) {
                    [self.coinsorter uploadOnePhoto:p upCallback:^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
                        });
                        NSLog(@"upload full res image using 3G");
                    }];
                } else {
                    NSLog(@"dont upload full res because it using 3g");
                }
            }
        }];
    }
    // if no unupload thumnail, then just upload unupload RAW photo
    else if (thumbPhotos.count ==0 && fullPhotos.count >0) {
        if ([networkStatus isEqualToString:WIFIEXTERNAL] || [networkStatus isEqualToString:WIFILOCAL] || upload3G) {
            for (CSPhoto *p in fullPhotos) {
                [self.coinsorter uploadOnePhoto:p upCallback:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
                    });
                    NSLog(@"upload full res image");
                }];
            }
        } else {
            NSLog(@"dont upload full res because it using 3g");
        }
    } else {
        
        NSLog(@"there are no photos to upload");
    }
}

- (void) deleteRawPhotoFromFile: (CSPhoto *) p {
    NSMutableArray *photoPath = [NSMutableArray array];
    NSString *documentsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    // get documents directory
    NSString *imageUrl = [documentsPath stringByAppendingString:[NSString stringWithFormat:@"/%@", p.imageURL]];
    [photoPath addObject:imageUrl];
    
    for (NSString *currentpath in photoPath) {
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:currentpath error:&error];
    }
    
    
}


@end
