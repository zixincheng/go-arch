//
//  RadarViewController.m
//  Go Arch
//
//  Created by zcheng on 2014-12-16.
//  Copyright (c) 2014 acdGO Software Ltd. All rights reserved.
//

#import "RadarViewController.h"

@interface RadarViewController ()
{
    UIView *hand;
    NSMutableArray *targets;
    NSMutableArray *Buttons;
    int count;
    NSTimer *timer;
    
}
@end

@implementation RadarViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
    [self.view addSubview:backgroundView];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    Buttons = [[NSMutableArray alloc] init];
    self.coinsorter = [[Coinsorter alloc] init];
    self.servers = [[NSMutableArray alloc] init];
    self.selectedServer =[[Server alloc]init];
    
    self.sendUdpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];
    self.recieveUdpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];
    
    // Setup the receiver and immediately send a UPD broadcast
    [self setupReciveUDPMessage];
    targets = [[NSMutableArray alloc] init];
    [self createView];
    
    [self createContourLine];
    
    [self createHand];
    [self start];
    /*
    [self.searchBtn addTarget:self
               action:@selector(search:)
     forControlEvents:UIControlEventTouchUpInside];
    [self.searchBtn setTitle:@"Search" forState:UIControlStateNormal];
    [self.view addSubview:self.buttonView];
    [self.buttonView addSubview:self.searchBtn];
     */
}
/*
- (void) search:(id)sender {
    UIButton *search = (UIButton *)sender;
    if ([search.currentTitle isEqualToString:@"Search"]) {
        [self start];
        [self udpcall];
        [self.searchBtn setTitle:@"Stop" forState:UIControlStateNormal];
        
    } else {
        [timer invalidate];
        timer = nil;
        [self.udpTimer invalidate];
        self.udpTimer = nil;
        [self.searchBtn setTitle:@"Search" forState:UIControlStateNormal];
        
    }
    
}
 */
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void) viewDidDisappear:(BOOL)animated
{
    NSLog(@"viewDidDisappear");
    [self.udpTimer invalidate];
    self.udpTimer = nil;
}

-(void) udpcall {
     // Setup a timer to refresh every 10 seconds
    self.udpTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(periodicallySendUDP) userInfo:nil repeats:YES];
    
}

- (void) viewDidAppear:(BOOL)animated
{
    NSLog(@"viewDidAppear");
    // Setup a timer to refresh every 10 seconds
    [self udpcall];
    [self sendUDPMessage];
}

-(void)periodicallySendUDP{
    NSLog(@"periodicallySendUDP Called.");
    
    [self sendUDPMessage];
}

#pragma mark - Table view data source

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

#pragma mark -
#pragma mark View

- (void) sendUDPMessage {
    NSData *data = [[NSString stringWithFormat:@"hello server - no connect"] dataUsingEncoding:NSUTF8StringEncoding];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
        NSLog(@"sending udp broadcast");
        
        NSError *err;
        [self.sendUdpSocket enableBroadcast:YES error:&err];
        //    [self.sendUdpSocket sendData:data withTimeout:-1 tag:1];
        [self.sendUdpSocket sendData:data toHost:@"255.255.255.255" port:9999 withTimeout:-1 tag:1];
    });
    
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
                            [self createTargets: s];
                        }
                    }
                });
            }
        }];
    }
}

#pragma mark -
#pragma mark Draw Server images

- (void)createContourLine
{
    float radius[] = {50, 100, 150};
    for (int i=0; i<3; i++) {
        float size = radius[i] * 2.0;
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size, size)];
        line.backgroundColor = [UIColor clearColor];
        line.layer.borderColor = [UIColor whiteColor].CGColor;
        line.layer.borderWidth = 2;
        line.center = CGPointMake(self.view.frame.size.width/2, (self.view.frame.size.height-self.navigationController.navigationBar.frame.size.height)/2);
        line.layer.cornerRadius = radius[i];
        [self.view addSubview:line];
    }
}

- (void)createHand
{
    hand = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 150, 4)];
    hand.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:hand];
    hand.layer.anchorPoint = CGPointMake(0, 0.5);
    hand.layer.position = CGPointMake(self.view.frame.size.width/2, (self.view.frame.size.height-self.navigationController.navigationBar.frame.size.height)/2);
}

