//
//  GridViewController.m
//  Go Angel
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import "GridViewController.h"

// identifiers
#define GRID_CELL @"squareImageCell"
#define PHOTO_HEADER @"photoSectionHeader"
#define SINGLE_PHOTO_SEGUE @"singleImageSegue"

// tags in cell
#define GRID_IMAGE 11

@interface GridViewController ()

@end

@implementation GridViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
  
  [self.navigationBar setTitle:self.device.deviceName];
  
  self.photos = [self.dataWrapper getPhotos:self.device.remoteId];
}

- (void) viewDidAppear:(BOOL)animated {
  // get photo async
//  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
//    self.photos = [self.dataWrapper getPhotos:self.device.remoteId];
//
//    
//    dispatch_async(dispatch_get_main_queue(), ^{
//      [self.collectionView reloadData];
//    });
//  });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma mark - Grid View Delegates/Data Source

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
  UICollectionReusableView *reusableview = nil;
  
  if (kind == UICollectionElementKindSectionHeader) {
    PhotoSectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:PHOTO_HEADER forIndexPath:indexPath];
    
    if (self.photos != nil) {
      NSString *title = [NSString stringWithFormat:@"%d Photos", self.photos.count];
      headerView.lblHeader.text = title;
    }
    reusableview = headerView;
  }
  
  return reusableview;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView {
  return 1;
}

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
  return self.photos.count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  GridCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:GRID_CELL forIndexPath:indexPath];
  UIImageView *imageView = (UIImageView *) [cell viewWithTag:GRID_IMAGE];
  
  CSPhoto *photo = [self.photos objectAtIndex:[indexPath row]];
  
  AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
  [appDelegate.mediaLoader loadThumbnail:photo completionHandler:^(UIImage *image) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [imageView setImage:image];
    });
  }];
  
  return cell;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  selected = [indexPath row];
  [self performSegueWithIdentifier:SINGLE_PHOTO_SEGUE sender:self];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if([segue.identifier isEqualToString:SINGLE_PHOTO_SEGUE]) {
    PhotoSwipeViewController *swipeController = (PhotoSwipeViewController *) segue.destinationViewController;
    swipeController.selected = selected;
    swipeController.photos = self.photos;
//    SinglePhotoViewController *singleController = (SinglePhotoViewController *)segue.destinationViewController;
//    singleController.selected = selected;
//    singleController.mediaLoader = self.mediaLoader;
//    singleController.photos = self.photos;
  }
}

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
