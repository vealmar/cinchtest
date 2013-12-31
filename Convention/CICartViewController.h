//
//  CICartViewController.h
//  Convention
//
//  Created by Matthew Clark on 5/11/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CICustomerInfoViewController.h"
#import "PWProductCell.h"
#import "CIStoreQtyTableViewController.h"

@class Cart;
@class ALineItem;
@class Product;

@protocol CICartViewDelegate <NSObject>

- (void)setOrderSubmitted:(BOOL)yes;

- (void)changeQuantityTo:(int)qty forProductId:(NSNumber *)productId;

- (void)changeVoucherTo:(double)voucher forProductId:(NSNumber *)productId;

- (Product *)getProduct:(NSNumber *)productId;

//Returns array with gross total, voucher total and discount total. All items in array are NSNumbers.
- (NSArray *)getTotals;

- (Cart *)getCoreDataForProduct:(NSNumber *)productId;

- (NSUInteger)getDiscountItemsCount;

- (ALineItem *)getDiscountItemAt:(int)index;

- (BOOL)orderReadyForSubmission;

@end

@interface CICartViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, ProductCellDelegate>

@property(nonatomic, strong) IBOutlet UITableView *productsUITableView;
@property(nonatomic, strong) NSArray *productsInCart;
@property(nonatomic, strong) NSDictionary *customer;
@property(nonatomic, strong) NSString *authToken;
@property(nonatomic) BOOL showPrice;
@property(nonatomic) BOOL multiStore;
@property(nonatomic) int tOffset;
@property(unsafe_unretained, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property(nonatomic, strong) UIPopoverController *popoverController;
@property(nonatomic, strong) CIStoreQtyTableViewController *storeQtysPO;

@property(unsafe_unretained, nonatomic) IBOutlet UINavigationBar *navBar;

@property(nonatomic, assign) id <CICartViewDelegate> delegate;
@property(weak, nonatomic) IBOutlet UIButton *zeroVouchers;

@property(weak, nonatomic) IBOutlet UILabel *lblShipDate1;
@property(weak, nonatomic) IBOutlet UILabel *lblShipDate2;
@property(weak, nonatomic) IBOutlet UILabel *lblShipDateCount;

@property(weak, nonatomic) IBOutlet UIView *tableHeaderPigglyWiggly;
@property(weak, nonatomic) IBOutlet UIView *tableHeaderFarris;

@property(nonatomic) BOOL allowPrinting;
@property(nonatomic) BOOL showShipDates;

@property(weak, nonatomic) IBOutlet UILabel *grossTotal;
@property(weak, nonatomic) IBOutlet UILabel *discountTotal;
@property(weak, nonatomic) IBOutlet UILabel *netTotal;
@property(weak, nonatomic) IBOutlet UILabel *voucherTotal;

@property(readwrite, copy) void(^finishTheOrder)(void);
@property(weak, nonatomic) IBOutlet UILabel *grossTotalLabel;
@property(weak, nonatomic) IBOutlet UILabel *discountTotalLabel;
@property(weak, nonatomic) IBOutlet UILabel *netTotalLabel;
@property(weak, nonatomic) IBOutlet UILabel *voucherTotalLabel;
@property(weak, nonatomic) IBOutlet UILabel *tableHeaderMinColumn;

- (id)initWithOrder:(Order *)coreDataOrder;

- (void)QtyChange:(int)qty forIndex:(int)idx;

- (void)VoucherChange:(double)voucherPrice forIndex:(int)idx;

- (IBAction)Cancel:(id)sender;


//- (IBAction)submit:(id)sender;
- (IBAction)finishOrder:(id)sender;

- (IBAction)clearVouchers:(id)sender;

@end
