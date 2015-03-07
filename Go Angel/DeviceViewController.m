//
// DeviceViewController.m
//  Go Arch
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.

#import "DeviceViewController.h"
@interface DeviceViewController (){
    BOOL takingPhoto;
    BOOL recording;
    NSTimer *timer;
    int sec;
    int min;
    int hour;
    
}

@end
@implementation DeviceViewController

#pragma mark - NSUserDefaults Constants

#define IMAGE_VIEW_TAG 11
#define GRID_CELL      @"gridCell"
#define SINGLE_PHOTO_SEGUE @"singleImageSegue"

//height
#define CAMERA_TOPVIEW_HEIGHT   44  //title
#define CAMERA_MENU_VIEW_HEIGH  44  //menu

#pragma mark -
#pragma mark Initialization


- (void)segmentChange {
  [self.tableView reloadData];
}

#pragma mark -
#pragma mark View

- (void)viewDidLoad {
  [super viewDidLoad];
    AVCaptureSession *tmpSession = [[AVCaptureSession alloc] init];
    self.session = tmpSession;
    [self.session setSessionPreset:AVCaptureSessionPresetHigh];
    [self.session startRunning];
    self.picker = [[UIImagePickerController alloc] init];
    self.overlay = [[UIView alloc] initWithFrame:self.view.bounds];
    [self addVideoInputFrontCamera:YES];
    //self.overlay = [[UIView alloc] initWithFrame:self.view.bounds];
    //[self addCameraCover];

  // nav bar
  // make light nav bar
  self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushNotificationReceived) name:@"pushNotification" object:nil];
    
  // init vars
  self.dataWrapper = [[CoreDataWrapper alloc] init];
  self.coinsorter = [[Coinsorter alloc] initWithWrapper:self.dataWrapper];
  localLibrary = [[LocalLibrary alloc] init];
  defaults = [NSUserDefaults standardUserDefaults];
  self.devices = [[NSMutableArray alloc] init];
  log = [[ActivityHistory alloc] init];
 //UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
  needParse = NO;
  self.currentlyUploading = NO;
    
  self.saveInAlbum = [defaults boolForKey:SAVE_INTO_ALBUM];
    
  // setup objects
  AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
  account = appDelegate.account;
  self.localDevice = [self.dataWrapper getDevice:account.cid];
 // refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Fetch Photos"];
  //[refresh addTarget:self action:@selector(syncAllFromApi) forControlEvents:UIControlEventValueChanged];
  //self.refreshControl = refresh;

  // get count of unuploaded photos
  self.unUploadedPhotos = [self.dataWrapper getCountUnUploaded];
  //self.photos =  [self.dataWrapper getPhotos:self.localDevice.remoteId];
    
  // set the progress bar to 100% for cool effect later
  [self.progressUpload setProgress:100.0f];
  
  // add the refresh control to the table view
  [self.tableView addSubview:self.refreshControl];
  
  // load the devices array
  [self loadDevices];

  // call methods to start controller
  
  // check if the camera button should be shown (only if the device has a camera)
  if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
  }
  
  // register for asset change notifications
//  [localLibrary registerForNotifications];
  // observe values in the user defaults
  [defaults addObserver:self forKeyPath:DEVICE_NAME options:NSKeyValueObservingOptionNew context:NULL];
  [defaults addObserver:self forKeyPath:ALBUMS options:NSKeyValueObservingOptionNew context:NULL];
  [defaults addObserver:self forKeyPath:DOWN_REMOTE options:NSKeyValueObservingOptionNew context:NULL];
  [defaults addObserver:self forKeyPath:SAVE_INTO_ALBUM options:NSKeyValueObservingOptionNew context:NULL];

    
  // notification so we know when app comes into foreground
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eachPhotoUploaded) name:@"onePhotoUploaded" object:nil];
  // Start networking
  
  self.prevBSSID = [self currentWifiBSSID];
  
  // setup network notification
  [self setupNet];
  
  // only ping if we are connected through wifi
  if (self.networkStatus == ReachableViaWiFi) {
    // ping the server to see if we are connected to bb
    [self.coinsorter pingServer:^(BOOL connected) {
      self.canConnect = connected;
      
      [self updateUploadCountUI];
      
      if (self.canConnect) {
        // get all devices and photos from server
        // only call this when we know we are connected
        [self syncAllFromApi];
      }
    }];
  }else {
    self.canConnect = NO;
  }
  
  // update ui status bar
  [self updateUploadCountUI];
  [self checkDeivceStatus];
  [self addHistoryButton];

}
// called when this controller leaves memory
// we need to stop observing asset library and defaults
- (void) dealloc {
    [_session stopRunning];
    self.session = nil;
  [localLibrary unRegisterForNotifications];
  
  [defaults removeObserver:self forKeyPath:DEVICE_NAME];
  [defaults removeObserver:self forKeyPath:ALBUMS];
//  [defaults removeObserver:self forKeyPath:DOWN_REMOTE];

  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

// load devices
// sets up the devices array used to populate the view table
- (void)loadDevices {
  
  [self.devices removeAllObjects];
  BOOL downRemote = [defaults boolForKey:DOWN_REMOTE];
  
  // get devices we already have in db to setup list
  // only get all the devices if we want to see them all
  // otherwise use just local device
  if (!downRemote) {
    [self.devices addObject:self.localDevice];
    NSLog(@"Adding only local device to devices list");
  }else {
    self.devices = [self.dataWrapper getAllDevices];
    NSLog(@"Adding all devices to devices list");
  }
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.tableView reloadData];
  });
}

