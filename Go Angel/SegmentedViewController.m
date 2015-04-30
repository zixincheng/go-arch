//
//  SegmentedViewController.m
//  
//
//  Created by zcheng on 2015-03-18.
//
//

#import "SegmentedViewController.h"
#import "FilterTableViewController.h"
#import <stdlib.h>


#define SORTNAME @"sortName"
#define SORTPRICEHIGH @"sortPriceHigh"
#define SORTPRICELOW @"sortPriceLow"

@interface SegmentedViewController () <DBRestClientDelegate>

- (UIViewController *)viewControllerForSegmentIndex:(NSInteger)index;

@end

@implementation SegmentedViewController {
    BOOL deleteRaw;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self restClient];
                                                                
    // Do any additional setup after loading the view.
    // init vars
    appDelegate = [[UIApplication sharedApplication] delegate];
    account = appDelegate.account;
    self.dataWrapper = appDelegate.dataWrapper;
    self.coinsorter = appDelegate.coinsorter;
    self.localDevice = [self.dataWrapper getDevice:account.cid];
    self.netWorkCheck = appDelegate.netWorkCheck;
    self.uploadFunction = [[UploadFunctions alloc]init];
    defaults = [NSUserDefaults standardUserDefaults];
    self.albums = [self.dataWrapper getAllAlbums];
    
    if (self.albums.count ==0) {
        self.dropbox = [[CSAlbum alloc]init];
        CSEntry *dropentry = [[CSEntry alloc]init];
        self.dropbox.entry = dropentry;
        CSLocation *droplocation = [[CSLocation alloc]init];
        self.dropbox.entry.location = droplocation;
        self.dropbox.name = @"DropBox";
        [self getCurrentLocation];
        //[self.dataWrapper addAlbum:self.dropbox];
    } else {
        self.dropbox = [self.albums objectAtIndex:0];
    }
    
    self.saveFunction = [[SaveToDocument alloc]init];
    // setup network notification
    [self.netWorkCheck setupNet];
    
    [self getViewController];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changePass) name:@"passwordChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadPhotoChanged:) name:@"addNewPhoto"object:nil];
    [defaults addObserver:self forKeyPath:UPLOAD_3G options:NSKeyValueObservingOptionNew context:NULL];
    [defaults addObserver:self forKeyPath:DELETE_RAW options:NSKeyValueObservingOptionNew context:NULL];
    [defaults addObserver:self forKeyPath:DEVICE_NAME options:NSKeyValueObservingOptionNew context:NULL];
    [defaults addObserver:self forKeyPath:IMPORT_DROPBOX options:NSKeyValueObservingOptionNew context:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateNetWork:) name:@"networkStatusChanged"object:nil];
    
    [self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    if (filterFlag != 1) {
        self.albums = [self.dataWrapper getAllAlbums];
    }
    if (sortFlag != nil) {
        [self sortarrays:sortFlag];
    } else {
    [self getViewController];
    }
}

- (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"passwordChanged" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"addNewPhoto" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"networkStatusChanged" object:nil];
}


- (IBAction)segmentChanged:(UISegmentedControl *)sender {
    UIViewController *vc = [self viewControllerForSegmentIndex:sender.selectedSegmentIndex];
    [self addChildViewController:vc];
    [self transitionFromViewController:self.currentViewController toViewController:vc duration:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.currentViewController.view removeFromSuperview];
        vc.view.frame = self.containerView.bounds;

        [self.view addSubview:vc.view];
    } completion:^(BOOL finished) {
        [vc didMoveToParentViewController:self];
        [self.currentViewController removeFromParentViewController];
        self.currentViewController = vc;
    }];
    self.navigationItem.title = vc.title;
}

