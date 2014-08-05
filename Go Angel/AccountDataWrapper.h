//
//  SettingsDataWrapper.h
//  coinsorter-ios
//
//  Created by Jake Runzer on 7/16/14.
//  Copyright (c) 2014 Jake Runzer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AccountDataWrapper : NSObject

@property (nonatomic, strong) NSString *ip;
@property (nonatomic, strong) NSString *token;
@property (nonatomic, strong) NSString *cid;
@property (nonatomic, strong) NSString *sid;

- (void) saveSettings;
- (void) readSettings;

@end
