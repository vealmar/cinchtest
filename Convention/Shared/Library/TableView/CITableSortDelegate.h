//
// Created by David Jafari on 1/29/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CITableViewHeaderColumnView.h"

@protocol CITableSortDelegate <NSObject>

@optional

- (void)sortSelected:(NSArray *)sortDescriptors;

@end