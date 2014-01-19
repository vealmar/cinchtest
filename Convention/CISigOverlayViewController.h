//
//  CISigOverlayViewController.h
//  Convention
//
//  Created by septerr on 1/16/14.
//  Copyright (c) 2014 Convention Innovations. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SignatureOverlayDelegate <NSObject>
@required
- (void)signatureOverlayDismissed;
@end


@interface CISigOverlayViewController : UIViewController
- (IBAction)cancel:(id)sender;

- (IBAction)swipedRight:(UISwipeGestureRecognizer *)sender;

- (id)initWithDelegate:(id <SignatureOverlayDelegate>)delegate;
@end
