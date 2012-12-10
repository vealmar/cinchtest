//
//  PrinterSelectionViewController.h
//  Convention
//
//  Created by Kerry Sanders on 12/9/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UIPrinterSelectedDelegate <NSObject>
@required
-(void)setSelectedPrinter:(NSString *)printer;
@end

@interface PrinterSelectionViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>

@property (strong, nonatomic) NSArray *availablePrinters;
@property (weak, nonatomic) IBOutlet UIPickerView *printerPicker;
@property (nonatomic, assign) id<UIPrinterSelectedDelegate> delegate;

@end
