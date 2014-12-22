//
// Created by David Jafari on 12/20/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Underscore.m/Underscore.h>
#import "CITableViewCell.h"
#import "CITableViewColumns.h"
#import "CITableViewColumnView.h"
#import "CITableViewColumn.h"
#import "CITableViewStandardColumnView.h"
#import "ThemeUtil.h"

@interface CITableViewCell()

@property CITableViewColumns *columns;
@property NSMutableArray *cellViews;

@end

@implementation CITableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.cellViews = [NSMutableArray array];
        self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.frame];
        self.selectedBackgroundView.backgroundColor = [ThemeUtil darkBlueColor];
    }

    return self;
}

-(id)prepareForDisplay:(CITableViewColumns *)columns {
    if (!self.columns || ![self.columns isEqual:columns]) {
        self.columns = columns;
        [self setupCellViews];
    }
    return self;
}

-(id)render:(id)rowData {
    Underscore.array(self.cellViews).each(^(CITableViewColumnView *columnView) {
       [self renderColumn:columnView rowData:rowData];
    });
    self.rowData = rowData;
    return self;
}

- (void)renderColumn:(CITableViewColumnView *)columnView rowData:(id)rowData {
    [columnView render:rowData];
}

-(void)setupCellViews {
    Underscore.array(self.cellViews).each(^(CITableViewColumnView *columnView) {
        [columnView removeFromSuperview];
    });
    [self.cellViews removeAllObjects];

    NSArray *frames = [self.columns createFramesForWidth:self.frame.size.width height:self.frame.size.height];
    [self.columns each:(^(CITableViewColumn *column, NSUInteger index) {
        CGRect frame = [((NSValue *) frames[index]) CGRectValue];
        CITableViewColumnView *columnView = [self viewForColumn:column frame:frame];
        [self.cellViews addObject:columnView];
        [self.contentView addSubview:columnView];
    })];
}

-(CITableViewColumnView *)viewForColumn:(CITableViewColumn *)column frame:(CGRect)frame {
    id clazz = [column.options objectForKey:ColumnOptionCustomTypeClass];
    if (ColumnTypeCurrency == column.columnType || ColumnTypeString == column.columnType || ColumnTypeInt == column.columnType) {
        return [[CITableViewStandardColumnView alloc] initColumn:column frame:frame];
    } else if (clazz) {
        //todo create new instance with clazz
//        [[CIQuantityColumnView alloc] initColumn:column frame:frame]
    } else {
        assert(false);
    }
    return nil;
}

- (void)updateRowHighlight:(NSIndexPath *)indexPath {

}

@end