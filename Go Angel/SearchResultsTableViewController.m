//
//  SearchResultsTableViewController.m
//  Pods
//
//  Created by zcheng on 2015-01-30.
//
//

#import "SearchResultsTableViewController.h"

@interface SearchResultsTableViewController ()

@end

@implementation SearchResultsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
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

    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    // Return the number of rows in the section.
    return [self.searchResults count]+1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"SearchResultCell" forIndexPath:indexPath];
    
    if (indexPath.row == [self.searchResults count]) {
        cell.textLabel.text = @"Add Location ...";
    } else {
    
    CSLocation *location = [self.searchResults objectAtIndex:indexPath.row];
    
        if (![location.unit isEqualToString:@""]) {
            cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@",location.unit, location.name];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@",location.city,location.province];
        } else {
            cell.textLabel.text = location.name;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@",location.city,location.province];
            // Configure the cell...
        }

    }
    return cell;
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == [self.searchResults count]) {
        AddingLocationViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"LocationTagging"];
        [self.presentingViewController.navigationController pushViewController:vc animated:YES];

    } else {
        self.selectedlocation = [self.searchResults objectAtIndex:indexPath.row];
        IndividualEntryViewController *individualViewControll = [[self storyboard] instantiateViewControllerWithIdentifier:@"IndividualViewController"];
        individualViewControll.dataWrapper = self.dataWrapper;
        individualViewControll.localDevice = self.localDevice;
        individualViewControll.location = self.selectedlocation;
        [self.presentingViewController.navigationController pushViewController:individualViewControll animated:YES];

    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"individualSegue"]) {
        
        IndividualEntryViewController *individualViewControll = (IndividualEntryViewController *)segue.destinationViewController;
        
        individualViewControll.dataWrapper = self.dataWrapper;
        individualViewControll.localDevice = self.localDevice;
        individualViewControll.location = self.selectedlocation;
        
        
    }
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
