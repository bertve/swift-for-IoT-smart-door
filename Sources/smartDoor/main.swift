import SwiftyGPIO
import Foundation
import Glibc

// setup exit sig
var signalReceived: sig_atomic_t = 0
signal(SIGINT) { signal in
    signalReceived = signal
}

// welcome 
print("-------WELCOME-------")
print("Press CTRL_C to exit.")

// setup services
let mqttService = MQTTService()
let controller = GPIOController(mqttService: mqttService)
let jsonDecoder = JSONDecoder()

// setup listeners
mqttService.subscribe(to: "door")
mqttService.client.addMessageListener { _, message, _ in
    print(message)
    if  let payload = message.payload,
        let json = payload.getString(at: payload.readerIndex, length: payload.readableBytes) {
                if let data = json.data(using: .utf8),
                   let doorRequest = try? jsonDecoder.decode(DoorRequest.self, from: data){
                    doorRequest.openDoor ? controller.openDoor() : controller.closeDoor()
                }
    }
}

// main loop
while signalReceived == 0 {

}

// cleanup
controller.switchOff()
exit(signalReceived)
