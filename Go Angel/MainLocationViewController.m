//
//  MainLocationViewController.m
//  Go Angel
//
//  Created by zcheng on 2015-01-22.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "MainLocationViewController.h"

@interface MainLocationViewController ()

@end

@implementation MainLocationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //init search controller
    UINavigationController *searchResultsController = [[self storyboard] instantiateViewControllerWithIdentifier:@"TableSearchResultsNavController"];
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:searchResultsController];
    self.searchController.searchResultsUpdater = self;
    
    self.searchController.searchBar.frame = CGRectMake(self.searchController.searchBar.frame.origin.x, self.searchController.searchBar.frame.origin.y, self.searchController.searchBar.frame.size.width, 44.0);
    self.tableView.tableHeaderView = self.searchController.searchBar;
    
    self.definesPresentationContext = YES;
    
    //init ui navigation buttons parts
    UIBarButtonItem * searchBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(showSearch:)];
    UIBarButtonItem * addLocationBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addLocationbuttonPressed:)];
    self.navigationItem.rightBarButtonItem = addLocationBtn;
    NSArray *rightButtonItems = [[NSArray alloc]initWithObjects:searchBtn, addLocationBtn, nil];
    [self.navigationItem setRightBarButtonItems:rightButtonItems];
    [self.navigationController setToolbarHidden:NO];
    self.btnUpload = [[UIBarButtonItem alloc]initWithTitle:@"Nothing to upload" style:UIBarButtonItemStylePlain target:self action:@selector(uploadBtnPressed:)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    self.toolbarItems = [NSArray arrayWithObjects:flexibleSpace, self.btnUpload, flexibleSpace, nil];
    
    // init vars
    self.dataWrapper = [[CoreDataWrapper alloc] init];
    self.coinsorter = [[Coinsorter alloc] initWithWrapper:self.dataWrapper];
    localLibrary = [[LocalLibrary alloc] init];
    defaults = [NSUserDefaults standardUserDefaults];
    self.devices = [[NSMutableArray alloc] init];
    self.locations = [self.dataWrapper getLocations];
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
    
    [refresh addTarget:self action:@selector(PullTorefresh) forControlEvents:UIControlEventValueChanged];
    
    self.unUploadedPhotos = [self.dataWrapper getCountUnUploaded];
    
    // setup objects
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    account = appDelegate.account;
    self.localDevice = [self.dataWrapper getDevice:account.cid];
    
    
    // add the refresh control to the table view
    self.refreshControl = refresh;
    
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
                //[self syncAllFromApi];
                NSLog(@"can connect to server");
            }
        }];
    }else {
        self.canConnect = NO;
        NSLog(@"cannot connect to server");
    }

    NSLog(@"Cid %@",account.cid);
    
    // Uncomment the following line to preserve selection between presentations.
     self.clearsSelectionOnViewWillAppear = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changePass) name:@"passwordChanged" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadPhotoChanged) name:@"coredataDone" object:nil];
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
     //self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void) uploadPhotoChanged {
    
    self.unUploadedPhotos = [self.dataWrapper getCountUnUploaded];
    if (self.canConnect) {
        [self uploadPhotosToApi];
    }
    [self updateUploadCountUI];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.locations = [self.dataWrapper getLocations];
    [self.tableView reloadData];
    self.unUploadedPhotos = [self.dataWrapper getCountUnUploaded];
    [self updateUploadCountUI];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Attempt to upload all the time
    if (self.canConnect) {
        //[self uploadPhotosToApi];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) PullTorefresh {
    
    [self.tableView reloadData];
    
   [self.refreshControl endRefreshing];
    
}

