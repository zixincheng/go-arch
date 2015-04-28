//
//  SetDeviceImageViewController.m
//  Go Arch
//
//  Created by zcheng on 2015-04-28.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "SetDeviceImageViewController.h"

@interface SetDeviceImageViewController ()

@end

@implementation SetDeviceImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)selectedAction:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = @[(NSString *) kUTTypeImage, (NSString *) kUTTypeVideo];
    picker.allowsEditing = NO;
    [self presentViewController:picker animated:YES completion:nil];
}
- (IBAction)takenAction:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    if ([info objectForKey:UIImagePickerControllerOriginalImage]){
        self.photoImage=[info objectForKey:UIImagePickerControllerOriginalImage];
        [self.imageView setImage:self.photoImage];
    }
    
    [picker dismissViewControllerAnimated:NO completion:nil];
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
