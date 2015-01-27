//
// Created by septerr on 1/16/14.
// Copyright (c) 2014 Convention Innovations. All rights reserved.
//

#import "CISignatureViewController.h"
#import "ShowConfigurations.h"
#import "NISignatureView.h"
#import "CIProductViewControllerHelper.h"
#import "NumberUtil.h"
#import "OrderManager.h"

@interface CISignatureViewController ()
@property(nonatomic, strong) NSNumber *orderId;
@property(nonatomic, strong) NSString *authToken;
@property(nonatomic, strong) CIProductViewControllerHelper *helper;
@end

@implementation CISignatureViewController {

}
- (id)init {
    self = [super initWithNibName:@"CISignatureViewController" bundle:nil];
    if (self) {
        self.helper = [[CIProductViewControllerHelper alloc] init];
    }
    return self;
}

- (void)reinitWithTotal:(NSNumber *)total authToken:(NSString *)authToken orderId:(NSNumber *)orderId andDelegate:(id <SignatureDelegate>)delegate {
    self.delegate = delegate;
    self.total = total;
    self.orderId = orderId;
    self.authToken = authToken;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.backgroundImageView.image = [[ShowConfigurations instance] loginScreen];
    self.totalLabel.text = [NumberUtil formatDollarAmount:self.total];
}

- (IBAction)submit:(UIButton *)sender {
    @try {
        void (^successBlock)() = ^() {
            [self signatureCaptured];
        };

        [OrderManager syncSignature:self.signatureView orderId:self.orderId showHUDAddedTo:self.view successBlock:successBlock failureBlock:nil];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception occurred: %@, %@", exception, [exception userInfo]);
        NSString *msg = [NSString stringWithFormat:@"There was an error capturing the signature. Please try again. \nError: %@", [exception name]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
}

- (IBAction)clear:(UIButton *)sender {
    [self.signatureView erase];
}

- (IBAction)back:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)signatureCaptured {
    [self.signatureView erase];
    [self.signatureView releaseMemory];
    [self dismissViewControllerAnimated:YES completion:^{
        [self.delegate signatureViewDismissed];
        self.delegate = nil;
    }];
}

@end