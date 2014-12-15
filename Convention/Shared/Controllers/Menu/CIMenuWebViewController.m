//
// Created by David Jafari on 12/14/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "CIMenuWebViewController.h"
#import "config.h"
#import "CurrentSession.h"
#import "CINavViewManager.h"

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
        self.navViewManager = [[CINavViewManager alloc] init];
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
            @"q": self.searchQuery,
            kAuthToken: [CurrentSession instance].authToken
    }]];
    NSURLRequest *request = [NSURLRequest requestWithURL:urlWithSearchQuery];
    self.currentUrl = urlWithSearchQuery;
    [self.uiWebView loadRequest:request];
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


@end