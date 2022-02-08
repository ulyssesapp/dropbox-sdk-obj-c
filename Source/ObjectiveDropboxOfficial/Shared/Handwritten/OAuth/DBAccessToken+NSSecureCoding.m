///
/// Copyright (c) 2020 Dropbox, Inc. All rights reserved.
///

#import "DBAccessToken+NSSecureCoding.h"
#import "DBOAuthManager.h"

@implementation DBAccessToken (NSSecureCoding)

+ (DBAccessToken *)createTokenFromData:(NSData *)data {
  return [NSKeyedUnarchiver unarchivedObjectOfClass:[DBAccessToken class] fromData:data error:NULL];
}

+ (NSData *)covertTokenToData:(DBAccessToken *)token {
  return [NSKeyedArchiver archivedDataWithRootObject:token requiringSecureCoding:YES error:NULL];
}

@end
