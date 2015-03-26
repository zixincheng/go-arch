//
//  MainLocationViewController.m
//  Go Arch
//
//  Created by zcheng on 2015-01-22.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "MainLocationViewController.h"
#define IMAGE_TAG       1
#define PRICE_TAG       2
#define BD_TAG          3
#define BA_TAG          4
#define ADDRESS_TAG     5
#define BUILDING_TAG    6
#define LAND_TAG        7

@interface MainLocationViewController ()

@end

@implementation MainLocationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //init search controller
    
    UINavigationController *searchResultsController = [[self storyboard] instantiateViewControllerWithIdentifier:@"TableSearchResultsNavController"];
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:searchResultsController];
    self.searchController.searchResultsUpdater = self;
    
    self.searchController.searchBar.frame = CGRectMake(self.searchController.searchBar.frame.origin.x, self.searchController.searchBar.frame.origin.y, self.searchController.searchBar.frame.size.width, 44.0);
    self.tableView.tableHeaderView = self.searchController.searchBar;
    
    self.definesPresentationContext = YES;
    self.tableView.contentOffset = CGPointMake(0, self.searchController.searchBar.frame.size.height);

    // init vars
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    account = appDelegate.account;
    self.dataWrapper = appDelegate.dataWrapper;
    self.coinsorter = appDelegate.coinsorter;
    self.localDevice = [self.dataWrapper getDevice:account.cid];
    defaults = [NSUserDefaults standardUserDefaults];
    
    //init object
    self.devices = [[NSMutableArray alloc] init];
    self.locations = [self.dataWrapper getLocations];
    
    // add the refresh control to the table view
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
    [refresh addTarget:self action:@selector(PullTorefresh) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refresh;

    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addNewLocation:) name:@"AddLocationSegue"object:nil];

}

-(void) addNewLocation: (NSNotification *)notification{
    
    self.locations = [self.dataWrapper getLocations];
    self.selectedlocation = [notification.userInfo objectForKey:LOCATION];
    loadCamera = 1;
    [self performSegueWithIdentifier:@"individualSegue" sender:self];
    loadCamera = 0;
}


- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AddLocationSegue" object:nil];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES animated:NO];
    self.locations = [self.dataWrapper getLocations];
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) PullTorefresh {
    
    [self.tableView reloadData];
    
    [self.refreshControl endRefreshing];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    // Return the number of rows in the section.
    return self.locations.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"LocationCell"];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LocationCell"];
    UIImageView *imageView  = (UIImageView *)[cell viewWithTag:IMAGE_TAG];
    UILabel *priceLable = (UILabel *)[cell viewWithTag:PRICE_TAG];
    UILabel *bdLbel = (UILabel *)[cell viewWithTag:BD_TAG];
    UILabel *baLbel = (UILabel *)[cell viewWithTag:BA_TAG];
    UILabel *addressLbel = (UILabel *)[cell viewWithTag:ADDRESS_TAG];
    UILabel *buildingLbel = (UILabel *)[cell viewWithTag:BUILDING_TAG];
    UILabel *landLbel = (UILabel *)[cell viewWithTag:LAND_TAG];
    CSLocation *l = self.locations[[indexPath row]];
    CSPhoto *photo;
    self.photos = [self.dataWrapper getPhotosWithLocation:self.localDevice.remoteId location:l];
    UIImage *defaultImage = [UIImage imageNamed:@"box.png"];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    imageView.image = defaultImage;
    if (self.photos.count != 0) {
        photo = [self.dataWrapper getCoverPhoto:self.localDevice.remoteId location:l];
        if (photo == nil) {
            photo = [self.photos objectAtIndex:0];
        }
        AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        [appDelegate.mediaLoader loadThumbnail:photo completionHandler:^(UIImage *image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                imageView.image = image;
            });
        }];
    }
    NSNumberFormatter *format = [[NSNumberFormatter alloc] init];
    [format setNumberStyle:NSNumberFormatterCurrencyStyle];
    [format setMaximumFractionDigits:0];
    [format setRoundingMode:NSNumberFormatterRoundHalfUp];
    NSString *priceString = [format stringFromNumber:l.locationMeta.price];
    [priceLable setText:priceString];
    
    if (l.locationMeta.bed !=nil) {
        [bdLbel setText:[NSString stringWithFormat:@"%@ BD",l.locationMeta.bed]];
    }
    if (l.locationMeta.bed !=nil) {
        [baLbel setText:[NSString stringWithFormat:@"%@ BA",l.locationMeta.bath]];
    }
    [addressLbel setText:[NSString stringWithFormat:@"%@, %@, %@, %@",l.name,l.city,l.province,l.country]];
  
    if (l.locationMeta.buildingSqft !=nil) {
        NSString *buildingString = [l formatArea:l.locationMeta.buildingSqft];
        [buildingLbel setText:[NSString stringWithFormat:@"Fl. %@ sq. ft.",buildingString]];
    }
    
    if (l.locationMeta.buildingSqft !=nil) {
        NSString *landString = [l formatArea:l.locationMeta.landSqft];
        [landLbel setText:[NSString stringWithFormat:@"Lt. %@ sq. ft.",landString]];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  
    self.selectedlocation = self.locations[[indexPath row]];
    [self performSegueWithIdentifier:@"individualSegue" sender:self];
    
    // Deselect
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}
/*
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}
*/
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        NSMutableArray *deletePhoto =  [self.dataWrapper getPhotosWithLocation:self.localDevice.remoteId location:[self.locations objectAtIndex:indexPath.row]];
        NSLog(@"delete count %lu",(unsigned long)deletePhoto.count);
        [self deletePhotoFromFile:deletePhoto];
        [self.dataWrapper deleteLocation:[self.locations objectAtIndex:indexPath.row]];
        [self.locations removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
}

