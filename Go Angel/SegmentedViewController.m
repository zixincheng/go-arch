//
//  SegmentedViewController.m
//  
//
//  Created by zcheng on 2015-03-18.
//
//

#import "SegmentedViewController.h"
#import "FilterTableViewController.h"


#define SORTNAME @"sortName"
#define SORTPRICEHIGH @"sortPriceHigh"
#define SORTPRICELOW @"sortPriceLow"

@interface SegmentedViewController ()

- (UIViewController *)viewControllerForSegmentIndex:(NSInteger)index;

@end

@implementation SegmentedViewController

- (void)viewDidLoad {
    [super viewDidLoad];

                                                                
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
    self.locations = [self.dataWrapper getLocations];
    // setup network notification
    [self.netWorkCheck setupNet];
    
    [self getViewController];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changePass) name:@"passwordChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadPhotoChanged:) name:@"addNewPhoto"object:nil];
    [defaults addObserver:self forKeyPath:UPLOAD_3G options:NSKeyValueObservingOptionNew context:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateNetWork:) name:@"networkStatusChanged"object:nil];
    
    [self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    if (filterFlag != 1) {
        self.locations = [self.dataWrapper getLocations];
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
    //[self.coinsorter getAlbumInfo];

    switch (index) {
        case 0:
            mainvc = (MainLocationViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"mainLocationViewController"];
            mainvc.locations = self.locations;
            vc = mainvc;
            break;
        case 1:
            mapvc = (SearchMapViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"MapView"];
            mapvc.locations = self.locations;
            vc = mapvc;
            break;
        case 2:
            largevc = (LargePhotoViewContoller *)[self.storyboard instantiateViewControllerWithIdentifier:@"LargePhotoViewContoller"];
            largevc.locations = self.locations;
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
                            NSMutableArray *unuploadphotos = [self.dataWrapper getPhotosToUploadWithLocation:self.localDevice.remoteId location:a.location];
                            for (CSPhoto *p in unuploadphotos) {
                                [self.uploadFunction onePhotoThumbToApi:p networkStatus:self.networkStatus];
                            }
                        }
                    }];
                }

            for (CSAlbum *a in alreadyUploaded) {
                NSMutableArray *unuploadphotos = [self.dataWrapper getPhotosToUploadWithLocation:self.localDevice.remoteId location:a.location];
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
    
    CSPhoto *p = [self.dataWrapper getPhoto:[notification.userInfo objectForKey:IMAGE_URL]];
    if (self.canConnect) {
        if (p.location.album.albumId != nil) {
            [self.uploadFunction onePhotoThumbToApi:p networkStatus:self.networkStatus];
        } else {
            CSAlbum *album = p.location.album;
            album.location = p.location;
            [self.coinsorter createAlbum:album callback:^(NSString *album_id) {
                if (album_id !=nil) {
                    [self.uploadFunction onePhotoThumbToApi:p networkStatus:self.networkStatus];
                }
            }];
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
    self.locations = [self.dataWrapper getLocations];
    [self getViewController];
}

-(void) filterInfo:(NSMutableArray *)data {
    filterFlag = 1;
    self.locations = data;
    [self getViewController];
    

}

#pragma mark - sort functions

-(void) sortarrays:(NSString *) sortBase {
    NSArray *sortedArray;
    
    if ([sortBase isEqualToString:SORTNAME]) {
        sortedArray = [self.locations sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSString *first = [(CSLocation *)obj1 sublocation];
            NSString *second = [(CSLocation *)obj2 sublocation];
            return [first compare:second];
        }];

    } else if ([sortBase isEqualToString:SORTPRICEHIGH]){
        sortedArray = [self.locations sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            CSAlbum *first = [(CSLocation *)obj1 album];
            CSAlbum *second = [(CSLocation *)obj2 album];
            return [second.price compare:first.price];
        }];
        
    } else if ([sortBase isEqualToString:SORTPRICELOW]){
        sortedArray = [self.locations sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            CSAlbum *first = [(CSLocation *)obj1 album];
            CSAlbum *second = [(CSLocation *)obj2 album];
            return [first.price compare:second.price];
        }];
    }
    
    self.locations = [NSMutableArray arrayWithArray:sortedArray];
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
            [self sortarrays:SORTNAME];
            sortFlag = SORTNAME;
            break;
        }
        case 1:
        {
            [self sortarrays:SORTPRICEHIGH];
            sortFlag = SORTPRICEHIGH;
            break;
        }
        case 2:
        {
            [self sortarrays:SORTPRICELOW];
            sortFlag = SORTPRICELOW;
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


@end
