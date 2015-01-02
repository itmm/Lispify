#import "Tokenizer.h"

@implementation Tokenizer {
    NSData *_source;
    NSInteger _current;
    NSInteger _length;
}

    - (instancetype) initWithString: (NSString *) source {
        if (self = [super init]) {
            _source = [source dataUsingEncoding:NSUTF8StringEncoding];
            _current = 0;
            _length = _source.length;
        }
        return self;
    }

    + (instancetype) tokenizerWithString: (NSString *) source {
        return [[Tokenizer alloc] initWithString: source];
    }

    - (unsigned char) current {
        return _current >= _length ? 0 : ((unsigned char *) _source.bytes)[_current];
    }

    - (unsigned char) next {
        ++_current;
        return [self current];
    }

@end
