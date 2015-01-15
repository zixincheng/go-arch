//
//  Constants.h
//  Go Angel
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

// this class is globally imported
// any constants that are used in more than 1 file
// should go here
// eg. xml keys for user settings

#import <Foundation/Foundation.h>

// api
#define DOWNLOAD_LIMIT 25

// plist file for server info
#define SETTINGS @"Account"

// user defaults keys
#define DEVICE_NAME @"deviceName"
#define ALBUMS @"albums"
#define DATE @"date"

// user defaults keys for groups
#define SELECTED    @"selected"
#define NAME        @"name"
#define ALBUMS      @"albums"
#define ALL_PHOTOS  @"allPhotos"
#define URL_KEY     @"url"
#define EST_COUNT   @"est_count"
#define GPS_META    @"gpsMeta"
#define DOWN_REMOTE @"downRemote"
#define SAVE_INTO_ALBUM @"saveInAlbum"

// core data entites
#define PHOTO @"Photo"
#define DEVICE @"Device"
#define LOG @"Log"

// photo entity attributes
#define DATE_CREATED @"dateCreated"
#define DATE_UPLOADED @"dateUploaded"
#define DEVICE_ID @"deviceId"
#define IMAGE_URL @"imageURL"
#define REMOTE_ID @"remoteId"
#define REMOTE_PATH @"remotePath"
#define THUMB_URL @"thumbURL"
#define ON_SERVER @"onServer"
#define FILE_NAME @"fileName"

// log entity attributes
#define TIME_UPDATE @"timeUpdate"
#define ACTIVITY_LOG @"activityLog"

// camera
#define SAVE_PHOTO_ALBUM @"Go Angel"

// location
#define CURR_LOC_LAT      @"currentLocationLongitude"
#define CURR_LOC_LONG      @"currentLocationLatitude"
#define CURR_LOC_NAME      @"currentLocationName"
#define CURR_LOC_UNIT      @"currentLocationUnit"
#define CURR_LOC_CITY      @"currentLocationCity"
#define CURR_LOC_PROV      @"currentLocationProv"
#define CURR_LOC_COUNTRY   @"currentLocationCountry"
#define CURR_LOC_COUN_CODE @"currentLocationCountryCode"

#define CURR_LOC_ON   @"currentLocationOn"

// device entitiy attributes
// same as above ones

//Custom Carema view
//frame and size
#define DEVICE_BOUNDS    [[UIScreen mainScreen] bounds]
#define DEVICE_SIZE      [[UIScreen mainScreen] bounds].size

#define APP_FRAME        [[UIScreen mainScreen] applicationFrame]
#define APP_SIZE         [[UIScreen mainScreen] applicationFrame].size

#define SELF_CON_FRAME      self.view.frame
#define SELF_CON_SIZE       self.view.frame.size
#define SELF_VIEW_FRAME     self.frame
#define SELF_VIEW_SIZE      self.frame.size

@interface Constants : NSObject

@end
