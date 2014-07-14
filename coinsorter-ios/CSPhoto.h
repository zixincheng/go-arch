//
//  CSPhoto.h
//  coinsorter-ios
//
//  Created by Jake Runzer on 7/13/14.
//  Copyright (c) 2014 Jake Runzer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MWPhoto.h"

@interface CSPhoto : NSObject

@property (strong) MWPhoto *photoObject;
@property (strong) MWPhoto *thumbObject;
@property (strong) NSString *deviceId;
@property (strong) NSURL *imageURL;

@end
