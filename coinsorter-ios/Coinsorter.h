//
//  Coinsorter.h
//  coinsorter-ios
//
//  Created by Jake Runzer on 7/14/14.
//  Copyright (c) 2014 Jake Runzer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSDevice.h"
#import "AccountDataWrapper.h"
#import "AppDelegate.h"
#import "SSKeychain.h"


typedef void (^CompletionHandlerType)();

@interface Coinsorter : NSObject <NSURLSessionDelegate> {
    AccountDataWrapper *account;
}

- (void) getDevices: (void (^) (NSMutableArray *devices)) callback;
- (void) getToken: (NSString *) ip name: (NSString *) name pass: (NSString *) pass callback: (void (^) (NSDictionary *authData)) callback;

@end
