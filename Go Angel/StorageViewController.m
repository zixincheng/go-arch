//
//  StorageViewController.m
//  Go Arch
//
//  Created by zcheng on 2014-11-20.
//  Copyright (c) 2014 acdGO Software Ltd. All rights reserved.
//

#import "StorageViewController.h"
#import "StorageTableViewCell.h"

@interface StorageViewController ()

@end

@implementation StorageViewController

static NSString *MyIdentifier = @"StorageCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Fetch Storage"];
    [refresh addTarget:self action:@selector(reload) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refresh;

    self.dataWrapper = [[CoreDataWrapper alloc] init];
    self.coinsorter = [[Coinsorter alloc] initWithWrapper:self.dataWrapper];
    self.storages = [[NSMutableArray alloc] init];
    self.labelArray = [[NSMutableArray alloc] init];
    self.buttonArray = [[NSMutableArray alloc] init];

    [self getStoragesFromApi];

    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void) viewWillAppear:(BOOL)animated{
    
    [self.tableView reloadData];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) reload{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
    [self stopRefresh];
    
}

- (void) getStoragesFromApi {
    // then get all devices
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    [self.coinsorter getStorages: ^(NSMutableArray *storages) {
        for (CSStorage *s in storages) {
            if ([s.pluged_in boolValue]==YES ) {
                [self.storages addObject:s];
                NSLog(@"%lu",(unsigned long)self.storages.count);
            }
        }
    dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
        
    }];
        });
}

// stops the refreshing animation
- (void)stopRefresh {
    if (self.refreshControl != nil && [self.refreshControl isRefreshing]) {
        [self.refreshControl endRefreshing];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;    //count of section
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.storages.count;
   //count number of row from counting array hear cataGorry is An Array
}



- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    StorageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    if (cell == nil) {
        cell = [[StorageTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:MyIdentifier];
    }
    
    // Configure
    CSStorage *s = self.storages[[indexPath row]];
    cell.StorageName.text = s.storageLabel;
    cell.StorageStat.text = [NSString stringWithFormat:@"Mounted: %@",([s.mounted boolValue] ? @"Y": @"N")];
    cell.StoragePrimary.text = ([s.primary boolValue] ? @"P": @"");
    cell.StorageBackup.text = ([s.backup boolValue] ? @"B": @"");
    cell.StorageName.adjustsFontSizeToFitWidth = YES;
    cell.StorageStat.adjustsFontSizeToFitWidth = YES;
    
    // Here we use the provided setImageWithURL: method to load the web image
    // Ensure you use a placeholder image otherwise cells will be initialized with no image
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CSStorage *s = [self.storages objectAtIndex:[indexPath row]];
    self.selectedStorage = s;
    
    [self performSegueWithIdentifier:@"detailSegue" sender:self];
    
    
    // Deselect
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"detailSegue"]) {
        StorageDetailViewController *detailController = (StorageDetailViewController *)segue.destinationViewController;
        detailController.storages = self.selectedStorage;
        detailController.dataWrapper = self.dataWrapper;
        detailController.coinsorter = self.coinsorter;
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
