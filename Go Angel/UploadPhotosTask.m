//
//  UploadPhotosTask.m
//  Go Angel
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import "UploadPhotosTask.h"

@implementation UploadPhotosTask

- (id) initWithWrapper:(CoreDataWrapper *)wrap {
  self = [super init];
  
  self.uploadingPhotos = [[NSMutableArray alloc] init];
  assetLibrary = [[ALAssetsLibrary alloc] init];
  self.dataWrapper = wrap;
  
  // setup background session config
    NSURLSessionConfiguration *config;
    NSString *currentVer = [[UIDevice currentDevice] systemVersion];
    NSString *reqVer = @"8.0";
    if([currentVer compare:reqVer options:NSNumericSearch] != NSOrderedAscending) {
    config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[NSString stringWithFormat:@"com.go.upload"]];
    } else {
        config = [NSURLSessionConfiguration backgroundSessionConfiguration:[NSString stringWithFormat:@"com.go.upload"]];
    }
    
    
  [config setSessionSendsLaunchEvents:YES];
  [config setDiscretionary:NO];
  
  // create the sessnon with backaground config
  self.session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
  
  return self;
}

-(NSData *)getPhotoWithMetaData:(UIImage *)image asset:(ALAsset *)asset {
  
  NSData *jpeg = [NSData dataWithData:UIImageJPEGRepresentation(image, 1.0)];
  
  CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)jpeg, NULL);
  
  NSDictionary *metadata = [[asset defaultRepresentation] metadata];
  
  NSMutableDictionary *metadataAsMutable = [metadata mutableCopy];
  
  NSMutableDictionary *EXIFDictionary = [metadataAsMutable objectForKey:(NSString *)kCGImagePropertyExifDictionary];
  NSMutableDictionary *GPSDictionary = [metadataAsMutable objectForKey:(NSString *)kCGImagePropertyGPSDictionary];
  NSMutableDictionary *TIFFDictionary = [metadataAsMutable objectForKey:(NSString *)kCGImagePropertyTIFFDictionary];
  NSMutableDictionary *RAWDictionary = [metadataAsMutable objectForKey:(NSString *)kCGImagePropertyRawDictionary];
  NSMutableDictionary *JPEGDictionary = [metadataAsMutable objectForKey:(NSString *)kCGImagePropertyJFIFDictionary];
  NSMutableDictionary *GIFDictionary = [metadataAsMutable objectForKey:(NSString *)kCGImagePropertyGIFDictionary];
  
  if(!EXIFDictionary) {
    EXIFDictionary = [NSMutableDictionary dictionary];
  }
  
  BOOL gpsMeta = [[NSUserDefaults standardUserDefaults] boolForKey:GPS_META];
  if(!GPSDictionary || !gpsMeta) {
    GPSDictionary = [NSMutableDictionary dictionary];
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
  
  [metadataAsMutable setObject:EXIFDictionary forKey:(NSString *)kCGImagePropertyExifDictionary];
  [metadataAsMutable setObject:GPSDictionary forKey:(NSString *)kCGImagePropertyGPSDictionary];
  [metadataAsMutable setObject:TIFFDictionary forKey:(NSString *)kCGImagePropertyTIFFDictionary];
  [metadataAsMutable setObject:RAWDictionary forKey:(NSString *)kCGImagePropertyRawDictionary];
  [metadataAsMutable setObject:JPEGDictionary forKey:(NSString *)kCGImagePropertyJFIFDictionary];
  [metadataAsMutable setObject:GIFDictionary forKey:(NSString *)kCGImagePropertyGIFDictionary];
  
  CFStringRef UTI = CGImageSourceGetType(source);
  
  NSMutableData *dest_data = [NSMutableData data];
  
  CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)dest_data,UTI,1,NULL);
  
  CGImageDestinationAddImageFromSource(destination,source,0, (__bridge CFDictionaryRef) metadataAsMutable);
  
  BOOL success = NO;
  success = CGImageDestinationFinalize(destination);
  
  if(!success) {
  }
  
  CFRelease(destination);
  CFRelease(source);
  
  return dest_data;
}

