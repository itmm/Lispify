#import "Tokenizer.h"

@implementation Tokenizer {
    NSString *_source;
    NSInteger _current;
    NSInteger _length;
}

    - (instancetype) initWithString: (NSString *) source {
        if (self = [super init]) {
            _source = source;
            _current = 0;
            _length = _source.length;
        }
        return self;
    }

    + (instancetype) tokenizerWithString: (NSString *) source {
        return [[Tokenizer alloc] initWithString: source];
    }

    - (char) current {
        return _current >= _length ? 0 : [_source characterAtIndex: _current];
    }

    - (char) next {
        ++_current;
        return [self current];
    }

@end
