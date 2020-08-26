


#include <linux/if_tun.h>


#include <fcntl.h>
#include <socket_type.h>
#include <errno.h>

#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <arpa/inet.h>
#include <sys/ioctl.h>
#include <stdint.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <net/if.h>
#include <net/route.h>

#include <strings.h>
#include <stdio.h>
#include <linux/sockios.h>

void TunC_function();
int TunC_X();


// Start	/usr/include/asm-generic/fcntl.h

int TunC_O_RDWR();


// End		/usr/include/asm-generic/fcntl.h


// Start 	socket_type.h
int TunC_SOCK_DGRAM();

// End 		socket_type.h



// Start	if.h
int TuncC_IFNAMSIZ();

// End		if.h



// Start    /usr/include/linux/if_tun.h 

// Read queue size 
int TunC_TUN_READQ_SIZE();
// TUN device type flags: deprecated. Use IFF_TUN/IFF_TAP instead. 
int TunC_TUN_TUN_DEV();
int TunC_TUN_TAP_DEV();
int TunC_TUN_TYPE_MASK();

// Ioctl defines 
int TunC_TUNSETNOCSUM();
int TunC_TUNSETDEBUG();
int TunC_TUNSETIFF();
int TunC_TUNSETPERSIST();
int TunC_TUNSETOWNER();
int TunC_TUNSETLINK();
int TunC_TUNSETGROUP();
int TunC_TUNGETFEATURES();
int TunC_TUNSETOFFLOAD();
int TunC_TUNSETTXFILTER();
int TunC_TUNGETIFF();
int TunC_TUNGETSNDBUF();
int TunC_TUNSETSNDBUF();
int TunC_TUNATTACHFILTER();
int TunC_TUNDETACHFILTER();
int TunC_TUNGETVNETHDRSZ();
int TunC_TUNSETVNETHDRSZ();
int TunC_TUNSETQUEUE();
int TunC_TUNSETIFINDEX();
int TunC_TUNGETFILTER();
int TunC_TUNSETVNETLE();
int TunC_TUNGETVNETLE();
int TunC_TUNSETVNETBE();
int TunC_TUNGETVNETBE();
int TunC_TUNSETCARRIER();

// TUNSETIFF ifr flags 
int TunC_IFF_TUN();
int TunC_IFF_TAP();
int TunC_IFF_NAPI();
int TunC_IFF_NAPI_FRAGS();
int TunC_IFF_NO_PI();
// This flag has no real effect 
int TunC_IFF_ONE_QUEUE();
int TunC_IFF_VNET_HDR();
int TunC_IFF_TUN_EXCL();
int TunC_IFF_MULTI_QUEUE();
int TunC_IFF_ATTACH_QUEUE();
int TunC_IFF_DETACH_QUEUE();
// read-only flag 
int TunC_IFF_PERSIST();
int TunC_IFF_NOFILTER();

// Socket options 
int TunC_TUN_TX_TIMESTAMP();

// Features for GSO (TUNSETOFFLOAD). 
int TunC_TUN_F_CSUM();
int TunC_TUN_F_TSO4();
int TunC_TUN_F_TSO6();
int TunC_TUN_F_TSO_ECN();
int TunC_TUN_F_UFO();

// Protocol info prepended to the packets (when IFF_NO_PI is not set) 
int TunC_TUN_PKT_STRIP();

int TunC_TUN_FLT_ALLMULTI();

// End    /usr/include/linux/if_tun.h 





