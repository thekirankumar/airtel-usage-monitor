//
//  AppDelegate.m
//  Airtel Usage Monitor
//
//  Created by Kiran Kumar on 22/12/13.
//  Copyright (c) 2013 Kiran Kumar. All rights reserved.
//

#import "AppDelegate.h"
#import "AFJSONRequestOperation.h"
#import "HTMLParser.h"
#import "Reachability.h"
@implementation AppDelegate
@synthesize  statusItem;

NSString *const SERVER_URL = @"http://122.160.230.125:8080/gbod/gb_on_demand.do";

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self checkReachability];
}

-(void) start
{
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    self.statusItem = [bar statusItemWithLength:NSVariableStatusItemLength];
    [self.statusItem setTitle:@"Loading..."];
    NSView * statusView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 40, 20)];
    
    NSImage * icon = [NSImage imageNamed:@"4"];
    NSImageView * iconView = [[NSImageView alloc] init];
    [iconView setFrame:CGRectMake(0, 5, 10, 10)];
    [iconView setImage:icon];
    [statusView addSubview:iconView];
    [self.statusItem setImage:icon];
    
    //[self.statusItem setView:statusView];
    NSURL *url = [NSURL URLWithString:SERVER_URL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:5.0];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:request];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self parse:operation.responseString];
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error){
        [self.statusItem setTitle:@"Non airtel BB"];
    }];
    
    [operation start];
}

-(void) parse:(NSString *)response
{
    NSError * error;
    HTMLParser *parser = [[HTMLParser alloc] initWithString:response error:&error];
    
    if(error)
    {
        [self.statusItem setTitle:@"Parsing error"];
        
    }
    else
    {
        
        HTMLNode *bodyNode = [parser body];
        HTMLNode *div = [[bodyNode findChildrenWithAttribute:@"class" matchingName:@"content-data" allowPartial:YES] objectAtIndex:0];
        NSArray * li = [div findChildTags:@"li"];
        HTMLNode * balanceNode = [li objectAtIndex:1];
        HTMLNode * totalNode = [li objectAtIndex:2];
        
        NSLog(@"response %@",[div rawContents]);
        NSString * usage = [self getUsage:[balanceNode contents]];
        NSString * total = [self getUsage:[totalNode contents]];
        if(usage!=nil && total!=nil && [usage length]>0 && [total length]>0)
        {
            float usageFloat = [usage floatValue];
            float totalFloat = [total floatValue];
            float percentage = (usageFloat/totalFloat)*100;
            NSString * title = [NSString stringWithFormat:@"%0.0f %%",percentage];
            [self.statusItem setTitle:title];
        }
        else
        {
            [self.statusItem setTitle:@"Error in fetching"];
        }
       
    }

}

-(NSString *) getUsage:(NSString *)fullString
{
    NSRange searchedRange = NSMakeRange(0, [fullString length]);
    NSString *pattern = @"([\\d\\.].*([MKGT]B))";
    NSError *error = nil;
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern: pattern options:0 error:&error];
    NSArray* matches = [regex matchesInString:fullString options:0 range: searchedRange];
    NSTextCheckingResult* match = [matches objectAtIndex:0];
    NSRange group1 = [match rangeAtIndex:1];
    NSString * finalMatch = [fullString substringWithRange:group1];
    return finalMatch;
                                  
}

- (void)checkReachability {
    [self.statusItem setTitle:@"Checking..."];
    Reachability* reach = [Reachability reachabilityWithHostname:@"www.google.com"];
    reach.reachableBlock = ^(Reachability*reach)
    {
        NSLog(@"Network reachable!");
        [self start];
    };
    
    reach.unreachableBlock = ^(Reachability*reach)
    {
        NSLog(@"Network unreachable!");
    };
    
    [reach startNotifier];
    
}

@end
