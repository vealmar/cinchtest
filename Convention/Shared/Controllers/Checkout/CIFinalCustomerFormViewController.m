//
//  CIFinalCustomerFormViewController.m
//  Convention
//
//  Created by Bogdan Covaci on 31.10.2014.
//  Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Underscore.m/Underscore.h>
#import "CIFinalCustomerFormViewController.h"
#import "ShowConfigurations.h"
#import "SetupInfo.h"
#import "CoreDataManager.h"
#import "Order.h"
#import "CoreDataUtil.h"
#import "CIFinalCustomerInfoViewController.h"
#import "CurrentSession.h"
#import "Order+Extensions.h"
#import "ShowCustomField.h"
#import "UIColor+Boost.h"
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

@interface CIFinalCustomerFormViewController () {
    SetupInfo *authorizedBy;
    NSManagedObjectContext *context;
}

@property CIFinalCustomerFormNavigationViewController *formNavigationController;
@property (strong, nonatomic) UIView *contentView;
@property (strong, nonatomic) XLFormViewController *formController;
@property (strong, nonatomic) XLFormRowDescriptor *authorizedByRow;
@property (strong, nonatomic) XLFormRowDescriptor *notesRow;

@end

@implementation CIFinalCustomerFormViewController

- (id)init {
    self = [super init];
    if (self) {
        self.preferredContentSize = CGSizeMake(400, 600);
    }
    return self;
}
- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 400.0f, 600.0f)];
    self.view.backgroundColor = [UIColor colorWithRed:234.0f/255.0f green:237.0f/255.0f blue:241.0f/255.0f alpha:1.000]; // #eaedf1 234,237,241

