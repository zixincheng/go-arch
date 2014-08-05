//
//  Coinsorter.m
//  coinsorter-ios
//
//  Created by Jake Runzer on 7/14/14.
//  Copyright (c) 2014 Jake Runzer. All rights reserved.
//

#import "Coinsorter.h"

#define FRONT_URL @"https://"
#define UUID_ACCOUNT @"UID_ACCOUNT"

#define DEVICE_NAME @"deviceName"

@implementation Coinsorter


-(id) initWithWrapper:(CoreDataWrapper *)wrap {
  self = [super init];
  
  AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
  account = appDelegate.account;
  
  self.dataWrapper = wrap;
  
  uploadTask = [[UploadPhotosTask alloc] initWithWrapper:self.dataWrapper];
  
  return self;
}

- (NSMutableURLRequest *) getHTTPGetRequest: (NSString *) path {
  NSString *urlString = [NSString stringWithFormat:@"%@%@%@", FRONT_URL, account.ip, path];
  NSURL *url = [NSURL URLWithString:urlString];
  
  NSDictionary *headers = @{@"token" : account.token};
  
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init] ;
  [request setURL:url];
  [request setHTTPMethod:@"GET"];
  [request setAllHTTPHeaderFields:headers];
  
  NSLog(@"making get request to %@", urlString);
  
  return request;
}

- (NSMutableURLRequest *) getHTTPPostRequest: (NSString *) path {
  NSString *urlString = [NSString stringWithFormat:@"%@%@%@", FRONT_URL, account.ip, path];
  NSURL *url = [NSURL URLWithString:urlString];
  
  NSDictionary *headers = @{@"token" : account.token};
  
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init] ;
  [request setURL:url];
  [request setHTTPMethod:@"POST"];
  [request setAllHTTPHeaderFields:headers];
  
  NSLog(@"making post request to %@", urlString);
  
  return request;
}

- (void) pingServer:(void (^) (BOOL connected))connectCallback {
  NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
  NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];

  NSMutableURLRequest *request = [self getHTTPGetRequest:@"/getSID"];
  [request setTimeoutInterval:5]; // timout to 5 seconds
  
  NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    if (error == nil) {
      NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
      
      NSString *sid = [jsonData objectForKey:@"SID"];
      
      if (sid != nil && [sid isEqualToString:account.sid]) {
        // we are connected
        connectCallback(YES);
      }else {
        // no server id or it does not equal the server
        // we have connected to before
        connectCallback(NO);
      }
    }else {
      connectCallback(NO);
    }
  }];
  
  [dataTask resume];
}

// update the device information on server
- (void) updateDevice {
  NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
  NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:defaultConfigObject delegate:self delegateQueue:nil];
  NSMutableURLRequest *request = [self getHTTPPostRequest:[NSString stringWithFormat:@"/devices/update/id=%@", account.cid]];
  
  [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
  [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
  
  NSDictionary *mapData = [self getThisDeviceInformation];
  
  NSError *error;
  NSData *postData = [NSJSONSerialization dataWithJSONObject:mapData options:0 error:&error];
  [request setHTTPBody:postData];
  
  NSURLSessionDataTask *postDataTask = [defaultSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    NSError *jsonError;
    NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    
    
  }];
  
  [postDataTask resume];
}

- (void) getDevices: (void (^) (NSMutableArray *devices)) callback {
  NSOperationQueue *background = [[NSOperationQueue alloc] init];
  
  NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
  NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:defaultConfigObject delegate:self delegateQueue:background];
  NSMutableURLRequest *request = [self getHTTPGetRequest:@"/devices"];
  
  //    ^(NSData *data, NSURLResponse *response, NSError *error)
  NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    if (error == nil) {
      NSError *jsonError;
      NSArray *deviceArr = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
      
      NSMutableArray *devices = [[NSMutableArray alloc] init];
      
      for (NSDictionary *d in deviceArr) {
        NSString *deviceName = [d objectForKey:@"device_name"];
        NSString *remoteId = [d objectForKey:@"_id"];
        
        CSDevice *newDev = [[CSDevice alloc] init];
        newDev.deviceName = deviceName;
        newDev.remoteId = remoteId;
        
        [devices addObject:newDev];
      }
      
      NSLog(@"sent %lu devices to callback", (unsigned long)devices.count);
      callback(devices);
    }
  }];
  
  [dataTask resume];
}

