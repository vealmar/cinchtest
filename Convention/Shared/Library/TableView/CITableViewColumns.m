//
// Created by David Jafari on 12/20/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Underscore.m/Underscore.h>
#import "CITableViewColumns.h"
#import "CITableViewColumn.h"

@interface CITableViewColumns()

@property NSMutableArray *mutableColumns;
@property NSNumber *instanceId; // simpler equality checks, dict keys

@property int lastWidthCalculationAllowedWidth;
@property NSDictionary *lastWidthCalculation;

@end

@implementation CITableViewColumns

static int instanceIdCounter = 1;

-(id)init {
    self = [super init];
    if (self) {
        self.mutableColumns = [NSMutableArray array];
        self.instanceId = [NSNumber numberWithInt:instanceIdCounter++];
    }
    return self;
}

-(void)each:(void (^)(CITableViewColumn *column, NSUInteger index))block {
    Underscore.array(self.mutableColumns).each(^(CITableViewColumn *column) {
        block(column, [self.mutableColumns indexOfObject:column]);
    });
}

-(CITableViewColumns *)add:(ColumnType)columnType titled:(NSString *)title forKey:(NSString *)rowDataKey {
    return [self add:columnType titled:title using:@{
            ColumnOptionContentKey: rowDataKey
    }];
}

-(CITableViewColumns *)add:(ColumnType)columnType titled:(NSString *)title using:(NSDictionary *)options {
    CITableViewColumn *column = [CITableViewColumn new];
    column.title = title;
    column.columnType = columnType;
    column.options = Underscore.extend(self.defaultOptions, options);

    [self.mutableColumns addObject:column];

    return self;
}

-(NSArray *)createPaddedFramesForWidth:(int)allowedWidth height:(int)frameHeight {
    NSMutableArray *frames = [NSMutableArray array];
    NSDictionary *widthsByColumn = [self calculateColumnWidths:allowedWidth];

    __block int currentXPosition = 0;
    [self each:(^(CITableViewColumn *column, NSUInteger index) {
        int width = [((NSNumber *) widthsByColumn[column.instanceId]) intValue];
        int horizontalPadding = [((NSNumber *) [column.options objectForKey:ColumnOptionHorizontalPadding]) intValue];
        if (0 == currentXPosition) {
            int horizontalInset = [((NSNumber *) [column.options objectForKey:ColumnOptionHorizontalInset]) intValue];
            currentXPosition += horizontalInset;
        }

        CGRect frame = CGRectMake(currentXPosition + horizontalPadding, 0, width - (2 * horizontalPadding), frameHeight);
        [frames addObject:[NSValue valueWithCGRect:frame]];
        currentXPosition += width + 2 * horizontalPadding;
    })];

    return [NSArray arrayWithArray:frames];
}


-(NSArray *)createFramesForWidth:(int)allowedWidth height:(int)frameHeight {
    NSMutableArray *frames = [NSMutableArray array];
    NSDictionary *widthsByColumn = [self calculateColumnWidths:allowedWidth];

    __block int currentXPosition = 0;
    [self each:(^(CITableViewColumn *column, NSUInteger index) {
        int width = [((NSNumber *) widthsByColumn[column.instanceId]) intValue];
        int horizontalPadding = [((NSNumber *) [column.options objectForKey:ColumnOptionHorizontalPadding]) intValue];
        if (0 == currentXPosition) {
            int horizontalInset = [((NSNumber *) [column.options objectForKey:ColumnOptionHorizontalInset]) intValue];
            currentXPosition += horizontalInset;
        }

        CGRect frame = CGRectMake(currentXPosition, 0, width, frameHeight);
        [frames addObject:[NSValue valueWithCGRect:frame]];
        currentXPosition += width + 2 * horizontalPadding;
    })];

    return [NSArray arrayWithArray:frames];
}

/**
* @return A mapping of columns to their widths
*/
-(NSDictionary *)calculateColumnWidths:(int)allowedWidth {
    // memoize value, this could be called a ton
    if (self.lastWidthCalculation && allowedWidth == self.lastWidthCalculationAllowedWidth) {
        return self.lastWidthCalculation;
    } else {
        self.lastWidthCalculationAllowedWidth = allowedWidth;
    }
    
    USArrayWrapper *iterable = Underscore.array(self.mutableColumns);

    __block int totalWidth = 0;
    __block int columnsWithDefinedWidth = 0;
    iterable.each(^(CITableViewColumn *column) {
        id desiredWidth = [column.options objectForKey:ColumnOptionDesiredWidth];
        id horizontalPadding = [column.options objectForKey:ColumnOptionHorizontalPadding];
        id horizontalInset = [column.options objectForKey:ColumnOptionHorizontalInset];

        if (horizontalPadding) totalWidth += 2 * [((NSNumber *) horizontalPadding) intValue];
        if (horizontalInset && (column == self.mutableColumns.firstObject || column == self.mutableColumns.lastObject)) {
            totalWidth += [((NSNumber *) horizontalInset) intValue];
        }

        if (desiredWidth) {
            columnsWithDefinedWidth += 1;
            totalWidth += [((NSNumber *) desiredWidth) intValue];
        }
    });

    int undefinedColumnWidth = 0;
    if (0 != self.mutableColumns.count - columnsWithDefinedWidth) {
        undefinedColumnWidth = (allowedWidth - totalWidth) / (self.mutableColumns.count - columnsWithDefinedWidth);
    }

    __block NSMutableDictionary *mapping = [NSMutableDictionary dictionary];
    iterable.each(^(CITableViewColumn *column) {
        id desiredWidth = [column.options objectForKey:ColumnOptionDesiredWidth];
        if (desiredWidth) {
            mapping[column.instanceId] = desiredWidth;
        } else {
            mapping[column.instanceId] = [NSNumber numberWithInt:undefinedColumnWidth];
        }
    });

    self.lastWidthCalculation = [NSDictionary dictionaryWithDictionary:mapping];
    return self.lastWidthCalculation;
}

static NSDictionary *_defaultOptions = nil;

-(NSDictionary *)defaultOptions {
    if (nil == _defaultOptions) {
        static dispatch_once_t createDefaultOptions;
        dispatch_once(&createDefaultOptions, ^{
            _defaultOptions = @{
                    ColumnOptionTextAlignment: [NSNumber numberWithInt:NSTextAlignmentLeft],
                    ColumnOptionHorizontalPadding: [NSNumber numberWithInt:5],
                    ColumnOptionHorizontalInset: [NSNumber numberWithInt:15]
            };
        });
    }
    return _defaultOptions;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self.instanceId isEqualToNumber:((CITableViewColumns *) other).instanceId];
}


@end