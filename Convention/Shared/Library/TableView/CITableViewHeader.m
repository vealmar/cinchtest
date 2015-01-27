//
// Created by David Jafari on 12/20/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Underscore.m/Underscore.h>
#import "CITableViewHeader.h"
#import "CITableViewColumns.h"
#import "CITableViewColumn.h"
#import "ThemeUtil.h"

@interface CITableViewHeader()

@property NSMutableArray *cellViews;
@property CITableViewColumns *columns;

@end

@implementation CITableViewHeader

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.cellViews = [NSMutableArray array];
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

-(void)setupCellViews {
    Underscore.array(self.cellViews).each(^(UILabel *columnView) {
        [columnView removeFromSuperview];
    });
    [self.cellViews removeAllObjects];

    NSArray *frames = [self.columns createFramesForWidth:self.frame.size.width height:self.frame.size.height];

    [self.columns each:(^(CITableViewColumn *column, NSUInteger index) {
        CGRect frame = [((NSValue *) frames[index]) CGRectValue];
        UILabel *columnLabel = [[UILabel alloc] initWithFrame:frame];
        NSDictionary *defaultAttributes = @{
                NSFontAttributeName: [UIFont semiboldFontOfSize:14],
                NSForegroundColorAttributeName: [ThemeUtil blackColor]
        };
        NSDictionary *optionAttributes = column.options[ColumnOptionTitleTextAttributes];
        if (optionAttributes) defaultAttributes = Underscore.dict(defaultAttributes).extend(optionAttributes).unwrap;

        columnLabel.attributedText = [[NSAttributedString alloc] initWithString:column.title attributes:defaultAttributes];
        columnLabel.textAlignment = column.alignment;

        [self.cellViews addObject:columnLabel];
        [self addSubview:columnLabel];
    })];
}

@end