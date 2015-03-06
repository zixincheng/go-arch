//
//  PhotoSwipeViewController.h
//  Go Arch
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
#import "CoreDataWrapper.h"
#import "Coinsorter.h"


// controller for swiping between fullscreen images

@interface PhotoSwipeViewController : UIViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate> {
  
  // bottom collection view selected cell index
  int bottom_selected;
}

@property (nonatomic, strong) UIPageViewController *pageViewController;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (nonatomic, strong) Coinsorter *coinsorter;



@property int selected;
@property (nonatomic, strong) CoreDataWrapper *dataWrapper;
@property (nonatomic, strong) CSPhoto *selectedPhoto;
@property (nonatomic, strong) NSMutableArray *photos;

@end
