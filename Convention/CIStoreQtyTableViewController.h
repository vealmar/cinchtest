//
//  CIStoreQtyTableViewController.h
//  Convention
//
//  Created by Matthew Clark on 8/16/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CIStoreQtyCell.h"

@protocol CIStoreQtyTableDelegate <NSObject>
@required
-(void)QtyTableChange:(NSMutableDictionary*)qty forIndex:(int)idx;
@end

@interface CIStoreQtyTableViewController : UITableViewController <CIStoreQtyDelegate>
@property (strong, nonatomic) NSMutableDictionary* stores;
@property (nonatomic, assign) id<CIStoreQtyTableDelegate> delegate;
@property (nonatomic) int tag;
@property (nonatomic) BOOL editable;

@end
