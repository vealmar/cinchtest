//
//  product.m
//  Convention
//
//  Created by Matthew Clark on 4/18/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import "product.h"
#import "config.h"

@implementation product
@synthesize venderID;
@synthesize regPrc;
@synthesize quantity;
@synthesize price;
@synthesize ridx;
@synthesize InvtID;
@synthesize descr;
@synthesize PartNbr;
@synthesize Uom;
@synthesize CaseQty;
@synthesize DirShip;
@synthesize LineNbr;
@synthesize New;
@synthesize Adv;

-(id)copyWithZone:(NSZone *)zone{
    product* them = [[product alloc] init];
    them.venderID = [venderID copy];
    them.regPrc = [regPrc copy];
    them.quantity = [quantity copy];
    them.price = [price copy];
    them.ridx = [ridx copy];
    them.InvtID = [InvtID copy];
    them.descr = [descr copy];
    them.PartNbr = [PartNbr copy];
    them.Uom = [Uom copy];
    them.CaseQty = [CaseQty copy];
    them.DirShip = DirShip;
    them.LineNbr = [LineNbr copy];
    them.New = New;
    them.Adv = Adv;
    return them;
}

-(void)loadDictionary:(NSDictionary*)dict{
    if ([dict objectForKey:kProductIdx]) {
        self.ridx = [[dict objectForKey:kProductIdx] stringValue];
    }
    if ([dict objectForKey:kProductInvtid]) {
        self.InvtID = [dict objectForKey:kProductInvtid];
    }
    if ([dict objectForKey:kProductDescr]) {
        self.descr = [dict objectForKey:kProductDescr];
    }
    if ([dict objectForKey:kProductPartNbr]&&![[dict objectForKey:kProductPartNbr] isKindOfClass:[NSNull class]]) {
        self.PartNbr = [[dict objectForKey:kProductPartNbr] stringValue];
    }
    if ([dict objectForKey:kProductUom]&&![[dict objectForKey:kProductUom] isKindOfClass:[NSNull class]]) {
        self.Uom = [[dict objectForKey:kProductUom] stringValue];
    }
    if ([dict objectForKey:kProductCaseQty]&&![[dict objectForKey:kProductCaseQty] isKindOfClass:[NSNull class]]) {
        self.CaseQty = [[dict objectForKey:kProductCaseQty] stringValue];
    }
    if ([dict objectForKey:kProductDirShip]) {
        self.DirShip = [[dict objectForKey:kProductDirShip] boolValue];
    }
    if ([dict objectForKey:kProductLineNbr]) {
        self.LineNbr = [dict objectForKey:kProductLineNbr];
    }
    if ([dict objectForKey:kProductNew]) {
        self.New = [[dict objectForKey:kProductNew] boolValue];
    }
    if ([dict objectForKey:kProductAdv]) {
        self.Adv = [[dict objectForKey:kProductAdv] boolValue];
    }

    if ([dict objectForKey:kProductRegPrc]&&![[dict objectForKey:kProductRegPrc] isKindOfClass:[NSNull class]]) {
        self.regPrc = [[dict objectForKey:kProductRegPrc] stringValue];
    }
    else {
        self.regPrc = @"0.00";
    }
    self.quantity = @"0";
    self.price = [self.regPrc copy];
}

@end
