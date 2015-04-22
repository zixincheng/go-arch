//
//  SingleLocationViewController.h
//  Go Arch
//
//  Created by Jake Runzer on 3/18/15.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "CSLocation.h"
#import "CoreDataWrapper.h"
#import "CSDevice.h"
#import "LocalLibrary.h"
#import "AccountDataWrapper.h"
#import "SingleLocationPageViewController.h"
#import "ELCImagePickerHeader.h"
#import "ELCOverlayImageView.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "SaveToDocument.h"


@interface SingleLocationViewController : UIViewController<UIActionSheetDelegate, ELCImagePickerControllerDelegate, UIImagePickerControllerDelegate> {
  LocalLibrary *localLibrary;
  NSUserDefaults *defaults;
}

@property (nonatomic, strong) Coinsorter *coinsorter;
@property (nonatomic, strong) CoreDataWrapper *dataWrapper;
//@property (nonatomic, strong) CSLocation *location;
@property (nonatomic, strong) CSAlbum *album;
@property (nonatomic, strong) CSDevice *localDevice;
@property (nonatomic, strong) SaveToDocument *saveFunction;

@property (nonatomic, strong) UIBarButtonItem *flexibleSpace;
@property (nonatomic, strong) UIBarButtonItem *mainCameraBtn;
@property (nonatomic, strong) UIBarButtonItem *deleteBtn;
@property (nonatomic, strong) UIBarButtonItem *shareBtn;

@property (nonatomic, assign) BOOL loadCamera;
@property (nonatomic, assign) BOOL saveInAlbum;

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (nonatomic, strong) SingleLocationPageViewController *pageController;
@property (nonatomic, strong) UIView *containerView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *rightButton;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

// camera vars
@property (nonatomic) UIImagePickerController *picker;
@property (nonatomic) UIView *overlay;
@property (nonatomic) AVCaptureSession *session;

@property (nonatomic, strong) UIView *topContainerView;
@property (nonatomic, strong) UILabel *topLbl;
@property (nonatomic, strong) UIView *cameraMenuView;
@property (nonatomic, strong) NSMutableSet *cameraBtnSet;

@property (nonatomic) UIButton *cameraBtn;


@end
