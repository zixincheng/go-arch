//
// DeviceViewController.m
//  Go Angel
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.

#import "DeviceViewController.h"

@implementation DeviceViewController

#pragma mark - NSUserDefaults Constants

#define IMAGE_VIEW_TAG 11
#define GRID_CELL      @"gridCell"
#define SINGLE_PHOTO_SEGUE @"singleImageSegue"

#pragma mark -
#pragma mark Initialization


- (void)segmentChange {
  [self.tableView reloadData];
}

#pragma mark -
#pragma mark View

- (void)viewDidLoad {
  [super viewDidLoad];
    
    self.valueSwirly.font            = [UIFont fontWithName:@"Futura-Medium" size:30.0];
    self.valueSwirly.thickness       = 30.0f;
    self.valueSwirly.shadowOffset    = CGSizeMake(1,1);

    self.valueSwirly.textColor       = [UIColor whiteColor];
    self.valueSwirly.shadowColor     = [UIColor blackColor];
    [self.valueSwirly addThreshold:0
                    withColor:[UIColor yellowColor]
                          rpm:0
                        label:@"Waiting"
                     segments:5];
    [self.valueSwirly addThreshold:1
                         withColor:[UIColor greenColor]
                               rpm:20
                             label:@"Uploading"
                          segments:5];
    [self.valueSwirly addThreshold:2
                         withColor:[UIColor redColor]
                               rpm:0
                             label:@"Done"
                          segments:100];
    self.valueSwirly.value = 2;
    //[self didChangeValue:self.valueSlider];
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
 //UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
  needParse = NO;
  self.currentlyUploading = NO;
  
  // setup objects
  AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
  account = appDelegate.account;
  self.localDevice = [self.dataWrapper getDevice:account.cid];
 // refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Fetch Photos"];
  //[refresh addTarget:self action:@selector(syncAllFromApi) forControlEvents:UIControlEventValueChanged];
  //self.refreshControl = refresh;

  // get count of unuploaded photos
  self.unUploadedPhotos = [self.dataWrapper getCountUnUploaded];
  self.photos =  [self.dataWrapper getPhotos:self.localDevice.remoteId];
    
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
  
  // notification so we know when app comes into foreground
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
  
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
  
    //[self addStatusButton];
  // update ui status bar
  [self updateUploadCountUI];
  [self checkDeivceStatus];

}
// called when this controller leaves memory
// we need to stop observing asset library and defaults
- (void) dealloc {
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
  }
}

