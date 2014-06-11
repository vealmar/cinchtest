//
// Created by septerr on 8/28/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "CIProductViewControllerHelper.h"
#import "config.h"
#import "JSONKit.h"
#import "StringManipulation.h"
#import "ShowConfigurations.h"
#import "SettingsManager.h"
#import "Order.h"
#import "Cart+Extensions.h"
#import "MBProgressHUD.h"
#import "Product.h"
#import "Product+Extensions.h"
#import "NilUtil.h"
#import "Order+Extensions.h"
#import "DiscountLineItem.h"
#import "CoreDataUtil.h"
#import "Vendor.h"
#import "NumberUtil.h"
#import "AFURLConnectionOperation.h"
#import "CinchJSONAPIClient.h"
#import "JSONResponseSerializerWithErrorData.h"


@implementation CIProductViewControllerHelper {

}

+ (int)getQuantity:(NSString *)quantity {
    if ([[quantity stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] startsWith:@"{"]) {
        int qty = 0;
        NSDictionary *quantitiesByStore = [quantity objectFromJSONString];
        for (NSString *storeId in [quantitiesByStore allKeys]) {
            qty += [[quantitiesByStore objectForKey:storeId] intValue];
        }
        return qty;
    }
    else {
        return [quantity intValue];
    }
}

- (BOOL)itemHasQuantity:(BOOL)multiStore quantity:(NSString *)quantity {
    NSInteger num = 0;
    if (!multiStore) {
        num = [quantity integerValue];
    } else {
        NSMutableDictionary *qty = [quantity objectFromJSONString];
        for (NSString *n in qty.allKeys) {
            int j = [[qty objectForKey:n] intValue];
            if (j > num) {
                num = j;
                if (num > 0) {
                    break;
                }
            }
        }
    }
    return num > 0;
}

- (BOOL)itemHasQuantity:(NSString *)quantity {
    if (quantity) {
        BOOL isMultiSTore = ([[quantity stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] startsWith:@"{"]);
        return [self itemHasQuantity:isMultiSTore quantity:quantity];
    } else
        return NO;
}

+ (BOOL)itemIsVoucher:(Product *)product {
    int idx = [product.idx intValue];
    NSString *invtId = product.invtid;
    return idx == 0 && ([invtId isEmpty] || [invtId isEqualToString:@"0"]);
}

- (BOOL)isProductAVoucher:(NSNumber *)productId {
    Product *product = [Product findProduct:productId];
    return [CIProductViewControllerHelper itemIsVoucher:product];
}

- (void)updateCellBackground:(UITableViewCell *)cell cart:(Cart *)cart {
    if ([ShowConfigurations instance].shipDatesRequired) {
        BOOL hasQty = [self itemHasQuantity:cart.editableQty];
        BOOL hasShipDates = cart.shipdates && cart.shipdates.count > 0;
        BOOL isVoucher = [CIProductViewControllerHelper itemIsVoucher:cart.product];
        if (!isVoucher) {
            if (hasQty) {
                if (hasShipDates) {
                    cell.backgroundColor = [UIColor colorWithRed:0.722 green:0.871 blue:0.765 alpha:0.75];
                } else {
                    cell.backgroundColor = [UIColor colorWithRed:0.839 green:0.655 blue:0.655 alpha:0.75];
                }
            } else {
                cell.backgroundColor = [UIColor whiteColor];
            }
        } else {
            if (hasQty) {
                cell.backgroundColor = [UIColor colorWithRed:0.722 green:0.871 blue:0.765 alpha:0.75];
            } else {
                cell.backgroundColor = [UIColor whiteColor];
            }
        }
    } else {
        BOOL hasQty = [self itemHasQuantity:cart.editableQty];
        if (hasQty) {
            cell.backgroundColor = [UIColor colorWithRed:0.722 green:0.871 blue:0.765 alpha:0.75];
        } else {
            cell.backgroundColor = [UIColor whiteColor];
        }
    }
}

- (UITableViewCell *)dequeueReusableProductCell:(UITableView *)table {
    NSString *CellIdentifier = [kShowCorp isEqualToString:kPigglyWiggly] ? @"PWProductCell" : @"FarrisProductCell";
    UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CellIdentifier owner:nil options:nil];
        cell = [topLevelObjects objectAtIndex:0];
    }
    return cell;
}

