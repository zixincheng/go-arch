//
//  Coinsorter.m
//  Go Arch
//
// acdGO data backup and recovery
// © acdGO Softwa:qre, Ltd., 2013-2014, All Rights Reserved.
//

#import "Coinsorter.h"

#define FRONT_URL @"https://"
#define PORT @":8443"
#define UUID_ACCOUNT @"UID_ACCOUNT"
#define PING_TIMEOUT 3

@implementation Coinsorter {
    
    NSMutableArray * deletePhotoId;
}


-(id) initWithWrapper:(CoreDataWrapper *)wrap {
  self = [super init];
  deletePhotoId = [NSMutableArray array];
  AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
  account = appDelegate.account;
  
  self.dataWrapper = wrap;
  
  uploadTask = appDelegate.uploadTask;
  
  return self;
}

- (NSMutableURLRequest *) getHTTPGetRequest: (NSString *) path {

  NSString *urlString = [NSString stringWithFormat:@"%@%@%@%@", FRONT_URL, account.currentIp,PORT, path];
  NSURL *url = [NSURL URLWithString:urlString];

  NSDictionary *headers = @{@"token" : account.token ,@"cid" : account.cid};
  
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init] ;
  [request setURL:url];
  [request setHTTPMethod:@"GET"];
  [request setAllHTTPHeaderFields:headers];
  [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
  [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
  
  NSLog(@"making get request to %@", urlString);
  
  return request;
}

- (NSMutableURLRequest *) getHTTPPostRequest: (NSString *) path {
  NSString *urlString = [NSString stringWithFormat:@"%@%@%@%@", FRONT_URL, account.currentIp,PORT, path];
  NSURL *url = [NSURL URLWithString:urlString];
  
  NSDictionary *headers = @{@"token" : account.token, @"cid" : account.cid};
  
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init] ;
  [request setURL:url];
  [request setHTTPMethod:@"POST"];
  [request setAllHTTPHeaderFields:headers];
  [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
  [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
  
  NSLog(@"making post request to %@", urlString);
  
  return request;
}


#pragma mark -
#pragma mark Auth APIs

- (void) getQRCode: (void (^) (NSString *base64Image))callback {
  NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
  NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
  
  NSMutableURLRequest *request = [self getHTTPGetRequest:@"/qr/getQR"];
  
  NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    if (error == nil && data != nil) {
      NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
      NSLog(@"%@", jsonData);
      NSString *base64 = [jsonData objectForKey:@"qr"];
      callback(base64);
    } else {
      NSLog(@"could not get qr code");
      callback(nil);
    }
  }];
  
  [dataTask resume];
}

- (void) pingServer:(void (^) (BOOL connected))connectCallback {
  NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
  NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];

  NSMutableURLRequest *request = [self getHTTPGetRequest:@"/getSID"];
  [request setTimeoutInterval:PING_TIMEOUT]; // set ping timeout
  
  NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    if (error == nil) {
      NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
      
      NSString *sid = [jsonData objectForKey:@"SID"];
      
      if (sid != nil && [sid isEqualToString:account.sid]) {
        // we are connected
        connectCallback(YES);
        NSLog(@"ping successful");
      }else {
        // no server id or it does not equal the server
        // we have connected to before
        connectCallback(NO);
        NSLog(@"local sid: %@ pinged sid: %@", account.sid, sid);
        NSLog(@"ping failed");
      }
    } else {
      NSLog(@"ping failed");
      
      connectCallback(NO);
    }
  }];
  
  [dataTask resume];
}

- (void) getSid:(NSString *)ip infoCallback:(void (^)(NSData *))infoCallback {
  NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
  NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
  
  NSString *urlString = [NSString stringWithFormat:@"%@%@%@%@", FRONT_URL, ip,PORT, @"/getSID"];
  NSURL *url = [NSURL URLWithString:urlString];
  
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init] ;
  [request setURL:url];
  [request setHTTPMethod:@"GET"];
  
  NSLog(@"making get request to %@", urlString);

  [request setTimeoutInterval:PING_TIMEOUT]; // set ping timeout
  
  NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    if (error == nil) {
      infoCallback(data);
    }else {
      infoCallback(nil);
    }
  }];
  
  [dataTask resume];
}