// called when a nsuserdefault value change
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  
  if ([keyPath isEqualToString:DEVICE_NAME]) {
    // device name change
    NSString *deviceName = [defaults valueForKey:DEVICE_NAME];
    
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
  }else if ([keyPath isEqualToString:DOWN_REMOTE]) {
    BOOL downRemote = [defaults boolForKey:DOWN_REMOTE];
    if (downRemote) {
      [self syncAllFromApi];
    }
    [self loadDevices];
  }else if([keyPath isEqualToString:SAVE_INTO_ALBUM]){
      self.saveInAlbum = [defaults boolForKey:SAVE_INTO_ALBUM];
  }
}

- (IBAction)buttonPressed:(id)sender {
  if (sender == self.btnUpload) {
    [self uploadPhotosToApi];
  }else if (sender == self.btnCamera) {
    self.picker.delegate = self;
    self.picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.overlay = [self creatCaremaOverlay];
    self.picker.cameraOverlayView = self.overlay;
    self.picker.showsCameraControls = NO;
    takingPhoto = YES;

    
    [self presentViewController:self.picker animated:YES completion:^{
        [self addCameraCover];
        NSLog(@"session %@",self.session);
    }];
  }
}

// stops the refreshing animation
- (void)stopRefresh {
  if (self.refreshControl != nil && [self.refreshControl isRefreshing]) {
    [self.refreshControl endRefreshing];
  }
}

// called by notification when app enters foreground
- (void)applicationWillEnterForeground:(NSNotification *)notification {
  // get the bssid and compare with prev one
  // if it has changed, then do ping
  NSString *bssid = [self currentWifiBSSID];
  
  // this means we do not hava wifi bssid
  // probably on 3g
  if (bssid == nil) {
    return;
  }
  
  if (self.prevBSSID == nil) {
    self.prevBSSID = bssid;
  }else {
    if (![self.prevBSSID isEqualToString:bssid]) {
      NSLog(@"network bssid changed");
      
      self.canConnect = NO;
      [self updateUploadCountUI];
      
      self.prevBSSID = bssid;
      [self.coinsorter pingServer:^(BOOL connected) {
        self.canConnect = connected;
        
        [self updateUploadCountUI];
        
        if (self.canConnect) {
          // get all devices and photos from server
          // only call this when we know we are connected
          [self syncAllFromApi];
        }
      }];
    }
  }
}

// called when the controllers view will become forground
- (void)viewWillAppear:(BOOL)animated {
    //self.photos =  [self.dataWrapper getPhotos:self.localDevice.remoteId];
    [self.collectionView reloadData];
    [self updateUploadCountUI];
    self.unUploadedPhotos = [self.dataWrapper getCountUnUploaded];
    [self checkDeivceStatus];
  [super viewWillAppear:animated];
  
  // this gets set when we add a new album
  // we want to parse through all of the new photos
  if (needParse) {
    needParse = NO;
  
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
    
    if (!self.canConnect) {
      title = @"Cannot Connect";
      [self checkDeivceStatus];
    }else if (self.unUploadedPhotos == 0) {
      title = @"Nothing to Upload";
        //self.valueSwirly.value = 2;
        [self checkDeivceStatus];
    }else if (self.currentlyUploading) {
      title = [NSString stringWithFormat:@"Uploading %d Photos", self.unUploadedPhotos];
        //self.valueSwirly.value = 1;
        [self checkDeivceStatus];
    }else {
      title = [NSString stringWithFormat:@"Upload %d Photos", self.unUploadedPhotos];
        [self checkDeivceStatus];
        //self.valueSwirly.value = 0;
    }
    [self.btnUpload setTitle:title];
    
    if (self.canConnect) {
      [self.progressUpload setTintColor:nil];
    }else {
      UIColor * color = [UIColor colorWithRed:212/255.0f green:1/255.0f blue:0/255.0f alpha:1.0f];
      [self.progressUpload setTintColor:color];
    }
    
    if (self.unUploadedPhotos == 0 || self.currentlyUploading || !self.canConnect) {
      [self.btnUpload setEnabled: NO];
    }else {
      [self.btnUpload setEnabled: YES];
    }
  });
}

// get photos from local library
// if parse all is true, parse through entire dir
// if false, stop parsing when find photo older than date saved
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

// get devices, photos from server
- (void) syncAllFromApi {
  
  BOOL downRemote = [defaults boolForKey:DOWN_REMOTE];
  
  // if we can connect to server than make api calls
  if (self.canConnect && downRemote) {
    // perform all db and api calls in backgroud
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
      [self getDevicesFromApi];
      [self getPhotosFromApi];
    });
  }
  
  // stop the refreshing animation
  [self stopRefresh];
}

