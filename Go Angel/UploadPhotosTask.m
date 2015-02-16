//
//  UploadPhotosTask.m
//  Go Angel
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import "UploadPhotosTask.h"

@implementation UploadPhotosTask

- (id)initWithWrapper:(CoreDataWrapper *)wrap {
    self = [super init];
    
    self.uploadingPhotos = [[NSMutableArray alloc] init];
    assetLibrary = [[ALAssetsLibrary alloc] init];
    self.dataWrapper = wrap;
    
    // setup background session config
    NSURLSessionConfiguration *config;
    NSString *currentVer = [[UIDevice currentDevice] systemVersion];
    NSString *reqVer = @"8.0";
    if ([currentVer compare:reqVer options:NSNumericSearch] !=
        NSOrderedAscending) {
        config = [NSURLSessionConfiguration
                  backgroundSessionConfigurationWithIdentifier:
                  [NSString stringWithFormat:@"com.go.upload"]];
    } else {
        config = [NSURLSessionConfiguration
                  backgroundSessionConfiguration:[NSString
                                                  stringWithFormat:@"com.go.upload"]];
    }
    
    [config setSessionSendsLaunchEvents:YES];
    [config setDiscretionary:NO];
    
    // create the sessnon with backaground config
    self.session = [NSURLSession sessionWithConfiguration:config
                                                 delegate:self
                                            delegateQueue:nil];
    
    return self;
}

// function to strip away gps photo metadata if user does not want uploaded
// also, if location tagging is enabled, the IPTC metadata of the photo is
// is edited to included all location properites
- (NSMutableDictionary *)manipulateMetadata:(NSDictionary *)metadata photo:(CSPhoto *)photo{
    NSMutableDictionary *metadataAsMutable = [metadata mutableCopy];
    
    NSMutableDictionary *EXIFDictionary = [metadataAsMutable
                                           objectForKey:(NSString *)kCGImagePropertyExifDictionary];
    NSMutableDictionary *GPSDictionary = [metadataAsMutable
                                          objectForKey:(NSString *)kCGImagePropertyGPSDictionary];
    NSMutableDictionary *TIFFDictionary = [metadataAsMutable
                                           objectForKey:(NSString *)kCGImagePropertyTIFFDictionary];
    NSMutableDictionary *RAWDictionary = [metadataAsMutable
                                          objectForKey:(NSString *)kCGImagePropertyRawDictionary];
    NSMutableDictionary *JPEGDictionary = [metadataAsMutable
                                           objectForKey:(NSString *)kCGImagePropertyJFIFDictionary];
    NSMutableDictionary *GIFDictionary = [metadataAsMutable
                                          objectForKey:(NSString *)kCGImagePropertyGIFDictionary];
    NSMutableDictionary *IPTCDictionary = [metadataAsMutable objectForKey:(NSString *)kCGImagePropertyIPTCDictionary];
    if (!IPTCDictionary) {
        IPTCDictionary = [NSMutableDictionary dictionary];
    }
    
    // tag the photo with the location from settings if user wants it
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL tagLocation = [defaults boolForKey:CURR_LOC_ON];
    
    // if the user wants to tag the photo with location
    if (tagLocation) {
        NSString *name = photo.location.name;
        NSString *unit = photo.location.unit;
        NSString *city = photo.location.city;
        NSString *state = photo.location.province;
        NSString *countryCode = photo.location.countryCode;
        NSString *country = photo.location.country;
        NSString *longitude = photo.location.longitude;
        NSString *latitude = photo.location.latitude;
        NSString *sublocation = name;
        
        // if there is a unit to the location, then change the sublocation to be UNIT - ADDRESS
        if (![unit isEqualToString:@""]) {
            sublocation = [NSString stringWithFormat:@"Unit %@ - %@", unit, name];
        }
        
        // set the properites for teh IPTCDictionary
        [IPTCDictionary setObject:sublocation forKey:(NSString *)kCGImagePropertyIPTCSubLocation];
        [IPTCDictionary setObject:city forKey:(NSString *)kCGImagePropertyIPTCCity];
        [IPTCDictionary setObject:state forKey:(NSString *)kCGImagePropertyIPTCProvinceState];
        [IPTCDictionary setObject:countryCode forKey:(NSString *)kCGImagePropertyIPTCCountryPrimaryLocationCode];
        [IPTCDictionary setObject:country forKey:(NSString *)kCGImagePropertyIPTCCountryPrimaryLocationName];
        [IPTCDictionary setValue:longitude forKey:(NSString *) kCGImagePropertyGPSLongitude];
        [IPTCDictionary setValue:latitude forKey:(NSString *)kCGImagePropertyGPSLatitude];
    }
    
    if (!EXIFDictionary) {
        EXIFDictionary = [NSMutableDictionary dictionary];
    }
    
    BOOL gpsMeta = [[NSUserDefaults standardUserDefaults] boolForKey:GPS_META];
    if (!GPSDictionary || !gpsMeta) {
        GPSDictionary = [NSMutableDictionary dictionary];
    }
    if (gpsMeta) {
        
        NSString *longitude = [defaults objectForKey:CURR_LOC_LONG];
        NSString *latitude = [defaults objectForKey:CURR_LOC_LAT];
        [GPSDictionary setObject:longitude forKeyedSubscript:(NSString *) kCGImagePropertyGPSLongitude];
        [GPSDictionary setObject:latitude forKeyedSubscript:(NSString *) kCGImagePropertyGPSLatitude];
    }
    if (!TIFFDictionary) {
        TIFFDictionary = [NSMutableDictionary dictionary];
    }
    
    if (!RAWDictionary) {
        RAWDictionary = [NSMutableDictionary dictionary];
    }
    
    if (!JPEGDictionary) {
        JPEGDictionary = [NSMutableDictionary dictionary];
    }
    
    if (!GIFDictionary) {
        GIFDictionary = [NSMutableDictionary dictionary];
    }
    
    [metadataAsMutable setObject:EXIFDictionary
                          forKey:(NSString *)kCGImagePropertyExifDictionary];
    [metadataAsMutable setObject:GPSDictionary
                          forKey:(NSString *)kCGImagePropertyGPSDictionary];
    [metadataAsMutable setObject:TIFFDictionary
                          forKey:(NSString *)kCGImagePropertyTIFFDictionary];
    [metadataAsMutable setObject:RAWDictionary
                          forKey:(NSString *)kCGImagePropertyRawDictionary];
    [metadataAsMutable setObject:JPEGDictionary
                          forKey:(NSString *)kCGImagePropertyJFIFDictionary];
    [metadataAsMutable setObject:GIFDictionary
                          forKey:(NSString *)kCGImagePropertyGIFDictionary];
    [metadataAsMutable setObject:IPTCDictionary forKey:(NSString *)kCGImagePropertyIPTCDictionary];
    
    return metadataAsMutable;
}

