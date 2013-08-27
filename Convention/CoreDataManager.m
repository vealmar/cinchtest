//
// Created by septerr on 8/27/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "CoreDataManager.h"
#import "Order.h"


@implementation CoreDataManager {

}
+ (Order *)getOrder:(NSNumber *)orderId managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    Order *order;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Order" inManagedObjectContext:managedObjectContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(orderId ==[c] %@)", [orderId stringValue]];
    [fetchRequest setPredicate:predicate];
    NSArray *keys = [NSArray arrayWithObjects:@"carts", @"carts.shipdates", nil];
    [fetchRequest setRelationshipKeyPathsForPrefetching:keys];
    [fetchRequest setReturnsObjectsAsFaults:NO];
    NSError *error = nil;
    NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error == nil && fetchedObjects != nil && [fetchedObjects count] > 0) {
        order = [fetchedObjects objectAtIndex:0];
    }
    return order;
}
@end