//
// Created by septerr on 1/16/14.
// Copyright (c) 2014 Convention Innovations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CISigOverlayViewController.h"

@class NISignatureView;

@protocol SignatureDelegate <NSObject>
@required
- (void)displayOverlayScreen;
@end

@interface CISignatureViewController : UIViewController
@property(weak, nonatomic) IBOutlet UILabel *totalLabel;

- (IBAction)back:(UIButton *)sender;

@property(weak, nonatomic) IBOutlet UIImageView *backgroundImageView;

- (id)initWithTotal:(NSNumber *)total authToken:(NSString *)authToken orderId:(NSNumber *)orderId andDelegate:(id <SignatureDelegate>)delegate;

- (IBAction)submit:(UIButton *)sender;

- (IBAction)clear:(UIButton *)sender;

@property(weak, nonatomic) IBOutlet NISignatureView *signatureView;
@property(strong, nonatomic) NSNumber *total;
@property(nonatomic, assign) id <SignatureDelegate> delegate;
@end