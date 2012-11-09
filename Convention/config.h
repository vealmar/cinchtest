//
//  config.h
//  Convention
//
//  Created by Matthew Clark on 10/31/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#ifndef Convention_config_h
#define Convention_config_h

//#define kBASEURL @"http://afc.conventioninnovations.com"
//#define kBASEURL @"http://conventioninnovations.herokuapp.com"
#define kBASEURL @"http://10.0.6.187"
//#define kBASEURL @"http://:3000"
#define kShowID @"1"
#define kDBLOGIN [NSString stringWithFormat:@"%@//vendors/sign_in.json",kBASEURL]
#define kDBLOGOUT [NSString stringWithFormat:@"%@//vendors/sign_out.json",kBASEURL]
#define kDBGETPRODUCTS [NSString stringWithFormat:@"%@//vendor/shows/%@/products.json",kBASEURL,kShowID]
#define kDBGETVENDORSWithVG(VendorGroupID) [NSString stringWithFormat:@"%@//vendor/vendorgroups.json?%@=%@",kBASEURL,kVendorGroupID,VendorGroupID]
#define kDBGETCUSTOMERS [NSString stringWithFormat:@"%@//vendor/shows/%@/customers.json",kBASEURL,kShowID]
#define kDBORDER [NSString stringWithFormat:@"%@//vendor/shows/%@/orders.json",kBASEURL,kShowID]
#define kDBORDEREDIT(ID) [NSString stringWithFormat:@"%@/vendor/orders/%d.json",kBASEURL,ID]
#define kDBORDEREDITS(ID) [NSString stringWithFormat:@"%@/vendor/shows/%@/orders/%d.json",kBASEURL,kShowID,ID]
#define kDBREPORTPRINTS [NSString stringWithFormat:@"%@//vendor/shows/%@/report_prints.json",kBASEURL,kShowID]


//temp not needed...
#define kDBMasterLOGIN [NSString stringWithFormat:@"%@//hosts/sign_in.json",kBASEURL]
#define kDBMasterLOGOUT [NSString stringWithFormat:@"%@//hosts/sign_out.json",kBASEURL]
#define kDBGETVENDORS [NSString stringWithFormat:@"%@//host/vendors.json",kBASEURL]
#define kDBMasterORDER [NSString stringWithFormat:@"%@//host/shows/%@/orders.json",kBASEURL,kShowID]

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
#define kVendorLines @"lines"
#define kVendorName @"name"
#define kVendorOwner @"owner"
#define kVendorSeason @"season"
#define kVendorUpdatedAt @"updated_at"
#define kVendorUsername @"username"
#define kVendorVendID @"vendid"
#define kVendorIsle @"isle"
#define kVendorBooth @"booth"
#define kVendorDept @"dept"

#define kVendorGroupID @"vendorgroup_id"

#define kID @"id"

#define kError @"error"

//Order keys:
#define kOrder @"order"
    //Customer Info keys:
#define kCustID @"custid"
#define kOrderCustID @"customer_id"
#define kCustName @"customer_name"
#define kStoreName @"store_name"
#define kCity @"city"
#define kSendEmail @"send_email"
#define kEmail @"email"
#define kStores @"stores"

#define kShipNotes @"ship_notes"
#define kNotes @"notes"
//#define kAuthorizer @"authorizer"

#define kBillName @"billname"

#define kAuthorizedBy @"authorized"
#define kItemCount @"line_item_count"
#define kItems @"line_items"
#define kTotal @"total"
#define kVoucherTotal @"voucherTotal"

    //purchased Items keys:
#define kOrderItems @"line_items_attributes"
#define kOrderItemID @"product_id"
#define kOrderItemNum @"quantity"
#define kOrderItemPRICE @"price"
#define kOrderItemVoucher @"voucherPrice"
#define kOrderItemShipDates @"shipdates"

#define kProductShowPrice @"showprc"
#define kProductIdx @"idx"
#define kProductInvtid @"invtid"
#define kProductDescr @"descr"
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

#define kEditablePrice @"editablePrice"
#define kEditableVoucher @"editableVoucher"
#define kEditableQty @"editableQty"

//report print keys:
#define kReportPrintIsle @"report_print[isle]"
#define kReportPrintBooth @"report_print[booth]"
#define kReportPrintNotes @"report_print[notes]"
#define kReportPrintOrderId @"report_print[order_id]"

#define kOFFSET_FOR_KEYBOARD 60.0

#define kFontName @"BEBAS"

//file names
#define kCustomerFile @"custFile.plist"

#endif
