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
#import "CIShowPriceColumnView.h"
#import "ShowConfigurations.h"
#import "NotificationConstants.h"
#import "ThemeUtil.h"
#import "LineItem.h"
#import "Order+Extensions.h"
#import "LineItem+Extensions.h"
#import "CIProductDescriptionColumnView.h"
#import "OrderManager.h"
#import "NumberUtil.h"

@interface CIProductTableViewCell()

@property id<ProductCellDelegate> productCellDelegate;
@property UIColor *lastStripeColor;
@property BOOL initialized;

@end

@implementation CIProductTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onCartQuantityChange:) name:LineQuantityChangedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onCartSelection:) name:LineSelectionNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onCartDeselection:) name:LineDeselectionNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProductsReturn:) name:ProductSelectionCompleteNotification object:nil];
    }

    return self;
}

-(id)prepareForDisplay:(CITableViewColumns *)columns productCellDelegate:(id<ProductCellDelegate>)productCellDelegate {
    self.productCellDelegate = productCellDelegate;
    return [super prepareForDisplay:columns];
}

-(id)render:(id)rowData lineItem:(LineItem *)lineItem {
    self.lineItem = lineItem;
    return [super render:rowData];
}

-(void)renderColumn:(CITableViewColumnView *)columnView rowData:(id)rowData{
    @try {
        if ([columnView isKindOfClass:[CIQuantityColumnView class]]) {
            [((CIQuantityColumnView *) columnView) render:rowData lineItem:self.lineItem];
        } else if ([columnView isKindOfClass:[CIShowPriceColumnView class]]) {
            [((CIShowPriceColumnView *) columnView) render:rowData lineItem:self.lineItem];
        } else if ([columnView isKindOfClass:[CIProductDescriptionColumnView class]]) {
            [((CIProductDescriptionColumnView *) columnView) render:rowData lineItem:self.lineItem];
        } else {
            [columnView render:rowData];
        }
    }
    @catch (NSException *e) {
        if ([NSObjectInaccessibleException isEqualToString:e.name]) {
            // product may be deleted during a refresh and be inaccessible until updated
            NSLog(@"Object could not be returned from fault. Products are likely being reloaded.");
        }
    }
}

