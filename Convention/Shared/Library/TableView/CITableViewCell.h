//
// Created by David Jafari on 12/20/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MGSwipeTableCell.h"

@class CITableViewColumns;
@class CITableViewColumn;
@class CITableViewColumnView;

@interface CITableViewCell : MGSwipeTableCell

@property id rowData;

-(id)prepareForDisplay:(CITableViewColumns *)columns;
-(id)render:(id)rowData;


// intended for override
-(void)renderColumn:(CITableViewColumnView *)columnView rowData:(id)rowData;
-(CITableViewColumnView *)viewForColumn:(CITableViewColumn *)column frame:(CGRect)frame;
- (void)updateRowHighlight:(NSIndexPath *)indexPath;

@end

@interface CITableViewCell (Private)

@property NSMutableArray *cellViews;

@end