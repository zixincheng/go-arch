//
//  StorageTableViewCell.h
//  Go Arch
//
//  Created by zcheng on 2014-11-27.
//  Copyright (c) 2014 acdGO Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StorageTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *StorageName;
@property (weak, nonatomic) IBOutlet UILabel *StorageStat;
@property (weak, nonatomic) IBOutlet UILabel *StoragePrimary;
@property (weak, nonatomic) IBOutlet UILabel *StorageBackup;

@end
