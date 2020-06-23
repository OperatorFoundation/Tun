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

// The include file for this constant does not appear to be available from Swift.
let CTLIOCGINFO: UInt = 3227799043

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
        
        let result = TunObjC.connectControl(fd)
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
        if !TUN.setNonBlocking(fd)
        {
            return
        }
        
        guard let newSource = DispatchSource.makeReadSource(fileDescriptor: fd, queue: DispatchQueue.main) as? DispatchSource else
        {
            return
        }
        
        newSource.setCancelHandler
        {
            close(fd)
            return
        }

        newSource.setEventHandler
        {
            self.handleRead()
        }

        newSource.resume()
        
        maybeSource = newSource
    }
    
    public func writeV4(_ packet: Data)
    {
        let protocolNumber = AF_INET
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
            guard let (data, protocolNumber) = self.read(packetSize: 1) else
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
        let n = UTUN_CONTROL_NAME.array(of: Int8.self)!
        var kernelControlInfo: ctl_info = ctl_info(ctl_id: 0, ctl_name: (n[0], n[1], n[2], n[3], n[4], n[5], n[6], n[7], n[8], n[9], n[10], n[11], n[12], n[13], n[14], n[15], n[16], n[17], n[18], n[19], n[20], n[21], n[22], n[23], n[24], n[25], n[26], n[27], n[28], n[29], n[30], n[31], n[32], n[33], n[34], n[35], n[36], n[37], n[38], n[39], n[40], n[41], n[42], n[43], n[44], n[45], n[46], n[47], n[48], n[49], n[50], n[51], n[52], n[53], n[54], n[55], n[56], n[57], n[58], n[59], n[60], n[61], n[62], n[63], n[64], n[65], n[66], n[67], n[68], n[69], n[70], n[71], n[72], n[73], n[74], n[75], n[76], n[77], n[78], n[79], n[80], n[81], n[82], n[83], n[84], n[85], n[86], n[87], n[88], n[89], n[90], n[91], n[92], n[93], n[94], n[95]))

        guard ioctl(socket, CTLIOCGINFO, &kernelControlInfo) != -1 else
        {
            print("ioctl failed on kernel control socket:", strerror(errno) ?? 0);
            return nil;
        }

        return kernelControlInfo.ctl_id;
    }
}
