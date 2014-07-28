//
//  CSPhoto.h
//  coinsorter-ios
//
//  Created by Jake Runzer on 7/13/14.
//  Copyright (c) 2014 Jake Runzer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MWPhoto.h"
#import "CSDevice.h"

@interface CSPhoto : NSObject

@property (nonatomic, strong) MWPhoto *photoObject;
@property (nonatomic, strong) MWPhoto *thumbObject;
@property (nonatomic, strong) NSString *deviceId;
@property (nonatomic, strong) NSString *imageURL;
@property (nonatomic, strong) NSString *thumbURL;
@property (nonatomic, strong) NSString *remoteID;
@property (nonatomic, strong) NSString *onServer;
@property (nonatomic, strong) NSDate *dateCreated;
@property (nonatomic, strong) NSDate *dateUploaded;

@end
