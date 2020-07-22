//
//  TunDevice.swift
//  ReplicantSwiftServerCore
//
//  Created by Dr. Brandon Wiley on 1/29/19.
//

import Foundation
import TunObjC
import Datable
import Darwin.C

// The include files that define these constants do not appear to be available from Swift.
// It would, of course, be better to find the correct way to import these from C.
let CTLIOCGINFO: UInt = 3227799043
let UTUN_OPT_IFNAME: Int32 = 2
let UTUN_CONTROL_NAME = "com.apple.net.utun_control"

//the following are from <sys/sockio.h>
let SIOCSHIWAT: UInt = 2147775232
let SIOCGHIWAT: UInt = 1074033409
let SIOCSLOWAT: UInt = 2147775234
let SIOCGLOWAT: UInt = 1074033411
let SIOCATMARK: UInt = 1074033415
let SIOCSPGRP: UInt = 2147775240
let SIOCGPGRP: UInt = 1074033417
let SIOCSIFADDR: UInt = 2149607692
let SIOCSIFDSTADDR: UInt = 2149607694
let SIOCSIFFLAGS: UInt = 2149607696
let SIOCGIFFLAGS: UInt = 3223349521
let SIOCSIFBRDADDR: UInt = 2149607699
let SIOCSIFNETMASK: UInt = 2149607702
let SIOCGIFMETRIC: UInt = 3223349527
let SIOCSIFMETRIC: UInt = 2149607704
let SIOCDIFADDR: UInt = 2149607705
let SIOCAIFADDR: UInt = 2151704858
let SIOCGIFADDR: UInt = 3223349537
let SIOCGIFDSTADDR: UInt = 3223349538
let SIOCGIFBRDADDR: UInt = 3223349539
let SIOCGIFNETMASK: UInt = 3223349541
let SIOCAUTOADDR: UInt = 3223349542
let SIOCAUTONETMASK: UInt = 2149607719
let SIOCARPIPLL: UInt = 3223349544
let SIOCADDMULTI: UInt = 2149607729
let SIOCDELMULTI: UInt = 2149607730
let SIOCGIFMTU: UInt = 3223349555
let SIOCSIFMTU: UInt = 2149607732
let SIOCGIFPHYS: UInt = 3223349557
let SIOCSIFPHYS: UInt = 2149607734
let SIOCSIFMEDIA: UInt = 3223349559
let SIOCGIFMEDIA: UInt = 3224135992
let SIOCSIFGENERIC: UInt = 2149607737
let SIOCGIFGENERIC: UInt = 3223349562
let SIOCRSLVMULTI: UInt = 3222300987
let SIOCSIFLLADDR: UInt = 2149607740
let SIOCGIFSTATUS: UInt = 3274795325
let SIOCSIFPHYADDR: UInt = 2151704894
let SIOCGIFPSRCADDR: UInt = 3223349567
let SIOCGIFPDSTADDR: UInt = 3223349568
let SIOCDIFPHYADDR: UInt = 2149607745
let SIOCGIFDEVMTU: UInt = 3223349572
let SIOCSIFALTMTU: UInt = 2149607749
let SIOCGIFALTMTU: UInt = 3223349576
let SIOCSIFBOND: UInt = 2149607750
let SIOCGIFBOND: UInt = 3223349575
let SIOCGIFXMEDIA: UInt = 3224136008
let SIOCSIFCAP: UInt = 2149607770
let SIOCGIFCAP: UInt = 3223349595
let SIOCIFCREATE: UInt = 3223349624
let SIOCIFDESTROY: UInt = 2149607801
let SIOCIFCREATE2: UInt = 3223349626
let SIOCSDRVSPEC: UInt = 2150132091
let SIOCGDRVSPEC: UInt = 3223873915
let SIOCSIFVLAN: UInt = 2149607806
let SIOCGIFVLAN: UInt = 3223349631
let SIOCSETVLAN: UInt = 2149607806
let SIOCGETVLAN: UInt = 3223349631
let SIOCGIFASYNCMAP: UInt = 3223349628
let SIOCSIFASYNCMAP: UInt = 2149607805
let SIOCGIFMAC: UInt = 3223349634
let SIOCSIFMAC: UInt = 2149607811
let SIOCSIFKPI: UInt = 2149607814
let SIOCGIFKPI: UInt = 3223349639
let SIOCGIFWAKEFLAGS: UInt = 3223349640
let SIOCGIFFUNCTIONALTYPE: UInt = 3223349677
let SIOCSIF6LOWPAN: UInt = 2149607876
let SIOCGIF6LOWPAN: UInt = 3223349701

