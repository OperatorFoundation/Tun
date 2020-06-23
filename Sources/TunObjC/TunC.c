//
//  TUN.c
//  ReplicantSwiftServerCore
//
//  Created by Dr. Brandon Wiley on 1/29/19.
//

#import "include/TunC.h"

int connectControl(int socket)
{
    struct ctl_info kernelControlInfo;
    
    bzero(&kernelControlInfo, sizeof(kernelControlInfo));
    strlcpy(kernelControlInfo.ctl_name, UTUN_CONTROL_NAME, sizeof(kernelControlInfo.ctl_name));
    
    if (ioctl(socket, CTLIOCGINFO, &kernelControlInfo))
    {
        printf("ioctl failed on kernel control socket: %s\n", strerror(errno));
        return 0;
    }
    
    unsigned int controlIdentifier = kernelControlInfo.ctl_id;
    
    if(controlIdentifier <= 0)
    {
        return -1;
    }
    
    struct sockaddr_ctl *control = malloc(sizeof(struct sockaddr_ctl));
    control->sc_len=sizeof(struct sockaddr_ctl);
    control->sc_family=AF_SYSTEM;
    control->ss_sysaddr=AF_SYS_CONTROL;
    control->sc_id=controlIdentifier;
    control->sc_unit=0;
    
    int connectResult = connect(socket, (struct sockaddr *)control, sizeof(struct sockaddr_ctl));
    
    return connectResult;
}

int setSocketNonBlocking(int socket)
{
    int currentFlags = fcntl(socket, F_GETFL);
    if (currentFlags < 0) {
        printf("fcntl(F_GETFL) failed: %s\n", strerror(errno));
        return 0;
    }

    currentFlags |= O_NONBLOCK;

    if (fcntl(socket, F_SETFL, currentFlags) < 0) {
        printf("fcntl(F_SETFL) failed: %s\n", strerror(errno));
        return 0;
    }

    return 1;
}
