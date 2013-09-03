//
//  CICartViewController.m
//  Convention
//
//  Created by Matthew Clark on 5/11/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import "CICartViewController.h"
#import "config.h"
#import "UIAlertViewDelegateWithBlock.h"
#import "ShowConfigurations.h"
#import "ALineItem.h"
#import "CIProductViewControllerHelper.h"
#import "DateUtil.h"
#import "NumberUtil.h"
#import "PWCartViewCell.h"
#import "FarrisCartViewCell.h"

@interface CICartViewController () {
    NSMutableArray *allCartItems; //product cart items + discount items
    NSIndexPath *selectedItemRowIndexPath;
    __weak IBOutlet UILabel *customerInfoLabel;
    __weak IBOutlet UIImageView *logo;
}

@end

@implementation CICartViewController
@synthesize products;
@synthesize productData;
@synthesize authToken;
@synthesize navBar;
@synthesize title;
@synthesize showPrice;
@synthesize indicator;
@synthesize customer;
@synthesize delegate;
@synthesize customersReady;
@synthesize tOffset;
@synthesize productCart;
@synthesize finishTheOrder;
@synthesize multiStore;
@synthesize popoverController;
@synthesize storeQtysPO;
@synthesize lblShipDate1, lblShipDate2, lblShipDateCount;
@synthesize tableHeaderPigglyWiggly, tableHeaderFarris;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        showPrice = YES;
        customersReady = NO;
        tOffset = 0;
        productCart = [NSMutableDictionary dictionary];
    }
    return self;
}
#pragma mark - View lifecycle

