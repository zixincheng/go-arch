//
//  GridViewController.h
//  Go Angel
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

@interface GridViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate> {
  int selected;
}

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UINavigationItem *navigationBar;

@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) CoreDataWrapper *dataWrapper;
@property (nonatomic, strong) CSDevice *device;

@end