// get the photos that need to be uploaded from core data
// and upload them to server
- (void) uploadPhotosToApi {
  NSMutableArray *photos = [self.dataWrapper getPhotosToUpload];
  __block int currentUploaded = 0;
  if (photos.count > 0) {
    //sent a notification when start uploading photos
    [[NSNotificationCenter defaultCenter] postNotificationName:@"startUploading" object:nil];
    self.currentlyUploading = YES;
    // hide upload button tool bar and show progress on
    [self.btnUpload setEnabled:NO];
    [self.progressUpload setProgress:0.0 animated:YES];
    
    [self updateUploadCountUI];
      [self updateUploadingStatus];
    
    NSLog(@"there are %lu photos to upload", (unsigned long)photos.count);
    //[self.coinsorter uploadPhotos:photos upCallback:^() {

      currentUploaded += 1;
      
      [self removeLocalPhoto];
      
      NSLog(@"%d / %lu", currentUploaded, (unsigned long)photos.count);
      
      // update progress bar on main thread
      dispatch_async(dispatch_get_main_queue(), ^{
        float progress = (float) currentUploaded / (float) photos.count;
        
        [self.progressUpload setProgress:progress animated:YES];
          
        //sent a notification to dashboard when finish uploading 1 photo
        [[NSNotificationCenter defaultCenter] postNotificationName:@"onePhotoUploaded" object:nil];
          
        // the upload is complete
        if (progress == 1.0) {
          [self.btnUpload setEnabled:YES];
          self.currentlyUploading = NO;
          [self updateUploadCountUI];
           //sent a notification to dashboard when finish uploading all photos 
          [[NSNotificationCenter defaultCenter] postNotificationName:@"endUploading" object:nil];
          // allow app to sleep again
          [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
          
          //add uploading message into activity history class
          NSString *message = [NSString stringWithFormat: @"App uploads %lu photo to Arch Box",(unsigned long)photos.count];
          log.activityLog = message;
          log.timeUpdate = [NSDate date];
          [self.dataWrapper addUpdateLog:log];
        }
      });
    //}];
  }else {
    NSLog(@"there are no photos to upload");
  }
}

// make api call to get all new photos from server
- (void) getPhotosFromApi {
  NSString *latestId = [self.dataWrapper getLatestId];
  [self.coinsorter getPhotos:latestId.intValue callback: ^(NSMutableArray *photos) {
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
#pragma mark Status Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DashBoardCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DashBoardCell"];
    }
    if (indexPath.row == 0) {
        cell.textLabel.text = [NSString stringWithFormat:@"Status: %d / %d", self.totalUploadedPhotos,self.totalPhotos];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }else if (indexPath.row == 1){
        cell.textLabel.text = [NSString stringWithFormat:@"All Photos"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
        return 40;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (indexPath.row) {
        case 0:
            [self performSegueWithIdentifier:@"dashboardSegue" sender:self];
            break;
        case 1:
            self.selectedDevice = self.localDevice;
            [self performSegueWithIdentifier:@"gridSegue" sender:self];
        break;
            break;
    }
    
    // Deselect
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"gridSegue"]) {
        GridViewController *gridController = (GridViewController *)segue.destinationViewController;
        gridController.device = self.selectedDevice;
        gridController.dataWrapper = self.dataWrapper;
        gridController.currentUploading = self.currentlyUploading;
        self.totalUploadedPhotos = [self.dataWrapper getCountUploaded:self.localDevice.remoteId];
        gridController.totalUploadedPhotos = self.totalUploadedPhotos;
        
    }  else if([segue.identifier isEqualToString:SINGLE_PHOTO_SEGUE]) {
        PhotoSwipeViewController *swipeController = (PhotoSwipeViewController *) segue.destinationViewController;
        swipeController.selected = selected;
        swipeController.photos = self.photos;
    } else if ([segue.identifier isEqualToString:@"dashboardSegue"]){
        [self checkDeivceStatus];
        
        DashboardViewController *dashboardVC = (DashboardViewController *) segue.destinationViewController;
        dashboardVC.title = @"DashBoard";
        dashboardVC.totalPhotos = self.totalPhotos;
        dashboardVC.processedUploadedPhotos = self.totalUploadedPhotos;
        dashboardVC.currentStatus = self.currentStatus;
        dashboardVC.homeServer = self.homeServer;
        dashboardVC.serverName = self.serverName;
        dashboardVC.serverIP = self.serverIP;
    }
}

#pragma mark -
#pragma mark Table view data source
/*

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
  
  CSDevice *d = [self.devices objectAtIndex:[indexPath row]];
  self.selectedDevice = d;
  
  [self performSegueWithIdentifier:@"gridSegue" sender:self];
  
  // Deselect
  [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if([segue.identifier isEqualToString:@"gridSegue"]) {
    GridViewController *gridController = (GridViewController *)segue.destinationViewController;
    gridController.device = self.selectedDevice;
    gridController.dataWrapper = self.dataWrapper;
  }
}

*/
# pragma mark - Camera

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
  //[picker dismissViewControllerAnimated:NO completion:^{
    // picker disappeared
    if (takingPhoto) {
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        NSDictionary *metadata = info[UIImagePickerControllerMediaMetadata];

        if (self.saveInAlbum) {
            NSLog(@"save photos into album");
/*
            [localLibrary saveImage:image metadata:metadata callback: ^(CSPhoto *photo){
                dispatch_async(dispatch_get_main_queue(), ^ {
                    [self addNewcell:photo];
                });
            }];*/
        }else{
            NSLog(@"save photos into application folder");
           // [self saveImageIntoDocument:image metadata:metadata callback: ^(CSPhoto *photo){
              //  dispatch_async(dispatch_get_main_queue(), ^ {
              //      [self addNewcell:photo];
               //     [self updateUploadCountUI];
               // });
           // }];

        }
    } else {
        if (self.saveInAlbum) {
            NSLog(@"save video into album");
            NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
            // Handle a movie capture
            if (CFStringCompare ((__bridge_retained CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
                NSURL *moviePath = [info objectForKey:UIImagePickerControllerMediaURL];
                NSLog(@"%@",moviePath);

               // [localLibrary saveVideo:moviePath callback:^(CSPhoto *photo) {
                   // dispatch_async(dispatch_get_main_queue(), ^ {
                    //    [self addNewcell:photo];
                    //});
               // }];
            }
        } else {
            NSLog(@"save video into application folder");
            NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
            // Handle a movie capture
            if (CFStringCompare ((__bridge_retained CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
                NSURL *moviePath = [info objectForKey:UIImagePickerControllerMediaURL];
                NSLog(@"%@",moviePath);

                [self saveVideoIntoDocument:moviePath callback:^(CSPhoto *photo) {
                    dispatch_async(dispatch_get_main_queue(), ^ {
                        [self addNewcell:photo];
                    });
                }];
            }

        }
    }
    
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [picker dismissViewControllerAnimated:YES completion:NULL];
}

# pragma mark - Network

// get the initial network status
- (void) setupNet {
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkNetworkStatus:) name:kReachabilityChangedNotification object:nil];
  
  self.reach = [Reachability reachabilityForInternetConnection];
  [self.reach startNotifier];
  
  NetworkStatus remoteHostStatus = [self.reach currentReachabilityStatus];
  self.networkStatus = remoteHostStatus;
  
  if (remoteHostStatus == NotReachable) {
    NSLog(@"not reachable");
  }else if (remoteHostStatus == ReachableViaWiFi) {
    NSLog(@"wifi");
  }else if (remoteHostStatus == ReachableViaWWAN) {
    NSLog(@"wwan");
  }
}

// called whenever network changes
- (void) checkNetworkStatus: (NSNotification *) notification {
  NSLog(@"network changed");
  
  NetworkStatus remoteHostStatus = [self.reach currentReachabilityStatus];
  self.networkStatus = remoteHostStatus;
  
  if (remoteHostStatus == NotReachable) {
    NSLog(@"not reachable");
    //sent a notification to dashboard when network is not reachable
    [[NSNotificationCenter defaultCenter] postNotificationName:@"homeServerDisconnected" object:nil];
    self.canConnect = NO;
    [self updateUploadCountUI];
  }else if (remoteHostStatus == ReachableViaWiFi) {
    // if we are connected to wifi
    // and we have a blackbox ip we have connected to before
    if (account.currentIp != nil) {
      [self.coinsorter pingServer:^(BOOL connected) {
        self.canConnect = connected;
        //sent a notification to dashboard when network connects with home server
        [[NSNotificationCenter defaultCenter] postNotificationName:@"homeServerConnected" object:nil];
        [self updateUploadCountUI];
      }];
    }
  }else if (remoteHostStatus == ReachableViaWWAN) {
    NSLog(@"wwan");
    //sent a notification to dashboard when network connects with WIFI not home server
    [[NSNotificationCenter defaultCenter] postNotificationName:@"homeServerDisconnected" object:nil];
    self.canConnect = NO;
    [self updateUploadCountUI];
  }
}

// get the current wifi bssid (network id)
- (NSString *)currentWifiBSSID {
  // Does not work on the simulator.
  NSString *bssid = nil;
  NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
  for (NSString *ifnam in ifs) {
    NSDictionary *info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
    if (info[@"BSSID"]) {
      bssid = info[@"BSSID"];
    }
  }
  return bssid;
}

# pragma mark - DashBoard view information

- (void)checkDeivceStatus{
    //NSMutableArray *photos = [self.dataWrapper getPhotos:self.localDevice.remoteId];
    self.totalUploadedPhotos = [self.dataWrapper getCountUploaded:self.localDevice.remoteId];
   // self.totalPhotos = photos.count;
    
    if (self.currentlyUploading) {
        self.currentStatus = @"Uploading Photos";
    }
    else if (self.unUploadedPhotos == 0) {
        self.currentStatus = @"Nothing to Upload";
        
    }
    else{
        self.currentStatus = @"Waiting";
    }
    
    if (self.canConnect) {
        self.serverName = account.name;
        self.serverIP = account.currentIp;
        self.homeServer = @"YES";
    }
    else{
        self.serverName = @"Unknown";
        self.serverIP = @"Unknown";
        self.homeServer = @"NO";
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

# pragma mark - CollectionViewController Methods

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.photos.count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    GridCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:GRID_CELL forIndexPath:indexPath];
    UIImageView *imageView = (UIImageView *) [cell viewWithTag:IMAGE_VIEW_TAG];
    
    CSPhoto *photo = [self.photos objectAtIndex:[indexPath row]];
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [appDelegate.mediaLoader loadThumbnail:photo completionHandler:^(UIImage *image) {
        dispatch_async(dispatch_get_main_queue(), ^{
           __block UIImage *newimage = [self markedImageStatus:image checkImageStatus:photo.thumbOnServer uploadingImage:self.currentlyUploading];
            [imageView setImage:newimage];
            
            //      if ([indexPath row] == bottom_selected) {
            //        UIView *overlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, imageView.frame.size.width, imageView.frame.size.height)];
            //        [overlay setTag:OVERLAY_TAG];
            //        [overlay setBackgroundColor:[UIColor colorWithRed:255/255.0f green:233/255.0f blue:0/255.0f alpha:0.6f]];
            //        [imageView addSubview:overlay];
            //      }
        });
    }];
    
    return cell;
}
- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

    selected = [indexPath row];
    [self performSegueWithIdentifier:SINGLE_PHOTO_SEGUE sender:self];
}

//update the collection view cell
-(void) addNewcell: (CSPhoto *)photos{
    
    int Size = (int)self.photos.count;
    [self.collectionView performBatchUpdates:^{
        
       [self.photos addObject:photos];
        NSMutableArray *arrayWithIndexPaths = [NSMutableArray array];
        
       // self.photos =  [self.dataWrapper getPhotos:self.localDevice.remoteId];
        [arrayWithIndexPaths addObject:[NSIndexPath indexPathForRow:0 inSection:0]];
        [self.collectionView insertItemsAtIndexPaths:arrayWithIndexPaths];

        if (Size != 0) {
            [self.collectionView reloadItemsAtIndexPaths:arrayWithIndexPaths];
        }
    }completion:^(BOOL finished) {
        if (finished) {
           // self.photos =  [self.dataWrapper getPhotos:self.localDevice.remoteId];
        }
    }];
}
-(void)pushNotificationReceived{
    NSLog(@"recieved notification");
    [self performSegueWithIdentifier:@"pushNotification" sender:self];

}

//uploading status image update
- (UIImage *)markedImageStatus:(UIImage *) image checkImageStatus:(NSString *)onServer uploadingImage:(BOOL)upload
{
    UIGraphicsBeginImageContext(image.size);
    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    
    if ([onServer isEqualToString:@"1"]) {
        UIImage *iconImage = [UIImage imageNamed:@"uploaded.png"];
        [iconImage drawInRect:CGRectMake(image.size.width-40, image.size.height-40, 40, 40)];
    }else if((!upload) && [onServer isEqualToString:@"0"]){
        UIImage *iconImage = [UIImage imageNamed:@"unupload.png"];
        [iconImage drawInRect:CGRectMake(image.size.width-40, image.size.height-40, 40, 40)];
    }else if( upload && [onServer isEqualToString:@"0"]){
        UIImage *iconImage = [UIImage imageNamed:@"uploading.png"];
        [iconImage drawInRect:CGRectMake(image.size.width-40, image.size.height-40, 40, 40)];
    }
    // make image out of bitmap context
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // free the context
    UIGraphicsEndImageContext();
    
    return finalImage;
}

# pragma mark - History View

//create a log button in navigation bar programmatically
- (void) addHistoryButton{
    logButton = [[UIBarButtonItem alloc] initWithTitle:@"Log" style:UIBarButtonItemStylePlain target:self action:@selector(presentHistoryView:)];
    NSArray *rightButtonItems = [[NSArray alloc] initWithObjects:settingButton,logButton,nil];
    
    [self.navigationItem setRightBarButtonItems:rightButtonItems animated:YES];
}

//log button action
- (void)presentHistoryView:(id)sender{
    HistoryTableViewController *historyVC = [[HistoryTableViewController alloc] init];
    historyVC.dataWrapper = self.dataWrapper;
    historyVC.title = @"Activity History";
    [self.navigationController pushViewController:historyVC animated:YES];
}

#pragma mark -
#pragma mark Image/Video Save Into document

// save photos to the document directory


//get currentdate so that each image can have a unique name

-(NSString*)getCurrentDateTime
{
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyyMMddHHmmss"];
    NSDate *now = [NSDate date];
    NSString *retStr = [format stringFromDate:now];
    
    return retStr;
}

-(void) saveVideoIntoDocument:(NSURL *)moviePath callback:(void (^) (CSPhoto *photo)) callback{


    // generate thumbnail for video
    AVAsset *asset = [AVAsset assetWithURL:moviePath];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:asset];
    CMTime time = [asset duration];
    time.value = 0;
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
    UIImage *thumbnail = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);

    // get app document path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];


    NSString *photoUID = [self getCurrentDateTime];
    NSString *thumbPath = [documentsPath stringByAppendingString:[NSString stringWithFormat:@"/thumb_%@.jpg", photoUID]];
    NSString *filePath = [documentsPath stringByAppendingString:[NSString stringWithFormat:@"/%@.mov", photoUID]];

    NSString *fullPath = [[NSURL fileURLWithPath:filePath] absoluteString];
    NSString *fullthumbPath = [[NSURL fileURLWithPath:thumbPath] absoluteString];

    NSData *videoData = [NSData dataWithContentsOfURL:moviePath];

    [videoData writeToFile:filePath atomically:YES];
    NSData *thumbData = [NSData dataWithData:UIImageJPEGRepresentation(thumbnail, 1.0)];
    [thumbData writeToFile:thumbPath atomically:YES];

    CSPhoto *p = [[CSPhoto alloc] init];

    p.dateCreated = [NSDate date];
    p.deviceId = self.localDevice.remoteId;
    p.thumbOnServer = @"0";
    p.thumbURL = fullthumbPath;
    p.imageURL = fullPath;
    p.fileName = [NSString stringWithFormat:@"%@.mov",photoUID];
    p.isVideo = @"1";

    [self.dataWrapper addPhoto:p];

    self.unUploadedPhotos++;
    callback(p);

}

