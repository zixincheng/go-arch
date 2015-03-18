//
//  NetWorkCheck.m
//  Go Arch
//
//  Created by zcheng on 2015-03-04.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "NetWorkCheck.h"

@implementation NetWorkCheck
-(id) initWithCoinsorter:(Coinsorter *)coinsorter {
    self = [super init];
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    account = appDelegate.account;
    
    self.dataWrapper = [[CoreDataWrapper alloc] init];
    
    self.coinsorter = coinsorter;
    self.reach = [Reachability reachabilityForInternetConnection];
    
    self.sendUdpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];
    self.recieveUdpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkNetworkStatus:) name:kReachabilityChangedNotification object:nil];
    return self;
}

- (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIApplicationWillEnterForegroundNotification" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

- (void) setupNet {
    
    [self.reach startNotifier];
        
        NetworkStatus remoteHostStatus = [self.reach currentReachabilityStatus];
        self.networkStatus = remoteHostStatus;
        
        if (remoteHostStatus == NotReachable) {
            NSLog(@"not reachable");
        }else if (remoteHostStatus == ReachableViaWiFi) {
            NSLog(@"wifi");
            [self pingLocal];
        }else if (remoteHostStatus == ReachableViaWWAN) {
            NSLog(@"wwan");
            account.currentIp = account.externalIp;
            [self.coinsorter pingServer:^(BOOL connected) {
                if (connected) {
                    NSLog(@"wwan connected");
                    self.checkNetWorkStat = WWAN;
                    NSDictionary *stat = @{@"status" : self.checkNetWorkStat};
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"networkStatusChanged" object:nil userInfo:stat];
                } else {
                    NSLog(@"wwan offline");
                    self.checkNetWorkStat = OFFLINE;
                    NSDictionary *stat = @{@"status" : self.checkNetWorkStat};
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"networkStatusChanged" object:nil userInfo:stat];
                }
            }];
        }
}

- (void) sendUDPMessage {
    NSData *data = [[NSString stringWithFormat:@"hello server - no connect"] dataUsingEncoding:NSUTF8StringEncoding];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
        NSLog(@"sending udp broadcast");
        
        NSError *err;
        [self.sendUdpSocket enableBroadcast:YES error:&err];
        //    [self.sendUdpSocket sendData:data withTimeout:-1 tag:1];
        [self.sendUdpSocket sendData:data toHost:@"255.255.255.255" port:9999 withTimeout:2 tag:1];
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
    
    if (msg && [host isEqualToString:account.localIp])  {
        NSLog(@"found server - %@", host);
        NSLog(@"device is in LAN");
        account.currentIp = account.localIp;
        
        
    }
}

// called whenever network changes
- (void) checkNetworkStatus: (NSNotification *) notification {
    NSLog(@"network changed");
    
    NetworkStatus remoteHostStatus = [self.reach currentReachabilityStatus];
    self.networkStatus = remoteHostStatus;
    
    if (remoteHostStatus == NotReachable) {
        NSLog(@"not reachable");
        self.checkNetWorkStat = OFFLINE;
        NSDictionary *stat = @{@"status" : self.checkNetWorkStat};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"networkStatusChanged" object:nil userInfo:stat];
    }else if (remoteHostStatus == ReachableViaWiFi) {
        // if we are connected to wifi
        // and we have a blackbox ip we have connected to before
         NSLog(@"wifi");
        [self pingLocal];
    } else if (remoteHostStatus == ReachableViaWWAN) {
        NSLog(@"wwan");
        //sent a notification to dashboard when network connects with WIFI not home server
        //[[NSNotificationCenter defaultCenter] postNotificationName:@"homeServerDisconnected" object:nil];
        account.currentIp = account.externalIp;
            [self.coinsorter pingServer:^(BOOL connected) {
                if (connected) {
                    NSLog(@"wwan connected");
                    self.checkNetWorkStat = WWAN;
                    NSDictionary *stat = @{@"status" : self.checkNetWorkStat};
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"networkStatusChanged" object:nil userInfo:stat];
                } else {
                    NSLog(@"wwan offline");
                    self.checkNetWorkStat = OFFLINE;
                    NSDictionary *stat = @{@"status" : self.checkNetWorkStat};
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"networkStatusChanged" object:nil userInfo:stat];
                }
            }];
        
    }
}

-(void) pingLocal {
    account.currentIp = account.localIp;
    [self.coinsorter pingServer:^(BOOL connected) {
        if (connected) {
            self.checkNetWorkStat = WIFILOCAL;
            NSLog(@"connected to the local network");
            NSDictionary *stat = @{@"status" : self.checkNetWorkStat};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"networkStatusChanged" object:nil userInfo:stat];
        } else {
            account.currentIp = account.externalIp;
            [self pingExternal];
        }
    }];
}

-(void) pingExternal {
    [self.coinsorter pingServer:^(BOOL connected) {
        if (connected) {
            NSLog(@"you are connect to external");
            self.checkNetWorkStat = WIFIEXTERNAL;
            NSDictionary *stat = @{@"status" : self.checkNetWorkStat};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"networkStatusChanged" object:nil userInfo:stat];
        } else {
            NSLog(@"you are not connect to any network");
            self.checkNetWorkStat = OFFLINE;
            NSDictionary *stat = @{@"status" : self.checkNetWorkStat};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"networkStatusChanged" object:nil userInfo:stat];
        }
    }];
    
}

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    // get the bssid and compare with prev one
    // if it has changed, then do ping
    NSString *bssid = [self currentWifiBSSID];
    
    // this means we do not hava wifi bssid
    // probably on 3g
    if (bssid == nil) {
        self.prevBSSID = nil;
        return;
    }
    
    if (self.prevBSSID == nil) {
        self.prevBSSID = bssid;
        //[self setupNet];
    }else {
        if (![self.prevBSSID isEqualToString:bssid]) {
            NSLog(@"network bssid changed");
            
            self.prevBSSID = bssid;
            [self setupNet];
        }
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


@end
