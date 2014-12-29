//
// Created by David Jafari on 12/14/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "CurrentSession.h"
#import "NotificationConstants.h"
#import "config.h"
#import "CIAppDelegate.h"

@implementation CurrentSession

static CurrentSession *currentSession = nil;

+ (CurrentSession *)instance {
    if (nil == currentSession) {
        currentSession = [CurrentSession new];
    }
    return currentSession;
}

- (id)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleContextSave:) name:NSManagedObjectContextDidSaveNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleContextSave:(NSNotification *)notification {
    if (![notification.object isEqual:self.managedObjectContext]) {
        [self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
    }
}

- (NSNumber *)loggedInVendorGroupId {
    NSNumber *vendorgroupId = (NSNumber *) [self.vendorInfo objectForKey:kVendorGroupID];
    return vendorgroupId;
}

- (NSNumber *)vendorId {
    NSNumber *vendorId = (NSNumber *) [self.vendorInfo objectForKey:kID];
    return vendorId;
}

- (void)dispatchSessionDidChange {
    [[NSNotificationCenter defaultCenter] postNotificationName:SessionDidChangeNotification object:self];
}

- (NSManagedObjectContext *)newManagedObjectContext {
    CIAppDelegate *appDelegate = (CIAppDelegate *) [UIApplication sharedApplication].delegate;
    NSPersistentStoreCoordinator *coordinator = [appDelegate persistentStoreCoordinator];
    if (coordinator != nil) {
        NSManagedObjectContext *newContext = [[NSManagedObjectContext alloc] init];
        [newContext setPersistentStoreCoordinator:coordinator];
        [newContext setMergePolicy:[[NSMergePolicy alloc] initWithMergeType:NSMergeByPropertyObjectTrumpMergePolicyType]];
        [newContext setUndoManager:nil];
        return newContext;
    } else {
        NSLog(@"A thread-safe NSManagedObjectContext was requested, but the NSPersistentStoreCoordinator was not available. Prepare for death by NIL");
        return nil;
    }
}

@end