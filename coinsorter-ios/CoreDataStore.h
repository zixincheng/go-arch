//
//  CoreDataStore.h
//  Coinsorter
//
//  Created by Jake Runzer on 7/23/14.
//  Copyright (c) 2014 ACDSystems. All rights reserved.
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
