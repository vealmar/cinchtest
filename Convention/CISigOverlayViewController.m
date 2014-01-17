//
//  CISigOverlayViewController.m
//  Convention
//
//  Created by septerr on 1/16/14.
//  Copyright (c) 2014 Convention Innovations. All rights reserved.
//

#import "CISigOverlayViewController.h"

@interface CISigOverlayViewController ()
@property id <SignatureOverlayDelegate> delegate;
@end

@implementation CISigOverlayViewController


- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [self.delegate signatureOverlayDismissed];
    }];
}

- (IBAction)swipedRight:(UISwipeGestureRecognizer *)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [self.delegate signatureOverlayDismissed];
    }];
}

- (id)initWithDelegate:(id <SignatureOverlayDelegate>)delegate {
    self = [super initWithNibName:@"CISigOverlayViewController" bundle:nil];
    if (self) {
        self.delegate = delegate;
    }
    return self;
}


@end
