
#import "DeviceTableViewController.h"
#import "MWCommon.h"


@implementation DeviceTableViewController

#pragma mark - NSUserDefaults Constants

#define DEVICENAME @"deviceName"
#define ALBUMS @"albums"
#define DATE @"date"

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
  
  // init vars
  self.dataWrapper = [[CoreDataWrapper alloc] init];
  self.coinsorter = [[Coinsorter alloc] init];
  defaults = [NSUserDefaults standardUserDefaults];
  self.allowedAlbums = [[NSMutableArray alloc] init];
  self.assetLibrary = [[ALAssetsLibrary alloc] init];
  self.devices = [[NSMutableArray alloc] init];
  UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
  needParse = NO;
  
  // setup objects
  self.coinsorter.dataWrapper = self.dataWrapper;
  AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
  account = appDelegate.account;
  self.localDevice = [self.dataWrapper getDevice:account.cid];
  refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
  [refresh addTarget:self action:@selector(syncAllFromApi) forControlEvents:UIControlEventValueChanged];
  self.refreshControl = refresh;
  
  // call methods to start controller
  
  // load the allowed albums from defaults
  [self loadAllowedAlbums];
  
  // load the images from iphone photo library
  [self loadLocalImages: NO];
  
  // register for alassetlibrarynotifications
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(assetChanged:) name:ALAssetsLibraryChangedNotification object:self.assetLibrary];
  
  [defaults addObserver:self forKeyPath:DEVICENAME options:NSKeyValueObservingOptionNew context:NULL];
  [defaults addObserver:self forKeyPath:ALBUMS options:NSKeyValueObservingOptionNew context:NULL];
  
  // get devices, photos, and upload
  [self syncAllFromApi];
}

// called when this controller leaves memory
// we need to stop observing asset library and defaults
- (void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:ALAssetsLibraryChangedNotification object:nil];
  //    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultsSettingsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];
  
  [defaults removeObserver:self forKeyPath:DEVICENAME];
  [defaults removeObserver:self forKeyPath:ALBUMS];
}

// called when a nsuserdefault value change
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  
  if ([keyPath isEqualToString:DEVICENAME]) {
    // device name change
    NSString *deviceName = [defaults valueForKey:DEVICENAME];
    
    for (CSDevice *d in self.devices) {
      if ([d.remoteId isEqualToString:self.localDevice.remoteId]) {
        
        // check if the device name has changed
        if (![deviceName isEqualToString:self.localDevice.deviceName]) {
          self.localDevice.deviceName = d.deviceName = deviceName;
          
          // if the device name has changed, update the server
          [self.coinsorter updateDevice];
        }
        break;
      }
    }
    [self asyncUpdateView];
  }else if ([keyPath isEqualToString:ALBUMS]) {
    [self loadAllowedAlbums];
    needParse = YES;
  }
}

// get the allowed albums from user defaults and load into array
- (void) loadAllowedAlbums {
  [self.allowedAlbums removeAllObjects];
  NSMutableArray *arr = [defaults mutableArrayValueForKey:ALBUMS];
  for (NSString *url in arr) {
    [self.allowedAlbums addObject:url];
  }
}

// stops the refreshing animation
- (void)stopRefresh {
  [self.refreshControl endRefreshing];
}

// called when the controllers view will become forground
- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  //    self.navigationController.navigationBar.barTintColor = [UIColor greenColor];
  //    self.navigationController.navigationBar.translucent = NO;
  //    [self.navigationController setNavigationBarHidden:YES animated:YES];
  
  // this gets set when we add a new album
  // we want to parse through all of the new photos
  if (needParse) {
    needParse = NO;
    
    NSLog(@"will parse through library to find new photos");
    [self loadLocalImages: YES];
  }
}

// called when controllers view will become background
- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  //    [self.navigationController setNavigationBarHidden:NO animated:YES];
  
  NSLog(@"saved defaults");
  [defaults synchronize];
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

// get devices, photos, and upload from server
- (void) syncAllFromApi {
  // perform all db and api calls in backgroud
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    [self getDevicesFromApi];
    [self getPhotosFromApi];
    [self uploadPhotosToApi];
  });
  
  // stop the refreshing animation
  [self stopRefresh];
}

// get the photos that need to be uploaded from core data
// and upload them to server
- (void) uploadPhotosToApi {
  NSMutableArray *photos = [self.dataWrapper getPhotosToUpload];
  if (photos.count > 0) {
    NSLog(@"there are %lu photos to upload", (unsigned long)photos.count);
    [self.coinsorter uploadPhotos:photos];
  }else {
    NSLog(@"there are no photos to upload");
  }
}

// make api call to get all new photos from server
- (void) getPhotosFromApi {
  NSString *latestId = [self.dataWrapper getLatestId];
  [self.coinsorter getPhotos:latestId callback: ^(NSMutableArray *photos) {
    for (CSPhoto *p in photos) {
      [self.dataWrapper addPhoto:p];
    }
  }];
}

// api call to get all of the devices from server
// we then store those devices in core data
- (void) getDevicesFromApi {
  // first update this device on server
  [self.coinsorter updateDevice];
  
  // then get all devices
  [self.coinsorter getDevices: ^(NSMutableArray *devices) {
    self.devices = devices;
    [self asyncUpdateView];
    for (CSDevice *d in self.devices) {
      [self.dataWrapper addUpdateDevice:d];
    }
  }];
}