public class TunDevice
{
    static let protocolNumberSize = 4
    var maybeName: String?
    var maybeTun: Int32?
    var maybeSource: DispatchSource?
    let reader: (Data, UInt32) -> Void
    
    public init?(address: String, reader: @escaping (Data, UInt32) -> Void)
    {
        self.reader = reader
        
        guard let fd = createInterface() else
        {
            return nil
        }
        
        print("Created TUN interface \(fd)")
        
        maybeTun = fd
        
        guard let ifname = getInterfaceName(fd: fd) else
        {
            return nil
        }
        
        print("TUN interface name \(ifname)")
        
        maybeName = ifname
        
        guard setAddress(name: ifname, address: address) else
        {
            return nil
        }
        
        startTunnel(fd: fd)
    }

    /// Create a UTUN interface.
    func createInterface() -> Int32?
    {
        let fd = socket(PF_SYSTEM, SOCK_DGRAM, SYSPROTO_CONTROL)
        guard fd >= 0 else
        {
            print("Failed to open TUN socket")
            return nil
        }
        
        let result = connectControl(socket: fd)
        guard result == 0 else
        {
            print("Failed to connect to TUN control socket: \(result)")
            close(fd)
            return nil
        }
        
        return fd
    }
    
    /// Get the name of a UTUN interface the associated socket.
    func getInterfaceName(fd: Int32) -> String?
    {
        let length = Int(IFNAMSIZ)
        var buffer = [Int8](repeating: 0, count: length)
        var bufferSize: socklen_t = socklen_t(length)
        let result = getsockopt(fd, SYSPROTO_CONTROL, UTUN_OPT_IFNAME, &buffer, &bufferSize)
        
        guard result >= 0 else
        {
            let errorString = String(cString: strerror(errno))
            print("getsockopt failed while getting the utun interface name: \(errorString)")
            return nil
        }
        
        return String(cString: &buffer)
    }
    
    func setAddress(name: String, address: String) -> Bool
    {
        return TUN.setAddress(name, withAddress: address)
    }
    
    func startTunnel(fd: Int32)
    {
        if !setSocketNonBlocking(socket: fd)
        {
            return
        }
        
//        guard let newSource = DispatchSource.makeReadSource(fileDescriptor: fd, queue: DispatchQueue.main) as? DispatchSource else
//        {
//            return
//        }
//
//        newSource.setCancelHandler
//        {
//            close(fd)
//            return
//        }
//
//        newSource.setEventHandler
//        {
//            self.handleRead()
//        }
//
//        newSource.resume()
//
//        maybeSource = newSource
    }
    
    public func writeV4(_ packet: Data)
    {
        guard let tun = maybeTun else
        {
            return
        }
        
        let protocolNumber = AF_INET
        DatableConfig.endianess = .big
        var protocolNumberBuffer = protocolNumber.data
        var buffer = Data(packet)
                    
        var iovecList =
        [
            iovec(iov_base: &protocolNumberBuffer, iov_len: TunDevice.protocolNumberSize),
            iovec(iov_base: &buffer, iov_len: packet.count)
        ]
                
        let writeCount = writev(tun, &iovecList, Int32(iovecList.count))
        if writeCount < 0
        {
            let errorString = String(cString: strerror(errno))
            print("Got an error while writing to utun: \(errorString)")
        }
    }

    public func writeV6(_ packet: Data)
    {
        let protocolNumber = AF_INET6
        DatableConfig.endianess = .big
        var protocolNumberBuffer = protocolNumber.data
        var buffer = Data(packet)
        var iovecList =
            [
                iovec(iov_base: &protocolNumberBuffer, iov_len: TunDevice.protocolNumberSize),
                iovec(iov_base: &buffer, iov_len: packet.count)
        ]
        
        guard let tun = maybeTun else {
            return
        }
        
        let writeCount = writev(tun, &iovecList, Int32(iovecList.count))
        if writeCount < 0
        {
            let errorString = String(cString: strerror(errno))
            print("Got an error while writing to utun: \(errorString)")
        }
    }
    
