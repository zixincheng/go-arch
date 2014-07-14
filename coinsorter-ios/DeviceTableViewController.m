//
//  Menu.m
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 21/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import "DeviceTableViewController.h"
#import "SDImageCache.h"
#import "MWCommon.h"

@implementation DeviceTableViewController

#pragma mark -
#pragma mark Initialization

- (id)initWithStyle:(UITableViewStyle)style {
    if ((self = [super initWithStyle:style])) {
        if (self) {
            // custome config (doesn't work)
        }
        
    }
    return self;
}

- (void)segmentChange {
    [self.tableView reloadData];
}


#pragma mark -
#pragma mark View

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:nil action:nil];
    
    self.devices = [[NSMutableArray alloc] init];
    
    // load the images from iphone photo library
    [self loadAssets];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //    self.navigationController.navigationBar.barTintColor = [UIColor greenColor];
    //    self.navigationController.navigationBar.translucent = NO;
    //    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationNone;
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = 1;
    //    @synchronized(_assets) {
    //        if (_assets.count) rows++;
    //    }
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	// Create
    static NSString *CellIdentifier = @"DevicePrototypeCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // Configure
	switch (indexPath.row) {
		case 0: {
            cell.textLabel.text = @"Jake's Local Photos";
            break;
        }
		default: break;
	}
    return cell;
	
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
	// Browser
    BOOL displayActionButton = YES;
    BOOL displaySelectionButtons = NO;
    BOOL displayNavArrows = YES;
    BOOL enableGrid = YES;
    BOOL startOnGrid = YES;
	
    //    // set the photos list to localPhotos for now
    //    @synchronized(localPhotos) {
    //        self.photos = localPhotos;
    //    }
    
	// Create browser
	MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    browser.displayActionButton = displayActionButton;
    browser.displayNavArrows = displayNavArrows;
    browser.displaySelectionButtons = displaySelectionButtons;
    browser.alwaysShowControls = displaySelectionButtons;
    browser.zoomPhotosToFill = YES;
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0
    browser.wantsFullScreenLayout = YES;
#endif
    browser.enableGrid = enableGrid;
    browser.startOnGrid = startOnGrid;
    browser.enableSwipeToDismiss = YES;
    [browser setCurrentPhotoIndex:0];

    // TODO: get this running in another thread
    // and then update browser data in main thread
    @synchronized(self.photos) {
        self.photos = [self getPhotos:@"1"];
        [browser reloadData];
    }
    
    // Reset selections
    if (displaySelectionButtons) {
        _selections = [NSMutableArray new];
        for (int i = 0; i < self.photos.count; i++) {
            [_selections addObject:[NSNumber numberWithBool:NO]];
        }
    }
    
    // Show
    [self.navigationController pushViewController:browser animated:YES];
    // Release
	
	// Deselect
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return _photos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < _photos.count) {
        CSPhoto *p = [_photos objectAtIndex:index];
        return p.photoObject;
    }
    return nil;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index {
    if (index < _photos.count) {
        CSPhoto *p = [_photos objectAtIndex:index];
        return p.thumbObject;
    }
    return nil;
}

//- (MWCaptionView *)photoBrowser:(MWPhotoBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index {
//    MWPhoto *photo = [self.photos objectAtIndex:index];
//    MWCaptionView *captionView = [[MWCaptionView alloc] initWithPhoto:photo];
//    return [captionView autorelease];
//}

//- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser actionButtonPressedForPhotoAtIndex:(NSUInteger)index {
//    NSLog(@"ACTION!");
//}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index {
    NSLog(@"Did start viewing photo at index %lu", (unsigned long)index);
}

- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser isPhotoSelectedAtIndex:(NSUInteger)index {
    return [[_selections objectAtIndex:index] boolValue];
}

//- (NSString *)photoBrowser:(MWPhotoBrowser *)photoBrowser titleForPhotoAtIndex:(NSUInteger)index {
//    return [NSString stringWithFormat:@"Photo %lu", (unsigned long)index+1];
//}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index selectedChanged:(BOOL)selected {
    [_selections replaceObjectAtIndex:index withObject:[NSNumber numberWithBool:selected]];
    NSLog(@"Photo at index %lu selected %@", (unsigned long)index, selected ? @"YES" : @"NO");
}

