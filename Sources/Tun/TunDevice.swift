//
//  TunDevice.swift
//  ReplicantSwiftServerCore
//
//  Created by Dr. Brandon Wiley on 1/29/19.
//

import Foundation
import Datable
import Glibc
import TunC
import Routing


//let X = TunC_X()

//if_tun.h 
let IFF_TUN = TunC_IFF_TUN()
let IFF_NO_PI = TunC_IFF_NO_PI()
let TUNSETIFF = TunC_TUNSETIFF()

//socket.h
let AF_INET = TunC_AF_INET()
let AF_INET6 = TunC_AF_INET6()

//fcntl.h
let O_RDWR = TunC_O_RDWR()

//socket_type.h
public let SOCK_DGRAM = TunC_SOCK_DGRAM()

//if.h
let IFNAMSIZ = TuncC_IFNAMSIZ()

//errno.h
let EAGAIN = TunC_EAGAIN()



func printDataBytes(bytes: Data, hexDumpFormat: Bool, seperator: String, decimal: Bool, enablePrinting: Bool = true) -> String
{
    var returnString: String = ""
    if hexDumpFormat
    {
        var count = 0
        var newLine: Bool = true
        for byte in bytes
        {
            if newLine
            {
                if enablePrinting { print("・ ", terminator: "") }
                newLine = false
            }
            if enablePrinting { print(String(format: "%02x", byte), terminator: " ") }
            returnString += String(format: "%02x", byte)
            returnString += " "
            count += 1
            if count % 8 == 0
            {
                if enablePrinting { print(" ", terminator: "") }
                returnString += " "
            }
            if count % 16 == 0
            {
                if enablePrinting { print("") }
                returnString += "\n"
                newLine = true
            }
        }
    }
    else
    {
        var i = 0
        for byte in bytes
        {
            if decimal
            {
                if enablePrinting { print(String(format: "%u", byte), terminator: "") }
                returnString += String(format: "%u", byte)
            }
            else
            {
                if enablePrinting { print(String(format: "%02x", byte), terminator: "") }
                returnString += String(format: "%02x", byte)
            }
            i += 1
            if i < bytes.count
            {
                if enablePrinting { print(seperator, terminator: "") }
                returnString += seperator
            }
        }
    }
    if enablePrinting { print("") }
    return returnString
}

public class TunDevice
{
    static let protocolNumberSize = 4
    public var maybeName: String?
    var maybeTun: Int32?
    var maybeSource: DispatchSource?
    let reader: (Data) -> Void

    public init?(address: String, reader: @escaping (Data) -> Void)
    {

        self.reader = reader
        
        //TunC_function()
        
        guard let fd = createInterface() else
        {
            return nil
        }
        
        print("Created TUN interface \(fd)")
        
        maybeTun = fd

        guard let interfaceName = self.maybeName else { return nil }
        setAddress(interfaceName: interfaceName, addressString: address, subnetString: "255.255.255.0")
        startTunnel(fd: fd, packetSize: 1500)
    }


    /// Create a TUN interface.
    func createInterface() -> Int32?
    {
        let fd = open("/dev/net/tun", O_RDWR)

        guard fd >= 0 else
        {
            print("Failed to open TUN socket")
            return nil
        }

        var ifr = ifreq()
        ifr.ifr_ifru.ifru_flags =  IFF_TUN | IFF_NO_PI
        let result = ioctl(fd, TUNSETIFF, &ifr)
        print("result of ioctl: \(result)")

        let name = withUnsafePointer(to: ifr.ifr_ifrn.ifrn_name) {
            $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout.size(ofValue: $0)) {
                String(cString: $0)
            }
        }
        self.maybeName = name
        print("interface name: \(self.maybeName)")

