import SwiftyGPIO
import Glibc

class MLX90614 {
    let i2c: I2CInterface
    let address: Int
    let adrAmbientTemp: UInt8 = 0x06
    let adrObjectTemp1: UInt8 = 0x07
    let adrObjectTemp2: UInt8 = 0x08
    
    var ambientTemp: Double {
        return data_to_temp(read(command: adrAmbientTemp))
    }

    var objectTemp: Double {
        return data_to_temp(read(command: adrObjectTemp1))
    }

    init(i2c: I2CInterface, address: Int = 0x5a){
        self.i2c = i2c
        self.address = address
    }

    func detect(){
        print("Detecting devices on the I2C bus:\n")
        outer: for i in 0x0...0x7 {
            if i == 0 {
                print("    0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f")
            }
            for j in 0x0...0xf {
                if j == 0 {
                    print(String(format:"%x0",i), terminator: "")
                }
                // Test within allowed range 0x3...0x77
                if (i==0) && (j<3) {print("   ", terminator: "");continue}
                if (i>=7) && (j>=7) {break outer}
                
                print(" \(i2c.isReachable(i<<4 + j) ? " x" : " ." )", terminator: "")
            }
            print()
        }
        print("\n")
    }

    private func read(command: UInt8) -> UInt16 {
        return i2c.readWord(address, command: command)
    }

    private func data_to_temp(_ data: UInt16) -> Double {
        return round(((Double(data) * 0.02) - 273.15) * 100)/100
    }

}