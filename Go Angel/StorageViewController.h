//
//  StorageViewController.h
//  Go Angel
//
//  Created by zcheng on 2014-11-20.
//  Copyright (c) 2014 acdGO Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Coinsorter.h"
#import "CoreDataWrapper.h"

@interface StorageViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *storages;
@property (nonatomic, strong) Coinsorter *coinsorter;
@property (nonatomic, strong) CoreDataWrapper *dataWrapper;

@end
