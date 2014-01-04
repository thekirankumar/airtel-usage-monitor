//
//  IconAnimator.h
//  Airtel Usage Monitor
//
//  Created by Kiran Kumar on 25/12/13.
//  Copyright (c) 2013 Kiran Kumar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IconAnimator : NSObject


- (id)initWithStatusItem:(NSStatusItem *) item;
-(void) startAnimation;
-(void) stopAnimation;
-(void) setPercentage:(int)perc;
@end