#pragma mark -
#pragma mark Storage APIs

-(void) updateStorage: (NSString*) queryAction stoUUID:(NSString *) uuid crontime: (NSString *) crontime infoCallback: (void (^) (NSDictionary *)) infoCallback{
    NSString *query = [NSString stringWithFormat:@"?action=%@&uuid=%@",queryAction,uuid];
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:defaultConfigObject delegate:self delegateQueue:nil];
    NSMutableURLRequest *request = [self getHTTPPostRequest:[NSString stringWithFormat:@"/storage/%@", query]];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSError *error;
    NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: crontime, @"crontime",nil];
    

    NSData *postData = [NSJSONSerialization dataWithJSONObject:mapData options:0 error:&error];
    [request setHTTPBody:postData];
    
    NSURLSessionDataTask *postDataTask = [defaultSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSError *jsonError;
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        NSLog(@"%@",jsonData);
        if (error == nil) {
            infoCallback(jsonData);
        }else {
            infoCallback(nil);
        }
    }];
    
    [postDataTask resume];
    
}

-(void) updateStorage: (NSString*) queryAction stoUUID:(NSString *) uuid infoCallback: (void (^) (NSDictionary *)) infoCallback{
    
    NSString *query = [NSString stringWithFormat:@"?action=%@&uuid=%@",queryAction,uuid];
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:defaultConfigObject delegate:self delegateQueue:nil];
    NSMutableURLRequest *request = [self getHTTPPostRequest:[NSString stringWithFormat:@"/storage/%@", query]];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSURLSessionDataTask *postDataTask = [defaultSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSError *jsonError;
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        NSLog(@"%@",jsonData);
        if (error == nil) {
            infoCallback(jsonData);
        }else {
            infoCallback(nil);
        }
    }];
    
    [postDataTask resume];
    
}

- (void) getStorages: (void (^) (NSMutableArray *storages)) callback {
    NSOperationQueue *background = [[NSOperationQueue alloc] init];
    
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:defaultConfigObject delegate:self delegateQueue:background];
    NSMutableURLRequest *request = [self getHTTPGetRequest:@"/storage"];
    
    //    ^(NSData *data, NSURLResponse *response, NSError *error)
    NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil) {
            NSError *jsonError;
            NSDictionary *respon = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            NSLog(@"%@",respon);
            NSArray *storageArr = [respon objectForKey:@"stores"];
            NSMutableArray *storages = [[NSMutableArray alloc] init];
            NSLog(@"%@",storageArr);
            for (NSDictionary *d in storageArr) {
                NSString *storageLabel = [d objectForKey:@"label"];
                NSString *uuid = [d objectForKey:@"uuid"];
                NSString *plugged_in = [d objectForKey:@"plugged_in"];
                NSString *mounted = [d objectForKey:@"mounted"];
                NSString *primary = [d objectForKey:@"primaryflag"];
                NSString *backup = [d objectForKey:@"backupflag"];
                NSNumber *freeSpace = [d objectForKey:@"free"];
                NSNumber *totalSpace = [d objectForKey:@"total"];
                
                CSStorage *newSto = [[CSStorage alloc] init];
                newSto.storageLabel = storageLabel;
                newSto.uuid = uuid;
                newSto.pluged_in = plugged_in;
                newSto.mounted = mounted;
                newSto.freeSpace = freeSpace;
                newSto.totalSpace = totalSpace;
                newSto.primary = primary;
                newSto.backup = backup;
                
                [storages addObject:newSto];
            }
            
            NSLog(@"sent %lu storages to callback", (unsigned long)storages.count);
            callback(storages);
        }
    }];
    
    [dataTask resume];
}

