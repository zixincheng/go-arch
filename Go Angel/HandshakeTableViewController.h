//
//  HandshakeTableViewController.h
//  Go Arch
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import <UIKit/UIKit.h>
#import "Server.h"
#import "GCDAsyncUdpSocket.h"
#import "ConnectViewController.h"
#import "Coinsorter.h"
#import "Reachability.h"
#import "NetWorkCheck.h"


// this controller shows a list of all avaiable server to connect to
// and an option to manually enter server ip

@interface HandshakeTableViewController : UITableViewController <GCDAsyncUdpSocketDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) NSMutableArray *servers;
@property (nonatomic, strong) GCDAsyncUdpSocket *sendUdpSocket;
@property (nonatomic, strong) GCDAsyncUdpSocket *recieveUdpSocket;
@property (nonatomic, strong) Coinsorter *coinsorter;
@property (nonatomic, retain) Reachability *reach;
@property (nonatomic, retain) NetWorkCheck *netWorkCheck;
@property (nonatomic) NSInteger networkStatus;
@property (nonatomic, strong) NSTimer *udpTimer;

@property (nonatomic, strong) NSString *ip;
@property (nonatomic, strong) NSString *localIp;
@property (nonatomic, strong) NSString *externalIp;
@property (nonatomic, strong) NSString *sid;
@property (nonatomic, strong) NSString *name;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *addServerButton;

@end
