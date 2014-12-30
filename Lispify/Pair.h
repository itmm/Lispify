@import Foundation;

@interface Pair : NSObject

    @property (readonly) id car;
    @property (readonly) id cdr;
    @property (readonly) BOOL hidden;

    @property NSInteger x;
    @property NSInteger y;
    
    + (instancetype) pairWithCar: (id) car cdr: (id) cdr hidden: (BOOL) hidden;

@end
