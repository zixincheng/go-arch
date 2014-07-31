//
//  LocalPhotos.h
//  Coinsorter
//
//  Created by Jake Runzer on 7/31/14.
//  Copyright (c) 2014 acdGO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "AppDelegate.h"
#import "CoreDataWrapper.h"
#import "AccountDataWrapper.h"

@interface LocalLibrary : NSObject {
  AccountDataWrapper *account;
  ALAssetsLibrary *assetLibrary;
}

@property (nonatomic, strong) CoreDataWrapper *dataWrapper;
@property (nonatomic, strong) NSMutableArray *allowedAlbums;

- (void) loadLocalImages: (BOOL) parseAll;
- (void) loadAllowedAlbums;
- (void) registerForNotifications;
- (void) unRegisterForNotifications;

@end
