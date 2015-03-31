//
//  FilterTableViewController.m
//  Go Arch
//
//  Created by zcheng on 2015-03-30.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "FilterTableViewController.h"

@interface FilterTableViewController ()

@end

@implementation FilterTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.bedroomStepper.value = 0;
    self.bedroomStepper.stepInterval = 1;
    self.bedroomStepper.max = 7;
    self.bedroomStepper.valueChnageCallback = ^(FilterStepper *stepper,float number) {
        if (number == 0) {
            stepper.countLabel.text = @"Any";
        } else if (number == 7){
            stepper.countLabel.text = [NSString stringWithFormat:@"Bedrooms 6+"];
        } else {
            stepper.countLabel.text = [NSString stringWithFormat:@"Bedrooms %@",@(number)];
        }
    };
    [self.bedroomStepper setUp];
    
    self.bathroomsStepper.value = 0;
    self.bathroomsStepper.stepInterval = 1;
    self.bathroomsStepper.max = 6;
    self.bathroomsStepper.valueChnageCallback = ^(FilterStepper *stepper,float number) {
        if (number == 0) {
            stepper.countLabel.text = @"Any";
        } else if (number == 6) {
            stepper.countLabel.text = @"Bathrooms 6+";
        } else {
            stepper.countLabel.text = [NSString stringWithFormat:@"Bathrooms %@",@(number)];
        }
    };
    [self.bathroomsStepper setUp];
    
    self.listing.value = 0;
    self.listing.stepInterval = 1;
    self.listing.max = 3;
    self.listing.valueChnageCallback = ^(FilterStepper *stepper,float number) {
        if (number == 0) {
            stepper.countLabel.text = @"Any";
        } else if (number == 1) {
            stepper.countLabel.text = @"For Rent";
        } else if (number == 2) {
            stepper.countLabel.text = @"For Sale";
        } else if (number == 3) {
            stepper.countLabel.text = @"For Rent Or Sale";
        }
    };
    [self.listing setUp];
    
    self.type.value = 0;
    self.type.stepInterval = 1;
    self.type.max = 9;
    self.type.valueChnageCallback = ^(FilterStepper *stepper,float number) {
        if (number == 0) {
            stepper.countLabel.text = @"Any";
        } else if (number == 1) {
            stepper.countLabel.text = @"Condominium";
        } else if (number == 2) {
            stepper.countLabel.text = @"Commercial";
        } else if (number == 3) {
            stepper.countLabel.text = @"Farm";
        } else if (number == 4) {
            stepper.countLabel.text = @"House";
        } else if (number == 5) {
            stepper.countLabel.text = @"Land";
        } else if (number == 6) {
            stepper.countLabel.text = @"Parking";
        } else if (number == 7) {
            stepper.countLabel.text = @"Residential";
        } else if (number == 8) {
            stepper.countLabel.text = @"Recretional";
        } else if (number == 8) {
            stepper.countLabel.text = @"TownHouses";
        }
    };
    [self.type setUp];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 8;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return 1;
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"filterCell" forIndexPath:indexPath];
 
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