- (void) uploadPhotoArray:(NSMutableArray *)photos upCallback: (void (^) ()) upCallback {
  // set the upload callback
  self.upCallback = upCallback;
  
  // This generates a guranteed unique string
  NSString *uniqueString = [[NSProcessInfo processInfo] globallyUniqueString];
  
  __block UIBackgroundTaskIdentifier background_task; //Create a task object
  
  UIApplication *application = [UIApplication sharedApplication];
  
  background_task = [application beginBackgroundTaskWithExpirationHandler: ^ {
    [application endBackgroundTask: background_task]; //Tell the system that we are done with the tasks
    background_task = UIBackgroundTaskInvalid; //Set the task to be invalid
    
    //System will be shutting down the app at any point in time now
  }];
  
  //Background tasks require you to use asyncrous tasks
  // This background task will have 30 seconds to complete before apple kills us
  // This should allow us to start all of the uploads which will then be able to
  // run in the background
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    //Perform your tasks that your application requires
    
    // prevent app from going to sleep when uploading
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    for (CSPhoto *p in photos) {
      // sets up a condition lock with "pending reads"
      readLock = [[NSConditionLock alloc] initWithCondition:WDASSETURL_PENDINGREADS];
      
      ALAssetsLibraryAssetForURLResultBlock resultBlock = ^(ALAsset *asset) {
        ALAssetRepresentation *rep = [asset defaultRepresentation];
        
        CGImageRef iref = [rep fullResolutionImage];
        
        // if the asset exists
        if (iref) { //photos found in album
          // Retrieve the image orientation from the ALAsset
          UIImageOrientation orientation = UIImageOrientationUp;
          NSNumber* orientationValue = [asset valueForProperty:ALAssetPropertyOrientation];
          if (orientationValue != nil) {
            orientation = [orientationValue intValue];
          }
          
          CGFloat scale  = 1;
          
          // correct the image orientation when we upload it
          UIImage *image = [UIImage imageWithCGImage:iref scale:scale orientation:orientation];
          
          // add the metadata to image before we upload
          NSData *imageData = [self getPhotoWithMetaData:image asset:asset];
//          NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
          
          NSString *fileName = [NSString stringWithFormat:@"%@_%@", uniqueString, @"image.jpg"];
          NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
          
          [imageData writeToURL:fileURL options:NSDataWritingAtomic error:nil];
          
          AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
          NSString *urlString = [NSString stringWithFormat:@"%@%@%@", @"https://", appDelegate.account.ip, @"/photos"];
          NSURL *url = [NSURL URLWithString:urlString];
          
          // TODO: Get these values from photo
          // eg. filename = actual filename (not unique string)
          NSArray *objects = [NSArray arrayWithObjects:appDelegate.account.token, uniqueString, @"image/jpeg", nil];
          NSArray *keys = [NSArray arrayWithObjects:@"token", @"filename", @"image-type", nil];
          NSDictionary *headers = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
          
          NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init] ;
          [request setURL:url];
          [request setHTTPMethod:@"POST"];
          [request setAllHTTPHeaderFields:headers];
          
          NSURLSessionUploadTask *uploadTask = [self.session uploadTaskWithRequest:request fromFile:fileURL];
          p.taskIdentifier = uploadTask.taskIdentifier;
          
          @synchronized (self.uploadingPhotos) {
            [self.uploadingPhotos addObject:p];
          }
          
          [uploadTask resume];
          NSLog(@"making post request to %@", urlString);
          
          [readLock lock];
          [readLock unlockWithCondition:WDASSETURL_ALLFINISHED];
        }else{ //if photos not found in album, try to find in application folder
            AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
            NSString *urlString = [NSString stringWithFormat:@"%@%@%@", @"https://", appDelegate.account.ip, @"/photos"];
            
            NSURL *url = [NSURL URLWithString:urlString];
            
            
            // TODO: Get these values from photo
            // eg. filename = actual filename (not unique string)
            NSArray *objects = [NSArray arrayWithObjects:appDelegate.account.token, uniqueString, @"image/jpg", nil];
            
            NSArray *keys = [NSArray arrayWithObjects:@"token", @"filename", @"image-type", nil];
            NSDictionary *headers = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
            NSLog(@"%@",p);
            
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init] ;
            
            [request setURL:url];
            [request setHTTPMethod:@"POST"];
            [request setAllHTTPHeaderFields:headers];
            
            NSURL *filepath = [NSURL URLWithString:[p.imageURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            
            NSURLSessionUploadTask *uploadTask = [self.session uploadTaskWithRequest:request fromFile:filepath];
            
            p.taskIdentifier = uploadTask.taskIdentifier;
            
            @synchronized (self.uploadingPhotos) {
                [self.uploadingPhotos addObject:p];
            }
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
      
      NSURL *asseturl = [NSURL URLWithString:p.imageURL];
      ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
      [assetslibrary assetForURL:asseturl
                     resultBlock:resultBlock
                    failureBlock:failureBlock];
      
      // non-busy wait for the asset read to finish (specifically until the condition is "all finished")
      [readLock lockWhenCondition:WDASSETURL_ALLFINISHED];
      [readLock unlock];
      
      // cleanup
      readLock = nil;
    }
    
    [application endBackgroundTask: background_task]; //End the task so the system knows that you are done with what you need to perform
    background_task = UIBackgroundTaskInvalid; //Invalidate the background_task
  });
}

