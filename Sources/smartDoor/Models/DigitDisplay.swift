import SwiftyGPIO
import Foundation 

class DigitDisplay {

    private let gpios: [GPIO]
    private var currentlyDisplayedNumber : Int {  
        didSet {
            print("setted display number: \(currentlyDisplayedNumber)")
            self.determineSequence(currentlyDisplayedNumber)
        }
    }

    private let digitSequences : [Int: [Int]] = 
    //               6x  8x9x   12x --> segment gpios (high = off)
    [   
        0: [1,1,0,1,0,1,1,1,1,1,1,1],
        1: [0,0,0,1,0,1,1,1,1,0,0,1],
        2: [1,1,0,0,1,1,1,1,1,0,1,1],
        3: [0,1,0,1,1,1,1,1,1,0,1,1],
        4: [0,0,0,1,1,1,1,1,1,1,0,1],
        5: [0,1,0,1,1,1,0,1,1,1,1,1],
        6: [1,1,0,1,1,1,0,1,1,1,1,1],
        7: [0,0,0,1,0,1,1,1,1,0,1,1],
        8: [1,1,0,1,1,1,1,1,1,1,1,1],
        9: [0,1,0,1,1,1,1,1,1,1,1,1] 
    ]
    // pos of gpio in digitseq, set low to activate segment
    private let segmentgpio = [11,8,7,5]

    private var displaySequences: [[Int]] = []

    init(gpios: [GPIO]) {
        for gpio in gpios {
            gpio.direction = .OUT
        }
        self.gpios = gpios
        self.currentlyDisplayedNumber = 0
        self.determineSequence(currentlyDisplayedNumber)
    }

    func reset(){
        currentlyDisplayedNumber = 0
    }

    func increment(){
        currentlyDisplayedNumber += 1
    }

    func decrement(){
        currentlyDisplayedNumber -= 1
    }

    func displayNumber(_ number: Int){
        currentlyDisplayedNumber = number
    }

    func display() {
        for seq in displaySequences {
            var seqIndex = 0
            for gpio in gpios {
                gpio.value = seq[seqIndex]
                seqIndex += 1
            }
            usleep(2000)
        }
    }

    func switchSegments(s1: Bool, s2: Bool, s3: Bool, s4: Bool){
        let segBools = [s1,s2,s3,s4]
        for (i,segBool) in segBools.enumerated() {
            // segment onn = low = 0 
            self.displaySequences[i][segmentgpio[i]] = segBool ? 0 : 1
        } 
    }

    func switchOff(){
        self.switchSegments(s1:false, s2:false, s3:false, s4:false)
    }

    private func determineSequence(_ num: Int) {
        guard num >= 0 && num <= 9999 else {
            reset()
            return 
        }
        
        self.displaySequences = []
        // 12,9,8,6 (not indexed)
        var numStr = String(num)
        let numberOfPrefixedZeros = 4 - numStr.length
        if (numberOfPrefixedZeros != 0){
            for _ in 1...numberOfPrefixedZeros {
                numStr = "0" + numStr
            }
        }

        print("numstr: \(numStr)")
        for (i,numChar) in numStr.enumerated() {
            if let digit = Int(String(numChar)),
                let sequence = self.digitSequences[digit] { 
                var varSeq = sequence
                varSeq[segmentgpio[i]] = 0
                displaySequences.append(varSeq)
            }
        }
        print("display seq: \(displaySequences)")
    }

}