//
//  PhotoSwipeViewController.h
//  Go Angel
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import <UIKit/UIKit.h>
#import "CSDevice.h"
#import "CSPhoto.h"
#import "MediaLoader.h"
#import "SinglePhotoViewController.h"

@interface PhotoSwipeViewController : UIViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (nonatomic, strong) UIPageViewController *pageViewController;
@property (weak, nonatomic) IBOutlet UIView *containerView;


@property int selected;
@property (nonatomic, strong) CSPhoto *selectedPhoto;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) MediaLoader *mediaLoader;

@end
