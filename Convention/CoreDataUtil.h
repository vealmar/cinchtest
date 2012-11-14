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
 
 
 */

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


-(NSArray *) fetchArray:(NSString *)entityDescription 
			withPredicate:(NSPredicate *)predicate;

- (void) deleteAllObjects: (NSString *) entityDescription;

- (void) deleteObject: (NSManagedObject *) managedObject;

- (void) saveObjects;

@end
