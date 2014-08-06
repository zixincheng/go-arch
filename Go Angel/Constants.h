//
//  Constants.h
//  Go Angel
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import <Foundation/Foundation.h>

// plist file for server info
#define SETTINGS @"Account"

// user defaults keys
#define DEVICE_NAME @"deviceName"
#define ALBUMS @"albums"
#define DATE @"date"

// user defaults keys for groups
#define SELECTED @"selected"
#define NAME     @"name"
#define ALBUMS   @"albums"
#define URL_KEY      @"url"

// core data entites
#define PHOTO @"Photo"
#define DEVICE @"Device"

// photo entity attributes
#define DATE_CREATED @"dateCreated"
#define DEVICE_ID @"deviceId"
#define IMAGE_URL @"imageURL"
#define REMOTE_ID @"remoteId"
#define REMOTE_PATH @"remotePath"
#define THUMB_URL @"thumbURL"
#define ON_SERVER @"onServer"

// device entitiy attributes
// same as above ones

@interface Constants : NSObject

@end
