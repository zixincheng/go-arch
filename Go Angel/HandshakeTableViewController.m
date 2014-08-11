//
//  HandshakeTableViewController.m
//  Go Angel
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

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  // Uncomment the following line to preserve selection between presentations.
  // self.clearsSelectionOnViewWillAppear = NO;
  
  // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
  // self.navigationItem.rightBarButtonItem = self.editButtonItem;
  
  self.coinsorter = [[Coinsorter alloc] init];
  
  self.servers = [[NSMutableArray alloc] init];
  
  self.sendUdpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];
  self.recieveUdpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];
  
  UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
  refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
  
  [refresh addTarget:self action:@selector(sendUDPMessage) forControlEvents:UIControlEventValueChanged];
  
  self.refreshControl = refresh;
  
  [self setupReciveUDPMessage];
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
  
  // Deselect
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (IBAction)buttonPressed:(id)sender {
  if (sender == self.addServerButton) {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Manually Add Server" message:@"Enter Server IP" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
    
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [[alertView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeURL];
    [[alertView textFieldAtIndex:0] becomeFirstResponder];
    
    [alertView show];
  }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  NSString *buttonTitle=[alertView buttonTitleAtIndex:buttonIndex];
  if([buttonTitle isEqualToString:@"Cancel"]) {
    return;
  }
  else if([buttonTitle isEqualToString:@"Add"]) {
    NSString *text = [alertView textFieldAtIndex:0].text;
    
    if (![text isEqualToString:@""]) {
      Server *s = [[Server alloc] init];
      s.ip = text;
      [self.servers addObject:s];
      
      [self.tableView reloadData];
    }
  }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  //    UINavigationController *navController = (UINavigationController *)segue.destinationViewController;
  //    ConnectViewController *connectController = (ConnectViewController *)navController.topViewController;
  
  NSIndexPath *path = [self.tableView indexPathForSelectedRow];
  Server *s = self.servers[[path row]];
  
  ConnectViewController *connectController = (ConnectViewController *)segue.destinationViewController;
  connectController.ip = s.ip;
  connectController.sid = s.serverId;
}

- (void) sendUDPMessage {
  NSData *data = [[NSString stringWithFormat:@"hello server - no connect"] dataUsingEncoding:NSUTF8StringEncoding];
  
  [self.servers removeAllObjects];
  
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
        
        Server *s = [[Server alloc] init];
        s.ip = host;
        s.hostname = hostname;
        s.serverId = sid;
        
        dispatch_async(dispatch_get_main_queue(), ^{
          @synchronized (self.servers) {
            [self.servers addObject:s];
            [self.tableView reloadData];
          }
        });
      }
    }];
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