-(NSData *)dataFromBase64EncodedString:(NSString *)string{
  if (string.length > 0) {
    
    //the iPhone has base 64 decoding built in but not obviously. The trick is to
    //create a data url that's base 64 encoded and ask an NSData to load it.
    NSString *data64URLString = [NSString stringWithFormat:@"data:;base64,%@", string];
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:data64URLString]];
    return data;
  }
  return nil;
}

- (NSDictionary *) getThisDeviceInformation {
  NSString *manufacturer = @"Apple";
  NSString *firmware_version = [[UIDevice currentDevice] systemVersion];
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  
  NSString *deviceName = [defaults objectForKey:DEVICE_NAME];
  
  //    NSDictionary *mapData = @{@"Device_Name": name, @"Manufacturer": manufacturer, @"Firmware": firmware_version};
  NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: deviceName, @"Device_Name", manufacturer, @"Manufacturer", firmware_version, @"Firmware", nil];
  
  return mapData;
}

- (void) getPhotos:(NSString *)lastId callback: (void (^) (NSMutableArray *photos)) callback {
  
  NSOperationQueue *background = [[NSOperationQueue alloc] init];
  
  NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
  NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:defaultConfigObject delegate:self delegateQueue:background];
  NSMutableURLRequest *request = [self getHTTPGetRequest:[NSString stringWithFormat:@"/photos/afterId?photo_id=%@&devNot=%@", lastId, @"1"]];
  
  // download the photos
  NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    if (error == nil) {
      NSError *jsonError;
      NSDictionary *photosDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
      
      if (photosDic == nil) {
        NSLog(@"the response is not valid json");
        return;
      }
      
      NSArray *photoArr = [photosDic valueForKey:@"photos"];
      
      if (photoArr == nil) {
        NSLog(@"there are no new photos from server");
        return;
      }
      
      NSMutableArray *photos = [[NSMutableArray alloc] init];
      
      NSLog(@"Downloaded %lu photos", (unsigned long)photoArr.count);
      
      // parse the json
      for (NSDictionary *p in photoArr) {
        NSString *photoId = [p objectForKey:@"_id"];
        NSString *deviceId = [p objectForKey:@"device_id"];
        
        NSArray *photo_data = [p objectForKey:@"photo_data"];
        NSDictionary *latest = photo_data[0];
        
        NSString *thumbnail = [latest objectForKey:@"thumbnail"];
        
        CSPhoto *photo = [[CSPhoto alloc] init];
        
        // TODO : Parse the string so it acutally works
        
        //                NSString *dateString = [latest objectForKey:@"created_date"];
        //                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        //                [dateFormatter setLocale:[NSLocale currentLocale]];
        //                [dateFormatter setDateFormat:@"yyyy-MM-ddTHH:mm:ssZ"];
        //                NSDate *date = [dateFormatter dateFromString:dateString];
        //
        //                NSLog(@"dateString - %@ date - %@", dateString, date);
        
        photo.deviceId = deviceId;
        photo.remoteID = photoId;
        
        photo.onServer = @"1";
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths objectAtIndex:0];
        NSString *filePath = [documentsPath stringByAppendingString:[NSString stringWithFormat:@"/%@.jpg", photoId]];
        
        NSString *fullPath = [[NSURL fileURLWithPath:filePath] absoluteString];
        
        photo.thumbURL = fullPath;
        photo.imageURL = fullPath;
        
        NSData *data = [self dataFromBase64EncodedString:thumbnail];
        [data writeToFile:filePath atomically:YES];
        
        NSLog(@"saving thumbnail to %@", filePath);
        
        [photos addObject:photo];
      }
      
      callback(photos);
    }
  }];
  
  [dataTask resume];
}

// upload photos from array
// the callback is what we want to do after each photo is uploaded
- (void) uploadPhotos:(NSMutableArray *)photos upCallback:(void (^)())upCallback {
  
  // start the recursive calls
//  [self uploadOnePhoto:photos index:0];
//  [self uploadTaskPhoto:photos];
  
  // hand off the upload to another class
  // we do this because it has its custom upload delegates
  // that can't screw with download ones
  [uploadTask uploadPhotoArray:photos upCallback:upCallback];
}

