//
//  GroupTableViewController.h
//  Coinsorter
//
//  Created by Jake Runzer on 7/25/14.
//  Copyright (c) 2014 ACDSystems. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface GroupTableViewController : UITableViewController {
    ALAssetsLibrary *assetLibrary;
}

@property (nonatomic, strong) NSMutableArray *allAlbums;

@end
