
//
//  DetailsViewController.h
//  Go Arch
//
//  Created by Jake Runzer on 3/19/15.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Coinsorter.h"
#import "CoreDataWrapper.h"
#import "CSDevice.h"
#import "CSLocation.h"
#import "AppDelegate.h"
#import "AddNewEntryViewController.h"
#import "CSPhoto.h"

@interface DetailsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate> {
  AppDelegate *appDelegate;
}

@property (nonatomic, strong) Coinsorter *coinsorter;
@property (nonatomic, strong) CoreDataWrapper *dataWrapper;
//@property (nonatomic, strong) CSLocation *location;
@property (nonatomic, strong) CSAlbum *album;
@property (nonatomic, strong) CSDevice *localDevice;

@property (nonatomic, strong) CSPhoto *coverPhoto;
@property (nonatomic, strong) NSMutableArray *photos;

@property (nonatomic, strong) NSMutableArray *sections;

@property (nonatomic, strong) NSMutableArray *locationKeys;
@property (nonatomic, strong) NSMutableArray *locationValues;

@property (nonatomic, strong) NSMutableArray *detailsKeys;
@property (nonatomic, strong) NSMutableArray *detailsValues;

@property (nonatomic, strong) NSMutableArray *buildingKeys;
@property (nonatomic, strong) NSMutableArray *buildingValues;

@property (weak, nonatomic) IBOutlet UIImageView *coverImageView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) AddNewEntryViewController *embedController;
@property (weak, nonatomic) IBOutlet UIView *containerView;

@end
