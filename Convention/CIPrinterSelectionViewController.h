//
//  CIPrinterSelectionViewController.h
//  Convention
//
//  Created by Kerry Sanders on 12/8/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UIPrinterSelectedDelegate <NSObject>
@required
-(void)setSelectedPrinter:(NSString *)printer;
@end

@interface CIPrinterSelectionViewController : UIViewController

@property (strong, nonatomic) NSArray *availablePrinters;
@property (weak, nonatomic) IBOutlet UIPickerView *printerPicker;

@property (nonatomic, assign) id<UIPrinterSelectedDelegate> delegate;

@end
