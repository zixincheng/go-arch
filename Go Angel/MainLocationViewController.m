//
//  MainLocationViewController.m
//  Go Angel
//
//  Created by zcheng on 2015-01-22.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "MainLocationViewController.h"

@interface MainLocationViewController ()

@end

@implementation MainLocationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // init vars
    self.dataWrapper = [[CoreDataWrapper alloc] init];
    self.coinsorter = [[Coinsorter alloc] initWithWrapper:self.dataWrapper];
    localLibrary = [[LocalLibrary alloc] init];
    defaults = [NSUserDefaults standardUserDefaults];
    self.devices = [[NSMutableArray alloc] init];
    self.locations = [self.dataWrapper getLocations];
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
    
    [refresh addTarget:self action:@selector(PullTorefresh) forControlEvents:UIControlEventValueChanged];
    
    // setup objects
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    account = appDelegate.account;
    self.localDevice = [self.dataWrapper getDevice:account.cid];
    
    
    // add the refresh control to the table view
    self.refreshControl = refresh;
    [self.tableView addSubview:self.refreshControl];
    
    // Start networking
    self.prevBSSID = [self currentWifiBSSID];
    
    // setup network notification
    [self setupNet];
    
    // only ping if we are connected through wifi
    if (self.networkStatus == ReachableViaWiFi) {
        // ping the server to see if we are connected to bb
        [self.coinsorter pingServer:^(BOOL connected) {
            self.canConnect = connected;
            
            //[self updateUploadCountUI];
            
            if (self.canConnect) {
                // get all devices and photos from server
                // only call this when we know we are connected
                //[self syncAllFromApi];
                NSLog(@"can connect to server");
            }
        }];
    }else {
        self.canConnect = NO;
        NSLog(@"cannot connect to server");
    }


    
    // Uncomment the following line to preserve selection between presentations.
     self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
     //self.navigationItem.rightBarButtonItem = self.editButtonItem;
     UIBarButtonItem * addLocationBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addLocationbuttonPressed:)];
    self.navigationItem.rightBarButtonItem = addLocationBtn;
}

-(void) viewWillAppear:(BOOL)animated {
    self.locations = [self.dataWrapper getLocations];
    [self.tableView reloadData];;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) PullTorefresh {
    
    [self.tableView reloadData];
    
   [self.refreshControl endRefreshing];
    
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    // Return the number of rows in the section.
    return self.locations.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"LocationCell"];
    //[tableView dequeueReusableCellWithIdentifier:@"LocationCell" forIndexPath:indexPath];
    
    CSLocation *l = self.locations[[indexPath row]];
    
    if (![l.unit isEqualToString:@""]) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@",l.unit, l.name];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@",l.city,l.province];
    } else {
    
    cell.textLabel.text = l.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@",l.city,l.province];
    // Configure the cell...
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [self.dataWrapper deleteLocation:[self.locations objectAtIndex:indexPath.row]];
        [self.locations removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


// get the current wifi bssid (network id)

# pragma mark - Network

// get the initial network status
- (void) setupNet {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkNetworkStatus:) name:kReachabilityChangedNotification object:nil];
    
    self.reach = [Reachability reachabilityForInternetConnection];
    [self.reach startNotifier];
    
    NetworkStatus remoteHostStatus = [self.reach currentReachabilityStatus];
    self.networkStatus = remoteHostStatus;
    
    if (remoteHostStatus == NotReachable) {
        NSLog(@"not reachable");
    }else if (remoteHostStatus == ReachableViaWiFi) {
        NSLog(@"wifi");
    }else if (remoteHostStatus == ReachableViaWWAN) {
        NSLog(@"wwan");
    }
}

// called whenever network changes
- (void) checkNetworkStatus: (NSNotification *) notification {
    NSLog(@"network changed");
    
    NetworkStatus remoteHostStatus = [self.reach currentReachabilityStatus];
    self.networkStatus = remoteHostStatus;
    
    if (remoteHostStatus == NotReachable) {
        NSLog(@"not reachable");
        //sent a notification to dashboard when network is not reachable
        //[[NSNotificationCenter defaultCenter] postNotificationName:@"homeServerDisconnected" object:nil];
        self.canConnect = NO;
        //[self updateUploadCountUI];
    }else if (remoteHostStatus == ReachableViaWiFi) {
        // if we are connected to wifi
        // and we have a blackbox ip we have connected to before
        if (account.ip != nil) {
            [self.coinsorter pingServer:^(BOOL connected) {
                self.canConnect = connected;
                //sent a notification to dashboard when network connects with home server
                //[[NSNotificationCenter defaultCenter] postNotificationName:@"homeServerConnected" object:nil];
                //[self updateUploadCountUI];
            }];
        }
    }else if (remoteHostStatus == ReachableViaWWAN) {
        NSLog(@"wwan");
        //sent a notification to dashboard when network connects with WIFI not home server
        //[[NSNotificationCenter defaultCenter] postNotificationName:@"homeServerDisconnected" object:nil];
        self.canConnect = NO;
        //[self updateUploadCountUI];
    }
}


- (NSString *)currentWifiBSSID {
    // Does not work on the simulator.
    NSString *bssid = nil;
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    for (NSString *ifnam in ifs) {
        NSDictionary *info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        if (info[@"BSSID"]) {
            bssid = info[@"BSSID"];
        }
    }
    return bssid;
}

#pragma mark - Button Actions

-(void) addLocationbuttonPressed: (id) sender {
    
    [self performSegueWithIdentifier:@"LocationSettingSegue" sender:self];
}

@end