        return fd
    }


    func startTunnel(fd: Int32, packetSize: Int)
    {
        if !setSocketNonBlocking(socket: fd)
        {
            return
        }
        let tunQueue = DispatchQueue(label: "concurrentTunQueue", attributes: .concurrent)

        guard let newSource = DispatchSource.makeReadSource(fileDescriptor: fd, queue: tunQueue) as? DispatchSource else
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
            self.handleRead(packetSize: packetSize)
        }

        newSource.resume()

        maybeSource = newSource
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


    public func writeBytes(_ packet: Data) -> Int
    {
        //function writes raw bytes to tun interface, supporting both IPv4 and IPv6 (this is untested but tun should also support other layer 3 protocols)
        //returns the number of bytes written to the interface or a value < 0 for errors

        var totalBytesWritten = 0

        guard let tun_fd = maybeTun else
        {
            print("🛠 problem with tun fd, unable to unwrap")
            return -1
        }

        //print("🛠 TunDevice file descriptor: \(tun_fd)")
        var buffer = [UInt8](packet)
        let bytesToWrite = buffer.count
        //print(buffer)

        while totalBytesWritten < bytesToWrite
        {
            let bytesLeft = bytesToWrite - totalBytesWritten
            var choppedBuffer = [UInt8](Data(buffer[totalBytesWritten..<buffer.count]))
            //print("🛠 bytesLeft: \(bytesLeft)")
            //print("🛠 &choppedBuffer \(&choppedBuffer)")
            let writeCount = write(tun_fd, &choppedBuffer, bytesLeft)
            //print("🛠 write's returned value: \(writeCount)")
            //print("🛠 Bytes TunDevice attempted to write:")
            //printDataBytes(bytes: Data(choppedBuffer), hexDumpFormat: true, seperator: "", decimal: false)

            if writeCount < 0 {
                let errorString = String(cString: strerror(errno))
                print("🛠 Got an error while writing to tun: \(errorString)")
                print("🛠 errno: \(errno)")
                let hexfmt = String(format: "%02x", bytesLeft)
                print("🛠 bytes left: \(bytesLeft), hex: \(hexfmt)")
                print("🛠 bytes attempted to write:")
                printDataBytes(bytes: Data(choppedBuffer), hexDumpFormat: true, seperator: "", decimal: false)

                if errno != EAGAIN
                {
                    print("🛠 EAGAIN")
                    return -1
                }
                else if errno == EINVAL
                {
                    if fcntl(tun_fd, F_GETFD) != -1 || errno != EBADF
                    {
                        print("🛠 File descriptor invalid!!")
                    }
                }

            } else {
                totalBytesWritten += writeCount
                //print("🛠 totalBytesWritten: \(totalBytesWritten)")
            }
        }

        return 0
    }


    func getIdentifier(socket: Int32) -> UInt32?
    {
        //FIXME: remove this function or change to return proper value
        return 0
    }


    func getInterfaceName(fd: Int32) -> String?
    {
        //FIXME: consider removing since self.maybeName returns the same value
        return self.maybeName
    }


    func handleRead(packetSize: Int)
    {
        //print("TunDevice: handle read")
        while true
        {
            guard let (data) = self.read(packetSize: packetSize) else
            {
                return
            }
            
            self.reader(data)
        }
    }


    public func readReady() -> Int
    {
        //print("entered readReady()")
        guard let tun_fd = maybeTun else
        {
            print("🛠 problem with tun fd, unable to unwrap")
            return -1
        }

        while true
        {
            var readFDSet: fd_set = fd_set(__fds_bits: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
            fdZero(&readFDSet)
            fdSet(maybeTun, set: &readFDSet)
            let status = select(tun_fd+1, &readFDSet, nil, nil, nil)
            //print("select returned: \(status)")

            // Because we only specified 1 FD, we do not need to check on which FD the event was received

            // In case of a timeout
//            if status == 0 {
//                return 0
//            }

            // In case of an error, close the connection
            if status == -1 {
                return -1
            }

            return 1
        }


//        int tunfd, sockfd;
//
//        tunfd  = createTunDevice();
//        sockfd = initUDPServer();
//
//        // Enter the main loop
//        while (1) {
//            fd_set readFDSet;
//
//            FD_ZERO(&readFDSet);
//            FD_SET(sockfd, &readFDSet);
//            FD_SET(tunfd, &readFDSet);
//            select(FD_SETSIZE, &readFDSet, NULL, NULL, NULL);
//
//            if (FD_ISSET(tunfd,  &readFDSet)) tunSelected(tunfd, sockfd);
//            if (FD_ISSET(sockfd, &readFDSet)) socketSelected(tunfd, sockfd);
//        }



    }


    public func read(packetSize: Int) -> Data?
    {
        //print("\n📚  Read called on TUN device. 📚")
        //print("Requested packet size is \(packetSize)\n")
                
        guard let source = maybeSource else
        {
            print("source is nil")
            return nil
        }
        
        var buffer = [UInt8](repeating:0, count: packetSize)
        var iovecList = [ iovec(iov_base: &buffer, iov_len: buffer.count) ]
        let iovecListPointer = UnsafeBufferPointer<iovec>(start: &iovecList, count: iovecList.count)
        let tunSocket = Int32((source as DispatchSourceRead).handle)
        var error: Int32 = 0
    
        repeat
        {
            let readCount = readv(tunSocket, iovecListPointer.baseAddress, Int32(iovecListPointer.count))
            error = errno
            //print("readCount: \(readCount)")
            guard readCount > 0 || error == EAGAIN else
            {
                if let errorString = String(utf8String: strerror(errno)), readCount < 0
                {
                    print("Got an error on the tun socket: \(errorString)")
                }
                
                source.cancel()
                print("error in guard")
                return nil
            }

            guard readCount > 0 else
            {
                //print("readCount <= 0")
                return nil
            }

            let data = Data(bytes: &buffer, count: readCount)
            //print("returning data:")
            //printDataBytes(bytes: data, hexDumpFormat: true, seperator: "", decimal: false)
            return (data)
        }
        while error == EAGAIN

        print("outside function")
    }
        

//    func connectControl(socket: Int32) -> Int32?
//    {
//        var flags = ifreq()
//        flags.ifr_ifru.ifru_flags =  IFF_TUN | IFF_NO_PI
//        ioctl(socket, TUNSETIFF, &flags)
//
//        return socket;
//    }


}

