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
    [self.searchController.navigationController setNavigationBarHidden:NO];
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
    //self.locations = [self.dataWrapper getLocations];
    
    // add the refresh control to the table view
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
    [refresh addTarget:self action:@selector(PullTorefresh) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refresh;

    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addNewLocation:) name:@"AddLocationSegue"object:nil];

}

-(void) addNewLocation: (NSNotification *)notification{
    
    self.albums = [self.dataWrapper getAllAlbums];
    self.selectedAlbum = [notification.userInfo objectForKey:LOCATION];
    loadCamera = 1;
    [self performSegueWithIdentifier:@"individualSegue" sender:self];
    loadCamera = 0;
}


- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AddLocationSegue" object:nil];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //[self.navigationController setToolbarHidden:NO animated:NO];
    //self.locations = [self.dataWrapper getLocations];
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
    return self.albums.count;
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
    CSAlbum *a = self.albums[[indexPath row]];
    CSPhoto *photo;
    self.photos = [self.dataWrapper getPhotosWithAlbum:self.localDevice.remoteId album:a];
    UIImage *defaultImage = [UIImage imageNamed:@"box.png"];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    imageView.image = defaultImage;
    if (self.photos.count != 0) {
        photo = [self.dataWrapper getCoverPhoto:self.localDevice.remoteId album:a];
        if (photo == nil) {
            photo = [self.photos objectAtIndex:0];
            //l.album.coverImage = photo.remoteID;
            //[self.dataWrapper updateLocation:l album:l.album];
            //[self.coinsorter updateMeta:photo entity:@"home" value:@"1"];
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
    NSString *priceString = [format stringFromNumber:a.entry.price];
    [priceLable setText:priceString];
    
    if (a.entry.bed !=nil) {
        [bdLbel setText:[NSString stringWithFormat:@"%@ Bedroom",a.entry.bed]];
    }
    if (a.entry.bed !=nil) {
        [baLbel setText:[NSString stringWithFormat:@"%@ Bathroom",a.entry.bath]];
    }
    [addressLbel setText:[NSString stringWithFormat:@"%@, %@, %@, %@",a.entry.location.sublocation,a.entry.location.city,a.entry.location.province,a.entry.location.country]];
  
    if (a.entry.buildingSqft !=nil) {
        NSString *buildingString = [a.entry formatArea:a.entry.buildingSqft];
        [buildingLbel setText:[NSString stringWithFormat:@"Floor Size %@ sq.ft.",buildingString]];
    }
    
    if (a.entry.buildingSqft !=nil) {
        NSString *landString = [a.entry formatArea:a.entry.landSqft];
        [landLbel setText:[NSString stringWithFormat:@"Lot Size %@ sq.ft.",landString]];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  
    self.selectedAlbum = self.albums[[indexPath row]];
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
        NSMutableArray *deletePhoto =  [self.dataWrapper getPhotosWithAlbum:self.localDevice.remoteId album:[self.albums objectAtIndex:indexPath.row]];
        NSLog(@"delete count %lu",(unsigned long)deletePhoto.count);
        [self deletePhotoFromFile:deletePhoto];
        [self.dataWrapper deleteAlbum:[self.albums objectAtIndex:indexPath.row]];
        [self.albums removeObjectAtIndex:indexPath.row];
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
        /*
      SingleLocationViewController *singleLocContoller = (SingleLocationViewController *)segue.destinationViewController;
      singleLocContoller.dataWrapper = self.dataWrapper;
      singleLocContoller.localDevice = self.localDevice;
      singleLocContoller.album = self.selectedAlbum;
      singleLocContoller.coinsorter = self.coinsorter;
      //[singleLocContoller setHidesBottomBarWhenPushed:YES];

      NSString * title = [NSString stringWithFormat:@"%@", self.selectedAlbum.entry.location.sublocation];
      singleLocContoller.title = title;
        */
        SingleViewViewController *singleviewContoller = (SingleViewViewController *)segue.destinationViewController;
        singleviewContoller.dataWrapper = self.dataWrapper;
        singleviewContoller.localDevice = self.localDevice;
        singleviewContoller.album = self.selectedAlbum;
        singleviewContoller.coinsorter = self.coinsorter;
        //[singleLocContoller setHidesBottomBarWhenPushed:YES];
        
        NSString * title = [NSString stringWithFormat:@"%@", self.selectedAlbum.entry.location.sublocation];
        singleviewContoller.title = title;

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
        vc.selectedAlbum = self.selectedAlbum;
        vc.coinsorter = self.coinsorter;
        vc.searchController = self.searchController;
        
        [vc.tableView reloadData];
    }
    
}

#pragma mark - Content Filtering

- (void)searchForAddress:(NSString *)address {
    
    
    if ((address == nil) || [address length] == 0) {
        
        self.searchResults = [self.albums mutableCopy];
        return;
    } else {
        [self.searchResults removeAllObjects]; // First clear the filtered array.
        
        for (CSAlbum *album in self.albums) {
            NSUInteger searchOptions = NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch;
            NSRange addressRange = NSMakeRange(0, album.entry.location.sublocation.length);
            NSRange unitRange = NSMakeRange(0, album.entry.location.unit.length);
            NSRange foundNameRange = [album.entry.location.sublocation rangeOfString:address options:searchOptions range:addressRange];
            NSRange foundUnitRange = NSRangeFromString(@"");
            if (![album.entry.location.unit isEqualToString:@""]) {
                foundUnitRange= [album.entry.location.unit rangeOfString:address options:searchOptions range:unitRange];
            }
            if ((foundNameRange.length > 0) || (foundUnitRange.length > 0)) {
                [self.searchResults addObject:album];
            }
        }
    }
}


@end
