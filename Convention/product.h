//
//  product.h
//  Convention
//
//  Created by Matthew Clark on 4/18/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface product : NSObject <NSCopying>
@property (strong, nonatomic) NSString *venderID;
@property (strong, nonatomic) NSString *regPrc;
@property (strong, nonatomic) NSString *quantity;
@property (strong, nonatomic) NSString *price;
@property (strong, nonatomic) NSString *ridx;
@property (strong, nonatomic) NSString *InvtID;
@property (strong, nonatomic) NSString *descr;
@property (strong, nonatomic) NSString *PartNbr;
@property (strong, nonatomic) NSString *Uom;
@property (strong, nonatomic) NSString *CaseQty;
@property BOOL DirShip;
@property (strong, nonatomic) NSString *LineNbr;
@property BOOL New;
@property BOOL Adv;

-(void)loadDictionary:(NSDictionary*)dict;

@end
