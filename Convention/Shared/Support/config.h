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
#define kShowCorp [[SettingsManager sharedManager] lookupSettingByString:@"host"]
#define ConfigUrl [NSString stringWithFormat:@"/shows/%@/configurations.json", ShowID]
#define kDBLOGIN @"/vendors/sign_in.json"
#define kDBLOGOUT @"/vendors/sign_out.json"
#define kDBGETPRODUCTS [NSString stringWithFormat:@"/vendor/shows/%@/products.json",ShowID]
#define kDBGETVENDORSWithVG [NSString stringWithFormat:@"/vendor/shows/%@/vendorgroups.json",ShowID]
#define kDBGETCUSTOMERS [NSString stringWithFormat:@"/vendor/shows/%@/customers.json",ShowID]
#define kDBGETCUSTOMER(customerId) [NSString stringWithFormat:@"/vendor/shows/%@/customers/%@.json?",ShowID, customerId]
#define kDBORDER [NSString stringWithFormat:@"/vendor/shows/%@/orders.json",ShowID]
#define kDBORDEREDITS(ID) [NSString stringWithFormat:@"/vendor/shows/%@/orders/%d.json",ShowID,ID]
#define kDBCAPTURESIG(ID)[NSString stringWithFormat:@"/vendor/orders/%d/signature.json",ID]

#define kDBREPORTPRINTS [NSString stringWithFormat:@"/vendor/shows/%@/report_prints.json",ShowID]
#define kDBGETPRINTERS [NSString stringWithFormat:@"/vendor/shows/%@/printers.json", ShowID]
#define kDBGETBULLETINS [NSString stringWithFormat:@"/vendor/shows/%@/bulletins.json", ShowID]

//Auth keys
#define kEmailKey @"user[login]"
#define kPasswordKey @"user[password]"
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
#define kVendorLines @"lines"
#define kVendorEmail @"email"
#define kVendorHideWSPrice @"hidewsprice"
#define kVendorHideSHPrice @"hideshprice"
#define kVendorVendorGroupId @"vendorgroup_id"
#define kVendorInitialShow @"initial_show"
#define kVendorIsle @"isle"
#define kVendorBooth @"booth"
#define kVendorDept @"dept"
#define kVendorBrokerId @"broker_id"
#define kVendorStatus @"status"
#define kVendorName @"name"
#define kVendorOwner @"owner"
#define kVendorSeason @"season"
#define kVendorUpdatedAt @"updated_at"
#define kVendorUsername @"username"
#define kVendorVendID @"vendid"
#define kVendorID @"id"

#define kVendorGroupID @"vendorgroup_id"

#define kID @"id"
#define kOrderId @"id"
#define kProductId @"id"
#define kLineItemId @"id"


//Order keys:
#define kOrder @"order"
#define kOrderPrint @"print"
#define kOrderPrinter @"printer"
#define kOrderPoNumber @"po_number"
#define kOrderPaymentTerms @"payment_terms"
#define kOrderShipDates @"ship_dates"


//Customer Info keys:
#define kCustID @"custid"
#define kOrderCustomerID @"customer_id"
#define kStores @"stores"

#define kNotes @"notes"

#define kBillName @"billname"

#define kAuthorizedBy @"authorized"
#define kShipFlag @"ship_flag"
#define kCancelByDays @"cancel_by_days"

//purchased Items keys:
#define kCustomFieldFieldName @"field_name"
#define kCustomFieldCustomFieldInfoId @"custom_field_info_id"
#define kCustomFieldValue @"value"
#define kOrderItems @"line_items_attributes"
#define kCustomFields @"custom_fields_attributes"
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
#define kProductSequence @"sequence"
#define kProductAdv @"adv"
#define kProductRegPrc @"regprc"
#define kProductShipDate1 @"shipdate1"
#define kProductShipDate2 @"shipdate2"
#define kProductVoucher @"voucher"
#define kProductDiscount @"discount"
#define kProductUniqueId @"unique_product_id"
#define kProductCompany @"company"
#define kProductInitialShow @"initial_show"
#define kProductVendID @"vendid"
#define kProductVendorID @"vendor_id"
#define kProductBulletin @"bulletin"
#define kProductBulletinId @"bulletin_id"
#define kProductMin @"min"
#define kProductStatus @"status"
#define kProductManufacturerNo @"manufacturer_no"
#define kProductCategory @"category"
#define kProductEditable @"editable"

#define kLineItemPRICE @"price"
#define kLineItemVoucher @"voucherPrice"

#define kReportPrintOrderId @"order_id"

#define kOFFSET_FOR_KEYBOARD 80.0

#define kFontName @"BEBAS"

#define kCustomerId @"id"
#define kCustomerCustId @"custid"
#define kCustomerBillName @"billname"
#define kCustomerEmail @"email"
#define kCustomerInitialShow @"initial_show"
#define kCustomerStores @"stores"

#define kBulletinId @"id"
#define kBulletinName @"name"
#define kBulletinNumber @"number"
#define kBulletinNote1 @"note1"
#define kBulletinNote2 @"note2"
#define kBulletinShipDate1 @"shipdate1"
#define kBulletinShipDate2 @"shipdate2"
#define kBulletinVendorId @"vendor_id"
#define kBulletinShowId @"show_id"
#define kBulletinStatus @"status"

#define kErrors @"errors"

#define kSettingsUsernameKey @"kSettingsUsernameKey"
#define kSettingsPasswordKey @"kSettingsPasswordKey"

#endif