- (void)photoBrowserDidFinishModalPresentation:(MWPhotoBrowser *)photoBrowser {
    // If we subscribe to this method we must dismiss the view controller ourselves
    NSLog(@"Did finish modal presentation");
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Load Assets

- (void)loadAssets {
    
    _assetLibrary = [[ALAssetsLibrary alloc] init];
    NSString *localDeviceId = @"1";
    
    // Run in the background as it takes a while to get all assets from the library
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *locals = [self getPhotos:localDeviceId];
        
        NSMutableArray *assetGroups = [[NSMutableArray alloc] init];
        NSMutableArray *assetURLDictionaries = [[NSMutableArray alloc] init];
        
        // Process assets
        void (^assetEnumerator)(ALAsset *, NSUInteger, BOOL *) = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
            if (result != nil) {
                if ([[result valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]) {
                    [assetURLDictionaries addObject:[result valueForProperty:ALAssetPropertyURLs]];
                    NSURL *url = result.defaultRepresentation.url;
                    [_assetLibrary assetForURL:url
                                   resultBlock:^(ALAsset *asset) {
                                       if (asset) {
                                           [self addPhoto:asset setCompareArray:localPhotos];
                                       }
                                   }
                                  failureBlock:^(NSError *error){
                                      NSLog(@"operation was not successfull!");
                                  }];
                    
                }
            }
        };
        
        // Process groups
        void (^ assetGroupEnumerator) (ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop) {
            if (group != nil) {
                [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:assetEnumerator];
                [assetGroups addObject:group];
            }
        };
        
        // Process!
        [self.assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll
                                         usingBlock:assetGroupEnumerator
                                       failureBlock:^(NSError *error) {
                                           NSLog(@"There is an error");
                                       }];
        localPhotos = locals;
        NSLog(@"finished loading local photos");
    });
}

// add photo to core data
- (void)addPhoto: (ALAsset *)asset setCompareArray: (NSMutableArray *)arr {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    
    // add photo to core data
    NSURL *url = [[asset defaultRepresentation] url];
    NSString *urlString = [url absoluteString];
    NSString *localDeviceId = @"1";
    
    //    NSLog([NSString stringWithFormat:@"size is %lu", (unsigned long)arr.count]);
    
    BOOL alreadyAdded = NO;
    
    for (int i=0;i<arr.count;i++) {
        CSPhoto *ph = arr[i];
        
        if ([urlString isEqualToString:[ph.imageURL absoluteString]]) {
            alreadyAdded = YES;
            break;
        }
    }
    
    if (!alreadyAdded) {
        @synchronized(localPhotos) {
            CSPhoto *photo = [[CSPhoto alloc] init];
            
            photo.photoObject = [MWPhoto photoWithURL:url];
            photo.thumbObject = [MWPhoto photoWithImage:[UIImage imageWithCGImage:asset.thumbnail]];
            
            photo.imageURL = url;
            photo.deviceId = localDeviceId;
            
            [arr addObject:photo];
            
            NSLog(@"creating new photo object");
            
            NSManagedObject *newPhoto = [NSEntityDescription insertNewObjectForEntityForName:@"Photo" inManagedObjectContext:context];
            
            [newPhoto setValue:[photo.imageURL absoluteString] forKey:@"imageURL"];
            [newPhoto setValue:photo.deviceId forKey:@"deviceId"];
            
            NSError *error;
            [context save:&error];
        }
    }else {
        //        NSLog(@"photo already exists in core data");
        ;
    }
}

- (NSMutableArray *)getPhotos: (NSString *) deviceId {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Photo" inManagedObjectContext:context];
    request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(deviceId = %@)", deviceId];
    [request setPredicate:pred];
    
    NSError *error;
    NSArray *phs = [context executeFetchRequest:request error:&error];
    
    if (phs == nil) {
        NSLog(@"error with core data request");
        abort();
    }
    
    // add all of the photo objects to the local photo list
    NSManagedObject *p;
    for (int i =0; i < [phs count]; i++) {
        p = phs[i];
        CSPhoto *photo = [[CSPhoto alloc] init];
        photo.deviceId = [p valueForKey:@"deviceId"];
        
        NSURL *url = [NSURL URLWithString:[p valueForKey:@"imageURL"]];
        
        [_assetLibrary assetForURL:url
                       resultBlock:^(ALAsset *asset) {
                           if (asset) {
                               photo.photoObject = [MWPhoto photoWithURL:asset.defaultRepresentation.url];
                               photo.thumbObject = [MWPhoto photoWithImage:[UIImage imageWithCGImage:asset.thumbnail]];
                           }
                       }
                      failureBlock:^(NSError *error){
                          NSLog(@"operation was not successfull!");
                      }];
        
        photo.imageURL = url;
        [arr addObject:photo];
    }
    
    NSLog(@"returning all photos");
    return arr;
}

@end

