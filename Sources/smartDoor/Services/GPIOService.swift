import SwiftyGPIO
import Foundation
import Glibc

class GPIOService {

    init(mqttService: MQTTService){
        self.mqttService = mqttService
        setup()
    }

    private let mqttService : MQTTService

    private let gpios: [GPIOName: GPIO] = SwiftyGPIO.GPIOs(for: .RaspberryPi4)
    private let i2cs = SwiftyGPIO.hardwareI2Cs(for: .RaspberryPi4)!
    private var redLED: GPIO?
    private var greenLED: GPIO?
    private var digitDisplay: DigitDisplay?
    private var mlx90614: MLX90614?

    private var objectTemp: Double? {
        return mlx90614?.objectTemp
    }

    private var ambientTemp: Double? {
        return mlx90614?.ambientTemp
    }

    var permissionPublishingTempData = false

    func setup(){

        // setup LEDs
        redLED = gpios[.P21]
        if let led = redLED {
            led.direction = .OUT
        }

        greenLED = gpios[.P22]
        if let led = greenLED {
            led.direction = .OUT
        }


        // setup display
        let gpioNames : [GPIOName] = [.P14, .P16, .P17, .P4, .P5, .P6, .P7, .P8, .P9, .P15, .P18, .P12]
        var digitDisplayGPIO = [GPIO]()
        for gpioName in gpioNames {
            guard let gpio = gpios[gpioName] else {
                fatalError("Could not init target \(gpioName)")
            }
            digitDisplayGPIO.append(gpio)
        }
        digitDisplay = DigitDisplay(gpios: digitDisplayGPIO )

        if let display = digitDisplay {
            Thread.detachNewThread {
                while true {
                    display.display()
                }
            }
        }

        // setup XML90416
        mlx90614 = MLX90614(i2c: i2cs[1])

        // setup btn
        guard let btn = gpios[.P20] else {
            fatalError("Could not init target gpio")
        }
        btn.direction = .IN
        let debounceTime = 0.5
        btn.bounceTime = debounceTime
        btn.onRaising{
            gpio in
            // publish if not already publishing
            if !self.permissionPublishingTempData {
                self.publishTempData()
            }
        }
    }

    func toggleRedLight(_ state: LightState){
        if let led = redLED {
            self.toggleLight(led,state)
        }
    }

    func toggleGreenLight(_ state: LightState){
        if let led = greenLED {
            self.toggleLight(led,state)
        }
    }

    private func toggleLight(_ led: GPIO,_ state: LightState){
            switch state {
                case .onn:
                led.value = 1
                case .off:
                led.value = 0
            }
    }

    func incrementDisplay(){
        if let display = digitDisplay {
            display.increment()
        } 
    }

    func decrementDisplay(){
        if let display = digitDisplay {
            display.decrement()
        } 
    }

    func display(_ number: Int){
        if let display = digitDisplay {
            display.displayNumber(number)
        } 
    }

    func resetDisplay() {
        if let display = digitDisplay {
            display.reset()
        }
    }

    private func publishTempData(){
        self.permissionPublishingTempData = true
        Thread.detachNewThread {
            while self.permissionPublishingTempData {
                if let oT = self.objectTemp {
                        // preventing data collision
                        usleep(100000)
                    if let aT = self.ambientTemp {
                        self.display(Int(oT))
                        let tempData = TempData(ambientTemp: aT, objectTemp: oT)
                        print("publishing...")
                        print(tempData)
                        self.mqttService.publish(to:"temperature",with: tempData)
                    }
                }
            }
            // publishing ends 
            self.resetDisplay()
        }
    }

    func switchOff(){
        if let display = self.digitDisplay {
            display.switchOff()
        }
    }

}