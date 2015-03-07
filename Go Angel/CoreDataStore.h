//
//  CoreDataStore.h
//  Go Arch
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import <Foundation/Foundation.h>

// first abstraction on top of the sqlite db
// manages getting the db context and handles the context
// notifications so we can use the db asynchronously
// we use this in CoreDataWrapper and it is very important for the
// non-threadsafeness of core data

@interface CoreDataStore : NSObject

+ (instancetype)defaultStore;

+ (NSManagedObjectContext *) mainQueueContext;
+ (NSManagedObjectContext *) privateQueueContext;

@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;

@property (nonatomic, strong) NSManagedObjectContext *mainQueueContext;
@property (nonatomic, strong) NSManagedObjectContext *privateQueueContext;

@end
