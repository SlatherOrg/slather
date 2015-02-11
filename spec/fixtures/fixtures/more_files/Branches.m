//
//  Branches.m
//  fixtures
//
//  Created by Julian Krumow on 11.10.14.
//  Copyright (c) 2014 marklarr. All rights reserved.
//

#import "Branches.h"

@implementation Branches

- (void)branches:(BOOL)goIf skipBranches:(BOOL)skipBranches
{
    if (goIf) {
        NSLog(@"foo.");
        
        if (!skipBranches) {
            NSLog(@"not skipped.");
        }
    } else {
        NSLog(@"bar.");
    }
    
    int i = 5;
    if (i == 5) {
        return;
    }
    switch (i) {
        case 0:
            NSLog(@"0");
            break;
            
        case 1:
            NSLog(@"1");
            break;
        case 5:
            NSLog(@"5");
            break;
        default:
            break;
    }
}

@end
