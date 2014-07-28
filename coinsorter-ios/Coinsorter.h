//
//  Coinsorter.h
//  coinsorter-ios
//
//  Created by Jake Runzer on 7/14/14.
//  Copyright (c) 2014 Jake Runzer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSDevice.h"
#import "CSPhoto.h"
#import "AccountDataWrapper.h"
#import "CoreDataWrapper.h"
#import "AppDelegate.h"
#import "SSKeychain.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>

@interface Coinsorter : NSObject <NSURLSessionDelegate> {
  AccountDataWrapper *account;
}

- (void) getDevices: (void (^) (NSMutableArray *devices)) callback;
- (void) getToken: (NSString *) ip pass: (NSString *) pass callback: (void (^) (NSDictionary *authData)) callback;
- (void) getPhotos: (NSString *) lastId callback: (void (^) (NSMutableArray *devices)) callback;
- (void) uploadPhotos: (NSMutableArray *) photos;
- (void) updateDevice;

// need reference to a data wrapper so we can change photo state when we download, upload, etc.
@property CoreDataWrapper *dataWrapper;

@end
