//
//  TUN.h
//  ReplicantSwiftServerCore
//
//  Created by Dr. Brandon Wiley on 1/29/19.
//

#import <Foundation/Foundation.h>

@interface TUN: NSObject

/// Get the identifier for the UTUN interface.
+ (BOOL)setAddress: (NSString *) name withAddress: (NSString *) address;

@end