// manuelly create server server label
- (void)createView{
    
    UIView *t0 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, 100)];
    //t0.layer.cornerRadius = 40.0;
    t0.center = CGPointMake(50, 200);
    t0.backgroundColor = [UIColor clearColor];
    t0.alpha = 0.0;
    t0.layer.borderColor = [UIColor clearColor].CGColor;
    [self.view addSubview:t0];
    [targets addObject:t0];
    
    
    UIView *t7 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
    t7.layer.cornerRadius = 40.0;
    t7.center = CGPointMake(100, 378);
    t7.backgroundColor = [UIColor clearColor];
    t7.alpha = 0;
    [self.view addSubview:t7];
    [targets addObject:t7];
    
    UIView *t6 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
    t6.layer.cornerRadius = 40.0;
    t6.center = CGPointMake(219, 378);
    t6.backgroundColor = [UIColor clearColor];
    t6.alpha = 0;
    [self.view addSubview:t6];
    [targets addObject:t6];
    
    UIView *t1 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
    t1.layer.cornerRadius = 40.0;
    t1.center = CGPointMake(150, 150);
    t1.backgroundColor = [UIColor clearColor];
    t1.alpha = 0.0;
    [self.view addSubview:t1];
    [targets addObject:t1];
    
    UIView *t2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
    t2.layer.cornerRadius = 40.0;
    t2.center = CGPointMake(254, 150);
    t2.backgroundColor = [UIColor clearColor];
    t2.alpha = 0.0;
    [self.view addSubview:t2];
    [targets addObject:t2];
    
    UIView *t3 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
    t3.layer.cornerRadius = 40.0;
    t3.center = CGPointMake(254, 286);
    t3.backgroundColor = [UIColor clearColor];
    t3.alpha = 0.0;
    [self.view addSubview:t3];
    [targets addObject:t3];
    
    UIView *t5 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
    t5.layer.cornerRadius = 40.0;
    t5.center = CGPointMake(119, 278);
    t5.backgroundColor = [UIColor clearColor];
    t5.alpha = 0.0;
    [self.view addSubview:t5];
    [targets addObject:t5];
    
}
//create images and set the text of server label
- (void)createTargets: (Server *) s
{
 
    
        NSLog(@"%lu",(unsigned long)self.servers.count);
        UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [button addTarget:self
                   action:@selector(displayServer:)
         forControlEvents:UIControlEventTouchUpInside];
        button.frame = CGRectMake(0, 0, 80, 80);
        button.layer.cornerRadius = 40.0;
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:button.frame];
        imageView.image = [UIImage imageNamed:@"box.png"];
        UIImage *buttonImage = [UIImage imageNamed:@"box.png"];
        UIGraphicsBeginImageContext(CGSizeMake(80, 80));
        [buttonImage drawInRect:CGRectMake(0, 0, 80, 80)];
        buttonImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [button setImage:buttonImage forState:UIControlStateNormal];
        [Buttons addObject:button];
        UILabel *lbl = [[UILabel alloc] init];
        [lbl setFrame:CGRectMake(0,80,80,20)];
        lbl.backgroundColor=[UIColor clearColor];
        lbl.text= s.hostname;
        lbl.textAlignment = NSTextAlignmentCenter;
        lbl.adjustsFontSizeToFitWidth = YES;
        UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:16];
        [lbl setFont:font];
        lbl.textColor=[UIColor whiteColor];
        UIView *t = [targets objectAtIndex:(self.servers.count-1)];
        [self.view addSubview:t];
        [t addSubview:button];
        [t addSubview:lbl];
        [t addSubview:imageView];
        button.tag = self.servers.count-1;

    NSLog(@"%@",button);
}

// start the timer to move the radar hand
- (void)start
{
    timer = [NSTimer scheduledTimerWithTimeInterval:1.5/60.0 target:self selector:@selector(tick:) userInfo:nil repeats:YES];
}

