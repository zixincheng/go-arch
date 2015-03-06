//
//  StorageDetailViewController.m
//  Go Arch
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
    
    //init buttons
    self.BackupSwitch= [[UISwitch alloc] initWithFrame:CGRectMake(228, 9, 0, 0)];
    [self.BackupSwitch addTarget:self action:@selector(changeBackupSwitch:) forControlEvents:UIControlEventValueChanged];
    
    self.primarySwitch = [[UISwitch alloc] initWithFrame:CGRectMake(228, 9, 0, 0)];
    [self.primarySwitch addTarget:self action:@selector(changePrimarySwitch:) forControlEvents:UIControlEventValueChanged];
    
    self.pickerViewContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 600, 320, 300)];
    self.pickerViewContainer.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:self.pickerViewContainer];
    
    self.pickToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
    [self.pickerViewContainer addSubview: self.pickToolbar];
    self.pickToolbar.backgroundColor = [UIColor blackColor];
    
    self.pickerViewButton = [[UIBarButtonItem alloc]
                                   initWithTitle:@"Done"
                                   style:UIBarButtonItemStyleDone
                                   target:self
                                   action:@selector(doneSelect:)];
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [self.pickToolbar setItems:@[flexibleItem,self.pickerViewButton] animated:NO];
    
    self.dataArray = [[NSMutableArray alloc] init];
    
    // Add some data for demo purposes.
    [self.dataArray addObject:@"Every Hour"];
    [self.dataArray addObject:@"Every Day"];
    [self.dataArray addObject:@"Every Week"];
    [self.dataArray addObject:@"Every Month"];
    
    self.pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 40, 320, 300)];
    [self.pickerView setDataSource: self];
    [self.pickerView setDelegate: self];
     [self.pickerViewContainer addSubview: self.pickerView];
    [self.pickerView selectRow:0 inComponent:0 animated:YES];
   self.pickerView.showsSelectionIndicator = YES;
    
    if ([self.storages.primary boolValue]){
           self.secondSectionRowCount = 3;
        self.BackupSwitch.on=NO;
        self.primarySwitch.on=YES;
    } else if ([self.storages.backup boolValue]){
           self.secondSectionRowCount = 4;
        self.BackupSwitch.on=YES;
        self.primarySwitch.on=NO;
    } else {
        self.secondSectionRowCount = 3;
    }
        
    self.currentSchedule = @"Every Hour";
    [self determineCronTime];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