// save photos to the document directory and save to core data
- (void) saveImageIntoDocument:(UIImage *)image metadata:(NSDictionary *)metadata callback: (void (^) (CSPhoto *photo)) callback {

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];

    NSString *photoUID = [self getCurrentDateTime];

    NSString *filePath = [documentsPath stringByAppendingString:[NSString stringWithFormat:@"/%@.jpg", photoUID]];
    NSString *fullPath = [[NSURL fileURLWithPath:filePath] absoluteString];

    
    CSPhoto *p = [[CSPhoto alloc] init];

    p.dateCreated = [NSDate date];
    p.deviceId = self.localDevice.remoteId;
    p.thumbOnServer = @"0";
    p.thumbURL = fullPath;
    p.imageURL = fullPath;
    p.fileName = [NSString stringWithFormat:@"%@.jpg", photoUID];
    p.isVideo = @"0";

// save the metada information into image
    NSData *data = UIImageJPEGRepresentation(image, 100);
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);

    CFStringRef UTI = CGImageSourceGetType(source);
     NSMutableData *dest_data = [NSMutableData data];
    CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef) dest_data, UTI, 1, NULL);

    CGImageDestinationAddImageFromSource(
                                         destination, source, 0, (__bridge CFDictionaryRef)metadata);

    CGImageDestinationFinalize(destination);

    [dest_data writeToFile:filePath atomically:YES];

    CFRelease(destination);
    NSLog(@"saving photo to %@ with filename %@", filePath, p.fileName);

    [self.dataWrapper addPhoto:p];

    self.unUploadedPhotos++;
    callback(p);
}

