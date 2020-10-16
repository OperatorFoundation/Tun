#include "TunC.h"



// Start wrapper examples
#define X 0

void TunC_function()
{
}

int TunC_X()
{
    return X;
}
// End wrapper examples


//  Start

//#define	FD_SET(fd, fdsetp)	__FD_SET (fd, fdsetp)
//#define	FD_CLR(fd, fdsetp)	__FD_CLR (fd, fdsetp)
//#define	FD_ISSET(fd, fdsetp)	__FD_ISSET (fd, fdsetp)
//#define	FD_ZERO(fdsetp)		__FD_ZERO (fdsetp)
//#define	FD_SETSIZE		__FD_SETSIZE




// End





// Start	/usr/include/asm-generic/fcntl.h
int TunC_O_RDWR()
{
	return O_RDWR;
}


// End		/usr/include/asm-generic/fcntl.h





// Start 	sys/socket.h
int TunC_SOCK_DGRAM()
{
	return (int)SOCK_DGRAM;
}

int TunC_AF_INET()
{
	return AF_INET;
}

int TunC_AF_INET6()
{
	return AF_INET6;
}



// End 		socket_type.h





// Start	if.h
int TuncC_IFNAMSIZ()
{
	return IFNAMSIZ;
}

// End		if.h


// Start	errno.h
int TunC_EAGAIN()
{
	return EAGAIN;
}

// End		errno.h


// Start    /usr/include/linux/if_tun.h 

// Read queue size 
int TunC_TUN_READQ_SIZE()
{
    return TUN_READQ_SIZE;
}

// TUN device type flags: deprecated. Use IFF_TUN/IFF_TAP instead. 
int TunC_TUN_TUN_DEV()
{
    return TUN_TUN_DEV;
}

int TunC_TUN_TAP_DEV()
{
    return TUN_TAP_DEV;
}

int TunC_TUN_TYPE_MASK()
{
    return TUN_TYPE_MASK;
}

// Ioctl defines 
int TunC_TUNSETNOCSUM()
{
    return TUNSETNOCSUM;
}

int TunC_TUNSETDEBUG()
{
    return TUNSETDEBUG;
}

unsigned long int TunC_TUNSETIFF()
{
    return TUNSETIFF;
}

int TunC_TUNSETPERSIST()
{
    return TUNSETPERSIST;
}

int TunC_TUNSETOWNER()
{
    return TUNSETOWNER;
}

int TunC_TUNSETLINK()
{
    return TUNSETLINK;
}

int TunC_TUNSETGROUP()
{
    return TUNSETGROUP;
}

int TunC_TUNGETFEATURES()
{
    return TUNGETFEATURES;
}

int TunC_TUNSETOFFLOAD()
{
    return TUNSETOFFLOAD;
}

int TunC_TUNSETTXFILTER()
{
    return TUNSETTXFILTER;
}

int TunC_TUNGETIFF()
{
    return TUNGETIFF;
}

int TunC_TUNGETSNDBUF()
{
    return TUNGETSNDBUF;
}

int TunC_TUNSETSNDBUF()
{
    return TUNSETSNDBUF;
}

int TunC_TUNATTACHFILTER()
{
    return TUNATTACHFILTER;
}

int TunC_TUNDETACHFILTER()
{
    return TUNDETACHFILTER;
}

int TunC_TUNGETVNETHDRSZ()
{
    return TUNGETVNETHDRSZ;
}

int TunC_TUNSETVNETHDRSZ()
{
    return TUNSETVNETHDRSZ;
}

int TunC_TUNSETQUEUE()
{
    return TUNSETQUEUE;
}

int TunC_TUNSETIFINDEX()
{
    return TUNSETIFINDEX;
}

int TunC_TUNGETFILTER()
{
    return TUNGETFILTER;
}

int TunC_TUNSETVNETLE()
{
    return TUNSETVNETLE;
}

int TunC_TUNGETVNETLE()
{
    return TUNGETVNETLE;
}

int TunC_TUNSETVNETBE()
{
    return TUNSETVNETBE;
}

int TunC_TUNGETVNETBE()
{
    return TUNGETVNETBE;
}

int TunC_TUNSETCARRIER()
{
    return TUNSETCARRIER;
}

// TUNSETIFF ifr flags 
short int TunC_IFF_TUN()
{
    return IFF_TUN;
}

int TunC_IFF_TAP()
{
    return IFF_TAP;
}

int TunC_IFF_NAPI()
{
    return IFF_NAPI;
}

int TunC_IFF_NAPI_FRAGS()
{
    return IFF_NAPI_FRAGS;
}

short int TunC_IFF_NO_PI()
{
    return IFF_NO_PI;
}

// This flag has no real effect 
int TunC_IFF_ONE_QUEUE()
{
    return IFF_ONE_QUEUE;
}

int TunC_IFF_VNET_HDR()
{
    return IFF_VNET_HDR;
}

int TunC_IFF_TUN_EXCL()
{
    return IFF_TUN_EXCL;
}

int TunC_IFF_MULTI_QUEUE()
{
    return IFF_MULTI_QUEUE;
}

int TunC_IFF_ATTACH_QUEUE()
{
    return IFF_ATTACH_QUEUE;
}

int TunC_IFF_DETACH_QUEUE()
{
    return IFF_DETACH_QUEUE;
}

// read-only flag 
int TunC_IFF_PERSIST()
{
    return IFF_PERSIST;
}

int TunC_IFF_NOFILTER()
{
    return IFF_NOFILTER;
}

// Socket options 
int TunC_TUN_TX_TIMESTAMP()
{
    return TUN_TX_TIMESTAMP;
}

// Features for GSO (TUNSETOFFLOAD). 
int TunC_TUN_F_CSUM()
{
    return TUN_F_CSUM;
}

int TunC_TUN_F_TSO4()
{
    return TUN_F_TSO4;
}

int TunC_TUN_F_TSO6()
{
    return TUN_F_TSO6;
}

int TunC_TUN_F_TSO_ECN()
{
    return TUN_F_TSO_ECN;
}

int TunC_TUN_F_UFO()
{
    return TUN_F_UFO;
}

// Protocol info prepended to the packets (when IFF_NO_PI is not set) 
int TunC_TUN_PKT_STRIP()
{
    return TUN_PKT_STRIP;
}

int TunC_TUN_FLT_ALLMULTI()
{
    return TUN_FLT_ALLMULTI;
}

// End  	  /usr/include/linux/if_tun.h 