#pragma mark -
#pragma mark Device APIs
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
  
    // TODO: check to see if device update worked
    // by reading json response
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
        
        // harded coded way to remove browser device from devices
        if ([deviceName isEqualToString:@"Browser"]) {
          continue;
        }
        
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


#pragma mark -
#pragma mark photo/video meta APIs
// update the device information on server
- (void) updateMeta: (CSPhoto *) photo entity:(NSString *)entity value:(NSString *)value  {
    NSString* TextEscaped = [value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:defaultConfigObject delegate:self delegateQueue:nil];
    NSMutableURLRequest *request;

    request = [self getHTTPPostRequest:[NSString stringWithFormat:@"/update/photos/metadata"]];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSDictionary *updateContent = [[NSDictionary alloc] initWithObjectsAndKeys: photo.remoteID, @"photo_id", entity, @"entity", TextEscaped, @"value",nil];
    
    NSArray *updatearray = [NSArray arrayWithObject:updateContent];
    
    NSDictionary *updateDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:updatearray,@"updates",nil];
    NSLog(@"%@",updateDictionary);
    NSError *error;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:updateDictionary options:0 error:&error];
    [request setHTTPBody:postData];
    
    NSArray *objects =
    [NSArray arrayWithObjects:photo.deviceId, account.token, nil];
    
    // set headers
    NSArray *keys = [NSArray
                     arrayWithObjects:@"cid",@"token", nil];
    NSDictionary *headers =
    [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    [request setAllHTTPHeaderFields:headers];
    
    NSURLSessionDataTask *postDataTask = [defaultSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSError *jsonError;
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        NSLog(@"update meta stat %@",jsonData);
        // TODO: check to see if metadata update worked
        // by reading json response
    }];
    
    [postDataTask resume];
}

- (void) getMetaVideo: (NSMutableArray *)photos{
    NSOperationQueue *background = [[NSOperationQueue alloc] init];
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:defaultConfigObject delegate:self delegateQueue:background];
    NSMutableURLRequest *request;
    
    //for (CSPhoto *photo in photos) {
    NSString *query = [NSString stringWithFormat:@"?photo_id=0"];
    request = [self getHTTPGetRequest:[NSString stringWithFormat:@"/videos/metadata/%@",query]];
    
    
    NSArray *objects =
    [NSArray arrayWithObjects:account.cid, account.token, nil];
    
    // set headers
    NSArray *keys = [NSArray
                     arrayWithObjects:@"cid",@"token", nil];
    NSDictionary *headers =
    [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    [request setAllHTTPHeaderFields:headers];
    
    NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil) {
            NSError *jsonError;
            NSArray *photoArr = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            /*
             for (NSDictionary *p in photoArr) {
             NSString *tag = [p objectForKey:@"tag"];
             if (![photo.tag isEqualToString:tag]) {
             photo.tag = tag;
             
             [self.dataWrapper addUpdatePhoto:photo];
             }
             */
            //}
            for (NSDictionary *p in photoArr) {
                NSString *tag = [p objectForKey:@"tag"];
                NSString *photoid = [p objectForKey:@"_id"];
                
                [self.dataWrapper updatePhotoTag:tag photoId:photoid photo:nil];
            }
        }
    }];
    [dataTask resume];
    //}
}

