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

@interface CIOrderViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate,
        UITextViewDelegate, UIAlertViewDelegate, ItemEditDelegate, CIProductViewDelegate, CIStoreQtyTableDelegate,
        CIStoreQtyDelegate, PullToRefreshViewDelegate, ReachabilityDelegate, UIPrinterSelectedDelegate> {
    ReachabilityDelegation *reachDelegation;
}

/*
* SG: orders is an array of NSDictionary objects. Each dictionary object represents an order.
* keys (NSString): id, customer_id, authorized, status, ship_notes, notes, line_item_count, total, voucherTotal,
* customer and line_items.
* customer points to another dictionary object. It contains following customer related keys: id, billname and custid.
* line_items points to an array of dictionaries. Each dictionary contains keys: id, order_id, product_id, quantity, price, voucherPrice, shipdates, category and product.
* product points to a dictionary with keys: shipdate1 and shipdate2.
*
* Relevant code in the web app:
* order.rb (method: as_json)
* line_item.rb (method: as_json)
* vendor/orders_controller.rb
* All values other than those for customer, line_items and product keys are NSString.
*
*/
@property(nonatomic, strong) NSMutableArray *orders;//SG: All orders for current show for the vendor group of the logged in vendor.
@property(nonatomic, strong) NSMutableArray *orderData;//SG: Orders filtered by the search field criteria.
@property(nonatomic, strong) NSString *authToken;
@property(nonatomic) BOOL showPrice;
@property(nonatomic, strong) NSDictionary *vendorInfo;//SG: NSDictionary containing vendor fields:id, name, auth_token, hideshprice, vendorgroup_id, isle, booth, dept and shows.
@property(nonatomic, strong) NSString *vendorGroup;//SG: This is actually the logged in vendor's id. It is set by the CIViewController.m before this view is loaded.
@property BOOL masterVender;
@property int currentVender;
@property(nonatomic, strong) NSDictionary *itemsDB; //SG:line items for the currently selected order.
@property(nonatomic, strong) NSMutableArray *itemsQty;//SG:quantities for line items of the currently selected order.
@property(nonatomic, strong) NSMutableArray *itemsPrice;//SG:prices for line items of the currently selected order.
@property(nonatomic, strong) NSMutableArray *itemsVouchers;//SG:voucher totals for line items of the currently selected order.
@property(nonatomic, strong) NSMutableArray *itemsShipDates;//SG:ship dates for line items of the currently selected order.
@property(nonatomic, strong) NSMutableArray *itemsDiscounts;//SG:discounts for line items of the currently selected order.
@property(nonatomic, strong) UIPopoverController *popoverController;
@property(nonatomic, strong) CIStoreQtyTableViewController *storeQtysPO;
@property(nonatomic, weak) NSManagedObjectContext *managedObjectContext;
@property(weak, nonatomic) IBOutlet UITextField *searchText;

@property(nonatomic) BOOL allowPrinting;
@property(nonatomic) BOOL showShipDates;

@property(weak, nonatomic) IBOutlet UITextView *shipdates;
@property(weak, nonatomic) IBOutlet UITableView *sideTable;
@property(weak, nonatomic) IBOutlet UIBarButtonItem *saveBtn;
@property(weak, nonatomic) IBOutlet UIView *EditorView; //SG:The view displayed to right of the side table.
@property(weak, nonatomic) IBOutlet UIToolbar *toolWithSave;
@property(weak, nonatomic) IBOutlet UIToolbar *toolPlain;
@property(weak, nonatomic) IBOutlet UITextView *customer; //SG:Text field next to Customer label in the editor view. Displays billname and custid of currently selected order's customer.
@property(weak, nonatomic) IBOutlet UITextView *authorizer;//SG:Text field next to Authorized label in the editor view. Displays authorized field value of currently selected order.
@property(weak, nonatomic) IBOutlet UITableView *itemsTable;//SG:Table of currently selected order's line items.
@property(weak, nonatomic) IBOutlet UITextView *notes; //SG:Displayed next to the Notes label in the editor view for Farris. Hidden for PW.
@property(weak, nonatomic) IBOutlet UILabel *SCtotal;//SG:Label next to Voucher in the editor view. Displays voucher total of the selected order.

