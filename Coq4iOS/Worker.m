//
//  Worker.m
//  Coq4iOS
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Worker.h"




@implementation Worker

- (void) bodyLoop
{
    
    NSThread *currentThread = [NSThread currentThread];
    
    while (1) {
        [queueCondition lock];
        while ([blockQueue count] == 0 && ![currentThread isCancelled]) {
            [queueCondition wait];
        }
        
        if ([currentThread isCancelled]) {
            [queueCondition unlock];
            return;
        }
        
        void (^block)(void) = [blockQueue objectAtIndex:0];
        [blockQueue removeObjectAtIndex:0];
        [queueCondition unlock];
        
        block();
    }
}

- (void) start
{
    workerThread = [[NSThread alloc]
                    initWithTarget:self selector:@selector(bodyLoop) object:nil];
    [workerThread start];
    queueCondition = [[NSCondition alloc] init];
    blockQueue = [[NSMutableArray alloc] init];
}


- (void)enqueue:(void(^)(void)) block
{
    [queueCondition lock];
    {
        [blockQueue addObject:[block copy]];
        [queueCondition signal];
    }
    [queueCondition unlock];
}

- (void)stop
{
    [queueCondition lock];
    {
        [workerThread cancel];
        [queueCondition signal];
    }
    [queueCondition unlock];
}
@end

