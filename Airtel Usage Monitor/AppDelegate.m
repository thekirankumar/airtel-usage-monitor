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
#import "IconAnimator.h"
#import "LaunchAtLoginController.h"
@implementation AppDelegate
{
    IconAnimator * animator;
    NSMenuItem * refreshItem;

    NSMenuItem * percentageItem;
    NSMenuItem * usageBandwidthItem;

    NSMenuItem * remainingBandwidthItem;

    NSMenuItem * totalBandwidthItem;

    NSMenuItem * daysRemainingItem;
    NSMenuItem * dslNumberItem;
    NSMenuItem * exitItem;
    NSMenuItem * aboutItem;
    NSMenuItem * errorItem;
}
@synthesize  statusItem;

NSString *const SERVER_URL = @"http://122.160.230.125:8080/gbod/gb_on_demand.do";

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self initialize];
    [self checkReachability];
}

-(void)initialize
{
    LaunchAtLoginController *launchController = [[LaunchAtLoginController alloc] init];
    [launchController setLaunchAtLogin:YES];
    
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    
    self.statusItem = [bar statusItemWithLength:NSVariableStatusItemLength];
    [self.statusItem setHighlightMode:YES];
    animator = [[IconAnimator alloc] initWithStatusItem:self.statusItem];
    NSMenu * menu = [[NSMenu alloc] init];
    [menu setAutoenablesItems:NO];

    
    errorItem = [[NSMenuItem alloc]initWithTitle:@"Error" action:@selector(menuItemClick:) keyEquivalent:@""];
    [errorItem setEnabled:NO];
    
    refreshItem = [[NSMenuItem alloc]initWithTitle:@"Refresh" action:@selector(menuItemClick:) keyEquivalent:@""];
    [refreshItem setImage:[NSImage imageNamed:@"refresh"]];
    [refreshItem setTag:1];
    [refreshItem setEnabled:YES];
    exitItem = [[NSMenuItem alloc]initWithTitle:@"Exit" action:@selector(menuItemClick:) keyEquivalent:@""];
    [exitItem setTag:0];
    [exitItem setEnabled:YES];
    
    aboutItem = [[NSMenuItem alloc]initWithTitle:@"About Airtel Usage Monitor for Mac v1.0" action:@selector(menuItemClick:) keyEquivalent:@""];
    [aboutItem setTag:2];

    [aboutItem setEnabled:YES];

    
    percentageItem = [[NSMenuItem alloc]initWithTitle:@"" action:@selector(menuItemClick:) keyEquivalent:@""];
    [percentageItem setEnabled:NO];
    
    
    remainingBandwidthItem = [[NSMenuItem alloc] initWithTitle:@"" action:@selector(menuItemClick:) keyEquivalent:@""];
    [remainingBandwidthItem setEnabled:NO];
    
    usageBandwidthItem = [[NSMenuItem alloc] initWithTitle:@"" action:@selector(menuItemClick:) keyEquivalent:@""];
    [usageBandwidthItem setEnabled:NO];
    
    totalBandwidthItem = [[NSMenuItem alloc] initWithTitle:@"" action:@selector(menuItemClick:) keyEquivalent:@""];
    [totalBandwidthItem setEnabled:NO];
    
    daysRemainingItem = [[NSMenuItem alloc] initWithTitle:@"" action:@selector(menuItemClick:) keyEquivalent:@""];
    [daysRemainingItem setEnabled:NO];
   
    dslNumberItem = [[NSMenuItem alloc] initWithTitle:@"" action:@selector(menuItemClick:) keyEquivalent:@""];
    [dslNumberItem setEnabled:NO];
    
    
    [self.statusItem setMenu:menu];
    
    [self.statusItem.menu removeAllItems];
    [self createCommonStartMenu];
    [errorItem setTitle:@"Loading ..."];
    [self.statusItem.menu addItem:errorItem];
    [self createCommonEndMenu];
    
    
}

-(void)reportError:(NSString *)error
{
    [animator stopAnimation];
    [self.statusItem.menu removeAllItems];
    
    [self createCommonStartMenu];
    
    [errorItem setTitle:error];
    [self.statusItem.menu addItem:errorItem];
    [self createCommonEndMenu];
}

-(void)menuItemClick:(NSMenuItem *)item
{
    if(item.tag == 1)
    {
        [self startWithDelay];
    }
    else if(item.tag == 0)
    {
        [[NSApplication sharedApplication] terminate:nil];
    }
    else if(item.tag == 2)
    {
        NSURL *url = [NSURL URLWithString:@"http://thekirankumar.com/?ref=airtelusagemonitor"];
        if( ![[NSWorkspace sharedWorkspace] openURL:url] )
            NSLog(@"Failed to open url: %@",[url description]);
    }
}

