//
//  UploadPhotosTask.m
//  Go Arch
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
        NSString *name = photo.album.entry.location.sublocation;
        NSString *unit = photo.album.entry.location.unit;
        NSString *city = photo.album.entry.location.city;
        NSString *state = photo.album.entry.location.province;
        NSString *countryCode = photo.album.entry.location.countryCode;
        NSString *country = photo.album.entry.location.country;
        NSString *longitude = photo.album.entry.location.longitude;
        NSString *latitude = photo.album.entry.location.latitude;
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
//    if (gpsMeta) {
//        
//        NSString *longitude = [defaults objectForKey:CURR_LOC_LONG];
//        NSString *latitude = [defaults objectForKey:CURR_LOC_LAT];
//        [GPSDictionary setObject:longitude forKeyedSubscript:(NSString *) kCGImagePropertyGPSLongitude];
//        [GPSDictionary setObject:latitude forKeyedSubscript:(NSString *) kCGImagePropertyGPSLatitude];
//    }
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
-(void)uploadOnePhoto:(CSPhoto *)p upCallback:(void (^)())upCallback {
    // set the upload callback
    self.fullPhotoCallback = upCallback;
    
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
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        // Perform your tasks that your application requires
        
        // prevent app from going to sleep when uploading
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        if ([p.isVideo isEqualToString:@"1"]) {
            NSLog(@"uploading from device folder");
            AppDelegate *appDelegate =
            [[UIApplication sharedApplication] delegate];
            NSString *urlString = [NSString
                                   stringWithFormat:@"%@%@%@%@", @"https://",
                                   appDelegate.account.currentIp,@":8443", @"/videos"];
          
            NSURL *url = [NSURL URLWithString:urlString];
            
            NSArray * keys;
            NSArray *objects;
            
            NSString *name = p.album.entry.location.sublocation;
            NSString *unit = p.album.entry.location.unit;
            NSString *city = p.album.entry.location.city;
            NSString *state = p.album.entry.location.province;
            NSString *countryCode = p.album.entry.location.countryCode;
            NSString *country = p.album.entry.location.country;
            NSString *longitude = p.album.entry.location.longitude;
            NSString *latitude = p.album.entry.location.latitude;
            NSString *sublocation = name;
            if (!unit) {
                unit = @"";
            }
            if (![unit isEqualToString:@""]) {
                sublocation = [NSString stringWithFormat:@"Unit %@ - %@", unit, name];
            }
            //if (tagLocation) {
            keys = [NSArray
                    arrayWithObjects:@"cid",@"token",@"photo_id", @"filename", @"file-type", @"longitude", @"latitude", @"city", @"state", @"countryCode", @"country", @"sublocation",nil];
            objects = [NSArray arrayWithObjects:p.deviceId, appDelegate.account.token, p.remoteID, uniqueString, @"movie/mov", longitude,latitude, city, state, countryCode, country, sublocation, nil];
            NSDictionary *headers =
            [NSDictionary dictionaryWithObjects:objects forKeys:keys];
            
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
            [request setURL:url];
            [request setHTTPMethod:@"POST"];
            [request setAllHTTPHeaderFields:headers];
            
            // get documents directory
            NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            //NSString *documentsDirectory = [pathArray objectAtIndex:0];
            NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/MyVideo"];
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
            
            
        } else {
            AppDelegate *appDelegate =
            [[UIApplication sharedApplication] delegate];
            NSString *urlString = [NSString
                                   stringWithFormat:@"%@%@%@%@", @"https://",
                                   appDelegate.account.currentIp,@":8443", @"/photos"];
            
            NSURL *url = [NSURL URLWithString:urlString];
            
            // TODO: Get these values from photo
            // eg. filename = actual filename (not unique string)
            NSArray *objects =
            [NSArray arrayWithObjects:p.deviceId, appDelegate.account.token,
             uniqueString, p.remoteID, @"image/jpg", nil];
            
            // set headers
            NSArray *keys = [NSArray
                             arrayWithObjects:@"cid",@"token", @"filename", @"photo_id",@"image-type", nil];
            NSDictionary *headers =
            [NSDictionary dictionaryWithObjects:objects forKeys:keys];
            
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
            
            [request setURL:url];
            [request setHTTPMethod:@"POST"];
            [request setAllHTTPHeaderFields:headers];
            
            // get documents directory
            NSArray *pathArray = NSSearchPathForDirectoriesInDomains(
                                                                     NSDocumentDirectory, NSUserDomainMask, YES);
            //NSString *documentsDirectory = [pathArray objectAtIndex:0];
            NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/MyImage"];
            NSString *textPath = [documentsDirectory
                                  stringByAppendingPathComponent:p.fileName];
            NSLog(@"text paht %@",textPath);
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
            
        }
        [application endBackgroundTask:background_task]; // End the task so the
        // system knows that you
        // are done with what you
        // need to perform
        background_task =
        UIBackgroundTaskInvalid;
        
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

- (void)uploadPhotoThumb:(NSMutableArray *)photos upCallback:(void (^)())upCallback{
    
    self.upCallback = upCallback;
    
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
        for (CSPhoto *p in photos) {
            if ([p.isVideo isEqualToString:@"1"]) {
                AppDelegate *appDelegate =
                [[UIApplication sharedApplication] delegate];
                NSString *urlString = [NSString
                                       stringWithFormat:@"%@%@%@%@", @"https://",
                                       appDelegate.account.currentIp, @":8443", @"/videos/thumbnail"];
                
                NSURL *url = [NSURL URLWithString:urlString];
                
                NSArray * keys;
                NSArray *objects;
                
                NSString *name = p.album.entry.location.sublocation;
                NSString *unit = p.album.entry.location.unit;
                NSString *city = p.album.entry.location.city;
                NSString *state = p.album.entry.location.province;
                NSString *countryCode = p.album.entry.location.countryCode;
                NSString *country = p.album.entry.location.country;
                NSString *longitude = p.album.entry.location.longitude;
                NSString *latitude = p.album.entry.location.latitude;
                NSString *sublocation = name;
                NSString *albumId = p.album.albumId;
                if (!unit) {
                    unit = @"";
                }
                if (![unit isEqualToString:@""]) {
                    sublocation = [NSString stringWithFormat:@"Unit %@ - %@", unit, name];
                }
                NSLog(@"SUBLOCATION: %@\n", sublocation);
                //if (tagLocation) {
                keys = [NSArray
                        arrayWithObjects:@"cid",@"token", @"filename", @"file-type", @"longitude", @"latitude", @"city", @"state", @"countryCode", @"country", @"sublocation",@"album_id",nil];
                objects = [NSArray arrayWithObjects:p.deviceId, appDelegate.account.token, uniqueString, @"movie/mov", longitude,latitude, city, state, countryCode, country, sublocation,albumId, nil];
                
                NSDictionary *headers =
                [NSDictionary dictionaryWithObjects:objects forKeys:keys];
                
                NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
                
                [request setURL:url];
                [request setHTTPMethod:@"POST"];
                [request setAllHTTPHeaderFields:headers];
                
                // get documents directory
                NSArray *pathArray = NSSearchPathForDirectoriesInDomains(
                                                                         NSDocumentDirectory, NSUserDomainMask, YES);
                //NSString *documentsDirectory = [pathArray objectAtIndex:0];
                NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/MyVideo"];
                
                NSString *textPath = [documentsDirectory
                                      stringByAppendingPathComponent:p.thumbnailName];
                
                // get image data from file path
                NSData *imageData = [NSData dataWithContentsOfFile:textPath];
                NSString *fileName = [NSString
                                      stringWithFormat:@"%@_%@", p.thumbnailName, @"image.jpg"];
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
                
            } else {
                AppDelegate *appDelegate =
                [[UIApplication sharedApplication] delegate];
                NSString *urlString = [NSString
                                       stringWithFormat:@"%@%@%@%@", @"https://",
                                       appDelegate.account.currentIp, @":8443", @"/photos/thumbnail"];
                
                NSURL *url = [NSURL URLWithString:urlString];
                
                NSArray * keys;
                NSArray *objects;
                
                NSString *name =p.album.entry.location.sublocation;
                NSString *unit = p.album.entry.location.unit;
                NSString *city = p.album.entry.location.city;
                NSString *state = p.album.entry.location.province;
                NSString *countryCode = p.album.entry.location.countryCode;
                NSString *country = p.album.entry.location.country;
                NSString *longitude = p.album.entry.location.longitude;
                NSString *latitude = p.album.entry.location.latitude;
                NSString *sublocation = name;
                NSString *albumId = p.album.albumId;
                if (!unit) {
                    unit = @"";
                }
                if (![unit isEqualToString:@""]) {
                    sublocation = [NSString stringWithFormat:@"Unit %@ - %@", unit, name];
                }
                //if (tagLocation) {
                keys = [NSArray
                        arrayWithObjects:@"cid",@"token", @"filename", @"file-type", @"longitude", @"latitude", @"city", @"state", @"countryCode", @"country", @"sublocation",@"album_id",nil];
                objects = [NSArray arrayWithObjects:p.deviceId, appDelegate.account.token, uniqueString, @"movie/mov", longitude,latitude, city, state, countryCode, country, sublocation,albumId, nil];
                
                NSDictionary *headers =
                [NSDictionary dictionaryWithObjects:objects forKeys:keys];
                
                NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
                
                [request setURL:url];
                [request setHTTPMethod:@"POST"];
                [request setAllHTTPHeaderFields:headers];
                
                // get documents directory
                NSArray *pathArray = NSSearchPathForDirectoriesInDomains(
                                                                         NSDocumentDirectory, NSUserDomainMask, YES);
               // NSString *documentsDirectory = [pathArray objectAtIndex:0];
                NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/MyImage"];
                NSString *textPath = [documentsDirectory
                                      stringByAppendingPathComponent:p.thumbnailName];
                NSLog(@"text path %@",textPath);
                // get image data from file path
                NSData *imageData = [NSData dataWithContentsOfFile:textPath];
                
                
                NSString *fileName = [NSString
                                      stringWithFormat:@"%@_%@", p.thumbnailName, @"image.jpg"];
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
            }
        }
        [application endBackgroundTask:background_task]; // End the task so the
        // system knows that you
        // are done with what you
        // need to perform
        background_task =
        UIBackgroundTaskInvalid;
    });
    
}

