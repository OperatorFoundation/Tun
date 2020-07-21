import XCTest
import Foundation
import InternetProtocols
@testable import Tun



func generateChecksum(data: Data) -> UInt16?
{
//    let data = Data(array: [
//        0x45, 0x00, 0x00, 0x3c, 0xea, 0x55, 0x40, 0x00, 0x40, 0x06,
//        0x5f, 0xa3,
//        0x0a, 0xd3,
//        0x37, 0x04, 0xa1, 0x23, 0x0d, 0xc9])
//    //5fa3
    
    var sum: UInt64 = 0
    let carryMask: UInt64 = ~0xFFFF
    var carry: UInt64 = 0
    
    for i in 0..<(data.count/2)
    {
        let bytes = data.subdata( in: (i*2)..<(i*2+2) )
        
        guard let value = bytes.uint16 else
        {
            XCTFail()
            return nil
        }
        
        if i != 5
        {
            sum += UInt64(value)
            carry = (sum & carryMask) >> 16
        }
    }
    
    print(">>>>><<<<<")
    var x = (sum & 0xFFFF) + carry

    x = ~x & 0xFFFF
    
    let checksum = UInt16(~((sum & 0xFFFF) + carry) & 0xFFFF)
    
    print("checksum: \(x)")
    printDataBytes(bytes: Data(uint16: checksum)!, hexDumpFormat: true, seperator: " ", decimal: false)

    return checksum
    
}





final class TunTests: XCTestCase
{
    
    

    
    
    func testSendReceivePackets()
    {
        /*
         define destination address and port
         setup a tun interface for reading and writing packets
         construct a tcp SYN packet using internet protocols
         send the SYN packet out tun interface
         packet gets routed by os from TUN to internet destination
         internet destination sends a syn-ack packet to OS, OS forwards to TUN
         read out packet from TUN
         If we get a matching packet, then test passes
         */
        print("Sleeping 2 seconds to allow debugger to attach to process...")
        sleep(2)
        let destinationAddress: Data = Data(array: [161,35,13,201])
        
        print("Hello, Operator.")
        
        let address = "10.2.0.1"
        
        print("Address: \(address)")
        
        var packetCount = 0
        
        let reader: (Data, UInt32) -> Void = {
            data, protocolNumber in
            packetCount += 1
            print("packet count: \(packetCount)")
            print("protocolNumber: \(protocolNumber)")
            print("Number of bytes: \(data.count)")
            print("Data: ")
            printDataBytes(bytes: data, hexDumpFormat: true, seperator: "", decimal: false)
        }
        
        guard let tun = TunDevice(address: address, reader: reader) else
        {
            XCTFail()
            return
        }
        print("Sleeping 30 seconds to allow wireshark to attach to interface...")
        sleep(30)
        
        let dataToSend = Data(array: [
            0x45, 0x00, 0x00, 0x40, 0x00, 0x00, 0x40, 0x00, 0x40, 0x06, 0x26, 0xb3, 0x0a, 0x02, 0x00, 0x01, 0x0a, 0x02, 0x00, 0x01, 0xc8, 0xb1, 0x00, 0x16, 0x25, 0x4b, 0x70, 0x3e, 0x00, 0x00, 0x00, 0x00, 0xb0, 0xc2, 0xff, 0xff, 0x7e, 0x2f, 0x00, 0x00, 0x02, 0x04, 0x05, 0xb4, 0x01, 0x03, 0x03, 0x06, 0x01, 0x01, 0x08, 0x0a, 0x5a, 0xc1, 0xea, 0xf4, 0x00, 0x00, 0x00, 0x00, 0x04, 0x02, 0x00, 0x00
])
        
            
            
        for i in 0...dataToSend.count
        {
            print("attempt # \(i)")
            let send = dataToSend.subdata( in: 0..<i )
            printDataBytes(bytes: send, hexDumpFormat: true, seperator: "", decimal: false)
            tun.writeV4(send)
            
        }
        
        

        
        for i in 1...30 {
            print(i)
            if let result = tun.read(packetSize: 1024)
            {
                print("Result of read: \(result)")
                reader(result.0, result.1)
            }
            
            print("sleeping 1")
            sleep(1)
        }
        
        
        //
        //
        //        print("sleeping 2")
        //        sleep(2)
        //
        //        print("sleeping 2")
        //        sleep(2)
        //
        //        print("sleeping 2")
        //        sleep(2)
        //
        //        print("sleeping 2")
        //        sleep(2)
        //
        //        print("sleeping 2")
        //        sleep(2)
        //
        //        print("sleeping 2")
        //        sleep(2)
        //
        //        print("sleeping 2")
        //        sleep(2)
        //
        //        print("sleeping 2")
        //        sleep(2)
        //
        //        print("sleeping 2")
        //        sleep(2)
        //
        //        print("sleeping 2")
        //        sleep(2)
        //
        //        print("sleeping 20")
        //        sleep(20)
        
        
    }
    
    
}
