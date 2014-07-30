//
//  UploadPhotosTask.m
//  Coinsorter
//
//  Created by Jake Runzer on 7/30/14.
//  Copyright (c) 2014 ACDSystems. All rights reserved.
//

#import "UploadPhotosTask.h"

@implementation UploadPhotosTask

- (id) init {
  self = [super init];
  
  self.uploadingPhotos = [[NSMutableArray alloc] init];
  
  assetLibrary = [[ALAssetsLibrary alloc] init];
  
  return self;
}

- (void) uploadPhotoArray:(NSMutableArray *)photos {
  
  //recursive upload
  [self uploadPhoto:photos index:0];
}

// NSConditionLock values
enum {
  WDASSETURL_PENDINGREADS = 1,
  WDASSETURL_ALLFINISHED = 0
};


- (void) uploadPhoto:(NSMutableArray *)photos index: (int) index {
  
  // This generates a guranteed unique string
  NSString *uniqueString = [[NSProcessInfo processInfo] globallyUniqueString];
  
  // setup background session config
  NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfiguration:[NSString stringWithFormat:@"com.go.upload.%@", uniqueString]];
  [config setSessionSendsLaunchEvents:YES];
  [config setHTTPMaximumConnectionsPerHost:1];
  [config setTimeoutIntervalForRequest:30];
  [config setRequestCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
  
  // create the sessnon with backaground config
  NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
  
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
    
    for (CSPhoto *p in photos) {
      // sets up a condition lock with "pending reads"
      readLock = [[NSConditionLock alloc] initWithCondition:WDASSETURL_PENDINGREADS];
      
      ALAssetsLibraryAssetForURLResultBlock resultBlock = ^(ALAsset *asset) {
        ALAssetRepresentation *rep = [asset defaultRepresentation];
        
        CGImageRef iref = [rep fullResolutionImage];
        
        // if the asset exists
        if (iref) {
          UIImage *image = [UIImage imageWithCGImage:iref];
          NSData *imageData = UIImageJPEGRepresentation(image, 100);
          
          NSString *fileName = [NSString stringWithFormat:@"%@_%@", uniqueString, @"image.jpg"];
          NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
          
          [imageData writeToURL:fileURL options:NSDataWritingAtomic error:nil];
          
          AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
          NSString *urlString = [NSString stringWithFormat:@"%@%@%@", @"https://", appDelegate.account.ip, @"/photos"];
          NSURL *url = [NSURL URLWithString:urlString];
          NSDictionary *headers = @{@"token" : appDelegate.account.token};
          
          NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init] ;
          [request setURL:url];
          [request setHTTPMethod:@"POST"];
          [request setAllHTTPHeaderFields:headers];
          
          NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request fromFile:fileURL];
          p.taskIdentifier = uploadTask.taskIdentifier;
          
          @synchronized (self.uploadingPhotos) {
            [self.uploadingPhotos addObject:p];
          }
        
          [uploadTask resume];
          NSLog(@"making post request to %@", urlString);
          
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
    NSLog(@"there are %d upload tasks", uploadTasks.count);
    
    NSLog(@"Background Session Finished All Events");
    
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
  }];
}

- (void) URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
  
//  NSLog(@"%lld / %lld bytes", totalBytesSent, totalBytesExpectedToSend);
}

- (void) URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
  if (error) {
    NSLog(@"%@", error);
    return;
  }
  
  CSPhoto *p = [self getPhotoWithTaskIdentifier:task.taskIdentifier];
//  NSLog(@"PHOTO COUNT %d", self.uploadingPhotos.count);
  if (p != nil) {
    NSLog(@"Finsished uploading %@", p.imageURL);
    
    @synchronized (self.uploadingPhotos) {
      p.taskIdentifier = -1;
      [self.uploadingPhotos removeObject:p];
    }
  }
}

# warning removing using self-signed certs in production
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
  
  NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
  completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
}

@end
