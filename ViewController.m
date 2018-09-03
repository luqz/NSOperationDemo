//
//  ViewController.m
//  NSOperationDemo
//
//  Created by luqz on 2018/9/2.
//  Copyright © 2018年 jason. All rights reserved.
//

#import "ViewController.h"

@interface LUOperation : NSOperation

@end

@implementation LUOperation

//重写main方法即可
- (void)main {
    if (!self.cancelled) {
        NSLog(@"customer operation start at: %@", [NSThread currentThread]);
        [NSThread sleepForTimeInterval:2];
        NSLog(@"customer operation finished at: %@", [NSThread currentThread]);
    }
}

@end


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //1. NSOperation对象的创建
    //NSOperation是抽象类，不能直接用来创建对象，需要自定义子类或者使用NSInvocationOperation、NSBlockOperation两个子类来创建对象
    //方法1：自定义子类
//    [self creatOperationByCustomerSubClass];
    //方法2：使用NSInvocationOperation子类
//    [self creatInvocationOperation];

    //方法3：使用NSBlockOperation子类
//    [self creatBlockOperation];
    
    //2. NSOperationQueue对象的创建及加入操作
//    [self creatOperationQueue];
    
    //3. 设置NSOperationQueue
//    [self setOperationQueue];
    //4. 设置NSOperation操作依赖
//    [self setOperation];
    //5. 通过在一个操作中将一个新的操作添加到主队列中以实现与主线程同步
//    [self addOperationToMainQueue];
    //6. 可通过NSLock 对象[[NSLock alloc] init]的 lock 和 unlock方法来保证线程安全
    [self safeForThread];

    
}

- (void)task1 {
    NSLog(@"task1 start at: %@", [NSThread currentThread]);
    [NSThread sleepForTimeInterval:2];
    NSLog(@"task1 finished at: %@", [NSThread currentThread]);
}

- (void)task2 {
    NSLog(@"task2 start at: %@", [NSThread currentThread]);
    [NSThread sleepForTimeInterval:2];
    NSLog(@"task2 finished at: %@", [NSThread currentThread]);
}

- (void)creatOperationByCustomerSubClass {
    //在某个线程中执行
    [NSThread detachNewThreadWithBlock:^{
        NSLog(@"currentThread: %@", [NSThread currentThread]);
        for (NSInteger i = 0; i < 5; i ++) {
            //创建
            LUOperation *customerOperation = [[LUOperation alloc] init];
            //开始执行
            //在当前线程中执行，不会创建新的线程
            [customerOperation start];
        }
    }];

}

- (void)creatInvocationOperation {
    //在某个线程中执行
    [NSThread detachNewThreadWithBlock:^{
        NSLog(@"currentThread: %@", [NSThread currentThread]);
        for (NSInteger i = 0; i < 5; i ++) {
            //创建
            NSInvocationOperation *invocationOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(task1) object:nil];
            //开始执行
            //在当前线程中执行，不会创建新的线程
            [invocationOperation start];
        }
    }];
}

- (void)creatBlockOperation {
    //在某个线程中执行
    [NSThread detachNewThreadWithBlock:^{
        NSLog(@"currentThread: %@", [NSThread currentThread]);
        for (NSInteger i = 0; i < 1; i ++) {
            //创建
            NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
                [self task1];
            }];
            
            //可以继续添加任务
            for (NSInteger j = 0; j < 100; j ++) {
                [blockOperation addExecutionBlock:^{
                    [self task2];
                }];
            }
            
            //开始执行
            //只有创建时的一个任务，不再添加后续任务时，在当前线程中执行，不会创建新的线程
            //添加多个任务后，所有block会在多个线程内执行，第一个block内的任务也不一定在当前线程执行了
            //当添加任务数量在100时，在iPhone 6s真机上只有两个轮流执行，在iPhone 6s模拟器上有9个线程轮流执行
            [blockOperation start];
            
            
            //当添加任务数量在100时，在iPhone 6s真机上只有大约65个线程异步执行，在实际场景中（操作耗费时间，而不是简单的让线程sleep），与上方的两个线程比较，哪个更高效呢？
//            for (NSInteger j = 0; j < 100; j ++) {
//                dispatch_async(queue, ^{
//                    [self task2];
//                });
//            }
        }
    }];
}

- (void)creatOperationQueue {
    NSLog(@"currentThread: %@", [NSThread currentThread]);
    //创建
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    for (NSInteger j = 0; j < 100; j ++) {
        //将Operation加入队列
        //方法1：加入已经创建的Operation
//        NSInvocationOperation *invocationOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(task1) object:nil];
//        NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
//            [self task2];
//        }];
//
//        //操作加入queue后就会被并发执行
//        //当循环100次时，在iPhone 6s上大约会创建出65个线程
//        [queue addOperation:invocationOperation];
//        [queue addOperation:blockOperation];
        
        //方法2：直接创建Operation并加入队列
        //操作加入queue后就会被并发执行
        //当循环100次时，在iPhone 6s上大约会创建出65个线程
        
        [queue addOperationWithBlock:^{
            [self task2];
        }];
    }

}

