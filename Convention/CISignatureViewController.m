//
// Created by septerr on 1/16/14.
// Copyright (c) 2014 Convention Innovations. All rights reserved.
//

#import "CISignatureViewController.h"
#import "ShowConfigurations.h"
#import "NISignatureView.h"
#import "AFHTTPRequestOperation.h"
#import "CIProductViewControllerHelper.h"
#import "NumberUtil.h"

@interface CISignatureViewController ()
@property(nonatomic, strong) NSNumber *orderId;
@property(nonatomic, strong) NSString *authToken;
@property(nonatomic, strong) CIProductViewControllerHelper *helper;
@property(nonatomic, strong) CISigOverlayViewController *ciSigOverlayViewController;
@end

@implementation CISignatureViewController {

}
- (id)initWithTotal:(NSNumber *)total authToken:(NSString *)authToken orderId:(NSNumber *)orderId andDelegate:(id <SignatureDelegate>)delegate {
    self = [super initWithNibName:@"CISignatureViewController" bundle:nil];
    if (self) {
        self.delegate = delegate;
        self.total = total;
        self.orderId = orderId;
        self.authToken = authToken;
        self.helper = [[CIProductViewControllerHelper alloc] init];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.backgroundImageView.image = [[ShowConfigurations instance] loginScreen];
    self.totalLabel.text = [NumberUtil formatDollarAmount:self.total];
}


- (IBAction)submit:(UIButton *)sender {
    UIImage *signatureImage = [self.signatureView getSignatureImage];
    if (signatureImage) {
        void (^successBlock)(NSURLRequest *, NSHTTPURLResponse *, id) = ^(NSURLRequest *req, NSHTTPURLResponse *response, id JSON) {
            [self signatureCaptured];
        };
        [self.helper sendSignature:signatureImage orderId:self.orderId authToken:self.authToken successBlock:successBlock failureBlock:nil view:self.view];
    } else {
        [self signatureCaptured];
    }
}

- (IBAction)clear:(UIButton *)sender {
    [self.signatureView erase];
}

- (IBAction)back:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)signatureCaptured {
    [self displayOverlayScreen];
}

- (void)displayOverlayScreen {
    self.ciSigOverlayViewController = [[CISigOverlayViewController alloc] initWithDelegate:(id <SignatureOverlayDelegate>) self];
    self.ciSigOverlayViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:self.ciSigOverlayViewController animated:YES completion:nil];
}

- (void)signatureOverlayDismissed {
    [self dismissViewControllerAnimated:YES completion:^{
        [self.delegate signatureViewDismissed];
    }];
}


@end