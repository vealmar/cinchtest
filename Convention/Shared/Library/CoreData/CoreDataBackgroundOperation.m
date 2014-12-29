//
// Created by David Jafari on 12/25/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "CoreDataBackgroundOperation.h"
#import "CurrentSession.h"

@implementation CoreDataBackgroundOperation

static dispatch_queue_t _coredata_background_save_queue;

dispatch_queue_t coredata_background_save_queue() {
    if (NULL == _coredata_background_save_queue) {
        _coredata_background_save_queue = dispatch_queue_create("com.urbancoding.cinch.coredata.backgroundsaves", 0);
    }
    return _coredata_background_save_queue;
}

+ (void)performInBackgroundWithContext:(void(^)(NSManagedObjectContext *context))asyncBlock
                            completion:(void(^)(void))completion {

    dispatch_async(coredata_background_save_queue(), ^{
        [self saveDataInContext:asyncBlock];

        if (completion) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                completion();
            });
        }
    });
}

+ (void)saveDataInContext:(void(^)(NSManagedObjectContext *context))saveBlock {
    // get default context, this is the main thread's context
    NSManagedObjectContext *contextForThread = [[CurrentSession instance] newManagedObjectContext];

    // overwrite the store with our data
    [contextForThread setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];

    saveBlock(contextForThread);
    //step 5
    NSError *error = nil;
    if ([contextForThread hasChanges] && ![contextForThread save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
}

@end