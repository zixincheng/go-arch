//
//  SettingsDataWrapper.m
//  Go Arch
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import "AccountDataWrapper.h"

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
  
  self.currentIp = [temp objectForKey:@"currentIp"];
  self.localIp = [temp objectForKey:@"localIp"];
  self.externalIp = [temp objectForKey:@"externalIp"];
  self.name = [temp objectForKey:@"name"];
  self.cid = [temp objectForKey:@"cid"];
  self.token = [temp objectForKey:@"token"];
  self.sid = [temp objectForKey:@"sid"];
}

- (void) saveSettings {
  NSArray *values = [NSArray arrayWithObjects:self.currentIp,self.localIp, self.externalIp, self.cid, self.token, self.sid,self.name, nil];
  NSArray *keys   = [NSArray arrayWithObjects:@"currentIp", @"localIp", @"externalIp", @"cid", @"token", @"sid",@"name", nil];
  
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
