//
//  SingleViewViewController.m
//  Go Arch
//
//  Created by zcheng on 2015-04-20.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "SingleViewViewController.h"

#define CAMERA_TOPVIEW_HEIGHT   44  //title
#define CAMERA_MENU_VIEW_HEIGH  44  //menu

@interface SingleViewViewController () {
    BOOL hasCover;
    int selected;
    BOOL editEnabled;
}

@end

@implementation SingleViewViewController {
    BOOL enableEdit;
    BOOL takingPhoto;
    BOOL recording;
    NSTimer *timer;
    int sec;
    int min;
    int hour;
}
CGFloat animatedDistance;
static const CGFloat KEYBOARD_ANIMATION_DURATION = 0.3;
static const CGFloat MINIMUM_SCROLL_FRACTION = 0.2;
static const CGFloat MAXIMUM_SCROLL_FRACTION = 0.8;
static const CGFloat PORTRAIT_KEYBOARD_HEIGHT = 216;
static const CGFloat LANDSCAPE_KEYBOARD_HEIGHT = 162;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.scrollview.contentSize = CGSizeMake(320, 1420);
    //self.coverImageView.backgroundColor = [UIColor greenColor];
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.photos = [self.dataWrapper getPhotosWithAlbum:self.localDevice.remoteId album:self.album];
/*
    if (self.album.albumId !=nil) {
        [self.coinsorter getAlbumInfo:self.album.albumId];
        self.album = [self.dataWrapper getSingleAlbum:self.album];
    }
*/
    localLibrary = [[LocalLibrary alloc] init];
    self.saveFunction = [[SaveToDocument alloc]init];
    defaults = [NSUserDefaults standardUserDefaults];
    
    self.saveInAlbum = [defaults boolForKey:SAVE_INTO_ALBUM];
    
    // init buttons
    
    self.mainCameraBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(cameraButtonPressed:)];
    self.flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.toolbarItems = [NSArray arrayWithObjects:self.flexibleSpace, self.mainCameraBtn, self.flexibleSpace, nil];
    
    [self.navigationController setToolbarHidden:NO];
    // Do any additional setup after loading the view.
    
    UITapGestureRecognizer *tapImageView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTaped:)];
    tapImageView.numberOfTapsRequired = 1;
    tapImageView.numberOfTouchesRequired = 1;
    [self.imageScrollView addGestureRecognizer:tapImageView];
    
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressRecognizer:)];
    lpgr.minimumPressDuration = 1.0;
    lpgr.delegate = self;
    [self.imageScrollView addGestureRecognizer:lpgr];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
    //[self.imageScrollView setUserInteractionEnabled:YES];
    [self settextfieldAction];
    [self setValues];
    [self updateCount];
    [self setCoverPhoto];
    [self addToolBarOnKeyboard];
    self.lblDescription.layer.borderWidth = 2.0f;
    self.lblDescription.layer.borderColor = [[UIColor grayColor] CGColor];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addnewPhoto) name:@"addNewPhoto" object:nil];
}

-(void)addToolBarOnKeyboard {
    
    UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 50)];
    numberToolbar.barStyle = UIBarStyleBlackTranslucent;
    numberToolbar.items = [NSArray arrayWithObjects:
                           [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                           [[UIBarButtonItem alloc]initWithTitle:@"Apply" style:UIBarButtonItemStyleDone target:self action:@selector(doneWithNumberPad:)],
                           nil];
    [numberToolbar sizeToFit];
    self.lblPrice.inputAccessoryView = numberToolbar;
    self.lblYearbuilt.inputAccessoryView = numberToolbar;
    self.lblFloor.inputAccessoryView = numberToolbar;
    self.lblLot.inputAccessoryView = numberToolbar;
    self.lblmls.inputAccessoryView = numberToolbar;
    self.lblDescription.inputAccessoryView = numberToolbar;
    
}

-(void)doneWithNumberPad:(id) sender{
    
    [self.lblPrice resignFirstResponder];
    [self.lblYearbuilt resignFirstResponder];
    [self.lblFloor resignFirstResponder];
    [self.lblLot resignFirstResponder];
    [self.lblmls resignFirstResponder];
    [self.lblDescription resignFirstResponder];
}


-(void)addnewPhoto {
    self.photos = [self.dataWrapper getPhotosWithAlbum:self.localDevice.remoteId album:self.album];
    //[self setCoverPhoto];
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"addNewPhoto" object:nil];
}
# pragma mark - long press gesture and set to home image

-(void) longPressRecognizer: (UILongPressGestureRecognizer *) gestureRecognizer {
    CGFloat width = self.imageScrollView.frame.size.width;
    float pagefloat = (self.imageScrollView.contentOffset.x) / width;
    NSInteger page = lround(pagefloat);
    selected = (int)page;
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        
            //self.setCoverPageViewContainer.frame = CGRectMake(0, 430, 320, 150);
            UIActionSheet *shareActionSheet = [[UIActionSheet alloc] initWithTitle:@"Cover Image" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Set As Cover Image",@"Share With Friends",@"Delete", nil];
            [shareActionSheet showInView:self.view];
        shareActionSheet.tag = 0;
        
        self.selectedCoverPhoto = [self.photos objectAtIndex:page];
    }
}

