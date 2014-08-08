//
//  SinglePhotoViewController.h
//  Go Angel
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import <UIKit/UIKit.h>
#import "MediaLoader.h"
#import "CSPhoto.h"

@interface SinglePhotoViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property int selected;
@property (nonatomic, strong) CSPhoto *selectedPhoto;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) MediaLoader *mediaLoader;

@end
