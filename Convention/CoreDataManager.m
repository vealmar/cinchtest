//
// Created by septerr on 8/27/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "CoreDataManager.h"
#import "Order.h"
#import "Customer.h"
#import "config.h"
#import "SettingsManager.h"
#import "SynchronousRequestUtil.h"
#import "Product.h"
#import "Product+Extensions.h"
#import "CoreDataUtil.h"
#import "DiscountLineItem+Extensions.h"
#import "Cart+Extensions.h"
#import "SynchronousResponse.h"


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

+ (Customer *)getCustomer:(NSNumber *)customerId managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    Customer *customer;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Customer" inManagedObjectContext:managedObjectContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(customer_id ==[c] %@)", [customerId stringValue]];
    [fetchRequest setPredicate:predicate];
    NSError *error = nil;
    NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error == nil && fetchedObjects != nil && [fetchedObjects count] > 0) {
        customer = [fetchedObjects objectAtIndex:0];
    }
    return customer;
}

+ (NSArray *)getCustomers:(NSManagedObjectContext *)managedObjectContext {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Customer" inManagedObjectContext:managedObjectContext]];
    NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"billname" ascending:YES]];
    [fetchRequest setSortDescriptors:sortDescriptors];
    NSError *error = nil;
    NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"%@ Error fetching customers. %@", [self class], [error localizedDescription]);
        return [[NSArray alloc] init];
    } else
        return fetchedObjects;
}

+ (NSArray *)getProducts:(NSManagedObjectContext *)managedObjectContext {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Product" inManagedObjectContext:managedObjectContext]];
    NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"invtid" ascending:YES]];
    [fetchRequest setSortDescriptors:sortDescriptors];
    NSError *error = nil;
    NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"%@ Error fetching products. %@", [self class], [error localizedDescription]);
        return [[NSArray alloc] init];
    } else
        return fetchedObjects;
}

+ (NSArray *)getVendors:(NSManagedObjectContext *)managedObjectContext {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Vendor" inManagedObjectContext:managedObjectContext]];
    NSError *error = nil;
    NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"%@ Error fetching vendors. %@", [self class], [error localizedDescription]);
        return [[NSArray alloc] init];
    } else
        return fetchedObjects;
}

+ (NSArray *)getBulletins:(NSManagedObjectContext *)managedObjectContext {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Bulletin" inManagedObjectContext:managedObjectContext]];
    NSError *error = nil;
    NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"%@ Error fetching bulletins. %@", [self class], [error localizedDescription]);
        return [[NSArray alloc] init];
    } else
        return fetchedObjects;
}

+ (void)reloadProducts:(NSString *)authToken vendorGroupId:(NSString *)vendorGroupId managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSString *url = [NSString stringWithFormat:@"%@?%@=%@&%@=%@", kDBGETPRODUCTS, kAuthToken, authToken, kVendorGroupID, vendorGroupId];
    SynchronousResponse *response = [SynchronousRequestUtil sendRequestTo:url];
    if (response.successful) {
        if (response.json) {
            [[CoreDataUtil sharedManager] deleteAllObjects:@"Product"];
            for (NSDictionary *productJson in response.json) {
                Product *product = [[Product alloc] initWithProductFromServer:productJson context:managedObjectContext];
                [managedObjectContext insertObject:product];
                //re-establish connection between carts and products
                NSArray *carts = [[CoreDataUtil sharedManager] fetchArray:@"Cart" withPredicate:[NSPredicate predicateWithFormat:@"(cartId == %@)", product.productId]];
                if (carts) {
                    for (Cart *cart in carts) {
                        cart.product = product;
                    }
                }
                //re-establish connection between discount line items and products
                NSArray *discountLineItems = [[CoreDataUtil sharedManager] fetchArray:@"DiscountLineItem" withPredicate:[NSPredicate predicateWithFormat:@"(productId == %@)", product.productId]];
                if (discountLineItems) {
                    for (DiscountLineItem *discountLineItem in discountLineItems) {
                        discountLineItem.product = product;
                    }
                }
            }
            [[CoreDataUtil sharedManager] saveObjects];
        }

    } else
        NSLog(@"%@ Error fetching bulletins. Status Code: %d", [self class], response.statusCode);
}


@end