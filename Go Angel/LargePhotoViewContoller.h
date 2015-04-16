//
//  LargePhotoViewContoller.h
//  Go Arch
//
//  Created by Jake Runzer on 3/23/15.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSDevice.h"
#import "CoreDataWrapper.h"
#import "Coinsorter.h"
#import "AppDelegate.h"
#import "AccountDataWrapper.h"
#import "SingleLocationViewController.h"

@interface LargePhotoViewContoller : UIViewController<UITableViewDataSource, UITableViewDelegate> {
  AccountDataWrapper *account;
  AppDelegate *appDelegate;
}

//@property (nonatomic, strong) NSMutableArray *locations;
@property (nonatomic, strong) NSMutableArray *albums;
//@property (nonatomic, strong) CSLocation *selectedLocation;
@property (nonatomic, strong) CSAlbum *selectedAlbum;

@property (nonatomic, strong) CoreDataWrapper *dataWrapper;
@property (nonatomic, strong) CSDevice *localDevice;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
