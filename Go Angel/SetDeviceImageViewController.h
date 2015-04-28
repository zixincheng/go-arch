//
//  SetDeviceImageViewController.h
//  Go Arch
//
//  Created by zcheng on 2015-04-28.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface SetDeviceImageViewController : UIViewController<UIImagePickerControllerDelegate,UINavigationControllerDelegate>


@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) UIImagePickerController *imagePicker;
@property (weak, nonatomic) UIImage *photoImage;


@end
