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
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stratUploading) name:@"startUploading" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eachPhotoUploaded) name:@"onePhotoUploaded" object:nil];
    
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

- (void)stratUploading{
    self.currentUploading = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        self.photos = [self.dataWrapper getPhotos:self.device.remoteId];
        dispatch_async(dispatch_get_main_queue(), ^ {
            [self.collectionView reloadData];
        });
    });
}
- (void)eachPhotoUploaded{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        self.photos = [self.dataWrapper getPhotos:self.device.remoteId];
        dispatch_async(dispatch_get_main_queue(), ^ {
            [self.collectionView reloadData];
        });
    });
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
        __block UIImage *newimage = [self markedImageStatus:image checkImageStatus:photo.onServer uploadingImage:self.currentUploading];
        [imageView setImage:newimage];
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

- (UIImage *)markedImageStatus:(UIImage *) image checkImageStatus:(NSString *)onServer uploadingImage:(BOOL)upload
{
    UIGraphicsBeginImageContext(image.size);
    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    
    if ([onServer isEqualToString:@"1"]) {
        UIImage *iconImage = [UIImage imageNamed:@"uploaded.png"];
        [iconImage drawInRect:CGRectMake(image.size.width-40, image.size.height-40, 40, 40)];
    }else if((!upload) && [onServer isEqualToString:@"0"]){
        UIImage *iconImage = [UIImage imageNamed:@"unupload.png"];
        [iconImage drawInRect:CGRectMake(image.size.width-40, image.size.height-40, 40, 40)];
    }else if( upload && [onServer isEqualToString:@"0"]){
        UIImage *iconImage = [UIImage imageNamed:@"uploading.png"];
        [iconImage drawInRect:CGRectMake(image.size.width-40, image.size.height-40, 40, 40)];
    }
    // make image out of bitmap context
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // free the context
    UIGraphicsEndImageContext();
    
    return finalImage;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"startUploading" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"onePhotoUploaded" object:nil];
}

@end
