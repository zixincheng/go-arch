//
//  CSPhoto.h
//  Go Angel
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "CSDevice.h"

// simple photo object class

@interface CSPhoto : NSObject

@property (nonatomic, strong) NSString *deviceId;
@property (nonatomic, strong) NSString *imageURL;
@property (nonatomic, strong) NSString *thumbURL;
@property (nonatomic, strong) NSString *remoteID;
@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSString *onServer;
@property (nonatomic, strong) NSDate *dateCreated;
@property (nonatomic, strong) NSDate *dateUploaded;
@property (nonatomic, strong) NSString *isVideo;
@property (nonatomic, strong) NSString *tag;
@property (nonatomic, strong) NSString *unit;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *cover;

// the background upload task id.
// if this is greater than -1, it means the photo is currently being uploaded
@property (nonatomic) unsigned long taskIdentifier;

- (void) onServerSet: (BOOL)on;

@end
