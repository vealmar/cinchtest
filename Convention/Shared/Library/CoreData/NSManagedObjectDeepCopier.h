//
// Created by David Jafari on 2/21/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSManagedObjectDeepCopier : NSObject

+ (NSManagedObject *)copyEntity:(NSManagedObject *)object;

+ (NSManagedObject *)copyEntity:(NSManagedObject *)object
         excludingRelationships:(NSArray *)relationshipsTraversed
                      toContext:(NSManagedObjectContext *)context;

@end