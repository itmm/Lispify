@import Foundation;

@interface Pair : NSObject

    @property (readonly) id car;
    @property (readonly) id cdr;

    @property NSInteger x;
    @property NSInteger y;
    
    + (instancetype) pairWithCar: (id) car cdr: (id) cdr;

@end
