//
// Created by David Jafari on 12/20/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CITableViewColumn;

typedef NS_ENUM(NSInteger, ColumnType) {
    ColumnTypeString,
    ColumnTypeCurrency,
    ColumnTypeInt,
    ColumnTypeCustom
};

@interface CITableViewColumns : NSObject

-(void)each:(void (^)(CITableViewColumn *column, NSUInteger index))block;
-(CITableViewColumns *)add:(ColumnType)columnType titled:(NSString *)title forKey:(NSString *)rowDataKey;
-(CITableViewColumns *)add:(ColumnType)columnType titled:(NSString *)title using:(NSDictionary *)options;
-(NSArray *)createPaddedFramesForWidth:(int)allowedWidth height:(int)frameHeight;
-(NSArray *)createFramesForWidth:(int)allowedWidth height:(int)frameHeight;
-(NSDictionary *)calculateColumnWidths:(int)allowedWidth;

@end