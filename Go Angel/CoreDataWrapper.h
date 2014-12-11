//
//  coreDataWrapper.h
//  Go Angel
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "CoreDataStore.h"
#import "CSDevice.h"
#import "CSPhoto.h"

// the wrapper to manage inserting our objects into the db
// simple abstraction where we send our objects, and
// this class reads them, and puts into db appropriatly

@interface CoreDataWrapper : NSObject

- (BOOL) addPhoto: (CSPhoto *) photo;
- (void) addDevice: (CSDevice *) device;
- (void) addUpdatePhoto: (CSPhoto *) photo;
- (void) addUpdateDevice: (CSDevice *) device;
- (NSMutableArray *) getAllPhotos;
- (NSMutableArray *) getAllDevices;
- (NSMutableArray *) getPhotos: (NSString *) deviceId;
- (NSMutableArray *) getPhotosToUpload;
- (int) getCountUnUploaded;
- (int) getCountUploaded:(NSString *) deviceId;
- (CSDevice *) getDevice: (NSString *) cid;
- (NSString *) getLatestId;

@end