// get NSData with correct metadata from an UIImage and ALAsset
- (NSData *)getPhotoWithMetaDataFromAsset:(UIImage *)image
                                    asset:(ALAsset *)asset photo:(CSPhoto *)photo{
    
    // convert UIImage to NSData (100% quality)
    NSData *jpeg = [NSData dataWithData:UIImageJPEGRepresentation(image, 1.0)];
    
    CGImageSourceRef source =
    CGImageSourceCreateWithData((__bridge CFDataRef)jpeg, NULL);
    
    // get metadata from asset
    NSDictionary *metadata = [[asset defaultRepresentation] metadata];
    
    // edit the metadata according to the user settings
    NSMutableDictionary *metadataAsMutable = [self manipulateMetadata:metadata photo:photo];
    CFStringRef UTI = CGImageSourceGetType(source);
    
    NSMutableData *dest_data = [NSMutableData data];
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithData(
                                                                         (__bridge CFMutableDataRef)dest_data, UTI, 1, NULL);
    
    CGImageDestinationAddImageFromSource(
                                         destination, source, 0, (__bridge CFDictionaryRef)metadataAsMutable);
    
    BOOL success = NO;
    success = CGImageDestinationFinalize(destination);
    
    CFRelease(destination);
    CFRelease(source);
    
    return dest_data;
}

// get NSData with correc tmetadata from local filepath
- (NSData *)getPhotoWithMetaDataFromFile:(NSString *)textPath photo: (CSPhoto *) photo {
    
    NSData *imageData = [NSData dataWithContentsOfFile:textPath];
    CGImageSourceRef source =
    CGImageSourceCreateWithData((CFMutableDataRef)imageData, NULL);
    
    NSDictionary *metadata = (NSDictionary *)CFBridgingRelease(
                                                               CGImageSourceCopyPropertiesAtIndex(source, 0, NULL));
    
    // edit the metadata according to the user settings
    NSMutableDictionary *metadataAsMutable = [self manipulateMetadata:metadata photo:photo];
    
    CFStringRef UTI = CGImageSourceGetType(source);
    
    NSMutableData *dest_data = [NSMutableData data];
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithData(
                                                                         (__bridge CFMutableDataRef)dest_data, UTI, 1, NULL);
    
    CGImageDestinationAddImageFromSource(
                                         destination, source, 0, (__bridge CFDictionaryRef)metadataAsMutable);
    
    BOOL success = NO;
    success = CGImageDestinationFinalize(destination);
    
    CFRelease(destination);
    CFRelease(source);
    
    return dest_data;
}

// get NSData with correct metadata from an UIImage and ALAsset
- (NSData *)getVideoWithMetaDataFromAsset:(NSString *)videPath
                                    asset:(ALAsset *)asset {
    
    NSData *movieData = [NSData dataWithContentsOfFile:videPath];
    

    return movieData;
    
}

// upload an array of CSPhotos to the server
// after each photo is uploaded, the upCallback function is called

// Process to upload photos is as follows
/*
 *
 */

