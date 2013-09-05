//
//  CIOrderViewController.h
//  Convention
//
//  Created by Matthew Clark on 12/8/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CIItemEditCell.h"
#import "CIProductViewController.h"
#import "CIStoreQtyTableViewController.h"
#import "PullToRefreshView.h"
#import "PrinterSelectionViewController.h"

@class AnOrder;

@interface CIOrderViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate,
        UITextViewDelegate, UIAlertViewDelegate, ItemEditDelegate, CIProductViewDelegate, CIStoreQtyTableDelegate,
        CIStoreQtyDelegate, PullToRefreshViewDelegate, ReachabilityDelegate, UIPrinterSelectedDelegate, CICustomerDelegate> {
    ReachabilityDelegation *reachDelegation;
}

@property(nonatomic, strong) NSString *authToken;
@property(nonatomic, strong) NSMutableArray *allorders;
@property(nonatomic, strong) NSMutableArray *filteredOrders;
@property(nonatomic, strong) NSDictionary *vendorInfo;
//itemsQty, itemsPrice, itemsVouchers, itemsShipDates and itemsDiscounts are used to track the changes user is making to quantity, price etc of the currently selected order. They are reset when user selects another order.
@property(nonatomic, strong) NSMutableArray *itemsQty;
@property(nonatomic, strong) NSMutableArray *itemsPrice;
@property(nonatomic, strong) NSMutableArray *itemsVouchers;
@property(nonatomic, strong) NSMutableArray *itemsShipDates;
@property(nonatomic, strong) NSMutableArray *itemsDiscounts;
@property(nonatomic, strong) UIPopoverController *poController;
@property(nonatomic, strong) CIStoreQtyTableViewController *storeQtysPO;
@property(nonatomic, weak) NSManagedObjectContext *managedObjectContext;
@property(weak, nonatomic) IBOutlet UITextField *searchText;

@property(weak, nonatomic) IBOutlet UITableView *sideTable;
@property(weak, nonatomic) IBOutlet UITextView *customer;
@property(weak, nonatomic) IBOutlet UITextView *authorizer;
@property(weak, nonatomic) IBOutlet UITableView *itemsTable;
@property(weak, nonatomic) IBOutlet UITextView *notes;

@property(weak, nonatomic) IBOutlet UILabel *NoOrdersLabel;
@property(strong, nonatomic) IBOutlet UIScrollView *OrderDetailScroll;
@property(weak, nonatomic) IBOutlet UIButton *printButton;
//SG:Print button
@property(weak, nonatomic) IBOutlet UILabel *grossTotal; //SG: label next to Total in the editor view for PW. Displays gross total.
@property(weak, nonatomic) IBOutlet UILabel *discountTotal;
//SG:Displays discount total.
@property(weak, nonatomic) IBOutlet UILabel *total;
@property(weak, nonatomic) IBOutlet UILabel *notesLabel;
@property(weak, nonatomic) IBOutlet UILabel *grossTotalLabel;
@property(weak, nonatomic) IBOutlet UILabel *totalLabel;
@property(weak, nonatomic) IBOutlet UILabel *discountTotalLabel;
@property(weak, nonatomic) IBOutlet UILabel *voucherTotal;
@property(weak, nonatomic) IBOutlet UILabel *voucherTotalLabel;

@property(weak, nonatomic) IBOutlet UIImageView *logoImage;

@property(weak, nonatomic) IBOutlet UILabel *voucherItemTotalLabel;

- (IBAction)AddNewOrder:(id)sender;

- (IBAction)logout:(id)sender;

- (IBAction)Save:(id)sender;

- (IBAction)Refresh:(id)sender;

- (IBAction)Print:(id)sender;

- (IBAction)Delete:(id)sender;

- (IBAction)searchOrders:(id)sender;


- (void)setSelectedPrinter:(NSString *)printer;

- (void)UpdateTotal;

- (IBAction)editOrder:(UIButton *)sender;

@end