// switches to main thread and performs tableview reload
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
  
  // synchrously get photos from core data
  CSDevice *d = [self.devices objectAtIndex:[indexPath row]];
  self.photos = [self.dataWrapper getPhotos:d.remoteId];
  
	// Create browser
	MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
  
  // mwphotobrowser options
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

// checks if the given url is one the user wants photos from
// returns YES if it is
- (BOOL) urlIsAllowed: (NSString *) url {
  for (NSString *u in self.allowedAlbums) {
    if ([u isEqualToString:[url description]]) {
      return YES;
    }
  }
  return NO;
}

// called when an asset in the photo library changes
- (void) assetChanged: (NSNotification *) notification {
  NSDictionary *info = [notification userInfo];
  
  // if the dictionary is nil
  // load all local photos
  if (info == nil) {
    [self loadLocalImages:NO];
    return;
  }
  
  [self loadLocalImages:NO];
  
  // I HAVE NOTICED THAT THE NOTIFICAITON THAT SAYS WHAT HAS BEEN UPDATED IS VERY VERY INCONSISTENT
  // INSTEAD OF USING THAT, WHEN THIS NOTIFICATION IS CALLED, ILL JUST MANUALLY LOOK FOR NEW PHOTOS
  
  //    NSSet *updatedAssets = [info objectForKey:ALAssetLibraryUpdatedAssetsKey];
  //    NSSet *updatedAssetsGroup = [info objectForKey:ALAssetLibraryUpdatedAssetGroupsKey];
  //    if (updatedAssetsGroup != nil) {
  //        for (NSURL *group in updatedAssetsGroup) {
  //            NSString *urlString = [group absoluteString];
  //            NSLog(@"URL STRING - %@", urlString);
  //            if ([self urlIsAllowed:urlString]) {
  //                for (NSURL *a in updatedAssets) {
  //                    NSLog(@"UPDATED - %@", a);
  //                }
  //            }
  //        }
  //    }
}

// add asset to core data
- (void) addAsset: (ALAsset *) asset {
  NSURL *url = asset.defaultRepresentation.url;
  
  // create photo object
  CSPhoto *photo =[[CSPhoto alloc] init];
  photo.imageURL = url.absoluteString;
  photo.deviceId = account.cid;
  photo.onServer = @"0";
  
  // add data to photo
  NSDate *date = [asset valueForProperty:ALAssetPropertyDate];
  photo.dateCreated = date;
  
  // add data to photo obj
  NSString *name = asset.defaultRepresentation.filename;
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsPath = [paths objectAtIndex:0];
  NSString *filePath = [documentsPath stringByAppendingString:[NSString stringWithFormat:@"/thumb-%@", name]];
  
  photo.thumbURL = filePath;
  
  // add photo to db
  [self.dataWrapper addPhoto:photo asset:asset];
}

// load all the local photos from allowed albums to core data
- (void) loadLocalImages: (BOOL) parseAll {
  
  // Run in the background as it takes a while to get all assets from the library
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    NSMutableArray *assetGroups = [[NSMutableArray alloc] init];
    NSMutableArray *assetURLDictionaries = [[NSMutableArray alloc] init];
  
    // the latest date that is stored in the user defaults
    NSDate *latestStored = [defaults objectForKey:DATE];
    
    // the actual latest date from the assets
    // this may be newer than the one stored in the defaults
    // and on first run, this is the only thing that will be change
    __block NSDate *latestAsset;
    
    // Process assets
    void (^assetEnumerator)(ALAsset *, NSUInteger, BOOL *) = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
      if (result != nil) {
        if ([[result valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]) {
          [assetURLDictionaries addObject:[result valueForProperty:ALAssetPropertyURLs]];
          NSURL *url = result.defaultRepresentation.url;
          NSDate *date = [result valueForProperty:ALAssetPropertyDate];
        
          // var to hold date comparison result
          NSComparisonResult result;
          
          if (latestAsset != nil) {
            result = [latestAsset compare:date];
            
            // the current asset date is newer
            if (result == NSOrderedAscending) {
              latestAsset = date;
              // store the latest date in defaults
              [defaults setObject:latestAsset forKey:DATE];
              [defaults synchronize];
            }
          }else {
            latestAsset = date;
            // store the latest date in defaults
            [defaults setObject:latestAsset forKey:DATE];
            [defaults synchronize];
          }
          
          // if you want to stop parsing after we know there are
          // no older ones
          if (!parseAll) {
            // if the latest stored date is there
            if (latestStored != nil) {
              result = [latestStored compare:date];
              
              // if current asset date is older than store date,
              // than stop enumerator
              if (result == NSOrderedDescending || result == NSOrderedSame) {
                *stop = YES;
                return;
              }
            }
          }

//          [defaults setValue:date forKey:[NSString stringWithFormat:@"%@-%@", DATE, ]]
          
          // async call to load the asset from asset library
          [_assetLibrary assetForURL:url
                         resultBlock:^(ALAsset *asset) {
                           if (asset) {
                             [self addAsset:asset];
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
        NSString *groupName = [group valueForProperty:ALAssetsGroupPropertyName];
        NSString *groupUrl = [group valueForProperty:ALAssetsGroupPropertyURL];
        
        // only get pictures from the allowed albums
        if ([self urlIsAllowed:groupUrl]) {
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

@end

