//
//  LaunchViewController.m
//  Convention
//
//  Created by septerr on 8/10/13.
//  Copyright (c) 2013 MotionMobs. All rights reserved.
//

#import <netinet/in.h>
#import "LaunchViewController.h"
#import "AFJSONRequestOperation.h"
#import "config.h"
#import "SettingsManager.h"
#import "AFHTTPClient.h"
#import "CIViewController.h"
#import "ShowConfigurations.h"

@interface LaunchViewController ()
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation LaunchViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[SettingsManager sharedManager] refresh]; //User might have left the app to update settings and come back, so we need to make sure we are using latest settings.
    NSThread*settingsThread = [[NSThread alloc] initWithTarget:self
                                                 selector:@selector(checkSettings)
                                                   object:nil];
    [settingsThread start];
    self.label.text = @"Loading Ci settings";
}

- (void) updateLabel:(NSString *)text{
    self.label.text = text;
}

- (void) stopActivityIndicator{
    [self.activityIndicator stopAnimating];
}

- (void) presentLoginView {
    CIViewController *ciViewController  = [[CIViewController alloc] initWithNibName:@"CIViewController_iPad" bundle:nil];
    ciViewController.managedObjectContext = self.managedObjectContext;
    [self presentViewController:ciViewController animated:YES completion:nil];
}

- (void) checkSettings {
    if(![self requiredSettingsArePresent]){
        [self performSelectorOnMainThread:@selector(updateLabel:)withObject:@"Some required settings are missing. Please make sure Server and Show are specified in Ci settings." waitUntilDone:NO];
        [self performSelectorOnMainThread:@selector(stopActivityIndicator)withObject:nil waitUntilDone:NO];
        return;
    }
    [self performSelectorOnMainThread:@selector(updateLabel:)withObject:@"Loading show configurations" waitUntilDone:NO];
    [self obtainShowConfigurationAndPresentLoginView];
}

- (Boolean) requiredSettingsArePresent{
    return [kBASEURL length] > 0 && [ShowID length] > 0;
}

- (void)obtainShowConfigurationAndPresentLoginView {
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:ConfigUrl]];
    void (^successBlock)(NSURLRequest *request , NSHTTPURLResponse *response , id JSON) = ^(NSURLRequest *request , NSHTTPURLResponse *response , id JSON){
        [ShowConfigurations createInstanceFromJson:(NSDictionary *) JSON];
        [self performSelectorOnMainThread:@selector(presentLoginView) withObject:nil waitUntilDone:NO];
    };
    void (^failureBlock)(NSURLRequest *request , NSHTTPURLResponse *response , NSError *error , id JSON) = ^(NSURLRequest *request , NSHTTPURLResponse *response , NSError *error , id JSON){
        [self performSelectorOnMainThread:@selector(updateLabel:)withObject:@"Settings seem to be invalid. Please make sure Server and Show specified in Ci settings are correct." waitUntilDone:NO];
        NSLog([error localizedDescription]);
        [self performSelectorOnMainThread:@selector(stopActivityIndicator)withObject:nil waitUntilDone:NO];
    };
    NSMutableURLRequest *request = [client requestWithMethod:@"GET" path:nil parameters:nil];
    AFJSONRequestOperation *op = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:successBlock failure:failureBlock];
    [op start];
}
@end