-(void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.tag == 0) {
        switch (buttonIndex) {
            case 0:
            {
                self.album.coverImage =  self.selectedCoverPhoto.remoteID;
                [self.dataWrapper updateAlbum:self.album];
                [self.coinsorter updateAlbum:self.album];
                //[self.coinsorter updateMeta:self.selectedCoverPhoto entity:@"home" value:@"1"];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"CoverPhotoChange" object:nil];
                break;
            }
            case 1:
            {
                [appDelegate.mediaLoader loadFullResImage:self.selectedCoverPhoto completionHandler:^(UIImage *image) {

                        NSArray *objectsToShare = @[ image ];
                        
                        UIActivityViewController *activityVC =
                        [[UIActivityViewController alloc] initWithActivityItems:objectsToShare
                                                          applicationActivities:nil];
                        
                        NSArray *excludeActivities = @[ ];
                        
                        activityVC.excludedActivityTypes = excludeActivities;
                        
                        [self presentViewController:activityVC animated:YES completion:nil];
                }];
                break;
            }
            case 2:
            {
                [self deletePhotoFromFile:self.selectedCoverPhoto];
                [self deleteItemsFromDataSourceAtIndexPath: self.selectedCoverPhoto itemPath:selected];
                break;
            }
            default:
                break;
        }

    } else if (actionSheet.tag==1){
        switch (buttonIndex) {
            case 0:
                // photo library
                [self photoLibrary];
                break;
            case 1:
                // take photo or video
                [self takePhotoOrVideo];
                break;
            default:
                break;
        }
    }
}

-(void) deleteItemsFromDataSourceAtIndexPath :(CSPhoto *)deletedPhoto itemPath:(int) itemPath{
    

    //[self.photos removeObjectAtIndex:itemPath];

    [self.dataWrapper deletePhotos:deletedPhoto];
    self.photos = [self.dataWrapper getPhotosWithAlbum:self.localDevice.remoteId album:self.album];
    [self setCoverPhoto];
}

- (void) deletePhotoFromFile: (CSPhoto *) p {
    NSMutableArray *photoPath = [NSMutableArray array];
    
        // get documents directory
        NSURL *imageUrl = [NSURL URLWithString:p.imageURL];
        NSURL *thumUrl = [NSURL URLWithString:p.thumbURL];
        [photoPath addObject:imageUrl.path];
        [photoPath addObject:thumUrl.path];
    
    for (NSString *currentpath in photoPath) {
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:currentpath error:&error];
    }
    
    
}

#pragma mark - edit actions
- (IBAction)editBtnPressed:(id)sender {
    if ([self.editBtn.title isEqualToString:@"Edit"]) {
        [self setEditEnabled:YES];
        
        self.editBtn.title = @"Save";
    } else {
        [self setEditEnabled:NO];
        self.editBtn.title = @"Edit";
        if (self.album.entry.location.sublocation !=nil && self.album.entry.location.city !=nil && self.album.entry.location.province != nil) {
            [appDelegate.dataWrapper updateAlbum:self.album];
            [appDelegate.coinsorter updateAlbum:self.album];
                

        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ERROR" message:@"Address or City or State Can't be Empty" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            
            [alert show];
        }

    }
    
}

- (void) setEditEnabled:(BOOL)enabled {
    editEnabled = enabled;
    
    [self.lblAddress setEnabled:enabled];
    [self.lblDescription setEditable:enabled];
    [self.lblFloor setEnabled:enabled];
    [self.lblPrice setEnabled:enabled];
    [self.lblLot setEnabled:enabled];
    [self.lblName setEnabled:enabled];
    [self.lblYearbuilt setEnabled:enabled];
    [self.lblmls setEnabled:enabled];
    [self.lbltag setEnabled:enabled];
    [self.lblDescription setEditable:enabled];
    [self.lblPrice setText:[self getPriceText]];
    [self.lblName setText:self.album.name];
    [self.lblDescription setText:self.album.albumDescritpion];
    if (enabled) {
        [self.lblAddress setBorderStyle:UITextBorderStyleRoundedRect];
        [self.lblPrice setBorderStyle:UITextBorderStyleRoundedRect];
        [self.lblFloor setBorderStyle:UITextBorderStyleRoundedRect];
        [self.lblLot setBorderStyle:UITextBorderStyleRoundedRect];
        [self.lblName setBorderStyle:UITextBorderStyleRoundedRect];
        [self.lblYearbuilt setBorderStyle:UITextBorderStyleRoundedRect];
        [self.lblmls setBorderStyle:UITextBorderStyleRoundedRect];
        [self.lbltag setBorderStyle:UITextBorderStyleRoundedRect];
        [self.statusSelectBtn setHidden:NO];
        [self.typeSelectBtn setHidden:NO];
        [self.bedSelectBtn setHidden:NO];
        [self.bathSelectBtn setHidden:NO];
        [self.lblFloor setText:[self.album.entry.buildingSqft stringValue]];
        [self.lblLot setText:[self.album.entry.landSqft stringValue]];
    } else {
        [self.lblAddress setBorderStyle:UITextBorderStyleNone];
        [self.lblPrice setBorderStyle:UITextBorderStyleNone];
        [self.lblFloor setBorderStyle:UITextBorderStyleNone];
        [self.lblLot setBorderStyle:UITextBorderStyleNone];
        [self.lblName setBorderStyle:UITextBorderStyleNone];
        [self.lblYearbuilt setBorderStyle:UITextBorderStyleNone];
        [self.lblmls setBorderStyle:UITextBorderStyleNone];
        [self.lbltag setBorderStyle:UITextBorderStyleNone];
        [self.statusSelectBtn setHidden:YES];
        [self.typeSelectBtn setHidden:YES];
        [self.bedSelectBtn setHidden:YES];
        [self.bathSelectBtn setHidden:YES];
        [self.lblFloor setText: [NSString stringWithFormat:@"%@ sq. ft.", self.album.entry.buildingSqft.stringValue]];
        [self.lblLot setText:[NSString stringWithFormat:@"%@ sq. ft.", self.album.entry.landSqft.stringValue]];
        if (self.album.name == nil) {
            [self.lblName setText:@"Name"];
        }
        if (self.album.albumDescritpion == nil) {
            [self.lblDescription setText:@"No Description Yet"];
        }
    }
}

