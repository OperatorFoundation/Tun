//
//  TUN.h
//  ReplicantSwiftServerCore
//
//  Created by Dr. Brandon Wiley on 1/29/19.
//

#import <Foundation/Foundation.h>

@interface TUN: NSObject

/// Get the identifier for the UTUN interface.
+ (int)connectControl: (int) socket;
+ (BOOL)setAddress: (NSString *) name withAddress: (NSString *) address;
+ (BOOL)setNonBlocking: (int) socket;

@end
