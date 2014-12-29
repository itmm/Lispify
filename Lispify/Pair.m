#import "Pair.h"

@implementation Pair

    - (instancetype) initWithCar: (id) car cdr: (id) cdr {
        if (self = [super init]) {
            _car = car;
            _cdr = cdr;
        }
        return self;
    }

    + (instancetype) pairWithCar: (id) car cdr: (id) cdr {
        return [[Pair alloc] initWithCar: car cdr: cdr];
    }

@end
