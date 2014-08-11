//
//  Server.h
//  Go Angel
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import <Foundation/Foundation.h>

@interface Server : NSObject

@property (nonatomic, strong) NSString *ip;
@property (nonatomic, strong) NSString *serverId;
@property (nonatomic, strong) NSString *hostname;

@end