/// Replacement for FD_ZERO macro.
///
/// - Parameter set: A pointer to a fd_set structure.
///
/// - Returns: The set that is opinted at is filled with all zero's.
public func fdZero(_ set: inout fd_set) {
    set.__fds_bits = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
}


/// Replacement for FD_SET macro
///
/// - Parameter fd: A file descriptor that offsets the bit to be set to 1 in the fd_set pointed at by 'set'.
/// - Parameter set: A pointer to a fd_set structure.
///
/// - Returns: The given set is updated in place, with the bit at offset 'fd' set to 1.
///
/// - Note: If you receive an EXC_BAD_INSTRUCTION at the mask statement, then most likely the socket was already closed.
public func fdSet(_ fd: Int32?, set: inout fd_set) {

    if let fd = fd {

        let intOffset = fd / 64
        let bitOffset = fd % 64
        let mask: Int = 1 << bitOffset

        switch intOffset {
        case 0: set.__fds_bits.0 = set.__fds_bits.0 | mask
        case 1: set.__fds_bits.1 = set.__fds_bits.1 | mask
        case 2: set.__fds_bits.2 = set.__fds_bits.2 | mask
        case 3: set.__fds_bits.3 = set.__fds_bits.3 | mask
        case 4: set.__fds_bits.4 = set.__fds_bits.4 | mask
        case 5: set.__fds_bits.5 = set.__fds_bits.5 | mask
        case 6: set.__fds_bits.6 = set.__fds_bits.6 | mask
        case 7: set.__fds_bits.7 = set.__fds_bits.7 | mask
        case 8: set.__fds_bits.8 = set.__fds_bits.8 | mask
        case 9: set.__fds_bits.9 = set.__fds_bits.9 | mask
        case 10: set.__fds_bits.10 = set.__fds_bits.10 | mask
        case 11: set.__fds_bits.11 = set.__fds_bits.11 | mask
        case 12: set.__fds_bits.12 = set.__fds_bits.12 | mask
        case 13: set.__fds_bits.13 = set.__fds_bits.13 | mask
        case 14: set.__fds_bits.14 = set.__fds_bits.14 | mask
        case 15: set.__fds_bits.15 = set.__fds_bits.15 | mask
        default: break
        }


    }
}