- (void) getMetaPhoto: (NSMutableArray *)photos{
    NSOperationQueue *background = [[NSOperationQueue alloc] init];
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:defaultConfigObject delegate:self delegateQueue:background];
    NSMutableURLRequest *request;
    
    //for (CSPhoto *photo in photos) {
    NSString *query = [NSString stringWithFormat:@"?photo_id=0"];
    request = [self getHTTPGetRequest:[NSString stringWithFormat:@"/photos/metadata/%@",query]];


        NSArray *objects =
        [NSArray arrayWithObjects:account.cid, account.token, nil];
        
        // set headers
        NSArray *keys = [NSArray
                         arrayWithObjects:@"cid",@"token", nil];
        NSDictionary *headers =
        [NSDictionary dictionaryWithObjects:objects forKeys:keys];
        [request setAllHTTPHeaderFields:headers];
        
        NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error == nil) {
                NSError *jsonError;
                NSArray *photoArr = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                /*
                for (NSDictionary *p in photoArr) {
                    NSString *tag = [p objectForKey:@"tag"];
                    if (![photo.tag isEqualToString:tag]) {
                        photo.tag = tag;

                        [self.dataWrapper addUpdatePhoto:photo];
                    }
*/
                //}
                for (NSDictionary *p in photoArr) {
                    NSString *tag = [p objectForKey:@"tag"];
                    NSString *photoid = [p objectForKey:@"_id"];
                    
                    [self.dataWrapper updatePhotoTag:tag photoId:photoid photo:nil];
                }
            }
        }];
        [dataTask resume];
    //}
}

#pragma mark -
#pragma mark Password APIs

-(void) setPassword: (NSString *)oldPass newPass:(NSString *)newPass callback: (void (^) (NSDictionary *)) callback{

    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:defaultConfigObject delegate:self delegateQueue:nil];
    NSMutableURLRequest *request;

    request = [self getHTTPPostRequest:[NSString stringWithFormat:@"/settings/password"]];

    NSArray *objects =
    [NSArray arrayWithObjects:account.cid, account.token,oldPass,newPass, nil];
    NSLog(@"account cid %@",account.cid);
    // set headers
    NSArray *keys = [NSArray
                     arrayWithObjects:@"cid",@"token",@"password",@"newpassword", nil];
    NSDictionary *headers =
    [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    [request setAllHTTPHeaderFields:headers];
    
    NSURLSessionDataTask *postDataTask = [defaultSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSError *jsonError;
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];

        // TODO: check to see if metadata update worked
        // by reading json response
        callback(jsonData);
    }];
    
    [postDataTask resume];
    
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
    
  NSString *apnId = [defaults objectForKey:@"apnId"];
    
  //    NSDictionary *mapData = @{@"Device_Name": name, @"Manufacturer": manufacturer, @"Firmware": firmware_version};
  NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: deviceName, @"Device_Name", manufacturer, @"Manufacturer", firmware_version, @"Firmware",apnId, @"apnId",nil];
  
  return mapData;
}


#pragma mark -
#pragma mark Photo APIs
- (void) DeletePhoto:(NSMutableArray*) deletePhotos {
     NSLog(@"delete");
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:defaultConfigObject delegate:self delegateQueue:nil];
    NSMutableURLRequest *request = [self getHTTPPostRequest:[NSString stringWithFormat:@"/photos/delete"]];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSError *error;
    for (CSPhoto *p in deletePhotos) {
        NSString * photoId = p.remoteID;
        [deletePhotoId addObject:photoId];
    }
    
    NSDictionary *deleted = [[NSDictionary alloc] initWithObjectsAndKeys:deletePhotoId,@"restore", nil];
    NSData *postData = [NSJSONSerialization dataWithJSONObject:deleted options:0 error:&error];
    [request setHTTPBody:postData];
    NSLog(@"%@",postData);
    NSURLSessionDataTask *postDataTask = [defaultSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSError *jsonError;
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        NSLog(@"delete result %@ ", jsonData);
        // TODO: check to see if device update worked
        // by reading json response
    }];
    
    [postDataTask resume];
}

