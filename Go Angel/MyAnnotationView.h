//
//  MyAnnotationView.h
//  Go Arch
//
//  Created by zcheng on 2015-03-26.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import <MapKit/MapKit.h>


@protocol MyAnnotationViewDelegate;
@interface MyAnnotationView : MKAnnotationView

@property (nonatomic,retain)UIView *contentView;


- (id)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier delegate:(id<MyAnnotationViewDelegate>)delegate;


@end

@protocol MyAnnotationViewDelegate <NSObject>

- (void)didSelectAnnotationView:(MyAnnotationView *)view;

@end
