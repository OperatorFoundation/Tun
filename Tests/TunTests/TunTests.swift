import XCTest
import Foundation
import Datable
@testable import Tun

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
        //let destinationAddress: Data = Data(array: [161,35,13,201])
        
        
        let address = "10.4.2.1"
        print("Address: \(address)")
        
        var packetCount = 0
        
        let reader: (Data) -> Void =
        {
            data in
            
            packetCount += 1
            print("packet count: \(packetCount)")
            print("Number of bytes: \(data.count)")
            print("Data: ")
            //printDataBytes(bytes: data, hexDumpFormat: true, separator: "", decimal: false)
        }
        
        guard let tun = TunDevice(address: address, reader: reader) else
        {
            XCTFail()
            return
        }
      
        
        print("Preparing to write to Tun...")

        
        let hexToSend = "4500004000004000400600007f0000017f000001c40d13ad6d4e7ed500000000b002fffffe34000002043fd8010303060101080a175fb6580000000004020000"
        let dataToSend = hexToSend.hexadecimal!
        
        let write1 = tun.writeBytes(dataToSend)
        print("First write result: \(write1)")
        sleep(1)
        let write2 = tun.writeBytes(dataToSend)
        print("Second write result: \(write2)")
        
        sleep(1)
        tun.writeBytes(dataToSend)
        sleep(1)
        tun.writeBytes(dataToSend)
        sleep(1)
        tun.writeBytes(dataToSend)
        sleep(1)
        tun.writeBytes(dataToSend)
        sleep(1)
        
    }
}

extension String
{
    var hexadecimal: Data?
    {
        var data = Data(capacity: count / 2)
        
        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: self, range: NSRange(startIndex..., in: self)) { match, _, _ in
            let byteString = (self as NSString).substring(with: match!.range)
            let num = UInt8(byteString, radix: 16)!
            data.append(num)
        }
        
        guard data.count > 0 else { return nil }
        
        return data
    }
}