- (void) getPhotos:(int) lastId callback: (void (^) (NSMutableArray *photos)) callback {
  
  NSOperationQueue *background = [[NSOperationQueue alloc] init];
  
  NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
  NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:defaultConfigObject delegate:self delegateQueue:background];
  NSMutableURLRequest *request = [self getHTTPGetRequest:[NSString stringWithFormat:@"/photos/afterId?photo_id=%d&devNot=%@&limit=%d", lastId, @"1", DOWNLOAD_LIMIT]];
  
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
      
      NSString *latestRemote = @"-1";
      
      // parse the json
      for (NSDictionary *p in photoArr) {
        NSString *photoId = [p objectForKey:@"_id"];
        NSString *deviceId = [p objectForKey:@"device_id"];
        
        NSArray *photo_data = [p objectForKey:@"photo_data"];
        NSDictionary *latest = photo_data[0];
        
        NSString *thumbnail = [latest objectForKey:@"thumbnail"];
        
        CSPhoto *photo = [[CSPhoto alloc] init];
        
        // TODO : Parse the string so it acutally works
        
        NSString *dateString = [latest objectForKey:@"created_date"];
        
        // remove the milliseconds from date and append back the Z
        // This is only way I found to parse the string
        dateString = [dateString substringToIndex:19];
        dateString = [dateString stringByAppendingString:@"Z"];
        NSDateFormatter *dataFormatter = [[NSDateFormatter alloc] init];
        [dataFormatter setLocale:[NSLocale currentLocale]];
        [dataFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSDate *date = [dataFormatter dateFromString:dateString];
        photo.dateCreated = date;
        
        photo.deviceId = deviceId;
        photo.remoteID = photoId;
        
        latestRemote = photoId;
        
        photo.thumbOnServer = @"1";
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths objectAtIndex:0];
        NSString *filePath = [documentsPath stringByAppendingString:[NSString stringWithFormat:@"/%@.jpg", photoId]];
        
        NSString *fullPath = [[NSURL fileURLWithPath:filePath] absoluteString];
        
        photo.thumbURL = fullPath;
        photo.imageURL = fullPath;
        photo.fileName = [NSString stringWithFormat:@"%@.jpg", photoId];
        
        NSData *data = [self dataFromBase64EncodedString:thumbnail];
        [data writeToFile:filePath atomically:YES];
        
        NSLog(@"saving thumbnail to %@", filePath);
        
        [photos addObject:photo];
      }
      
      // call callback with photos we downloaded
      callback(photos);
      
      // recursivly download the next set of photos until we get no more back
      if (photoArr.count > 0) {
        NSLog(@"will download next set of photos");
        int nextLatest = [latestRemote intValue] + 1;
        [self getPhotos:nextLatest callback:callback];
      }
    }
  }];
  
  [dataTask resume];
}

//upload one full res photo to the server, this is called after thumbnail upload
- (void) uploadOnePhoto:(CSPhoto *)photo upCallback:(void (^)())upCallback {
    
    [uploadTask uploadOnePhoto:photo upCallback:upCallback];
}

// upload one thumbnail, this is called after each photo is taken
- (void) uploadOneThumb:(CSPhoto *)photo upCallback:(void (^)())upCallback {
    
    [uploadTask uploadOneThumb: photo upCallback:upCallback];
}

