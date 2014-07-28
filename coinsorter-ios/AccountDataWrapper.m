//
//  SettingsDataWrapper.m
//  coinsorter-ios
//
//  Created by Jake Runzer on 7/16/14.
//  Copyright (c) 2014 Jake Runzer. All rights reserved.
//

#import "AccountDataWrapper.h"

#define SETTINGS @"Account"

@implementation AccountDataWrapper

- (void) readSettings {
  NSString *errorDesc = nil;
  NSPropertyListFormat format;
  NSString *plistPath;
  NSString *rootPath =
  [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
  plistPath = [rootPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", SETTINGS]];
  if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
    plistPath = [[NSBundle mainBundle] pathForResource:SETTINGS ofType:@"plist"];
  }
  NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
  NSDictionary *temp = (NSDictionary *)[NSPropertyListSerialization
                                        propertyListFromData:plistXML mutabilityOption:NSPropertyListMutableContainersAndLeaves format:&format errorDescription:&errorDesc];
  if (!temp) {
    NSLog(@"error reading plist: %@, format: %d", errorDesc, format);
  }
  
  self.ip = [temp objectForKey:@"ip"];
  self.cid = [temp objectForKey:@"cid"];
  self.token = [temp objectForKey:@"token"];
}

- (void) saveSettings {
  NSArray *values = [NSArray arrayWithObjects:self.ip, self.cid, self.token, nil];
  NSArray *keys   = [NSArray arrayWithObjects:@"ip", @"cid", @"token", nil];
  
  NSString *error;
  NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
  NSString *plistPath = [rootPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", SETTINGS]];
  NSDictionary *plistDict = [NSDictionary dictionaryWithObjects:values forKeys:keys];
  NSData *plistData = [NSPropertyListSerialization dataFromPropertyList:plistDict format:NSPropertyListXMLFormat_v1_0 errorDescription:&error];
  
  if (plistData) {
    [plistData writeToFile:plistPath atomically:YES];
  } else {
    NSLog(error);
  }
}

@end