// NSConditionLock values
enum {
  WDASSETURL_PENDINGREADS = 1,
  WDASSETURL_ALLFINISHED = 0
};

- (CSPhoto *) getPhotoWithTaskIdentifier: (unsigned long) taskId {
  for (CSPhoto *p in self.uploadingPhotos) {
    if (p.taskIdentifier == taskId) {
      return p;
    }
  }
  return nil;
}

// custom url task delegates
- (void) URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
  AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
  
  [session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
    NSLog(@"there are %lu upload tasks", (unsigned long)uploadTasks.count);
    
    if (uploadTasks.count == 0) {
      NSLog(@"Background Session Finished All Events");
      
      // allow app to sleep again
      [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
      
      if (appDelegate.backgroundTransferCompletionHandler != nil) {
        // Copy locally the completion handler.
        void(^completionHandler)() = appDelegate.backgroundTransferCompletionHandler;
        
        // Make nil the backgroundTransferCompletionHandler.
        appDelegate.backgroundTransferCompletionHandler = nil;
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
          // Call the completion handler to tell the system that there are no other background transfers.
          completionHandler();
          
          // Show a local notification when all downloads are over.
          UILocalNotification *localNotification = [[UILocalNotification alloc] init];
          localNotification.alertBody = @"Finished Uploading Local Photos";
          [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
        }];
      }
    }
  }];
}

- (void) URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
  
  //  NSLog(@"%lld / %lld bytes", totalBytesSent, totalBytesExpectedToSend);
}

- (void) URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
  // TODO: Handle error better
  if (error) {
    NSLog(@"%@", error);
    return;
  }
  
  CSPhoto *p = [self getPhotoWithTaskIdentifier:task.taskIdentifier];
  //  NSLog(@"PHOTO COUNT %d", self.uploadingPhotos.count);
  if (p != nil) {
    NSLog(@"Finsished uploading %@", p.imageURL);
    
    [p onServerSet:YES];
    p.dateUploaded = [NSDate date];
    [self.dataWrapper addUpdatePhoto:p];
    
    @synchronized (self.uploadingPhotos) {
      p.taskIdentifier = -1;
      [self.uploadingPhotos removeObject:p];
      
      if (self.upCallback != nil) {
        self.upCallback();
      }
    }
  }
}

# warning removing using self-signed certs in production
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
  
  NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
  completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
}

@end
