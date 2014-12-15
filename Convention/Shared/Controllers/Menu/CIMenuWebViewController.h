//
// Created by David Jafari on 12/14/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CIMenuWebViewController : UIViewController <UIWebViewDelegate>

-(void)navigateTo:(NSURL *)url titled:(NSAttributedString *)title;

@end