//
//  SegmentedViewController.h
//  
//
//  Created by zcheng on 2015-03-18.
//
//

#import <UIKit/UIKit.h>
#import "MainLocationViewController.h"
#import "CoreDataWrapper.h"
#import "Coinsorter.h"
#import "AccountDataWrapper.h"
#import "CSDevice.h"
#import "CSPhoto.h"
#import "NetWorkCheck.h"
#import "Reachability.h"
#import "UploadFunctions.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import "FilterTableViewController.h"
#import "MainLocationViewController.h"
#import "SearchMapViewController.h"
#import "LargePhotoViewContoller.h"
#import "CSLocation.h"
#import "CSAlbum.h"


@interface SegmentedViewController : UIViewController<FilterTableViewControllerDelegate,UIActionSheetDelegate>{
    AppDelegate *appDelegate;
    AccountDataWrapper *account;
    NSUserDefaults *defaults;
    NSString *sortFlag;
    int filterFlag;
}

@property (weak, nonatomic) IBOutlet UISegmentedControl *typeSegmentedControl;

@property (weak, nonatomic) IBOutlet UIView *containerView;

@property (strong, nonatomic) UIViewController *currentViewController;

@property (nonatomic, strong) CoreDataWrapper *dataWrapper;
@property (nonatomic, retain) Reachability *reach;
@property (nonatomic, retain) NetWorkCheck *netWorkCheck;
@property (nonatomic, strong) Coinsorter *coinsorter;
@property (nonatomic, strong) CSDevice *localDevice;
@property (nonatomic, strong) UploadFunctions *uploadFunction;
//@property (nonatomic, strong) NSMutableArray *locations;
@property (nonatomic, strong) NSMutableArray *albums;
@property (nonatomic, strong) NSArray *sortArray;
@property (nonatomic, strong) NSArray *filterArray;

@property (nonatomic) NSString *networkStatus;
@property (nonatomic, assign) BOOL canConnect;

-(void)fetchNewDataWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;

@end
