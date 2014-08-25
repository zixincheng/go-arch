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

// this is the page where the user can select and deselect watched albums
// this page gets called from the InAppSettingsView
// we define that we want to use this page in Root.plist in the
// settings bundle (we define the storyboard id to use there)

@property (nonatomic, strong) NSMutableArray *allAlbums;
@property (nonatomic, strong) NSMutableArray *selected;

@end
