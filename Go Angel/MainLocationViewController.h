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
#import <SystemConfiguration/CaptiveNetwork.h>
#import "IndividualEntryViewController.h"
#import "SingleLocationViewController.h"
#import "SearchMapViewController.h"
#import "SearchResultsTableViewController.h"

@interface MainLocationViewController : UIViewController <UITableViewDelegate,UITableViewDataSource, UIAlertViewDelegate,UISearchResultsUpdating, UISearchBarDelegate,GCDAsyncUdpSocketDelegate> {
    AccountDataWrapper *account;
    NSUserDefaults *defaults;
    int loadCamera;
    
}
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) NSMutableArray *searchResults;

@property (nonatomic, strong) CSLocation *selectedlocation;
@property (nonatomic, strong) CSDevice *localDevice;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) Coinsorter *coinsorter;
@property (nonatomic, strong) CoreDataWrapper *dataWrapper;

@property (nonatomic, strong) NSMutableArray *devices;
@property (nonatomic, strong) NSMutableArray *locations;
@property (nonatomic, strong) NSMutableArray *photos;

@property (nonatomic, strong) UIRefreshControl *refreshControl;


@end