- (void)uploadPhotoArray:(NSMutableArray *)photos
              upCallback:(void (^)())upCallback {
    // set the upload callback
    self.upCallback = upCallback;
    
    // This generates a guranteed unique string
    NSString *uniqueString = [[NSProcessInfo processInfo] globallyUniqueString];
    
    __block UIBackgroundTaskIdentifier background_task; // Create a task object
    
    UIApplication *application = [UIApplication sharedApplication];
    
    background_task = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:background_task]; // Tell the system that
        // we are done with the
        // tasks
        background_task = UIBackgroundTaskInvalid; // Set the task to be invalid
        
        // System will be shutting down the app at any point in time now
    }];
    
    // Background tasks require you to use asyncrous tasks
    // This background task will have 30 seconds to complete before apple kills us
    // This should allow us to start all of the uploads which will then be able to
    // run in the background
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        // Perform your tasks that your application requires
        
        // prevent app from going to sleep when uploading
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        
        for (CSPhoto *p in photos) {
            //readLock =
           // [[NSConditionLock alloc] initWithCondition:WDASSETURL_PENDINGREADS];
            
            ALAssetsLibraryAssetForURLResultBlock resultBlock = ^(ALAsset *asset) {
                ALAssetRepresentation *rep = [asset defaultRepresentation];
                if ([p.isVideo isEqualToString:@"1"]) {
                    CGImageRef iref = [rep fullResolutionImage];
                    // if the asset exists
                    if (iref) {
                        NSLog(@"uploading from album");
                        Byte *buffer = (Byte*)malloc(rep.size);
                        NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:rep.size error:nil];
                        NSData *movieData = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
                        
                        NSString *fileName = [NSString
                                              stringWithFormat:@"%@_%@", uniqueString, @"movie.mov"];
                        NSURL *fileURL = [NSURL
                                          fileURLWithPath:[NSTemporaryDirectory()
                                                           stringByAppendingPathComponent:fileName]];
                        
                        [movieData writeToURL:fileURL
                                      options:NSDataWritingAtomic
                                        error:nil];
                        CLLocation *location = [asset valueForProperty:ALAssetPropertyLocation];
                        AppDelegate *appDelegate =
                        [[UIApplication sharedApplication] delegate];
                        NSString *urlString = [NSString
                                               stringWithFormat:@"%@%@%@", @"https://",
                                               appDelegate.account.ip, @"/videos"];
                        NSURL *url = [NSURL URLWithString:urlString];
                        
                        // TODO: Get these values from photo
                        // eg. filename = actual filename (not unique string)
                        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                        BOOL tagLocation = [[NSUserDefaults standardUserDefaults] boolForKey:CURR_LOC_ON];
                        NSArray * keys;
                        NSArray *objects;
                        
                        NSString *name = p.location.name;
                        NSString *unit = p.location.unit;
                        NSString *city = p.location.city;
                        NSString *state = p.location.province;
                        NSString *countryCode = p.location.countryCode;
                        NSString *country = p.location.country;
                        NSString *longitude = p.location.longitude;
                        NSString *latitude = p.location.latitude;
                        NSString *sublocation = name;
                        if (![unit isEqualToString:@""]) {
                            sublocation = [NSString stringWithFormat:@"Unit %@ - %@", unit, name];
                        }
                        //  if (tagLocation) {
                        keys = [NSArray
                                arrayWithObjects:@"cid",@"token", @"filename", @"file-type", @"longitude", @"latitude", @"unit", @"city", @"state", @"countryCode", @"country", @"sublocation",nil];
                        objects = [NSArray arrayWithObjects:p.deviceId, appDelegate.account.token, uniqueString, @"movie/mov", longitude,latitude, unit, city, state, countryCode, country, sublocation, nil];
                        //} //else {
                        // keys = [NSArray
                        //        arrayWithObjects:@"token", @"filename", @"file-type",nil];
                        //objects = [NSArray arrayWithObjects:appDelegate.account.token, uniqueString, @"movie/mov", nil];
                        // }
                        NSDictionary *headers =
                        [NSDictionary dictionaryWithObjects:objects forKeys:keys];
                        
                        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
                        [request setURL:url];
                        [request setHTTPMethod:@"POST"];
                        [request setAllHTTPHeaderFields:headers];
                        // [request setValue:@"multipart/form-data; boundary=AaB03x" forHTTPHeaderField:@"Content-Type"];
                        
                        NSURLSessionUploadTask *uploadTask =
                        [self.session uploadTaskWithRequest:request fromFile:fileURL];
                        p.taskIdentifier = uploadTask.taskIdentifier;
                        
                        @synchronized(self.uploadingPhotos) {
                            [self.uploadingPhotos addObject:p];
                        }
                        
                        [uploadTask resume];
                        NSLog(@"making post request to %@", urlString);
                        
                        [readLock lock];
                        [readLock unlockWithCondition:WDASSETURL_ALLFINISHED];
                    } else {
                        NSLog(@"uploading from device folder");
                        AppDelegate *appDelegate =
                        [[UIApplication sharedApplication] delegate];
                        NSString *urlString = [NSString
                                               stringWithFormat:@"%@%@%@", @"https://",
                                               appDelegate.account.ip, @"/videos"];
                        
                        NSURL *url = [NSURL URLWithString:urlString];
                        
                        // TODO: Get these values from photo
                        // eg. filename = actual filename (not unique string)
                        //[NSArray arrayWithObjects:appDelegate.account.token,
                        // uniqueString, @"movie/mov", nil];
                        
                        // set headers
                        // NSArray *keys = [NSArray
                        //arrayWithObjects:@"token", @"filename", @"file-type", nil];
        
                        NSArray * keys;
                        NSArray *objects;
                        
                        NSString *name = p.location.name;
                        NSString *unit = p.location.unit;
                        NSString *city = p.location.city;
                        NSString *state = p.location.province;
                        NSString *countryCode = p.location.countryCode;
                        NSString *country = p.location.country;
                        NSString *longitude = p.location.longitude;
                        NSString *latitude = p.location.latitude;
                        NSString *sublocation = name;
                        if (![unit isEqualToString:@""]) {
                            sublocation = [NSString stringWithFormat:@"Unit %@ - %@", unit, name];
                        }
                        //if (tagLocation) {
                        keys = [NSArray
                                arrayWithObjects:@"cid",@"token", @"filename", @"file-type", @"longitude", @"latitude", @"unit", @"city", @"state", @"countryCode", @"country", @"sublocation",nil];
                        objects = [NSArray arrayWithObjects:p.deviceId, appDelegate.account.token, uniqueString, @"movie/mov", longitude,latitude, unit, city, state, countryCode, country, sublocation, nil];
                        // } //else {
                        //  keys = [NSArray
                        //         arrayWithObjects:@"token", @"filename", @"file-type",nil];
                        //  objects = [NSArray arrayWithObjects:appDelegate.account.token, uniqueString, @"movie/mov", nil];
                        //}
                        NSDictionary *headers =
                        [NSDictionary dictionaryWithObjects:objects forKeys:keys];
                        
                        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
                        [request setURL:url];
                        [request setHTTPMethod:@"POST"];
                        [request setAllHTTPHeaderFields:headers];
                        
                        // get documents directory
                        NSArray *pathArray = NSSearchPathForDirectoriesInDomains(
                                                                                 NSDocumentDirectory, NSUserDomainMask, YES);
                        NSString *documentsDirectory = [pathArray objectAtIndex:0];
                        NSString *textPath = [documentsDirectory
                                              stringByAppendingPathComponent:p.fileName];
                        
                        // get movie data from file path
                        NSData *movieData = [NSData dataWithContentsOfFile:textPath];
                        NSString *fileName = [NSString
                                              stringWithFormat:@"%@_%@", p.fileName, @"movie.mov"];
                        NSURL *fileURL =
                        [NSURL fileURLWithPath:[NSTemporaryDirectory()
                                                stringByAppendingString:fileName]];
                        // write the image data to a temp dir
                        [movieData writeToURL:fileURL
                                      options:NSDataWritingAtomic
                                        error:nil];
                        
                        // upload the file from the temp dir
                        NSURLSessionUploadTask *uploadTask =
                        [self.session uploadTaskWithRequest:request fromFile:fileURL];
                        
                        p.taskIdentifier = uploadTask.taskIdentifier;
                        
                        @synchronized(self.uploadingPhotos) {
                            [self.uploadingPhotos addObject:p];
                        }
                        
                        // start upload
                        [uploadTask resume];
                        
                        [readLock lock];
                        [readLock unlockWithCondition:WDASSETURL_ALLFINISHED];
                        
                    }
                }
                else {
                    
                    CGImageRef iref = [rep fullResolutionImage];
                    
                    // if the asset exists
                    if (iref) {
                        // photos found in album
                        // Retrieve the image orientation from the ALAsset
                        UIImageOrientation orientation = UIImageOrientationUp;
                        NSNumber *orientationValue =
                        [asset valueForProperty:ALAssetPropertyOrientation];
                        if (orientationValue != nil) {
                            orientation = [orientationValue intValue];
                        }
                        
                        CGFloat scale = 1;
                        
                        // correct the image orientation when we upload it
                        UIImage *image = [UIImage imageWithCGImage:iref
                                                             scale:scale
                                                       orientation:orientation];
                        
                        // add the metadata to image before we upload
                        NSData *imageData =
                        [self getPhotoWithMetaDataFromAsset:image asset:asset photo:p];
                        
                        NSString *fileName = [NSString
                                              stringWithFormat:@"%@_%@", uniqueString, @"image.jpg"];
                        NSURL *fileURL = [NSURL
                                          fileURLWithPath:[NSTemporaryDirectory()
                                                           stringByAppendingPathComponent:fileName]];
                        
                        [imageData writeToURL:fileURL
                                      options:NSDataWritingAtomic
                                        error:nil];
                        
                        AppDelegate *appDelegate =
                        [[UIApplication sharedApplication] delegate];
                        NSString *urlString = [NSString
                                               stringWithFormat:@"%@%@%@", @"https://",
                                               appDelegate.account.ip, @"/photos"];
                        NSURL *url = [NSURL URLWithString:urlString];
                        
                        // TODO: Get these values from photo
                        // eg. filename = actual filename (not unique string)
                        NSArray *objects =
                        [NSArray arrayWithObjects:p.deviceId, appDelegate.account.token,
                         uniqueString, @"image/jpeg", nil];
                        NSArray *keys = [NSArray
                                         arrayWithObjects:@"cid",@"token", @"filename", @"image-type", nil];
                        NSDictionary *headers =
                        [NSDictionary dictionaryWithObjects:objects forKeys:keys];
                        
                        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
                        [request setURL:url];
                        [request setHTTPMethod:@"POST"];
                        [request setAllHTTPHeaderFields:headers];
                        
                        NSURLSessionUploadTask *uploadTask =
                        [self.session uploadTaskWithRequest:request fromFile:fileURL];
                        p.taskIdentifier = uploadTask.taskIdentifier;
                        
                        @synchronized(self.uploadingPhotos) {
                            [self.uploadingPhotos addObject:p];
                        }
                        
                        [uploadTask resume];
                        NSLog(@"making post request to %@", urlString);
                        
                        [readLock lock];
                        [readLock unlockWithCondition:WDASSETURL_ALLFINISHED];
                    } else {
                        // if photos not found in album, try to find in application
                        // folder
                        AppDelegate *appDelegate =
                        [[UIApplication sharedApplication] delegate];
                        NSString *urlString = [NSString
                                               stringWithFormat:@"%@%@%@", @"https://",
                                               appDelegate.account.ip, @"/photos"];
                        
                        NSURL *url = [NSURL URLWithString:urlString];
                        
                        // TODO: Get these values from photo
                        // eg. filename = actual filename (not unique string)
                        NSArray *objects =
                        [NSArray arrayWithObjects:p.deviceId, appDelegate.account.token,
                         uniqueString, @"image/jpg", nil];
                        
                        // set headers
                        NSArray *keys = [NSArray
                                         arrayWithObjects:@"cid",@"token", @"filename", @"image-type", nil];
                        NSDictionary *headers =
                        [NSDictionary dictionaryWithObjects:objects forKeys:keys];
                        
                        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
                        
                        [request setURL:url];
                        [request setHTTPMethod:@"POST"];
                        [request setAllHTTPHeaderFields:headers];
                        
                        // get documents directory
                        NSArray *pathArray = NSSearchPathForDirectoriesInDomains(
                                                                                 NSDocumentDirectory, NSUserDomainMask, YES);
                        NSString *documentsDirectory = [pathArray objectAtIndex:0];
                        NSString *textPath = [documentsDirectory
                                              stringByAppendingPathComponent:p.fileName];
                        
                        // get image data from file path
                        NSData *imageData = [self getPhotoWithMetaDataFromFile:textPath photo:p];
                        NSString *fileName = [NSString
                                              stringWithFormat:@"%@_%@", p.fileName, @"image.jpg"];
                        NSURL *fileURL =
                        [NSURL fileURLWithPath:[NSTemporaryDirectory()
                                                stringByAppendingString:fileName]];
                        // write the image data to a temp dir
                        [imageData writeToURL:fileURL
                                      options:NSDataWritingAtomic
                                        error:nil];
                        
                        // upload the file from the temp dir
                        NSURLSessionUploadTask *uploadTask =
                        [self.session uploadTaskWithRequest:request fromFile:fileURL];
                        
                        p.taskIdentifier = uploadTask.taskIdentifier;
                        
                        @synchronized(self.uploadingPhotos) {
                            [self.uploadingPhotos addObject:p];
                        }
                        
                        // start upload
                        [uploadTask resume];
                       // [readLock lock];
                        //[readLock unlockWithCondition:WDASSETURL_ALLFINISHED];
                    }
                }
            };
            
            ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *err) {
                NSLog(@"can't get image - %@", [err localizedDescription]);
                
                [readLock lock];
                [readLock unlockWithCondition:WDASSETURL_ALLFINISHED];
            };
            
            NSURL *asseturl = [NSURL URLWithString:p.imageURL];
            ALAssetsLibrary *assetslibrary = [[ALAssetsLibrary alloc] init];
            [assetslibrary assetForURL:asseturl
                           resultBlock:resultBlock
                          failureBlock:failureBlock];
            
            // non-busy wait for the asset read to finish (specifically until the
            // condition is "all finished")
            //[readLock lockWhenCondition:WDASSETURL_ALLFINISHED];
            //[readLock unlock];
            
            // cleanup
            //readLock = nil;
        }
        
        [application endBackgroundTask:background_task]; // End the task so the
        // system knows that you
        // are done with what you
        // need to perform
        background_task =
        UIBackgroundTaskInvalid; // Invalidate the background_task
    });
}

