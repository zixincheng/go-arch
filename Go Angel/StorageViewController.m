//
//  StorageViewController.m
//  Go Angel
//
//  Created by zcheng on 2014-11-20.
//  Copyright (c) 2014 acdGO Software Ltd. All rights reserved.
//

#import "StorageViewController.h"
#import "TSPopoverController.h"
#import "TSActionSheet.h"

@interface StorageViewController ()

@end

@implementation StorageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.contentMode = UIViewContentModeScaleAspectFill;
    self.dataWrapper = [[CoreDataWrapper alloc] init];
    self.coinsorter = [[Coinsorter alloc] initWithWrapper:self.dataWrapper];
    self.storages = [[NSMutableArray alloc] init];
    self.labelArray = [[NSMutableArray alloc] init];
    self.buttonArray = [[NSMutableArray alloc] init];
    // dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    [self getStoragesFromApi];

   //  });
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) getStoragesFromApi {
    // first update this device on server
    NSLog(@"hello");
    // then get all devices
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    [self.coinsorter getStorages: ^(NSMutableArray *storages) {
        for (CSStorage *d in storages) {
            [self.storages addObject:d];
            NSLog(@"%lu",(unsigned long)self.storages.count);
        }
         [self getStorageLabel];
    }];
        });
}

- (void) getStorageLabel {
    NSLog(@"create label");
    NSLog(@"%lu",(unsigned long)self.storages.count);
      dispatch_async(dispatch_get_main_queue(), ^{
          int y =80;
          for (int count=0; count<self.storages.count; count++) {
              UILabel *myLabel =[[UILabel alloc]initWithFrame:CGRectMake(20, y, 200, 40)];
              CSStorage *d = [self.storages objectAtIndex:count];
              [myLabel setText:[NSString stringWithFormat:@" Label: %@ , \n UUID: %@ ",d.storageLabel, d.uuid]];
              NSLog(@"create label %d, postion, %d", count, y);
             
              [myLabel setNumberOfLines:2];
              [myLabel sizeToFit];
              [myLabel setBackgroundColor:[UIColor grayColor]];
              [[self view] addSubview:myLabel];
              [self.labelArray addObject:myLabel];
              
              UIButton *myButton =[UIButton buttonWithType:UIButtonTypeRoundedRect];
              myButton.tag = count;
              [myButton addTarget:self action:@selector(storageAction:forEvent:) forControlEvents:UIControlEventTouchUpInside];
               myButton.frame = CGRectMake(180, y, 20, 40);
              [myButton setTitle:@" Select an Action " forState:UIControlStateNormal];
              [myButton sizeToFit];
              [myButton setBackgroundColor:[UIColor redColor]];
              [self.view addSubview:myButton];
              [self.buttonArray addObject:myButton];
              myButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
              
              y = y+60;
          }
      });
     NSLog(@"%lu Storage sent back",(unsigned long)self.labelArray.count);
    
}