- (void)setOperationQueue {

    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    //通过设置maxConcurrentOperationCount属性来控制队列串行执行或并发执行
    //设置为1即为串行执行
//    [queue setMaxConcurrentOperationCount:1];
    //设置为大于1的整数即为并行执行，实际并发数不会超过系统控制的最大值
    [queue setMaxConcurrentOperationCount:100];
    
    for (NSInteger j = 0; j < 10; j ++) {
        //当最大并发数为100，且循环100次时，在iPhone 6s上大约会创建出65个线程
        [queue addOperationWithBlock:^{
//        [self task2];
        }];
    }
    
    NSInvocationOperation *invocationOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(task1) object:nil];
    [queue addOperation:invocationOperation];
    [NSThread sleepForTimeInterval:1];
    
    //取消所操作，并将队列清空，正在执行的操作会被标记为取消
//    [queue cancelAllOperations];
//    NSLog(@"queue is canceled.");
    
    //通过设置suspended属性来暂停或恢复队列，不会影响正在执行的操作
//    queue.suspended = YES;
//    NSLog(@"queue is suspended");
//
//    if ([queue isSuspended]) {
//        [queue setSuspended:NO];
//    }
    
    if (invocationOperation.isCancelled) {
        NSLog(@"operation is cancelled");
    } else {
        NSLog(@"operation is not cancelled");
    }
    
    [queue addOperationWithBlock:^{
        [self task2];
    }];
    
    //等待所有操作执行完成，如果queue为暂停状态可能无法继续运行
//    [queue waitUntilAllOperationsAreFinished];
//    NSLog(@"all operation is finished");
    
    //添加操作数组，并标记是否阻塞当前线程直到本次添加的数组中的操作执行完成，不包括之前添加到队列中的操作
//    NSLog(@"add nothing to queue");
//    [queue addOperations:@[] waitUntilFinished:YES];
//    NSLog(@"all operation is finished");
    
    
    //通过operations属性获取队列中的所有操作，只读、copy，不包括已经执行完毕的操作
//    [NSThread sleepForTimeInterval:1];
    NSArray *operations = [queue operations];
    NSLog(@"operations:%@", operations);
    
    //通过operationCount属性读取队列中的操作个数
    NSLog(@"operationCount:%lu", (unsigned long)queue.operationCount);
    
    
    //获取当前线程所在队列，不在NSOperationQueue中时返回nil
    NSOperationQueue *queue2 = [NSOperationQueue currentQueue];
    NSLog(@"queue:%@", queue);
    NSLog(@"queue2:%@", queue2);
    //获取主队列
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    NSLog(@"mainQueue:%@", mainQueue);
    
}

- (void)setOperation {
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    NSInvocationOperation *invocationOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(task1) object:nil];
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        [self task2];
    }];
    
    //添加依赖
    //invocationOperation会等到blockOperation执行完成才开始执行
    [invocationOperation addDependency:blockOperation];
    
    //移除依赖
//    [invocationOperation removeDependency:blockOperation];
    
    //设置优先级
    //一共有五个优先级
    //NSOperationQueuePriorityVeryLow = -8L,
    //NSOperationQueuePriorityLow = -4L,
    //NSOperationQueuePriorityNormal = 0,
    //NSOperationQueuePriorityHigh = 4,
    //NSOperationQueuePriorityVeryHigh = 8
    //优先级仅对准备就绪的操作有效，若一个高优先级的操作A依赖的操作B未执行完毕，而另一个低优先级操作C已经准备就绪，操作C会先于操作A执行
    [invocationOperation setQueuePriority:NSOperationQueuePriorityHigh];
    [blockOperation setQueuePriority:NSOperationQueuePriorityLow];
    
    //标记isCancelled状态，在操作内容里可通过isCancelled属性判断是否需要执行部分代码
//    [invocationOperation cancel];
    //除了isCancelled状态，还有isFinished、isExecuting、isReady几种状态
    
    //阻塞当前线程直到操作执行完毕
    [blockOperation waitUntilFinished];
    
    //设置操作执行完毕之后的后续任务
    [invocationOperation setCompletionBlock:^{
        
    }];
    
    //通过dependencies只读属性读取当前操作依赖的所有操作对象，注意是只读属性且被标记为copy
    NSArray *dependencies = invocationOperation.dependencies;
    dependencies = nil;
    
    [queue addOperation:invocationOperation];
    [queue addOperation:blockOperation];

}

- (void)addOperationToMainQueue {
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    for (NSInteger j = 0; j < 10; j ++) {
        [queue addOperationWithBlock:^{
            [NSThread sleepForTimeInterval:2];
            NSLog(@"currentThread for queue: %@", [NSThread currentThread]);
            
            //获取主队列并加入操作
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [NSThread sleepForTimeInterval:2];
                NSLog(@"currentThread for mainQueue: %@", [NSThread currentThread]);
            }];
        }];
    }
}

- (void)safeForThread {
    
    for (NSInteger i = 0; i < 5; i ++) {
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        static NSLock *lock = nil;
        if (lock == nil) {
            lock = [[NSLock alloc] init];
        }
        for (NSInteger j = 0; j < 5; j ++) {
            [queue addOperationWithBlock:^{
                NSLog(@"start operation");
                //加锁
                [lock lock];
                
                //执行任务
                NSLog(@"operation is executing.");
                [NSThread sleepForTimeInterval:3];
                
                //解锁
                [lock unlock];
                NSLog(@"operation is finished");
            }];
        }
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