//    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 400.0f, 220.0f)];
//    header.backgroundColor = [UIColor whiteColor];
//    UIImageView *headerImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ico-title"]];
//    headerImage.frame = CGRectMake((400.0f - headerImage.image.size.width)/2.0f, 35.0f, headerImage.image.size.width, 73.0);
//    UILabel *headerTitle = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 113.0f, 400.0f, 43.0f)];
//    headerTitle.font = [UIFont regularFontOfSize:24.0];
//    headerTitle.textAlignment = NSTextAlignmentCenter;
//    headerTitle.textColor = [UIColor colorWith256Red:145 green:182 blue:43];
//    headerTitle.text = @"Order Confirmation";
//    UILabel *headerSubtitle = [[UILabel alloc] initWithFrame:CGRectMake(75.0f, 135.0f, 250.0f, 70.0f)];
//    headerSubtitle.font = [UIFont regularFontOfSize:17.0];
//    headerSubtitle.textAlignment = NSTextAlignmentCenter;
//    headerSubtitle.textColor = [UIColor colorWith256Red:155 green:155 blue:155];
//    headerSubtitle.lineBreakMode = NSLineBreakByTruncatingTail;
//    headerSubtitle.numberOfLines = 2;
//    headerSubtitle.text = @"Post-order authorization and detail, record handling information.";
//    [header addSubview:headerImage];
//    [header addSubview:headerTitle];
//    [header addSubview:headerSubtitle];
//    [self.view addSubview:header];

    float w = self.view.frame.size.width;
    float h = self.view.frame.size.height;

    [[UILabel appearanceWhenContainedIn:[CIFinalCustomerFormViewController class], [UITableViewHeaderFooterView class], nil] setFont:[UIFont boldFontOfSize:13.0]];
    [[UILabel appearanceWhenContainedIn:[CIFinalCustomerFormViewController class], [UITableViewHeaderFooterView class], nil] setTextColor:[UIColor whiteColor]];
    [[UILabel appearanceWhenContainedIn:[CIFinalCustomerFormViewController class], [UITableViewHeaderFooterView class], nil] setFont:[UIFont regularFontOfSize:16.0]];

    XLFormDescriptor *formDescriptor = [XLFormDescriptor formDescriptor];
    XLFormSectionDescriptor *section = [XLFormSectionDescriptor formSection];
    section.title = @"Order Details";

    [formDescriptor addFormSection:section];
    self.authorizedByRow = [XLFormRowDescriptor formRowDescriptorWithTag:section.title
                                                                 rowType:XLFormRowDescriptorTypeText
                                                                   title:@"Authorized By"];
    [self.authorizedByRow.cellConfig setObject:[UIFont semiboldFontOfSize:16.0] forKey:@"textLabel.font"];
    [self.authorizedByRow.cellConfig setObject:[UIColor lightGrayColor] forKey:@"textLabel.color"];
    [section addFormRow:self.authorizedByRow];

    Underscore.array([[ShowConfigurations instance] orderCustomFields]).each(^(ShowCustomField *showCustomField) {
        XLFormRowDescriptor *descriptor = nil;
        if (showCustomField.isStringValueType) {
            descriptor = [XLFormRowDescriptor formRowDescriptorWithTag:showCustomField.fieldKey
                                                                                    rowType:XLFormRowDescriptorTypeTextView
                                                                                      title:showCustomField.label];
        } else if (showCustomField.isEnumValueType) {
            descriptor = [XLFormRowDescriptor formRowDescriptorWithTag:showCustomField.fieldKey
                                                                                    rowType:XLFormRowDescriptorTypeSelectorPush
                                                                                      title:showCustomField.label];
            descriptor.selectorOptions = Underscore.array(showCustomField.enumValues).map(^id(NSString *enumValue) {
                return [XLFormOptionsObject formOptionsObjectWithValue:enumValue displayText:enumValue];
            }).unwrap;
            descriptor.required = YES;
        } else if (showCustomField.isDateValueType) {
            descriptor = [XLFormRowDescriptor formRowDescriptorWithTag:showCustomField.fieldKey
                                                                                    rowType:XLFormRowDescriptorTypeDate
                                                                                      title:showCustomField.label];
        } else if (showCustomField.isBooleanValueType) {
            descriptor = [XLFormRowDescriptor formRowDescriptorWithTag:showCustomField.fieldKey
                                                                                    rowType:XLFormRowDescriptorTypeBooleanSwitch
                                                                                      title:showCustomField.label];
        } else {
            NSLog(@"Unsupported Custom Field Value Type.");
        }

        if (descriptor) {
            [descriptor.cellConfig setObject:[UIFont semiboldFontOfSize:16.0] forKey:@"textLabel.font"];
            [descriptor.cellConfig setObject:[UIColor lightGrayColor] forKey:@"textLabel.color"];
            [section addFormRow:descriptor];
        }
    });

    section = [XLFormSectionDescriptor formSection];
    section.title = @"Additional Information";
    [formDescriptor addFormSection:section];
    self.notesRow = [XLFormRowDescriptor formRowDescriptorWithTag:section.title
                                                          rowType:XLFormRowDescriptorTypeTextView];
    [self.notesRow.cellConfig setObject:@"Order Notes" forKey:@"textView.placeholder"];
    [section addFormRow:self.notesRow];

    self.formController = [[XLFormViewController alloc] initWithForm:formDescriptor];
    self.formController.view.frame = CGRectMake(0, 0, w, h - 60);
    self.formController.view.backgroundColor = [UIColor clearColor];
    self.formController.tableView.backgroundColor = [UIColor clearColor];
    self.formController.navigationItem.title = @"Order Details";

    self.formNavigationController = [[CIFinalCustomerFormNavigationViewController alloc] initWithRootViewController:self.formController];
    self.formNavigationController.view.frame = CGRectMake(0, 0, w, h - 60);
    [self.view addSubview:self.formNavigationController.view];

    UIView *buttonsView = [[UIView alloc] initWithFrame:CGRectMake(0.0, self.formController.view.frame.origin.y + self.formController.view.frame.size.height, 400.0f, 60.0f)];
    buttonsView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:buttonsView];

    UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(15.0f, (buttonsView.frame.size.height - 30.0f)/2.0f, 75.0, 30.0)];
    cancelButton.userInteractionEnabled = YES;
    cancelButton.layer.borderColor = [UIColor colorWithRed:194.0f/255.0f green:200.0f/255.0f blue:207.0f/255.0f alpha:1.000].CGColor; // #c2c8cf 194 200 207
    cancelButton.backgroundColor = [UIColor colorWithRed:234.0f/255.0f green:237.0f/255.0f blue:241.0f/255.0f alpha:1.000]; // #eaedf1 234,237,241
    cancelButton.layer.borderWidth = 1.0f;
    cancelButton.layer.cornerRadius = 3.0f;
    NSDictionary *cancelButtonTitleAttributes = @{
            NSFontAttributeName: [UIFont regularFontOfSize:13],
            NSForegroundColorAttributeName: [UIColor colorWithRed:194.0f/255.0f green:200.0f/255.0f blue:207.0f/255.0f alpha:1.000]
    };
    [cancelButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"Cancel" attributes:cancelButtonTitleAttributes] forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchDown];
    [buttonsView addSubview:cancelButton];

    UIButton *submitButton = [[UIButton alloc] initWithFrame:CGRectMake(buttonsView.frame.size.width - 15.0f - 75.0f, (buttonsView.frame.size.height - 30.0f)/2.0f, 75.0, 30.0)];
    submitButton.userInteractionEnabled = YES;
    submitButton.layer.borderColor = [UIColor colorWithRed:0.902 green:0.494 blue:0.129 alpha:1.000].CGColor;
    submitButton.backgroundColor = [UIColor colorWithRed:0.922 green:0.647 blue:0.416 alpha:1.000];
    submitButton.layer.borderWidth = 1.0f;
    submitButton.layer.cornerRadius = 3.0f;
    NSDictionary *submitButtonTitleAttributes = @{
            NSFontAttributeName: [UIFont regularFontOfSize:13],
            NSForegroundColorAttributeName: [UIColor whiteColor]
    };
    [submitButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"Submit" attributes:submitButtonTitleAttributes] forState:UIControlStateNormal];
    [submitButton addTarget:self action:@selector(submit:) forControlEvents:UIControlEventTouchDown];
    [buttonsView addSubview:submitButton];

    context = [CurrentSession mainQueueContext];
    authorizedBy = [CoreDataManager getSetupInfo:@"authorizedBy"];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    self.view.superview.bounds = CGRectMake(0, 0, 400, 600);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.authorizedByRow.value = self.order && self.order.authorizedBy ? self.order.authorizedBy : authorizedBy ? authorizedBy.value : @"";
    self.notesRow.value = self.order && self.order.notes ? self.order.notes : @"";

    Underscore.array([[ShowConfigurations instance] orderCustomFields]).each(^(ShowCustomField *showCustomField) {
        XLFormRowDescriptor *descriptor = [self.formController.form formRowWithTag:showCustomField.fieldKey];
        NSString *value = [self.order customFieldValueFor:showCustomField];
        if (showCustomField.isEnumValueType) {
            if (value) descriptor.value = [XLFormOptionsObject formOptionsObjectWithValue:value displayText:value];
            else descriptor.value = descriptor.selectorOptions.firstObject;
        } else {
            descriptor.value = value ? value : @"";
        }
    });
    
    [self.formController.tableView reloadData];
}

