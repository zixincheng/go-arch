//
//  GroupTableViewController.m
//  Go Angel
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
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
  self.selected = [[NSMutableArray alloc] init];
  self.dataWrapper = [[CoreDataWrapper alloc] init];
  self.log = [[ActivityHistory alloc] init];

  // load the selected albums from nsuserdefaults
  [self loadDefaults];
  
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
  cell.textLabel.text = [d valueForKey:NAME];
  
  NSString *selString = [d valueForKey:SELECTED];
  if ([selString isEqualToString:@"YES"]) cell.accessoryType = UITableViewCellAccessoryCheckmark;
  else cell.accessoryType = UITableViewCellAccessoryNone;
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
  
  NSDictionary *d = [self.allAlbums objectAtIndex:[indexPath row]];
  NSString *selString = [d valueForKey:SELECTED];
  if ([selString isEqualToString:@"NO"]) {
    [d setValue:@"YES" forKey:SELECTED];
    NSLog(@"selected group %@", [d valueForKey:NAME]);
      
    //add message into activity history
    NSString *message = [NSString stringWithFormat: @"Select album %@, photos in %@ can upload to Arch Box", [d valueForKey:NAME], [d valueForKey:NAME]];
    self.log.activityLog = message;
    self.log.timeUpdate = [NSDate date];
    [self.dataWrapper addUpdateLog:self.log];
  }else {
    [d setValue:@"NO" forKey:SELECTED];
    NSLog(@"de-selected group %@", [d valueForKey:NAME]);
      
    //add message into activity history
    NSString *message = [NSString stringWithFormat: @"Remove album %@, new photos in %@ cannot upload to Arch Box", [d valueForKey:NAME], [d valueForKey:NAME]];
    self.log.activityLog = message;
    self.log.timeUpdate = [NSDate date];
    [self.dataWrapper addUpdateLog:self.log];
  }
  
  [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
  
  [self setDefaults];
}

#pragma mark - asset library / defaults

// load up the albums settings from defaults
- (void) loadDefaults {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  
  NSMutableArray *arr = [defaults mutableArrayValueForKey:ALBUMS];
  for (NSString *url in arr) {
    [self.selected addObject:url];
    NSLog(@"found selected album %@", url);
  }
}

// set the currently selected albums in defaults
- (void) setDefaults {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  
  NSMutableArray *arr = [[NSMutableArray alloc] init];
  
  for (NSDictionary *d in self.allAlbums) {
    NSString *selString = [d valueForKey: SELECTED];
    if ([selString isEqualToString:@"YES"]) {
      NSString *url = [d valueForKey:URL_KEY];
      [arr addObject:[url description]];
    }
  }
  
  NSLog(@"setting value for %@ to %@", ALBUMS, arr);
  [defaults setValue:arr forKey:ALBUMS];
  [defaults synchronize];
}

// load all albums names and urls into array
- (void) loadAllAlbums {
  [self.allAlbums removeAllObjects];
  void (^ assetGroupEnumerator) (ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop) {
    if (group != nil) {
      NSString *groupName = [group valueForProperty:ALAssetsGroupPropertyName];
      NSString *groupUrl = [group valueForProperty:ALAssetsGroupPropertyURL];
      
      NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
      [d setValue:groupName forKey:NAME];
      [d setValue:groupUrl forKey:URL_KEY];
      if ([self isURLSelected:groupUrl]) {
        [d setValue:@"YES" forKey:SELECTED];
      }else if([groupName isEqualToString:SAVE_PHOTO_ALBUM]){
        [d setValue:@"YES" forKey:SELECTED];
      }else {
        [d setValue:@"NO" forKey:SELECTED];
      }
      
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

// checks to see if the given url is selected
// returns YES if selected
- (BOOL) isURLSelected: (NSString *) url {
  for (NSString *u in self.selected) {
    if ([u isEqualToString:[url description]]) {
      return YES;
    }
  }
  return NO;
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
