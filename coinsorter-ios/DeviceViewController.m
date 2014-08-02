
#import "DeviceViewController.h"
#import "MWCommon.h"


@implementation DeviceViewController

#pragma mark - NSUserDefaults Constants

#define DEVICENAME @"deviceName"
#define ALBUMS @"albums"
#define DATE @"date"

#pragma mark -
#pragma mark Initialization


- (void)segmentChange {
  [self.tableView reloadData];
}


#pragma mark -
#pragma mark View

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // init vars
  self.dataWrapper = [[CoreDataWrapper alloc] init];
  self.coinsorter = [[Coinsorter alloc] initWithWrapper:self.dataWrapper];
  localLibrary = [[LocalLibrary alloc] init];
  defaults = [NSUserDefaults standardUserDefaults];
  self.devices = [[NSMutableArray alloc] init];
  UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
  needParse = NO;
  self.currentlyUploading = NO;
  
  // setup objects
  AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
  account = appDelegate.account;
  self.localDevice = [self.dataWrapper getDevice:account.cid];
  refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Fetch Photos"];
  [refresh addTarget:self action:@selector(syncAllFromApi) forControlEvents:UIControlEventValueChanged];
  self.refreshControl = refresh;
  
  // get count of unuploaded photos
  self.unUploadedPhotos = [self.dataWrapper getCountUnUploaded];
  [self updateUploadCountUI];
  
  // set the progress bar to 100% for cool effect later
  [self.progressUpload setProgress:100.0f];
  
  // add the refresh control to the table view
  [self.tableView addSubview:self.refreshControl];
  
  // call methods to start controller
  
  // load the allowed albums from defaults
  [localLibrary loadAllowedAlbums];
  
  // load the images from iphone photo library
  [localLibrary loadLocalImages: NO addCallback:^{
    self.unUploadedPhotos++;
    [self updateUploadCountUI];
  }];
  
  // register for asset change notifications
  [localLibrary registerForNotifications];
  // observe values in the user defaults
  [defaults addObserver:self forKeyPath:DEVICENAME options:NSKeyValueObservingOptionNew context:NULL];
  [defaults addObserver:self forKeyPath:ALBUMS options:NSKeyValueObservingOptionNew context:NULL];
  
  // get devices, photos, and upload
  [self syncAllFromApi];
}

// called when this controller leaves memory
// we need to stop observing asset library and defaults
- (void) dealloc {
  [localLibrary unRegisterForNotifications];
  
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
    [localLibrary loadAllowedAlbums];
    needParse = YES;
  }
}

- (IBAction)buttonPressed:(id)sender {
  if (sender == self.btnUpload) {
    [self uploadPhotosToApi];
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
    // load the images from iphone photo library
    [self loadLocalPhotos:YES];
  }else {
    [self loadLocalPhotos:NO];
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

- (void) updateUploadCountUI {
  dispatch_async(dispatch_get_main_queue(), ^{
    NSString *title;
    if (self.unUploadedPhotos == 0) {
      title = @"Nothing to Upload";
    }else {
      title = [NSString stringWithFormat:@"Upload %d Photos", self.unUploadedPhotos];
    }
    [self.btnUpload setTitle:title];
    
    if (self.unUploadedPhotos == 0 || self.currentlyUploading) {
      [self.btnUpload setEnabled: NO];
    }else {
      [self.btnUpload setEnabled: YES];
    }
  });
}

- (void) loadLocalPhotos: (BOOL) parseAll {
  [localLibrary loadLocalImages: parseAll addCallback:^{
    self.unUploadedPhotos++;
    [self updateUploadCountUI];
  }];
}

- (void) removeLocalPhoto {
  self.unUploadedPhotos--;
  [self updateUploadCountUI];
}

#pragma mark -
#pragma mark Coinsorter api

// get devices, photos, and upload from server
- (void) syncAllFromApi {
  // perform all db and api calls in backgroud
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    [self getDevicesFromApi];
    [self getPhotosFromApi];
  });
  
  // stop the refreshing animation
  [self stopRefresh];
}

// get the photos that need to be uploaded from core data
// and upload them to server
- (void) uploadPhotosToApi {
  NSMutableArray *photos = [self.dataWrapper getPhotosToUpload];
  __block int currentUploaded = 0;
  if (photos.count > 0) {
    self.currentlyUploading = YES;
    // hide upload button tool bar and show progress on
    [self.btnUpload setEnabled:NO];
    [self.progressUpload setProgress:0.0 animated:YES];
    
    NSLog(@"there are %lu photos to upload", (unsigned long)photos.count);
    [self.coinsorter uploadPhotos:photos upCallback:^() {
      currentUploaded += 1;
      
      [self removeLocalPhoto];
      
      NSLog(@"%d / %lu", currentUploaded, (unsigned long)photos.count);
      
      // update progress bar on main thread
      dispatch_async(dispatch_get_main_queue(), ^{
        float progress = (float) currentUploaded / (float) photos.count;
        
        [self.progressUpload setProgress:progress animated:YES];
      
        if (progress == 1.0) {
          [self.btnUpload setEnabled:YES];
          self.currentlyUploading = NO;
          [self updateUploadCountUI];
        }
      });
    }];
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
    for (CSDevice *d in devices) {
      [self.dataWrapper addUpdateDevice:d];
    }
      self.devices = [self.dataWrapper getAllDevices];
      [self asyncUpdateView];
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

@end

