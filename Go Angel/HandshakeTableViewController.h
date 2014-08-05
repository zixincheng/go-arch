//
//  HandshakeTableViewController.h
//  coinsorter-ios
//
//  Created by Jake Runzer on 7/15/14.
//  Copyright (c) 2014 Jake Runzer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Server.h"
#import "GCDAsyncUdpSocket.h"
#import "ConnectViewController.h"

@interface HandshakeTableViewController : UITableViewController <GCDAsyncUdpSocketDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) NSMutableArray *servers;
@property (nonatomic, strong) GCDAsyncUdpSocket *sendUdpSocket;
@property (nonatomic, strong) GCDAsyncUdpSocket *recieveUdpSocket;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *addServerButton;

@end
