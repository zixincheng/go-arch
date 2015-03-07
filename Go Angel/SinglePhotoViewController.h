//
//  SinglePhotoViewController.h
//  Go Arch
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "CSPhoto.h"
#import <MediaPlayer/MediaPlayer.h>
#import "CoreDataWrapper.h"
#import "Coinsorter.h"


// controller to display the fullscreen photo
// used by the PhotoSwipeViewController
// this should manage the photo zooming

// TODO: Add photo zooming

@interface SinglePhotoViewController : UIViewController <UIScrollViewDelegate>

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic)  UIScrollView *scrollView;


@property int selected;
@property (nonatomic, strong) CSPhoto *selectedPhoto;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) UINavigationItem *navBar;
@property (strong, nonatomic) MPMoviePlayerController *videoController;
@property (weak, nonatomic) IBOutlet UITextField *tagField;
@property (nonatomic, strong) CoreDataWrapper *dataWrapper;
@property (weak, nonatomic) IBOutlet UIView *container;
@property (nonatomic, strong) Coinsorter *coinsorter;

@end
