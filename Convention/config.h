//
//  config.h
//  Convention
//
//  Created by Matthew Clark on 10/31/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#ifndef Convention_config_h
#define Convention_config_h


#define SERVER @"server"
#define kBASEURL [[SettingsManager sharedManager] lookupSettingByString:SERVER]
#define ShowID [[SettingsManager sharedManager] lookupSettingByString:@"show"]

#define kPigglyWiggly @"PigglyWiggly"
#define kFarris @"Farris"
#define kShowCorp kPigglyWiggly
#define ConfigUrl [NSString stringWithFormat:@"%@/shows/%@/configurations.json", kBASEURL, ShowID]
#define kDBLOGIN [NSString stringWithFormat:@"%@/vendors/sign_in.json",kBASEURL]
#define kDBLOGOUT [NSString stringWithFormat:@"%@/vendors/sign_out.json",kBASEURL]
#define kDBGETPRODUCTS [NSString stringWithFormat:@"%@/vendor/shows/%@/products.json",kBASEURL,ShowID]
#define kDBGETVENDORSWithVG(VendorGroupID) [NSString stringWithFormat:@"%@/vendor/shows/%@/vendorgroups.json?%@=%@",kBASEURL,ShowID,kVendorGroupID,VendorGroupID]
#define kDBGETCUSTOMERS [NSString stringWithFormat:@"%@/vendor/shows/%@/customers.json",kBASEURL,ShowID]
#define kDBGETCUSTOMER(customerId) [NSString stringWithFormat:@"%@/vendor/shows/%@/customers/%@.json?",kBASEURL,ShowID, customerId]
#define kDBORDER [NSString stringWithFormat:@"%@/vendor/shows/%@/orders.json",kBASEURL,ShowID]
#define kDBORDEREDITS(ID) [NSString stringWithFormat:@"%@/vendor/shows/%@/orders/%d.json",kBASEURL,ShowID,ID]

//delete line item from given order
#define kDBOrderLineItemDelete(ID) [NSString stringWithFormat:@"%@/vendor/line_items/%d.json", kBASEURL, ID]

#define kDBREPORTPRINTS [NSString stringWithFormat:@"%@/vendor/shows/%@/report_prints.json",kBASEURL,ShowID]
#define kDBGETPRINTERS [NSString stringWithFormat:@"%@/vendor/shows/%@/printers.json", kBASEURL, ShowID]
#define kDBGETBULLETINS [NSString stringWithFormat:@"%@/vendor/shows/%@/bulletins.json", kBASEURL, ShowID]

//Auth keys
#define kEmailKey @"vendor[login]"
#define kPasswordKey @"vendor[password]"
#define kEmailMasterKey @"host[login]"
#define kPasswordMasterKey @"host[password]"
#define kAuthToken @"auth_token"
#define kResponse @"response"
#define kOK @"ok"
#define kName @"name"

#define kVenderHidePrice @"hideshprice"

#define kVendorCommodity @"commodity"
#define kVendorCompany @"company"
#define kVendorComplete @"complete"
#define kVendorCreatedAt @"created_at"
#define kVendorDlybill @"dlybill"
#define kVendorEmail @"email"
#define kVendorHideWSPrice @"hidewsprice"
#define kVendorImportID @"import_id"
#define kVendorInitialShow @"initial_show"
#define kVendorName @"name"
#define kVendorOwner @"owner"
#define kVendorSeason @"season"
#define kVendorUpdatedAt @"updated_at"
#define kVendorUsername @"username"
#define kVendorVendID @"vendid"

#define kVendorGroupID @"vendorgroup_id"

#define kID @"id"
#define kOrderId @"id"
#define kProductId @"id"
#define kLineItemId @"id"


//Order keys:
#define kOrder @"order"
//Customer Info keys:
#define kCustID @"custid"
#define kOrderCustID @"customer_id"
#define kEmail @"email"
#define kStores @"stores"

#define kShipNotes @"ship_notes"
#define kNotes @"notes"

#define kBillName @"billname"

#define kAuthorizedBy @"authorized"
#define kShipFlag @"ship_flag"

//purchased Items keys:
#define kOrderItems @"line_items_attributes"
#define kLineItemProductID @"product_id"
#define kLineItemQuantity @"quantity"
#define kLineItemPrice @"price"
#define kLineItemVoucherPrice @"voucherPrice"
#define kLineItemShipDates @"shipdates"
#define kOrderStatus @"status"
#define kPartialOrder @"partial"

#define kProductShowPrice @"showprc"
#define kProductIdx @"idx"
#define kProductInvtid @"invtid"
#define kProductDescr @"descr"
#define kProductDescr2 @"descr2"
#define kProductPartNbr @"partnbr"
#define kProductUom @"uom"
#define kProductCaseQty @"caseqty"
#define kProductDirShip @"dirship"
#define kProductLineNbr @"linenbr"
#define kProductNew @"new"
#define kProductAdv @"adv"
#define kProductRegPrc @"regprc"
#define kProductShipDate1 @"shipdate1"
#define kProductShipDate2 @"shipdate2"
#define kProductVoucher @"voucher"
#define kProductDiscount @"discount"
#define kProductUniqueId @"unique_product_id"
#define kProductCompany @"company"
#define kProductImportID @"import_id"
#define kProductInitialShow @"initial_show"
#define kProductVendID @"vendid"
#define kProductVendorID @"vendor_id"
#define kProductCreatedAt @"created_at"
#define kProductUpdatedAt @"updated_at"

#define kLineItemPRICE @"price"
#define kLineItemVoucher @"voucherPrice"


#define kEditablePrice @"editablePrice"
#define kEditableVoucher @"editableVoucher"
#define kEditableQty @"editableQty"


#define kReportPrintOrderId @"order_id"

#define kOFFSET_FOR_KEYBOARD 80.0

#define kFontName @"BEBAS"


//notifications
#define kNotificationCustomersLoaded @"NotificationCustomersLoaded"
#define kCustomerNotificationKey @"customers"
#define kPrintersLoaded @"PrintersLoaded"


#endif
