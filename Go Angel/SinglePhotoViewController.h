//
//  SinglePhotoViewController.h
//  Go Angel
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "CSPhoto.h"


// controller to display the fullscreen photo
// used by the PhotoSwipeViewController
// this should manage the photo zooming

// TODO: Add photo zooming

@interface SinglePhotoViewController : UIViewController <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property int selected;
@property (nonatomic, strong) CSPhoto *selectedPhoto;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) UINavigationItem *navBar;

@end