- (void)adjustTotals {
    NSMutableArray *visibleTotalFields = [[NSMutableArray alloc] init];
    if (!self.grossTotal.hidden) [visibleTotalFields addObject:@{@"field" : self.grossTotal, @"label" : self.grossTotalLabel}];
    if (!self.discountTotal.hidden) [visibleTotalFields addObject:@{@"field" : self.discountTotal, @"label" : self.discountTotalLabel}];
    if (!self.voucherTotal.hidden) [visibleTotalFields addObject:@{@"field" : self.voucherTotal, @"label" : self.voucherTotalLabel}];
    if (!self.netTotal.hidden) [visibleTotalFields addObject:@{@"field" : self.netTotal, @"label" : self.netTotalLabel}];
    int availableHeight = 84;
    int heightPerField = availableHeight / visibleTotalFields.count;
    int marginBottomPerField = 2;
    heightPerField = heightPerField - marginBottomPerField;
    int y = 4;
    for (NSDictionary *totalField in visibleTotalFields) {
        ((UILabel *) [totalField objectForKey:@"label"]).frame = CGRectMake(766, y, 129, heightPerField);
        UITextField *textField = ((UITextField *) [totalField objectForKey:@"field"]);
        textField.text = @"0";
        textField.frame = CGRectMake(875, y, 101, heightPerField);
        y = y + heightPerField + marginBottomPerField;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    logo.image = [ShowConfigurations instance].logo;
    self.discountTotal.hidden = self.discountTotalLabel.hidden = ![ShowConfigurations instance].discounts;
    self.netTotal.hidden = self.netTotalLabel.hidden = ![ShowConfigurations instance].discounts;
    self.voucherTotal.hidden = self.voucherTotalLabel.hidden = ![ShowConfigurations instance].vouchers;
    self.grossTotalLabel.text = [ShowConfigurations instance].discounts ? @"Gross Total" : @"Total";
    [self adjustTotals];
    if ([kShowCorp isEqualToString:kPigglyWiggly]) {
        tableHeaderPigglyWiggly.hidden = NO;
        tableHeaderFarris.hidden = YES;
    } else if ([kShowCorp isEqualToString:kFarris]) {
        tableHeaderPigglyWiggly.hidden = YES;
        tableHeaderFarris.hidden = NO;
        self.zeroVouchers.hidden = YES;
    } else {
        tableHeaderPigglyWiggly.hidden = YES;
        tableHeaderFarris.hidden = YES;
    }
    customerInfoLabel.text = customer != nil &&
            customer[kBillName] != nil &&
            ![customer[kBillName] isKindOfClass:[NSNull class]] ? customer[kBillName] : @"";

    allCartItems = [NSMutableArray arrayWithCapacity:[self.productData count] + [self.discountItems count]];
    double grossTotal = 0.0;
    double voucherTotal = 0.0;
    NSArray *keys = [self.productData allKeys];
    for (NSString *key in keys) {
        ALineItem *lineItem = [self.productData objectForKey:key];
        [allCartItems addObject:lineItem];
        int qty = 0;
        if (multiStore) {
            NSDictionary *quantitiesByStore = [lineItem.quantity objectFromJSONString];
            for (NSString *storeId in [quantitiesByStore allKeys]) {
                qty += [[quantitiesByStore objectForKey:storeId] intValue];
            }
        }
        else {
            qty += [lineItem.quantity intValue];
        }
        int numOfShipDates = [lineItem.shipDates count];
        double price = [lineItem.price doubleValue];
        grossTotal += qty * price * (numOfShipDates == 0 ? 1 : numOfShipDates);

        if (lineItem.voucherPrice != nil && ![lineItem.voucherPrice isKindOfClass:[NSNull class]]) {
            double voucherPrice = [lineItem.voucherPrice doubleValue];
            voucherTotal += qty * voucherPrice * (numOfShipDates == 0 ? 1 : numOfShipDates);
        }
    }
    double discountTotal = 0.0;
    keys = [self.discountItems allKeys];
    for (NSString *key in keys) {
        ALineItem *discountLineItem = [self.discountItems objectForKey:key];
        [allCartItems addObject:discountLineItem];
        double price = [discountLineItem.price doubleValue];
        double qty = [discountLineItem.quantity doubleValue];
        discountTotal += price * qty;
    }
    self.grossTotal.text = [NumberUtil formatDollarAmount:[NSNumber numberWithDouble:grossTotal]];
    self.discountTotal.text = [NumberUtil formatDollarAmount:[NSNumber numberWithDouble:discountTotal]];
    double netTotal = grossTotal + discountTotal;
    self.netTotal.text = [NumberUtil formatDollarAmount:[NSNumber numberWithDouble:netTotal]];
    self.voucherTotal.text = [NumberUtil formatDollarAmount:[NSNumber numberWithDouble:voucherTotal]];
    [self.products reloadData];
    [self.indicator stopAnimating];
    self.indicator.hidden = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.indicator startAnimating];
    navBar.topItem.title = self.title;
    self.showShipDates = [[ShowConfigurations instance] shipDates];
    self.allowPrinting = [ShowConfigurations instance].printing;
    self.multiStore = [[self.customer objectForKey:kStores] isKindOfClass:[NSArray class]] && [((NSArray *) [self.customer objectForKey:kStores]) count] > 0;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

#pragma mark - Table stuff
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)myTableView numberOfRowsInSection:(NSInteger)section {
    if (allCartItems) {
        return [allCartItems count];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)myTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.productData) {return nil;}
    CIProductViewControllerHelper *helper = [[CIProductViewControllerHelper alloc] init];
    ALineItem *lineItem = (ALineItem *) [allCartItems objectAtIndex:indexPath.row];
    NSDictionary *editableDict = @{kEditablePrice : lineItem.price,
            kEditableVoucher : lineItem.voucherPrice ? lineItem.voucherPrice : [NSNumber numberWithInt:0],
            kEditableQty : lineItem.quantity,
            kLineItemShipDates : [DateUtil convertYyyymmddArrayToDateArray:lineItem.shipDates]};
    NSDictionary *product = [self.delegate getProduct:lineItem.productId];
    if ([kShowCorp isEqualToString:kPigglyWiggly]) {
        PWCartViewCell *cell = (PWCartViewCell *) [helper dequeueReusableCartViewCell:myTableView];
        [cell initializeWith:multiStore showPrice:self.showPrice product:product item:lineItem tag:[indexPath row] productCellDelegate:self];
        [helper updateCellBackground:cell product:product editableItemDetails:editableDict multiStore:multiStore];
        return cell;
    } else if ([kShowCorp isEqualToString:kFarris]) {
        FarrisCartViewCell *cell = (FarrisCartViewCell *) [helper dequeueReusableCartViewCell:myTableView];
        [cell initializeWith:product item:lineItem tag:[indexPath row] ProductCellDelegate:self];
        return cell;
    }
    return nil;
}

#pragma mark - Other