- (NSString *) getPriceText {
    if (editEnabled) {
        return [self.album.entry.price stringValue];
    } else {
        return [self.album.entry formatPrice:self.album.entry.price];
    }
}

-(void) imageTaped:(UIGestureRecognizer *)gestureRecognizer {
    [self performSegueWithIdentifier:@"singleImageSegue" sender:self];
}

#pragma mark - TextField Delegate


-(void)textViewDidChange:(UITextView *)textView {
    self.album.albumDescritpion = self.lblDescription.text;
}



-(void)dismissKeyboard {
    [self.view endEditing:YES];
    if (self.popView.visible) {
        [self.popView hide:YES];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}
- (void)textFieldValueChanged:(id)sender {
    
    // if using previous location, don't save all edits into location objectbrew up
    //    if (_usePreviousLocation) {
    //        return;
    //    }
    
    NSNumberFormatter *format = [[NSNumberFormatter alloc]init];
    format.numberStyle = NSNumberFormatterDecimalStyle;
    if (sender == self.lblAddress) {
        self.album.entry.location.sublocation = self.lblAddress.text;
        [self geocodeAddress];
    } else if (sender == self.lblCity) {
        self.album.entry.location.city = self.lblCity.text;
    } else if (sender == self.lblCountry) {
        self.album.entry.location.country = self.lblCountry.text;
    } else if (sender == self.lbltag) {
        self.album.entry.tag = self.lbltag.text;
    } else if (sender == self.lblPrice) {
        self.album.entry.price = [format numberFromString: self.lblPrice.text];
    } else if (sender == self.lblYearbuilt) {
        self.album.entry.yearBuilt = self.lblYearbuilt.text;
    } else if (sender == self.lblFloor) {
        self.album.entry.buildingSqft = [format numberFromString: self.lblFloor.text];
    } else if (sender == self.lblLot) {
        self.album.entry.landSqft = [format numberFromString: self.lblLot.text];
    } else if (sender == self.lblmls) {
        self.album.entry.mls = self.lblmls.text;
    } else if (sender == self.lblName) {
        self.album.name = self.lblName.text;
    }
}

-(void) textFieldDidBeginEditing:(UITextField *)textField {
    if (self.popView.visible) {
        self.popView.hidden = YES;
    }
    
    //the following few lines calculate how far we’ll need to scroll
    CGRect textFieldRect = [self.view.window convertRect:textField.bounds fromView:textField];
    CGRect viewRect = [self.view.window convertRect:self.view.bounds fromView:self.view];
    
    CGFloat midline = textFieldRect.origin.y + 0.5 * textFieldRect.size.height;
    CGFloat numerator = midline - viewRect.origin.y - MINIMUM_SCROLL_FRACTION * viewRect.size.height;
    CGFloat denominator = (MAXIMUM_SCROLL_FRACTION - MINIMUM_SCROLL_FRACTION) * viewRect.size.height;
    CGFloat heightFraction = numerator / denominator;
    
    //make sure it's scrolling reasonably
    if (heightFraction < 0.0) {
        heightFraction = 0.0;
    }else if (heightFraction > 1.0) {
        heightFraction = 1.0;
    }
    
    //the orientation of the phone changes how much we want to scroll.
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
        animatedDistance = floor(PORTRAIT_KEYBOARD_HEIGHT * heightFraction);
    }else {
        animatedDistance = floor(LANDSCAPE_KEYBOARD_HEIGHT * heightFraction);
    }
    
    //get the scrollview's current size, and add the distance we want to scroll to it
    CGSize newSize = self.scrollview.contentSize;
    newSize.height += animatedDistance;
    self.scrollview.contentSize = newSize;
    
    //finally, scroll that distance
    CGPoint p = self.scrollview.contentOffset;
    p.y += animatedDistance;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:KEYBOARD_ANIMATION_DURATION];
    
    [self.scrollview setContentOffset:p animated:NO];
    
    [UIView commitAnimations];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    

    CGSize newSize = self.scrollview.contentSize;
    newSize.height -= animatedDistance;
    CGPoint p = self.scrollview.contentOffset;
    p.y -= animatedDistance;
    
    //note that we have to animate BOTH the scrollview resizing AND the offset change.
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:KEYBOARD_ANIMATION_DURATION];
    self.scrollview.contentSize = newSize;
    [self.scrollview setContentOffset:p animated:NO];
    [UIView commitAnimations];
    //return YES;
    //self.priceTextField.text = [self getPriceText];
}