-(void) changePass {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Upload Failed" message:@"Password Has been changed, Please Enter New Password" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Confirm", nil];
        
        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        [[alertView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeURL];
        [[alertView textFieldAtIndex:0] becomeFirstResponder];
        
        [alertView show];
    });
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *buttonTitle=[alertView buttonTitleAtIndex:buttonIndex];
    if([buttonTitle isEqualToString:@"Cancel"]) {
        return;
    }
    else if([buttonTitle isEqualToString:@"Confirm"]) {
        NSString *text = [alertView textFieldAtIndex:0].text;
        
        if (![text isEqualToString:@""]) {
            [self.coinsorter getToken:account.ip pass:text callback:^(NSDictionary *authData) {
                if (authData == nil || authData == NULL) {
                    // we could not connect to server
                    NSLog(@"could not connect to server");
                    return;
                }
                
                NSString *token = [authData objectForKey:@"token"];
                if (token == nil || token == NULL) {
                    // if we get here we assume the password is incorrect
                    NSLog(@"password incorrect");
                    return;
                }
                account.token = token;
                [account saveSettings];
                [self uploadPhotosToApi];
                [defaults setObject:text forKey:@"password"];
            }];
        }
    }
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    // Return the number of rows in the section.
    return self.locations.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"LocationCell"];
    //[tableView dequeueReusableCellWithIdentifier:@"LocationCell" forIndexPath:indexPath];
    
    CSLocation *l = self.locations[[indexPath row]];
    CSPhoto *photo;
    self.photos = [self.dataWrapper getPhotosWithLocation:self.localDevice.remoteId location:l];
    UIImage *defaultImage = [UIImage imageNamed:@"box.png"];
    cell.imageView.image = defaultImage;
    if (self.photos.count != 0) {
        photo = [self.dataWrapper getCoverPhoto:self.localDevice.remoteId location:l];
        if (photo == nil) {
            photo = [self.photos objectAtIndex:0];
        }
        AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        [appDelegate.mediaLoader loadThumbnail:photo completionHandler:^(UIImage *image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.imageView.image = image;
            });
        }];
    }
    if (![l.unit isEqualToString:@""]) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@",l.unit, l.name];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@",l.city,l.province];
    } else {
        cell.textLabel.text = l.name;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@",l.city,l.province];
    // Configure the cell...
    }


    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    self.selectedlocation = self.locations[[indexPath row]];
    [self performSegueWithIdentifier:@"individualSegue" sender:self];
    
    // Deselect
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [self.dataWrapper deleteLocation:[self.locations objectAtIndex:indexPath.row]];
        [self.locations removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void) showSearch: (id) sender {
    [self performSegueWithIdentifier:@"searchSegue" sender:self];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"individualSegue"]) {
        
        IndividualEntryViewController *individualViewControll = (IndividualEntryViewController *)segue.destinationViewController;
        
        individualViewControll.dataWrapper = self.dataWrapper;
        individualViewControll.localDevice = self.localDevice;
        individualViewControll.location = self.selectedlocation;
        individualViewControll.coinsorter = self.coinsorter;
        
        NSString *title;
        if (![self.selectedlocation.unit isEqualToString:@""]) {
            title = [NSString stringWithFormat:@"%@ - %@",self.selectedlocation.unit, self.selectedlocation.name];
        } else {
            title = [NSString stringWithFormat:@"%@", self.selectedlocation.name];
        }
        individualViewControll.navigationItem.title = title;
        

    } else if ([segue.identifier isEqualToString:@"searchSegue"]) {
        
        SearchMapViewController *searchVC = (SearchMapViewController *)segue.destinationViewController;
        searchVC.dataWrapper = self.dataWrapper;
        searchVC.localDevice = self.localDevice;
        
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


// get the current wifi bssid (network id)

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
        //[[NSNotificationCenter defaultCenter] postNotificationName:@"homeServerDisconnected" object:nil];
        self.canConnect = NO;
        [self updateUploadCountUI];
    }else if (remoteHostStatus == ReachableViaWiFi) {
        // if we are connected to wifi
        // and we have a blackbox ip we have connected to before
        if (account.ip != nil) {
            [self.coinsorter pingServer:^(BOOL connected) {
                self.canConnect = connected;
                if (self.canConnect && self.unUploadedPhotos !=0) {
                    [self uploadPhotosToApi];
                }
                //sent a notification to dashboard when network connects with home server
                //[[NSNotificationCenter defaultCenter] postNotificationName:@"homeServerConnected" object:nil];
                [self updateUploadCountUI];
            }];
        }
    }else if (remoteHostStatus == ReachableViaWWAN) {
        NSLog(@"wwan");
        //sent a notification to dashboard when network connects with WIFI not home server
        //[[NSNotificationCenter defaultCenter] postNotificationName:@"homeServerDisconnected" object:nil];
        self.canConnect = NO;
        [self updateUploadCountUI];
    }
}


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

#pragma mark - Button Actions

-(void) addLocationbuttonPressed: (id) sender {
    
    [self performSegueWithIdentifier:@"LocationSettingSegue" sender:self];
}

- (void)uploadBtnPressed:(id)sender {
        [self uploadPhotosToApi];
}

