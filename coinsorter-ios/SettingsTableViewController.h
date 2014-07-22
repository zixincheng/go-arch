//
//  SettingsTableViewController.h
//  coinsorter-ios
//
//  Created by Jake Runzer on 7/22/14.
//  Copyright (c) 2014 Jake Runzer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Coinsorter.h"

@interface SettingsTableViewController : UITableViewController <UITextFieldDelegate>

@property (nonatomic, strong) NSString *deviceName;
@property Coinsorter *coinsorter;

@property (weak, nonatomic) IBOutlet UITextField *txtDeviceName;

@end