    func handleRead()
    {
        while true
        {
            //FIX packet size is fixed!
            guard let (data, protocolNumber) = self.read(packetSize: 1500) else
            {
                return
            }
            
            self.reader(data, protocolNumber)
        }
    }
    
    public func read(packetSize: Int) -> (Data, UInt32)?
    {
        print("\n📚  Read called on TUN device. 📚")
        print("Requested packet size is \(packetSize)\n")
                
        guard let source = maybeSource else
        {
            return nil
        }
        
        var buffer = [UInt8](repeating:0, count: packetSize)
        var protocolNumber: UInt32 = 0
        var iovecList = [ iovec(iov_base: &protocolNumber, iov_len: MemoryLayout.size(ofValue: protocolNumber)), iovec(iov_base: &buffer, iov_len: buffer.count) ]
        let iovecListPointer = UnsafeBufferPointer<iovec>(start: &iovecList, count: iovecList.count)
        let utunSocket = Int32((source as DispatchSourceRead).handle)
                        
        var error: Int32 = 0
    
        repeat
        {
            let readCount = readv(utunSocket, iovecListPointer.baseAddress, Int32(iovecListPointer.count))
            error = errno

            guard readCount > 0 || error == EAGAIN else
            {
                if let errorString = String(utf8String: strerror(errno)), readCount < 0
                {
                    print("Got an error on the utun socket: \(errorString)")
                }
                
                source.cancel()
                
                return nil
            }

            guard readCount > MemoryLayout.size(ofValue: protocolNumber) else
            {
                return nil
            }

            if protocolNumber.littleEndian == protocolNumber
            {
                protocolNumber = protocolNumber.byteSwapped
            }

            let data = Data(bytes: &buffer, count: readCount - MemoryLayout.size(ofValue: protocolNumber))
            
            return (data, protocolNumber)
        }
        while error == EAGAIN
    }
        
    func getIdentifier(socket: Int32) -> UInt32?
    {
        var n = UTUN_CONTROL_NAME.array(of: Int8.self)!
        
        //pad out n
        for _ in 1...(96 - n.count)
        {
            n.append(0)
        }

        
        var kernelControlInfo: ctl_info = ctl_info(ctl_id: 0, ctl_name: (n[0], n[1], n[2], n[3], n[4], n[5], n[6], n[7], n[8], n[9], n[10], n[11], n[12], n[13], n[14], n[15], n[16], n[17], n[18], n[19], n[20], n[21], n[22], n[23], n[24], n[25], n[26], n[27], n[28], n[29], n[30], n[31], n[32], n[33], n[34], n[35], n[36], n[37], n[38], n[39], n[40], n[41], n[42], n[43], n[44], n[45], n[46], n[47], n[48], n[49], n[50], n[51], n[52], n[53], n[54], n[55], n[56], n[57], n[58], n[59], n[60], n[61], n[62], n[63], n[64], n[65], n[66], n[67], n[68], n[69], n[70], n[71], n[72], n[73], n[74], n[75], n[76], n[77], n[78], n[79], n[80], n[81], n[82], n[83], n[84], n[85], n[86], n[87], n[88], n[89], n[90], n[91], n[92], n[93], n[94], n[95]))

        guard ioctl(socket, CTLIOCGINFO, &kernelControlInfo) != -1 else
        {
            print("ioctl failed on kernel control socket:", strerror(errno) ?? 0);
            return nil;
        }

        return kernelControlInfo.ctl_id;
    }
    
    func setSocketNonBlocking(socket: Int32) -> Bool
    {
        let currentFlags = fcntl(socket, F_GETFL)
        guard currentFlags >= 0 else
        {
            print("fcntl(F_GETFL) failed:", strerror(errno) ?? 0)
            
            return false
        }

        let newFlags = currentFlags | O_NONBLOCK

        guard fcntl(socket, F_SETFL, newFlags) >= 0 else
        {
            print("fcntl(F_SETFL) failed: %s\n", strerror(errno) ?? 0);
            
            return false
        }

        return true
    }
    
