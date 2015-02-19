//
// Created by David Jafari on 12/31/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "CITagColumnView.h"
#import "LineItem.h"
#import "Product.h"
#import "ThemeUtil.h"
#import "CITableViewColumn.h"
#import "LayoutUtil.h"
#import "CITagsView.h"

@interface CITagColumnView ()

@property CITagsView *tagsView;

@end

@implementation CITagColumnView


- (id)initColumn:(CITableViewColumn *)column frame:(CGRect)frame {
    self = [super initColumn:column frame:frame];
    if (self) {
        self.tagsView = [[CITagsView alloc] initWithFrame:frame];
    }

    return self;
}

- (void)render:(id)rowData {
    [super render:rowData];

    // add new tags
    NSArray *values = [self.column valuesFor:rowData];
    NSString *tagString = values.count > 0 ? values[0] : nil;

    [self.tagsView prepareForDisplay:tagString];
}

-(void)unhighlight {
    for (UIView *view in self.tagsView.tagViews) {
        view.backgroundColor = [ThemeUtil darkBlueColor];
        view.layer.borderColor = [UIColor clearColor].CGColor;
    }
}

-(void)highlight:(NSDictionary *)attributes {
    for (UIView *view in self.tagsView.tagViews) {
        view.backgroundColor = [UIColor clearColor];
        view.layer.borderColor = [UIColor whiteColor].CGColor;
    }
}

@end