//
//  StorageDetailViewController.h
//  Go Arch
//
//  Created by zcheng on 2014-11-26.
//  Copyright (c) 2014 acdGO Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataWrapper.h"
#import "CSStorage.h"
#import "Coinsorter.h"

@interface StorageDetailViewController : UITableViewController <UIAlertViewDelegate,UITableViewDataSource,UITableViewDelegate,UIPickerViewDataSource,UIPickerViewDelegate>
@property (nonatomic, strong) CSStorage *storages;
@property (nonatomic, strong) CoreDataWrapper *dataWrapper;
@property (nonatomic, strong) Coinsorter *coinsorter;

@property (nonatomic) UISwitch *BackupSwitch;
@property (nonatomic) UISwitch *primarySwitch;
@property (nonatomic) UILabel *StorageMountLabel;
@property (nonatomic) UILabel *StorageUsageLabel;
@property (nonatomic) UIButton *CronSchedule;

@property (nonatomic) UIView *pickerViewContainer;
@property (nonatomic, retain) UIPickerView *pickerView;
@property (nonatomic, retain) NSMutableArray *dataArray;
@property (nonatomic, retain) UIToolbar *pickToolbar;
@property (nonatomic, retain) UIBarButtonItem *pickerViewButton;

@property (nonatomic) UIButton *ejectBtn;

@property (nonatomic) NSInteger secondSectionRowCount;
@property (nonatomic) NSString  *currentSchedule;
@property (nonatomic) NSString  *cronTime;

@end