// This the old way of uploading photos and thumbnails using data task
- (void) uploadOnePhoto: (NSMutableArray *) photos index: (int) index {
  CSPhoto *p = [photos objectAtIndex:index];
  
  // create the post request
  NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
  NSURLSession *uploadSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
  
  NSString *filePath = p.imageURL;
  
  ALAssetsLibraryAssetForURLResultBlock resultBlock = ^(ALAsset *asset) {
    ALAssetRepresentation *rep = [asset defaultRepresentation];
    CGImageRef iref = [rep fullResolutionImage];
    
    // if the asset exists
    if (iref) {
      UIImage *image = [UIImage imageWithCGImage:iref];
      NSData *imageData = UIImageJPEGRepresentation(image, 100);
      
      NSString *boundary = @"--XXXX--";
      
      // create request
      NSMutableURLRequest *request = [self getHTTPPostRequest:@"/photos"];
      [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
      [request setHTTPShouldHandleCookies:NO];
      [request setTimeoutInterval:30];
      [request setHTTPMethod:@"POST"];
      
      // set Content-Type in HTTP header
      NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
      [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
      
      // post body
      NSMutableData *body = [NSMutableData data];
      
      // get the file name from path
      NSString *fileName = [filePath lastPathComponent];
      
      // add image data
      if (imageData) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", @"fileUpload", fileName] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:imageData];
        [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
      }
      
      // get the thumbnail data
      NSString *thumbPrefix = @"file://";
      NSString *thumbPath = p.thumbURL;
      NSString *pureThumbPath = [thumbPath substringFromIndex:thumbPrefix.length];
      NSData *thumbData = [NSData dataWithContentsOfFile:pureThumbPath];
      NSString *thumbName = [pureThumbPath lastPathComponent];
      
      // add the thumbnail data
      if (thumbData) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", @"fileThumb", thumbName] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:thumbData];
        [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
      }
      
      
      [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
      
      // setting the body of the post to the reqeust
      [request setHTTPBody:body];
      
      // set the content-length
      NSString *postLength = [NSString stringWithFormat:@"%d", [body length]];
      [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
      
      NSURLSessionDataTask *uploadTask = [uploadSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        NSError *jsonError;
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        
        //                    NSLog(@"%@", jsonData);
        
        if (jsonData != nil) {
          NSString *result = [jsonData valueForKeyPath:@"stat"];
          if (result != nil) {
            NSLog(@"%@", result);
          }else {
            NSLog(@"the result is null");
          }
          
          p.onServer = @"1";
          [self.dataWrapper addUpdatePhoto:p];
          
          NSLog(@"setting photo to onServer = True");
          
          if (index < photos.count - 1) {
            int i = index + 1;
            NSLog(@"uploading next photo with index %d", i);
            [self uploadOnePhoto:photos index:i];
          }
        }
      }];
      
      [uploadTask resume];
    }
  };
  
  ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *err) {
    NSLog(@"can't get image - %@", [err localizedDescription]);
  };
  
  NSURL *asseturl = [NSURL URLWithString:p.imageURL];
  ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
  [assetslibrary assetForURL:asseturl
                 resultBlock:resultBlock
                failureBlock:failureBlock];
  
}

- (void) getToken:(NSString *)ip pass:(NSString *)pass callback: (void (^) (NSDictionary *authData)) callback {
  NSString *urlString = [NSString stringWithFormat:@"%@%@%@", FRONT_URL, ip, @"/auth"];
  NSURL *url = [NSURL URLWithString:urlString];
  
  NSError *error;
  
  NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
  NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
  
  NSString *uid = [self uniqueAppId];
  
  NSDictionary *headers = @{
                            @"pass" : pass,
                            @"uid"  : uid
                            };
  
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init] ;
  [request setURL:url];
  [request setHTTPMethod:@"POST"];
  [request setAllHTTPHeaderFields:headers];
  
  NSDictionary *mapData = [self getThisDeviceInformation];
  
  [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
  [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
  
  NSData *postData = [NSJSONSerialization dataWithJSONObject:mapData options:0 error:&error];
  [request setHTTPBody:postData];
  
  NSLog(@"making post request to %@", urlString);
  
  NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    NSError *jsonError;
    NSDictionary *authData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    
    callback(authData);
  }];
  
  [postDataTask resume];
}

// on first run this will get the app vender uid and save in the device keychain
// if the app is reinstalled, it will get the original uid from keychain
// without this, the uid would change if the app was reinstalled
- (NSString *)uniqueAppId {
  NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
  NSString *strApplicationUUID = [SSKeychain passwordForService:appName account:UUID_ACCOUNT];
  if (strApplicationUUID == nil) {
    strApplicationUUID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    [SSKeychain setPassword:strApplicationUUID forService:appName account:UUID_ACCOUNT];
  }
  return strApplicationUUID;
}

# warning removing using self-signed certs in production
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
  
  NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
  completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
}

@end
