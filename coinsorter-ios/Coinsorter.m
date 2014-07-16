//
//  Coinsorter.m
//  coinsorter-ios
//
//  Created by Jake Runzer on 7/14/14.
//  Copyright (c) 2014 Jake Runzer. All rights reserved.
//

#import "Coinsorter.h"

#define TOKEN @"7c0d1c6437a01790ff4eebab66051a2502a60696f2d63de85c9d7a3da251ca69"
#define ROOT_URL @"https://192.168.0.19:443"

@implementation Coinsorter

- (NSMutableURLRequest *) getHTTPGetRequest: (NSString *) path {
    NSString *urlString = [NSString stringWithFormat:@"%@%@", ROOT_URL, path];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSDictionary *headers = @{@"token" : TOKEN};
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init] ;
    [request setURL:url];
    [request setHTTPMethod:@"GET"];
    [request setAllHTTPHeaderFields:headers];
    
    NSLog(@"making get request to %@", urlString);
    
    return request;
}

- (NSMutableURLRequest *) getHTTPPostRequest: (NSString *) path {
    NSString *urlString = [NSString stringWithFormat:@"%@%@", ROOT_URL, path];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSDictionary *headers = @{@"token" : TOKEN};
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init] ;
    [request setURL:url];
    [request setHTTPMethod:@"POST"];
    [request setAllHTTPHeaderFields:headers];
    
    NSLog(@"making post request to %@", urlString);
    
    return request;
}

- (void) getDevices: (void (^) (NSMutableArray *devices)) callback {
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:defaultConfigObject delegate:self delegateQueue:[NSOperationQueue mainQueue]];
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
            
            callback(devices);
        }
    }];
    
    [dataTask resume];
}

- (void) getToken:(NSString *)ip pass:(NSString *)pass callback: (void (^) (NSDictionary *authData)) callback {
    NSString *urlString = [NSString stringWithFormat:@"%@%@", ROOT_URL, @"/auth"];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSError *error;
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    
    NSString *uid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    NSDictionary *headers = @{
                              @"pass" : pass,
                              @"uid"  : uid
                              };
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init] ;
    [request setURL:url];
    [request setHTTPMethod:@"POST"];
    [request setAllHTTPHeaderFields:headers];
    
    NSString *name = [[UIDevice currentDevice] name];
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

# warning removing using self-signed certs in production
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler{
    
    NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
    completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
}

@end
