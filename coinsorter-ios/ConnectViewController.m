//
//  ConnectViewController.m
//  coinsorter-ios
//
//  Created by Jake Runzer on 7/15/14.
//  Copyright (c) 2014 Jake Runzer. All rights reserved.
//

#import "ConnectViewController.h"

@interface ConnectViewController ()

@end

@implementation ConnectViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.passTextField addTarget:self
                       action:@selector(connectPressed:)
             forControlEvents:UIControlEventEditingDidEndOnExit];
    
    self.coinsorter = [[Coinsorter alloc] init];
    
    self.lblIp.text = self.ip;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)connectPressed:(id)sender {
    NSString *pass = self.passTextField.text;
    
    if (![pass isEqualToString:@""]) {
            [self authDevice: pass];
    }else {
        self.lblError.text = @"password is empty";
    }
}

- (void) authDevice: (NSString *) pass {
    [self.coinsorter getToken:self.ip pass:pass callback:^(NSDictionary *authData) {
        if (authData == nil || authData == NULL) {
            // we could not connect to server
            [self asyncSetErrorLabel:@"could not connect to server"];
            NSLog(@"could not connect to server");
            return;
        }
        
        NSString *token = [authData objectForKey:@"token"];
        if (token == nil || token == NULL) {
            // if we get here we assume the password is incorrect
            [self asyncSetErrorLabel:@"password incorrect"];
            NSLog(@"password incorrect");
            return;
        }
        
        NSString *cid = [authData objectForKey: @"_id"];
        
        NSLog(@"token: %@", token);
        NSLog(@"cid: %@", cid);
        
        [self performSegueWithIdentifier:@"deviceSegue" sender:self];
    }];
}

- (void) asyncSetErrorLabel: (NSString *) err {
    dispatch_async(dispatch_get_main_queue(), ^ {
        self.lblError.text = err;
    });
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
