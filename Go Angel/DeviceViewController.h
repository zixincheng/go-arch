//
//  DeviceViewController.h
//  Go Angel
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "AccountDataWrapper.h"
#import "CSPhoto.h"
#import "CSDevice.h"
#import "Coinsorter.h"
#import "CoreDataWrapper.h"
#import "GridViewController.h"
#import "LocalLibrary.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreLocation/CoreLocation.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import "Reachability.h"


// the controller that displays a list of devices that are on the server
// this is the 'main page' of the app
// its where all the network calls are made from (upload and download)
// the app functionality starts here

@interface DeviceViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
  NSMutableArray *_selections;
  
  LocalLibrary *localLibrary;
  AccountDataWrapper *account;
  NSUserDefaults *defaults;
  
  // do we need to fully parse local library
  // happens after albums select
  BOOL needParse;
}


// progress toolbar
@property (weak, nonatomic) IBOutlet UIProgressView *progressUpload;

// upload toolbar
@property (weak, nonatomic) IBOutlet UIToolbar *toolUpload;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnUpload;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) UIRefreshControl *refreshControl;

@property (nonatomic, strong) NSMutableArray *devices;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) CSDevice *selectedDevice;

@property (nonatomic, strong) Coinsorter *coinsorter;
@property (nonatomic, strong) CoreDataWrapper *dataWrapper;

@property (nonatomic, strong) CSDevice *localDevice;

@property (nonatomic )int unUploadedPhotos;
@property (nonatomic) BOOL currentlyUploading;

@property (nonatomic, retain) Reachability *reach;
@property (nonatomic, assign) BOOL canConnect;
@property (nonatomic) NSString *prevBSSID;
@property (nonatomic) NSInteger networkStatus;

@end
