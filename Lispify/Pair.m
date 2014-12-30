#import "Pair.h"

@implementation Pair

    - (instancetype) initWithCar: (id) car cdr: (id) cdr hidden: (BOOL) hidden {
        if (self = [super init]) {
            _car = car;
            _cdr = cdr;
            _hidden = hidden;
        }
        return self;
    }

    + (instancetype) pairWithCar: (id) car cdr: (id) cdr hidden: (BOOL) hidden {
        return [[Pair alloc] initWithCar: car cdr: cdr hidden: hidden];
    }

@end
