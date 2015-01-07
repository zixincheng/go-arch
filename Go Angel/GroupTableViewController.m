//
//  GroupTableViewController.m
//  Go Angel
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import "GroupTableViewController.h"

@import Photos;

@interface GroupTableViewController ()

@end

@implementation GroupTableViewController

- (id)initWithStyle:(UITableViewStyle)style {
  self = [super initWithStyle:style];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  // Uncomment the following line to preserve selection between presentations.
  // self.clearsSelectionOnViewWillAppear = NO;

  // Uncomment the following line to display an Edit button in the navigation
  // bar for this view controller.
  // self.navigationItem.rightBarButtonItem = self.editButtonItem;

  allPhotosSelected = NO;

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

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  // Return the number of sections.
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  NSInteger numberOfRows = 0;
  if (section == 0) {
    numberOfRows = 1; // "All Photos" section
  } else {
    numberOfRows = self.allAlbums.count;
  }
  return numberOfRows;
}

- (NSString *)tableView:(UITableView *)tableView
    titleForHeaderInSection:(NSInteger)section {
  NSString *title = nil;
  if (section > 0) {
    title = @"Albums";
  }
  return title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell =
      [tableView dequeueReusableCellWithIdentifier:@"groupCell"
                                      forIndexPath:indexPath];

  if (indexPath.section == 0) {
    cell.textLabel.text = @"All Photos";

    if (allPhotosSelected) {
      cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
      cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
  } else {
    NSDictionary *d = [self.allAlbums objectAtIndex:[indexPath row]];

    // Configure the cell...
    cell.textLabel.text = [d valueForKey:NAME];

    NSString *selString = [d valueForKey:SELECTED];
    if ([selString isEqualToString:@"YES"] && !allPhotosSelected)
      cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
      cell.accessoryType = UITableViewCellAccessoryNone;

    if (allPhotosSelected) {
      cell.userInteractionEnabled = !allPhotosSelected;
      cell.textLabel.enabled = !allPhotosSelected;
      cell.detailTextLabel.enabled = !allPhotosSelected;
    }

    return cell;
  }
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  // if all photos was selected
  if (indexPath.section == 0) {
    allPhotosSelected = !allPhotosSelected;

    [self colorOtherAlbums];

    [self.tableView reloadData];

  } else {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    NSDictionary *d = [self.allAlbums objectAtIndex:[indexPath row]];
    NSString *selString = [d valueForKey:SELECTED];
    if ([selString isEqualToString:@"NO"]) {
      [d setValue:@"YES" forKey:SELECTED];
      NSLog(@"selected group %@", [d valueForKey:NAME]);

      // add message into activity history
      NSString *message =
          [NSString stringWithFormat:
                        @"Select album %@, photos in %@ can upload to Arch Box",
                        [d valueForKey:NAME], [d valueForKey:NAME]];
      self.log.activityLog = message;
      self.log.timeUpdate = [NSDate date];
      [self.dataWrapper addUpdateLog:self.log];
    } else {
      [d setValue:@"NO" forKey:SELECTED];
      NSLog(@"de-selected group %@", [d valueForKey:NAME]);

      // add message into activity history
      NSString *message = [NSString
          stringWithFormat:
              @"Remove album %@, new photos in %@ cannot upload to Arch Box",
              [d valueForKey:NAME], [d valueForKey:NAME]];
      self.log.activityLog = message;
      self.log.timeUpdate = [NSDate date];
      [self.dataWrapper addUpdateLog:self.log];
    }

    [self setDefaults];
    [tableView reloadRowsAtIndexPaths:@[ indexPath ]
                     withRowAnimation:UITableViewRowAnimationNone];
  }
}

// grey out and deselect all other albums if All Photos is seleceted
- (void)colorOtherAlbums {
  // loop through all cells in section 1 and disable them
  NSInteger section = 1;
  for (NSInteger i = 0; i < [self.tableView numberOfRowsInSection:section];
       ++i) {
    UITableViewCell *cell = [self.tableView
        cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i
                                                 inSection:section]];
    cell.userInteractionEnabled = !allPhotosSelected;
    cell.textLabel.enabled = !allPhotosSelected;
    cell.detailTextLabel.enabled = !allPhotosSelected;
  }

  if (allPhotosSelected) {
    // deselect all other user albums if all photos checked yes
    for (NSDictionary *d in self.allAlbums) {
      [d setValue:@"NO" forKey:SELECTED];
    }
  } else {
  }

  [self setDefaults];
}

#pragma mark - asset library / defaults

// load up the albums settings from defaults
- (void)loadDefaults {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  // load the all Photos selected property from defaults
  allPhotosSelected = [defaults boolForKey:ALL_PHOTOS];
  if (allPhotosSelected) {
  }

  // load all of the selected albums
  NSMutableArray *arr = [defaults mutableArrayValueForKey:ALBUMS];
  for (NSString *url in arr) {
    [self.selected addObject:url];
    NSLog(@"found selected album %@", url);
  }
}

// set the currently selected albums in defaults
- (void)setDefaults {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  // put state of allPhotosSelected in defaults
  [defaults setBool:allPhotosSelected forKey:ALL_PHOTOS];

  // put url's of all albums selected in defaults
  NSMutableArray *arr = [[NSMutableArray alloc] init];
  for (NSDictionary *d in self.allAlbums) {
    NSString *selString = [d valueForKey:SELECTED];
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
- (void)loadAllAlbums {

  // get all the user created albums (not smart ones) using the photo framework
  PHFetchOptions *userAlbumsOptions = [PHFetchOptions new];
  userAlbumsOptions.predicate =
      [NSPredicate predicateWithFormat:@"estimatedAssetCount > 0"];

  PHFetchResult *userAlbums = [PHAssetCollection
      fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                            subtype:PHAssetCollectionSubtypeAny
                            options:userAlbumsOptions];

  [userAlbums enumerateObjectsUsingBlock:^(PHAssetCollection *collection,
                                           NSUInteger idx, BOOL *stop) {
      NSLog(@"ALBUM: %@ COUNT: %d", collection.localizedTitle, collection.estimatedAssetCount);
    
  }];

  [self.allAlbums removeAllObjects];
  void (^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) =
      ^(ALAssetsGroup *group, BOOL *stop) {
      if (group != nil) {
        NSString *groupName =
            [group valueForProperty:ALAssetsGroupPropertyName];
        NSString *groupUrl = [group valueForProperty:ALAssetsGroupPropertyURL];

        NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
        [d setValue:groupName forKey:NAME];
        [d setValue:groupUrl forKey:URL_KEY];
        if ([self isURLSelected:groupUrl]) {
          [d setValue:@"YES" forKey:SELECTED];
        } else if ([groupName isEqualToString:SAVE_PHOTO_ALBUM]) {
          // TODO: Do we always want to have this album selected?
          //          [d setValue:@"YES" forKey:SELECTED];
        } else {
          [d setValue:@"NO" forKey:SELECTED];
        }

        [self.allAlbums addObject:d];

        NSLog(@"found album - %@ - %@", groupUrl, groupName);

        dispatch_async(dispatch_get_main_queue(),
                       ^{ [self.tableView reloadData]; });
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
- (BOOL)isURLSelected:(NSString *)url {
  for (NSString *u in self.selected) {
    if ([u isEqualToString:[url description]]) {
      return YES;
    }
  }
  return NO;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath
 *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView
 commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
 forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath]
 withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array,
 and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath
 *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath
 *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
 #pragma mark - Navigation

 // In a storyboard-based application, you will often want to do a little
 preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
