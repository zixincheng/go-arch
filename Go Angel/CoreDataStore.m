//
//  CoreDataStore.m
//  Go Arch
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.

#import "CoreDataStore.h"

@implementation CoreDataStore

+ (instancetype)defaultStore {
  static CoreDataStore *_defaultStore = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _defaultStore = [self new];
  });
  
  return _defaultStore;
}

#pragma mark - singleton access

+ (NSManagedObjectContext *) mainQueueContext {
  return [[self defaultStore] mainQueueContext];
}

+ (NSManagedObjectContext *) privateQueueContext {
  return [[self defaultStore] privateQueueContext];
}

#pragma mark - lifecycle

- (id) init {
  self = [super init];
  if (self) {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidSavePrivateQueueContext:) name:NSManagedObjectContextDidSaveNotification object:[self privateQueueContext]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidSaveMainQueueContext:) name:NSManagedObjectContextDidSaveNotification object:[self mainQueueContext]];
  }
  return self;
}

- (void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - notifications

- (void) contextDidSavePrivateQueueContext:(NSNotification *) notification {
  @synchronized (self) {
    [self.mainQueueContext performBlock:^{
      [self.privateQueueContext mergeChangesFromContextDidSaveNotification:notification];
    }];
  }
}

- (void) contextDidSaveMainQueueContext:(NSNotification *) notification {
  @synchronized (self) {
    [self.privateQueueContext performBlock:^{
      [self.privateQueueContext mergeChangesFromContextDidSaveNotification:notification];
    }];
  }
}

#pragma mark - getters

- (NSManagedObjectContext *) mainQueueContext {
  if (!_mainQueueContext) {
    _mainQueueContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    _mainQueueContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
  }
  
  return _mainQueueContext;
}

- (NSManagedObjectContext *) privateQueueContext {
  if (!_privateQueueContext) {
    _privateQueueContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    _privateQueueContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
  }
  
  return _privateQueueContext;
}

#pragma mark - stack setup

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
  if (_managedObjectModel != nil) {
    return _managedObjectModel;
  }
  NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
  _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
  return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
  if (_persistentStoreCoordinator != nil) {
    return _persistentStoreCoordinator;
  }
  
  // This code prevents multiple threads trying to get
  // the persistent store coordinator at the same time
  
  // It makes it so that all threads wanting access to this
  // will be ordered when they come in
  if (![NSThread currentThread].isMainThread) {
    dispatch_sync(dispatch_get_main_queue(), ^{
      (void)[self persistentStoreCoordinator];
    });
    return _persistentStoreCoordinator;
  }
  
  NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Model.sqlite"];
  
  NSError *error = nil;
  _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
  NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption : @(YES),
                               NSInferMappingModelAutomaticallyOption : @(YES) };
    
  if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    abort();
  }
  return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
  return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
