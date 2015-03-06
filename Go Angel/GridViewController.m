//
//  GridViewController.m
//  Go Arch
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

@interface GridViewController () {
    BOOL enableEdit;
    NSMutableArray *selectedPhotos;
}

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
    self.coinsorter = [[Coinsorter alloc] initWithWrapper:self.dataWrapper];
    selectedPhotos = [NSMutableArray array];
    // Do any additional setup after loading the view.
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eachPhotoUploaded) name:@"onePhotoUploaded" object:nil];
    
  [self.navigationBar setTitle:self.device.deviceName];
  
  //self.photos = [self.dataWrapper getPhotos:self.device.remoteId ];
}

-(void)viewWillAppear:(BOOL)animated{
    NSLog(@"view appear");
    [self clearCellSelections];
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

- (void)eachPhotoUploaded{
    self.totalUploadedPhotos += 1;
    int currentPhotoIndex = (int)self.photos.count - self.totalUploadedPhotos;
    
    //update current uploaded photo onServer value
    CSPhoto *photo = [self.photos objectAtIndex:currentPhotoIndex];
    photo.thumbOnServer = [self.dataWrapper getCurrentPhotoOnServerVaule:self.device.remoteId CurrentIndex:currentPhotoIndex];
    [self.photos replaceObjectAtIndex:currentPhotoIndex withObject:photo];
    NSLog(@"current photo onServer value is: %@", photo.thumbOnServer);
    
    NSMutableArray *arrayWithIndexPaths = [NSMutableArray array];
    [arrayWithIndexPaths addObject:[NSIndexPath indexPathForRow:currentPhotoIndex inSection:0]];
    dispatch_async(dispatch_get_main_queue(), ^ {
        [self.collectionView reloadItemsAtIndexPaths:arrayWithIndexPaths];
    });
    NSLog(@"reload current photo at index : %i", currentPhotoIndex);
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
    cell.selectedBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"selectedbackground.png"]];
  [appDelegate.mediaLoader loadThumbnail:photo completionHandler:^(UIImage *image) {
    dispatch_async(dispatch_get_main_queue(), ^{
        __block UIImage *newimage = [self markedImageStatus:image checkImageStatus:photo.thumbOnServer uploadingImage:self.currentUploading];
        [imageView setImage:newimage];
    });
  }];
  
  return cell;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (enableEdit) {
        CSPhoto *selectedphoto = [self.photos objectAtIndex:indexPath.row];
        // Add the selected item into the array
        [selectedPhotos addObject:selectedphoto];
    } else {
  selected = [indexPath row];
  [self performSegueWithIdentifier:SINGLE_PHOTO_SEGUE sender:self];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (enableEdit) {
       NSString *deSelectedPhoto = [self.photos objectAtIndex:indexPath.row];
        [selectedPhotos removeObject:deSelectedPhoto];
    }
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

- (IBAction)editButtonTouched:(id)sender {
    UIBarButtonItem *editbtn =  (UIBarButtonItem *)sender;
    if ([editbtn.title isEqualToString:@"Delete"]) {
        self.collectionView.allowsMultipleSelection = YES;
        enableEdit = YES;
        self.editBtn.title = @"Done";
    } else {

        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Delete"
                                                          message:@"Delete Selected Photos?"
                                                         delegate:self
                                                cancelButtonTitle:@"Cancel"
                                                otherButtonTitles:@"Delete Only Locally", @"Delete Both Locally and Remote", nil];
        [message show];

    }
}

-(void)alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self clearCellSelections];
        self.collectionView.allowsMultipleSelection = NO;
        enableEdit = NO;
        self.editBtn.title = @"Delete";
    } else if (buttonIndex == 1){
        NSArray *selectedIndexPath = [self.collectionView indexPathsForSelectedItems];
        [self.collectionView performBatchUpdates:^{
            [self deleteItemsFromDataSourceAtIndexPaths: selectedIndexPath];
            [self.collectionView deleteItemsAtIndexPaths:selectedIndexPath];
        } completion:^(BOOL finished){
            [self.collectionView reloadData];
        }];

        self.collectionView.allowsMultipleSelection = NO;
        enableEdit = NO;
        self.editBtn.title = @"Delete";
    } else if (buttonIndex == 2) {
        NSString *onserver;

        for (CSPhoto *p in selectedPhotos) {
            if ([p.thumbOnServer isEqualToString:@"0"]) {
                onserver = @"0";
                break;
            }
        }
        if ([onserver isEqualToString:@"0"]) {
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Error"
                                                              message:@"Can't delete photo on server because it has not been uploaded yet"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                                    otherButtonTitles:nil];
            [message show];
        } else {
            NSArray *selectedIndexPath = [self.collectionView indexPathsForSelectedItems];
            [self.collectionView performBatchUpdates:^{
                [self deleteItemsFromDataSourceAtIndexPaths: selectedIndexPath];
                [self.collectionView deleteItemsAtIndexPaths:selectedIndexPath];
            } completion:^(BOOL finished){
                [self.collectionView reloadData];
            }];

            self.collectionView.allowsMultipleSelection = NO;
            enableEdit = NO;
            self.editBtn.title = @"Delete";

            [self.coinsorter DeletePhoto:selectedPhotos];
        }
    }
}

-(void) deleteItemsFromDataSourceAtIndexPaths :(NSArray *)itemPaths{

    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for (NSIndexPath *itemPath  in itemPaths) {
        [indexSet addIndex:itemPath.row];
    }
    [self.photos removeObjectsAtIndexes:indexSet];

    [self.dataWrapper deletePhotos:itemPaths];
}

- (void)clearCellSelections {
    int collectonViewCount = [self.collectionView numberOfItemsInSection:0];
    for (int i=0; i<=collectonViewCount; i++) {
        [self.collectionView deselectItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0] animated:YES];
    }
}
@end