// update the status image everytime a photo been uploaded
- (void)eachPhotoUploaded{
    if (self.unUploadedPhotos == 0) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            CSPhoto *photo = [self.photos objectAtIndex:0];
            photo.thumbOnServer = [self.dataWrapper getCurrentPhotoOnServerVaule:self.localDevice.remoteId CurrentIndex:0];
            [self.photos replaceObjectAtIndex:0 withObject:photo];
            NSLog(@"current photo onServer value is: %@", photo.thumbOnServer);

            NSMutableArray *arrayWithIndexPaths = [NSMutableArray array];
            [arrayWithIndexPaths addObject:[NSIndexPath indexPathForRow:0 inSection:0]];
            dispatch_async(dispatch_get_main_queue(), ^ {
                [self.collectionView reloadItemsAtIndexPaths:arrayWithIndexPaths];
            });
            NSLog(@"reload current photo at index : %i", 0);

        });
    } else {
    self.totalUploadedPhotos += 1;
    int currentPhotoIndex = (int)self.unUploadedPhotos;
    //update current uploaded photo onServer value
    CSPhoto *photo = [self.photos objectAtIndex:currentPhotoIndex];
    photo.thumbOnServer = [self.dataWrapper getCurrentPhotoOnServerVaule:self.localDevice.remoteId CurrentIndex:currentPhotoIndex];
    [self.photos replaceObjectAtIndex:currentPhotoIndex withObject:photo];
    NSLog(@"current photo onServer value is: %@", photo.thumbOnServer);

    NSMutableArray *arrayWithIndexPaths = [NSMutableArray array];
    [arrayWithIndexPaths addObject:[NSIndexPath indexPathForRow:currentPhotoIndex inSection:0]];
    dispatch_async(dispatch_get_main_queue(), ^ {
        [self.collectionView reloadItemsAtIndexPaths:arrayWithIndexPaths];
    });
    NSLog(@"reload current photo at index : %i", currentPhotoIndex);
    }
}

