//
//  SetPasswordTableViewController.m
//  Go Arch
//
//  Created by zcheng on 2015-02-17.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "SetPasswordTableViewController.h"

@implementation SetPasswordTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    
    self.dataWrapper = [[CoreDataWrapper alloc] init];
    self.coinsorter = [[Coinsorter alloc] initWithWrapper:self.dataWrapper];
    defaults = [NSUserDefaults standardUserDefaults];

    self.oldPass = [defaults objectForKey:@"password"];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
- (void) viewDidAppear:(BOOL)animated {
    
    // make the keyboard come up on when page is navigated to
    [self.oldPassTextField becomeFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.oldPassTextField) {
        [textField resignFirstResponder];
        [self.PassText becomeFirstResponder];
    } else if (textField == self.PassText) {
        [textField resignFirstResponder];
        [self.confirmPass becomeFirstResponder];
    } else {
    [textField resignFirstResponder];
    }
    return YES;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0)
    {
        if([self.oldPass isEqualToString:@""])
            return 0;
        else
            return 1;
    }
    else
    {
        return 2;
    
    }
}

- (IBAction)SaveBtnPressed:(id)sender {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    AccountDataWrapper *account = appDelegate.account;
    if (![self.PassText.text isEqualToString:self.confirmPass.text]) {
        NSLog(@"password is not equal");
        NSLog(@"password you enter is not same as old one");
        [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Failed"
                                                       description:@"Password Does Not Match"
                                                              type:TWMessageBarMessageTypeError
                                                    statusBarStyle:UIStatusBarStyleLightContent
                                                          callback:nil];
    } else if ([self.PassText.text isEqualToString:@""] || [self.confirmPass.text isEqualToString:@""]){
        NSLog(@"password cannot be");
        [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Failed"
                                                       description:@"Password Can Not Be Empty"
                                                              type:TWMessageBarMessageTypeError
                                                    statusBarStyle:UIStatusBarStyleLightContent
                                                          callback:nil];
        
    }else {
        
        [self.coinsorter setPassword:self.oldPassTextField.text newPass:self.PassText.text callback:^(NSDictionary *authData) {
            NSLog(@"data %@",authData);
            if (authData ==nil || authData == NULL) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"ERROR!!!"
                                                                   description:@"could not connect to server"
                                                                          type:TWMessageBarMessageTypeError
                                                                statusBarStyle:UIStatusBarStyleLightContent
                                                                      callback:nil];
                });
                return;
            } else {
                
                if ([[authData objectForKey:@"stat"] isEqualToString:@"success"]) {
                    account.token = [authData objectForKey:@"token"];
                    [account saveSettings];
                    
                    [defaults setObject:self.PassText.text forKey:@"password"];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Success!!!"
                                                                       description:@"New Password Set Success"
                                                                              type:TWMessageBarMessageTypeSuccess
                                                                    statusBarStyle:UIStatusBarStyleLightContent
                                                                          callback:nil];
                    });
                    NSLog(@"set password successfuly ");
                    
                } else {
                    NSLog(@"error %@",[authData objectForKey:@"message"]);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Failed"
                                                                       description:[NSString stringWithFormat:@"%@",[authData objectForKey:@"message"]]
                                                                              type:TWMessageBarMessageTypeError
                                                                    statusBarStyle:UIStatusBarStyleLightContent
                                                                          callback:nil];
                    });
                }
            }
        }];
    }
}
@end
