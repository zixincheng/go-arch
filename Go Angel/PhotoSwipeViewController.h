//
//  PhotoSwipeViewController.h
//  Go Angel
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "CSDevice.h"
#import "CSPhoto.h"
#import "SinglePhotoViewController.h"
#import "GridCell.h"

@interface PhotoSwipeViewController : UIViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate> {
  
  // bottom collection view selected cell index
  int bottom_selected;
}

@property (nonatomic, strong) UIPageViewController *pageViewController;
@property (weak, nonatomic) IBOutlet UIView *containerView;


@property int selected;
@property (nonatomic, strong) CSPhoto *selectedPhoto;
@property (nonatomic, strong) NSMutableArray *photos;

@end