// the callback is what we want to do after each photo is uploaded
-(void) uploadPhotoThumb: (NSMutableArray *)photos upCallback:(void (^)())upCallback{
    
    [uploadTask uploadPhotoThumb:photos upCallback:upCallback];
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
      
      // create request g
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
          
          p.thumbOnServer = @"1";
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

#pragma mark -
#pragma mark Album APIs

-(NSString *) getKey:(NSString *) key value:(NSString *)value {
    
    if (value == nil) {
        return @"";
    } else {
            return [NSString stringWithFormat:@"%@=%@&",key,value];
    }
    
}

- (void) createAlbum: (CSAlbum *) album callback: (void (^) (NSString *album_id)) callback {
    CSDevice *localDevice = [self.dataWrapper getDevice:account.cid];
    NSString* nameTextEscaped = [album.entry.location.sublocation stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString* listTextEscaped = [album.entry.listing stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString* countryTextEscaped = [album.entry.location.country stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString* descriptionTextEscaped = [album.albumDescritpion stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *bedquery = [self getKey:@"bed" value:album.entry.bed];
    NSString *bathquery = [self getKey:@"bath" value:album.entry.bath];
    NSString *namequery = [self getKey:@"name" value:album.name];
    NSString *descriptionquery = [self getKey:@"description" value:descriptionTextEscaped];
    //NSString *coverquery = [self getKey:@"alb_cover" value:album.coverImage];
    NSString *buildingsqftquery = [self getKey:@"buildingsqft" value:[album.entry.buildingSqft stringValue]];
    NSString *landsqftquery = [self getKey:@"landsqft" value:[album.entry.landSqft stringValue]];
    NSString *listingquery = [self getKey:@"listing" value:listTextEscaped];
    NSString *mlsquery = [self getKey:@"mls" value:album.entry.mls];
    NSString *pricequery = [self getKey:@"price" value:[album.entry.price stringValue]];
    NSString *tagquery = [self getKey:@"tag" value:album.entry.tag];
    NSString *typequery = [self getKey:@"type" value:album.entry.type];
    NSString *yearbuiltquery = [self getKey:@"yearbuilt" value:album.entry.yearBuilt];
    
    
    NSString *query = [NSString stringWithFormat:@"?%@%@alb_latitude=%@&alb_longitude=%@&alb_altitude=%@&alb_sublocation=%@&alb_city=%@&alb_state=%@&alb_country=%@&%@%@%@%@%@%@%@%@%@%@",namequery,descriptionquery,album.entry.location.latitude,album.entry.location.longitude,album.entry.location.altitude,nameTextEscaped,album.entry.location.city,album.entry.location.province,countryTextEscaped,bathquery,bedquery,buildingsqftquery,landsqftquery,listingquery,mlsquery,pricequery,tagquery,typequery,yearbuiltquery];
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:defaultConfigObject delegate:self delegateQueue:nil];
    NSMutableURLRequest *request;
    

    request = [self getHTTPPostRequest:[NSString stringWithFormat:@"/albums/%@",query]];
    
    NSArray *objects =
    [NSArray arrayWithObjects:localDevice.remoteId, account.token, nil];
    
    // set headers
    NSArray *keys = [NSArray
                     arrayWithObjects:@"cid",@"token", nil];
    NSDictionary *headers =
    [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    [request setAllHTTPHeaderFields:headers];
    
    NSURLSessionDataTask *postDataTask = [defaultSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSError *jsonError;
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        NSLog(@"create album stat %@",jsonData);
        
        NSString * albumId = [[jsonData valueForKey:@"album_id"] stringValue];
        NSLog(@"%@",albumId);
        album.albumId = albumId;
        
        [self.dataWrapper updateAlbum:album];
        
        callback(albumId);
        // TODO: check to see if metadata update worked
        // by reading json response
    }];
    
    [postDataTask resume];
}

-(NSDictionary *) createUpdateArray:(NSString *)object key:(NSString *)key album: (CSAlbum *)album{
    if (!object) {
        object = @"";
    }
    NSDictionary *content = [[NSDictionary alloc] initWithObjectsAndKeys:album.albumId,@"photo_id",key,@"entity",object,@"value", nil];
    
    return content;
}

- (void) updateAlbum: (CSAlbum *) album{
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:defaultConfigObject delegate:self delegateQueue:nil];
    NSMutableURLRequest *request;
    
    request = [self getHTTPPostRequest:[NSString stringWithFormat:@"/update/albums/metadata"]];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    
    
   // NSString* typeTextEscaped = [album.entry.type stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    NSMutableArray *updatearray =[[NSMutableArray alloc] init];
    [updatearray addObject:[self createUpdateArray:album.entry.bed key:@"bed" album:album]];
    [updatearray addObject:[self createUpdateArray:album.entry.bath key:@"bath" album:album]];
    [updatearray addObject:[self createUpdateArray:album.name key:@"name" album:album]];
    [updatearray addObject:[self createUpdateArray:album.coverImage key:@"cover" album:album]];
    [updatearray addObject:[self createUpdateArray:album.albumDescritpion key:@"description" album:album]];
    [updatearray addObject:[self createUpdateArray:[album.entry.buildingSqft stringValue] key:@"buildingsqft" album:album]];
    [updatearray addObject:[self createUpdateArray:[album.entry.landSqft stringValue] key:@"landSqft" album:album]];
    [updatearray addObject:[self createUpdateArray:album.entry.listing key:@"listing" album:album]];
    [updatearray addObject:[self createUpdateArray:album.entry.mls key:@"mls" album:album]];
    [updatearray addObject:[self createUpdateArray:[album.entry.price stringValue] key:@"price" album:album]];
    [updatearray addObject:[self createUpdateArray:album.entry.tag key:@"tag" album:album]];
    [updatearray addObject:[self createUpdateArray:album.entry.type key:@"type" album:album]];
    [updatearray addObject:[self createUpdateArray:album.entry.yearBuilt key:@"yearbuilt" album:album]];
    [updatearray addObject:[self createUpdateArray:album.entry.location.city key:@"city" album:album]];
    [updatearray addObject:[self createUpdateArray:album.entry.location.sublocation key:@"sublocation" album:album]];
    [updatearray addObject:[self createUpdateArray:album.entry.location.province key:@"state" album:album]];
    [updatearray addObject:[self createUpdateArray:album.entry.location.countryCode key:@"countryCode" album:album]];
    [updatearray addObject:[self createUpdateArray:album.entry.location.country key:@"country" album:album]];
    [updatearray addObject:[self createUpdateArray:album.entry.location.longitude key:@"longitude" album:album]];
    [updatearray addObject:[self createUpdateArray:album.entry.location.latitude key:@"latitude" album:album]];
    [updatearray addObject:[self createUpdateArray:album.entry.location.altitude key:@"altitude" album:album]];
    [updatearray addObject:[self createUpdateArray:album.entry.location.longitude key:@"longitude" album:album]];
    NSDictionary *updateDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:updatearray,@"updates",nil];
    
    NSLog(@"%@",updateDictionary);
    NSError *error;
    
    NSData *postData = [NSJSONSerialization dataWithJSONObject:updateDictionary options:0 error:&error];
    [request setHTTPBody:postData];
    
    NSArray *objects =
    [NSArray arrayWithObjects:account.cid, account.token, nil];
    
    // set headers
    NSArray *keys = [NSArray
                     arrayWithObjects:@"cid",@"token", nil];
    NSDictionary *headers =
    [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    [request setAllHTTPHeaderFields:headers];
    
    NSURLSessionDataTask *postDataTask = [defaultSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSError *jsonError;
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        NSLog(@"update album stat %@",jsonData);
        
        //NSString * albumId = [[jsonData valueForKey:@"album_id"] stringValue];
        //NSLog(@"%@",albumId);
        //album.albumId = albumId;
        
        //[self.dataWrapper updateAlbum:album];
        
        // TODO: check to see if metadata update worked
        // by reading json response
    }];
    
    [postDataTask resume];
}


-(void) getAlbumInfo:(NSString *) album_id{
    
    NSOperationQueue *background = [[NSOperationQueue alloc] init];
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:defaultConfigObject delegate:self delegateQueue:background];
    NSMutableURLRequest *request;
    
    NSString *query = [NSString stringWithFormat:@"?album_id=%@",album_id];
    request = [self getHTTPGetRequest:[NSString stringWithFormat:@"/albums/%@",query]];
    
    
    NSArray *objects =
    [NSArray arrayWithObjects:account.cid, account.token, nil];
    
    // set headers
    NSArray *keys = [NSArray
                     arrayWithObjects:@"cid",@"token", nil];
    NSDictionary *headers =
    [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    [request setAllHTTPHeaderFields:headers];
    NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil) {
            NSError *jsonError;
            NSArray *albumArr = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            for (NSDictionary *p in albumArr) {
                NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
                f.numberStyle = NSNumberFormatterDecimalStyle;
                CSAlbum *album = [[CSAlbum alloc]init];
                CSEntry *entry = [[CSEntry alloc]init];
                CSLocation *location = [[CSLocation alloc]init];
                album.entry = entry;
                entry.location = location;
                album.entry.location.latitude = [p objectForKey:@"latitude"];
                album.entry.location.longitude = [p objectForKey:@"longitude"];
                album.entry.location.altitude = [p objectForKey:@"altitude"];
                album.entry.location.sublocation = [p objectForKey:@"sublocation"];
                album.entry.location.city = [p objectForKey:@"city"];
                album.entry.location.province = [p objectForKey:@"state"];
                album.entry.location.country = [p objectForKey:@"country"];
                album.name = [p objectForKey:@"name"];
                album.albumDescritpion = [p objectForKey:@"description"];
                album.coverImage = [p objectForKey:@"cover"];
                album.albumId = [p objectForKey:@"_id"];
                album.entry.bath = [p objectForKey:@"bath"];
                album.entry.bed = [p objectForKey:@"bed"];
                album.entry.buildingSqft = [f numberFromString:[p objectForKey:@"buildingsqft"]];
                album.entry.landSqft = [f numberFromString:[p objectForKey:@"landsqft"]];
                album.entry.mls = [p objectForKey:@"mls"];
                album.entry.price = [f numberFromString:[p objectForKey:@"price"]];
                album.entry.yearBuilt = [p objectForKey:@"yearbuilt"];
                album.entry.location.longitude = [p objectForKey:@"longitude"];
                album.entry.location.latitude = [p objectForKey:@"latitude"];
                album.entry.location.altitude = [p objectForKey:@"altitude"];
                album.entry.location.countryCode = [p objectForKey:@"countryCode"];
                NSString *currentVersion = [p objectForKey:@"version"];
                
                if (currentVersion >= album.version) {
                    album.version = currentVersion;
                    [self.dataWrapper updateAlbum:album];
                }
            }
        }
    }];
    NSLog(@"update album finished");
    [dataTask resume];
    
}
#pragma mark -
#pragma mark Get token APIs

