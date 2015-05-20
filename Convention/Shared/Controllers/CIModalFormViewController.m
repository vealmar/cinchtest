//
// Created by David Jafari on 2/16/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import "CIModalFormViewController.h"
#import "CIButton.h"
#import "ThemeUtil.h"

@interface CIFinalCustomerFormNavigationViewController : UINavigationController

@end

@implementation CIFinalCustomerFormNavigationViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setTintColor:[ThemeUtil orangeColor]];
}

@end

@interface CIModalFormViewController()

@property NSString *title;
@property CIFinalCustomerFormNavigationViewController *formNavigationController;
@property (strong, nonatomic) UITapGestureRecognizer *outsideTapRecognizer;

@end

@implementation CIModalFormViewController

- (id)initWithTitle:(NSString *)title {
    self = [super init];
    if (self) {
        self.title = title;
        self.preferredContentSize = CGSizeMake(400, 600);
    }
    return self;
}

- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 400.0f, 600.0f)];
    self.view.backgroundColor = [UIColor colorWithRed:234.0f/255.0f green:237.0f/255.0f blue:241.0f/255.0f alpha:1.000]; // #eaedf1 234,237,241

    float w = self.view.frame.size.width;
    float h = self.view.frame.size.height;

    [[UILabel appearanceWhenContainedIn:[CIModalFormViewController class], [UITableViewHeaderFooterView class], nil] setFont:[UIFont boldFontOfSize:13.0]];
    [[UILabel appearanceWhenContainedIn:[CIModalFormViewController class], [UITableViewHeaderFooterView class], nil] setTextColor:[UIColor whiteColor]];
    [[UILabel appearanceWhenContainedIn:[CIModalFormViewController class], [UITableViewHeaderFooterView class], nil] setFont:[UIFont regularFontOfSize:16.0]];

    XLFormDescriptor *formDescriptor = [XLFormDescriptor formDescriptor];
    [self addSections:formDescriptor];

    self.formController = [[XLFormViewController alloc] initWithForm:formDescriptor];
    self.formController.view.frame = CGRectMake(0, 0, w, h - 60);
    self.formController.view.backgroundColor = [UIColor clearColor];
    self.formController.tableView.backgroundColor = [UIColor clearColor];
    self.formController.navigationItem.title = self.title;

    self.formNavigationController = [[CIFinalCustomerFormNavigationViewController alloc] initWithRootViewController:self.formController];
    self.formNavigationController.view.frame = CGRectMake(0, 0, w, h - 60);
    [self.view addSubview:self.formNavigationController.view];

    UIView *buttonsView = [[UIView alloc] initWithFrame:CGRectMake(0.0, self.formController.view.frame.origin.y + self.formController.view.frame.size.height, 400.0f, 60.0f)];
    buttonsView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:buttonsView];

    UIButton *cancelButton = [[CIButton alloc] initWithOrigin:CGPointMake(15.0f, (buttonsView.frame.size.height - 30.0f)/2.0f)
                                                        title:@"Cancel"
                                                         size:CIButtonSizeSmall
                                                        style:CIButtonStyleCancel];
    [cancelButton addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchDown];
    [buttonsView addSubview:cancelButton];

    UIButton *submitButton = [[CIButton alloc] initWithOrigin:CGPointMake(buttonsView.frame.size.width - 15.0f - 75.0f, (buttonsView.frame.size.height - 30.0f)/2.0f)
                                                        title:@"Submit"
                                                         size:CIButtonSizeSmall
                                                        style:CIButtonStyleNeutral];
    [submitButton addTarget:self action:@selector(submit:) forControlEvents:UIControlEventTouchDown];
    [buttonsView addSubview:submitButton];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self.view.window removeGestureRecognizer:self.outsideTapRecognizer];
    self.outsideTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapBehind:)];
    [self.outsideTapRecognizer setNumberOfTapsRequired:1];
    self.outsideTapRecognizer.cancelsTouchesInView = NO;
    self.outsideTapRecognizer.delegate = self;
    [self.view.window addGestureRecognizer:self.outsideTapRecognizer];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.view.window removeGestureRecognizer:self.outsideTapRecognizer];
    self.outsideTapRecognizer = nil;
}

- (void)handleTapBehind:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        CGPoint l = [sender locationInView:self.view];

        if (![self.view pointInside:l withEvent:nil]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self dismissViewControllerAnimated:YES completion:nil];
            });
        }
    }
}

- (void)addSections:(XLFormDescriptor *)formDescriptor {

}

- (void)setDefaultStyle:(XLFormRowDescriptor *)descriptor {
    if (descriptor) {
        [descriptor.cellConfig setObject:[UIFont semiboldFontOfSize:16.0] forKey:@"textLabel.font"];
        [descriptor.cellConfig setObject:[UIColor lightGrayColor] forKey:@"textLabel.color"];
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    self.view.superview.bounds = CGRectMake(0, 0, 400, 600);
}

- (void)back:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)submit:(id)sender {
    [self back:sender];
}

#pragma mark - UIGestureRecognizer Delegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

@end