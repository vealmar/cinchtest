//
// Created by septerr on 12/30/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//

#import "SynchronousRequestUtil.h"


@implementation SynchronousRequestUtil {

}
+ (NSDictionary *)sendRequestTo:(NSString *)url error:(NSError **)error {
    NSDictionary *json;
    NSURL *nsUrl = [NSURL URLWithString:url];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:nsUrl];
    NSHTTPURLResponse *responseCode = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&responseCode error:error];
    if (data) {
        NSError *jsonError;
        json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
        if (jsonError) {
            [[[UIAlertView alloc] initWithTitle:@"Error!" message:error ? jsonError.localizedDescription : @"There was a problem processing this request." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    }
    if ([responseCode statusCode] < 200 || [responseCode statusCode] > 299) {
        [[[UIAlertView alloc] initWithTitle:@"Error!" message:error ? (*error).localizedDescription : @"There was a problem processing this request." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
    return json;
}
@end