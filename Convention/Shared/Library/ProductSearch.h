//
// Created by David Jafari on 5/31/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ProductSearch : NSObject

@property NSString *queryString;
@property NSInteger currentBulletin;
@property NSInteger currentVendor;
@property NSInteger limit;
@property NSArray *sortDescriptors;

+ (ProductSearch *)searchFor:(NSString *)query inBulletin:(NSInteger)bulletin forVendor:(NSInteger)vendor sortedBy:(NSArray *)sortDescriptors limitResultSize:(NSInteger)limit usingContext:(NSManagedObjectContext *)context;
- (NSArray *) split:(NSString *)separator;
- (NSManagedObjectContext *)context;

@end