    func connectControl(socket: Int32) -> Int32?
    {
        guard let controlIdentifier = getIdentifier(socket: socket) else
        {
            return nil
        }
        
        guard controlIdentifier > 0 else
        {
            return nil
        }

        let size = MemoryLayout<sockaddr_ctl>.stride
        
        var control: sockaddr_ctl = sockaddr_ctl(
            sc_len: UInt8(size),
            sc_family: UInt8(AF_SYSTEM),
            ss_sysaddr: UInt16(AF_SYS_CONTROL),
            sc_id: controlIdentifier,
            sc_unit: 0,
            sc_reserved: (0, 0, 0, 0, 0)
        )

        let connectResult = withUnsafeMutablePointer(to: &control)
        {
            controlPointer -> Int32 in
            
            return controlPointer.withMemoryRebound(to: sockaddr.self, capacity: 1)
            {
                sockaddrPointer -> Int32 in
                
                return connect(socket, sockaddrPointer, socklen_t(size))
            }
        }
        
        return connectResult;
    }

    func setAddress(interfaceName: String, addressString: String) -> Bool
    {
        var address = in_addr()
        
        let cstring = addressString.cString(using: .utf8)
                
        guard inet_pton(AF_INET, cstring, &address) == 1 else
        {
            return false
        }

        guard let interfaceNameArray = interfaceName.data.array(of: Int8.self) else
        {
            return false
        }
        var infra_name: [Int8] = paddedArray(source: interfaceNameArray, targetSize: 16, padValue: 0)
        
        guard let addressArray = addressString.data.array(of: Int8.self) else
        {
            return false
        }
        
        var sin_addr: [Int8] = paddedArray(source: addressArray, targetSize: 14, padValue: 0)
        
        let socketDescriptor = socket(AF_INET, SOCK_DGRAM, 0)

        guard socketDescriptor > 0 else
        {
            print("Failed to create a DGRAM socket:", strerror(errno) ?? 0)
            
            return false
        }
        
        let sockaddr_in_size = MemoryLayout<sockaddr_in>.stride
        
        var interfaceAliasRequest = ifaliasreq(
            ifra_name: (infra_name[0], infra_name[1], infra_name[2], infra_name[3], infra_name[4], infra_name[5], infra_name[6], infra_name[7], infra_name[8], infra_name[9], infra_name[10], infra_name[11], infra_name[12], infra_name[13], infra_name[14], infra_name[15]),
            ifra_addr: sockaddr(
                sa_len: __uint8_t(sockaddr_in_size),
                sa_family: sa_family_t(AF_INET),
                sa_data: (sin_addr[0], sin_addr[1], sin_addr[2], sin_addr[3], sin_addr[4], sin_addr[5], sin_addr[6], sin_addr[7], sin_addr[8], sin_addr[9], sin_addr[10], sin_addr[11], sin_addr[12], sin_addr[13])
            ),
            ifra_broadaddr: sockaddr(
                sa_len: __uint8_t(sockaddr_in_size),
                sa_family: sa_family_t(AF_INET),
                sa_data: (sin_addr[0], sin_addr[1], sin_addr[2], sin_addr[3], sin_addr[4], sin_addr[5], sin_addr[6], sin_addr[7], sin_addr[8], sin_addr[9], sin_addr[10], sin_addr[11], sin_addr[12], sin_addr[13])
            ),
            ifra_mask: sockaddr(
                sa_len: __uint8_t(sockaddr_in_size),
                sa_family: sa_family_t(AF_INET),
                sa_data: (Int8(bitPattern: 255), Int8(bitPattern: 255), Int8(bitPattern: 255), Int8(bitPattern: 255), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
            )
        )
        
        guard ioctl(socketDescriptor, SIOCAIFADDR, &interfaceAliasRequest) > 0 else
        {
            print("Failed to set the address of the interface")
            close(socketDescriptor)
            return false
        }

        close(socketDescriptor)
        
//            memcpy(&((struct sockaddr_in *)&interfaceAliasRequest.ifra_broadaddr)->sin_addr, &address, sizeof(address));
        
        return true
    }
    
    func paddedArray<T>(source: [T], targetSize: Int, padValue: T) -> [T]
    {
        var result: [T] = []
        for item in source
        {
            result.append(item)
        }
        
        for _ in result.count..<targetSize
        {
            result.append(padValue)
        }
        
        return result
    }
}
