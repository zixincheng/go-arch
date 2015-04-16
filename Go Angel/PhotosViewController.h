//
//  PhotosViewController.h
//  Go Arch
//
//  Created by Jake Runzer on 3/19/15.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Coinsorter.h"
#import "CoreDataWrapper.h"
#import "CSDevice.h"
#import "CSLocation.h"
#import "AppDelegate.h"
#import "CSPhoto.h"
#import "CellLayout.h"
#import "GridCell.h"
#import "PhotoSwipeViewController.h"

@interface PhotosViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate, CellLayoutDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate, UIActionSheetDelegate> {
  AppDelegate *appDelegate;
  NSMutableArray *selectedPhotos;
}

@property (nonatomic, strong) Coinsorter *coinsorter;
@property (nonatomic, strong) CoreDataWrapper *dataWrapper;
//@property (nonatomic, strong) CSLocation *location;
@property (nonatomic, strong) CSAlbum *album;
@property (nonatomic, strong) CSDevice *localDevice;

@property (nonatomic, strong) CSPhoto *selectedCoverPhoto;
@property (nonatomic, strong) NSMutableArray *photos;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end
