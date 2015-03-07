//
//  HistoryTableViewController.h
//  Go Arch
//
//  Created by Xing Qiao on 2014-12-16.
//  Copyright (c) 2014 acdGO Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataWrapper.h"

@interface HistoryTableViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *logs;
@property (nonatomic, strong) CoreDataWrapper *dataWrapper;

@end