- (void)Cancel {
    self.indicator.hidden = NO;
    [self.indicator startAnimating];
    if (self.delegate) {
        [self.delegate setProductCart:[NSMutableDictionary dictionaryWithDictionary:self.productCart]];
        [self.delegate setOrderSubmitted:NO];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)Cancel:(id)sender {
    [self Cancel];
}


- (IBAction)finishOrder:(id)sender {
    if ([[self.productCart allKeys] count] <= 0) {
        [[[UIAlertView alloc] initWithTitle:@"Cart Empty." message:@"You don't have anything in your cart!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return;
    }
    if (self.delegate) {
        [self.delegate setProductCart:self.productCart];
        [self.delegate setOrderSubmitted:YES];
    }
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)clearVouchers:(id)sender {
    if ([[self.productCart allKeys] count] <= 0) {
        [[[UIAlertView alloc] initWithTitle:@"Cart Empty." message:@"You don't have anything in your cart!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return;
    }

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm" message:@"Zero out all vouchers?"
                                                   delegate:nil cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [UIAlertViewDelegateWithBlock showAlertView:alert withCallBack:^(NSInteger buttonIndex) {
        if (buttonIndex == 1) {
            [self zeroAllVouchers];
        }

    }];

}

- (void)zeroAllVouchers {
    for (NSString *key in [self.productData allKeys]) {
        ALineItem *lineItem = [self.productData objectForKey:key];
        lineItem.voucherPrice = [NSNumber numberWithDouble:0.0];
    }
    [self.products reloadData];
}

- (void)VoucherChange:(double)voucherPrice forIndex:(int)idx {
    NSString *key = [[self.productData allKeys] objectAtIndex:idx];
    ALineItem *lineItem = [self.productCart objectForKey:key];
    lineItem.voucherPrice = [NSNumber numberWithDouble:voucherPrice];
}

- (void)PriceChange:(double)price forIndex:(int)idx {
    NSString *key = [[self.productData allKeys] objectAtIndex:idx];
    ALineItem *lineItem = [self.productCart objectForKey:key];
    lineItem.price = [NSNumber numberWithDouble:price];
}

- (void)QtyChange:(double)qty forIndex:(int)idx {
    NSString *key = [[self.productData allKeys] objectAtIndex:idx];
    ALineItem *lineItem = [self.productCart objectForKey:key];
    if (qty <= 0) {
        [self.productData removeObjectForKey:key];
        [self.productCart removeObjectForKey:key];
        [self.products reloadData];
    }
    self.grossTotal.textColor = [UIColor redColor];
    self.discountTotal.textColor = [UIColor redColor];
    self.netTotal.textColor = [UIColor redColor];
    [self.delegate QtyChange:qty forIndex:idx];
    lineItem.quantity = [[NSNumber numberWithDouble:qty] stringValue];
}

- (void)QtyTouchForIndex:(int)idx {
    if ([popoverController isPopoverVisible]) {
        [popoverController dismissPopoverAnimated:YES];
    } else {
        if (!storeQtysPO) {
            storeQtysPO = [[CIStoreQtyTableViewController alloc] initWithNibName:@"CIStoreQtyTableViewController" bundle:nil];
        }
        NSString *key = [[self.productData allKeys] objectAtIndex:idx];
        ALineItem *lineItem = [self.productCart objectForKey:key];
        storeQtysPO.stores = [[lineItem.quantity objectFromJSONString] mutableCopy];
        storeQtysPO.tag = idx;
        storeQtysPO.editable = NO;
        storeQtysPO.delegate = (id <CIStoreQtyTableDelegate>) self;
        CGRect frame = [self.products rectForRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
        frame = CGRectOffset(frame, 750, 0);
        popoverController = [[UIPopoverController alloc] initWithContentViewController:storeQtysPO];
        [popoverController presentPopoverFromRect:frame inView:self.products permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

#pragma mark - keyboard functionality
- (void)setViewMovedUp:(BOOL)movedUp {
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.5]; // if you want to slide up the view

        CGPoint rect = self.products.contentOffset;
        if (movedUp) {
            // 1. move the view's origin up so that the text field that will be hidden come above the keyboard
            // 2. increase the size of the view so that the area behind the keyboard is covered up.
            tOffset = rect.y;
            rect.y += (kOFFSET_FOR_KEYBOARD* 6);//was -
            //rect.size.height += kOFFSET_FOR_KEYBOARD;
        }
        else {
            // revert back to the normal state.
            rect.y = tOffset;//-(kOFFSET_FOR_KEYBOARD-16);//was +
            //tOffset =0;
            //rect.size.height -= kOFFSET_FOR_KEYBOARD;
        }
        self.products.contentOffset = rect;

        [UIView commitAnimations];
    });
}


- (void)textEditBeginWithFrame:(CGRect)frame {
    int offset = frame.origin.y - self.products.contentOffset.y;
    if (offset >= 340) {
        [self setViewMovedUp:YES];
    }
    else {
        tOffset = self.products.contentOffset.y;
        [self setViewMovedUp:NO];
    }
}

- (void)textEditEndWithFrame:(CGRect)frame {
    [self setViewMovedUp:NO];
}

- (NSDictionary *)getCustomerInfo {
    return [self.customer copy];
}

- (void)setSelectedRow:(NSUInteger)index {
    selectedItemRowIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
}

- (void)keyboardWillShow {

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    self.products.contentOffset = selectedItemRowIndexPath ? CGPointMake(0, [self.products rowHeight] * selectedItemRowIndexPath.row) : CGPointMake(0, 0);
    [UIView commitAnimations];
}

- (void)keyboardDidHide {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    self.products.contentOffset = CGPointMake(0, 0);
    [UIView commitAnimations];
}


@end
