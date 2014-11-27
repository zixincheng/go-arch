//
//  StorageDetailViewController.m
//  Go Angel
//
//  Created by zcheng on 2014-11-26.
//  Copyright (c) 2014 acdGO Software Ltd. All rights reserved.
//

#import "StorageDetailViewController.h"

@interface StorageDetailViewController ()

@end

@implementation StorageDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    self.StorageNameLabel.text = self.storages.storageLabel;
    self.StorageUUIDLabel.text = self.storages.uuid;
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)buttonPressed:(id)sender{
    if (sender == self.ejectBtn) {
        [self.coinsorter updateStorage:@"format" stoUUID:self.storages.uuid infoCallback:^(NSDictionary *Data){
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
    }
    else if (sender == self.copyingBtn){
        [self.coinsorter updateStorage:@"copy" stoUUID:self.storages.uuid infoCallback:^(NSDictionary *Data){
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
    }
    else if (sender == self.mountBtn){
        
        [self.coinsorter updateStorage:@"mount" stoUUID:self.storages.uuid infoCallback:^(NSDictionary *Data){
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

    }
}

/*
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#warning Incomplete method implementation.
    switch (section) {
        case 0:
            return 5;
            break;
        case 1:
            return 1;
            break;
        default:
            break;
    }
    // Return the number of rows in the section.
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *sectionName;
    switch (section)
    {
        case 0:
            sectionName = NSLocalizedString(@"Storage Detail Info", @"Storage Detail Info");
            break;
        case 1:
            sectionName = NSLocalizedString(@"Actions", @"Actions");
            break;
            // ...
        default:
            sectionName = @"";
            break;
    }
    return sectionName;
}
*/
/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
