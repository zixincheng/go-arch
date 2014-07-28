//
//  GroupTableViewController.m
//  Coinsorter
//
//  Created by Jake Runzer on 7/25/14.
//  Copyright (c) 2014 ACDSystems. All rights reserved.
//

#import "GroupTableViewController.h"

@interface GroupTableViewController ()

@end

@implementation GroupTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    assetLibrary = [[ALAssetsLibrary alloc] init];
    self.allAlbums = [[NSMutableArray alloc] init];
    
    // load up all the albums
    [self loadAllAlbums];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.allAlbums.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"groupCell" forIndexPath:indexPath];
    
    NSDictionary *d = [self.allAlbums objectAtIndex:[indexPath row]];
    
    // Configure the cell...
    cell.textLabel.text = [d valueForKey:@"name"];
    
    return cell;
}

// load all albums names and urls into array
- (void) loadAllAlbums {
    [self.allAlbums removeAllObjects];
    void (^ assetGroupEnumerator) (ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop) {
        if (group != nil) {
            NSString *groupName = [group valueForProperty:ALAssetsGroupPropertyName];
            NSString *groupUrl = [group valueForProperty:ALAssetsGroupPropertyURL];
            
            NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
            [d setValue:groupName forKey:@"name"];
            [d setValue:groupUrl forKey:@"url"];
            
            [self.allAlbums addObject:d];
            
            NSLog(@"found album - %@ - %@", groupUrl, groupName);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
    };
    
    // Process!
    [assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll
                                     usingBlock:assetGroupEnumerator
                                   failureBlock:^(NSError *error) {
                                       NSLog(@"There is an error");
                                   }];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
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
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

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