-(void) updateUploadingStatus {
    NSMutableArray *arrayWithIndexPaths = [NSMutableArray array];
    if (self.currentlyUploading) {
        for (int i = 0; i < self.unUploadedPhotos; i++) {
                    [arrayWithIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        dispatch_async(dispatch_get_main_queue(), ^ {
            [self.collectionView reloadItemsAtIndexPaths:arrayWithIndexPaths];
        });

    }

}

//create custom camera overlay
-(UIView *) creatCaremaOverlay {
    
    [self addTopViewWithText:@"Taking Photo"];
    [self addCameraMenuView];
    
    return self.overlay;
    
}

// text message at top of the custom camera view
- (void)addTopViewWithText:(NSString*)text{
    if (!_topContainerView) {
        CGRect topFrame = CGRectMake(0, 0, APP_SIZE.width, CAMERA_TOPVIEW_HEIGHT);
        
        UIView *tView = [[UIView alloc] initWithFrame:topFrame];
        tView.backgroundColor = [UIColor clearColor];
        [self.overlay addSubview:tView];
        self.topContainerView = tView;
        
        UIView *emptyView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, topFrame.size.width, topFrame.size.height)];
        emptyView.backgroundColor = [UIColor blackColor];
        emptyView.alpha = 0.4f;
        [_topContainerView addSubview:emptyView];
        
        topFrame.origin.x += 10;
        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 500, topFrame.size.height)];
        lbl.backgroundColor = [UIColor clearColor];
        lbl.textColor = [UIColor whiteColor];
        lbl.font = [UIFont systemFontOfSize:25.f];
        lbl.textAlignment = NSTextAlignmentNatural;
        [_topContainerView addSubview:lbl];
        self.topLbl = lbl;
    }
    _topLbl.text = text;
}