//setup cron time to match specific string
-(void) determineCronTime {
    if ([self.currentSchedule isEqualToString: @"Every Hour"]) {
        self.cronTime = @"*/5 * * * * *";
    } else if ([self.currentSchedule isEqualToString: @"Every Day"]) {
        self.cronTime = @"0 0 * * *";
    } else if ([self.currentSchedule isEqualToString: @"Every Week"]) {
        self.cronTime = @"0 0 * * 0";
    } else if ([self.currentSchedule isEqualToString: @"Every Month"]) {
        self.cronTime = @"0 0 1 * *";
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// picker view done button action, update the cron time
-(void) doneSelect: (UIBarButtonItem *)button {
    [self.tableView reloadData];
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    self.pickerViewContainer.frame = CGRectMake(0, 600, 320, 300);
    [UIView commitAnimations];

    [self.coinsorter updateStorage:@"setBackup" stoUUID:self.storages.uuid crontime:self.cronTime infoCallback:^(NSDictionary *Data){

        if ([[Data objectForKey:@"stat"] isEqualToString:@"OK"]) {
            self.storages.backup = @"1";
            self.storages.mounted = @"1";
            self.storages.primary = @"0";
            dispatch_async(dispatch_get_main_queue(), ^ {
                self.primarySwitch.on = NO;
                self.BackupSwitch.on = YES;
                NSNumber *number =[NSNumber numberWithFloat: 1 - [self.storages.freeSpace floatValue] / [self.storages.totalSpace floatValue]];
                NSString *numberStr = [NSNumberFormatter localizedStringFromNumber:number numberStyle:NSNumberFormatterPercentStyle];
                self.StorageUsageLabel.text = numberStr;
                self.StorageMountLabel.text = @"Yes";
                self.secondSectionRowCount = 4;
                [self.tableView reloadData];
                UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Update Successful!"
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
//display the picker view
-(void) showAction: (UIButton *)button {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    self.pickerViewContainer.frame = CGRectMake(0, 280, 320, 300);
    [UIView commitAnimations];
    
}

// eject button to unmount the external device
-(void) ejectStorage:(UIButton*)button {
    [self.coinsorter updateStorage:@"unmount" stoUUID:self.storages.uuid infoCallback:^(NSDictionary *Data){
        if ([[Data objectForKey:@"stat"] isEqualToString:@"OK"]) {
            self.storages.mounted = 0;
            self.storages.freeSpace = nil;
            self.storages.totalSpace = nil;
            dispatch_async(dispatch_get_main_queue(), ^ {
                self.StorageMountLabel.text = @"NO";
                NSNumber *number =[NSNumber numberWithFloat: 1 - [self.storages.freeSpace floatValue] / [self.storages.totalSpace floatValue]];
                NSString *numberStr = [NSNumberFormatter localizedStringFromNumber:number numberStyle:NSNumberFormatterPercentStyle];
                self.StorageUsageLabel.text = numberStr;
                UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Eject Successful!"
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

-(void)alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex {
    // set to primary alert view
    if (alertView.tag ==1) {
        if (buttonIndex == 0) {
            self.primarySwitch.on = NO;
        } else if (buttonIndex == 1) {
        [self.coinsorter updateStorage:@"setPrimary" stoUUID:self.storages.uuid infoCallback:^(NSDictionary *Data){
            if ([[Data objectForKey:@"stat"] isEqualToString:@"OK"]) {
                self.storages.primary = @"1";
                self.storages.mounted = @"1";
                self.storages.backup = @"0";
                dispatch_async(dispatch_get_main_queue(), ^ {
                    self.primarySwitch.on = YES;
                    self.BackupSwitch.on = NO;
                    NSNumber *number =[NSNumber numberWithFloat: 1 - [self.storages.freeSpace floatValue] / [self.storages.totalSpace floatValue]];
                    NSString *numberStr = [NSNumberFormatter localizedStringFromNumber:number numberStyle:NSNumberFormatterPercentStyle];
                    self.StorageUsageLabel.text = numberStr;
                    self.StorageMountLabel.text = @"Yes";
                    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Set Primary Successful!"
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
    // set to backup alert view
    else if (alertView.tag == 2) {
            if (buttonIndex == 0) {
                self.BackupSwitch.on = NO;
            } else if (buttonIndex == 1) {
                [self.coinsorter updateStorage:@"setBackup" stoUUID:self.storages.uuid crontime:self.cronTime infoCallback:^(NSDictionary *Data){
                if ([[Data objectForKey:@"stat"] isEqualToString:@"OK"]) {
                    self.storages.backup = @"1";
                    self.storages.mounted = @"1";
                    self.storages.primary = @"0";
                    dispatch_async(dispatch_get_main_queue(), ^ {
                        self.primarySwitch.on = NO;
                        self.BackupSwitch.on = YES;
                        NSNumber *number =[NSNumber numberWithFloat: 1 - [self.storages.freeSpace floatValue] / [self.storages.totalSpace floatValue]];
                        NSString *numberStr = [NSNumberFormatter localizedStringFromNumber:number numberStyle:NSNumberFormatterPercentStyle];
                        self.StorageUsageLabel.text = numberStr;
                        self.StorageMountLabel.text = @"Yes";
                        self.secondSectionRowCount = 4;
                        [self.tableView reloadData];
                        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"setBackup Successful!"
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
}

//switches that enable or disable primary storage
- (void)changePrimarySwitch:(UISwitch *)primarySwitch{
    
    if(primarySwitch.on){
        NSLog(@"Priamary Switch is ON");
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Set Primary Storage"
                                                          message:@"Are you sure you want format the storage and set a as primary?"
                                                         delegate:self
                                                cancelButtonTitle:@"Cancel"
                                                otherButtonTitles:@"OK", nil];
        message.tag = 1;
        
        [message show];

    } else{
        NSLog(@"Priamary Switch is OFF %@",self.storages.primary);
        [self.coinsorter updateStorage:@"disablePrimary" stoUUID:self.storages.uuid infoCallback:^(NSDictionary *Data){
            if ([[Data objectForKey:@"stat"] isEqualToString:@"OK"]) {
                self.storages.primary = @"0";
                self.storages.mounted = @"1";
                dispatch_async(dispatch_get_main_queue(), ^ {
                    self.StorageMountLabel.text = @"YES";
                    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Disable Successful!"
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
//switches that enable or disable backup storage
- (void)changeBackupSwitch:(UISwitch *)backupSwitch{
    
    if(backupSwitch.on){
        NSLog(@"Backup Switch is ON");
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Set Backup Storage"
                                                          message:@"Are you sure you want set this storage as backup"
                                                         delegate:self
                                                cancelButtonTitle:@"Cancel"
                                                otherButtonTitles:@"OK", nil];
        message.tag = 2;
        
        [message show];
    } else{
        self.secondSectionRowCount = 3;
        [self.tableView reloadData];
        NSLog(@"Backup Switch is OFF");;
        [self.coinsorter updateStorage:@"disableBackup" stoUUID:self.storages.uuid infoCallback:^(NSDictionary *Data){
            if ([[Data objectForKey:@"stat"] isEqualToString:@"OK"]) {
                self.storages.backup = @"0";
                self.storages.mounted = @"1";
                dispatch_async(dispatch_get_main_queue(), ^ {
                    self.StorageMountLabel.text = @"YES";
                    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Disable Successful!"
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


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 4;
            break;
        case 1:
            return self.secondSectionRowCount;
            break;
        default:
            return 0;
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


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
   // NSString *identifier = [NSString stringWithFormat:@"cell%ld",indexPath.row+1];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
       switch (indexPath.section) {
           case 0:
         {
             for (UIView *subviews in cell.contentView.subviews){
                 [subviews removeFromSuperview];
             }
             switch (indexPath.row) {
                 case 0:
                 {
                     UILabel *NameDisplay = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, 120, 30.0)];
                     NameDisplay.text = @"Stroage Label:";
                     [cell.contentView addSubview:NameDisplay];
            
                     UILabel *StorageNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(228, 9, 85, 30.0)];
                     StorageNameLabel.text = self.storages.storageLabel;
                     StorageNameLabel.adjustsFontSizeToFitWidth = YES;
                     [cell.contentView addSubview:StorageNameLabel];
                 }
                 break;
                 case 1:
                 {
                     UILabel *UUIDDisplay = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, 120, 30.0)];
                     UUIDDisplay.text = @"Stroage UUID:";
                     [cell.contentView addSubview:UUIDDisplay];
            
                     UILabel *StorageUUIDLabel = [[UILabel alloc] initWithFrame:CGRectMake(228, 9, 85, 30.0)];
                     StorageUUIDLabel.text = self.storages.uuid;
                     StorageUUIDLabel.adjustsFontSizeToFitWidth = YES;
                     [cell.contentView addSubview:StorageUUIDLabel];
                 }
                 break;
                 case 2:
                 {
                     
                     UILabel *MountDisplay = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, 120, 30.0)];
                     MountDisplay.text = @"Mount Point";
                     [cell.contentView addSubview:MountDisplay];
                     
                     self.StorageMountLabel = [[UILabel alloc] initWithFrame:CGRectMake(228, 9, 85, 30.0)];
                     self.StorageMountLabel.text = [NSString stringWithFormat:@"%@",([self.storages.mounted boolValue] ? @"YES": @"NO")];
                     [cell.contentView addSubview:self.StorageMountLabel];
                 }
                 break;
                 case 3:
                    {
                        UILabel *UsageDisplay = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, 120, 30.0)];
                        UsageDisplay.text = @"Stroage Usage:";
            
                        [cell.contentView addSubview:UsageDisplay];
                        
                        NSNumber *number =[NSNumber numberWithFloat: 1 - [self.storages.freeSpace floatValue] / [self.storages.totalSpace floatValue]];
                        NSString *numberStr = [NSNumberFormatter localizedStringFromNumber:number numberStyle:NSNumberFormatterPercentStyle];
                        self.StorageUsageLabel = [[UILabel alloc] initWithFrame:CGRectMake(228, 9, 85, 30.0)];
                        self.StorageUsageLabel.text = numberStr;
                        [cell.contentView addSubview:self.StorageUsageLabel];

                    }
                 break;
                 default:
                 break;
             }

        }
        break;
               case 1:
           {
               for (UIView *subviews in cell.contentView.subviews){
               [subviews removeFromSuperview];
                }
                switch (indexPath.row) {
                    case 0:
                    {
                   UILabel *SetPrimaryDisplay = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, 120, 30.0)];
                   SetPrimaryDisplay.text = @"Set Primary";
                   [cell.contentView addSubview:SetPrimaryDisplay];
                   
                   [cell.contentView addSubview:self.primarySwitch];
                    }
                    break;
                    case 1:
                    {
                        UILabel *SetBackupDisplay = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, 120, 30.0)];
                        SetBackupDisplay.text = @"Set Backup";
                        [cell.contentView addSubview:SetBackupDisplay];
                        
                        [cell.contentView addSubview:self.BackupSwitch];
                        
                    }
                    break;
                    case 2:
                    {
                        if (self.BackupSwitch.on) {

                        UILabel *CronDisplay = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, 120, 30.0)];
                        CronDisplay.text = @"Cron Schedule";
                        [cell.contentView addSubview:CronDisplay];

                        self.CronSchedule = [UIButton buttonWithType:UIButtonTypeRoundedRect];
                        [self.CronSchedule addTarget:self
                                          action:@selector(showAction:)
                                forControlEvents:UIControlEventTouchUpInside];
                        self.CronSchedule.frame= CGRectMake(228, 9, 85, 30.0);
                        [self.CronSchedule setTitle: self.currentSchedule forState:UIControlStateNormal];
                        [cell.contentView addSubview:self.CronSchedule];
                        NSLog(@"%@",self.currentSchedule);
                        } else {
                            UILabel *EjectDisplay = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, 120, 30.0)];
                            EjectDisplay.text = @"Eject Storage";
                            [cell.contentView addSubview:EjectDisplay];
                            
                            self.ejectBtn= [UIButton buttonWithType:UIButtonTypeRoundedRect];
                            [self.ejectBtn addTarget:self
                                              action:@selector(ejectStorage:)
                                    forControlEvents:UIControlEventTouchUpInside];
                            [self.ejectBtn setTitle:@"Eject" forState:UIControlStateNormal];
                            self.ejectBtn.frame = CGRectMake(228, 9, 85, 30.0);
                            [cell.contentView addSubview:self.ejectBtn];
                        }
                    }
                    break;
                    case 3:
                    {
                        UILabel *EjectDisplay = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, 120, 30.0)];
                        EjectDisplay.text = @"Eject Storage";
                        [cell.contentView addSubview:EjectDisplay];
                        
                        self.ejectBtn= [UIButton buttonWithType:UIButtonTypeRoundedRect];
                        [self.ejectBtn addTarget:self
                                          action:@selector(ejectStorage:)
                                forControlEvents:UIControlEventTouchUpInside];
                        [self.ejectBtn setTitle:@"Eject" forState:UIControlStateNormal];
                        self.ejectBtn.frame = CGRectMake(228, 9, 85, 30.0);
                        [cell.contentView addSubview:self.ejectBtn];
                    }
                        break;

               
                    }
           }
           default:
            break;
       }
    
    return cell;
    // Configure the cell...
}
# pragma picker view datasource and delegate
// Number of components.
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

// Total rows in our component.
-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return [self.dataArray count];
}

// Display each row's data.
-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    return [self.dataArray objectAtIndex: row];
}

/*
-(UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, pickerView.frame.size.width, 44)];
    label.backgroundColor = [UIColor lightGrayColor];
    label.textColor = [UIColor blackColor];
    label.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18];
    label.text = [self.dataArray objectAtIndex: row];
    return label;
}
 */
// Do something with the selected row.
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    NSLog(@"You selected this: %@", [self.dataArray objectAtIndex: row]);
    self.currentSchedule =[self.dataArray objectAtIndex: row];
      [self determineCronTime];
      NSLog(@"You selected this: %@",self.cronTime);
}
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
