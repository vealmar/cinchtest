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
#import "Product.h"
#import "Product+Extensions.h"
#import "CoreDataUtil.h"
#import "DiscountLineItem+Extensions.h"
#import "Cart+Extensions.h"
#import "SynchronousResponse.h"
#import "AFJSONRequestOperation.h"
#import "CIAppDelegate.h"


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

+ (void)reloadProducts:(NSString *)authToken vendorGroupId:(NSString *)vendorGroupId managedObjectContext:(NSManagedObjectContext *)managedObjectContext
        onSuccess:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id JSON))successBlock
        onFailure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON))failureBlock {

    NSString *url = [NSString stringWithFormat:@"%@?%@=%@&%@=%@", kDBGETPRODUCTS, kAuthToken, authToken, kVendorGroupID, vendorGroupId];

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                        success:^(NSURLRequest *req, NSHTTPURLResponse *response, id JSON) {
                                                                                            if (JSON && ([(NSArray *) JSON count] > 0)) {
                                                                                                [[CoreDataUtil sharedManager] deleteAllObjects:@"Product"];
                                                                                                NSArray *products = (NSArray *) JSON;

                                                                                                int batchSize = 500;
                                                                                                int productsCount = [products count];
                                                                                                NSRange range = NSMakeRange(0, productsCount > batchSize ? batchSize : productsCount);

                                                                                                NSDate *start = [NSDate date];
                                                                                                while (range.length > 0) {
                                                                                                    NSArray *productsBatch = [products subarrayWithRange:range];
                                                                                                    @autoreleasepool {
                                                                                                        for (NSDictionary *productJson in productsBatch) {
                                                                                                            [[Product alloc] initWithProductFromServer:productJson context:managedObjectContext];
                                                                                                        }
                                                                                                        [managedObjectContext save:nil];
                                                                                                    }
                                                                                                    int newStartLocation = range.location + range.length;
                                                                                                    range = NSMakeRange(newStartLocation, productsCount - newStartLocation > batchSize ? batchSize : productsCount - newStartLocation);
                                                                                                }

                                                                                                //re-establish connection between carts and products
                                                                                                NSArray *carts = [[CoreDataUtil sharedManager] fetchArray:@"Cart" withPredicate:nil];
                                                                                                if (carts) {
                                                                                                    for (Cart *cart in carts) {
                                                                                                        Product *product = (Product *) [[CoreDataUtil sharedManager] fetchObject:@"Product" withPredicate:[NSPredicate predicateWithFormat:@"(productId == %@)", cart.cartId]];
                                                                                                        if (product) {
                                                                                                            cart.product = product;
                                                                                                        }
                                                                                                    }
                                                                                                }
                                                                                                //re-establish connection between discount line items and products
                                                                                                NSArray *discountLineItems = [[CoreDataUtil sharedManager] fetchArray:@"DiscountLineItem" withPredicate:nil];
                                                                                                if (discountLineItems) {
                                                                                                    for (DiscountLineItem *discountLineItem in discountLineItems) {
                                                                                                        Product *product = (Product *) [[CoreDataUtil sharedManager] fetchObject:@"Product" withPredicate:[NSPredicate predicateWithFormat:@"(productId == %@)", discountLineItem.productId]];
                                                                                                        if (product) {
                                                                                                            discountLineItem.product = product;
                                                                                                        }
                                                                                                    }
                                                                                                }
                                                                                                [[CoreDataUtil sharedManager] saveObjects];

                                                                                                NSDate *methodFinish = [NSDate date];
                                                                                                NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:start];

                                                                                                NSLog(@"Execution Time: %f", executionTime);
                                                                                            }
                                                                                            if (successBlock) successBlock(req, response, JSON);
                                                                                        }
                                                                                        failure:^(NSURLRequest *req, NSHTTPURLResponse *response, NSError *err, id JSON) {
                                                                                            if (failureBlock) failureBlock(req, response, err, JSON);
                                                                                            NSInteger statusCode = [[[err userInfo] objectForKey:AFNetworkingOperationFailingURLResponseErrorKey] statusCode];
                                                                                            NSString *alertMessage = [NSString stringWithFormat:@"There was an error processing this request. Status Code: %d", statusCode];
                                                                                            if (statusCode == 422) {
                                                                                                NSArray *validationErrors = JSON ? [((NSDictionary *) JSON) objectForKey:kErrors] : nil;
                                                                                                if (validationErrors && validationErrors.count > 0) {
                                                                                                    alertMessage = validationErrors.count > 1 ? [NSString stringWithFormat:@"%@ ...", validationErrors[0]] : validationErrors[0];
                                                                                                }
                                                                                            } else if (statusCode == 0) {
                                                                                                alertMessage = @"Request timed out.";
                                                                                            } else {
                                                                                                alertMessage = [err localizedDescription];
                                                                                            }
                                                                                            [[[UIAlertView alloc] initWithTitle:@"Error!" message:alertMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                                                                                            NSLog(@"%@ Error Loading Products: %@", [self class], [err localizedDescription]);
                                                                                        }];
    [operation start];
}

+ (NSUInteger)getProductCount {
    CIAppDelegate *delegate = (CIAppDelegate *) [UIApplication sharedApplication].delegate;
    NSManagedObjectContext *context = delegate.managedObjectContext;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Product" inManagedObjectContext:context]];
    [request setIncludesSubentities:NO];
    NSError *err;
    NSUInteger count = [context countForFetchRequest:request error:&err];
    if (count == NSNotFound) {
        NSLog([NSString stringWithFormat:@"An error occurred when fetching product count. %@", err == nil? @"" : [err localizedDescription]]);
        return 0; //todo: handle error
    }
    return count;
}

@end