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
#import "AFJSONRequestOperation.h"
#import "AFHTTPClient.h"


@implementation CIProductViewControllerHelper {

}

- (int)getQuantity:(NSString *)quantity {
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

- (BOOL)itemIsVoucher:(NSDictionary *)product {
    int idx = [[product objectForKey:kProductIdx] intValue];
    NSString *invtId = [product objectForKey:kProductInvtid];
    return idx == 0 && ([invtId isEmpty] || [invtId isEqualToString:@"0"]);
}

- (void)updateCellBackground:(UITableViewCell *)cell product:(NSDictionary *)product
                        cart:(Cart *)cart {
    if ([ShowConfigurations instance].shipDates) {
        BOOL hasQty = [self itemHasQuantity:cart.editableQty];
        BOOL hasShipDates = cart.shipdates && cart.shipdates.count > 0;
        BOOL isVoucher = [self itemIsVoucher:product];
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
        NSString *msg = [NSString stringWithFormat:@"Error loading order: %@", [error localizedDescription]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
}

- (void)sendRequest:(NSString *)httpMethod url:(NSString *)url parameters:(NSDictionary *)parameters
       successBlock:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id JSON))successBlock
       failureBlock:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON))failureBlock
               view:(UIView *)view loadingText:(NSString *)loadingText {
    MBProgressHUD *submit = [MBProgressHUD showHUDAddedTo:view animated:YES];
    submit.labelText = loadingText;
    [submit show:NO];
    AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:url]];
    [client setParameterEncoding:AFJSONParameterEncoding];

    NSMutableURLRequest *request = [client requestWithMethod:httpMethod path:nil parameters:parameters];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                        success:^(NSURLRequest *req, NSHTTPURLResponse *response, id json) {
                                                                                            [submit hide:NO];
                                                                                            successBlock(req, response, json);
                                                                                        } failure:^(NSURLRequest *req, NSHTTPURLResponse *response, NSError *error, id json) {
                [submit hide:NO];
                failureBlock(req, response, error, json);
                NSInteger statusCode = [[[error userInfo] objectForKey:AFNetworkingOperationFailingURLResponseErrorKey] statusCode];
                NSString *alertMessage = statusCode == 422 ? @"There was an error processing this request. Please correct any errors indicated on the screen and try again." : [NSString stringWithFormat:@"There was an error submitting this request. Status Code: %d", statusCode];
                [[[UIAlertView alloc] initWithTitle:@"Error!" message:alertMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            }];
    [operation start];
}


@end