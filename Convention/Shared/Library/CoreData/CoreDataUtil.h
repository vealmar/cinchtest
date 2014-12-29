//
//  ConnectionManager.h
//   
//
//  Created by Chris Hardin on 2/8/11.
//  Copyright 2011 Dapper Dapple Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
 
/**
 
 ConnectionManager will manage several different types of connections to HTTP or HTTPS in an automated fashion.
 This class works well when you need to make a quick HTTP call. 

**/

@interface CoreDataUtil : NSObject {
		
}


#pragma mark Singleton
+ (CoreDataUtil*)sharedManager;

-(NSManagedObject *) createNewEntity:(NSString *)entityDescription;

-(NSArray *) fetchObjects:(NSString *)entityDescription sortField:(NSString *)sortField;

-(NSFetchedResultsController *) fetchGroupedObjects:(NSString *)entityDescription 
										  sortField:(NSString *)sortField 
									  withPredicate:(NSPredicate *)predicate;

-(NSManagedObject *) fetchObject:(NSString *)entityDescription 
										withPredicate:(NSPredicate *)predicate;

- (NSManagedObject *)fetchObject:(NSString *)entityDescription
                       inContext:(NSManagedObjectContext *)context
                   withPredicate:(NSPredicate *)predicate;

/**
* Returns a CoreData Fault for an entity instead of the entire data. While this does perform
* a db search to confirm the existance and object ID, it otherwise saves on memory/time versus
* trying to load an entire record. This is useful for situations where a object is only needed
* to establish a relationship between NSManagedObjects.
*/
- (id)fetchObjectFault:(NSString *)entity
             inContext:(NSManagedObjectContext *)context
         withPredicate:(NSPredicate *)predicate;

-(NSArray *) fetchArrayWithTemplate:(NSString *)templateName subs:(NSDictionary *) subs;

- (void) deleteObjectsWithTemplate:(NSString *)templateName  subs:(NSDictionary *) subs;


-(NSManagedObject *) fetchObjectWithTemplate:(NSString *)templateName subs:(NSDictionary *) subs;


-(NSArray *) fetchArray:(NSString *)entityDescription 
			withPredicate:(NSPredicate *)predicate;

- (void) deleteAllObjects: (NSString *) entityDescription;

- (BOOL) deleteObject: (NSManagedObject *) managedObject;

- (void) deleteObjects: (NSString *) entityDescription  withPredicate:(NSPredicate *)predicate;

- (void) saveObjects;

@end