-(CITableViewColumnView *)viewForColumn:(CITableViewColumn *)column frame:(CGRect)frame {
    __weak CIProductTableViewCell *weakSelf = self;

    if (ColumnTypeCustom == column.columnType && [CIQuantityColumnView class] == [column.options objectForKey:ColumnOptionCustomTypeClass]) {
        CIQuantityColumnView *view = [[CIQuantityColumnView alloc] initColumn:column frame:frame];

        [view.quantityTextField setBk_shouldBeginEditingBlock:^BOOL(UITextField *field) {
            bool liShipDates = [ShowConfigurations instance].isLineItemShipDatesType;
            if (liShipDates) [weakSelf.productCellDelegate quantityWillBeginEditing:((Product *) weakSelf.rowData).productId lineItem:weakSelf.lineItem];
            return !liShipDates;
        }];
        [view.quantityTextField setBk_didEndEditingBlock:^(UITextField *field) {
            Order *order = [weakSelf.productCellDelegate currentOrderForCell];
            if (!weakSelf.lineItem) {
                weakSelf.lineItem = [order createLineForProductId:((Product *) weakSelf.rowData).productId context:[CurrentSession mainQueueContext]];
                [OrderManager saveOrder:order inContext:[CurrentSession mainQueueContext]];
            }
            [weakSelf.lineItem setQuantity:field.text];
        }];

        return view;
    } else if (ColumnTypeCustom == column.columnType && [CIShowPriceColumnView class] == [column.options objectForKey:ColumnOptionCustomTypeClass]) {
        CIShowPriceColumnView *view = [[CIShowPriceColumnView alloc] initColumn:column frame:frame];

        [view.editablePriceTextField setBk_didEndEditingBlock:^(UITextField *field) {
            NSNumber *price = [NumberUtil convertStringToDollars:field.text];
            // immediately set it back in the event the price changed because of a formatting error (needs to be visible)
            field.text = [NumberUtil formatDollarAmount:price];
            
            Order *order = [weakSelf.productCellDelegate currentOrderForCell];
            if (!weakSelf.lineItem) {
                weakSelf.lineItem = [order createLineForProductId:((Product *) weakSelf.rowData).productId context:[CurrentSession mainQueueContext]];
            }
            [weakSelf.lineItem setPrice:price];
            [OrderManager saveOrder:order inContext:[CurrentSession mainQueueContext]];
        }];

        return view;
    } else if (ColumnTypeCustom == column.columnType && [CIProductDescriptionColumnView class] == [column.options objectForKey:ColumnOptionCustomTypeClass]) {
        CIProductDescriptionColumnView *view = [[CIProductDescriptionColumnView alloc] initColumn:column frame:frame];

        [view.editableDescriptionTextField setBk_didEndEditingBlock:^(UITextField *field) {
            Order *order = [weakSelf.productCellDelegate currentOrderForCell];
            if (!weakSelf.lineItem) {
                weakSelf.lineItem = [order createLineForProductId:((Product *) weakSelf.rowData).productId context:[CurrentSession mainQueueContext]];
            }
            weakSelf.lineItem.description1 = field.text;
            [OrderManager saveOrder:order inContext:[CurrentSession mainQueueContext]];
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
    if (self.lineItem && self.lineItem.totalQuantity > 0) {
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
    LineItem *lineItem = (LineItem *) notification.object;
    NSNumber *productId = ((Product *) self.rowData).productId;
    if ((self.lineItem && [self.lineItem.objectID isEqual:lineItem.objectID]) ||
            (!self.lineItem && productId && lineItem.productId && [lineItem.productId isEqualToNumber:productId])) {
        self.lineItem = lineItem;
        [self updateRowHighlight:nil];
        Underscore.array(self.cellViews).each(^(CITableViewColumnView *view) {
            if ([view isKindOfClass:[CIQuantityColumnView class]]) {
                [((CIQuantityColumnView *) view) updateQuantity:lineItem];
            }
        });
    }
}
//
//- (void)onCartPriceChange:(NSNotification *)notification {
//    LineItem *lineItem = (LineItem *) notification.object;
//    NSNumber *productId = ((Product *) self.rowData).productId;
//    if ((self.lineItem && [self.lineItem.objectID isEqual:lineItem.objectID]) ||
//            (!self.lineItem && productId && lineItem.productId && [lineItem.productId isEqualToNumber:productId])) {
//        self.lineItem = lineItem;
//        [self updateRowHighlight:nil];
//        Underscore.array(self.cellViews).each(^(CITableViewColumnView *view) {
//            if ([view isKindOfClass:[CIQuantityColumnView class]]) {
//                [((CIShowPriceColumnView *) view) updatePrice:lineItem];
//            }
//        });
//    }
//}

- (void)onCartSelection:(NSNotification *)notification {
    LineItem *lineItem = (LineItem *) notification.object;
    NSNumber *productId = ((Product *) self.rowData).productId;
    if ((self.lineItem && [self.lineItem.objectID isEqual:lineItem.objectID]) ||
            (!self.lineItem && productId && lineItem.productId && [lineItem.productId isEqualToNumber:productId])) {
        self.lineItem = lineItem;
        self.selected = YES;
        [self updateRowHighlight:nil];
    }
}

- (void)onCartDeselection:(NSNotification *)notification {
    LineItem *lineItem = (LineItem *) notification.object;
    NSNumber *productId = ((Product *) self.rowData).productId;
    if ((self.lineItem && [self.lineItem.objectID isEqual:lineItem.objectID]) ||
            (!self.lineItem && productId && lineItem.productId && [lineItem.productId isEqualToNumber:productId])) {
        self.lineItem = lineItem;
        self.selected = NO;
        [self updateRowHighlight:nil];
    }
}

- (void)onProductsReturn:(NSNotification *)notification {
    if (self.selected) self.selected = NO;
    self.lineItem = nil;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end