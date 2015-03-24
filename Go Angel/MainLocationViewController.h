//
//  MainLocationViewController.h
//  Go Arch
//
//  Created by zcheng on 2015-01-22.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSLocation.h"
#import "CoreDataWrapper.h"
#import "Coinsorter.h"
#import "AccountDataWrapper.h"
#import "CSDevice.h"
#import "CSPhoto.h"
#import "LocalLibrary.h"
#import "Reachability.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import "IndividualEntryViewController.h"
#import "SingleLocationViewController.h"
#import "SearchMapViewController.h"
#import "SearchResultsTableViewController.h"
#import "NetWorkCheck.h"
#import "F3Swirly.h"
#import "SWTableViewCell.h"

@interface MainLocationViewController : UIViewController <UITableViewDelegate,UITableViewDataSource, UIAlertViewDelegate,UISearchResultsUpdating, UISearchBarDelegate,GCDAsyncUdpSocketDelegate,SWTableViewCellDelegate> {
    LocalLibrary *localLibrary;
    AccountDataWrapper *account;
    NSUserDefaults *defaults;
    int loadCamera;
    
}
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) NSMutableArray *searchResults;

@property (nonatomic, strong) CSLocation *selectedlocation;
@property (nonatomic, strong) CSDevice *localDevice;
@property (retain, nonatomic) F3Swirly *valueSwirly;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) Coinsorter *coinsorter;
@property (nonatomic, strong) CoreDataWrapper *dataWrapper;
@property (nonatomic, retain) Reachability *reach;
@property (nonatomic, retain) NetWorkCheck *netWorkCheck;

@property (nonatomic, strong) NSMutableArray *devices;
@property (nonatomic, strong) NSMutableArray *locations;
@property (nonatomic, strong) NSMutableArray *photos;

@property (nonatomic) NSString *prevBSSID;
@property (nonatomic) NSString *networkStatus;
@property (nonatomic) NSInteger localLanStatus;
@property (nonatomic, assign) BOOL canConnect;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) UILabel *btnUpload;
@property (nonatomic, strong) UILabel *netWorkstatLabel;

@property (nonatomic )int unUploadedThumbnail;
@property (nonatomic )int unUploadedFullPhotos;
@property (nonatomic) BOOL currentlyUploading;
-(void)fetchNewDataWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
@end
