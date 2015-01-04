//
//  CoreDataUtil.m
//
//
//  Created by Chris Hardin on 2/8/11.
//  Copyright 2011 Dapper Dapple Mobile LLC. All rights reserved.
//

#import "CoreDataUtil.h"
#import "CIAppDelegate.h"
#import "CurrentSession.h"

static CoreDataUtil *sharedInstance;

@implementation CoreDataUtil

#pragma mark Singleton Implementation

+ (CoreDataUtil *)sharedManager {
    @synchronized (self) {
        if (sharedInstance == nil) {
            sharedInstance = [[self alloc] init];
        }
    }
    return sharedInstance;
}

- (NSManagedObject *)createNewEntity:(NSString *)entityDescription {

    return [NSEntityDescription insertNewObjectForEntityForName:entityDescription
                                         inManagedObjectContext:[CurrentSession mainQueueContext]];
}

- (NSArray *)fetchObjects:(NSString *)entityDescription sortField:(NSString *)sortField {

    NSManagedObjectContext *context = [CurrentSession mainQueueContext];
    NSError *error;

    //Fetch the data....
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
            entityForName:entityDescription inManagedObjectContext:context];
    [fetchRequest setEntity:entity];

    //Sort by Category Name
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
            initWithKey:sortField ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];

    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];


    return fetchedObjects;
}


- (NSFetchedResultsController *)fetchGroupedObjects:(NSString *)entityDescription
                                          sortField:(NSString *)sortField
                                      withPredicate:(NSPredicate *)predicate {

    NSManagedObjectContext *context = [CurrentSession mainQueueContext];
    //NSError *error;

    //Fetch the data....
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
            entityForName:entityDescription inManagedObjectContext:context];
    [fetchRequest setEntity:entity];

    NSSortDescriptor *groupDescription = [[NSSortDescriptor alloc]
            initWithKey:GROUP_NAME ascending:YES];
    //Sort by Category Name
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
            initWithKey:sortField ascending:YES];

    NSMutableArray *sorts = [[NSMutableArray alloc] init];

    [sorts addObject:sortDescriptor];
    [sorts addObject:groupDescription];


    [fetchRequest setSortDescriptors:sorts];
    //[fetchRequest setResultType:NSDictionaryResultType];
    //[fetchRequest setPropertiesToGroupBy:[entity.propertiesByName valueForKey:CONTRACTOR_NAME];


    if (predicate != nil)
        [fetchRequest setPredicate:predicate];


    //NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];

    //NSFetchResultsController

    [fetchRequest setFetchBatchSize:20];

    NSFetchedResultsController *fetchedResultsController =
            [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                managedObjectContext:context sectionNameKeyPath:GROUP_NAME
                                                           cacheName:nil]; //Don't use a cache

    return fetchedResultsController; //You can't autorelease this thing... the requestor must  do that.


}

- (NSManagedObject *)fetchObject:(NSString *)entityDescription
                   withPredicate:(NSPredicate *)predicate {

    NSManagedObjectContext *context = [CurrentSession mainQueueContext];
    return [self fetchObject:entityDescription inContext:context withPredicate:predicate];
}

- (NSManagedObject *)fetchObject:(NSString *)entityDescription
                       inContext:(NSManagedObjectContext *)context
                   withPredicate:(NSPredicate *)predicate {
    NSError *error;

    //Fetch the data....
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
            entityForName:entityDescription inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    fetchRequest.fetchLimit = 1;

    if (predicate != nil)
        [fetchRequest setPredicate:predicate];

    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];


    if ([fetchedObjects count] > 0)
        return [fetchedObjects objectAtIndex:0];
    else
        return nil;
}

- (id)fetchObjectFault:(NSString *)entity
             inContext:(NSManagedObjectContext *)context
         withPredicate:(NSPredicate *)predicate {
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entity];
    request.predicate = predicate;
    request.resultType = NSManagedObjectIDResultType;
    request.fetchLimit = 1;
    NSArray *results = [context executeFetchRequest:request error:nil];
    return results.count > 0 ? [context objectWithID:((NSManagedObjectID *)results[0])] : nil;
}

