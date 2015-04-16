//
//  OverviewViewController.h
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

@interface OverviewViewController : UIViewController {
  AppDelegate *appDelegate;
}

@property (nonatomic, strong) Coinsorter *coinsorter;
@property (nonatomic, strong) CoreDataWrapper *dataWrapper;
//@property (nonatomic, strong) CSLocation *location;
@property (nonatomic, strong) CSAlbum *album;
@property (nonatomic, strong) CSDevice *localDevice;

@property (nonatomic, strong) NSMutableArray *photos;

@property (nonatomic, assign) int totalPhotos;
@property (nonatomic, assign) int totalUnuploaded;
@property (nonatomic, assign) int totalUploaded;

@property (weak, nonatomic) IBOutlet UIImageView *coverImageView;
@property (weak, nonatomic) IBOutlet UILabel *lblCityState;
@property (weak, nonatomic) IBOutlet UILabel *lblAddress;
@property (weak, nonatomic) IBOutlet UILabel *lblPrice;
@property (weak, nonatomic) IBOutlet UILabel *lblCountry;
@property (weak, nonatomic) IBOutlet UILabel *lblPhotosTotal;
@property (weak, nonatomic) IBOutlet UILabel *lblFloor;
@property (weak, nonatomic) IBOutlet UILabel *lblLot;
@property (weak, nonatomic) IBOutlet UILabel *lblBed;
@property (weak, nonatomic) IBOutlet UILabel *lblBath;



@end
