//
// Created by David Jafari on 12/25/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CoreDataBackgroundOperation : NSObject

+ (void)performBatchInBackgroundWithContext:(void(^)(NSManagedObjectContext *context))asyncBlock
                                 completion:(void(^)(void))completion;

+ (void)performInBackgroundWithContext:(void(^)(NSManagedObjectContext *context))asyncBlock
                            completion:(void(^)(void))completion;

@end