- (IBAction)buttonPressed:(id)sender {
  if (sender == self.btnUpload) {
    [self uploadPhotosToApi];
  }else if (sender == self.btnCamera) {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    [self presentViewController:picker animated:YES completion:nil];
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
  [super viewWillAppear:animated];
  //    self.navigationController.navigationBar.barTintColor = [UIColor greenColor];
  //    self.navigationController.navigationBar.translucent = NO;
  //    [self.navigationController setNavigationBarHidden:YES animated:YES];
  
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
        self.valueSwirly.value = 2;
        [self checkDeivceStatus];
    }else if (self.currentlyUploading) {
      title = [NSString stringWithFormat:@"Uploading %d Photos", self.unUploadedPhotos];
        self.valueSwirly.value = 1;
        [self checkDeivceStatus];
    }else {
      title = [NSString stringWithFormat:@"Upload %d Photos", self.unUploadedPhotos];
        [self checkDeivceStatus];
        self.valueSwirly.value = 0;
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

// get devices, photos, and upload from server
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
    self.currentlyUploading = YES;
    // hide upload button tool bar and show progress on
    [self.btnUpload setEnabled:NO];
    [self.progressUpload setProgress:0.0 animated:YES];
    
    [self updateUploadCountUI];
    
    NSLog(@"there are %lu photos to upload", (unsigned long)photos.count);
    [self.coinsorter uploadPhotos:photos upCallback:^() {
    //sent a notification to dashboard when finish uploading 1 photo
    [[NSNotificationCenter defaultCenter] postNotificationName:@"photoUploading" object:nil];
      currentUploaded += 1;
      
      [self removeLocalPhoto];
      
      NSLog(@"%d / %lu", currentUploaded, (unsigned long)photos.count);
      
      // update progress bar on main thread
      dispatch_async(dispatch_get_main_queue(), ^{
        float progress = (float) currentUploaded / (float) photos.count;
        
        [self.progressUpload setProgress:progress animated:YES];
      
        // the upload is complete
        if (progress == 1.0) {
          [self.btnUpload setEnabled:YES];
          self.currentlyUploading = NO;
          [self updateUploadCountUI];
           //sent a notification to dashboard when finish uploading all photos 
          [[NSNotificationCenter defaultCenter] postNotificationName:@"waitingForPhoto" object:nil];
          // allow app to sleep again
          [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
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
        cell.textLabel.text = [NSString stringWithFormat:@"Photos Progress: %d / %d", self.totalUploadedPhotos,self.totalPhotos];
    }else if (indexPath.row == 1){
        cell.textLabel.text = [NSString stringWithFormat:@"Server Name: %@",account.name];
    }else if (indexPath.row == 2){
        cell.textLabel.text = [NSString stringWithFormat:@"Server IP: %@",account.ip];
    }else if (indexPath.row == 3){
        cell.textLabel.text = [NSString stringWithFormat:@"Uploading Status: %@",self.currentStatus];
    }else if (indexPath.row == 4){
        cell.textLabel.text = [NSString stringWithFormat:@"Home Server: %@", self.homeServer];
    }
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
        return 35;
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
  
  [picker dismissViewControllerAnimated:YES completion:^{
    // picker disappeared
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    NSDictionary *metadata = info[UIImagePickerControllerMediaMetadata];
    
    [localLibrary saveImage:image metadata:metadata];

  }];
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
    if (account.ip != nil) {
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

//create a status button in navigation bar programmatically
/*
- (void) addStatusButton{
    statusButton = [[UIBarButtonItem alloc] initWithTitle:@"Status" style:UIBarButtonItemStylePlain target:self action:@selector(presentDashboardView:)];
    NSArray *rightButtonItems = [[NSArray alloc] initWithObjects:settingButton,statusButton,nil];
    
    [self.navigationItem setRightBarButtonItems:rightButtonItems animated:YES];
}
*/
//display app status information on dashboard
/*
- (void)presentDashboardView:(id)sender{
    //[self uploadPhotosStatus];
    //[self currentUploadingStatus];
    //[self homeServerStatus];
    [self checkDeivceStatus];
    
    DashboardViewController *dashboardVC = [[DashboardViewController alloc] init];
    dashboardVC.title = @"DashBoard";
    dashboardVC.totalPhotos = self.totalPhotos;
    dashboardVC.processedUploadedPhotos = self.totalUploadedPhotos;
    dashboardVC.currentStatus = self.currentStatus;
    dashboardVC.homeServer = self.homeServer;
    dashboardVC.serverName = self.serverName;
    dashboardVC.serverIP = self.serverIP;
    
    [self.navigationController pushViewController:dashboardVC animated:YES];
}
*/
- (void)checkDeivceStatus{
    NSMutableArray *photos = [self.dataWrapper getPhotos:self.localDevice.remoteId];
    self.totalUploadedPhotos = [self.dataWrapper getCountUploaded:self.localDevice.remoteId];
    self.totalPhotos = photos.count;
    
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
        self.serverIP = account.ip;
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
            [imageView setImage:image];
            
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
/*
-(void) addNewcell: (CSPhoto *)photos{
    
    long Size = self.photos.count;
    [self.collectionView performBatchUpdates:^{
        
        [self.photos addObject:photos];
        NSMutableArray *arrayWithIndexPaths = [NSMutableArray array];
        
        [arrayWithIndexPaths addObject:[NSIndexPath indexPathForRow:Size inSection:0]];
        
        [self.collectionView insertItemsAtIndexPaths:arrayWithIndexPaths];
    }completion:nil];
}
*/
- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:SINGLE_PHOTO_SEGUE]) {
        PhotoSwipeViewController *swipeController = (PhotoSwipeViewController *) segue.destinationViewController;
        swipeController.selected = selected;
        swipeController.photos = self.photos;

    }
}
-(void)pushNotificationReceived{
    NSLog(@"recieved notification");
    [self performSegueWithIdentifier:@"pushNotification" sender:self];

}

@end