- (UIViewController *)viewControllerForSegmentIndex:(NSInteger)index {
    UIViewController *vc;
    MainLocationViewController *mainvc;
    SearchMapViewController *mapvc;
    LargePhotoViewContoller *largevc;
    if (self.canConnect) {
        [self.coinsorter getAlbumInfo:@"0"];
    }
    self.albums = [self.dataWrapper getAllAlbums];
    
    if (sortFlag !=nil) {
        self.albums = [NSMutableArray arrayWithArray:self.sortArray];
    }
    if (filterFlag == 1) {
        self.albums = [NSMutableArray arrayWithArray:self.filterArray];
    }

    switch (index) {
        case 0:
            mainvc = (MainLocationViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"mainLocationViewController"];
            mainvc.albums = self.albums;
            vc = mainvc;
            break;
        case 1:
            mapvc = (SearchMapViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"MapView"];
            mapvc.albums = self.albums;
            vc = mapvc;
            break;
        case 2:
            largevc = (LargePhotoViewContoller *)[self.storyboard instantiateViewControllerWithIdentifier:@"LargePhotoViewContoller"];
            largevc.albums = self.albums;
            vc = largevc;
            break;
    }
    return vc;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - server password changed notification

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
                    [self.uploadFunction uploadPhotosToApi:self.networkStatus];
                    [defaults setObject:text forKey:@"password"];
                }];
            }
        }
    } else if (alertView.tag ==2) {
        if (buttonIndex == 0) {
            [self.uploadFunction uploadPhotosToApi:self.networkStatus];
        }
    }
}

#pragma mark - network check notification

-(void) updateNetWork: (NSNotification *)notification{
    
    NSString *networkstat = [notification.userInfo objectForKey:@"status"];
    self.networkStatus = networkstat;
    
    if (![networkstat isEqualToString:OFFLINE]) {
        self.canConnect = YES;
        if ([networkstat isEqualToString:WIFILOCAL] || [networkstat isEqualToString:WIFIEXTERNAL]) {
            //int unUploadedThumbnail = [self.dataWrapper getCountUnUploaded];
            //int unUploadedFullPhotos = [self.dataWrapper getFullImageCountUnUploaded];
            NSMutableArray *unUploadarray = [self.dataWrapper getAlbumsToUpload];
            NSMutableArray *alreadyUploaded = [self.dataWrapper getAlbumsAlreadyUploaded];
            for (CSAlbum *a in unUploadarray) {
                
                    [self.coinsorter createAlbum:a callback:^(NSString *album_id) {
                        if (album_id !=nil) {
                            NSMutableArray *unuploadphotos = [self.dataWrapper getThumbsToUploadWithAlbum:self.localDevice.remoteId album:a];
                            for (CSPhoto *p in unuploadphotos) {
                                [self.uploadFunction onePhotoThumbToApi:p networkStatus:self.networkStatus];
                            }
                        }
                    }];
                }

            for (CSAlbum *a in alreadyUploaded) {
                NSMutableArray *unuploadphotos = [self.dataWrapper getThumbsToUploadWithAlbum:self.localDevice.remoteId album:a];
                for (CSPhoto *p in unuploadphotos) {
                    [self.uploadFunction onePhotoThumbToApi:p networkStatus:self.networkStatus];
                }

            }
        }
    } else {
        self.canConnect = NO;
    }
}
#pragma mark - upload one photo notification from coredata

-(void) uploadPhotoChanged: (NSNotification *)notification{
    if (notification.userInfo == nil) {
        NSMutableArray *unUploadarray = [self.dataWrapper getAlbumsToUpload];
        NSMutableArray *alreadyUploaded = [self.dataWrapper getAlbumsAlreadyUploaded];
        for (CSAlbum *a in unUploadarray) {
            
            [self.coinsorter createAlbum:a callback:^(NSString *album_id) {
                if (album_id !=nil) {
                    NSMutableArray *unuploadphotos = [self.dataWrapper getThumbsToUploadWithAlbum:self.localDevice.remoteId album:a];
                    for (CSPhoto *p in unuploadphotos) {
                        [self.uploadFunction onePhotoThumbToApi:p networkStatus:self.networkStatus];
                    }
                }
            }];
        }
        
        for (CSAlbum *a in alreadyUploaded) {
            NSMutableArray *unuploadphotos = [self.dataWrapper getThumbsToUploadWithAlbum:self.localDevice.remoteId album:a];
            for (CSPhoto *p in unuploadphotos) {
                [self.uploadFunction onePhotoThumbToApi:p networkStatus:self.networkStatus];
            }
            
        }
    } else {
    CSPhoto *p = [self.dataWrapper getPhoto:[notification.userInfo objectForKey:IMAGE_URL]];
    if (self.canConnect) {
        if (p.album.albumId != nil) {
            [self.uploadFunction onePhotoThumbToApi:p networkStatus:self.networkStatus];
        } else {
            CSAlbum *album = p.album;
            [self.coinsorter createAlbum:album callback:^(NSString *album_id) {
                if (album_id !=nil) {
                    [self.uploadFunction onePhotoThumbToApi:p networkStatus:self.networkStatus];
                }
            }];
        }
    }
    }
}