// create camera menu view, include camera button and camera control buttons
- (void)addCameraMenuView{
    
    //Button to take photo
    CGFloat cameraBtnLength = 90;
    self.caremaBtn =[self buildButton:CGRectMake((APP_SIZE.width - cameraBtnLength) / 2, (DEVICE_SIZE.height - CAMERA_MENU_VIEW_HEIGH - cameraBtnLength)  , cameraBtnLength, cameraBtnLength)
         normalImgStr:@"shot.png"
      highlightImgStr:@""
       selectedImgStr:@""
               action:@selector(takePictureBtnPressed:)
           parentView:self.overlay];
    
    
    //sub view of list of buttons in camera view
    UIView *menuView = [[UIView alloc] initWithFrame:CGRectMake(0, DEVICE_SIZE.height - CAMERA_MENU_VIEW_HEIGH, self.view.frame.size.width, CAMERA_MENU_VIEW_HEIGH)];
    menuView.backgroundColor = [UIColor clearColor];
    [self.overlay addSubview:menuView];
    self.cameraMenuView = menuView;
    
    
    
    [self addMenuViewButtons];
}

//buttons on the bottom of camera view
- (void)addMenuViewButtons {

    NSMutableArray *normalArr = [[NSMutableArray alloc] initWithObjects:@"close_cha.png", @"camera_line.png", @"switch_camera.png", @"flashing_auto.png", nil];
       NSMutableArray *highlightArr = [[NSMutableArray alloc] initWithObjects:@"close_cha_h.png", @"", @"", @"", nil];
    NSMutableArray *selectedArr = [[NSMutableArray alloc] initWithObjects:@"", @"camera_line_h.png", @"switch_camera_h.png", @"", nil];
    
    NSMutableArray *actionArr = [[NSMutableArray alloc] initWithObjects:@"dismissBtnPressed:", @"VideoBtnPressed:", @"switchCameraBtnPressed:", @"flashBtnPressed:", nil];
    
    CGFloat eachW = APP_SIZE.width / actionArr.count;
    
    [self drawALineWithFrame:CGRectMake(eachW, 0, 1, CAMERA_MENU_VIEW_HEIGH) andColor:[UIColor colorWithRed:102 green:102 blue:102 alpha:1.0000] inLayer:_cameraMenuView.layer];
    
    

    for (int i = 0; i < actionArr.count; i++) {
        
        UIButton * btn = [self buildButton:CGRectMake(eachW * i, 0, eachW, CAMERA_MENU_VIEW_HEIGH)
                              normalImgStr:[normalArr objectAtIndex:i]
                           highlightImgStr:[highlightArr objectAtIndex:i]
                            selectedImgStr:[selectedArr objectAtIndex:i]
                                    action:NSSelectorFromString([actionArr objectAtIndex:i])
                                parentView:_cameraMenuView];
        
        btn.showsTouchWhenHighlighted = YES;
        
        [_cameraBtnSet addObject:btn];
    }
}

- (UIButton*)buildButton:(CGRect)frame
            normalImgStr:(NSString*)normalImgStr
         highlightImgStr:(NSString*)highlightImgStr
          selectedImgStr:(NSString*)selectedImgStr
                  action:(SEL)action
              parentView:(UIView*)parentView {
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = frame;
    if (normalImgStr.length > 0) {
        [btn setImage:[UIImage imageNamed:normalImgStr] forState:UIControlStateNormal];
    }
    if (highlightImgStr.length > 0) {
        [btn setImage:[UIImage imageNamed:highlightImgStr] forState:UIControlStateHighlighted];
    }
    if (selectedImgStr.length > 0) {
        [btn setImage:[UIImage imageNamed:selectedImgStr] forState:UIControlStateSelected];
    }
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [parentView addSubview:btn];
    
    return btn;
}

- (void)drawALineWithFrame:(CGRect)frame andColor:(UIColor*)color inLayer:(CALayer*)parentLayer {
    CALayer *layer = [CALayer layer];
    layer.frame = frame;
    layer.backgroundColor = color.CGColor;
    [parentLayer addSublayer:layer];
}

// create a camra cover to indicate each time taking a photo
- (void)addCameraCover {
    UIView *upView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, APP_SIZE.width, 0)];
    upView.backgroundColor = [UIColor blackColor];
    [self.overlay addSubview:upView];
    self.doneCameraUpView = upView;
    
    UIView *downView = [[UIView alloc] initWithFrame:CGRectMake(0, DEVICE_SIZE.height - CAMERA_MENU_VIEW_HEIGH - 90, APP_SIZE.width, 0)];
    downView.backgroundColor = [UIColor blackColor];
    [self.overlay addSubview:downView];
    self.doneCameraDownView = downView;
}

// camera cover animation
- (void)showCameraCover:(BOOL)toShow {
    
    [UIView animateWithDuration:0.38f animations:^{
        CGRect upFrame = _doneCameraUpView.frame;
        upFrame.size.height = (toShow ? (DEVICE_SIZE.height - CAMERA_MENU_VIEW_HEIGH - 90) / 2:0 );
        _doneCameraUpView.frame = upFrame;
        
        CGRect downFrame = _doneCameraDownView.frame;
        downFrame.origin.y = (toShow ? (DEVICE_SIZE.height - CAMERA_MENU_VIEW_HEIGH - 90)/2 : DEVICE_SIZE.height - CAMERA_MENU_VIEW_HEIGH - 90);
        downFrame.size.height = (toShow ? (DEVICE_SIZE.height - CAMERA_MENU_VIEW_HEIGH - 90) / 2 : 0);
        _doneCameraDownView.frame = downFrame;
    }];
}

#pragma mark Camera buttons actions

