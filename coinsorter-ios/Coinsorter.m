//
//  Coinsorter.m
//  coinsorter-ios
//
//  Created by Jake Runzer on 7/14/14.
//  Copyright (c) 2014 Jake Runzer. All rights reserved.
//

#import "Coinsorter.h"

#define TOKEN @"7c0d1c6437a01790ff4eebab66051a2502a60696f2d63de85c9d7a3da251ca69"
#define ROOT_URL @"https://192.168.120.71:443"

@implementation Coinsorter

- (NSMutableURLRequest *) getHTTPGetRequest: (NSString *) path {
    NSString *urlString = [NSString stringWithFormat:@"%@%@", ROOT_URL, path];
    //    NSString *urlString = @"https://api.twitter.com/1.1/statuses/mentions_timeline.json";
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSDictionary *headers = @{@"token" : TOKEN};
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init] ;
    [request setURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"GET"];
    [request setAllHTTPHeaderFields:headers];
    
    NSLog(@"making get request to %@", urlString);
    
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

# warning removing using self-signed certs in production
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler{
    
    NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
    completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
}

@end
