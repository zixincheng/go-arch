//
//  HandshakeTableViewController.m
//  Go Arch
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import "HandshakeTableViewController.h"
#import "DeviceViewController.h"

@interface HandshakeTableViewController ()

@end

@implementation HandshakeTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
  self = [super initWithStyle:style];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void) viewDidDisappear:(BOOL)animated
{
    NSLog(@"viewDidDisappear");
    [self.udpTimer invalidate];
    self.udpTimer = nil;
}

- (void) viewDidAppear:(BOOL)animated
{
    NSLog(@"viewDidAppear");
    // Setup a timer to refresh every 10 seconds

    if (self.networkStatus == ReachableViaWiFi) {
        self.udpTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(periodicallySendUDP) userInfo:nil repeats:YES];
        [self sendUDPMessage];
    }
}


- (void)viewDidLoad
{
  [super viewDidLoad];
  
  // Uncomment the following line to preserve selection between presentations.
  // self.clearsSelectionOnViewWillAppear = NO;
  
  // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
  // self.navigationItem.rightBarButtonItem = self.editButtonItem;
  
  self.coinsorter = [[Coinsorter alloc] init];
  self.servers = [[NSMutableArray alloc] init];
  self.netWorkCheck = [[NetWorkCheck alloc]init];
  [self setupNet];
  self.sendUdpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];
  self.recieveUdpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];
  
  UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
  refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
  
  [refresh addTarget:self action:@selector(sendUDPMessage) forControlEvents:UIControlEventValueChanged];
  
  self.refreshControl = refresh;
    
  // Setup the receiver and immediately send a UPD broadcast
  [self setupReciveUDPMessage];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changePass) name:@"passwordChanged" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scannedQR:) name:@"scanQRNotification" object:nil];
}

-(void)periodicallySendUDP{
    NSLog(@"periodicallySendUDP Called.");
    
    [self sendUDPMessage];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  // Return the number of sections.
  return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  // Return the number of rows in the section.
  return self.servers.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"serverPrototypeCell" forIndexPath:indexPath];
  
  Server *s = self.servers[[indexPath row]];
  cell.textLabel.text = s.hostname;
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  
    Server *s = self.servers[[indexPath row]];
    self.ip = s.currentIp;
    self.sid = s.serverId;
    self.name = s.hostname;
    self.localIp = s.localIp;
    self.externalIp = s.externalIp;
    NSLog(@"extranl ip %@",self.externalIp);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"" forKey:@"password"];
    
    [self authDevice:@""];
  // Deselect
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void) changePass {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Login Failed" message:@"Password Has been changed, Please Enter New Password" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Confirm", nil];
        
        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        [[alertView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeURL];
        [[alertView textFieldAtIndex:0] becomeFirstResponder];
        
        alertView.tag = 1;
        [alertView show];
    });
    
}


- (IBAction)buttonPressed:(id)sender {
  if (sender == self.addServerButton) {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Manually Add Server" message:@"Enter Server IP" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
    
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [[alertView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeURL];
    [[alertView textFieldAtIndex:0] becomeFirstResponder];
      
    alertView.tag = 0;
    [alertView show];
  }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  NSString *buttonTitle=[alertView buttonTitleAtIndex:buttonIndex];
    if (alertView.tag == 0) {
        if([buttonTitle isEqualToString:@"Cancel"]) {
            return;
        }
        else if([buttonTitle isEqualToString:@"Add"]) {
            NSString *text = [alertView textFieldAtIndex:0].text;
            
            if (![text isEqualToString:@""]) {
                [self.coinsorter getSid:text infoCallback:^(NSData *data) {
                    if (data) {
                        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                        NSString *sid = [jsonData objectForKey:@"SID"];
                        NSString *hostname = [jsonData objectForKey:@"HOSTNAME"];
                        NSString *externalIp = [jsonData objectForKeyedSubscript:@"IP_EXTERNAL"];
                        NSString *localIp = [jsonData objectForKeyedSubscript:@"IP_INTERNAL"];
                        Server *s = [[Server alloc] init];
                        s.localIp = localIp;
                        s.externalIp = externalIp;
                        s.currentIp = text;
                        s.hostname = hostname;
                        s.serverId = sid;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            @synchronized (self.servers) {
                                
                                // Before adding it, lets attempt to find it in the list first.
                                NSArray *array = [self.servers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"serverId == %@", sid]];
                                
                                if (array == nil || [array count] == 0) {
                                    // If nothing exists at all
                                    [self.servers addObject:s];
                                    [self.tableView reloadData];
                                }
                            }
                        });
                    } else {
                        NSLog(@"no server");
                    }
                }];
            }
        }
    } else if (alertView.tag == 1) {
        if([buttonTitle isEqualToString:@"Cancel"]) {
            return;
        }
        else if([buttonTitle isEqualToString:@"Confirm"]) {
            NSString *text = [alertView textFieldAtIndex:0].text;
            
            if (![text isEqualToString:@""]) {
                [self authDevice:text];
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setObject:text forKey:@"password"];
            }
        }

    }
}
/*
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  //    UINavigationController *navController = (UINavigationController *)segue.destinationViewController;
  //    ConnectViewController *connectController = (ConnectViewController *)navController.topViewController;
  
  NSIndexPath *path = [self.tableView indexPathForSelectedRow];
  Server *s = self.servers[[path row]];
  
  ConnectViewController *connectController = (ConnectViewController *)segue.destinationViewController;
  connectController.ip = s.ip;
  connectController.sid = s.serverId;
  connectController.name = s.hostname;
}
*/
- (void) sendUDPMessage {
  NSData *data = [[NSString stringWithFormat:@"hello server - no connect"] dataUsingEncoding:NSUTF8StringEncoding];
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.tableView reloadData];
  });
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
    NSLog(@"sending udp broadcast");
    
    NSError *err;
    [self.sendUdpSocket enableBroadcast:YES error:&err];
    //    [self.sendUdpSocket sendData:data withTimeout:-1 tag:1];
    [self.sendUdpSocket sendData:data toHost:@"255.255.255.255" port:9999 withTimeout:-1 tag:1];
  });
  [self.refreshControl endRefreshing];
}

