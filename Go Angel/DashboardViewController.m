//
//  DashboardViewController.m
//  Go Arch
//
//  Created by Xing Qiao on 2014-12-08.
//  Copyright (c) 2014 acdGO Software Ltd. All rights reserved.
//

#import "DashboardViewController.h"

@interface DashboardViewController ()

@end

@implementation DashboardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    account = appDelegate.account;
    
    // notification that current status is uploading
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadingStatus) name:@"onePhotoUploaded" object:nil];
    
    // notification that current status is waiting
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endUploadingStatus) name:@"endUploading" object:nil];
    
    // notification that home server is disconnected
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(homeServerDisconnected) name:@"homeServerDisconnected" object:nil];
    
    // notification that home server is connected
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(homeServerConnected) name:@"homeServerConnected" object:nil];
    // Do any additional setup after loading the view from its nib.
}

-(void) uploadingStatus{
    self.processedUploadedPhotos += 1;
    self.currentStatus = @"Uploading Photos";
    dispatch_async(dispatch_get_main_queue(), ^ {
        [self.tableView reloadData];
    });
}

-(void) endUploadingStatus{
    self.processedUploadedPhotos = self.totalPhotos;
    self.currentStatus = @"Waiting";
    dispatch_async(dispatch_get_main_queue(), ^ {
        [self.tableView reloadData];
    });
}

-(void) homeServerConnected{
    self.serverName = account.name;
    self.serverIP = account.currentIp;
    self.homeServer = @"YES";
    dispatch_async(dispatch_get_main_queue(), ^ {
        [self.tableView reloadData];
    });
}

-(void) homeServerDisconnected{
    self.serverName = @"Unknown";
    self.serverIP = @"Unknown";
    self.homeServer = @"NO";
    dispatch_async(dispatch_get_main_queue(), ^ {
        [self.tableView reloadData];
    });
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DashBoardCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DashBoardCell"];
    }
    if (indexPath.row == 0) {
        cell.textLabel.text = [NSString stringWithFormat:@"Photos Progress: %d / %d", self.processedUploadedPhotos,self.totalPhotos];
    }else if (indexPath.row == 1){
        cell.textLabel.text = [NSString stringWithFormat:@"Server Name: %@",self.serverName];
    }else if (indexPath.row == 2){
        cell.textLabel.text = [NSString stringWithFormat:@"Server IP: %@",self.serverIP];
    }else if (indexPath.row == 3){
        cell.textLabel.text = [NSString stringWithFormat:@"Uploading Status: %@",self.currentStatus];
    }else if (indexPath.row == 4){
        cell.textLabel.text = [NSString stringWithFormat:@"Home Network: %@", self.homeServer];
    }
    
    return cell;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"onePhotoUploaded" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"endUploading" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"homeServerDisconnected" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"homeServerConnected" object:nil];
}


@end