-(void) geocodeAddress {
    geocoder = [[CLGeocoder alloc]init];
    [geocoder geocodeAddressString:self.lblAddress.text completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error) {
            NSLog(@"%@", error);
        } else {
            CLPlacemark *placemark = [placemarks lastObject];
            [NSString stringWithFormat:@"%f", placemark.location.coordinate.latitude];
            self.album.entry.location.longitude = [NSString stringWithFormat:@"%f", placemark.location.coordinate.longitude];
            self.album.entry.location.latitude = [NSString stringWithFormat:@"%f", placemark.location.coordinate.latitude];
            self.album.entry.location.postCode = [placemark.addressDictionary objectForKey:@"ZIP"];
            self.album.entry.location.country =
            [placemark.addressDictionary objectForKey:@"Country"];
            self.album.entry.location.countryCode =
            [placemark.addressDictionary objectForKey:@"CountryCode"];
            self.album.entry.location.city = [placemark.addressDictionary objectForKey:@"City"];
            self.album.entry.location.province = [placemark.addressDictionary objectForKey:@"State"];
            [self setValues];
        }
    }];
}


- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"singleImageSegue"]) {
        PhotoSwipeViewController *swipeController = (PhotoSwipeViewController *) segue.destinationViewController;
        swipeController.selected = selected;
        swipeController.photos = self.photos;
        swipeController.dataWrapper = self.dataWrapper;
        swipeController.coinsorter = self.coinsorter;
    }
    
}

# pragma mark - UI setup

- (IBAction)showpop:(id)sender {
        if (self.popView.visible) {
            self.popView.hidden = YES;
        }
        self.popView = [[SGPopSelectView alloc] init];
        if (sender == self.typeSelectBtn) {
            NSArray *type = @[@"Condominium",@"Commercial",@"Farm",@"House",@"Land",@"Parking",@"Residential",@"Recreational",@"Townhouses"];
            [self.view addSubview:self.popView];
            self.popView.selections = type;
            typeof(self) __weak weakSelf = self;
            self.popView.selectedHandle = ^(NSInteger selectedIndex){
                NSLog(@"selected index %ld, content is %@", selectedIndex,type[selectedIndex]);
                [weakSelf.lblType setText:[type objectAtIndex:selectedIndex]];
                weakSelf.album.entry.type = weakSelf.lblType.text;
            };
        } else if (sender == self.statusSelectBtn) {
            
            NSArray *type = @[@"For Sale",@"For Rent",@"For Sale Or Rent"];
            [self.view addSubview:self.popView];
            self.popView.selections = type;
            typeof(self) __weak weakSelf = self;
            self.popView.selectedHandle = ^(NSInteger selectedIndex){
                NSLog(@"selected index %ld, content is %@", selectedIndex,type[selectedIndex]);
                [weakSelf.lblListing setText:[type objectAtIndex:selectedIndex]];
                weakSelf.album.entry.listing = weakSelf.lblListing.text;
            };
        } else if (sender == self.bedSelectBtn) {
            NSArray *type = @[@"1",@"2",@"3",@"4",@"5",@"6",@"6+"];
            [self.view addSubview:self.popView];
            self.popView.selections = type;
            typeof(self) __weak weakSelf = self;
            self.popView.selectedHandle = ^(NSInteger selectedIndex){
                NSLog(@"selected index %ld, content is %@", selectedIndex,type[selectedIndex]);
                [weakSelf.lblBed setText:[type objectAtIndex:selectedIndex]];
                weakSelf.album.entry.bed = weakSelf.lblBed.text;
            };
        } else if (sender == self.bathSelectBtn) {
            NSArray *type = @[@"1",@"2",@"3",@"4",@"5",@"5+"];
            [self.view addSubview:self.popView];
            self.popView.selections = type;
            typeof(self) __weak weakSelf = self;
            self.popView.selectedHandle = ^(NSInteger selectedIndex){
                NSLog(@"selected index %ld, content is %@", selectedIndex,type[selectedIndex]);
                [weakSelf.lblBath setText:[type objectAtIndex:selectedIndex]];
                weakSelf.album.entry.bath = weakSelf.lblBath.text;
            };
        }
    CGPoint p = [self.view center];
    
    [self.popView showFromView:self.view atPoint:p animated:YES];
    
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint p = [gestureRecognizer locationInView:self.view];
    if (self.popView.visible && CGRectContainsPoint(self.popView.frame, p)) {
        return NO;
    }
    return YES;
}

