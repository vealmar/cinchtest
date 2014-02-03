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
#import "CISignatureViewController.h"

@class Cart;
@class ALineItem;
@class Product;
@class Order;
@class AnOrder;
@class CISignatureViewController;

@protocol CICartViewDelegate <NSObject>

- (void)cartViewDismissedWith:(Order *)coreDataOrder savedOrder:(AnOrder *)savedOrder unsavedChangesPresent:(BOOL)unsavedChangesPresent orderCompleted:(BOOL)orderCompleted;

@end

@interface CICartViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, ProductCellDelegate, SignatureDelegate>

@property(nonatomic, strong) IBOutlet UITableView *productsUITableView;
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
@property(nonatomic) BOOL allowSignature;

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

@property(weak, nonatomic) IBOutlet UILabel *vendorLabel;

- (id)initWithOrder:(Order *)coreDataOrder customer:(NSDictionary *)customerDictionary authToken:(NSString *)token selectedVendorId:(NSNumber *)selectedVendorId loggedInVendorId:(NSString *)loggedInVendorId loggedInVendorGroupId:(NSString *)loggedInVendorGroupId andManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (void)QtyChange:(int)qty forIndex:(int)idx;

- (void)VoucherChange:(double)voucherPrice forIndex:(int)idx;

- (IBAction)Cancel:(id)sender;


//- (IBAction)submit:(id)sender;
- (IBAction)finishOrder:(id)sender;

- (IBAction)clearVouchers:(id)sender;

- (IBAction)handleTap:(UITapGestureRecognizer *)sender;
@end
