//
//  ConnectViewController.h
//  coinsorter-ios
//
//  Created by Jake Runzer on 7/15/14.
//  Copyright (c) 2014 Jake Runzer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Coinsorter.h"

@interface ConnectViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *passTextField;
@property (weak, nonatomic) IBOutlet UILabel *lblIp;
@property (weak, nonatomic) IBOutlet UILabel *lblError;
@property (nonatomic, strong) NSString *ip;

@property (nonatomic, strong) Coinsorter *coinsorter;

@end