#pragma mark - app setting for 3g upload notification

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:UPLOAD_3G]) {
        BOOL upload3G = [defaults boolForKey:UPLOAD_3G];
        if (upload3G) {
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Warnning" message:@"Uploading photo through 3G will have addition cost of Data, Are you sure?" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            alertView.tag = 2;
            [alertView show];
        }
    } else if ([keyPath isEqualToString:DEVICE_NAME]) {
        // device name change
        NSString *deviceName = [defaults valueForKey:DEVICE_NAME];
        
        self.localDevice.deviceName = deviceName;
        
        [self.coinsorter updateDevice];
    } else if ([keyPath isEqualToString:DELETE_RAW]) {
        bool deletRaw = [defaults boolForKey:DELETE_RAW];
        if (deletRaw) {
            NSLog(@"delete raw yes");
        } else {
            NSLog(@"delete raw no");
        }
    } else if ([keyPath isEqualToString:IMPORT_DROPBOX]){
        bool dropboxImport = [defaults boolForKey:IMPORT_DROPBOX];
        
        if (dropboxImport) {
             [[DBSession sharedSession] linkFromController:self];
        } else {
                [[DBSession sharedSession] unlinkAll];
        }
    }
    
}

#pragma mark - background upload function
-(void)fetchNewDataWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    appDelegate = [[UIApplication sharedApplication] delegate];

    NSString *bssid = [self currentWifiBSSID];
    if (bssid == nil) {
        return;
    } else  {
        int unUploadedThumbnail = [appDelegate.dataWrapper getCountUnUploaded];
        int unUploadedFullPhotos = [appDelegate.dataWrapper getFullImageCountUnUploaded];
        NSLog(@"count %d ",unUploadedThumbnail);
        if (unUploadedFullPhotos != 0 && unUploadedThumbnail != 0) {
            [self.uploadFunction uploadPhotosToApi:WIFILOCAL];
            completionHandler(UIBackgroundFetchResultNewData);
        } else {
            completionHandler(UIBackgroundFetchResultNoData);
        }
    }
}
- (IBAction)downloadDropbox:(id)sender {
    NSString *photosRoot = nil;
    if ([DBSession sharedSession].root == kDBRootDropbox) {
        photosRoot = @"/Photos";
    } else {
        photosRoot = @"/";
    }
    
    [restClient loadMetadata:photosRoot];
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

- (IBAction)resetFilter:(id)sender {
    filterFlag = 0;
    sortFlag =nil;
    self.albums = [self.dataWrapper getAllAlbums];
    [self getViewController];
}

-(void) filterInfo:(NSMutableArray *)data {
    filterFlag = 1;
    self.filterArray = data;
    [self getViewController];
    

}

#pragma mark - sort functions

-(void) sortarrays:(NSString *) sortBase {
    //NSArray *sortedArray;
    
    if ([sortBase isEqualToString:SORTNAME]) {
        self.sortArray = [self.albums sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSString *first = [(CSAlbum *)obj1 name];
            NSString *second = [(CSAlbum *)obj2 name];
            return [first compare:second];
        }];

    } else if ([sortBase isEqualToString:SORTPRICEHIGH]){
        self.sortArray = [self.albums sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            CSEntry *first = [(CSAlbum *)obj1 entry];
            CSEntry *second = [(CSAlbum *)obj2 entry];
            return [second.price compare:first.price];
        }];
        
    } else if ([sortBase isEqualToString:SORTPRICELOW]){
        self.sortArray = [self.albums sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            CSEntry *first = [(CSAlbum *)obj1 entry];
            CSEntry *second = [(CSAlbum *)obj2 entry];
            return [first.price compare:second.price];
        }];
    }
    
    self.albums = [NSMutableArray arrayWithArray:self.sortArray];
    [self getViewController];

    
}

