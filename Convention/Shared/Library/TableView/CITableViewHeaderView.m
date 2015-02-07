//
// Created by David Jafari on 12/20/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Underscore.m/Underscore.h>
#import "CITableViewHeaderView.h"
#import "CITableViewColumns.h"
#import "CITableViewColumn.h"
#import "CITableSortDelegate.h"
#import "ThemeUtil.h"
#import "CITableViewHeaderColumnView.h"

@interface CITableViewHeaderView ()

@property NSMutableArray *cellViews;
@property CITableViewColumns *columns;

@end

@implementation CITableViewHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.cellViews = [NSMutableArray array];
    }

    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.cellViews = [NSMutableArray array];
}

-(id)prepareForDisplay:(CITableViewColumns *)columns {
    if (!self.columns || ![self.columns isEqual:columns]) {
        self.columns = columns;
        [self setupCellViews];
    }

    return self;
}

- (NSArray *)currentSortDescriptors {
    NSMutableArray *sorts = [NSMutableArray array];
    Underscore.array(self.cellViews).each(^(CITableViewHeaderColumnView *headerColumn) {
        NSSortDescriptor *descriptor = [headerColumn sortDescriptor];
        if (descriptor) [sorts addObject:descriptor];
    });

    return [NSArray arrayWithArray:sorts];
}


-(void)setupCellViews {
    Underscore.array(self.cellViews).each(^(UILabel *columnView) {
        [columnView removeFromSuperview];
    });
    [self.cellViews removeAllObjects];

    NSArray *paddedFrames = [self.columns createPaddedFramesForWidth:self.frame.size.width height:self.frame.size.height];
    NSArray *frames = [self.columns createFramesForWidth:self.frame.size.width height:self.frame.size.height];

    __weak CITableViewHeaderView *weakSelf = self;
    [self.columns each:(^(CITableViewColumn *column, NSUInteger index) {
        CGRect paddedFrame = [((NSValue *) paddedFrames[index]) CGRectValue];
        CGRect frame = [((NSValue *) frames[index]) CGRectValue];

        CITableViewHeaderColumnView *headerView = [[CITableViewHeaderColumnView alloc] initColumn:column frame:frame paddedFrame:paddedFrame];

        [headerView bk_whenTapped:^{
            [weakSelf sortTransition:headerView];
        }];

        [self.cellViews addObject:headerView];
        [self addSubview:headerView];
    })];
}

- (void)sortTransition:(CITableViewHeaderColumnView *)selectedColumn {
    Underscore.array(self.cellViews).each(^(CITableViewHeaderColumnView *headerColumn) {
        if ([headerColumn isEqual:selectedColumn]) {
            [headerColumn transitionSort];
        } else {
            [headerColumn resetSort];
        }
    });
    if (self.sortDelegate && [self.sortDelegate respondsToSelector:@selector(sortSelected:)]) {
        [self.sortDelegate sortSelected:[self currentSortDescriptors]];
    }
}

@end