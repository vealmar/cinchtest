//
//  vender.h
//  Convention
//
//  Created by Matthew Clark on 4/18/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import <Foundation/Foundation.h>

//{"commodity":false,"company":"AFC","complete":false,"created_at":"2011-12-13T04:50:26Z","dlybill":"4/1/12","email":"afc-agr00601@temp.com","hideshprice":false,"hidewsprice":false,"id":217,"import_id":16,"initial_show":null,"lines":124,"name":"AGRI-SALES","owner":"STEVEM","season":"B","updated_at":"2012-04-20T02:45:13Z","username":"afc-agr00601","vendid":"AGR00601"}

@interface vender : NSObject

@property BOOL commodity;
@property (nonatomic, strong) NSString* company;
@property (nonatomic, strong) NSString* complete;
@property (nonatomic, strong) NSString* created_at;
@property (nonatomic, strong) NSString* dlybill;
@property (nonatomic, strong) NSString* email;
@property BOOL hideshprice;
@property BOOL hidewsprice;
@property long ID;
@property long import_id;
@property (nonatomic, strong) NSString* initial_show;
@property long lines;
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* owner;
@property (nonatomic, strong) NSString* season;
@property (nonatomic, strong) NSString* updated_at;
@property (nonatomic, strong) NSString* username;
@property (nonatomic, strong) NSString* vendid;

-(void)loadDictionary:(NSDictionary*)dict;

@end
