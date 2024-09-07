#ifndef URLSessionHook_h
#define URLSessionHook_h

@interface URLSessionHook : NSObject

typedef void (^NSCompletionHandler)(NSData *data, NSURLResponse *response, NSError *error);

@end
#endif