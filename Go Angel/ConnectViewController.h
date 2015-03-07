//
//  ConnectViewController.h
//  Go Arch
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import <UIKit/UIKit.h>
#import "Coinsorter.h"
#import "AppDelegate.h"
#import "CoreDataWrapper.h"


// controller where the user enters the password for the box
// they are trying to connect to

@interface ConnectViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *passTextField;
@property (weak, nonatomic) IBOutlet UILabel *lblIp;
@property (weak, nonatomic) IBOutlet UILabel *lblError;
@property (nonatomic, strong) NSString *ip;
@property (nonatomic, strong) NSString *sid;
@property (nonatomic, strong) NSString *name;

@property (nonatomic, strong) Coinsorter *coinsorter;

@end
