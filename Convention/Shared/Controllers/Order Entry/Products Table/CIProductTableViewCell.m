//
// Created by David Jafari on 12/21/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Underscore.m/Underscore.h>
#import "CIProductTableViewCell.h"
#import "CITableViewColumns.h"
#import "CITableViewColumn.h"
#import "CITableViewColumnView.h"
#import "CIQuantityColumnView.h"
#import "Product.h"
#import "ProductCellDelegate.h"
#import "CurrentSession.h"
#import "Order.h"
#import "Order+Extensions.h"
#import "Cart+Extensions.h"
#import "CIShowPriceColumnView.h"
#import "UITextField+BlocksKit.h"
#import "ShowConfigurations.h"
#import "NotificationConstants.h"
#import "ThemeUtil.h"

@interface CIProductTableViewCell()

@property id<ProductCellDelegate> delegate;
@property Cart *cart;
@property UIColor *lastStripeColor;

@end

@implementation CIProductTableViewCell

-(id)prepareForDisplay:(CITableViewColumns *)columns delegate:(id<ProductCellDelegate>)delegate {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onCartQuantityChange:) name:CartQuantityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onCartSelection:) name:CartSelectionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onCartDeselection:) name:CartDeselectionNotification object:nil];

    self.delegate = delegate;
    return [super prepareForDisplay:columns];
}


-(void)renderColumn:(CITableViewColumnView *)columnView rowData:(id)rowData{
    Order *order = [self.delegate currentOrderForCell];
    Cart *cart = self.cart = [order findCartForProductId:((Product *) rowData).productId];

    if ([columnView isKindOfClass:[CIQuantityColumnView class]]) {
        [((CIQuantityColumnView *) columnView) render:rowData cart:cart];
    } else if ([columnView isKindOfClass:[CIShowPriceColumnView class]]) {
        [((CIShowPriceColumnView *) columnView) render:rowData cart:cart];
    } else {
        [columnView render:rowData];
    }
}

-(CITableViewColumnView *)viewForColumn:(CITableViewColumn *)column frame:(CGRect)frame {
    if (ColumnTypeCustom == column.columnType && [CIQuantityColumnView class] == [column.options objectForKey:ColumnOptionCustomTypeClass]) {
        CIQuantityColumnView *view = [[CIQuantityColumnView alloc] initColumn:column frame:frame];

        __weak CIProductTableViewCell *weakSelf = self;
//        [view bk_whenTapped:^{
//            [weakSelf.delegate QtyTouchForIndex:((Product *) weakSelf.rowData).productId];
//        }];

        [view.quantityTextField setBk_shouldBeginEditingBlock:^BOOL(UITextField *field) {
            bool liShipDates = [ShowConfigurations instance].isLineItemShipDatesType;
            if (liShipDates) [weakSelf.delegate QtyTouchForIndex:((Product *) weakSelf.rowData).productId];
            return !liShipDates;
        }];
        [view.quantityTextField setBk_didEndEditingBlock:^(UITextField *field) {
            Order *order = [weakSelf.delegate currentOrderForCell];
            Cart *cart = [order findOrCreateCartForId:((Product *) weakSelf.rowData).productId context:[CurrentSession instance].managedObjectContext];
            [cart setQuantity:[field.text intValue]];
        }];

        return view;
    } else if (ColumnTypeCustom == column.columnType && [CIShowPriceColumnView class] == [column.options objectForKey:ColumnOptionCustomTypeClass]) {
        CIShowPriceColumnView *view = [[CIShowPriceColumnView alloc] initColumn:column frame:frame];

        __weak CIProductTableViewCell *weakSelf = self;
        [view.editablePriceTextField setBk_didEndEditingBlock:^(UITextField *field) {
            [weakSelf.delegate ShowPriceChange:[field.text doubleValue] productId:((Product *) weakSelf.rowData).productId];
        }];

        return view;
    } else {
        return [super viewForColumn:column frame:frame];
    }
}

- (void)updateRowHighlight:(NSIndexPath *)indexPath {
    if (indexPath) {
        self.lastStripeColor = indexPath.row % 2 == 1 ? [ThemeUtil tableAltRowColor] : [UIColor whiteColor];
    }

    [self unhighlightColumns];
    if (self.cart && self.cart.totalQuantity > 0) {
        self.backgroundColor = [ThemeUtil greenColor];
        [self highlightColumns];
    } else if (self.selected) {
        self.backgroundColor = [ThemeUtil darkBlueColor];
        [self highlightColumns];
    } else {
        self.backgroundColor = self.lastStripeColor;
    }
}

- (void)unhighlightColumns {
    Underscore.array(self.cellViews).each(^(CITableViewColumnView *column) {
        [column unhighlight];
    });
}

- (void)highlightColumns {
    Underscore.array(self.cellViews).each(^(CITableViewColumnView *column) {
        [column highlight: @{
                NSFontAttributeName: [UIFont semiboldFontOfSize:14],
                NSForegroundColorAttributeName: [UIColor whiteColor]
        }];
    });
}

- (void)onCartQuantityChange:(NSNotification *)notification {
    Cart *cart = (Cart *) notification.object;
    NSNumber *productId = ((Product *) self.rowData).productId;
    if (productId && cart.cartId && [cart.cartId isEqualToNumber:productId]) {
        self.cart = cart;
        [self updateRowHighlight:nil];
        Underscore.array(self.cellViews).each(^(CITableViewColumnView *view) {
            if ([view isKindOfClass:[CIQuantityColumnView class]]) {
                [((CIQuantityColumnView *) view) updateQuantity:cart];
            }
        });
    }
}

- (void)onCartSelection:(NSNotification *)notification {
    Cart *cart = (Cart *) notification.object;
    NSNumber *productId = ((Product *) self.rowData).productId;
    if (productId && cart.cartId && [cart.cartId isEqualToNumber:productId]) {
        self.cart = cart;
        self.selected = YES;
        [self updateRowHighlight:nil];
    }
}

- (void)onCartDeselection:(NSNotification *)notification {
    Cart *cart = (Cart *) notification.object;
    NSNumber *productId = ((Product *) self.rowData).productId;
    if (productId && cart.cartId && [cart.cartId isEqualToNumber:productId]) {
        self.cart = cart;
        self.selected = NO;
        [self updateRowHighlight:nil];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



@end