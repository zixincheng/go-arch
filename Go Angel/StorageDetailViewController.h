//
//  StorageDetailViewController.h
//  Go Angel
//
//  Created by zcheng on 2014-11-26.
//  Copyright (c) 2014 acdGO Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataWrapper.h"
#import "CSStorage.h"
#import "Coinsorter.h"

@interface StorageDetailViewController : UITableViewController <UITableViewDataSource,UITableViewDelegate>

@property (nonatomic, strong) CSStorage *storages;
@property (nonatomic, strong) CoreDataWrapper *dataWrapper;
@property (nonatomic, strong) Coinsorter *coinsorter;


@property (weak, nonatomic) IBOutlet UILabel *StorageNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *StorageUUIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *StorageUsageLabel;
@property (weak, nonatomic) IBOutlet UILabel *StorageMountLabel;

@property (weak, nonatomic) IBOutlet UIButton *ejectBtn;
@property (weak, nonatomic) IBOutlet UIButton *copyingBtn;
@property (weak, nonatomic) IBOutlet UIButton *mountBtn;

@end
