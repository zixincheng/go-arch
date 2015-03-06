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
    //self.netWorkCheck = [[NetWorkCheck alloc] init];
    self.netWorkCheck = [[NetWorkCheck alloc] initWithCoinsorter:self.coinsorter];
    defaults = [NSUserDefaults standardUserDefaults];
    self.devices = [[NSMutableArray alloc] init];
    self.locations = [self.dataWrapper getLocations];
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
    
    [refresh addTarget:self action:@selector(PullTorefresh) forControlEvents:UIControlEventValueChanged];
    
    self.unUploadedThumbnail = [self.dataWrapper getCountUnUploaded];
    self.unUploadedFullPhotos = [self.dataWrapper getFullImageCountUnUploaded];
    
    // setup objects
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    account = appDelegate.account;
    self.localDevice = [self.dataWrapper getDevice:account.cid];
    
    // add the refresh control to the table view
    self.refreshControl = refresh;
    
    // Start networking
    
    // setup network notification
    [self.netWorkCheck setupNet];

    // only ping if we are connected through wifi

    NSLog(@"Cid %@",account.cid);
    
    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changePass) name:@"passwordChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadPhotoChanged:) name:@"addNewPhoto"object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addNewLocation:) name:@"AddLocationSegue"object:nil];
    [defaults addObserver:self forKeyPath:UPLOAD_3G options:NSKeyValueObservingOptionNew context:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateNetWork:) name:@"networkStatusChanged"object:nil];
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    //self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void) updateNetWork: (NSNotification *)notification{
    
    NSString *networkstat = [notification.userInfo objectForKey:@"status"];
     self.networkStatus = networkstat;
    
    if (![networkstat isEqualToString:OFFLINE]) {
        self.canConnect = YES;
        [self updateUploadCountUI];
        if ([networkstat isEqualToString:WIFILOCAL] || [networkstat isEqualToString:WIFIEXTERNAL]) {
            self.unUploadedThumbnail = [self.dataWrapper getCountUnUploaded];
            self.unUploadedFullPhotos = [self.dataWrapper getFullImageCountUnUploaded];
            if (self.unUploadedThumbnail != 0 || self.unUploadedFullPhotos !=0) {
                [self uploadPhotosToApi];
            }
        }
    } else {
        self.canConnect = NO;
        [self updateUploadCountUI];
        
    }
}

-(void) addNewLocation: (NSNotification *)notification{
    
    self.locations = [self.dataWrapper getLocations];
    self.selectedlocation = [notification.userInfo objectForKey:LOCATION];
    loadCamera = 1;
    [self performSegueWithIdentifier:@"individualSegue" sender:self];
    loadCamera = 0;
}


-(void) uploadPhotoChanged: (NSNotification *)notification{
    
    CSPhoto *p = [self.dataWrapper getPhoto:[notification.userInfo objectForKey:IMAGE_URL]];
    if (self.canConnect) {
        [self onePhotoThumbToApi:p];
    }
}

- (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"passwordChanged" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"addNewPhoto" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AddLocationSegue" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"networkStatusChanged" object:nil];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.locations = [self.dataWrapper getLocations];
    [self.tableView reloadData];
    self.unUploadedThumbnail = [self.dataWrapper getCountUnUploaded];
    self.unUploadedFullPhotos = [self.dataWrapper getFullImageCountUnUploaded];
    [self updateUploadCountUI];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Attempt to upload all the time
    if (self.canConnect) {
        if (self.unUploadedFullPhotos !=0 || self.unUploadedThumbnail !=0) {
            //[self uploadPhotosToApi];
        }
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

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:UPLOAD_3G]) {
        BOOL upload3G = [defaults boolForKey:UPLOAD_3G];
        if (upload3G) {
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Warnning" message:@"Uploading photo through 3G will have addition cost of Data, Are you sure?" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            alertView.tag = 2;
            [alertView show];
        }
    }
    
}

