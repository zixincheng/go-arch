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
#import "DashboardViewController.h"
#import "F3Swirly.h"
#import "ActivityHistory.h"
#import "HistoryTableViewController.h"

// the controller that displays a list of devices that are on the server
// this is the 'main page' of the app
// its where all the network calls are made from (upload and download)
// the app functionality starts here

@interface DeviceViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverPresentationControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate> {
  int selected;
  NSMutableArray *_selections;
  
  LocalLibrary *localLibrary;
  AccountDataWrapper *account;
  NSUserDefaults *defaults;
  ActivityHistory *log;
    
  // do we need to fully parse local library
  // happens after albums select
  BOOL needParse;
    
    IBOutlet UIBarButtonItem *settingButton;
    UIBarButtonItem *logButton;
}


// progress toolbar
@property (weak, nonatomic) IBOutlet UIProgressView *progressUpload;

// upload toolbar
@property (weak, nonatomic) IBOutlet UIToolbar *toolUpload;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnUpload;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnCamera;
@property (retain, nonatomic) IBOutlet F3Swirly *valueSwirly;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) UIRefreshControl *refreshControl;

@property (nonatomic, strong) NSMutableArray *devices;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) CSDevice *selectedDevice;

@property (nonatomic, strong) Coinsorter *coinsorter;
@property (nonatomic, strong) CoreDataWrapper *dataWrapper;

@property (nonatomic, strong) CSDevice *localDevice;

@property (nonatomic )int unUploadedPhotos;
@property (nonatomic, assign )int totalUploadedPhotos;
@property (nonatomic, assign )int totalPhotos;
@property (nonatomic) BOOL currentlyUploading;

@property (nonatomic, retain) Reachability *reach;
@property (nonatomic, assign) BOOL canConnect;
@property (nonatomic) NSString *prevBSSID;
@property (nonatomic) NSInteger networkStatus;

@property (nonatomic,strong) NSString *currentStatus;
@property (nonatomic,strong) NSString *homeServer;
@property (nonatomic,strong) NSString *serverName;
@property (nonatomic,strong) NSString *serverIP;

@end
