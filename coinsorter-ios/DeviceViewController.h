//
//  Menu.h
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 21/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MWPhotoBrowser.h"
#import "AppDelegate.h"
#import "AccountDataWrapper.h"
#import "CSPhoto.h"
#import "CSDevice.h"
#import "Coinsorter.h"
#import "CoreDataWrapper.h"
#import "LocalLibrary.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreLocation/CoreLocation.h>

@interface DeviceViewController : UIViewController <MWPhotoBrowserDelegate, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate> {
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

@property (nonatomic, strong) Coinsorter *coinsorter;
@property (nonatomic, strong) CoreDataWrapper *dataWrapper;

@property (nonatomic, strong) CSDevice *localDevice;

@property int unUploadedPhotos;
@property BOOL currentlyUploading;

@end
