import Foundation
class GPIOController {

    private let service : GPIOService    

    init(mqttService: MQTTService){
        self.service = GPIOService(mqttService: mqttService)
    }

    func openDoor(){
        stopPublishingTempData()
        Thread.detachNewThread {
            self.service.toggleGreenLight(.onn)
            sleep(3)
            self.service.toggleGreenLight(.off)
        }
    }

    func closeDoor(){
        stopPublishingTempData()
        Thread.detachNewThread {               
            self.service.toggleRedLight(.onn)
            sleep(3)
            self.service.toggleRedLight(.off)
        }
    }

    private func stopPublishingTempData(){
        service.permissionPublishingTempData = false
    }

    func switchOff(){
        service.switchOff()
    }

}