//
//  IndividualEntryViewController.h
//  Go Angel
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

@interface IndividualEntryViewController : UIViewController< UICollectionViewDataSource,UICollectionViewDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate,UITextFieldDelegate>{
    
    LocalLibrary *localLibrary;
    NSUserDefaults *defaults;
    AccountDataWrapper *account;
}

@property (nonatomic, strong) CSLocation *location;
@property (nonatomic, strong) CSDevice *localDevice;

@property (nonatomic, strong) Coinsorter *coinsorter;
@property (nonatomic, strong) CoreDataWrapper *dataWrapper;



@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, assign) BOOL saveInAlbum;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) NSMutableArray *tags;

// Camera vars
@property (nonatomic, strong) UIBarButtonItem *mainCameraBtn;
@property (nonatomic) UIImagePickerController *picker;
@property (nonatomic) UIView *overlay;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic, strong) UIView *doneCameraDownView;
@property (nonatomic, strong) UIView *doneCameraUpView;
@property (nonatomic, strong) UIView *topContainerView;
@property (nonatomic, strong) UILabel *topLbl;
@property (nonatomic, strong) UIView *cameraMenuView;
@property (nonatomic, strong) NSMutableSet *cameraBtnSet;

@property (nonatomic) UIButton *caremaBtn;


@end
