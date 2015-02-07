//
// Created by David Jafari on 1/29/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CITableViewColumn;

typedef NS_ENUM(NSInteger, CITableViewSortDirection) {
    CITableViewSortDirectionNone,
    CITableViewSortDirectionAscending,
    CITableViewSortDirectionDescending
};

@interface CITableViewHeaderColumnView : UIView

@property CITableViewColumn *column;
@property CITableViewSortDirection sortDirection;
@property (readonly) NSSortDescriptor *sortDescriptor;

-(id)initColumn:(CITableViewColumn *)column frame:(CGRect)frame paddedFrame:(CGRect)paddedFrame;
- (void)resetSort;
- (void)transitionSort;

@end