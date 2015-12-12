//
//  config.h
//  Convention
//
//  Created by Matthew Clark on 10/31/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#ifndef Convention_config_h
#define Convention_config_h

//Settings/Preferences/NSUserDefaults
#define ServerSetting @"server"
#define CodeSetting @"code"
#define ShowIdSetting @"show"
#define HostIdSetting @"host"
#define kUsernameSetting @"UsernameSetting"
#define kPasswordSetting @"PasswordSetting"

//API End Points
#define kConfigsByCodeUrl @"/configurations_by_code/%@.json"
#define kDBLOGIN @"/vendors/sign_in.json"
#define kDBLOGOUT @"/vendors/sign_out.json"
#define kDBGETPRODUCTS @"/vendor/shows/%d/products.json"
#define kDBGETVENDORS @"/vendor/vendors.json"
#define kDBGETCUSTOMERS@"/vendor/customers.json"
#define kDBGETCUSTOMER @"/vendor/shows/%d/customers/%d.json?"
#define kDBGETORDER @"/vendor/shows/%d/orders/%d.json"
#define kDBORDER @"/vendor/shows/%d/orders.json"
#define kDBORDEREDITS @"/vendor/shows/%d/orders/%d.json"
#define kDBORDERDETAILEDITS @"/vendor/shows/%d/orders/%d/details.json"
#define kDBCAPTURESIG @"/vendor/orders/%d/signature.json"
#define kDBGETBULLETINS @"/vendor/bulletins.json"

//Auth keys
#define kEmailKey @"user[login]"
#define kPasswordKey @"user[password]"
#define kAuthToken @"auth_token"
#define kResponse @"response"
#define kOK @"ok"
#define kName @"name"

//Vendor JSON Keys
#define kVendorCommodity @"commodity"
#define kVendorCompany @"company"
#define kVendorComplete @"complete"
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
#define kVendorUsername @"username"
#define kVendorVendID @"vendid"
#define kVendorGroupName @"groupname"
#define kVendorID @"id"

#define kVendorGroupID @"vendorgroup_id"

#define kID @"id"
#define kProductId @"id"


//Order JSON keys:
#define kOrder @"order"
#define kOrderPoNumber @"po_number"
#define kOrderShipDates @"ship_dates"


//Customer Info keys:
#define kCustID @"custid"
#define kOrderCustomerID @"customer_id"

#define kNotes @"notes"

#define kBillName @"billname"

#define kAuthorizedBy @"authorized"

//purchased Items keys:
#define kCustomFieldFieldName @"field_name"
#define kCustomFieldCustomFieldInfoId @"custom_field_info_id"
#define kCustomFieldValue @"value"
#define kOrderItems @"line_items_attributes"
#define kCustomFields @"custom_fields_attributes"
#define kLineItemProductID @"product_id"
#define kLineItemQuantity @"quantity"
#define kLineItemPrice @"price"
#define kLineItemShipDates @"shipdates"
#define kOrderStatus @"status"
#define kOrderPricingTierIndex @"pricing_tier_index"
#define kOrderDiscountPercentage @"discount_percentage"

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
#define kProductPrices @"prices"
#define kProductTags @"tags"

#define kFontName @"BEBAS"

#define kCustomerId @"id"
#define kCustomerCustId @"custid"
#define kCustomerBillName @"billname"
#define kCustomerEmail @"email"
#define kCustomerDefaultShippingAddressSummary @"default_shipping_address_summary"

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

//Show JSON Keys
#define kShowId @"id"
#define kShowTitle @"title"
#define kShowDescription @"description"
#define kShowHostId @"host_id"
#define kShowBeginDate @"begin_date"
#define kShowEndDate @"end_date"
#define kShowStatus @"status"

#endif
