//
//  SinglePhotoViewController.m
//  Go Angel
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import "SinglePhotoViewController.h"

@interface SinglePhotoViewController ()

@end

@implementation SinglePhotoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self.container addSubview:self.tagField];
    // Do any additional setup after loading the view.
   NSLog(@"is video %@",self.selectedPhoto.isVideo);

  AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    if (self.selectedPhoto.isVideo == nil || [self.selectedPhoto.isVideo isEqualToString:@"0"]) {
      NSLog(@"NOT VIDEO, LOAD FULL SCREEN IMAGE");
        [appDelegate.mediaLoader loadFullScreenImage:self.selectedPhoto
                       completionHandler:^(UIImage *image) {

                           dispatch_async(dispatch_get_main_queue(), ^{
                               [self.imageView setImage:image];
                           });
                       }];
    } else {
        
        NSLog(@"%@",self.selectedPhoto.isVideo);
            
            NSString *newUrl = [[NSString alloc] initWithFormat:@"%@",self.selectedPhoto.imageURL];
            self.videoController = [[MPMoviePlayerController alloc]init];

            NSURL *theURL = [NSURL URLWithString:newUrl];
            [self.videoController.view setFrame:CGRectMake (0, 0, 320, 480)];

            [self.videoController setContentURL:theURL];
        
            [self.view insertSubview:self.videoController.view aboveSubview:self.imageView];
            self.videoController.shouldAutoplay = NO;
            [self.videoController prepareToPlay];
        //[self.videoController play];
            
    }
    self.tagField.text = self.selectedPhoto.tag;
}

- (void)viewDidAppear:(BOOL)animated {

  // set nav bar title
  [self.navBar
      setTitle:[NSString stringWithFormat:@"%d / %lu", self.selected + 1,
                                          (unsigned long)self.photos.count]];

  // add share button to top nav bar
  self.navBar.rightBarButtonItem = [[UIBarButtonItem alloc]
      initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                           target:self
                           action:@selector(shareAction)];
}

# pragma mark - TextField delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:0.25];
    [UIView setAnimationBeginsFromCurrentState:YES];
    self.tagField.frame = CGRectMake(self.tagField.frame.origin.x, self.tagField.frame.origin.y - 208.0, self.tagField.frame.size.width, self.tagField.frame.size.height);
    [UIView commitAnimations];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:0.25];
    [UIView setAnimationBeginsFromCurrentState:YES];
    self.tagField.frame = CGRectMake(self.tagField.frame.origin.x, (self.tagField.frame.origin.y + 208.0), self.tagField.frame.size.width, self.tagField.frame.size.height);
    [UIView commitAnimations];
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}

- (IBAction) textfieldChanged:(id)sender {
    
    UITextField *text = sender;
    self.selectedPhoto.tag = text.text;
    if (self.selectedPhoto.remoteID != nil) {
        [self.dataWrapper updatePhotoTag:self.selectedPhoto.tag photoId:self.selectedPhoto.remoteID photo:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"tagUpdated" object:nil];
    } else {
        [self.dataWrapper updatePhotoTag:self.selectedPhoto.tag photoId:nil photo:self.selectedPhoto];
        NSLog(@"could not update tag at this moment because the photo is not upload yet, tag will be update when uploading the photo");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"tagUpdated" object:nil];
    }
}

- (void)shareAction {
  
  AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
  [appDelegate.mediaLoader loadFullResImage:self.selectedPhoto completionHandler:^(UIImage *image) {
    NSArray *objectsToShare = @[ image ];
    
    UIActivityViewController *activityVC =
    [[UIActivityViewController alloc] initWithActivityItems:objectsToShare
                                      applicationActivities:nil];
    
    NSArray *excludeActivities = @[ ];
    
    activityVC.excludedActivityTypes = excludeActivities;
    
    [self presentViewController:activityVC animated:YES completion:nil];
  }];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
  return self.imageView;
}

/*
 #pragma mark - Navigation

 // In a storyboard-based application, you will often want to do a little
 preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
