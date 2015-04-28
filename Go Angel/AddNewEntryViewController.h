//
//  AddNewEntryViewController.h
//  Go Arch
//
//  Created by zcheng on 2015-03-19.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "CSLocation.h"
#import "CSDevice.h"
#import "CSPhoto.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "AddingLocationViewController.h"
#import "SGPopSelectView.h"
#import "CSAlbum.h"
#import "SaveToDocument.h"
#import <CoreLocation/CoreLocation.h>

@interface AddNewEntryViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate,UIActionSheetDelegate,UIImagePickerControllerDelegate,AddingLocationViewControllerDelegate,UIGestureRecognizerDelegate,CLLocationManagerDelegate,UINavigationControllerDelegate>{
  
  AppDelegate *appDelegate;
    
  CLGeocoder *geocoder;
}

- (void) updateCoverPhoto:(CSPhoto *)image;
- (void) setEditEnabled:(BOOL)enabled;

// IF WE ARE GOING TO USE A LOCATION ALREADY IN DB AND EDIT IT, OR CREATE NEW LOCATION
@property (nonatomic) BOOL usePreviousLocation;

@property (weak, nonatomic) IBOutlet UIImageView *CoverImageView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *containerView;

@property (nonatomic,strong) UITextField *addressTextField;
@property (nonatomic,strong) UITextField *cityTextField;
@property (nonatomic,strong) UITextField *stateTextField;
@property (nonatomic,strong) UITextField *countryTextField;
@property (nonatomic,strong) UITextField *postcodeTextField;
@property (nonatomic,strong) UITextField *tagTextField;
@property (nonatomic,strong) UITextField *priceTextField;
@property (nonatomic,strong) UITextField *yearBuiltTextField;
@property (nonatomic,strong) UITextField *buildingSqftTextField;
@property (nonatomic,strong) UITextField *landSqftTextField;
@property (nonatomic,strong) UITextField *mlsTextField;
@property (nonatomic,strong) UITextField *nameTextField;
@property (nonatomic,strong) UITextField *descriptionTextField;

@property (nonatomic,strong) UILabel *typeLabel;
@property (nonatomic,strong) UILabel *statusLabel;
@property (nonatomic,strong) UILabel *bedLabel;
@property (nonatomic,strong) UILabel *bathLabel;

@property (nonatomic,strong)  UIButton *mapAddingBtn;
@property (nonatomic,strong)  UIButton *historySelectBtn;
@property (nonatomic,strong)  UIButton *typeSelectBtn;
@property (nonatomic,strong)  UIButton *statusSelectBtn;
@property (nonatomic,strong)  UIButton *bedSelectBtn;
@property (nonatomic,strong)  UIButton *bathSelectBtn;

@property (nonatomic,strong) CSDevice *localDevice;
@property (nonatomic,strong) CSLocation *location;
@property (nonatomic,strong) CSPhoto *coverPhoto;
@property (nonatomic,strong) CSAlbum *album;
@property (nonatomic,strong) CSEntry *entry;
@property (nonatomic,strong) SaveToDocument *saveFunction;

@property (nonatomic,strong) UIImage *photoImage;
@property (weak, nonatomic) IBOutlet UITableView *tableView;


@property (weak, nonatomic) IBOutlet UIView *locationView;
@property (nonatomic,strong) UIView *metadataView;

@property (nonatomic, strong) SGPopSelectView *popView;

@end