-(void) settextfieldAction {
    [self.lblAddress addTarget:self action:@selector(textFieldValueChanged:) forControlEvents:UIControlEventAllEditingEvents];
    [self.lblName addTarget:self action:@selector(textFieldValueChanged:) forControlEvents:UIControlEventAllEditingEvents];
    [self.lblPrice addTarget:self action:@selector(textFieldValueChanged:) forControlEvents:UIControlEventAllEditingEvents];
    [self.lblFloor addTarget:self action:@selector(textFieldValueChanged:) forControlEvents:UIControlEventAllEditingEvents];
    [self.lblLot addTarget:self action:@selector(textFieldValueChanged:) forControlEvents:UIControlEventAllEditingEvents];
    [self.lblYearbuilt addTarget:self action:@selector(textFieldValueChanged:) forControlEvents:UIControlEventAllEditingEvents];
    [self.lblAddress addTarget:self action:@selector(textFieldValueChanged:) forControlEvents:UIControlEventAllEditingEvents];
    [self.lblmls addTarget:self action:@selector(textFieldValueChanged:) forControlEvents:UIControlEventAllEditingEvents];
    [self.lbltag addTarget:self action:@selector(textFieldValueChanged:) forControlEvents:UIControlEventAllEditingEvents];
}

- (void) setValues {
    NSString *price = [self.album.entry formatPrice:self.album.entry.price];
    NSString *buildingSqft = [NSString stringWithFormat:@"%@ sq. ft.", self.album.entry.buildingSqft.stringValue];
    NSString *landSqft = [NSString stringWithFormat:@"%@ sq. ft.", self.album.entry.landSqft.stringValue];
    NSString *beds = [NSString stringWithFormat:@"%@", self.album.entry.bed];
    NSString *baths = [NSString stringWithFormat:@"%@", self.album.entry.bath];
    NSString *name = [NSString stringWithFormat:@"%@", self.album.name];
    NSString *description = [NSString stringWithFormat:@"%@", self.album.albumDescritpion];
    NSString *type = [NSString stringWithFormat:@"%@", self.album.entry.type];
    NSString *listing = [NSString stringWithFormat:@"%@", self.album.entry.listing];
    NSString *yearBuilt = [NSString stringWithFormat:@"%@", self.album.entry.yearBuilt];
    NSString *mls = [NSString stringWithFormat:@"%@", self.album.entry.mls];
    NSString *tag = [NSString stringWithFormat:@"%@", self.album.entry.tag];
    NSString *state = [NSString stringWithFormat:@"%@", self.album.entry.location.province];
    
    if (!self.album.entry.bed) {
        beds = @"";
    }
    if (!self.album.entry.bath) {
        baths = @"";
    }
    if (!self.album.entry.buildingSqft) {
        buildingSqft = @"";
    }
    if (!self.album.entry.landSqft) {
        landSqft = @"";
    }
    if (!self.album.name) {
        name = @"Name";
    }
    if (!self.album.albumDescritpion) {
        description = @"";
    }
    if (!self.album.entry.type) {
        type = @"";
    }
    if (!self.album.entry.listing) {
        listing = @"";
    }
    if (!self.album.entry.yearBuilt) {
        yearBuilt = @"";
    }
    if (!self.album.entry.mls) {
        mls = @"";
    }
    if (!self.album.entry.tag) {
        tag = @"";
    }
    if (!self.album.albumDescritpion) {
        description = @"No Description Yet";
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _lblAddress.text = self.album.entry.location.sublocation;
        [_lblCity setText:self.album.entry.location.city];
        [_lblState setText:state];
        [_lblCountry setText:self.album.entry.location.country];
        [_lblPrice setText:price];
        [_lblFloor setText:buildingSqft];
        [_lblLot setText:landSqft];
        [_lblBed setText:beds];
        [_lblBath setText:baths];
        [_lblName setText:name];
        [_lblDescription setText:description];
        [_lbltag setText:tag];
        [_lblType setText:type];
        [_lblListing setText:listing];
        [_lblYearbuilt setText:yearBuilt];
        [_lblmls setText:mls];
        [_lblDescription setText:description];
    });
}

- (void) updateCount {
    _photos = [self.dataWrapper getPhotosWithAlbum:self.localDevice.remoteId album:self.album];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_lblPhotosTotal setText:[NSString stringWithFormat:@"%lu Photos", (unsigned long)_photos.count]];
    });
}

-(void) scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat width = self.imageScrollView.frame.size.width;
    float pagefloat = (self.imageScrollView.contentOffset.x) / width;
    NSInteger page = lround(pagefloat);
    selected = (int)page;
    dispatch_async(dispatch_get_main_queue(), ^{
        [_lblPhotosTotal setText:[NSString stringWithFormat:@"%ld/%lu Photos", (long)page+1,(unsigned long)_photos.count]];
    });
}

