//
//  CICartViewController.h
//  Convention
//
//  Created by Matthew Clark on 5/11/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CISelectCustomerViewController.h"
#import "CISignatureViewController.h"
#import "ProductCellDelegate.h"
#import "CINavViewManager.h"

@class Product;
@class Order;
@class CISignatureViewController;
@class LineItem;

@protocol CICartViewDelegate <NSObject>

- (void)cartViewDismissedWith:(Order *)order orderCompleted:(BOOL)orderCompleted;

@end

@interface CICartViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, ProductCellDelegate, SignatureDelegate, CINavViewManagerDelegate>

@property(nonatomic, strong) IBOutlet UITableView *productsUITableView;
@property(nonatomic, strong) NSDictionary *customer;
@property(nonatomic, strong) NSString *authToken;
@property(unsafe_unretained, nonatomic) IBOutlet UIActivityIndicatorView *indicator;

@property(unsafe_unretained, nonatomic) IBOutlet UINavigationBar *navBar;

@property(nonatomic, assign) id <CICartViewDelegate> delegate;
@property(weak, nonatomic) IBOutlet UIButton *zeroVouchers;

@property(weak, nonatomic) IBOutlet UILabel *tableHeaderPrice1Label;
@property(weak, nonatomic) IBOutlet UILabel *tableHeaderPrice2Label;
@property(weak, nonatomic) IBOutlet UILabel *lblShipDate1;
@property(weak, nonatomic) IBOutlet UILabel *lblShipDate2;
@property(weak, nonatomic) IBOutlet UILabel *lblShipDateCount;

@property(weak, nonatomic) IBOutlet UIView *tableHeaderPigglyWiggly;
@property(weak, nonatomic) IBOutlet UIView *tableHeaderFarris;

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

- (id)initWithOrder:(Order *)coreDataOrder customer:(NSDictionary *)customerDictionary authToken:(NSString *)token selectedVendorId:(NSNumber *)selectedVendorId andManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (IBAction)Cancel:(id)sender;

- (IBAction)handleTap:(UITapGestureRecognizer *)sender;
@end
