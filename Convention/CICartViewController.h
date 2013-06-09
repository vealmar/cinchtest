//
//  CICartViewController.h
//  Convention
//
//  Created by Matthew Clark on 5/11/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CICustomerInfoViewController.h"
#import "CIProductCell.h"
#import "CIStoreQtyTableViewController.h"

@protocol CICartViewDelegate <NSObject>

-(void) Return;

-(void) setProductCart:(NSMutableDictionary*)cart;

-(void) setBackFromCart:(BOOL)yes;
-(void) setFinishOrder:(BOOL)yes;
-(void)QtyChange:(double)qty forIndex:(int)idx;
-(void)reload;
- (IBAction)finishOrder:(id)sender;

@end

@interface CICartViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) IBOutlet UITableView *products;
@property (nonatomic, strong) NSMutableDictionary* productData;
@property (nonatomic, strong) NSDictionary* customer;
@property (nonatomic, strong) NSString* authToken;
//@property (nonatomic, strong) NSArray* customerDB;
@property (nonatomic, strong) NSMutableDictionary* productCart;
@property (nonatomic, strong) NSMutableDictionary *discountItems;
@property (nonatomic) BOOL showPrice;
@property (nonatomic) BOOL multiStore;
@property (nonatomic) BOOL customersReady;
@property (nonatomic) int tOffset;
@property (unsafe_unretained, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property (nonatomic, strong) UIPopoverController *popoverController;
@property (nonatomic, strong) CIStoreQtyTableViewController *storeQtysPO;

@property (unsafe_unretained, nonatomic) IBOutlet UINavigationBar *navBar;

@property (nonatomic, assign) id<CICartViewDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIButton *zeroVouchers;

@property (weak, nonatomic) IBOutlet UILabel *lblShipDate1;
@property (weak, nonatomic) IBOutlet UILabel *lblShipDate2;
@property (weak, nonatomic) IBOutlet UILabel *lblShipDateCount;

@property (weak, nonatomic) IBOutlet UIView *tableHeaderPigglyWiggly;
@property (weak, nonatomic) IBOutlet UIView *tableHeaderFarris;

@property (nonatomic) BOOL allowPrinting;
@property (nonatomic) BOOL showShipDates;

@property (weak, nonatomic) IBOutlet UILabel *grossTotal;
@property (weak, nonatomic) IBOutlet UILabel *discountTotal;
@property (weak, nonatomic) IBOutlet UILabel *netTotal;

@property (readwrite, copy) void(^finishTheOrder)(void);

-(void)PriceChange:(double)price forIndex:(int)idx;
-(void)QtyChange:(double)qty forIndex:(int)idx;
-(void)VoucherChange:(double)price forIndex:(int)idx;

- (IBAction)Cancel:(id)sender;

 
//- (IBAction)submit:(id)sender;
- (IBAction)finishOrder:(id)sender;
- (IBAction)clearVouchers:(id)sender;

@end