// set the cover photo that is displayed
- (void) setCoverPhoto {
    
    //  UILabel for title
    CSPhoto * coverPhoto = [[CSPhoto alloc]init];
    if (self.photos.count !=0) {
        coverPhoto = [self.dataWrapper getCoverPhoto:self.localDevice.remoteId album:self.album];
        if (coverPhoto == nil) {
            coverPhoto = [self.photos objectAtIndex:0];
        }
    }
    //[self.imageScrollView setUserInteractionEnabled:NO];
   //[cell addGestureRecognizer:scrollView.panGestureRecognizer];
    

    CGRect adjustedFrame =self.coverImageView.frame;
    adjustedFrame.size.width = self.imageScrollView.frame.size.width;
    adjustedFrame.origin.x = 0;
    [self.coverImageView setFrame:adjustedFrame];
    self.coverImageView.image = nil;

    [appDelegate.mediaLoader loadFullScreenImage:coverPhoto completionHandler:^(UIImage *image) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _coverImageView.image = image;
            UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            titleLabel.textAlignment = NSTextAlignmentRight;
            titleLabel.backgroundColor = [UIColor clearColor];
            titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:15];
            titleLabel.textColor = [UIColor whiteColor];
            titleLabel.shadowColor = [UIColor blackColor];
            titleLabel.shadowOffset = CGSizeMake(0, 1);
            titleLabel.numberOfLines = 1;
            titleLabel.frame = CGRectMake(5, self.coverImageView.frame.size.height - 25, self.coverImageView.frame.size.width - 10, 20);
            titleLabel.text = coverPhoto.tag;
            [self.coverImageView addSubview:titleLabel];
        });
    }];
    // loop through all photos
    int index = 0;
    for (CSPhoto *p in self.photos) {
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        titleLabel.textAlignment = NSTextAlignmentRight;
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:15];
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.shadowColor = [UIColor blackColor];
        titleLabel.shadowOffset = CGSizeMake(0, 1);
        titleLabel.numberOfLines = 1;
        titleLabel.frame = CGRectMake(5, self.coverImageView.frame.size.height - 25, self.coverImageView.frame.size.width - 10, 20);
        // don't display home photo twice
        if ([p.imageURL isEqualToString:coverPhoto.imageURL]) {
            continue;
        }
        
        // create new frame based on cover view (the front image)
        CGRect newFrame = self.coverImageView.frame;
        newFrame.origin.x = newFrame.origin.x + ((index + 1) * newFrame.size.width);
        
        //    NSLog(@"cover frame x: %f, cover frame width: %f", coverImageView.frame.origin.x, coverImageView.frame.size.width);
        
        UIImageView *view = [[UIImageView alloc] initWithFrame:newFrame];
        [view setContentMode:UIViewContentModeScaleAspectFill];
        [view setClipsToBounds:YES];
        [appDelegate.mediaLoader loadThumbnail:p completionHandler:^(UIImage* image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [view setImage:image];
            });
        }];
        titleLabel.text = p.tag;
        [view addSubview:titleLabel];
        [self.imageScrollView addSubview:view];
        //    NSLog(@"view width: %f, x: %f", view.frame.size.width, view.frame.origin.x);
        index += 1;
    }
    
    // set scroll view content size based on how many images are in album
    int totalWidth = self.coverImageView.frame.size.width + (self.coverImageView.frame.size.width * index);
    //  NSLog(@"index: %d, total width: %d", index, totalWidth);
    [self.imageScrollView setContentSize:CGSizeMake(totalWidth, self.coverImageView.frame.size.height)];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


# pragma mark - camera setup

- (void) cameraButtonPressed:(id) sender {
    UIActionSheet *cameraSheet = [[UIActionSheet alloc] initWithTitle:@"Upload Photo or Video" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Photo Library", @"Take Photo or Video", nil];
    cameraSheet.tag = 1;
    [cameraSheet showInView:self.view];
    
}

- (UIButton*)buildButton:(CGRect)frame
            normalImgStr:(NSString*)normalImgStr
         highlightImgStr:(NSString*)highlightImgStr
          selectedImgStr:(NSString*)selectedImgStr
                  action:(SEL)action
              parentView:(UIView*)parentView {
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = frame;
    if (normalImgStr.length > 0) {
        [btn setImage:[UIImage imageNamed:normalImgStr] forState:UIControlStateNormal];
    }
    if (highlightImgStr.length > 0) {
        [btn setImage:[UIImage imageNamed:highlightImgStr] forState:UIControlStateHighlighted];
    }
    if (selectedImgStr.length > 0) {
        [btn setImage:[UIImage imageNamed:selectedImgStr] forState:UIControlStateSelected];
    }
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [parentView addSubview:btn];
    
    return btn;
}

# pragma mark - camera selectors

// text message at top of the custom camera view
- (void)addTopViewWithText:(NSString*)text{
    //if (!_topContainerView) {
    CGRect topFrame = CGRectMake(0, 0, APP_SIZE.width, CAMERA_TOPVIEW_HEIGHT);
    
    UIView *tView = [[UIView alloc] initWithFrame:topFrame];
    tView.backgroundColor = [UIColor clearColor];
    [self.overlay addSubview:tView];
    self.topContainerView = tView;
    
    UIView *emptyView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, topFrame.size.width, topFrame.size.height)];
    emptyView.backgroundColor = [UIColor blackColor];
    emptyView.alpha = 0.4f;
    [_topContainerView addSubview:emptyView];
    
    topFrame.origin.x += 10;
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 500, topFrame.size.height)];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor whiteColor];
    lbl.font = [UIFont systemFontOfSize:25.f];
    lbl.textAlignment = NSTextAlignmentNatural;
    [_topContainerView addSubview:lbl];
    self.topLbl = lbl;
    // }
    _topLbl.text = text;
}