- (void) deletePhotoFromFile: (NSArray *) deletedPhoto {
    NSMutableArray *photoPath = [NSMutableArray array];
    NSLog(@"delete count agign %lu",(unsigned long)deletedPhoto.count);
    for (CSPhoto *p in deletedPhoto) {
        // get documents directory
        
        NSURL *imageUrl = [NSURL URLWithString:p.imageURL];
        NSURL *thumUrl = [NSURL URLWithString:p.thumbURL];
        [photoPath addObject:imageUrl.path];
        [photoPath addObject:thumUrl.path];
    }
    for (NSString *currentpath in photoPath) {
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:currentpath error:&error];
    }
    
    
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void) showSearch: (id) sender {
    [self performSegueWithIdentifier:@"searchSegue" sender:self];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"individualSegue"]) {
      SingleLocationViewController *singleLocContoller = (SingleLocationViewController *)segue.destinationViewController;
      singleLocContoller.dataWrapper = self.dataWrapper;
      singleLocContoller.localDevice = self.localDevice;
      singleLocContoller.location = self.selectedlocation;
      singleLocContoller.coinsorter = self.coinsorter;
      [singleLocContoller setHidesBottomBarWhenPushed:YES];

      NSString *title;
      if (self.selectedlocation.unit !=nil) {
        title = [NSString stringWithFormat:@"%@ - %@",self.selectedlocation.unit, self.selectedlocation.name];
      } else {
        title = [NSString stringWithFormat:@"%@", self.selectedlocation.name];
      }
      singleLocContoller.title = title;
        
    } else if ([segue.identifier isEqualToString:@"searchSegue"]) {
        
        SearchMapViewController *searchVC = (SearchMapViewController *)segue.destinationViewController;
        searchVC.dataWrapper = self.dataWrapper;
        searchVC.localDevice = self.localDevice;
        
    }
}

#pragma mark - UISearchResultsUpdating

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    
    NSString *searchString = [self.searchController.searchBar text];
    
    [self searchForAddress:searchString];
    
    if (self.searchController.searchResultsController) {
        UINavigationController *navController = (UINavigationController *)self.searchController.searchResultsController;
        
        SearchResultsTableViewController *vc = (SearchResultsTableViewController *)navController.topViewController;
        vc.searchResults = self.searchResults;
        vc.localDevice = self.localDevice;
        vc.dataWrapper = self.dataWrapper;
        vc.selectedlocation = self.selectedlocation;
        
        [vc.tableView reloadData];
    }
    
}

#pragma mark - Content Filtering

- (void)searchForAddress:(NSString *)address {
    
    
    if ((address == nil) || [address length] == 0) {
        
        self.searchResults = [self.locations mutableCopy];
        return;
    } else {
        [self.searchResults removeAllObjects]; // First clear the filtered array.
        
        for (CSLocation *locaion in self.locations) {
            NSUInteger searchOptions = NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch;
            NSRange addressRange = NSMakeRange(0, locaion.name.length);
            NSRange unitRange = NSMakeRange(0, locaion.unit.length);
            NSRange foundNameRange = [locaion.name rangeOfString:address options:searchOptions range:addressRange];
            NSRange foundUnitRange = NSRangeFromString(@"");
            if (![locaion.unit isEqualToString:@""]) {
                foundUnitRange= [locaion.unit rangeOfString:address options:searchOptions range:unitRange];
            }
            if ((foundNameRange.length > 0) || (foundUnitRange.length > 0)) {
                [self.searchResults addObject:locaion];
            }
        }
    }
}


@end
