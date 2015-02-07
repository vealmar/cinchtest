//
// Created by David Jafari on 1/29/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import <Underscore.m/Underscore.h>
#import "CITableViewHeaderColumnView.h"
#import "CITableViewColumn.h"
#import "ThemeUtil.h"

@interface CITableViewHeaderColumnView()

@property UILabel *titleLabel;

@end

@implementation CITableViewHeaderColumnView

- (id)initColumn:(CITableViewColumn *)column frame:(CGRect)frame paddedFrame:(CGRect)paddedFrame {
    self = [super initWithFrame:frame];
    if (self) {
        self.sortDirection = CITableViewSortDirectionNone;
        self.column = column;
        self.titleLabel = [self newTitleLabel:column frame:CGRectMake(paddedFrame.origin.x - frame.origin.x, paddedFrame.origin.y - frame.origin.y, paddedFrame.size.width, paddedFrame.size.height)];
        [self addSubview:self.titleLabel];
    }
    return self;
}

- (BOOL)sortable {
    return nil != self.column.options[ColumnOptionContentKey] && [self.column.options[ColumnOptionSortableKey] boolValue];
}

- (NSSortDescriptor *)sortDescriptor {
    if ([self sortable] && CITableViewSortDirectionNone != self.sortDirection) {
        return [NSSortDescriptor sortDescriptorWithKey:self.column.options[ColumnOptionContentKey] ascending:CITableViewSortDirectionAscending == self.sortDirection];
    } else {
        return nil;
    }
}

- (void)resetSort {
    self.sortDirection = CITableViewSortDirectionNone;
    [self applySortStyle];
}

- (void)transitionSort {
    if (self.sortable) {
        if (CITableViewSortDirectionNone == self.sortDirection) {
            self.sortDirection = CITableViewSortDirectionAscending;
        } else if (CITableViewSortDirectionAscending == self.sortDirection) {
            self.sortDirection = CITableViewSortDirectionDescending;
        } else {
            self.sortDirection = CITableViewSortDirectionNone;
        }
        [self applySortStyle];
    }
}

- (void)applySortStyle {
    NSDictionary *labelAttributes = [self buildLabelAttributes:self.column];
    NSMutableAttributedString *columnTitle = [[NSMutableAttributedString alloc] init];

    if (CITableViewSortDirectionNone == self.sortDirection) {
        [columnTitle appendAttributedString:[[NSAttributedString alloc] initWithString:self.column.title attributes:labelAttributes]];
        self.backgroundColor = [UIColor clearColor];
    } else {
        // make font bold
        NSMutableDictionary *boldLabelAttributes = [NSMutableDictionary dictionaryWithDictionary:labelAttributes];
        boldLabelAttributes[NSFontAttributeName] = [UIFont boldFontOfSize:((UIFont *) labelAttributes[NSFontAttributeName]).pointSize];
        boldLabelAttributes[NSForegroundColorAttributeName] = [UIColor whiteColor];
        labelAttributes = [NSDictionary dictionaryWithDictionary:boldLabelAttributes];

        // add arrow
        NSMutableDictionary *arrowLabelAttributes = [NSMutableDictionary dictionaryWithDictionary:boldLabelAttributes];
        arrowLabelAttributes[NSFontAttributeName] = [UIFont iconFontOfSize:((UIFont *) labelAttributes[NSFontAttributeName]).pointSize];
        NSString *pointer = CITableViewSortDirectionDescending == self.sortDirection ? @"\uf0d8 " : @"\uf0d7 ";

        [columnTitle appendAttributedString:[[NSAttributedString alloc] initWithString:pointer attributes:arrowLabelAttributes]];
        [columnTitle appendAttributedString:[[NSAttributedString alloc] initWithString:self.column.title attributes:labelAttributes]];

        self.backgroundColor = [ThemeUtil blueHighlightColor];
    }

    self.titleLabel.attributedText = [[NSAttributedString alloc] initWithAttributedString:columnTitle];
    [self.titleLabel setNeedsDisplay];
}

- (UILabel *)newTitleLabel:(CITableViewColumn *)column frame:(CGRect)frame {
    UILabel *columnLabel = [[UILabel alloc] initWithFrame:frame];
    NSDictionary *labelAttributes = [self buildLabelAttributes:column];

    columnLabel.attributedText = [[NSAttributedString alloc] initWithString:column.title attributes:labelAttributes];
    columnLabel.textAlignment = column.alignment;
    columnLabel.backgroundColor = [UIColor clearColor];

    return columnLabel;
}

- (NSDictionary *)buildLabelAttributes:(CITableViewColumn *)column {
    NSDictionary *defaultAttributes = @{
                NSFontAttributeName: [UIFont semiboldFontOfSize:14],
                NSForegroundColorAttributeName: [ThemeUtil blackColor]
        };
    NSDictionary *optionAttributes = column.options[ColumnOptionTitleTextAttributes];
    if (optionAttributes) defaultAttributes = Underscore.dict(defaultAttributes).extend(optionAttributes).unwrap;
    return defaultAttributes;
}


@end