-(void) flashScreen {
    CGFloat height = DEVICE_SIZE.height - CAMERA_MENU_VIEW_HEIGH - 95;
    UIWindow* wnd = [UIApplication sharedApplication].keyWindow;
    UIView* v = [[UIView alloc] initWithFrame: CGRectMake(0, 0, DEVICE_SIZE.width, height)];
    [wnd addSubview: v];
    v.backgroundColor = [UIColor whiteColor];
    [UIView beginAnimations: nil context: nil];
    [UIView setAnimationDuration: 1.0];
    v.alpha = 0.0f;
    [UIView commitAnimations];
}

//button taking picture
- (void)takePictureBtnPressed: (id) sender{
    // if the camera is under photo model
    if (takingPhoto) {
        [self.picker takePicture];
        [self flashScreen];
    }
    // if the camera is under video model
    else {
        if (recording) {
            [self.cameraBtn setImage:[UIImage imageNamed:@"video.png"] forState:UIControlStateNormal];
            
            [self.picker stopVideoCapture];
            recording = NO;
            sec = 0;
            min = 0;
            hour = 0;
            _topLbl.text = [NSString stringWithFormat:@"%d:%d:%d",hour,min,sec];
            [timer invalidate];
        } else {
            [self.cameraBtn setImage:[UIImage imageNamed:@"videoFinish.png"] forState:UIControlStateNormal];
            [self.picker startVideoCapture];
            timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(videotimer) userInfo:nil repeats:YES];
            recording = YES;
        }
        
    }
}
// taking videos
- (void)VideoBtnPressed:(UIButton*)sender {
    
    sender.selected = !sender.selected;
    if (takingPhoto) {
        
        self.picker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
        takingPhoto = NO;
        [self.cameraBtn setImage:[UIImage imageNamed:@"video.png"] forState:UIControlStateNormal];
        
        _topLbl.text = @"Taking Video";
        NSLog(@"media type %@",self.picker.mediaTypes );
    } else {
        self.picker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil];
        takingPhoto = YES;
        [self.cameraBtn setImage:[UIImage imageNamed:@"shot.png"] forState:UIControlStateNormal];
        _topLbl.text = @"Taking Photo";
    }
}

// set a timer when video starts, to display the time of a video has been taken
-(void)videotimer {
    NSLog(@"timer");
    sec = sec % 60;
    min = sec / 60;
    hour = min / 60;
    dispatch_async(dispatch_get_main_queue(), ^{
        _topLbl.text = [NSString stringWithFormat:@"%d:%d:%d",hour,min,sec];
    });
    sec ++;
    NSLog(@"%d",sec);
}

//button "X"
- (void)dismissBtnPressed:(id)sender {
    [self.picker dismissViewControllerAnimated:YES completion:^{
        [timer invalidate];
    }];
    
}

// flash light button functions
- (void)flashBtnPressed:(UIButton*)sender {
    [self switchFlashMode:sender];
}

- (void)switchFlashMode:(UIButton*)sender {
    
    NSString *imgStr = @"";
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    [device lockForConfiguration:nil];
    if ([device hasFlash]) {
        if (!sender) {
            device.flashMode = AVCaptureFlashModeAuto;
        } else {
            if (device.flashMode == AVCaptureFlashModeOff) {
                device.flashMode = AVCaptureFlashModeOn;
                imgStr = @"flashing_on.png";
                
            } else if (device.flashMode == AVCaptureFlashModeOn) {
                device.flashMode = AVCaptureFlashModeAuto;
                imgStr = @"flashing_auto.png";
                
            } else if (device.flashMode == AVCaptureFlashModeAuto) {
                device.flashMode = AVCaptureFlashModeOff;
                imgStr = @"flashing_off.png";
                
            }
        }
        
        if (sender) {
            [sender setImage:[UIImage imageNamed:imgStr] forState:UIControlStateNormal];
        }
        
    }
    [device unlockForConfiguration];
}


# pragma mark - camera overlay

- (UIView *) createCameraOverlay {
    
    // Button to take photo
    CGFloat cameraBtnLength = 90;
    
    self.cameraBtn =[self buildButton:CGRectMake((APP_SIZE.width - cameraBtnLength) / 2, (DEVICE_SIZE.height - CAMERA_MENU_VIEW_HEIGH - cameraBtnLength)  , cameraBtnLength, cameraBtnLength)
                         normalImgStr:@"shot.png"
                      highlightImgStr:@""
                       selectedImgStr:@""
                               action:@selector(takePictureBtnPressed:)
                           parentView:self.overlay];
    
    //sub view of list of buttons in camera view
    UIView *menuView = [[UIView alloc] initWithFrame:CGRectMake(0, DEVICE_SIZE.height - CAMERA_MENU_VIEW_HEIGH, self.view.frame.size.width, CAMERA_MENU_VIEW_HEIGH)];
    menuView.backgroundColor = [UIColor clearColor];
    
    [self.overlay addSubview:menuView];
    
    self.cameraMenuView = menuView;
    
    [self addTopViewWithText:@"Taking Photo"];
    
    [self addMenuViewButtons];
    
    return self.overlay;
}

