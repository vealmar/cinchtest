//
// Created by David Jafari on 12/14/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "CIMenuWebViewController.h"
#import "config.h"
#import "CurrentSession.h"
#import "CINavViewManager.h"
#import "MBProgressHUD.h"

@interface CIMenuWebViewController() <CINavViewManagerDelegate>

@property UIWebView *uiWebView;
@property NSURL *currentUrl;
@property NSString *searchQuery;
@property CINavViewManager *navViewManager;

@end

@implementation CIMenuWebViewController

-(id)init {
    self = [super init];
    if (self) {
        self.searchQuery = @"";
        self.view = self.uiWebView = [[UIWebView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        self.uiWebView.delegate = self;
        self.navViewManager = [[CINavViewManager alloc] init:YES];
        self.navViewManager.delegate = self;
    }
    return self;
}

-(void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navViewManager setupNavBar];
}


-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.uiWebView.loading) {
        [self.uiWebView stopLoading];
    }
}

-(void)navigateTo:(NSURL *)url titled:(NSAttributedString *)title {
    self.navViewManager.title = title;
    NSURL *urlWithSearchQuery = [NSURL URLWithString:[self addQueryStringToUrlString:url.absoluteString withDictionary:@{
            kAuthToken: [CurrentSession instance].authToken
    }]];
    NSURLRequest *request = [NSURLRequest requestWithURL:urlWithSearchQuery];
    self.currentUrl = url;
    [self.uiWebView loadRequest:request];
}

-(void)issueSearchQuery:(NSString *)query {
    if (self.currentUrl && ![self.searchQuery isEqualToString:query]) {
        NSURL *urlWithSearchQuery = [NSURL URLWithString:[self addQueryStringToUrlString:self.currentUrl.absoluteString withDictionary:@{
                @"q": query,
                kAuthToken: [CurrentSession instance].authToken
        }]];
        NSURLRequest *request = [NSURLRequest requestWithURL:urlWithSearchQuery];
        [self.uiWebView loadRequest:request];
        self.searchQuery = query;
    }
}

-(NSString*)urlEscapeString:(NSString *)unencodedString {
    CFStringRef originalStringRef = (__bridge_retained CFStringRef)unencodedString;
    NSString *s = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,originalStringRef, NULL, NULL,kCFStringEncodingUTF8);
    CFRelease(originalStringRef);
    return s;
}

-(NSString*)addQueryStringToUrlString:(NSString *)urlString withDictionary:(NSDictionary *)dictionary {
    NSMutableString *urlWithQuerystring = [[NSMutableString alloc] initWithString:urlString];

    for (id key in dictionary) {
        NSString *keyString = [key description];
        NSString *valueString = [[dictionary objectForKey:key] description];

        if ([urlWithQuerystring rangeOfString:@"?"].location == NSNotFound) {
            [urlWithQuerystring appendFormat:@"?%@=%@", [self urlEscapeString:keyString], [self urlEscapeString:valueString]];
        } else {
            [urlWithQuerystring appendFormat:@"&%@=%@", [self urlEscapeString:keyString], [self urlEscapeString:valueString]];
        }
    }
    return urlWithQuerystring;
}

#pragma mark - NavViewManagerDelegate

- (UINavigationController *)navigationControllerForNavViewManager {
    return self.navigationController;
}

- (UINavigationItem *)navigationItemForNavViewManager {
    return self.navigationItem;
}

- (void)navViewDidSearch:(NSString *)searchTerm inputCompleted:(BOOL)inputCompleted {
    if (inputCompleted) {
        [self issueSearchQuery:searchTerm];
    }
}


#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
    hud.labelText = @"Loading Page...";
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [MBProgressHUD hideHUDForView:self.view animated:NO];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {

}


@end