- (NSArray *)fetchArray:(NSString *)entityDescription
          withPredicate:(NSPredicate *)predicate
            withContext:(NSManagedObjectContext *)managedObjectContext{

    NSError *error;

    //Fetch the data....
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
            entityForName:entityDescription inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];

    if (predicate != nil)
        [fetchRequest setPredicate:predicate];

    NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];


    return fetchedObjects;
}


- (NSArray *)fetchArrayWithTemplate:(NSString *)templateName subs:(NSDictionary *)subs {


    NSManagedObjectModel *model = [DELEGATE managedObjectModel];
    NSManagedObjectContext *context = [DELEGATE managedObjectContext];
    NSError *error;

    //Fetch the data....
    NSFetchRequest *fetchRequest = [model fetchRequestFromTemplateWithName:templateName substitutionVariables:subs];


    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];


    return fetchedObjects;
}


- (NSManagedObject *)fetchObjectWithTemplate:(NSString *)templateName subs:(NSDictionary *)subs {

    NSManagedObjectModel *model = [DELEGATE managedObjectModel];
    NSManagedObjectContext *context = [DELEGATE managedObjectContext];
    NSError *error;

    //Fetch the data....
    NSFetchRequest *fetchRequest = [model fetchRequestFromTemplateWithName:templateName substitutionVariables:subs];


    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];


    if ([fetchedObjects count] > 0)
        return [fetchedObjects objectAtIndex:0];
    else
        return nil;
}


- (void)deleteObjectsWithTemplate:(NSString *)templateName  subs:(NSDictionary *)subs {

    NSManagedObjectModel *model = [DELEGATE managedObjectModel];
    NSManagedObjectContext *context = [DELEGATE managedObjectContext];

    //Fetch the data....
    NSFetchRequest *fetchRequest = [model fetchRequestFromTemplateWithName:templateName substitutionVariables:subs];

    NSError *error;
    NSArray *items = [context executeFetchRequest:fetchRequest error:&error];

    for (NSManagedObject *managedObject in items) {
        [context deleteObject:managedObject];
    }
    if (![context save:&error]) {
        DLog(@"Error deleting %@ - error:%@", templateName, error);
    }
}


- (void)deleteAllObjectsAndSave:(NSString *)entityDescription withContext:(NSManagedObjectContext *)managedObjectContext {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityDescription inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];

    NSError *error;
    NSArray *items = [managedObjectContext executeFetchRequest:fetchRequest error:&error];

    for (NSManagedObject *managedObject in items) {
        [managedObjectContext deleteObject:managedObject];
    }
    if (![managedObjectContext save:&error]) {
        DLog(@"Error deleting %@ - error:%@", entityDescription, error);
    }
}

- (void)deleteObjects:(NSString *)entityDescription  withPredicate:(NSPredicate *)predicate {

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityDescription inManagedObjectContext:[DELEGATE managedObjectContext]];
    [fetchRequest setEntity:entity];

    if (predicate != nil)
        [fetchRequest setPredicate:predicate];


    NSError *error;
    NSArray *items = [[DELEGATE managedObjectContext] executeFetchRequest:fetchRequest error:&error];

    for (NSManagedObject *managedObject in items) {
        [[DELEGATE managedObjectContext] deleteObject:managedObject];
    }
    if (![[DELEGATE managedObjectContext] save:&error]) {
        DLog(@"Error deleting %@ - error:%@", entityDescription, error);
    }
}

- (BOOL)deleteObject:(NSManagedObject *)managedObject {

    NSError *error;
    NSManagedObjectContext *context = managedObject.managedObjectContext;
    [context deleteObject:managedObject];
    if (![context save:&error]) {
        DLog(@"Error deleting - error:%@", error);
        return NO;
    }
    return YES;
}

- (void)saveObjects {
    [DELEGATE saveContext];
}

@end
