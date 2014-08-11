//
//  PhotoSwipeViewController.m
//  Go Angel
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import "PhotoSwipeViewController.h"

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
  
  // Create page view controller
  self.pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"pageViewController"];
  self.pageViewController.dataSource = self;
  
  SinglePhotoViewController *startingViewController = [self viewControllerAtIndex:self.selected];
  NSArray *viewControllers = @[startingViewController];
  [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
  
  // Change the size of page view controller
  self.pageViewController.view.frame = self.containerView.frame;

  
  [self addChildViewController:_pageViewController];
  [self.containerView addSubview:_pageViewController.view];
  [self.pageViewController didMoveToParentViewController:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

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
  singlePage.selectedPhoto = [self.photos objectAtIndex:index];
  singlePage.mediaLoader = self.mediaLoader;
  
  return singlePage;
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