- (void) getToken:(NSString *)ip pass:(NSString *)pass callback: (void (^) (NSDictionary *authData)) callback {
  NSString *urlString = [NSString stringWithFormat:@"%@%@%@%@", FRONT_URL, ip,PORT, @"/auth"];
  NSURL *url = [NSURL URLWithString:urlString];
  
  NSString *uid = [self uniqueAppId];
    NSLog(@"uid %@",uid);
  NSDictionary *headers = @{
                            @"password" : pass,
                            @"uid"  : uid
                            };
  
  [self getToken:url headerData:headers callback:callback];
}

- (void) getToken: (NSString *) ip fromTokenHash: (NSString *) hash_token toDevice: (NSString *) cid callback: (void (^) (NSDictionary *authData)) callback {
  NSString *urlString = [NSString stringWithFormat:@"%@%@%@%@", FRONT_URL, ip,PORT, @"/qr/authQR"];
  NSURL *url = [NSURL URLWithString:urlString];
  
  NSString *uid = [self uniqueAppId];
  NSLog(@"uid %@",uid);
  NSDictionary *headers = @{
                            @"hash_token" : hash_token,
                            @"sender_cid": cid,
                            @"uid"  : uid
                            };
  
  [self getToken:url headerData:headers callback:callback];
}

- (void) getToken: (NSURL *) url headerData: (NSDictionary *) headerData callback: (void (^) (NSDictionary *authData)) callback {
  NSError *error;
  
  NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
  NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
  
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init] ;
  [request setURL:url];
  [request setHTTPMethod:@"POST"];
  [request setAllHTTPHeaderFields:headerData];
  
  NSDictionary *mapData = [self getThisDeviceInformation];
  
  [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
  [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
  
  NSData *postData = [NSJSONSerialization dataWithJSONObject:mapData options:0 error:&error];
  [request setHTTPBody:postData];
  
  NSLog(@"making post request to %@", [url absoluteString]);
  
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