// NSConditionLock values
enum { WDASSETURL_PENDINGREADS = 1, WDASSETURL_ALLFINISHED = 0 };

- (CSPhoto *)getPhotoWithTaskIdentifier:(unsigned long)taskId {
    for (CSPhoto *p in self.uploadingPhotos) {
        if (p.taskIdentifier == taskId) {
            return p;
        }
    }
    return nil;
}

- (void)uploadVideoThumb:(CSPhoto *)photo {
    
    NSString *uniqueString = [[NSProcessInfo processInfo] globallyUniqueString];
    
    __block UIBackgroundTaskIdentifier background_task; // Create a task object
    
    UIApplication *application = [UIApplication sharedApplication];
    
    background_task = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:background_task]; // Tell the system that
        // we are done with the
        // tasks
        background_task = UIBackgroundTaskInvalid; // Set the task to be invalid
        
        // System will be shutting down the app at any point in time now
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        readLock = [[NSConditionLock alloc] initWithCondition:WDASSETURL_PENDINGREADS];
        
        ALAssetsLibraryAssetForURLResultBlock resultBlock = ^(ALAsset *asset) {
            ALAssetRepresentation *rep = [asset defaultRepresentation];
            CGImageRef iref = [rep fullResolutionImage];
            if (iref) {
                UIImageOrientation orientation = UIImageOrientationUp;
                NSNumber *orientationValue =
                [asset valueForProperty:ALAssetPropertyOrientation];
                if (orientationValue != nil) {
                    orientation = [orientationValue intValue];
                }
                
                CGFloat scale = 1;
                
                // correct the image orientation when we upload it
                UIImage *image = [UIImage imageWithCGImage:iref
                                                     scale:scale
                                               orientation:orientation];
                
                // add the metadata to image before we upload
                NSData *imageData = [NSData dataWithData:UIImageJPEGRepresentation(image, 1.0)];
                
                NSString *fileName = [NSString
                                      stringWithFormat:@"%@_%@", uniqueString, @"image.jpg"];
                NSURL *fileURL = [NSURL
                                  fileURLWithPath:[NSTemporaryDirectory()
                                                   stringByAppendingPathComponent:fileName]];
                
                [imageData writeToURL:fileURL
                              options:NSDataWritingAtomic
                                error:nil];
                
                AppDelegate *appDelegate =
                [[UIApplication sharedApplication] delegate];
                NSString *urlString = [NSString
                                       stringWithFormat:@"%@%@%@", @"https://",
                                       appDelegate.account.ip, @"/videos/thumbnail"];
                NSURL *url = [NSURL URLWithString:urlString];
                
                // TODO: Get these values from photo
                // eg. filename = actual filename (not unique string)
                NSArray *objects =
                [NSArray arrayWithObjects:photo.deviceId, appDelegate.account.token,
                 uniqueString, @"image/jpeg",photo.remoteID, nil];
                NSArray *keys = [NSArray
                                 arrayWithObjects:@"cid",@"token", @"filename", @"image-type",@"photo_id", nil];
                NSDictionary *headers =
                [NSDictionary dictionaryWithObjects:objects forKeys:keys];
                
                NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
                [request setURL:url];
                [request setHTTPMethod:@"POST"];
                [request setAllHTTPHeaderFields:headers];
                
                NSURLSessionUploadTask *uploadTask =
                [self.session uploadTaskWithRequest:request fromFile:fileURL];
                
                [uploadTask resume];
                NSLog(@"making post request to %@", urlString);
                [readLock lock];
                [readLock unlockWithCondition:WDASSETURL_ALLFINISHED];
                
            }else {
                AppDelegate *appDelegate =
                [[UIApplication sharedApplication] delegate];
                NSString *urlString = [NSString
                                       stringWithFormat:@"%@%@%@", @"https://",
                                       appDelegate.account.ip, @"/videos/thumbnail"];
                
                NSURL *url = [NSURL URLWithString:urlString];
                
                // TODO: Get these values from photo
                // eg. filename = actual filename (not unique string)
                NSArray *objects =
                [NSArray arrayWithObjects:photo.deviceId, appDelegate.account.token,
                 uniqueString, @"image/jpg",photo.remoteID, nil];
                
                // set headers
                NSArray *keys = [NSArray
                                 arrayWithObjects:@"cid",@"token", @"filename", @"image-type",@"photo_id", nil];
                NSDictionary *headers =
                [NSDictionary dictionaryWithObjects:objects forKeys:keys];
                
                NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
                
                [request setURL:url];
                [request setHTTPMethod:@"POST"];
                [request setAllHTTPHeaderFields:headers];
                
                // get documents directory
                NSArray *pathArray = NSSearchPathForDirectoriesInDomains(
                                                                         NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsDirectory = [pathArray objectAtIndex:0];
                NSString *textPath = [documentsDirectory
                                      stringByAppendingPathComponent:photo.thumbnailName];
                
                // get image data from file path
                NSData *imageData = [NSData dataWithContentsOfFile:textPath];
                NSString *fileName = [NSString
                                      stringWithFormat:@"%@_%@", photo.thumbnailName, @"image.jpg"];
                NSURL *fileURL =
                [NSURL fileURLWithPath:[NSTemporaryDirectory()
                                        stringByAppendingString:fileName]];
                // write the image data to a temp dir
                [imageData writeToURL:fileURL
                              options:NSDataWritingAtomic
                                error:nil];
                
                
                // upload the file from the temp dir
                NSURLSessionUploadTask *uploadTask =
                [self.session uploadTaskWithRequest:request fromFile:fileURL];
                
                // start upload
                [uploadTask resume];
                
                [readLock lock];
                [readLock unlockWithCondition:WDASSETURL_ALLFINISHED];
            }
        };
        ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *err) {
            NSLog(@"can't get image - %@", [err localizedDescription]);
            
            [readLock lock];
            [readLock unlockWithCondition:WDASSETURL_ALLFINISHED];
        };
        
        NSURL *asseturl = [NSURL URLWithString:photo.imageURL];
        ALAssetsLibrary *assetslibrary = [[ALAssetsLibrary alloc] init];
        [assetslibrary assetForURL:asseturl
                       resultBlock:resultBlock
                      failureBlock:failureBlock];
    });
    
}

