//
//  QRReaderViewController.m
//  Go Arch
//
//  Created by Jake Runzer on 3/3/15.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "QRReaderViewController.h"

@interface QRReaderViewController ()

@end

@implementation QRReaderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
  
  [_lblStatus setText:@"Idle"];
  
  [self startReading];
  _reading = NO;
}

- (void) viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  
  [self stopReading];
}

- (void) startReading {
  AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
  
  NSError *error;
  AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
  
  if (!input) {
    NSLog(@"%@", [error localizedDescription]);
    return;
  }
  
  _captureSession = [[AVCaptureSession alloc] init];
  [_captureSession addInput:input];
  
  AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
  [_captureSession addOutput:captureMetadataOutput];
  
  dispatch_queue_t dispatchQueue;
  dispatchQueue = dispatch_queue_create("qrQueue", NULL);
  [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
  [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
  
  _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
  [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
  [_videoPreviewLayer setFrame:_viewPreview.layer.bounds];
  [_viewPreview.layer addSublayer:_videoPreviewLayer];
  
  [self addOverlay];
  
  [_captureSession startRunning];
    [self setStatus:@"Searching..."];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(failAuthQR) name:@"failAuthNotification" object:nil];
}

- (void) addOverlay {
  UIView *top = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _viewPreview.frame.size.width, _viewPreview.frame.size.height / 5)];
  [top setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.4]];
  [_viewPreview addSubview:top];
  
  UIView *bot = [[UIView alloc] initWithFrame:CGRectMake(0, _viewPreview.frame.size.height - (_viewPreview.frame.size.height / 5), _viewPreview.frame.size.width, _viewPreview.frame.size.height / 4)];
  [bot setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.4]];
  [_viewPreview addSubview:bot];
}

- (void) stopReading {
  [self setStatus:@"Idle"];
  [_captureSession stopRunning];
  _captureSession = nil;
  
  [_videoPreviewLayer removeFromSuperlayer];
}

// gets called when the qr auth failed
- (void) failAuthQR {
  NSLog(@"QR Authentication failed");
  [self setStatus:@"Searching..."];
  
  dispatch_async(dispatch_get_main_queue(), ^{
    CAKeyframeAnimation * anim = [ CAKeyframeAnimation animationWithKeyPath:@"transform" ] ;
    anim.values = @[ [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(-5.0f, 0.0f, 0.0f) ], [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(5.0f, 0.0f, 0.0f) ] ] ;
    anim.autoreverses = YES ;
    anim.repeatCount = 6.0f ;
    anim.duration = 0.12f ;
    
    [ _viewPreview.layer addAnimation:anim forKey:nil ] ;
    
    [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Invalid QR Code" description:@"The QR code scanned does not authenicate with any avaiable server" type:TWMessageBarMessageTypeError duration:2.0];
  });
  
  double delayInSeconds = 2.5;
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    _reading = NO;
  });
}

// called when not a valid qr code scanned
- (void) invalidQRCode {
  [self setStatus:@"Searhing..."];
  dispatch_async(dispatch_get_main_queue(), ^{
         [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Invalid QR Code" description:@"The scanned QR code does not belong to an Arch server" type:TWMessageBarMessageTypeError duration:2.0];
  });
  
  double delayInSeconds = 2.0;
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    _reading = NO;
  });
}

// returns YES if will start trying to auth (qr code has right properties)
- (BOOL) processData:(NSString *)jsonString {
  NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
  id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
  
  NSString *ip_internal = [json objectForKey:@"IP_INTERNAL"];
  NSString *ip_external = [json objectForKey:@"IP_EXTERNAL"];
  NSString *cid = [json objectForKey:@"cid"];
  NSString *hash_token = [json objectForKey:@"hash_token"];
  
  NSLog(@"%@ - %@ - %@ - %@", ip_internal, ip_external, cid, hash_token);
  
  if (!ip_internal || !cid || !hash_token || !ip_external) {
    return NO;
  }
  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"scanQRNotification" object:nil userInfo:json];
  return YES;
}

- (void) setStatus:(NSString *)status {
  dispatch_async(dispatch_get_main_queue(), ^{
    [_lblStatus setText:status];
  });
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
  if (metadataObjects != nil && [metadataObjects count] > 0) {
    AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
    if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode] && !_reading) {
      NSLog(@"read qr data");
      [self setStatus:@"Reading..."];
      _reading = [self processData:[metadataObj stringValue]];
      
      if (!_reading) {
        _reading = YES;
        [self invalidQRCode];
      }
    }
  }
}

@end
