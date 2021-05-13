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
        //TODO: setup green led
        greenLED = gpios[.P22]
        if let led = greenLED {
            led.direction = .OUT
        }


        // setup display
        var digitDisplayGPIO = [GPIO]()
        guard let gpioOne = gpios[.P14] else {
            fatalError("Could not init target 14 gpio")
        }
        digitDisplayGPIO.append(gpioOne)
        guard let gpioTwo = gpios[.P16] else {
            fatalError("Could not init target 16 gpio")
        }
        digitDisplayGPIO.append(gpioTwo)
        guard let gpioThree = gpios[.P17] else {
            fatalError("Could not init target 17 gpio")
        }
        digitDisplayGPIO.append(gpioThree)
        guard let gpioFour = gpios[.P4] else {
            fatalError("Could not init target 4 gpio")
        }
        digitDisplayGPIO.append(gpioFour)
        guard let gpioFive = gpios[.P5] else {
            fatalError("Could not init target 5 gpio")
        }
        digitDisplayGPIO.append(gpioFive)
        guard let gpioSix = gpios[.P6] else {
            fatalError("Could not init target 6 gpio")
        }
        digitDisplayGPIO.append(gpioSix)
        guard let gpioSeven = gpios[.P7] else {
            fatalError("Could not init target 7 gpio")
        }
        digitDisplayGPIO.append(gpioSeven)
        guard let gpioEight = gpios[.P8] else {
            fatalError("Could not init target 8 gpio")
        }
        digitDisplayGPIO.append(gpioEight)
        guard let gpioNine = gpios[.P9] else {
            fatalError("Could not init target 9 gpio")
        }
        digitDisplayGPIO.append(gpioNine)
        guard let gpioTen = gpios[.P15] else {
            fatalError("Could not init target 15 gpio")
        }
        digitDisplayGPIO.append(gpioTen)
        guard let gpioEleven = gpios[.P18] else {
            fatalError("Could not init target 18 gpio")
        }
        digitDisplayGPIO.append(gpioEleven)
        guard let gpioTwelve = gpios[.P12] else {
            fatalError("Could not init target 12 gpio")
        }
        digitDisplayGPIO.append(gpioTwelve)

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
                        usleep(250000)
                    if let aT = self.ambientTemp {
                        self.display(Int(oT))
                        let tempData = TempData(ambientTemp: aT, objectTemp: oT)
                        print("publishing...")
                        print(tempData)
                        self.mqttService.publish(to:"temperature",with: tempData)
                    }
                }
                usleep(250000)
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