- (void)uploadPhotoThumb:(CSPhoto *)photo {
    
    NSString *uniqueString = [[NSProcessInfo processInfo] globallyUniqueString];
    
    __block UIBackgroundTaskIdentifier background_task; // Create a task object
    
    UIApplication *application = [UIApplication sharedApplication];
    
    background_task = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:background_task]; // Tell the system that
        // we are done with the
        // tasks
        background_task = UIBackgroundTaskInvalid; // Set the task to be invalid
        
        // System will be shutting down the app at any point in time now
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        //readLock2 = [[NSConditionLock alloc] initWithCondition:WDASSETURL_PENDINGREADS];
        
        ALAssetsLibraryAssetForURLResultBlock resultBlock = ^(ALAsset *asset) {
            ALAssetRepresentation *rep = [asset defaultRepresentation];
            CGImageRef iref = [asset thumbnail];
            if (iref) {
                
                UIImage *image = [UIImage imageWithCGImage:iref];
                
                // add the metadata to image before we upload
                NSData *imageData = [NSData dataWithData:UIImageJPEGRepresentation(image, 1.0)];
                
                NSString *fileName = [NSString
                                      stringWithFormat:@"%@_%@", uniqueString, @"image.jpg"];
                NSURL *fileURL = [NSURL
                                  fileURLWithPath:[NSTemporaryDirectory()
                                                   stringByAppendingPathComponent:fileName]];
                
                [imageData writeToURL:fileURL
                              options:NSDataWritingAtomic
                                error:nil];
                
                AppDelegate *appDelegate =
                [[UIApplication sharedApplication] delegate];
                NSString *urlString = [NSString
                                       stringWithFormat:@"%@%@%@", @"https://",
                                       appDelegate.account.ip, @"/photos/thumbnail"];
                NSURL *url = [NSURL URLWithString:urlString];
                
                // TODO: Get these values from photo
                // eg. filename = actual filename (not unique string)
                NSArray *objects =
                [NSArray arrayWithObjects:photo.deviceId, appDelegate.account.token,
                 uniqueString, @"image/jpeg",photo.remoteID, nil];
                NSArray *keys = [NSArray
                                 arrayWithObjects:@"cid",@"token", @"filename", @"image-type",@"photo_id", nil];
                NSDictionary *headers =
                [NSDictionary dictionaryWithObjects:objects forKeys:keys];
                
                NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
                [request setURL:url];
                [request setHTTPMethod:@"POST"];
                [request setAllHTTPHeaderFields:headers];
                
                NSURLSessionUploadTask *uploadTask =
                [self.session uploadTaskWithRequest:request fromFile:fileURL];
                
                [uploadTask resume];
                NSLog(@"making post request to %@", urlString);
                [readLock lock];
                [readLock unlockWithCondition:WDASSETURL_ALLFINISHED];
                
            }else {
                AppDelegate *appDelegate =
                [[UIApplication sharedApplication] delegate];
                NSString *urlString = [NSString
                                       stringWithFormat:@"%@%@%@", @"https://",
                                       appDelegate.account.ip, @"/photos/thumbnail"];
                
                NSURL *url = [NSURL URLWithString:urlString];
                
                // TODO: Get these values from photo
                // eg. filename = actual filename (not unique string)
                NSArray *objects =
                [NSArray arrayWithObjects:photo.deviceId, appDelegate.account.token,
                 uniqueString, @"image/jpg",photo.remoteID, nil];
                
                // set headers
                NSArray *keys = [NSArray
                                 arrayWithObjects:@"cid",@"token", @"filename", @"image-type",@"photo_id", nil];
                NSDictionary *headers =
                [NSDictionary dictionaryWithObjects:objects forKeys:keys];
                
                NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
                
                [request setURL:url];
                [request setHTTPMethod:@"POST"];
                [request setAllHTTPHeaderFields:headers];
                
                // get documents directory
                NSURL * thumbUrl = [NSURL URLWithString:photo.thumbURL];
                // get image data from file path
                NSData *imageData = [NSData dataWithContentsOfURL:thumbUrl];
                NSString *fileName = [NSString
                                      stringWithFormat:@"%@_%@", photo.thumbnailName, @"image.jpg"];
                NSURL *fileURL =
                [NSURL fileURLWithPath:[NSTemporaryDirectory()
                                        stringByAppendingString:fileName]];
                // write the image data to a temp dir
                [imageData writeToURL:fileURL
                              options:NSDataWritingAtomic
                                error:nil];
                
                
                // upload the file from the temp dir
                NSURLSessionUploadTask *uploadTask =
                [self.session uploadTaskWithRequest:request fromFile:fileURL];
                
                // start upload
                [uploadTask resume];
                
               // [readLock2 lock];
                //NSLog(@"lock 2%@",readLock2);
                //[readLock2 unlockWithCondition:WDASSETURL_ALLFINISHED];
                //NSLog(@"lock 2%@",readLock2);
            }
        };
        ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *err) {
            NSLog(@"can't get image - %@", [err localizedDescription]);
            
            //[readLock2 lock];
            //[readLock2 unlockWithCondition:WDASSETURL_ALLFINISHED];
        };
        
        NSURL *asseturl = [NSURL URLWithString:photo.thumbURL];
        ALAssetsLibrary *assetslibrary = [[ALAssetsLibrary alloc] init];
        [assetslibrary assetForURL:asseturl
                       resultBlock:resultBlock
                      failureBlock:failureBlock];
        
        //[readLock2 lockWhenCondition:WDASSETURL_ALLFINISHED];
        //[readLock2 unlock];
        
        // cleanup
        readLock = nil;
        [application endBackgroundTask:background_task]; // End the task so the
        // system knows that you
        // are done with what you
        // need to perform
        background_task =
        UIBackgroundTaskInvalid;
    });
    
}


