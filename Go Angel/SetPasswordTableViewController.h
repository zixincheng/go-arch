//
//  SetPasswordTableViewController.h
//  Go Arch
//
//  Created by zcheng on 2015-02-17.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Coinsorter.h"
#import "CoreDataWrapper.h"
#import "TWMessageBarManager.h"

@interface SetPasswordTableViewController : UITableViewController  <UITableViewDelegate, UITableViewDataSource,UITextFieldDelegate> {
    NSUserDefaults *defaults;
}

@property (nonatomic, strong) Coinsorter *coinsorter;
@property (nonatomic, strong) CoreDataWrapper *dataWrapper;
@property (weak, nonatomic) IBOutlet UITextField *oldPassTextField;
@property (weak, nonatomic) IBOutlet UITextField *PassText;
@property (weak, nonatomic) IBOutlet UITextField *confirmPass;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveBtn;

@property (nonatomic, strong) NSString *oldPass;
@property (nonatomic, strong) NSString *newestPass;
@property (nonatomic, strong) NSString *doubleCheckPass;

@end
