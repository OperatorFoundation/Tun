//
//  TUN.c
//  ReplicantSwiftServerCore
//
//  Created by Dr. Brandon Wiley on 1/29/19.
//

#import <stdint.h>
#import "include/TunC.h"
#import <net/if_utun.h>
#import <sys/kern_control.h>
#import <sys/ioctl.h>
#import <errno.h>
#import <strings.h>
#import <stdio.h>

int getIdentifier(int socket)
{
    struct ctl_info kernelControlInfo;
    
    bzero(&kernelControlInfo, sizeof(kernelControlInfo));
    strlcpy(kernelControlInfo.ctl_name, UTUN_CONTROL_NAME, sizeof(kernelControlInfo.ctl_name));
    
    if (ioctl(socket, CTLIOCGINFO, &kernelControlInfo)) {
        printf("ioctl failed on kernel control socket: %s\n", strerror(errno));
        return 0;
    }
    
    return kernelControlInfo.ctl_id;
}

int nameOption(void)
{
    return UTUN_OPT_IFNAME;
}
