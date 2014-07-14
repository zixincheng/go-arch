//
//  Menu.h
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 21/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MWPhotoBrowser.h"
#import "AppDelegate.h"
#import "CSPhoto.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface DeviceTableViewController : UITableViewController <MWPhotoBrowserDelegate, UITableViewDataSource> {
    NSMutableArray *_selections;
    NSMutableArray *localPhotos;
    // core data vars
}

@property (nonatomic, strong) NSMutableArray *devices;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) ALAssetsLibrary *assetLibrary;

- (void)loadAssets;

@end