#pragma mark - ui
- (void) updateUploadCountUI {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *title;
        
        if (!self.canConnect) {
            title = @"Cannot Connect";
        }else if (self.unUploadedPhotos == 0) {
            title = @"Nothing to Upload";

        }else if (self.currentlyUploading) {
            title = [NSString stringWithFormat:@"Uploading %d Photos", self.unUploadedPhotos];

        }else {
            title = [NSString stringWithFormat:@"Upload %d Photos", self.unUploadedPhotos];

        }
        [self.btnUpload setTitle:title];
        
        if (self.canConnect) {
            //[self.progressUpload setTintColor:nil];
        }else {
            //UIColor * color = [UIColor colorWithRed:212/255.0f green:1/255.0f blue:0/255.0f alpha:1.0f];
            //[self.progressUpload setTintColor:color];
        }
        
        if (self.unUploadedPhotos == 0 || self.currentlyUploading || !self.canConnect) {
            [self.btnUpload setEnabled: NO];
        }else {
            [self.btnUpload setEnabled: YES];
        }
    });
}

- (void) removeLocalPhoto {
    self.unUploadedPhotos--;
    [self updateUploadCountUI];
}

- (void) uploadPhotosToApi {
    NSMutableArray *photos = [self.dataWrapper getPhotosToUpload];
    self.unUploadedPhotos = [self.dataWrapper getCountUnUploaded];
    __block int currentUploaded = 0;
    if (photos.count > 0) {
        //sent a notification when start uploading photos
        [[NSNotificationCenter defaultCenter] postNotificationName:@"startUploading" object:nil];
        self.currentlyUploading = YES;
        // hide upload button tool bar and show progress on
        [self.btnUpload setEnabled:NO];
        //[self.progressUpload setProgress:0.0 animated:YES];
        
        [self updateUploadCountUI];
        
        NSLog(@"there are %lu photos to upload", (unsigned long)photos.count);
        [self.coinsorter uploadPhotos:photos upCallback:^(CSPhoto *p) {
            
            NSLog(@"removete id %@", p.remoteID );
            currentUploaded += 1;
/*            if ([p.isVideo isEqualToString:@"1"]) {
                [self.coinsorter uploadVideoThumb:p];
                NSLog(@"uploading the video thumbnails");
            } else {
                [self.coinsorter uploadPhotoThumb:p];
                NSLog(@"uploading the photo thumbnails");
            }
  */
            if (p.tag != nil) {
                [self.coinsorter updateMeta:p entity:@"tag" value:p.tag];
                NSLog(@"updating the tags");
            }
            [self removeLocalPhoto];
            
            NSLog(@"%d / %lu", currentUploaded, (unsigned long)photos.count);
            
            // update progress bar on main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                float progress = (float) currentUploaded / (float) photos.count;
                
                //[self.progressUpload setProgress:progress animated:YES];
                
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
                   // NSString *message = [NSString stringWithFormat: @"App uploads %lu photo to Arch Box",(unsigned long)photos.count];
                    //log.activityLog = message;
                    //log.timeUpdate = [NSDate date];
                   // [self.dataWrapper addUpdateLog:log];
                }
            });
        }];
    }else {
        NSLog(@"there are no photos to upload");
    }
}

#pragma mark - UISearchResultsUpdating

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    
    NSString *searchString = [self.searchController.searchBar text];
    
    [self searchForAddress:searchString];
    
    if (self.searchController.searchResultsController) {
        UINavigationController *navController = (UINavigationController *)self.searchController.searchResultsController;
        
        SearchResultsTableViewController *vc = (SearchResultsTableViewController *)navController.topViewController;
        vc.searchResults = self.searchResults;
        vc.localDevice = self.localDevice;
        vc.dataWrapper = self.dataWrapper;
        vc.selectedlocation = self.selectedlocation;
        
        [vc.tableView reloadData];
    }
    
}

#pragma mark - Content Filtering

- (void)searchForAddress:(NSString *)address {
    

    if ((address == nil) || [address length] == 0) {

        self.searchResults = [self.locations mutableCopy];
        return;
    } else {
        [self.searchResults removeAllObjects]; // First clear the filtered array.
        
        for (CSLocation *locaion in self.locations) {
            NSUInteger searchOptions = NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch;
            NSRange addressRange = NSMakeRange(0, locaion.name.length);
            NSRange unitRange = NSMakeRange(0, locaion.unit.length);
            NSRange foundNameRange = [locaion.name rangeOfString:address options:searchOptions range:addressRange];
            NSRange foundUnitRange = NSRangeFromString(@"");
            if (![locaion.unit isEqualToString:@""]) {
                foundUnitRange= [locaion.unit rangeOfString:address options:searchOptions range:unitRange];
            }
            if ((foundNameRange.length > 0) || (foundUnitRange.length > 0)) {
                [self.searchResults addObject:locaion];
            }
        }
    }
}


@end
