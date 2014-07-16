//
//  CSDevice.h
//  coinsorter-ios
//
//  Created by Jake Runzer on 7/15/14.
//  Copyright (c) 2014 Jake Runzer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CSDevice : NSObject

@property (nonatomic, strong) NSString *remoteId;
@property (nonatomic, strong) NSString *coreId;
@property (nonatomic, strong) NSString *deviceName;

@end