- (void)tick:(NSTimer*)sender
{
    hand.transform = CGAffineTransformRotate(hand.transform, M_PI * 0.01);
    float angle = [[hand.layer valueForKeyPath:@"transform.rotation.z"] floatValue];
    
    CALayer *line = [CALayer layer];
    line.frame = CGRectMake(0, 0, 150, 5);
    line.anchorPoint = CGPointMake(0, 0.5);
    line.position = CGPointMake(self.view.frame.size.width/2, (self.view.frame.size.height-self.navigationController.navigationBar.frame.size.height)/2);
    line.transform = CATransform3DMakeRotation(angle, 0, 0, 1);
    line.backgroundColor = [UIColor whiteColor].CGColor;
    line.opacity = 0;
    [self.view.layer addSublayer:line];
    if ( [Buttons count] != 0) {
          for (int i=0; i<[Buttons count]; i++) {
             UIButton *b = [Buttons objectAtIndex:i];
             if ([hand.layer.presentationLayer hitTest:b.superview.center]) {
                b.superview.alpha = 0.95;
         //[UIView animateWithDuration:1.5 animations:^{
          //  t.alpha = 0.0;
         //}];
           }
         }
    }
    CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fade.fromValue = @1.0;
    fade.toValue = @0;
    fade.duration = 0.5;
    [line addAnimation:fade forKey:nil];
    [line performSelector:@selector(removeFromSuperlayer) withObject:nil afterDelay:0.5];
    
}

#pragma mark -
#pragma mark server connection


-(void) displayServer: (UIButton *) sender {
        NSLog(@"%ld",(long)sender.tag);

    Server *s = self.servers[sender.tag];
    
    self.selectedServer.currentIp = s.currentIp;
    self.selectedServer.serverId = s.serverId;
    self.selectedServer.hostname = s.hostname;
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[ NSString stringWithFormat:@"server IP: %@",s.currentIp] message:[ NSString stringWithFormat:@"Server Name: %@",s.hostname] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Connect", nil];
    
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [[alertView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeURL];
    [[alertView textFieldAtIndex:0] becomeFirstResponder];
    
    alertView.tag = 1;
    
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *buttonTitle=[alertView buttonTitleAtIndex:buttonIndex];
    if (alertView.tag == 1) {
        if([buttonTitle isEqualToString:@"Cancel"]) {
            return;
        }
        else if([buttonTitle isEqualToString:@"Connect"]) {
            NSString *text = [alertView textFieldAtIndex:0].text;
        
            if (![text isEqualToString:@""]) {
                [self authDevice:text];
            }
        }
    } else if (alertView.tag ==2) {
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

                        Server *s = [[Server alloc] init];
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
                                    [self createTargets: s];
                                }
                            }
                        });
                    } else {
                        NSLog(@"no server");
                    }
                }];
            }
        }

        
    }
}

// make api call with password to register device
- (void) authDevice: (NSString *) pass {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    AccountDataWrapper *account = appDelegate.account;
    
    [self.coinsorter getToken:self.selectedServer.currentIp pass:pass callback:^(NSDictionary *authData) {
        if (authData == nil || authData == NULL) {
            // we could not connect to server
           // [self asyncSetErrorLabel:@"could not connect to server"];
            NSLog(@"could not connect to server");
            return;
        }
        
        NSString *token = [authData objectForKey:@"token"];
        if (token == nil || token == NULL) {
            // if we get here we assume the password is incorrect
          //  [self asyncSetErrorLabel:@"password incorrect"];
            
          //  dispatch_async(dispatch_get_main_queue(), ^ {
         //       [self.passTextField setText:@""];
          //  });
            
            NSLog(@"password incorrect");
            return;
        }
        
        NSString *cid = [authData objectForKey: @"_id"];
        
        NSLog(@"token: %@", token);
        NSLog(@"cid: %@", cid);
        
        account.currentIp = self.selectedServer.currentIp;
        account.token = token;
        account.cid = cid;
        account.sid = self.selectedServer.serverId;
        account.name = self.selectedServer.hostname;
        
        [account saveSettings];
        
        CSDevice *device = [[CSDevice alloc] init];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        device.deviceName = [defaults valueForKey:@"deviceName"];
        device.remoteId = cid;
        
        CoreDataWrapper *dataWrapper = [[CoreDataWrapper alloc] init];
        [dataWrapper addUpdateDevice:device];
        
        dispatch_async(dispatch_get_main_queue(), ^ {
            [self performSegueWithIdentifier:@"deviceSegue" sender:self];
        });
    }];
}

- (IBAction)buttonPressed:(id)sender {
    if (sender == self.addServerButton) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Manually Add Server" message:@"Enter Server IP" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
        
        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        [[alertView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeURL];
        [[alertView textFieldAtIndex:0] becomeFirstResponder];
        alertView.tag =2;
        [alertView show];
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
