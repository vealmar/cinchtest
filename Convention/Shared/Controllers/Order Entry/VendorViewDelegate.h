//
//  VendorViewDelegate.h
//  Convention
//
//  Created by Kerry Sanders on 1/13/13.
//  Copyright (c) 2013 MotionMobs. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol VendorViewDelegate <NSObject>

-(void)setVendor:(NSInteger) vendorId;
-(void)setBulletin:(NSInteger) bulletinId;
-(void)dismissVendorPopover;

@end