-(void) start
{
    NSURL *url = [NSURL URLWithString:SERVER_URL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:5.0];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:request];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self parse:operation.responseString];
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error){
        [self reportError:@"Error : This app only works on Airtel Broadband."];
        
    }];
    
    [operation start];
}

-(void) parse:(NSString *)response
{
    NSError * error;
    HTMLParser *parser = [[HTMLParser alloc] initWithString:response error:&error];
    
    if(error)
    {
        [self reportError:@"Parsing error"];
        
        
    }
    else
    {
        
        HTMLNode *bodyNode = [parser body];
        HTMLNode *div = [[bodyNode findChildrenWithAttribute:@"class" matchingName:@"content-data" allowPartial:YES] objectAtIndex:0];
        NSArray * li = [div findChildTags:@"li"];
        HTMLNode * dslNumberNode = [li objectAtIndex:0];
        HTMLNode * balanceNode = [li objectAtIndex:1];
        HTMLNode * totalNode = [li objectAtIndex:2];
        HTMLNode * daysLeftNode = [li objectAtIndex:3];
        
        NSLog(@"response %@",[div rawContents]);
        NSString * balance = [self getUsage:[balanceNode contents]];
        NSString * total = [self getUsage:[totalNode contents]];
        if(balance!=nil && total!=nil && [balance length]>0 && [total length]>0)
        {
            float balanceFloat = [balance floatValue];
            float totalFloat = [total floatValue];
            float usedFloat = totalFloat - balanceFloat;
            float percentage = (balanceFloat/totalFloat)*100;
            [animator stopAnimation];
            [animator setPercentage:percentage];
            
            [self.statusItem.menu removeAllItems];
            [self.statusItem setTitle:nil];
            
            [self createCommonStartMenu];
            
            
            NSString * bandwidthString = [NSString stringWithFormat:@"%0.0f%% of bandwidth remaining", percentage];
            [percentageItem setTitle:bandwidthString];
            [self.statusItem.menu addItem:percentageItem];
            [self.statusItem.menu addItem:[NSMenuItem separatorItem]];

            [dslNumberItem setTitle:[dslNumberNode contents]];
            [self.statusItem.menu addItem:dslNumberItem];
         airt
            
            NSString * usageString = [NSString stringWithFormat:@"Usage : %0.2f GB", usedFloat];
            [usageBandwidthItem setTitle:usageString];
            [self.statusItem.menu addItem:usageBandwidthItem];
            
            NSString * balanceString = [NSString stringWithFormat:@"Remaining : %@", balance];
            [remainingBandwidthItem setTitle:balanceString];
            [self.statusItem.menu addItem:remainingBandwidthItem];
            
            NSString * totalString = [NSString stringWithFormat:@"Limit : %@", total];
            [totalBandwidthItem setTitle:totalString];
            [self.statusItem.menu addItem:totalBandwidthItem];
            
            [daysRemainingItem setTitle:[daysLeftNode contents]];
            [self.statusItem.menu addItem:daysRemainingItem];
            
            [self createCommonEndMenu];
            
            
        }
        else
        {
            [self reportError:@"Error in fetching"];
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

-(void) startWithDelay
{
    [animator startAnimation];
    [self performSelector:@selector(start) withObject:nil afterDelay:1.0];
}

- (void)checkReachability {
    Reachability* reach = [Reachability reachabilityForInternetConnection];
    reach.reachableBlock = ^(Reachability*reach)
    {
        NSLog(@"Network reachable!");
        [self performSelectorOnMainThread:@selector(startWithDelay) withObject:nil waitUntilDone:NO];
    };
    
    reach.unreachableBlock = ^(Reachability*reach)
    {
        NSLog(@"Network unreachable!");
        [animator stopAnimation];
    };
    if([reach isReachable])
    {
        [self performSelectorOnMainThread:@selector(startWithDelay) withObject:nil waitUntilDone:NO];

    }
    
    [reach startNotifier];
    
}


-(void)createCommonEndMenu
{
    [self.statusItem.menu addItem:[NSMenuItem separatorItem]];
    [self.statusItem.menu addItem:aboutItem];
    [self.statusItem.menu addItem:exitItem];
}
-(void)createCommonStartMenu
{
    [self.statusItem.menu addItem:refreshItem];
    [self.statusItem.menu addItem:[NSMenuItem separatorItem]];
}



@end