//buttons on the bottom of camera view
- (void)addMenuViewButtons {
    
    NSMutableArray *normalArr = [[NSMutableArray alloc] initWithObjects:@"close_cha.png", @"camera_line.png", @"flashing_auto.png", nil];
    NSMutableArray *highlightArr = [[NSMutableArray alloc] initWithObjects:@"close_cha_h.png", @"", @"", @"", nil];
    NSMutableArray *selectedArr = [[NSMutableArray alloc] initWithObjects:@"", @"camera_line_h.png", @"", nil];
    
    NSMutableArray *actionArr = [[NSMutableArray alloc] initWithObjects:@"dismissBtnPressed:", @"VideoBtnPressed:", @"flashBtnPressed:", nil];
    
    CGFloat eachW = APP_SIZE.width / actionArr.count;
    
    [self drawALineWithFrame:CGRectMake(eachW, 0, 1, CAMERA_MENU_VIEW_HEIGH) andColor:[UIColor colorWithRed:102 green:102 blue:102 alpha:1.0000] inLayer:_cameraMenuView.layer];
    
    for (int i = 0; i < actionArr.count; i++) {
        
        UIButton * btn = [self buildButton:CGRectMake(eachW * i, 0, eachW, CAMERA_MENU_VIEW_HEIGH)
                              normalImgStr:[normalArr objectAtIndex:i]
                           highlightImgStr:[highlightArr objectAtIndex:i]
                            selectedImgStr:[selectedArr objectAtIndex:i]
                                    action:NSSelectorFromString([actionArr objectAtIndex:i])
                                parentView:_cameraMenuView];
        
        btn.showsTouchWhenHighlighted = YES;
        
        [_cameraBtnSet addObject:btn];
    }
}

- (void)drawALineWithFrame:(CGRect)frame andColor:(UIColor*)color inLayer:(CALayer*)parentLayer {
    CALayer *layer = [CALayer layer];
    layer.frame = frame;
    layer.backgroundColor = color.CGColor;
    [parentLayer addSublayer:layer];
}

- (void) takePhotoOrVideo {
    self.picker = [[UIImagePickerController alloc] init];
    self.overlay = [[UIView alloc] initWithFrame:self.scrollview.bounds];
    self.picker.delegate = self;
    self.picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.overlay = [self createCameraOverlay];
    self.picker.cameraOverlayView = self.overlay;
    self.picker.showsCameraControls = NO;
    takingPhoto = YES;
    
    [self presentViewController:self.picker animated:YES completion:nil];
}

- (void) photoLibrary {
    ELCImagePickerController *elcpicker = [[ELCImagePickerController alloc] initImagePicker];
    elcpicker.maximumImagesCount = 1000;
    elcpicker.returnsImage = YES;
    elcpicker.returnsOriginalImage = YES;
    elcpicker.onOrder = NO;
    elcpicker.mediaTypes =@[(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie];
    elcpicker.imagePickerDelegate = self;
    [self presentViewController:elcpicker animated:YES completion:nil];
}
- (IBAction)rightButtonPressed:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RightButtonPressed" object:nil];
}

# pragma mark - elcimage picker delegate

- (void) elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

    for (ALAsset *asset in info) {
        //ALAsset *asset = [dict objectForKey:@"asset"];
        id obj = [asset valueForProperty:ALAssetPropertyType];
        if (obj == ALAssetTypePhoto) {
            [self.saveFunction saveImageAssetIntoDocument:asset album:self.album];
            
        } else if (obj == ALAssetTypeVideo) {
            [self.saveFunction saveVideoAssetIntoDocument:asset album:self.album];
        }

    }
    });
}

- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

# pragma mark - image picker delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if (takingPhoto) {
            UIImage *image = info[UIImagePickerControllerOriginalImage];
            NSDictionary *metadata = info[UIImagePickerControllerMediaMetadata];
            
            // [self.tmpPhotos addObject:image];
            //[self.tmpMeta addObject:metadata];
            //NSLog(@"number of photo taken count %lu",(unsigned long)self.tmpPhotos.count);
            if (self.saveInAlbum) {
                NSLog(@"save photos into album");
                
                //[localLibrary saveImage:image metadata:metadata location:self.location];
            }else{
                NSLog(@"save photos into application folder");
                //[self saveImageIntoDocument:image metadata:metadata];
                [self.saveFunction saveImageIntoDocument:image metadata:metadata album:self.album];
            }
        } else {
            NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
            // Handle a movie capture
            if (CFStringCompare ((__bridge_retained CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
                NSURL *moviePath = [info objectForKey:UIImagePickerControllerMediaURL];
                // [self.videoUrl addObject:moviePath];
                //NSLog(@"number of video taken count %lu",(unsigned long)self.videoUrl.count);
                if (self.saveInAlbum) {
                    NSLog(@"save video into album");
                    //[localLibrary saveVideo:moviePath location:self.location];
                } else {
                    NSLog(@"save video into application folder");
                    [self.saveFunction saveVideoIntoDocument:moviePath album:self.album];
                    //[self saveVideoIntoDocument:moviePath];
                }
                
            }
            CFRelease((__bridge CFTypeRef)(mediaType));
        }
    });
    //totalAssets = (int)self.tmpPhotos.count +(int)self.videoUrl.count;
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
