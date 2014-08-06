//
//  SettingsDataWrapper.h
//  Go Angel
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
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