- (void)back:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)submit:(id)sender {
    NSString *authorizedByText = self.authorizedByRow.value ? self.authorizedByRow.value : @"";
    [self updateSetting:@"authorizedBy" newValue:authorizedByText setupInfo:authorizedBy];

    self.order.notes = self.notesRow.value;
    self.order.authorizedBy = self.authorizedByRow.value;

    Underscore.array([[ShowConfigurations instance] orderCustomFields]).each(^(ShowCustomField *showCustomField) {
        id value = self.formController.form.formValues[showCustomField.fieldKey];
        if (showCustomField.isEnumValueType) {
            value = [(XLFormOptionsObject*)value displayText];
        }
        [self.order setCustomFieldValueFor:showCustomField value:(NSString *)value];
    });

    [self.delegate submit:nil];
    [self.delegate dismissFinalCustomerViewController];
}

- (void)updateSetting:(NSString *)itemName newValue:(NSString *)newValue setupInfo:(SetupInfo *)setupInfo {
    if ([newValue length] > 0) {
        if (setupInfo == nil) {
            setupInfo = (SetupInfo *) [[CoreDataUtil sharedManager] createNewEntity:@"SetupInfo"];
            setupInfo.item = itemName;
        }
        if (!setupInfo.value || ![setupInfo.value isEqualToString:newValue]) {
            setupInfo.value = newValue;
            NSError *error;
            [context save:&error];
        }
    }
}

@end
