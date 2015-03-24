//
//  IndividualEntryViewController.h
//  Go Arch
//
//  Created by zcheng on 2015-01-23.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSLocation.h"
#import "CoreDataWrapper.h"
#import "Coinsorter.h"
#import "CSDevice.h"
#import "PhotoSectionHeaderView.h"
#import "GridCell.h"
#import "Constants.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "LocalLibrary.h"
#import "AccountDataWrapper.h"
#import "AppDelegate.h"
#import "PhotoSwipeViewController.h"    
#import "CellLayoutDelegate.h"
#import "CellLayout.h"
#import "ELCImagePickerHeader.h"
#import "ELCOverlayImageView.h"
#import "PopOverMenu.h"
#import "SaveToDocument.h"

@interface IndividualEntryViewController : UIViewController< UICollectionViewDataSource,UICollectionViewDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate,UITextFieldDelegate,UIGestureRecognizerDelegate,CellLayoutDelegate,ELCImagePickerControllerDelegate,CTPopoutMenuDelegate,UIActionSheetDelegate>{
    
    LocalLibrary *localLibrary;
    NSUserDefaults *defaults;
    AccountDataWrapper *account;
    int totalAssets;
}

@property (nonatomic, strong) CSLocation *location;
@property (nonatomic, strong) CSDevice *localDevice;
@property (nonatomic, strong) CSPhoto *selectedCoverPhoto;

@property (nonatomic, strong) Coinsorter *coinsorter;
@property (nonatomic, strong) CoreDataWrapper *dataWrapper;
@property (nonatomic, strong) SaveToDocument *saveFunction;


@property (nonatomic) UIView *setCoverPageViewContainer;
@property (nonatomic) UIButton *DonesetCover;
@property (nonatomic) UIButton *CancelsetCover;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, assign) BOOL saveInAlbum;
@property (nonatomic, strong) NSMutableArray *photos;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *editBtn;
@property (nonatomic, strong) UIBarButtonItem *deleteBtn;
@property (nonatomic, strong) UIBarButtonItem *shareBtn;
@property (nonatomic, strong) UIBarButtonItem *exportBtn;
@property (nonatomic, strong) UIBarButtonItem *flexibleSpace;
// Camera vars
@property (nonatomic, strong) UIBarButtonItem *mainCameraBtn;
@property (nonatomic) UIImagePickerController *picker;
@property (nonatomic) UIImagePickerController *imagePicker;
@property (nonatomic, assign) BOOL isImagePickerUp;
@property (nonatomic) UIView *overlay;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic, strong) UIView *doneCameraDownView;
@property (nonatomic, strong) UIView *doneCameraUpView;
@property (nonatomic, strong) UIView *topContainerView;
@property (nonatomic, strong) UILabel *topLbl;
@property (nonatomic, strong) UIView *cameraMenuView;
@property (nonatomic, strong) NSMutableSet *cameraBtnSet;

@property (nonatomic) UIButton *caremaBtn;

@property (nonatomic, strong) NSMutableArray *tmpPhotos;
@property (nonatomic, strong) NSMutableArray *tmpMeta;
@property (nonatomic, strong) NSMutableArray *videoUrl;
@property (nonatomic, strong) NSMutableArray *locationArray;

@property (nonatomic, assign) NSString *loadCamera;
@property (nonatomic) CTPopoutMenu * popMenu;

@end
