//
//  TUN.h
//  ReplicantSwiftServerCore
//
//  Created by Dr. Brandon Wiley on 1/29/19.
//

#import <stdint.h>
#import <net/if_utun.h>
#import <sys/socket.h>
#import <sys/kern_control.h>
#import <sys/ioctl.h>
#import <sys/sys_domain.h>
#import <errno.h>
#import <strings.h>
#import <stdio.h>
#import <stdlib.h>
#include <fcntl.h>

/// Get the identifier for the UTUN interface.
int connectControl(int socket);
int setSocketNonBlocking(int socket);
