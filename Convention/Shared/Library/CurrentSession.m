//
// Created by David Jafari on 12/14/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "CurrentSession.h"
#import "NotificationConstants.h"
#import "config.h"
#import "CIAppDelegate.h"
#import "NilUtil.h"
#import "Show.h"
#import "Show+Extensions.h"
#import "Vendor.h"

@interface CurrentSession ()

@property (strong, nonatomic) NSManagedObjectContext *privateQueueContext;
@property (strong, nonatomic) NSManagedObjectContext *mainQueueContext;

@end;

@implementation CurrentSession

static CurrentSession *currentSession = nil;

+ (CurrentSession *)instance {
    if (nil == currentSession) {
        currentSession = [CurrentSession new];
        currentSession.vendorNameCache = [NSMutableDictionary dictionary];
    }
    return currentSession;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSNumber *)showId {
    NSNumber *showId = (NSNumber *) self.userInfo[@"current_show"][kShowId];
    return showId;
}

- (BOOL)hasAdminAccess {
    return self.userInfo && ((NSNumber *) self.userInfo[@"admin"]).boolValue;
}

- (NSNumber *)vendorGroupId {
    NSNumber *vendorgroupId = (NSNumber *) self.userInfo[kVendorGroupID];
    return vendorgroupId;
}

- (NSNumber *)brokerId {
    NSNumber *brokerId = (NSNumber *) self.userInfo[kVendorBrokerId];
    return brokerId;
}

- (NSNumber *)vendorId {
    NSNumber *vendorId = (NSNumber *) self.userInfo[kID];
    return vendorId;
}

- (void)setVendor:(Vendor *) vendor {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:self.userInfo];
    userInfo[kID] = vendor.vendorId;
    userInfo[kVendorGroupID] = vendor.vendorgroup_id;
    userInfo[kName] = vendor.name;
    userInfo[kVendorBrokerId] = vendor.broker_id;
    self.userInfo = [NSDictionary dictionaryWithDictionary:userInfo];
}

- (NSString *)vendorName {
    return [NilUtil objectOrEmptyString:self.userInfo[@"name"]];
}

- (NSString *)showTitle {
    return [NilUtil objectOrEmptyString:self.userInfo[@"current_show"][@"title"]];
}


- (void) setShow:(Show *)show{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[CurrentSession instance].userInfo];
    if(show){
        userInfo[@"current_show"] = [show asDictionary];
    }else{
        [userInfo setNilValueForKey:@"current_show"];
    }
    [CurrentSession instance].userInfo = [NSDictionary dictionaryWithDictionary:userInfo];
}

- (void)dispatchSessionDidChange {
    [self.vendorNameCache removeAllObjects];

    [[NSNotificationCenter defaultCenter] postNotificationName:SessionDidChangeNotification object:self];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleContextDidSave:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contextDidSavePrivateQueueContext:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:[self privateQueueContext]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contextDidSaveMainQueueContext:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:[self mainQueueContext]];

}

- (NSManagedObjectContext *)newManagedObjectContext {
    CIAppDelegate *appDelegate = (CIAppDelegate *) [UIApplication sharedApplication].delegate;
    NSPersistentStoreCoordinator *coordinator = [appDelegate persistentStoreCoordinator];
    if (coordinator != nil) {
        NSManagedObjectContext *newContext = [[NSManagedObjectContext alloc] init];
        [newContext setPersistentStoreCoordinator:coordinator];
        [newContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
        [newContext setUndoManager:nil];
        return newContext;
    } else {
        DLog(@"A thread-safe NSManagedObjectContext was requested, but the NSPersistentStoreCoordinator was not available. Prepare for death by NIL");
        return nil;
    }
}

#pragma New Context Setup

#pragma mark - Singleton Access

+ (NSManagedObjectContext *)mainQueueContext
{
    return [[self instance] mainQueueContext];
}

+ (NSManagedObjectContext *)privateQueueContext
{
    return [[self instance] privateQueueContext];
}

#pragma mark - Getters

- (NSManagedObjectContext *)mainQueueContext
{
    if (!_mainQueueContext) {
        CIAppDelegate *appDelegate = (CIAppDelegate *) [UIApplication sharedApplication].delegate;
        NSPersistentStoreCoordinator *coordinator = [appDelegate persistentStoreCoordinator];
        _mainQueueContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _mainQueueContext.persistentStoreCoordinator = coordinator;
        _mainQueueContext.mergePolicy = NSOverwriteMergePolicy;
        _mainQueueContext.undoManager = nil;
//        _mainQueueContext.mergePolicy = NSErrorMergePolicyType;
    }

    return _mainQueueContext;
}

- (NSManagedObjectContext *)privateQueueContext
{
    if (!_privateQueueContext) {
        CIAppDelegate *appDelegate = (CIAppDelegate *) [UIApplication sharedApplication].delegate;
        NSPersistentStoreCoordinator *coordinator = [appDelegate persistentStoreCoordinator];
        _privateQueueContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _privateQueueContext.persistentStoreCoordinator = coordinator;
        _privateQueueContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    }

    return _privateQueueContext;
}

- (void)handleContextDidSave:(NSNotification *)notification
{
    if (![notification.object isEqual:self.mainQueueContext] && ![notification.object isEqual:self.privateQueueContext]) {
        [self contextDidSavePrivateQueueContext:notification];
        [self contextDidSaveMainQueueContext:notification];
    }
}

- (void)contextDidSavePrivateQueueContext:(NSNotification *)notification
{
    @synchronized(self) {
        [self.mainQueueContext performBlock:^{
            DLog(@"Context Merge |-> Main Queue");
            [self.mainQueueContext mergeChangesFromContextDidSaveNotification:notification];
        }];
    }
}

- (void)contextDidSaveMainQueueContext:(NSNotification *)notification
{
    @synchronized(self) {
        [self.privateQueueContext performBlock:^{
            DLog(@"Context Merge: |-> Private Queue");
            [self.privateQueueContext mergeChangesFromContextDidSaveNotification:notification];
        }];
    }
}




@end