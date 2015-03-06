//
//  DashboardViewController.h
//  Go Arch
//
//  Created by Xing Qiao on 2014-12-08.
//  Copyright (c) 2014 acdGO Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AccountDataWrapper.h"
#import "AppDelegate.h"

@interface DashboardViewController : UITableViewController<UITableViewDataSource,UITableViewDelegate>{
    AccountDataWrapper *account;
}

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, assign)int totalPhotos;
@property (nonatomic, assign)int processedUploadedPhotos;
@property (nonatomic, strong) NSString *currentStatus;
@property (nonatomic, strong) NSString *homeServer;
@property (nonatomic, strong) NSString *serverName;
@property (nonatomic, strong) NSString *serverIP;

@end
