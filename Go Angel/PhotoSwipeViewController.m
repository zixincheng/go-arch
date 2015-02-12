//
//  PhotoSwipeViewController.m
//  Go Angel
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import "PhotoSwipeViewController.h"

#define IMAGE_VIEW_TAG 11
#define OVERLAY_TAG    12
#define GRID_CELL      @"gridCell"

@interface PhotoSwipeViewController ()

@end

@implementation PhotoSwipeViewController

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
  
  bottom_selected = self.selected;
    
  // Create page view controller
  self.pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"pageViewController"];
  self.pageViewController.dataSource = self;
  
  SinglePhotoViewController *startingViewController = [self viewControllerAtIndex:self.selected];
  startingViewController.dataWrapper = self.dataWrapper;
  startingViewController.coinsorter = self.coinsorter;
  NSArray *viewControllers = @[startingViewController];
  [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
  
  // Change the size of page view controller
  self.pageViewController.view.frame = self.containerView.frame;

  [self addChildViewController:_pageViewController];
  [self.containerView addSubview:_pageViewController.view];
  [self.pageViewController didMoveToParentViewController:self];
    
  [self.navigationController setToolbarHidden:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma mark - PageViewController Methods

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
  NSUInteger index = ((SinglePhotoViewController*) viewController).selected;
  
  if ((index == 0) || (index == NSNotFound)) {
    return nil;
  }
  
  index--;
  return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
  NSUInteger index = ((SinglePhotoViewController*) viewController).selected;
  
  if (index == NSNotFound) {
    return nil;
  }
  
  index++;
  if (index == [self.photos count]) {
    return nil;
  }
  return [self viewControllerAtIndex:index];
}

- (SinglePhotoViewController *)viewControllerAtIndex:(NSUInteger)index
{
  if (([self.photos count] == 0) || (index >= [self.photos count])) {
    return nil;
  }
  
  // Create a new view controller and pass suitable data
  SinglePhotoViewController *singlePage = [self.storyboard instantiateViewControllerWithIdentifier:@"singlePhotoView"];
  singlePage.selected = index;
  singlePage.photos = self.photos;
  singlePage.navBar = self.navigationItem;
  singlePage.selectedPhoto = [self.photos objectAtIndex:index];
  
  return singlePage;
}

# pragma mark - CollectionViewController Methods

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView {
  return 1;
}

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
  return self.photos.count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  GridCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:GRID_CELL forIndexPath:indexPath];
  UIImageView *imageView = (UIImageView *) [cell viewWithTag:IMAGE_VIEW_TAG];
  
  CSPhoto *photo = [self.photos objectAtIndex:[indexPath row]];
  
  AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
  [appDelegate.mediaLoader loadThumbnail:photo completionHandler:^(UIImage *image) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [imageView setImage:image];
      
//      if ([indexPath row] == bottom_selected) {
//        UIView *overlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, imageView.frame.size.width, imageView.frame.size.height)];
//        [overlay setTag:OVERLAY_TAG];
//        [overlay setBackgroundColor:[UIColor colorWithRed:255/255.0f green:233/255.0f blue:0/255.0f alpha:0.6f]];
//        [imageView addSubview:overlay];
//      }
    });
  }];
  
  return cell;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  // TODO: Make this work
  
//  NSIndexPath *lastSelected = [NSIndexPath indexPathForRow:bottom_selected inSection:1];
//  bottom_selected = [indexPath row];
//  
//  NSLog(@"trying to reload %d", [lastSelected row]);
//  
//  [collectionView reloadData];
  
  bottom_selected = self.selected = [indexPath row];
  self.selectedPhoto = [self.photos objectAtIndex:self.selected];
  
  SinglePhotoViewController *startingViewController = [self viewControllerAtIndex:self.selected];
  NSArray *viewControllers = @[startingViewController];
  [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
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