- (UITableViewCell *)dequeueReusableCartViewCell:(UITableView *)table {
    NSString *CellIdentifier = [kShowCorp isEqualToString:kPigglyWiggly] ? @"PWCartViewCell" : @"FarrisCartViewCell";
    UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CellIdentifier owner:nil options:nil];
        cell = [topLevelObjects objectAtIndex:0];
    }
    return cell;
}

- (void)saveManagedContext:(NSManagedObjectContext *)managedObjectContext {
    NSError *error = nil;
    if (![managedObjectContext save:&error]) {
        NSString *msg = [NSString stringWithFormat:@"Error saving changes: %@", [error localizedDescription]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
}

- (BOOL)isOrderReadyForSubmission:(Order *)coreDataOrder {
    //check there are items in cart
    if (coreDataOrder.carts.count == 0) {
        [[[UIAlertView alloc] initWithTitle:@"Error!" message:@"Please add at least one product to the cart before continuing." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return NO;
    }

    BOOL hasQuantity = NO;
    for (Cart *cart in coreDataOrder.carts) {
        if ([self itemHasQuantity:cart.editableQty]) {
            hasQuantity = YES;
            break;
        }
    }

    if (!hasQuantity) {
        [[[UIAlertView alloc] initWithTitle:@"Error!" message:@"Please add at least one product to the cart before continuing." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return NO;
    }

    //if using ship dates, all items with non-zero quantity (except vouchers) should have ship date(s)
    if ([ShowConfigurations instance].shipDatesRequired) {
        for (Cart *cart in coreDataOrder.carts) {
            Product *product = [Product findProduct:cart.cartId];
            BOOL hasQty = [self itemHasQuantity:cart.editableQty];
            if (hasQty && ![CIProductViewControllerHelper itemIsVoucher:product]) {
                BOOL hasShipDates = [NilUtil objectOrEmptyArray:cart.shipdates].count > 0; //todo is call to nilutil needed?
                if (!hasShipDates) {
                    [[[UIAlertView alloc] initWithTitle:@"Missing Data" message:@"All items in the cart must have ship date(s) before the order can be submitted. Check cart items and try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                    return NO;
                }
            }
        }
    }
    return YES;
}

- (void)sendRequest:(NSString *)httpMethod url:(NSString *)url parameters:(NSDictionary *)parameters
       successBlock:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id JSON))successBlock
       failureBlock:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON))failureBlock
               view:(UIView *)view loadingText:(NSString *)loadingText {
    MBProgressHUD *submit = [MBProgressHUD showHUDAddedTo:view animated:YES];
    submit.labelText = loadingText;
    [submit show:NO];

    NSMutableURLRequest *request = [[CinchJSONAPIClient sharedInstance].requestSerializer requestWithMethod:httpMethod URLString:[NSString stringWithFormat:@"%@%@", kBASEURL, url] parameters:parameters error:nil];
    __block NSURLSessionDataTask *task = [[CinchJSONAPIClient sharedInstanceWithJSONRequestSerialization] dataTaskWithRequest:request completionHandler:^(NSURLResponse * response, id json, NSError *error) {
        if (error) {
            [submit hide:NO];
            if (failureBlock) failureBlock(request, response, error, json);
            NSInteger statusCode = [[[error userInfo] objectForKey:AFNetworkingOperationFailingURLResponseErrorKey] statusCode];
            NSString *alertMessage = [NSString stringWithFormat:@"There was an error processing this request. Status Code: %d", statusCode];
            if (statusCode == 422) {
                NSArray *validationErrors = json ? [((NSDictionary *) json) objectForKey:kErrors] : nil;
                if (validationErrors && validationErrors.count > 0) {
                    alertMessage = validationErrors.count > 1 ? [NSString stringWithFormat:@"%@ ...", validationErrors[0]] : validationErrors[0];
                }
            } else if (statusCode == 0) {
                alertMessage = @"Request timed out.";
            }
            [[[UIAlertView alloc] initWithTitle:@"Error!" message:alertMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        } else {
            [submit hide:NO];
            if (successBlock) successBlock(request, response, json);
        }
    }];

    [task resume];
}

- (void)sendSignature:(UIImage *)signature total:(NSNumber *)total orderId:(NSNumber *)orderId authToken:(NSString *)authToken successBlock:(void (^)())successBlock failureBlock:(void (^)(NSError *error))failureBlock view:(UIView *)view {
    NSData *imageData = nil;
//    @autoreleasepool {
    imageData = UIImagePNGRepresentation(signature);
//    }
    if (imageData) {
        MBProgressHUD *submit = [MBProgressHUD showHUDAddedTo:view animated:YES];
        submit.labelText = @"Saving signature";
        [submit show:NO];

        [[CinchJSONAPIClient sharedInstanceWithJSONRequestSerialization] POST:kDBCAPTURESIG([orderId intValue]) parameters:@{ kAuthToken: authToken, @"total": total } constructingBodyWithBlock:^(id <AFMultipartFormData> formData) {
            [formData appendPartWithFileData:imageData name:@"signature" fileName:@"signature" mimeType:@"image/png"];
        } success:^(NSURLSessionDataTask *task, id JSON) {
            [submit hide:NO];
            if (successBlock) successBlock();
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            [submit hide:NO];
            if (failureBlock) failureBlock(error);
            NSInteger statusCode = [[[error userInfo] objectForKey:AFNetworkingOperationFailingURLResponseErrorKey] statusCode];
            NSString *alertMessage = [NSString stringWithFormat:@"There was an error processing this request. Status Code: %d", statusCode];
            [[[UIAlertView alloc] initWithTitle:@"Error!" message:alertMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Error!" message:@"There was an error in capturing your signature. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

- (void)alert:(NSString *)title message:(NSString *)message {
    [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

- (Order *)createCoreDataCopyOfOrder:(AnOrder *)order
                            customer:(NSDictionary *)customer
                    loggedInVendorId:(NSString *)loggedInVendorId
               loggedInVendorGroupId:(NSString *)loggedInVendorGroupId
                managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    Order *coreDataOrder = [[Order alloc] initWithOrder:order forCustomer:customer vendorId:[[NSNumber alloc] initWithInt:[loggedInVendorId intValue]] vendorGroup:loggedInVendorId andVendorGroupId:loggedInVendorGroupId context:managedObjectContext];
    [managedObjectContext insertObject:coreDataOrder];
    [self saveManagedContext:managedObjectContext];
    return coreDataOrder;
}

- (NSArray *)sortProductsByinvtId:(NSArray *)productIdsOrProducts {
    NSArray *sortedArray;
    sortedArray = [productIdsOrProducts sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        Product *product1 = [a isKindOfClass:[Product class]] ? a : [Product findProduct:a];
        Product *product2 = [b isKindOfClass:[Product class]] ? b : [Product findProduct:b];
        NSString *first = (NSString *) [NilUtil nilOrObject:product1.invtid];
        NSString *second = (NSString *) [NilUtil nilOrObject:product2.invtid];
        return [first compare:second];
    }];
    return sortedArray;
}

- (NSArray *)sortDiscountsByLineItemId:(NSArray *)lineItemIds {
    NSArray *sortedArray;
    sortedArray = [lineItemIds sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSNumber *first = (NSNumber *) a;
        NSNumber *second = (NSNumber *) b;
        return [first compare:second];
    }];
    return sortedArray;
}

//Returns array with gross total, voucher total and discount total. All items in array are NSNumbers.
- (NSArray *)getTotals:(Order *)coreDataOrder {
    NSDecimalNumber *grossTotal = [NumberUtil zeroDecimal];
    NSDecimalNumber *voucherTotal = [NumberUtil zeroDecimal];
    NSDecimalNumber *discountTotal = [NumberUtil zeroDecimal];
    if (coreDataOrder) {
        for (Cart *cart in coreDataOrder.carts) {
            NSNumber *qtyNumber = [NSNumber numberWithInt:[CIProductViewControllerHelper getQuantity:cart.editableQty]];//takes care of resolving quantities for multi stores
            NSDecimalNumber *qty = [NSDecimalNumber decimalNumberWithString:[qtyNumber stringValue]];

            ShowConfigurations *config = [ShowConfigurations instance];
            int shipDatesCount = 0;
            if (config.shipDates) {
                if ([config isLineItemShipDatesType]) {
                    shipDatesCount = cart.shipdates.count;
                } else if ([config isOrderShipDatesType]) {
                    shipDatesCount = cart.order.ship_dates.count;
                }
            }
            NSDecimalNumber *shipDates = shipDatesCount == 0 ? [NSDecimalNumber decimalNumberWithString:@"1"] :
                    [NSDecimalNumber decimalNumberWithString:[[NSNumber numberWithInt:shipDatesCount] stringValue]];

            NSNumber *priceNumber = [NSNumber numberWithDouble:[cart.editablePrice intValue] / 100.0];
            NSDecimalNumber *price = [NSDecimalNumber decimalNumberWithString:[priceNumber stringValue]];
            if (config.isLineItemShipDatesType) {
                grossTotal = [grossTotal decimalNumberByAdding:[qty decimalNumberByMultiplyingBy:price]];
            } else {
                grossTotal = [grossTotal decimalNumberByAdding:[[qty decimalNumberByMultiplyingBy:price] decimalNumberByMultiplyingBy:shipDates]];
            }
            if ([cart.editableVoucher intValue] != 0) {
                //cart.editableVoucher will never be null. all number fields have a default value of 0 in core data. you can change the default if you want .
                NSNumber *voucherNumber = [NSNumber numberWithDouble:[cart.editableVoucher intValue] / 100.0];
                NSDecimalNumber *voucher = [NSDecimalNumber decimalNumberWithString:[voucherNumber stringValue]];
                NSDecimalNumber *intermediate = [[qty decimalNumberByMultiplyingBy:voucher] decimalNumberByMultiplyingBy:shipDates];
                voucherTotal = [voucherTotal decimalNumberByAdding:intermediate];
            }
        }
        for (DiscountLineItem *discountLineItem in coreDataOrder.discountLineItems) {
            NSNumber *priceNumber = [NSNumber numberWithDouble:[discountLineItem.price intValue] / 100.0];
            NSDecimalNumber *price = [NSDecimalNumber decimalNumberWithString:[priceNumber stringValue]];
            NSDecimalNumber *qty = [NSDecimalNumber decimalNumberWithString:[discountLineItem.quantity stringValue]];
            discountTotal = [discountTotal decimalNumberByAdding:[price decimalNumberByMultiplyingBy:qty]];
        }
    }
    grossTotal = grossTotal == nil? [NumberUtil zeroDecimal] : grossTotal;
    voucherTotal = voucherTotal == nil? [NumberUtil zeroDecimal] : voucherTotal;
    discountTotal = discountTotal == nil? [NumberUtil zeroDecimal] : discountTotal;
    return @[grossTotal, voucherTotal, discountTotal];
}

- (NSString *)displayNameForVendor:(NSInteger)id vendorDisctionaries:(NSArray *)vendorDictionaries {
    NSMutableString *displayName = [NSMutableString string];
    for (NSDictionary *vendor in vendorDictionaries) {
        NSNumber *vendorId = (NSNumber *) [NilUtil nilOrObject:[vendor objectForKey:kVendorID]];
        if ([NilUtil nilOrObject:[vendor objectForKey:kVendorID]] && [vendorId integerValue] == id) {
            NSString *vendId = (NSString *) [NilUtil nilOrObject:[vendor objectForKey:kVendorVendID]];
            NSString *vendorName = (NSString *) [NilUtil nilOrObject:[vendor objectForKey:kVendorName]];
            [displayName appendString:vendId ? vendId : @""];
            if (vendorName) {
                if (displayName.length > 0) {
                    [displayName appendString:@" - "];
                }
                [displayName appendString:vendorName];
            }
            break;
        }
    }
    return displayName;
}

- (NSString *)displayNameForVendor:(NSNumber *)vendorId {
    Vendor *vendor = (Vendor *) [[CoreDataUtil sharedManager] fetchObject:@"Vendor" withPredicate:[NSPredicate predicateWithFormat:@"(vendorId == %@)", vendorId]];
    NSString *vendId = [NilUtil objectOrDefaultString:vendor.vendid defaultObject:@""];
    NSString *vendorName = [NilUtil objectOrDefaultString:vendor.name defaultObject:@""];
    return vendorName.length > 0 ? [NSString stringWithFormat:@"%@ - %@", vendId, vendorName] : vendorName;
}

@end