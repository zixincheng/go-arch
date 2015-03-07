//
//  RadarViewController.h
//  Go Arch
//
//  Created by zcheng on 2014-12-16.
//  Copyright (c) 2014 acdGO Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Server.h"
#import "GCDAsyncUdpSocket.h"
#import "ConnectViewController.h"
#import "Coinsorter.h"
#import "ConnectViewController.h"

@interface RadarViewController : UIViewController<GCDAsyncUdpSocketDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) NSMutableArray *servers;
@property (nonatomic, strong) GCDAsyncUdpSocket *sendUdpSocket;
@property (nonatomic, strong) GCDAsyncUdpSocket *recieveUdpSocket;
@property (nonatomic, strong) Coinsorter *coinsorter;
@property (nonatomic, strong) NSTimer *udpTimer;
@property (nonatomic, strong) Server *selectedServer;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *addServerButton;


@end
