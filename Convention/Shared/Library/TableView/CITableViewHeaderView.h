//
// Created by David Jafari on 12/20/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CITableViewColumns;
@protocol CITableSortDelegate;

@interface CITableViewHeaderView : UIView

@property (weak) id<CITableSortDelegate> sortDelegate;

-(id)prepareForDisplay:(CITableViewColumns *)columns;
- (NSArray *)currentSortDescriptors;

@end