- (IBAction)sortLocations:(id)sender {
    UIActionSheet *shareActionSheet = [[UIActionSheet alloc] initWithTitle:@"Sort" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Sort By Name",@"Sort By Price(High to Low)",@"Sort By Price(Low to High)", nil];
    [shareActionSheet showInView:self.view];
    
}

-(void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {

    switch (buttonIndex) {
        case 0:
        {
            sortFlag = SORTNAME;
            [self sortarrays:SORTNAME];
            break;
        }
        case 1:
        {
            sortFlag = SORTPRICEHIGH;
            [self sortarrays:SORTPRICEHIGH];
            break;
        }
        case 2:
        {
            sortFlag = SORTPRICELOW;
            [self sortarrays:SORTPRICELOW];
            break;
    
        }
        default:
            break;
    }
}


-(void) getViewController {
    UIViewController *vc = [self viewControllerForSegmentIndex:self.typeSegmentedControl.selectedSegmentIndex];
    [self addChildViewController:vc];
    vc.view.frame = self.containerView.bounds;
    [self.view addSubview:vc.view];
    self.currentViewController = vc;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"filterSegue"]) {
        
        FilterTableViewController *vc = (FilterTableViewController *)segue.destinationViewController;
        vc.delegate = self;
        vc.hidesBottomBarWhenPushed = YES;
    }

}

#pragma mark - Dropbox delegate

- (DBRestClient*)restClient {
    if (restClient == nil) {
        restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        restClient.delegate = self;
    }
    return restClient;
}


- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata {

    NSArray* validExtensions = [NSArray arrayWithObjects:@"jpg", @"jpeg", nil];
    NSLog(@"Folder '%@' contains:", metadata.path);
        for(DBMetadata *file in metadata.contents) {
             NSString* extension = [[file.path pathExtension] lowercaseString];
            if (!file.isDirectory && [validExtensions indexOfObject:extension] != NSNotFound) {
                self.dropboxPath = file.path;
                NSString *documentsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/MyImage"];
                
                if (![[NSFileManager defaultManager] fileExistsAtPath:documentsPath]){
                    [[NSFileManager defaultManager] createDirectoryAtPath:documentsPath withIntermediateDirectories:NO attributes:nil error:nil];}
                
                NSString *photoUID = [[NSProcessInfo processInfo] globallyUniqueString];
                
                NSString *tmpThumbPath = [documentsPath stringByAppendingString:[NSString stringWithFormat:@"/thumb_%@.jpg", photoUID]];
                
                NSString *tmpFullPath = [documentsPath stringByAppendingString:[NSString stringWithFormat:@"/%@.jpg", photoUID]];
                
                [self.restClient loadThumbnail:self.dropboxPath  ofSize:@"iphone_bestfit" intoPath:tmpThumbPath];
                [self.restClient loadFile:self.dropboxPath intoPath:tmpFullPath];
            }

            
            NSLog(@"%@", file.filename);
        }
}
- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError*)error {
    NSLog(@"Error loading metadata: %@", error);
}

- (void)restClient:(DBRestClient*)client metadataUnchangedAtPath:(NSString*)path {
}

- (void)restClient:(DBRestClient*)client loadedThumbnail:(NSString*)destPath {
     NSLog(@"dowload thumbnail");
    


    
    //[restClient loadFile:path intoPath:tmpFullPath];
    //[self.saveFunction saveImageIntoDocument:[UIImage imageWithContentsOfFile:destPath] metadata:self.dropboxMeta album:dropbox];
}

