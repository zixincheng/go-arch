//
//  StorageViewController.h
//  Go Arch
//
//  Created by zcheng on 2014-11-20.
//  Copyright (c) 2014 acdGO Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Coinsorter.h"
#import "CoreDataWrapper.h"
#import "StorageDetailViewController.h"


@interface StorageViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray *storages;
@property (nonatomic, retain) NSMutableArray *labelArray;
@property (nonatomic, retain) NSMutableArray *buttonArray;
@property (nonatomic, strong) Coinsorter *coinsorter;
@property (nonatomic, strong) CoreDataWrapper *dataWrapper;
@property (weak, nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic, strong) CSStorage *selectedStorage;



@end
