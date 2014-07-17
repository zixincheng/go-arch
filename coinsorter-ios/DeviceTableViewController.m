//
//  Menu.m
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 21/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import "DeviceTableViewController.h"
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
    
    // libraries
    self.coinsorter = [[Coinsorter alloc] init];
    self.dataWrapper = [[CoreDataWrapper alloc] init];
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    account = appDelegate.account;
    
    self.localDevice = [self.dataWrapper getDevice:account.cid];
    
    self.devices = [[NSMutableArray alloc] init];
    
    // load the images from iphone photo library
    [self loadLocalImages];
    
    [self syncAllFromApi];
    
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
    
    [refresh addTarget:self action:@selector(syncAllFromApi) forControlEvents:UIControlEventValueChanged];
    
    self.refreshControl = refresh;
}

- (IBAction)buttonPressed:(id)sender {
    if (sender == self.syncButton) {
        [self syncAllFromApi];
    }else if (sender == self.settingsButton) {
        
    }
}

- (void)stopRefresh {
    [self.refreshControl endRefreshing];
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
#pragma mark Coinsorter api
- (void) syncAllFromApi {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^ {
        [self getDevicesFromApi];
    });
    
    [self stopRefresh];
}

- (void) getDevicesFromApi {
    [self.coinsorter getDevices: ^(NSMutableArray *devices) {
        self.devices = devices;
        [self asyncUpdateView];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
            NSMutableArray *copy = self.devices;
            for (CSDevice *d in copy) {
                [self.dataWrapper addUpdateDevice:d];
            }
        });
    }];
}

- (void) asyncUpdateView {
    dispatch_async(dispatch_get_main_queue(), ^ {
        [self.tableView reloadData];
    });
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.devices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	// Create
    static NSString *CellIdentifier = @"DevicePrototypeCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // Configure
    CSDevice *d = self.devices[[indexPath row]];
    cell.textLabel.text = d.deviceName;
    
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
    
    //    CSDevice *d = [self.devices objectAtIndex:[indexPath row]];
    //    self.photos = [self.dataWrapper getPhotos: d.remoteId];
    
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
    
    // get photos async
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
        CSDevice *d = [self.devices objectAtIndex:[indexPath row]];
        self.photos = [self.dataWrapper getPhotos:d.remoteId];
        
        NSLog(@"size of photos is %d", self.photos.count);
        dispatch_async(dispatch_get_main_queue(), ^ {
            [browser reloadData];
        });
    });
    
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

#pragma mark - Load Local Images

- (void) loadLocalImages {
    _assetLibrary = [[ALAssetsLibrary alloc] init];
    
    // Run in the background as it takes a while to get all assets from the library
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSMutableArray *assetGroups = [[NSMutableArray alloc] init];
        NSMutableArray *assetURLDictionaries = [[NSMutableArray alloc] init];
        
        // Process assets
        void (^assetEnumerator)(ALAsset *, NSUInteger, BOOL *) = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
            if (result != nil) {
                if ([[result valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]) {
                    [assetURLDictionaries addObject:[result valueForProperty:ALAssetPropertyURLs]];
                    NSURL *url = result.defaultRepresentation.url;
                    
                    CSPhoto *photo =[[CSPhoto alloc] init];
                    photo.imageURL = url;
                    photo.deviceId = self.localDevice.remoteId;
                    
                    [self.dataWrapper addPhoto:photo];
                }
            }
        };
        
        // Process groups
        void (^ assetGroupEnumerator) (ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop) {
            if (group != nil) {
                NSString *groupName = [group valueForProperty:ALAssetsGroupPropertyName];
                
                // only get pictures from the coinsorter album
                if ([groupName isEqualToString:@"Coinsorter"]) {
                    [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:assetEnumerator];
                    [assetGroups addObject:group];
                }
            }
        };
        
        // Process!
        [self.assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll
                                         usingBlock:assetGroupEnumerator
                                       failureBlock:^(NSError *error) {
                                           NSLog(@"There is an error");
                                       }];
        //        localPhotos = locals;
        NSLog(@"finished loading local photos");
    });
    
}

- (void)loadAssets {
    
    _assetLibrary = [[ALAssetsLibrary alloc] init];
    
    // Run in the background as it takes a while to get all assets from the library
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSMutableArray *assetGroups = [[NSMutableArray alloc] init];
        NSMutableArray *assetURLDictionaries = [[NSMutableArray alloc] init];
        
        // Process assets
        void (^assetEnumerator)(ALAsset *, NSUInteger, BOOL *) = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
            if (result != nil) {
                if ([[result valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]) {
                    [assetURLDictionaries addObject:[result valueForProperty:ALAssetPropertyURLs]];
                    NSURL *url = result.defaultRepresentation.url;
                    
                    CSPhoto *photo =[[CSPhoto alloc] init];
                    photo.imageURL = url;
                    photo.deviceId = self.localDevice.remoteId;
                    
                    [self.dataWrapper addPhoto:photo];
                    //                    [_assetLibrary assetForURL:url
                    //                                   resultBlock:^(ALAsset *asset) {
                    //                                       if (asset) {
                    //                                           CSPhoto *photo = [[CSPhoto alloc] init];
                    //
                    //                                           photo.photoObject = [MWPhoto photoWithURL:url];
                    //                                           photo.thumbObject = [MWPhoto photoWithImage:[UIImage imageWithCGImage:asset.thumbnail]];
                    //
                    //                                           photo.imageURL = url;
                    //                                           photo.deviceId = self.localDevice.remoteId;
                    //
                    //                                           [self.dataWrapper addPhoto:photo];
                    //                                       }
                    //                                   }
                    //                                  failureBlock:^(NSError *error){
                    //                                      NSLog(@"operation was not successfull!");
                    //                                  }];
                    
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
        //        localPhotos = locals;
        NSLog(@"finished loading local photos");
    });
}

@end

