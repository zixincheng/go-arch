//
//  CellLayout.h
//  Go Arch
//
//  Created by zcheng on 2015-02-04.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CellLayoutDelegate.h"
@interface CellLayout : UICollectionViewLayout {
    
    NSMutableArray *_columns;
    NSMutableArray *_itemsAttributes;
}

@property (weak) id <CellLayoutDelegate> delegate;
@property (readonly) NSUInteger columnsQuantity;

-(float)columnWidth;

@end
