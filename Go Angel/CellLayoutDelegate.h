//
//  CellLayoutDelegate.h
//  
//
//  Created by zcheng on 2015-02-04.
//
//

#import <Foundation/Foundation.h>

@protocol  CellLayoutDelegate <NSObject>

-(float)collectionView:(UICollectionView *)collectionView relativeHeightForItemAtIndexPath:(NSIndexPath *)indexPath;

//  Returns if the cell at a particular index path can be shown as "double column"

-(BOOL)collectionView:(UICollectionView *)collectionView isDoubleColumnAtIndexPath:(NSIndexPath *)indexPath;

//  Returns the amount of columns that have to display at that moment
-(NSUInteger)numberOfColumnsInCollectionView:(UICollectionView *)collectionView;

@end
