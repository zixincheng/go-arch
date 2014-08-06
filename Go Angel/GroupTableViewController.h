//
//  GroupTableViewController.h
//  Go Angel
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface GroupTableViewController : UITableViewController {
  ALAssetsLibrary *assetLibrary;
}

@property (nonatomic, strong) NSMutableArray *allAlbums;
@property (nonatomic, strong) NSMutableArray *selected;

@end