// custom url task delegates
- (void)URLSessionDidFinishEventsForBackgroundURLSession:
(NSURLSession *)session {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    [session getTasksWithCompletionHandler:^(NSArray *dataTasks,
                                             NSArray *uploadTasks,
                                             NSArray *downloadTasks) {
        NSLog(@"there are %lu upload tasks", (unsigned long)uploadTasks.count);
        
        if (uploadTasks.count == 0) {
            NSLog(@"Background Session Finished All Events");
            
            // allow app to sleep again
            [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
            
            if (appDelegate.backgroundTransferCompletionHandler != nil) {
                // Copy locally the completion handler.
                void (^completionHandler)() =
                appDelegate.backgroundTransferCompletionHandler;
                
                // Make nil the backgroundTransferCompletionHandler.
                appDelegate.backgroundTransferCompletionHandler = nil;
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    // Call the completion handler to tell the system that there are
                    // no other background transfers.
                    completionHandler();
                    
                    // Show a local notification when all downloads are over.
                    UILocalNotification *localNotification =
                    [[UILocalNotification alloc] init];
                    localNotification.alertBody = @"Finished Uploading Local Photos";
                    [[UIApplication sharedApplication]
                     presentLocalNotificationNow:localNotification];
                }];
            }
        }
    }];
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    
    //  NSLog(@"%lld / %lld bytes", totalBytesSent, totalBytesExpectedToSend);
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    // TODO: Handle error better
    if (error) {
        NSLog(@"%@", error);
        return;
    }
    
    CSPhoto *p = [self getPhotoWithTaskIdentifier:task.taskIdentifier];
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)task.response;
    if ([task.response respondsToSelector:@selector(allHeaderFields)]) {
        NSDictionary *dictionary = [httpResponse allHeaderFields];
        p.remoteID = [dictionary valueForKey:@"photo_id"];
        NSLog(@"upload status %@",dictionary);
    }
    
    //  NSData * data = [NSJSONSerialization dataWithJSONObject:task.response
    //  options:0 error:nil];
    //  NSLog(@"%@", data);
    
    //  NSLog(@"PHOTO COUNT %d", self.uploadingPhotos.count);
    if (p != nil) {
        if (p.remoteID !=nil) {
            NSLog(@"Finsished uploading %@", p.imageURL);
        
            [p onServerSet:YES];
            p.dateUploaded = [NSDate date];
        
            [self.dataWrapper addUpdatePhoto:p];
            if ([p.isVideo isEqualToString:@"1"]) {
                [self uploadVideoThumb:p];
                NSLog(@"uploading the video thumbnails");
            } else {
                [self uploadPhotoThumb:p];
                NSLog(@"uploading the photo thumbnails");
            }
        
            @synchronized(self.uploadingPhotos) {
                p.taskIdentifier = -1;
                [self.uploadingPhotos removeObject:p];
            
                if (self.upCallback != nil) {
                    self.upCallback(p);
                }
            }
        }
    }
}

// need to avoid errors when using https self signed certs
// REMOVE IN PRODUCTION
#warning removing using self-signed certs in production
- (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition,
                             NSURLCredential *))completionHandler {
    
    NSURLCredential *credential = [NSURLCredential
                                   credentialForTrust:challenge.protectionSpace.serverTrust];
    completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
}

@end
