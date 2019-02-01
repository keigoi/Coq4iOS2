//
//  Worker.h
//  Coq4iOS
//
//  Created by keigoi on 2019/02/02.
//  Copyright © 2019 後藤宗一朗. All rights reserved.
//

#ifndef Worker_h
#define Worker_h

@interface Worker : NSObject {
    NSThread* workerThread;
    NSCondition* queueCondition;
    NSMutableArray* blockQueue;
}
- (void)start;
- (void)enqueue:(void(^)(void)) block;
- (void)stop;
@end

#endif /* Worker_h */