-(void) storageAction:(id)sender forEvent:(UIEvent*)event {
    NSLog(@"action");
    UIButton *clicked = (UIButton *) sender;
    CSStorage *d = [self.storages objectAtIndex:clicked.tag];
    TSActionSheet *actionSheet = [[TSActionSheet alloc] initWithTitle:@"action sheet"];
    [actionSheet destructiveButtonWithTitle:@"Format" block:^{
        NSLog(@"Formatting Storage %ld",(long)clicked.tag);
        [self.coinsorter updateStorage:@"format" stoUUID:d.uuid infoCallback:^(NSDictionary *Data){
            if ([[Data objectForKey:@"stat"] isEqualToString:@"OK"]) {
                dispatch_async(dispatch_get_main_queue(), ^ {
                    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Format Successful!"
                                                                      message:[Data objectForKey:@"message"]
                                                                     delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
                    
                    [message show];
                });

            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^ {
                    UIAlertView *message = [[UIAlertView alloc] initWithTitle:[Data objectForKey:@"stat"]
                                                                      message:[Data objectForKey:@"message"]
                                                                     delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
                    [message show];
                });

            }
        }];
    }];

    [actionSheet destructiveButtonWithTitle:@"Ignore" block:^{
        NSLog(@"Ignoring Storage");
        [self.coinsorter updateStorage:@"ignore" stoUUID:d.uuid infoCallback:^(NSDictionary *Data){
            if ([[Data objectForKey:@"stat"] isEqualToString:@"OK"]) {
                dispatch_async(dispatch_get_main_queue(), ^ {
                    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Ignore Successful!"
                                                                      message:[Data objectForKey:@"message"]
                                                                     delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
                    
                    [message show];
                });
                
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^ {
                    UIAlertView *message = [[UIAlertView alloc] initWithTitle:[Data objectForKey:@"stat"]
                                                                      message:[Data objectForKey:@"message"]
                                                                     delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
                    [message show];
                });
                
            }
            
        }];

    }];
    
    [actionSheet destructiveButtonWithTitle:@"Forget" block:^{
        NSLog(@"Forgeting Storage");
        [self.coinsorter updateStorage:@"forget" stoUUID:d.uuid infoCallback:^(NSDictionary *Data){
            if ([[Data objectForKey:@"stat"] isEqualToString:@"OK"]) {
            dispatch_async(dispatch_get_main_queue(), ^ {
                UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Forget Successful!"
                                                                  message:[Data objectForKey:@"message"]
                                                                 delegate:nil
                                                        cancelButtonTitle:@"OK"
                                                        otherButtonTitles:nil];
                
                [message show];
                });
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^ {
                    UIAlertView *message = [[UIAlertView alloc] initWithTitle:[Data objectForKey:@"stat"]
                                                                      message:[Data objectForKey:@"message"]
                                                                     delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
                    [message show];
                });
                
            }
        }];

    }];
    [actionSheet destructiveButtonWithTitle:@"Unmount" block:^{
        NSLog(@"Unmounting Storage");
        [self.coinsorter updateStorage:@"unmont" stoUUID:d.uuid infoCallback:^(NSDictionary *Data){
            if ([[Data objectForKey:@"stat"] isEqualToString:@"OK"]) {
            dispatch_async(dispatch_get_main_queue(), ^ {
                UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Unmount Successful!"
                                                                  message:[Data objectForKey:@"message"]
                                                                 delegate:nil
                                                        cancelButtonTitle:@"OK"
                                                        otherButtonTitles:nil];
                
                [message show];
                });
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^ {
                    UIAlertView *message = [[UIAlertView alloc] initWithTitle:[Data objectForKey:@"stat"]
                                                                      message:[Data objectForKey:@"message"]
                                                                     delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
                    [message show];
                });
                
            }
            
        }];

    }];
    [actionSheet addButtonWithTitle:@"Add" block:^{
        NSLog(@"Adding Storage");
        [self.coinsorter updateStorage:@"add" stoUUID:d.uuid infoCallback:^(NSDictionary *Data){
            if ([[Data objectForKey:@"stat"] isEqualToString:@"OK"]) {
            dispatch_async(dispatch_get_main_queue(), ^ {
                UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Add Successful!"
                                                                  message:[Data objectForKey:@"message"]
                                                                 delegate:nil
                                                        cancelButtonTitle:@"OK"
                                                        otherButtonTitles:nil];
                
                [message show];
                });
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^ {
                    UIAlertView *message = [[UIAlertView alloc] initWithTitle:[Data objectForKey:@"stat"]
                                                                      message:[Data objectForKey:@"message"]
                                                                     delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
                    [message show];
                });
                
            }
        }];

    }];
    [actionSheet addButtonWithTitle:@"Copy" block:^{
        NSLog(@"Copying Storage");
        [self.coinsorter updateStorage:@"copy" stoUUID:d.uuid infoCallback:^(NSDictionary *Data){
            if ([[Data objectForKey:@"stat"] isEqualToString:@"OK"]) {
            dispatch_async(dispatch_get_main_queue(), ^ {
                UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Copy Successful!"
                                                                  message:[Data objectForKey:@"message"]
                                                                 delegate:nil
                                                        cancelButtonTitle:@"OK"
                                                        otherButtonTitles:nil];
                
                [message show];
                });
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^ {
                    UIAlertView *message = [[UIAlertView alloc] initWithTitle:[Data objectForKey:@"stat"]
                                                                      message:[Data objectForKey:@"message"]
                                                                     delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
                    [message show];
                });
                
            }
        }];

    }];
    [actionSheet addButtonWithTitle:@"Mount" block:^{
        NSLog(@"Mounting Storage");
        [self.coinsorter updateStorage:@"mount" stoUUID:d.uuid infoCallback:^(NSDictionary *Data){
            if ([[Data objectForKey:@"stat"] isEqualToString:@"OK"]) {
            dispatch_async(dispatch_get_main_queue(), ^ {
                UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Mount Successful!"
                                                                  message:[Data objectForKey:@"message"]
                                                                 delegate:nil
                                                        cancelButtonTitle:@"OK"
                                                        otherButtonTitles:nil];
                
                [message show];
                });
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^ {
                    UIAlertView *message = [[UIAlertView alloc] initWithTitle:[Data objectForKey:@"stat"]
                                                                      message:[Data objectForKey:@"message"]
                                                                     delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
                    [message show];
                });
                
            }
        }];

    }];
    [actionSheet cancelButtonWithTitle:@"Cancel" block:nil];
    actionSheet.cornerRadius = 5;
    
    [actionSheet showWithTouch:event];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