/// Replacement for FD_CLR macro
///
/// - Parameter fd: A file descriptor that offsets the bit to be cleared in the fd_set pointed at by 'set'.
/// - Parameter set: A pointer to a fd_set structure.
///
/// - Returns: The given set is updated in place, with the bit at offset 'fd' cleared to 0.
public func fdClr(_ fd: Int32?, set: inout fd_set) {

    if let fd = fd {

        let intOffset = fd / 64
        let bitOffset = fd % 64
        let mask: Int = ~(1 << bitOffset)

        switch intOffset {
        case 0: set.__fds_bits.0 = set.__fds_bits.0 & mask
        case 1: set.__fds_bits.1 = set.__fds_bits.1 & mask
        case 2: set.__fds_bits.2 = set.__fds_bits.2 & mask
        case 3: set.__fds_bits.3 = set.__fds_bits.3 & mask
        case 4: set.__fds_bits.4 = set.__fds_bits.4 & mask
        case 5: set.__fds_bits.5 = set.__fds_bits.5 & mask
        case 6: set.__fds_bits.6 = set.__fds_bits.6 & mask
        case 7: set.__fds_bits.7 = set.__fds_bits.7 & mask
        case 8: set.__fds_bits.8 = set.__fds_bits.8 & mask
        case 9: set.__fds_bits.9 = set.__fds_bits.9 & mask
        case 10: set.__fds_bits.10 = set.__fds_bits.10 & mask
        case 11: set.__fds_bits.11 = set.__fds_bits.11 & mask
        case 12: set.__fds_bits.12 = set.__fds_bits.12 & mask
        case 13: set.__fds_bits.13 = set.__fds_bits.13 & mask
        case 14: set.__fds_bits.14 = set.__fds_bits.14 & mask
        case 15: set.__fds_bits.15 = set.__fds_bits.15 & mask
        default: break
        }

    }
}


/// Replacement for FD_ISSET macro
///
/// - Parameter fd: A file descriptor that offsets the bit to be tested in the fd_set pointed at by 'set'.
/// - Parameter set: A pointer to a fd_set structure.
///
/// - Returns: 'true' if the bit at offset 'fd' is 1, 'false' otherwise.
public func fdIsSet(_ fd: Int32?, set: inout fd_set) -> Bool {

    if let fd = fd {

        let intOffset = fd / 64
        let bitOffset = fd % 64
        let mask: Int = 1 << bitOffset

        switch intOffset {
        case 0: return set.__fds_bits.0 & mask != 0
        case 1: return set.__fds_bits.1 & mask != 0
        case 2: return set.__fds_bits.2 & mask != 0
        case 3: return set.__fds_bits.3 & mask != 0
        case 4: return set.__fds_bits.4 & mask != 0
        case 5: return set.__fds_bits.5 & mask != 0
        case 6: return set.__fds_bits.6 & mask != 0
        case 7: return set.__fds_bits.7 & mask != 0
        case 8: return set.__fds_bits.8 & mask != 0
        case 9: return set.__fds_bits.9 & mask != 0
        case 10: return set.__fds_bits.10 & mask != 0
        case 11: return set.__fds_bits.11 & mask != 0
        case 12: return set.__fds_bits.12 & mask != 0
        case 13: return set.__fds_bits.13 & mask != 0
        case 14: return set.__fds_bits.14 & mask != 0
        case 15: return set.__fds_bits.15 & mask != 0
        default: return false
        }

    } else {
        return false
    }
}