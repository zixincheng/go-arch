//
//  coreDataWrapper.h
//  Go Arch
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "CoreDataStore.h"
#import "CSDevice.h"
#import "CSPhoto.h"
#import "CSLocation.h"
#import "CSLocationMeta.h"
#import "ActivityHistory.h"

// the wrapper to manage inserting our objects into the db
// simple abstraction where we send our objects, and
// this class reads them, and puts into db appropriatly

@interface CoreDataWrapper : NSObject

- (BOOL) addPhoto: (CSPhoto *) photo;
- (void) addDevice: (CSDevice *) device;
- (void) addUpdatePhoto: (CSPhoto *) photo;
- (void) addUpdateDevice: (CSDevice *) device;
- (void) addUpdateLog:(ActivityHistory *)log;
- (NSMutableArray *) getAllPhotos;
- (NSMutableArray *) getAllDevices;
- (NSMutableArray *) getPhotosWithLocation: (NSString *) deviceId location:(CSLocation *)location;
- (CSPhoto *)getCoverPhoto: (NSString *) deviceId location:(CSLocation *)location;
- (NSMutableArray *) getPhotos: (NSString *) deviceId;
- (NSMutableArray *) getPhotosToUpload;
- (NSMutableArray *) getFullSizePhotosToUpload;
- (NSMutableArray *) getLogs;
- (NSMutableArray *) getLocations;
- (int) getCountUnUploaded;
- (int) getCountUploaded:(NSString *) deviceId;
- (int) getFullImageCountUnUploaded;
- (int) getFullImageCountUploaded:(NSString *) deviceId;
- (CSDevice *) getDevice: (NSString *) cid;
- (NSString *) getLatestId;
- (NSString *) getCurrentPhotoOnServerVaule: (NSString *) deviceId CurrentIndex:(int)index;
- (void) deletePhotos:(CSPhoto *) photo;
- (void) updateLocation:(CSLocation *)location locationmeta:(CSLocationMeta *)locationMeta;
- (void) addLocation:(CSLocation *)location locationmeta :(CSLocationMeta *) locationMeta;
- (void) deleteLocation:(CSLocation *) location;
- (NSMutableArray *) searchLocation: (NSString *) location;
-(void) updatePhotoTag: (NSString *) tag photoId: (NSString *) photoid photo: (CSPhoto *) photo;
- (CSPhoto *)getPhoto: (NSString *) imageURL;
@end
