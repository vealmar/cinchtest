//
// Created by David Jafari on 5/31/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "ProductSearch.h"
#import "StringManipulation.h"

@interface ProductSearch () {
    NSManagedObjectContext *context;
}

@property NSPersistentStoreCoordinator *coordinator;

@end

@implementation ProductSearch

+ (ProductSearch *)searchFor:(NSString *)query inBulletin:(NSInteger)bulletin forVendor:(NSInteger)vendor sortedBy:(NSArray *)sortDescriptors limitResultSize:(NSInteger)limit usingContext:(NSManagedObjectContext *)context {
    ProductSearch *search = [[ProductSearch alloc] init];
    if (query) {
        search.queryString = [query stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    } else {
        search.queryString = @"";
    }
    search.currentBulletin = bulletin;
    search.currentVendor = vendor;
    search.limit = limit;
    search.coordinator = context.persistentStoreCoordinator;
    if (sortDescriptors && sortDescriptors.count > 0) {
        search.sortDescriptors = sortDescriptors;
    } else {
        search.sortDescriptors = @[
                [NSSortDescriptor sortDescriptorWithKey:@"sequence" ascending:YES],
                [NSSortDescriptor sortDescriptorWithKey:@"invtid" ascending:YES]
        ];
    }

    return search;
}

- (NSManagedObjectContext *)context {
    if (!context) {
        context = [[NSManagedObjectContext alloc] init];
        [context setPersistentStoreCoordinator:self.coordinator];
    }

    return context;
}

- (NSArray *)split:(NSString *)separator {
    if (![self.queryString contains:@","]) {
        return [NSArray arrayWithObject:self];
    }

    NSMutableArray *searches = [NSMutableArray array];
    [[self.queryString componentsSeparatedByString:separator] enumerateObjectsUsingBlock:^(NSString *query, NSUInteger idx, BOOL *stop) {
        if ([query stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length > 0) {
            [searches addObject:[ProductSearch searchFor:query inBulletin:self.currentBulletin forVendor:self.currentVendor sortedBy:nil limitResultSize:self.limit usingContext:self.context]];
        }
    }];
    return searches;
}


@end