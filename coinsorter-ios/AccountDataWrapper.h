//
//  SettingsDataWrapper.h
//  coinsorter-ios
//
//  Created by Jake Runzer on 7/16/14.
//  Copyright (c) 2014 Jake Runzer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AccountDataWrapper : NSObject

@property (strong) NSString *ip;
@property (strong) NSString *token;
@property (strong) NSString *cid;

- (void) saveSettings;
- (void) readSettings;

@end
