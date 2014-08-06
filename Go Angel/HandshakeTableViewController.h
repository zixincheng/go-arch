//
//  HandshakeTableViewController.h
//  Go Angel
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
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
