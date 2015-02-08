//
// Created by David Jafari on 12/20/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "CITableViewStandardColumnView.h"
#import "CITableViewColumn.h"
#import "UIView+Boost.h"
#import "ThemeUtil.h"
#import "NumberUtil.h"

@interface CITableViewStandardColumnView()

@property UILabel *primaryTextView;
@property UILabel *secondaryTextView;

@end

@implementation CITableViewStandardColumnView

- (id)initColumn:(CITableViewColumn *)column frame:(CGRect)frame {
    self = [super initColumn:column frame:frame];
    if (self) {
        self.primaryTextView = [[UILabel alloc] init];
        if (column.options[ColumnOptionLineBreakMode]) {
            self.primaryTextView.lineBreakMode = (NSLineBreakMode) [column.options[ColumnOptionLineBreakMode] intValue];
        } else {
            self.primaryTextView.adjustsFontSizeToFitWidth = YES;
        }
        [self addSubview:self.primaryTextView];

        self.secondaryTextView = [[UILabel alloc] init];
        if (column.options[ColumnOptionLineBreakMode]) {
            self.secondaryTextView.lineBreakMode = (NSLineBreakMode) [column.options[ColumnOptionLineBreakMode] intValue];
        } else {
            self.secondaryTextView.adjustsFontSizeToFitWidth = YES;
        }
        [self addSubview:self.secondaryTextView];

        [self unhighlight];
    }
    return self;
}

- (void)render:(id)rowData {
    [super render:rowData];
    NSArray *values = [self.column valuesFor:rowData];
    switch (values.count) {
        case 1:
            [self useOneTextView];
            self.primaryTextView.text = [self formatForDisplay:values.firstObject];
            break;
        case 2:
            [self useTwoTextViews];
            self.primaryTextView.text = [self formatForDisplay:values.firstObject];
            self.secondaryTextView.text = [self formatForDisplay:values.lastObject];
            break;
        default:
            [self useNoTextViews];
    }
}

-(void)unhighlight {
    self.primaryTextView.font = [UIFont regularFontOfSize:14.0];
    self.primaryTextView.textColor = [ThemeUtil blackColor];
    self.primaryTextView.textAlignment = self.column.alignment;

    self.secondaryTextView.font = [UIFont regularFontOfSize:14.0];
    self.secondaryTextView.textColor = [ThemeUtil blackColor];
    self.secondaryTextView.textAlignment = self.column.alignment;
}

-(void)highlight:(NSDictionary *)attributes {
    UIFont *font = (UIFont *) [attributes objectForKey:NSFontAttributeName];
    if (font) {
        self.primaryTextView.font = font;
        self.secondaryTextView.font = font;
    }
    UIColor *color = (UIColor *) [attributes objectForKey:NSForegroundColorAttributeName];
    if (color) {
        self.primaryTextView.textColor = color;
        self.secondaryTextView.textColor = color;
    }
}

-(void)useOneTextView {
    self.primaryTextView.visible = YES;
    self.secondaryTextView.visible = NO;
    self.primaryTextView.frame = CGRectMake(0.0, 0.0, self.frame.size.width, self.frame.size.height);
}

-(void)useTwoTextViews {
    self.primaryTextView.visible = YES;
    self.secondaryTextView.visible = YES;
    self.primaryTextView.frame = CGRectMake(0.0, 1.0, self.frame.size.width, (self.frame.size.height / 2) - 1.0);
    self.secondaryTextView.frame = CGRectMake(0.0, 22.0, self.frame.size.width, (self.frame.size.height / 2) - 2.0);
}

-(void)useNoTextViews {
    self.primaryTextView.visible = NO;
    self.secondaryTextView.visible = NO;
}

-(NSString *)formatForDisplay:(id)data {
    if (ColumnTypeInt == self.column.columnType) {
        return [NSString stringWithFormat:@"%@", data];
    } else if (ColumnTypeCurrency == self.column.columnType) {
        if ([data isKindOfClass:[NSNumber class]]) {
            return [NSString stringWithFormat:@"%@", [NumberUtil formatDollarAmount:(NSNumber*)data]];
        }
    } else if ([data isKindOfClass:[NSString class]]) {
        return data;
    }
    return @"";
}


@end