- (void) setupReciveUDPMessage {
  NSError *err;
  
  if (![self.recieveUdpSocket bindToPort:9998 error:&err]) {
    NSLog(@"error binding to port");
    abort();
  }
  if (![self.recieveUdpSocket beginReceiving:&err]) {
    NSLog(@"error begin receiving");
    abort();
  }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext {

  NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  
  NSString *host = nil;
  uint16_t port = 0;
  [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
  
  if (msg)  {
    NSLog(@"found server - %@", host);
    
    // found the server, now need to make api call to get server info
    [self.coinsorter getSid:host infoCallback:^(NSData *data) {
      if (data) {
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSString *sid = [jsonData objectForKey:@"SID"];
        NSString *hostname = [jsonData objectForKey:@"HOSTNAME"];
        NSString *externalIp = [jsonData objectForKeyedSubscript:@"IP_EXTERNAL"];
        NSString *localIp = [jsonData objectForKeyedSubscript:@"IP_INTERNAL"];
        Server *s = [[Server alloc] init];
        s.localIp = localIp;
        s.externalIp = externalIp;
        s.currentIp = host;
        s.hostname = hostname;
        s.serverId = sid;

        
        dispatch_async(dispatch_get_main_queue(), ^{
          @synchronized (self.servers) {
              
            // Before adding it, lets attempt to find it in the list first.
            NSArray *array = [self.servers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"serverId == %@", sid]];
            
            if (array == nil || [array count] == 0) {
                // If nothing exists at all
                [self.servers addObject:s];
                [self.tableView reloadData];
            }
          }
        });
      }
    }];
  } else {
      NSLog(@"cannot find server");
      [self.sendUdpSocket close];
  }
}

- (void) scannedQR: (NSNotification *) notification {
  NSDictionary *userInfo = [notification userInfo];
  if (userInfo) {
    NSString *hash_token = [userInfo objectForKey:@"hash_token"];
    NSString *cid = [userInfo objectForKey:@"cid"];
    NSString *ip_internal = [userInfo objectForKey:@"IP_INTERNAL"];
    NSString *ip_external = [userInfo objectForKey:@"IP_EXTERNAL"];
    
    if ([ip_internal containsString:@":"]) {
      ip_internal = [ip_internal substringWithRange:NSMakeRange(0, [ip_internal length] - 5)];
    }
    if ([ip_external containsString:@":"]) {
      ip_external = [ip_external substringWithRange:NSMakeRange(0, [ip_external length] - 5)];
    }
    
    NSLog(@"GOT THE INFO %@", userInfo);
    
    [self.coinsorter getSid:ip_internal infoCallback:^(NSData *data) {
      if (data) {
        [self addQRInfo:data];
        self.ip = ip_internal;
        [self authDeviceQR:hash_token fromDeviceID:cid toHost:ip_internal];
      } else {
        [self.coinsorter getSid:ip_external infoCallback:^(NSData *data) {
          if (data) {
            [self addQRInfo: data];
            self.ip = ip_external;
            [self authDeviceQR:hash_token fromDeviceID:cid toHost:ip_external];
          } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"failAuthNotification" object:nil];
          }
        }];
      }
    }];
  }
}

