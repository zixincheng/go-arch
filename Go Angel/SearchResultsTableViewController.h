//
//  SearchResultsTableViewController.h
//  Pods
//
//  Created by zcheng on 2015-01-30.
//
//

#import <UIKit/UIKit.h>
#import "CSLocation.h"
#import "IndividualEntryViewController.h"
#import "CoreDataWrapper.h"
#import "CSDevice.h"
#import "AddingLocationViewController.h"

@interface SearchResultsTableViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *searchResults;
@property (nonatomic, strong) CoreDataWrapper *dataWrapper;
@property (nonatomic, strong) CSDevice *localDevice;
@property (nonatomic, strong) CSLocation *selectedlocation;

@end
