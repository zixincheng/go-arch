//
//  NetWorkCheck.h
//  Go Arch
//
//  Created by zcheng on 2015-03-04.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncUdpSocket.h"
#import "Reachability.h"
#import "Coinsorter.h"
#import "CoreDataWrapper.h"
#import <SystemConfiguration/CaptiveNetwork.h>

@class Coinsorter;

@interface NetWorkCheck : NSObject <GCDAsyncUdpSocketDelegate> {
    AccountDataWrapper *account;
}

@property (nonatomic, strong) GCDAsyncUdpSocket *sendUdpSocket;
@property (nonatomic, strong) GCDAsyncUdpSocket *recieveUdpSocket;
@property (nonatomic, strong) Coinsorter *coinsorter;
@property (nonatomic, retain) Reachability *reach;
@property (nonatomic, strong) CoreDataWrapper *dataWrapper;
@property (nonatomic) NSInteger networkStatus;
@property (nonatomic) NSString *checkNetWorkStat;
@property (nonatomic) NSString *prevBSSID;

-(void) setupNet;
-(id) initWithCoinsorter:(Coinsorter *)coinsorter;
@end