@property(weak, nonatomic) IBOutlet UILabel *NoOrdersLabel;
@property(weak, nonatomic) IBOutlet UIActivityIndicatorView *ordersAct;
@property(weak, nonatomic) IBOutlet UIActivityIndicatorView *itemsAct;//SG:Displays spinning gear when line item information is being put together after an order from left is selected.
@property(strong, nonatomic) IBOutlet UIScrollView *OrderDetailScroll;
@property(weak, nonatomic) IBOutlet UIView *sideContainer;
@property(weak, nonatomic) IBOutlet UIView *placeholderContainer;
@property(weak, nonatomic) IBOutlet UIView *orderContainer;
@property(weak, nonatomic) IBOutlet UILabel *lblCompany;//SG:Don't see this in ui. Farris screenshots indicate the 'Customer' label in the editor view used to be 'Company'. 'Customer' in current ui is not a label though. It is part of the background.
@property(weak, nonatomic) IBOutlet UILabel *lblAuthBy;//SG:Don't see this in ui. Farris screenshots indicate the 'Authorized' label in the editor view used to be 'Authorized By'. 'Authorized' in current ui is not a label. It is part of the background.
@property(weak, nonatomic) IBOutlet UILabel *lblNotes;//SG:Don't see this in ui. Farris screenshots indicate the 'Shipping' label in the editor view used to be 'Notes and Shipping Instructions'. 'Shipping' in current ui is not a label. It is part of the background.
@property(weak, nonatomic) IBOutlet UILabel *lblVoucher;//SG:Don't see this in ui. This was probably used for PW shows before the ui was redone and the Voucher totals label became part of the background.
@property(weak, nonatomic) IBOutlet UILabel *lblItems;//SG:Don't see this in ui. This was probably one of the header labels in the line items table in the editor.
@property(weak, nonatomic) IBOutlet UILabel *lblTotalPrice;//SG:Don't see this in ui. Probably was replaced by one of the labels present in the background image after the ui was redone.
@property(weak, nonatomic) IBOutlet UIButton *printButton;//SG:Print button
@property(weak, nonatomic) IBOutlet UILabel *headerVoucherLbl;//SG:Don't see this in ui. Probably was replaced by one of the labels present in the background image after the ui was redone.
@property(weak, nonatomic) IBOutlet UILabel *grossTotal; //SG: label next to Total in the editor view for PW. Displays gross total.
@property(weak, nonatomic) IBOutlet UILabel *discountTotal;//SG:Displays discount total.
@property(weak, nonatomic) IBOutlet UILabel *total;
//SG:NoOrders and NoOrdersLabel reference the same label. One of these references can be removed. Displays static label "You have no orders" when there are no orders.
@property (weak, nonatomic) IBOutlet UILabel *notesLabel;
@property (weak, nonatomic) IBOutlet UILabel *grossTotalLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalLabel;
@property (weak, nonatomic) IBOutlet UILabel *discountTotalLabel;
@property (weak, nonatomic) IBOutlet UILabel *voucherTotal;
@property (weak, nonatomic) IBOutlet UILabel *voucherTotalLabel;

@property (weak, nonatomic) IBOutlet UIImageView *logoImage;

@property (weak, nonatomic) IBOutlet UILabel *voucherItemTotalLabel;
- (IBAction)AddNewOrder:(id)sender;

- (IBAction)logout:(id)sender;

- (IBAction)Save:(id)sender;

- (IBAction)Refresh:(id)sender;

- (IBAction)Print:(id)sender;

- (IBAction)Delete:(id)sender;

- (IBAction)searchOrders:(id)sender;


- (void)setSelectedPrinter:(NSString *)printer;

- (void)UpdateTotal;

- (void)Return;

@end
