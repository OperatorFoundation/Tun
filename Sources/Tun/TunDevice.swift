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
        let result = getsockopt(fd, SYSPROTO_CONTROL, TUN.nameOption(), &buffer, &bufferSize)
        
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
}
