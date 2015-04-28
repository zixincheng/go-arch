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
#import "CSAlbum.h"
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
- (NSMutableArray *) getPhotosWithAlbum: (NSString *) deviceId album:(CSAlbum *)album;
- (CSPhoto *)getCoverPhoto: (NSString *) deviceId album:(CSAlbum *)album;
- (NSMutableArray *) getPhotos: (NSString *) deviceId;
- (NSMutableArray *) getPhotosToUpload;
- (NSMutableArray *) getFullSizePhotosToUpload;
- (NSMutableArray *) getLogs;
- (NSMutableArray *) getAllAlbums;
- (int) getCountUnUploaded;
- (int) getCountUploaded:(NSString *) deviceId;
- (int) getFullImageCountUnUploaded;
- (int) getFullImageCountUploaded:(NSString *) deviceId;
- (CSDevice *) getDevice: (NSString *) cid;
- (NSString *) getLatestId;
- (NSString *) getCurrentPhotoOnServerVaule: (NSString *) deviceId CurrentIndex:(int)index;
- (void) deletePhotos:(CSPhoto *) photo;
- (void) updateAlbum:(CSAlbum *)album;
- (void) addAlbum:(CSAlbum *)album;
- (void) deleteAlbum:(CSAlbum *) album;
- (NSMutableArray *) searchLocation: (NSString *) location;
-(void) updatePhotoTag: (NSString *) tag photoId: (NSString *) photoid photo: (CSPhoto *) photo;
- (CSPhoto *)getPhoto: (NSString *) imageURL;
-(NSMutableArray *)filterLocations: (NSMutableDictionary *)filterInfo;
- (NSMutableArray *) getAlbumsToUpload;
- (NSMutableArray *)getThumbsToUploadWithAlbum: (NSString *) deviceId album:(CSAlbum *)album;
- (NSMutableArray *) getAlbumsAlreadyUploaded;
- (CSAlbum *) getSingleAlbum:(CSAlbum *)album;
- (BOOL) addPhotoArray:(NSArray *)photoArray;
@end
