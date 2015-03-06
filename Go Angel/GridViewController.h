//
//  GridViewController.h
//  Go Arch
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "CSPhoto.h"
#import "CSDevice.h"
#import "CoreDataWrapper.h"
#import "GridCell.h"
#import "PhotoSectionHeaderView.h"
#import "PhotoSwipeViewController.h"
#import "Coinsorter.h"


// the grid view for a devices photos
// displayed when a user taps on a device from the device controller
// uses uicollection view

@interface GridViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate> {
  int selected;
}

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UINavigationItem *navigationBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editBtn;

- (IBAction)editButtonTouched:(id)sender;

@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) CoreDataWrapper *dataWrapper;
@property (nonatomic, strong) CSDevice *device;
@property (nonatomic, assign) BOOL currentUploading;
@property (nonatomic, assign) int totalUploadedPhotos;

@property (nonatomic, strong) Coinsorter *coinsorter;

@end