- (void) addQRInfo: (NSData *) data {
  NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
  NSString *sid = [jsonData objectForKey:@"SID"];
  NSString *hostname = [jsonData objectForKey:@"HOSTNAME"];
  NSString *ip_internal = [jsonData objectForKey:@"IP_INTERNAL"];
  NSString *ip_external = [jsonData objectForKey:@"IP_EXTERNAL"];
  
  self.sid = sid;
  self.name = hostname;
  self.localIp = ip_internal;
  self.externalIp = ip_external;

}

// make api call with hash_token to auth from scanned qr code
- (void) authDeviceQR: (NSString *) hash_token fromDeviceID: (NSString *) cid toHost: (NSString *) host {
  AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
  AccountDataWrapper *account = appDelegate.account;
  [self.coinsorter getToken:host fromTokenHash:hash_token toDevice:cid callback:^(NSDictionary *authData) {
    
    if (authData == nil || authData == NULL) {
      // we could not connect to server
      NSLog(@"could not connect to server");
      [[NSNotificationCenter defaultCenter] postNotificationName:@"failAuthNotification" object:nil];
      return;
    }
    
    NSString *token = [authData objectForKey:@"token"];
    if (token == nil || token == NULL) {
      [[NSNotificationCenter defaultCenter] postNotificationName:@"failAuthNotification" object:nil];
      // if we get here we assume the password is incorrect
      return;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *cid = [authData objectForKey: @"_id"];
    
    NSLog(@"token: %@", token);
    NSLog(@"cid: %@", cid);
    
    NSLog(@"internal IP: %@", self.localIp);
    NSLog(@"external IP: %@", self.externalIp);
    NSLog(@"current IP: %@", self.ip);
    
    account.currentIp = self.ip;
    account.token = token;
    account.cid = cid;
    account.sid = self.sid;
    account.name = self.name;
    account.localIp = self.localIp;
    account.externalIp = self.externalIp;
    
    [account saveSettings];
    
    CSDevice *device = [[CSDevice alloc] init];
    
    device.deviceName = [defaults valueForKey:@"deviceName"];
    device.remoteId = cid;
    
    CoreDataWrapper *dataWrapper = [[CoreDataWrapper alloc] init];
    [dataWrapper addUpdateDevice:device];
    
    NSLog(@"QR Auth successful");
    dispatch_async(dispatch_get_main_queue(), ^ {
      [self performSegueWithIdentifier:@"deviceSegue" sender:self];
    });
  }];
}

// make api call with password to register device
- (void) authDevice: (NSString *) pass {
  AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
  AccountDataWrapper *account = appDelegate.account;
  [self.coinsorter getToken:self.ip pass:pass callback: ^(NSDictionary *authData) {
    if (authData == nil || authData == NULL) {
      // we could not connect to server
      NSLog(@"could not connect to server");
      return;
    }

    NSString *token = [authData objectForKey:@"token"];
    if (token == nil || token == NULL) {
      // if we get here we assume the password is incorrect
      [[NSNotificationCenter defaultCenter] postNotificationName:@"passwordChanged" object:nil];
      NSLog(@"password incorrect");
      return;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *cid = [authData objectForKey: @"_id"];
    
    NSLog(@"token: %@", token);
    NSLog(@"cid: %@", cid);
    
    account.currentIp = self.ip;
    account.token = token;
    account.cid = cid;
    account.sid = self.sid;
    account.name = self.name;
    account.localIp = self.localIp;
    account.externalIp = self.externalIp;
      NSLog(@"ex ip %@",account.externalIp);
    [account saveSettings];
    
    CSDevice *device = [[CSDevice alloc] init];
    
    device.deviceName = [defaults valueForKey:@"deviceName"];
    device.remoteId = cid;
    
    CoreDataWrapper *dataWrapper = [[CoreDataWrapper alloc] init];
    [dataWrapper addUpdateDevice:device];
    
    dispatch_async(dispatch_get_main_queue(), ^ {
      [self performSegueWithIdentifier:@"deviceSegue" sender:self];
    });
  }];
}

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

- (void) checkNetworkStatus: (NSNotification *) notification {
    NSLog(@"network changed");
    
    NetworkStatus remoteHostStatus = [self.reach currentReachabilityStatus];
    self.networkStatus = remoteHostStatus;
    
    if (remoteHostStatus == NotReachable) {
        NSLog(@"not reachable");
    }else if (remoteHostStatus == ReachableViaWiFi) {
        [self sendUDPMessage];
        
    }else if (remoteHostStatus == ReachableViaWWAN) {
        NSLog(@"wwan");
    }
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
