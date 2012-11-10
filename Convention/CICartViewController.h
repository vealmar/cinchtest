//
//  CICartViewController.h
//  Convention
//
//  Created by Matthew Clark on 5/11/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CICustomerInfoViewController.h"
#import "CIFinalCustomerInfoViewController.h"
#import "CIProductCell.h"
#import "CIStoreQtyTableViewController.h"

@protocol CICartViewDelegate <NSObject>

-(void) Return;

-(void) setProductCart:(NSMutableDictionary*)cart;

-(void) setBackFromCart:(BOOL)yes;
-(void) setFinishOrder:(BOOL)yes;

- (IBAction)finishOrder:(id)sender;

@end

@interface CICartViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property (unsafe_unretained, nonatomic) IBOutlet UITableView *products;
@property (nonatomic, strong) NSMutableDictionary* productData;
@property (nonatomic, strong) NSDictionary* customer;
@property (nonatomic, strong) NSString* authToken;
@property (nonatomic, strong) NSArray* customerDB;
@property (nonatomic, strong) NSMutableDictionary* productCart;
@property (nonatomic) BOOL showPrice;
@property (nonatomic) BOOL multiStore;
@property (nonatomic) BOOL customersReady;
@property (nonatomic) int tOffset;
@property (unsafe_unretained, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property (nonatomic, retain) UIPopoverController *popoverController;
@property (nonatomic, retain) CIStoreQtyTableViewController *storeQtysPO;

@property (unsafe_unretained, nonatomic) IBOutlet UINavigationBar *navBar;

@property (nonatomic, assign) id<CICartViewDelegate> delegate;

@property (readwrite, copy) void(^finishTheOrder)(void);

-(void)PriceChange:(double)price forIndex:(int)idx;
-(void)QtyChange:(double)qty forIndex:(int)idx;
-(void)VoucherChange:(double)price forIndex:(int)idx;

- (IBAction)Cancel:(id)sender;

- (IBAction)logout:(id)sender;
- (IBAction)submit:(id)sender;
- (IBAction)finishOrder:(id)sender;



-(void)setCustomerInfo:(NSDictionary*)info;

-(void)setTitle:(NSString *)title;

@end
