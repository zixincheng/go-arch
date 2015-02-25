//
//  MainLocationViewController.h
//  Go Angel
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
#import "SearchMapViewController.h"
#import "SearchResultsTableViewController.h"

@interface MainLocationViewController : UITableViewController <UISearchResultsUpdating, UISearchBarDelegate> {
    LocalLibrary *localLibrary;
    AccountDataWrapper *account;
    NSUserDefaults *defaults;
    int loadCamera;
    
}
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) NSMutableArray *searchResults;

@property (nonatomic, strong) CSLocation *selectedlocation;
@property (nonatomic, strong) CSDevice *localDevice;

@property (nonatomic, strong) Coinsorter *coinsorter;
@property (nonatomic, strong) CoreDataWrapper *dataWrapper;
@property (nonatomic, retain) Reachability *reach;

@property (nonatomic, strong) NSMutableArray *devices;
@property (nonatomic, strong) NSMutableArray *locations;
@property (nonatomic, strong) NSMutableArray *photos;

@property (nonatomic) NSString *prevBSSID;
@property (nonatomic) NSInteger networkStatus;
@property (nonatomic, assign) BOOL canConnect;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) UIBarButtonItem *btnUpload;

@property (nonatomic )int unUploadedPhotos;
@property (nonatomic) BOOL currentlyUploading;

@end
