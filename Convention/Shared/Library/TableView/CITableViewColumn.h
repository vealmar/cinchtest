//
// Created by David Jafari on 12/20/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CITableViewColumns.h"

extern NSString *const ColumnOptionCustomTypeClass;     // Class*
extern NSString *const ColumnOptionTextAlignment;       // NSNumber* with NSTextAlignment
extern NSString *const ColumnOptionLineBreakMode;       // NSNumber* with NSLineBreakMode
extern NSString *const ColumnOptionContentKey;          // NSString*
extern NSString *const ColumnOptionContentKey2;         // NSString*
extern NSString *const ColumnOptionDesiredWidth;        // NSNumber* (int)
extern NSString *const ColumnOptionHorizontalPadding;   // NSNumber* (int)
extern NSString *const ColumnOptionHorizontalInset;     // NSNumber* (int)
extern NSString *const ColumnOptionTitleTextAttributes;
extern NSString *const ColumnOptionSortableKey;         // NSNumber* (bool)

@interface CITableViewColumn : NSObject <NSCopying>

@property (readonly) NSNumber *instanceId; // simpler equality checks, dict keys
@property ColumnType columnType;
@property NSString *title;
@property NSDictionary *options;

@property (readonly) NSTextAlignment alignment;

-(NSArray *)valuesFor:(id)rowData;

@end