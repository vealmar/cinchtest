//
//  CoreDataUtil.m
//
//
//  Created by Chris Hardin on 2/8/11.
//  Copyright 2011 Dapper Dapple Mobile LLC. All rights reserved.
//

#import "CoreDataUtil.h"
#import "GroupedObject.h"
#import "CIAppDelegate.h"



static CoreDataUtil * sharedInstance;

@implementation CoreDataUtil



#pragma mark Singleton Implementation

+ (CoreDataUtil*)sharedManager
{
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [[self alloc] init];
        }
    }
    return sharedInstance;
}

-(NSManagedObject *) createNewEntity:(NSString *)entityDescription
                          forContext:(NSManagedObjectContext *)managedObjectContext {
    
	return [NSEntityDescription insertNewObjectForEntityForName:entityDescription
                                         inManagedObjectContext:managedObjectContext];
}

-(NSManagedObject *) createNewEntity:(NSString *)entityDescription {
	
	CIAppDelegate *delegate = (CIAppDelegate *)[UIApplication sharedApplication].delegate;
	
//	return [NSEntityDescription insertNewObjectForEntityForName:entityDescription
//                                         inManagedObjectContext:delegate.managedObjectContext];
    
    return [self createNewEntity:entityDescription forContext:delegate.managedObjectContext];
}


-(NSArray *) fetchObjects:(NSString *)entityDescription sortField:(NSString *)sortField {
	
	CIAppDelegate *delegate = (CIAppDelegate *)[UIApplication sharedApplication].delegate;
	NSManagedObjectContext *context = delegate.managedObjectContext;
	NSError *error;
	
	//Fetch the data....
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription
								   entityForName:entityDescription inManagedObjectContext:context];
	[fetchRequest setEntity:entity];
	
	//Sort by Category Name
	NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc]
										initWithKey:sortField ascending:YES];
	NSArray* sortDescriptors = [[NSArray alloc] initWithObjects: sortDescriptor, nil];
	[fetchRequest setSortDescriptors:sortDescriptors];
    
	NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
	
	return fetchedObjects;
}


-(NSFetchedResultsController *) fetchGroupedObjects:(NSString *)entityDescription
										  sortField:(NSString *)sortField
                                      withPredicate:(NSPredicate *)predicate  {
	
	CIAppDelegate *delegate = (CIAppDelegate *)[UIApplication sharedApplication].delegate;
    
	NSManagedObjectContext *context = delegate.managedObjectContext;
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

-(NSManagedObject *) fetchObject:(NSString *)entityDescription
				   withPredicate:(NSPredicate *)predicate {
	
	CIAppDelegate *delegate = (CIAppDelegate *)[UIApplication sharedApplication].delegate;
	NSManagedObjectContext *context = delegate.managedObjectContext;
	NSError *error;
	
	//Fetch the data....
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription
								   entityForName:entityDescription inManagedObjectContext:context];
	[fetchRequest setEntity:entity];

	if (predicate != nil)
		[fetchRequest setPredicate:predicate];
    
	NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
	
	DLog(@"Objects Found: %d", [fetchedObjects count]);
    
 	if ([fetchedObjects count] > 0)
        return [fetchedObjects objectAtIndex:0];
    else
        return nil;
}

-(NSArray *) fetchArray:(NSString *)entityDescription
          withPredicate:(NSPredicate *)predicate {
	
	CIAppDelegate *delegate = (CIAppDelegate *)[UIApplication sharedApplication].delegate;
    
	NSManagedObjectContext *context = delegate.managedObjectContext;
	NSError *error;
	
	//Fetch the data....
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription
								   entityForName:entityDescription inManagedObjectContext:context];
	[fetchRequest setEntity:entity];

	if (predicate != nil)
		[fetchRequest setPredicate:predicate];
    
	NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
	
	DLog(@"Objects Found: %d", [fetchedObjects count]);
    
    return fetchedObjects;
}

- (void) deleteAllObjects: (NSString *) entityDescription  {
	
	CIAppDelegate *delegate = (CIAppDelegate *)[UIApplication sharedApplication].delegate;
	
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityDescription inManagedObjectContext:delegate.managedObjectContext];
    [fetchRequest setEntity:entity];
	
    NSError *error;
    NSArray *items = [delegate.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    for (NSManagedObject *managedObject in items) {
        [delegate.managedObjectContext deleteObject:managedObject];
        DLog(@"%@ object deleted",entityDescription);
    }
    if (![delegate.managedObjectContext save:&error]) {
        DLog(@"Error deleting %@ - error:%@",entityDescription,error);
    }
}

- (void) deleteObject: (NSManagedObject *) managedObject  {
	
	CIAppDelegate *delegate = (CIAppDelegate *)[UIApplication sharedApplication].delegate;
    NSError *error;
    [delegate.managedObjectContext deleteObject:managedObject];
    if (![delegate.managedObjectContext save:&error]) {
        DLog(@"Error deleting - error:%@",error);
    }
}

-(BOOL) deleteObjectWithConfirmation:(NSManagedObject *) managedObject {
	CIAppDelegate *delegate = (CIAppDelegate *)[UIApplication sharedApplication].delegate;
    NSError *error;
    [delegate.managedObjectContext deleteObject:managedObject];
    if (![delegate.managedObjectContext save:&error]) {
        DLog(@"Error deleting - error:%@",error);
        return NO;
    }
    return YES;
}

- (void) saveObjects {
    CIAppDelegate *delegate = (CIAppDelegate*)[UIApplication sharedApplication].delegate;
    [delegate saveContext];
}

@end