//button taking picture
- (void)takePictureBtnPressed: (id) sender{
// if the camera is under photo model
    if (takingPhoto) {
        [self.picker takePicture];
        [self showCameraCover:YES];
        double delayInSeconds = 0.5f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            //sender.userInteractionEnabled = YES;
            [self showCameraCover:NO];
        });
    }
// if the camera is under video model
    else {
        if (recording) {
            [self.caremaBtn setImage:[UIImage imageNamed:@"video.png"] forState:UIControlStateNormal];
            
            [self.picker stopVideoCapture];
            recording = NO;
            sec = 0;
            min = 0;
            hour = 0;
            _topLbl.text = [NSString stringWithFormat:@"%d:%d:%d",hour,min,sec];
            [timer invalidate];
        } else {
            [self.caremaBtn setImage:[UIImage imageNamed:@"videoDone.png"] forState:UIControlStateNormal];
            [self.picker startVideoCapture];
            timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(videotimer) userInfo:nil repeats:YES];
            recording = YES;
        }
        
    }
}

//button "X"
- (void)dismissBtnPressed:(id)sender {

    [self.picker dismissViewControllerAnimated:YES completion:^{
        [timer invalidate];
    }];

}

// taking videos
- (void)VideoBtnPressed:(UIButton*)sender {

    sender.selected = !sender.selected;
    if (takingPhoto) {

    self.picker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
    takingPhoto = NO;
    [self.caremaBtn setImage:[UIImage imageNamed:@"video.png"] forState:UIControlStateNormal];
    _topLbl.text = @"Taking Video";
    NSLog(@"media type %@",self.picker.mediaTypes );
    } else {
            self.picker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil];
            takingPhoto = YES;
            [self.caremaBtn setImage:[UIImage imageNamed:@"shot.png"] forState:UIControlStateNormal];
        _topLbl.text = @"Taking Photo";
    }
}

// set a timer when video starts, to display the time of a video has been taken
-(void)videotimer {
    NSLog(@"timer");
    sec = sec % 60;
    min = sec / 60;
    hour = min / 60;
    dispatch_async(dispatch_get_main_queue(), ^{
    _topLbl.text = [NSString stringWithFormat:@"%d:%d:%d",hour,min,sec];
    });
    sec ++;
    NSLog(@"%d",sec);
}

// button switch fron and back camera
- (void)switchCameraBtnPressed:(UIButton*)sender {
    sender.selected = !sender.selected;
    NSLog(@"input %@",self.inputDevice);
    if (!self.inputDevice) {
        return;
    }

    [self.session beginConfiguration];
    [self.session removeInput:self.inputDevice];
    
    [self addVideoInputFrontCamera:sender.selected];
    [self.session commitConfiguration];
}

- (void)addVideoInputFrontCamera:(BOOL)front {
    
    NSArray *devices = [AVCaptureDevice devices];
    AVCaptureDevice *frontCamera;
    AVCaptureDevice *backCamera;
    
    for (AVCaptureDevice *device in devices) {
        
        NSLog(@"Device name: %@", [device localizedName]);
        
        if ([device hasMediaType:AVMediaTypeVideo]) {
            
            if ([device position] == AVCaptureDevicePositionBack) {
                NSLog(@"Device position : back");
                backCamera = device;
                
            }  else {
                NSLog(@"Device position : front");
                frontCamera = device;
            }
        }
    }
    
    NSError *error = nil;
    
    if (front) {
        AVCaptureDeviceInput *frontFacingCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:frontCamera error:&error];
        NSLog(@"%@",frontFacingCameraDeviceInput);
        if (!error) {
            if ([_session canAddInput:frontFacingCameraDeviceInput]) {
                [_session addInput:frontFacingCameraDeviceInput];
                self.inputDevice = frontFacingCameraDeviceInput;
                
            } else {
                NSLog(@"Couldn't add front facing video input");
            }
        }
    } else {
        AVCaptureDeviceInput *backFacingCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:&error];
        NSLog(@"%@",backFacingCameraDeviceInput);
        if (!error) {
            if ([_session canAddInput:backFacingCameraDeviceInput]) {
                [_session addInput:backFacingCameraDeviceInput];
                self.inputDevice = backFacingCameraDeviceInput;
            } else {
                NSLog(@"Couldn't add back facing video input");
            }
        }
    }
}

// flash light button functions
- (void)flashBtnPressed:(UIButton*)sender {
     [self switchFlashMode:sender];
}

- (void)switchFlashMode:(UIButton*)sender {
    
    NSString *imgStr = @"";
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    [device lockForConfiguration:nil];
    if ([device hasFlash]) {
                if (!sender) {
                    device.flashMode = AVCaptureFlashModeAuto;
                } else {
        if (device.flashMode == AVCaptureFlashModeOff) {
            device.flashMode = AVCaptureFlashModeOn;
            imgStr = @"flashing_on.png";
            
        } else if (device.flashMode == AVCaptureFlashModeOn) {
            device.flashMode = AVCaptureFlashModeAuto;
            imgStr = @"flashing_auto.png";
            
        } else if (device.flashMode == AVCaptureFlashModeAuto) {
            device.flashMode = AVCaptureFlashModeOff;
            imgStr = @"flashing_off.png";
            
        }
                }
        
        if (sender) {
            [sender setImage:[UIImage imageNamed:imgStr] forState:UIControlStateNormal];
        }
        
    }
    [device unlockForConfiguration];
}

@end

