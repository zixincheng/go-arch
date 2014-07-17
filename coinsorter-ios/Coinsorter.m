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

@implementation Coinsorter

- (id) init {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    account = appDelegate.account;
    
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

- (void) getDevices: (void (^) (NSMutableArray *devices)) callback {
    NSOperationQueue *background = [[NSOperationQueue alloc] init];
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:defaultConfigObject delegate:self delegateQueue:background];
    NSMutableURLRequest *request = [self getHTTPGetRequest:@"/devices"];
    
    NSAssert(![NSThread isMainThread], @"MAIN THREAD WHEN USING DB!!!");
    
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
            
            callback(devices);
        }
    }];
    
    [dataTask resume];
}

- (void) getToken:(NSString *)ip name: (NSString *) name pass:(NSString *)pass callback: (void (^) (NSDictionary *authData)) callback {
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
    
    NSString *manufacturer = @"Apple";
    NSString *firmware_version = [[UIDevice currentDevice] systemVersion];
    
//    NSDictionary *mapData = @{@"Device_Name": name, @"Manufacturer": manufacturer, @"Firmware": firmware_version};
    NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: name, @"Device_Name", manufacturer, @"Manufacturer", firmware_version, @"Firmware", nil];
    
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
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler{
    
    NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
    completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
}

@end