-(void) changePass {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Upload Failed" message:@"Password Has been changed, Please Enter New Password" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Confirm", nil];
        
        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        [[alertView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeURL];
        [[alertView textFieldAtIndex:0] becomeFirstResponder];
        alertView.tag =1;
        [alertView show];
    });
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *buttonTitle=[alertView buttonTitleAtIndex:buttonIndex];
    if (alertView.tag == 1) {
        if([buttonTitle isEqualToString:@"Cancel"]) {
            return;
        }
        else if([buttonTitle isEqualToString:@"Confirm"]) {
            NSString *text = [alertView textFieldAtIndex:0].text;
            
            if (![text isEqualToString:@""]) {
                [self.coinsorter getToken:account.currentIp pass:text callback:^(NSDictionary *authData) {
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
    } else if (alertView.tag ==2) {
        if (buttonIndex == 0) {
            [self uploadPhotosToApi];
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
        NSMutableArray *deletePhoto =  [self.dataWrapper getPhotosWithLocation:self.localDevice.remoteId location:[self.locations objectAtIndex:indexPath.row]];
        NSLog(@"delete count %lu",(unsigned long)deletePhoto.count);
        [self deletePhotoFromFile:deletePhoto];
        [self.dataWrapper deleteLocation:[self.locations objectAtIndex:indexPath.row]];
        [self.locations removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
}

- (void) deletePhotoFromFile: (NSArray *) deletedPhoto {
    NSMutableArray *photoPath = [NSMutableArray array];
    NSLog(@"delete count agign %lu",(unsigned long)deletedPhoto.count);
    for (CSPhoto *p in deletedPhoto) {
        // get documents directory
        
        NSURL *imageUrl = [NSURL URLWithString:p.imageURL];
        NSURL *thumUrl = [NSURL URLWithString:p.thumbURL];
        [photoPath addObject:imageUrl.path];
        [photoPath addObject:thumUrl.path];
    }
    for (NSString *currentpath in photoPath) {
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:currentpath error:&error];
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
        
        if (loadCamera == 1) {
            individualViewControll.loadCamera = @"Yes";
        }
        
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


#pragma mark - Button Actions

-(void) addLocationbuttonPressed: (id) sender {
    
    [self performSegueWithIdentifier:@"LocationSettingSegue" sender:self];
}

- (void)uploadBtnPressed:(id)sender {
    if ([self.networkStatus isEqualToString:WWAN]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"You Are Connecting Through WWAN, Upload Full Resolution Will Can Addtion Data Cost, Are You Going TO Upload Anyway?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes", nil];
        alertView.tag = 2;
        [alertView show];
    } else {
        [self uploadPhotosToApi];
    }
}

#pragma mark - ui
- (void) updateUploadCountUI {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *title;
        
        if (!self.canConnect) {
            title = @"Cannot Connect";
        }else if (self.unUploadedThumbnail == 0 && self.unUploadedFullPhotos ==0) {
            title = @"Nothing to Upload";
            
        }else if (self.currentlyUploading) {
            title = [NSString stringWithFormat:@"Uploading %d thumbnials and %d photos", self.unUploadedThumbnail,self.unUploadedFullPhotos];
            
        } else if (self.unUploadedThumbnail == 0 && self.unUploadedFullPhotos !=0) {
            title = [NSString stringWithFormat:@"Upload %d thumbnials and %d photos", self.unUploadedThumbnail,self.unUploadedFullPhotos];
            [self.btnUpload setEnabled:NO];
        } else {
            title = [NSString stringWithFormat:@"Upload %d thumbnials and %d photos", self.unUploadedThumbnail,self.unUploadedFullPhotos];
            
        }
        
        if (self.canConnect) {
            if ([self.networkStatus isEqualToString:WIFIEXTERNAL]) {
                title = [NSString stringWithFormat:@"%@ (WIFIEXTERNAL)",title];
            } else if ([self.networkStatus isEqualToString:WIFILOCAL]) {
                title = [NSString stringWithFormat:@"%@ (WIFILOCAL)",title];
            }
            else {
                title = [NSString stringWithFormat:@"%@ (WWAN)",title];
            }
        }else {
            //UIColor * color = [UIColor colorWithRed:212/255.0f green:1/255.0f blue:0/255.0f alpha:1.0f];
            //[self.progressUpload setTintColor:color];
        }
        [self.btnUpload setTitle:title];
        
        if ((self.unUploadedThumbnail == 0  && self.unUploadedFullPhotos ==0) || self.currentlyUploading || !self.canConnect ){
            [self.btnUpload setEnabled: NO];
        }else {
            [self.btnUpload setEnabled: NO];
        }
    });
}


- (void) removeThumbnail {
    self.unUploadedThumbnail--;
    [self updateUploadCountUI];
}

-(void) removeFullPhoto {
    self.unUploadedFullPhotos--;
    [self updateUploadCountUI];
}

#pragma mark - upload function

- (void) onePhotoThumbToApi:(CSPhoto *)photo {
    __block int currentthumbnailUploaded = 0;
    __block int currentFullPhotoUploaded = 0;
    [self updateUploadCountUI];
    self.currentlyUploading = YES;
    // hide upload button tool bar and show progress on
    [self.btnUpload setEnabled:NO];
    BOOL upload3G = [defaults boolForKey:UPLOAD_3G];
    [self.coinsorter uploadOneThumb:photo upCallback:^(CSPhoto *p){
        NSLog(@"removete id %@", p.remoteID );
        if (p.tag != nil) {
            [self.coinsorter updateMeta:p entity:@"tag" value:p.tag];
            NSLog(@"updating the tags");
        }
        currentthumbnailUploaded += 1;
        self.unUploadedThumbnail = [self.dataWrapper getCountUnUploaded];
        dispatch_async(dispatch_get_main_queue(), ^{

                [self updateUploadCountUI];
                [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
            
        });
        if ([self.networkStatus isEqualToString:WIFIEXTERNAL] || [self.networkStatus isEqualToString:WIFILOCAL]) {
            [self.coinsorter uploadOnePhoto:p upCallback:^{
                currentFullPhotoUploaded +=1;
                self.unUploadedFullPhotos = [self.dataWrapper getFullImageCountUnUploaded];
                dispatch_async(dispatch_get_main_queue(), ^{

                        [self updateUploadCountUI];
                        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
                    
                });
                
                NSLog(@"upload full res image");
            }];
        } else {
            if (upload3G) {
                [self.coinsorter uploadOnePhoto:p upCallback:^{
                    currentFullPhotoUploaded +=1;
                    self.unUploadedFullPhotos = [self.dataWrapper getFullImageCountUnUploaded];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        float progress = (float) currentFullPhotoUploaded / 1;
                        if (progress == 1.0) {
                            self.currentlyUploading = NO;
                            [self updateUploadCountUI];
                            [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
                            
                        }
                    });
                    
                    NSLog(@"upload full res image using 3G");
                }];
                
            } else {
                NSLog(@"dont upload full res because it using 3g");
            }
        }
    }];
}
- (void) uploadPhotosToApi {
    NSMutableArray *thumbPhotos = [self.dataWrapper getPhotosToUpload];
    NSMutableArray *fullPhotos = [self.dataWrapper getFullSizePhotosToUpload];
    BOOL upload3G = [defaults boolForKey:UPLOAD_3G];
    NSLog(@"unupload full image %d",self.unUploadedFullPhotos);
    
    self.unUploadedThumbnail = [self.dataWrapper getCountUnUploaded];
    __block int currentthumbnailUploaded = 0;
    __block int currentFullPhotoUploaded = 0;
    if (thumbPhotos.count > 0) {
        //sent a notification when start uploading photos
        [[NSNotificationCenter defaultCenter] postNotificationName:@"startUploading" object:nil];
        self.currentlyUploading = YES;
        // hide upload button tool bar and show progress on
        [self.btnUpload setEnabled:NO];
        //[self.progressUpload setProgress:0.0 animated:YES];
        
        [self updateUploadCountUI];
        
        NSLog(@"there are %lu thumbnails to upload", (unsigned long)thumbPhotos.count);
        [self.coinsorter uploadPhotoThumb:thumbPhotos upCallback:^(CSPhoto *p) {
            
            NSLog(@"removete id %@", p.remoteID );
            if (p.tag != nil) {
                [self.coinsorter updateMeta:p entity:@"tag" value:p.tag];
                NSLog(@"updating the tags");
            }
            currentthumbnailUploaded += 1;
            self.unUploadedThumbnail = [self.dataWrapper getCountUnUploaded];
            dispatch_async(dispatch_get_main_queue(), ^{
                float progress = (float) currentthumbnailUploaded / 1;
                if (progress == 1.0) {
                    self.currentlyUploading = NO;
                    [self updateUploadCountUI];
                    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
                    
                }
            });
            if ([self.networkStatus isEqualToString:WIFIEXTERNAL] || [self.networkStatus isEqualToString:WIFILOCAL]) {
                [self.coinsorter uploadOnePhoto:p upCallback:^{
                    currentFullPhotoUploaded +=1;
                    self.unUploadedFullPhotos = [self.dataWrapper getFullImageCountUnUploaded];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        float progress = (float) currentFullPhotoUploaded / 1;
                        if (progress == 1.0) {
                            self.currentlyUploading = NO;
                            [self updateUploadCountUI];
                            [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
                            
                        }
                    });
                    
                    NSLog(@"upload full res image");
                }];
            } else {
                if (upload3G) {
                    [self.coinsorter uploadOnePhoto:p upCallback:^{
                        currentFullPhotoUploaded +=1;
                        self.unUploadedFullPhotos = [self.dataWrapper getFullImageCountUnUploaded];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            float progress = (float) currentFullPhotoUploaded / 1;
                            if (progress == 1.0) {
                                self.currentlyUploading = NO;
                                [self updateUploadCountUI];
                                [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
                                
                            }
                        });
                        
                        NSLog(@"upload full res image using 3G");
                    }];
                } else {
                    NSLog(@"dont upload full res because it using 3g");
                }
            }
        }];
    } else if (thumbPhotos.count ==0 && fullPhotos.count >0) {
        if ([self.networkStatus isEqualToString:WIFIEXTERNAL] || [self.networkStatus isEqualToString:WIFILOCAL] || upload3G) {
            for (CSPhoto *p in fullPhotos) {
                [self.coinsorter uploadOnePhoto:p upCallback:^{
                    currentFullPhotoUploaded +=1;
                    self.unUploadedFullPhotos = [self.dataWrapper getFullImageCountUnUploaded];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        float progress = (float) currentFullPhotoUploaded / 1;
                        if (progress == 1.0) {
                            self.currentlyUploading = NO;
                            [self updateUploadCountUI];
                            [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
                            
                        }
                    });
                    NSLog(@"upload full res image");
                }];
            }
        } else {
            NSLog(@"dont upload full res because it using 3g");
        }
    } else {
        
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
