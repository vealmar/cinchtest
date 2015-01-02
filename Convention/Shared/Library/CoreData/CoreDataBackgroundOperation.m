//
// Created by David Jafari on 12/25/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "CoreDataBackgroundOperation.h"
#import "CurrentSession.h"

@implementation CoreDataBackgroundOperation

dispatch_queue_t coredata_background_save_queue() {
    static dispatch_once_t queueCreationGuard;
    static dispatch_queue_t queue;
    dispatch_once(&queueCreationGuard, ^{
        queue = dispatch_queue_create("com.urbancoding.cinch.coredata.backgroundsaves", nil);
    });
    return queue;
}

dispatch_queue_t coredata_batch_save_queue() {
    static dispatch_once_t queueCreationGuard;
    static dispatch_queue_t queue;
    dispatch_once(&queueCreationGuard, ^{
        queue = dispatch_queue_create("com.urbancoding.cinch.coredata.batchsaves", nil);
    });
    return queue;
}

+ (void)performInBackgroundWithContext:(void(^)(NSManagedObjectContext *context))asyncBlock
                            completion:(void(^)(void))completion
                               onQueue:(dispatch_queue_t)queue {

    dispatch_async(queue, ^{
        [self saveDataInContext:asyncBlock];

        if (completion) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                completion();
            });
        }
    });
}

+ (void)performBatchInBackgroundWithContext:(void(^)(NSManagedObjectContext *context))asyncBlock
                            completion:(void(^)(void))completion {
    
    dispatch_queue_t queue = coredata_batch_save_queue();
    [CoreDataBackgroundOperation performInBackgroundWithContext:asyncBlock completion:completion onQueue:queue];
}

+ (void)performInBackgroundWithContext:(void(^)(NSManagedObjectContext *context))asyncBlock
                            completion:(void(^)(void))completion {

    dispatch_queue_t queue = coredata_background_save_queue();
    [CoreDataBackgroundOperation performInBackgroundWithContext:asyncBlock completion:completion onQueue:queue];
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