//
//  SingleViewViewController.h
//  Go Arch
//
//  Created by zcheng on 2015-04-20.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "CSLocation.h"
#import "CoreDataWrapper.h"
#import "CSDevice.h"
#import "LocalLibrary.h"
#import "AccountDataWrapper.h"
#import "ELCImagePickerHeader.h"
#import "ELCOverlayImageView.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "SaveToDocument.h"
#import "PhotoSwipeViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "SGPopSelectView.h"

@interface SingleViewViewController : UIViewController <UIActionSheetDelegate, ELCImagePickerControllerDelegate, UIImagePickerControllerDelegate,UIScrollViewDelegate,UITextFieldDelegate,CLLocationManagerDelegate,UIGestureRecognizerDelegate,UITextViewDelegate> {
    AppDelegate *appDelegate;
    LocalLibrary *localLibrary;
    NSUserDefaults *defaults;
    CLGeocoder *geocoder;
}

@property (nonatomic, strong) Coinsorter *coinsorter;
@property (nonatomic, strong) CoreDataWrapper *dataWrapper;
//@property (nonatomic, strong) CSLocation *location;
@property (nonatomic, strong) CSAlbum *album;
@property (nonatomic, strong) CSDevice *localDevice;
@property (nonatomic, strong) SaveToDocument *saveFunction;
@property (nonatomic, strong) CSPhoto *selectedCoverPhoto;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) SGPopSelectView *popView;
@property (weak, nonatomic) IBOutlet UIView *infoview;

@property (nonatomic, strong) UIBarButtonItem *flexibleSpace;
@property (nonatomic, strong) UIBarButtonItem *mainCameraBtn;
@property (nonatomic, strong) UIBarButtonItem *deleteBtn;
@property (nonatomic, strong) UIBarButtonItem *shareBtn;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editBtn;

@property (nonatomic, assign) BOOL loadCamera;
@property (nonatomic, assign) BOOL saveInAlbum;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollview;
// camera vars
@property (nonatomic) UIImagePickerController *picker;
@property (nonatomic) UIView *overlay;
@property (nonatomic) AVCaptureSession *session;

@property (nonatomic, strong) UIView *topContainerView;
@property (nonatomic, strong) UILabel *topLbl;
@property (nonatomic, strong) UIView *cameraMenuView;
@property (nonatomic, strong) NSMutableSet *cameraBtnSet;

@property (nonatomic) UIButton *cameraBtn;

@property (weak, nonatomic) IBOutlet UIScrollView *imageScrollView;
@property (weak, nonatomic) IBOutlet UIImageView *coverImageView;


@property (weak, nonatomic) IBOutlet UITextField *lblCity;
@property (weak, nonatomic) IBOutlet UITextField *lblAddress;
@property (weak, nonatomic) IBOutlet UITextField *lblPrice;
@property (weak, nonatomic) IBOutlet UITextField *lblCountry;
@property (weak, nonatomic) IBOutlet UILabel *lblPhotosTotal;
@property (weak, nonatomic) IBOutlet UITextField *lblFloor;
@property (weak, nonatomic) IBOutlet UITextField *lblLot;
@property (weak, nonatomic) IBOutlet UITextField *lblBed;
@property (weak, nonatomic) IBOutlet UITextField *lblBath;
@property (weak, nonatomic) IBOutlet UITextField *lblName;
@property (weak, nonatomic) IBOutlet UITextField *lblType;
@property (weak, nonatomic) IBOutlet UITextField *lblListing;
@property (weak, nonatomic) IBOutlet UITextField *lblYearbuilt;
@property (weak, nonatomic) IBOutlet UITextField *lblmls;
@property (weak, nonatomic) IBOutlet UITextView *lblDescription;
@property (weak, nonatomic) IBOutlet UITextField *lbltag;
@property (weak, nonatomic) IBOutlet UILabel *lblState;


@property (weak, nonatomic) IBOutlet UIButton *typeSelectBtn;
@property (weak, nonatomic) IBOutlet UIButton *statusSelectBtn;
@property (weak, nonatomic) IBOutlet UIButton *bedSelectBtn;
@property (weak, nonatomic) IBOutlet UIButton *bathSelectBtn;



@end