- (void)restClient:(DBRestClient*)client loadThumbnailFailedWithError:(NSError*)error {

}

- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)destPath
{
    NSLog(@"dowload file");
    
    NSArray* firstSplit = [destPath componentsSeparatedByString: @"/"];
    NSString *fileName = [firstSplit objectAtIndex:9];
    
    //NSArray *secondSplit = [fileName componentsSeparatedByString:@"_"];
   // NSString *uidWithExt = [secondSplit objectAtIndex:1];
    
    NSArray *thirdSplit = [fileName componentsSeparatedByString:@"."];
    NSString *photoUID = [thirdSplit objectAtIndex:0];
    
    NSString *filePath = [@"MyImage" stringByAppendingString:[NSString stringWithFormat:@"/%@.jpg", photoUID]];
    
    NSString *thumbPath = [@"MyImage" stringByAppendingString:[NSString stringWithFormat:@"/thumb_%@.jpg", photoUID]];
    
    CSPhoto *p = [[CSPhoto alloc] init];
    
    p.dateCreated = [NSDate date];
    p.deviceId = self.localDevice.remoteId;
    p.thumbOnServer = @"0";
    p.fullOnServer = @"0";
    p.thumbURL = thumbPath;
    p.imageURL = filePath;
    p.fileName = [NSString stringWithFormat:@"%@.jpg", photoUID];
    p.thumbnailName = [NSString stringWithFormat:@"thumb_%@.jpg",photoUID];
    p.isVideo = @"0";
    p.album = self.dropbox;
    [self.dataWrapper addPhoto:p];

    
    //Here destPath is the path at which place your image is downloaded
}
-(void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error
{
NSLog(@"Error downloading file: %@", error);
}

#pragma mark - Get current location 

-(void) getCurrentLocation {
    locationManager = [[CLLocationManager alloc]init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.distanceFilter = 10;
    [locationManager requestWhenInUseAuthorization];
    [locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    NSLog(@"OldLocation %f %f", oldLocation.coordinate.latitude, oldLocation.coordinate.longitude);
    NSLog(@"NewLocation %f %f", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
    [self geocodeLocation:newLocation];
}

- (void)geocodeLocation:(CLLocation *)location {
    if (!geocoder)
        geocoder = [[CLGeocoder alloc] init];
    
    [geocoder reverseGeocodeLocation:location
                   completionHandler:^(NSArray *placemarks, NSError *error) {
                       if ([placemarks count] > 0) {
                           
                           // get address properties of location
                           CLPlacemark *p = [placemarks lastObject];
                           self.dropbox.entry.location.postCode = [p.addressDictionary objectForKey:@"ZIP"];
                           self.dropbox.entry.location.country =
                           [p.addressDictionary objectForKey:@"Country"];
                           self.dropbox.entry.location.countryCode =
                           [p.addressDictionary objectForKey:@"CountryCode"];
                           self.dropbox.entry.location.city = [p.addressDictionary objectForKey:@"City"];
                           self.dropbox.entry.location.sublocation = [p.addressDictionary objectForKey:@"Name"];
                           self.dropbox.entry.location.province = [p.addressDictionary objectForKey:@"State"];
                           self.dropbox.entry.location.longitude = [NSString stringWithFormat:@"%f", location.coordinate
                                                      .longitude];
                           self.dropbox.entry.location.latitude = [NSString stringWithFormat:@"%f", location.coordinate
                                                     .latitude];
                           
                           self.dropbox.entry.location.altitude = [NSString stringWithFormat:@"%f",location.altitude];
                           // self.location.unit = self.txtUnit.text;
                           
                           //[self.streetName setText:self.location.name];
                           //[self.streetName setHidden:NO];
                           //[//self saveLocation];
                           //generate pins on map
                           [self.dataWrapper addAlbum:self.dropbox];
                           [self getViewController];

                       }
                   }];
    [locationManager stopUpdatingLocation];

}

@end
