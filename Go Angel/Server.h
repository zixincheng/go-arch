//
//  Server.h
//  Go Arch
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import <Foundation/Foundation.h>


// server object class

@interface Server : NSObject

@property (nonatomic, strong) NSString *currentIp;
@property (nonatomic, strong) NSString *localIp;
@property (nonatomic, strong) NSString *externalIp;
@property (nonatomic, strong) NSString *serverId;
@property (nonatomic, strong) NSString *hostname;

@end
