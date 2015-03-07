//
//  ConnectViewController.m
//  Go Arch
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
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
  
  // use iqkeyboardmanager to manager scrolling of text fields
//  [[IQKeyboardManager sharedManager] setEnable:YES];
//  [[IQKeyboardManager sharedManager] setShouldResignOnTouchOutside:YES];
  
  [self.passTextField addTarget:self
                         action:@selector(connectPressed:)
               forControlEvents:UIControlEventEditingDidEndOnExit];
  
  self.passTextField.inputAccessoryView = [[UIView alloc] init];
  
  self.coinsorter = [[Coinsorter alloc] init];
  
  self.lblIp.text = self.ip;
  self.lblError.text = @"";
}

- (void) viewDidAppear:(BOOL)animated {
  
  // make the keyboard come up on when page is navigated to
  [self.passTextField becomeFirstResponder];
}

- (void) viewDidDisappear:(BOOL)animated {
  
  // remove observer
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:[UIDevice currentDevice]];
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

// make api call with password to register device
- (void) authDevice: (NSString *) pass {
  AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
  AccountDataWrapper *account = appDelegate.account;
  
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
      
      dispatch_async(dispatch_get_main_queue(), ^ {
        [self.passTextField setText:@""];
      });
      
      NSLog(@"password incorrect");
      return;
    }
    
    NSString *cid = [authData objectForKey: @"_id"];
    
    NSLog(@"token: %@", token);
    NSLog(@"cid: %@", cid);
    
    account.currentIp = self.ip;
    account.token = token;
    account.cid = cid;
    account.sid = self.sid;
    account.name = self.name;
    
    [account saveSettings];
    
    CSDevice *device = [[CSDevice alloc] init];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    device.deviceName = [defaults valueForKey:@"deviceName"];
    device.remoteId = cid;
    
    CoreDataWrapper *dataWrapper = [[CoreDataWrapper alloc] init];
    [dataWrapper addUpdateDevice:device];
    
    dispatch_async(dispatch_get_main_queue(), ^ {
      [self performSegueWithIdentifier:@"deviceSegue" sender:self];
    });
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
