//
//  LaunchViewController.m
//  Convention
//
//  Created by septerr on 8/10/13.
//  Copyright (c) 2013 MotionMobs. All rights reserved.
//

#import "LaunchViewController.h"
#import "config.h"
#import "SettingsManager.h"
#import "CIViewController.h"
#import "ShowConfigurations.h"
#import "CinchJSONAPIClient.h"

@interface LaunchViewController ()
@property(weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property(weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation LaunchViewController


- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self startSettingsThread];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}


- (void)startSettingsThread {
    self.label.text = @"Loading Configurations";
    if ([self requiredSettingsArePresent]) {
        [self obtainShowConfigurationAndPresentLoginView];
    } else {
        [self updateLabel:@"Some required settings are missing. Please make sure Server and Show are specified in Ci settings."];
        [self stopActivityIndicator];
    }

}


- (void)updateLabel:(NSString *)text {
    self.label.text = text;
}

- (void)stopActivityIndicator {
    [self.activityIndicator stopAnimating];
}

- (void)presentLoginView {
    CIViewController *ciViewController = [[CIViewController alloc] initWithNibName:@"CIViewController_iPad" bundle:nil];
    ciViewController.managedObjectContext = self.managedObjectContext;
    [self presentViewController:ciViewController animated:YES completion:nil];
}

- (BOOL)checkSettings {
    if (![self requiredSettingsArePresent]) {

        return NO;
    }
    [self performSelectorOnMainThread:@selector(updateLabel:) withObject:@"Loading show configurations" waitUntilDone:NO];
    [self obtainShowConfigurationAndPresentLoginView];
}

- (Boolean)requiredSettingsArePresent {
    return [kBASEURL length] > 0 && [ShowID length] > 0;
}

- (void)obtainShowConfigurationAndPresentLoginView {
    [[CinchJSONAPIClient sharedInstance] GET:ConfigUrl parameters:@{} success:^(NSURLSessionDataTask *task, id JSON) {
        NSLog(@"%@", JSON);
        [ShowConfigurations createInstanceFromJson:(NSDictionary *) JSON];
        [self performSelectorOnMainThread:@selector(presentLoginView) withObject:nil waitUntilDone:NO];
    }                                failure:^(NSURLSessionDataTask *task, NSError *error) {
        [self performSelectorOnMainThread:@selector(updateLabel:) withObject:@"Settings seem to be invalid. Please make sure Server and Show specified in Ci settings are correct." waitUntilDone:NO];
        NSLog([error localizedDescription]);
        [self performSelectorOnMainThread:@selector(stopActivityIndicator) withObject:nil waitUntilDone:NO];
    }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
