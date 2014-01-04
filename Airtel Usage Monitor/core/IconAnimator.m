//
//  IconAnimator.m
//  Airtel Usage Monitor
//
//  Created by Kiran Kumar on 25/12/13.
//  Copyright (c) 2013 Kiran Kumar. All rights reserved.
//

#import "IconAnimator.h"

@implementation IconAnimator
{
    NSStatusItem * statusItem;
    int currentCounter;
    int maxCounter;
    NSTimer * timer;
}

- (id)initWithStatusItem:(NSStatusItem *) item
{
    self = [super init];
    if (self) {
        statusItem = item;
        maxCounter = 4;
        currentCounter = maxCounter;

    }
    return self;
}

-(void) animate
{
    int perc = currentCounter*100/maxCounter;
    if(currentCounter<=maxCounter && currentCounter>0)
    [self setPercentage:perc];
    currentCounter --;
    if(currentCounter<1)
    {
        currentCounter = maxCounter+3;
    }
}
-(void) startAnimation
{
    if(timer!=nil)
    {
        [self stopAnimation];
    }
    timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(animate) userInfo:nil repeats:YES];

}

-(void) stopAnimation
{
    if(timer!=nil)
    {
        [timer invalidate];
        timer = nil;
        currentCounter = maxCounter;
        [self setPercentage:100];
    }
}

-(void) setPercentage:(int)perc
{
    NSImage * image = [self convertPercentageToImage:perc];
    [statusItem setImage:image];
}

-(void) setError
{
    [statusItem setImage:[NSImage imageNamed:@"error"]];
}

-(NSImage *)convertPercentageToImage:(int)perc
{
    int image;
    if(perc>75)
    {
        image = 4;
    }
    else if(perc>50)
    {
        image = 3;
    }
    else if(perc>25)
    {
        image = 2;
    }
    else if(perc > 10)
    {
        image = 1;
    }
    else
    {
        image = 0;
    }
    NSImage * imageToReturn = [NSImage imageNamed:[NSString stringWithFormat:@"%d",image]];
    return imageToReturn;
}

@end
