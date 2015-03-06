//
//  SettingsDataWrapper.h
//  Go Arch
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import <Foundation/Foundation.h>

// simple class which manages the account plist file
// the file contains information about the current server we are connected to
// a lot simpler then storing this info in the database, especially cause its
// only a few string values

@interface AccountDataWrapper : NSObject

@property (nonatomic, strong) NSString *currentIp;
@property (nonatomic, strong) NSString *localIp;
@property (nonatomic, strong) NSString *externalIp;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *token;
@property (nonatomic, strong) NSString *cid;
@property (nonatomic, strong) NSString *sid;

- (void) saveSettings;
- (void) readSettings;

@end
