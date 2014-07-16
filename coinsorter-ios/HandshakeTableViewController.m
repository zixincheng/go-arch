//
//  HandshakeTableViewController.m
//  coinsorter-ios
//
//  Created by Jake Runzer on 7/15/14.
//  Copyright (c) 2014 Jake Runzer. All rights reserved.
//

#import "HandshakeTableViewController.h"
#import "DeviceTableViewController.h"

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
    cell.textLabel.text = s.ip;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Server *s = self.servers[[indexPath row]];
    
    UIAlertView *passInput = [[UIAlertView alloc] initWithTitle:s.ip message:@"Please Enter Password for this Server" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Done", nil];
    passInput.alertViewStyle = UIAlertViewStyleSecureTextInput;
    [passInput show];
    
    // Deselect
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *buttonText = [alertView buttonTitleAtIndex:buttonIndex];
    
    if ([buttonText isEqualToString:@"Done"]) {
        
    }
}

- (IBAction)reSync:(id)sender {
    [self sendUDPMessage];
}

- (void) sendUDPMessage {
    NSData *data = [[NSString stringWithFormat:@"hello server - no connect"] dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *err;
    [self.sendUdpSocket enableBroadcast:YES error:&err];
    //    [self.sendUdpSocket sendData:data withTimeout:-1 tag:1];
    [self.sendUdpSocket sendData:data toHost:@"255.255.255.255" port:9999 withTimeout:-1 tag:1];
    
    [self.servers removeAllObjects];
    
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
        if (msg)  {
            NSLog(@"found server - %@", host);
            
            Server *s = [[Server alloc] init];
            s.ip = [NSString stringWithFormat:@"%@", host];
            s.serverId = msg;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                @synchronized (self.servers) {
                    [self.servers addObject:s];
                    [self.tableView reloadData];
                }
            });
        }
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
