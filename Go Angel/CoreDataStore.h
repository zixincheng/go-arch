//
//  CoreDataStore.h
//  Go Angel
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import <Foundation/Foundation.h>

@interface CoreDataStore : NSObject

+ (instancetype)defaultStore;

+ (NSManagedObjectContext *) mainQueueContext;
+ (NSManagedObjectContext *) privateQueueContext;

@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;

@property (nonatomic, strong) NSManagedObjectContext *mainQueueContext;
@property (nonatomic, strong) NSManagedObjectContext *privateQueueContext;

@end