- (void)uploadOneThumb:(CSPhoto *)photo upCallback:(void (^)())upCallback{
    self.upCallback = upCallback;
    
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
        if ([photo.isVideo isEqualToString:@"1"]) {
            AppDelegate *appDelegate =
            [[UIApplication sharedApplication] delegate];
            NSString *urlString = [NSString
                                   stringWithFormat:@"%@%@%@%@", @"https://",
                                   appDelegate.account.currentIp, @":8443", @"/videos/thumbnail"];
            
            NSURL *url = [NSURL URLWithString:urlString];
            
            NSArray * keys;
            NSArray *objects;
            
            NSString *name = photo.album.entry.location.sublocation;
            NSString *unit = photo.album.entry.location.unit;
            NSString *city = photo.album.entry.location.city;
            NSString *state = photo.album.entry.location.province;
            NSString *countryCode = photo.album.entry.location.countryCode;
            NSString *country = photo.album.entry.location.country;
            NSString *longitude = photo.album.entry.location.longitude;
            NSString *latitude = photo.album.entry.location.latitude;
            NSString *sublocation = name;
            NSString *albumId = photo.album.albumId;
            if (!unit) {
                unit = @"";
            }
            if (![unit isEqualToString:@""]) {
                sublocation = [NSString stringWithFormat:@"Unit %@ - %@", unit, name];
            }
            //if (tagLocation) {
            keys = [NSArray
                    arrayWithObjects:@"cid",@"token", @"filename", @"file-type", @"longitude", @"latitude", @"city", @"state", @"countryCode", @"country", @"sublocation",@"album_id",nil];
            objects = [NSArray arrayWithObjects:photo.deviceId, appDelegate.account.token, uniqueString, @"movie/mov", longitude,latitude, city, state, countryCode, country, sublocation,albumId, nil];
            
            NSDictionary *headers =
            [NSDictionary dictionaryWithObjects:objects forKeys:keys];
            
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
            
            [request setURL:url];
            [request setHTTPMethod:@"POST"];
            [request setAllHTTPHeaderFields:headers];
            
            // get documents directory
           /* NSArray *pathArray = NSSearchPathForDirectoriesInDomains(
                                                                     NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [pathArray objectAtIndex:0];*/
            NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/MyVideo"];
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
            
            photo.taskIdentifier = uploadTask.taskIdentifier;
            
            @synchronized(self.uploadingPhotos) {
                [self.uploadingPhotos addObject:photo];
            }
            
            // start upload
            [uploadTask resume];
            
        } else {
            AppDelegate *appDelegate =
            [[UIApplication sharedApplication] delegate];
            NSString *urlString = [NSString
                                   stringWithFormat:@"%@%@%@%@", @"https://",
                                   appDelegate.account.currentIp, @":8443", @"/photos/thumbnail"];
            
            NSURL *url = [NSURL URLWithString:urlString];
            
            NSArray * keys;
            NSArray *objects;
            
            NSString *name = photo.album.entry.location.sublocation;
            NSString *unit = photo.album.entry.location.unit;
            NSString *city = photo.album.entry.location.city;
            NSString *state = photo.album.entry.location.province;
            NSString *countryCode = photo.album.entry.location.countryCode;
            NSString *country = photo.album.entry.location.country;
            NSString *longitude = photo.album.entry.location.longitude;
            NSString *latitude = photo.album.entry.location.latitude;
            NSString *sublocation = name;
            NSString *albumId = photo.album.albumId;
            if (!unit) {
                unit = @"";
            }
            if (![unit isEqualToString:@""]) {
                sublocation = [NSString stringWithFormat:@"Unit %@ - %@", unit, name];
            }
            //if (tagLocation) {
            /*
            keys = [NSArray
                    arrayWithObjects:@"cid",@"token", @"filename", @"file-type", @"longitude", @"latitude", @"city", @"state", @"countryCode", @"country", @"sublocation",@"album_id",nil];
            objects = [NSArray arrayWithObjects:photo.deviceId, appDelegate.account.token, uniqueString, @"movie/mov", longitude,latitude, city, state, countryCode, country, sublocation,albumId, nil];
            
            */
            keys = [NSArray
                    arrayWithObjects:@"cid",@"token", @"filename", @"file-type", @"longitude", @"latitude", @"city", @"state", @"country", @"sublocation",@"album_id",nil];
            objects = [NSArray arrayWithObjects:photo.deviceId, appDelegate.account.token, uniqueString, @"movie/mov", longitude,latitude, city, state, country, sublocation,albumId, nil];
            NSDictionary *headers =
            [NSDictionary dictionaryWithObjects:objects forKeys:keys];
            
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
            
            [request setURL:url];
            [request setHTTPMethod:@"POST"];
            [request setAllHTTPHeaderFields:headers];
            
            // get documents directory
            NSArray *pathArray = NSSearchPathForDirectoriesInDomains(
                                                                     NSDocumentDirectory, NSUserDomainMask, YES);
           // NSString *documentsDirectory = [pathArray objectAtIndex:0];
            
            NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/MyImage"];
            
            NSString *textPath = [documentsDirectory
                                  stringByAppendingPathComponent:photo.thumbnailName];
            NSLog(@"text path %@",textPath);
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
            
            photo.taskIdentifier = uploadTask.taskIdentifier;
            
            @synchronized(self.uploadingPhotos) {
                [self.uploadingPhotos addObject:photo];
            }
            
            // start upload
            [uploadTask resume];
        }
        
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
    p = [self.dataWrapper getPhoto:p.imageURL];
    NSString *stat;
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)task.response;
    if ([task.response respondsToSelector:@selector(allHeaderFields)]) {
        NSDictionary *dictionary = [httpResponse allHeaderFields];
        p.remoteID = [dictionary valueForKey:@"photo_id"];
        stat = [dictionary valueForKey:@"stat"];
        NSLog(@"upload status %@",dictionary);
    }
    NSInteger responseStatusCode = [httpResponse statusCode];
    NSLog(@"code %ld",(long)responseStatusCode);
    
    if (responseStatusCode == 403) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"passwordChanged" object:nil];
    } else if (responseStatusCode == 200) {
        if (p != nil) {
            if (p.remoteID !=nil) {
                NSLog(@"Finsished uploading thumbnail %@", p.thumbURL);
                
                [p thumbOnServerSet:YES];
                p.dateUploaded = [NSDate date];
                
                [self.dataWrapper addUpdatePhoto:p];
                
                @synchronized(self.uploadingPhotos) {
                    p.taskIdentifier = -1;
                    [self.uploadingPhotos removeObject:p];
                    
                    if (self.upCallback != nil) {
                        self.upCallback(p);
                    }
                }
            } else if (stat !=nil) {
                NSLog(@"Finsished uploading full image %@", p.imageURL);
                
                [p fullOnServerSet:YES];
                p.dateUploaded = [NSDate date];
                
                [self.dataWrapper addUpdatePhoto:p];
                
                @synchronized(self.uploadingPhotos) {
                    p.taskIdentifier = -1;
                    [self.uploadingPhotos removeObject:p];
                    
                    if (self.fullPhotoCallback != nil) {
                        self.fullPhotoCallback(p);
                    }
                }
                
                
            }
        }
        //  NSData * data = [NSJSONSerialization dataWithJSONObject:task.response
        //  options:0 error:nil];
        //  NSLog(@"%@", data);
        
        //  NSLog(@"PHOTO COUNT %d", self.uploadingPhotos.count);
        
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
