//
//  firstLoadViewController.m
//  Go Arch
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import "firstLoadViewController.h"
#import "AppDelegate.h"
#import "AccountDataWrapper.h"

@interface firstLoadViewController ()

@end

@implementation firstLoadViewController

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
}

- (void)viewDidAppear:(BOOL)animated {
  AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
  AccountDataWrapper *account = appDelegate.account;
  
  if (account.currentIp != nil) {
    [self performSegueWithIdentifier:@"connectedSegue" sender:self];
  }else {
    [self performSegueWithIdentifier:@"handshakeSeque" sender:self];
  }
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
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
