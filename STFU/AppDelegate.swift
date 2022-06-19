//
//  AppDelegate.swift
//  STFU
//
//  Created by Genius on 6/19/22.
//

import Cocoa
import AVFAudio
import AVFoundation
import SoundAnalysis

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusItem: NSStatusItem?
    @IBOutlet weak var menu: NSMenu?
    @IBOutlet weak var menuItem: NSMenuItem?
    
    private let audioEngine: AVAudioEngine = AVAudioEngine()
    private let inputBus: AVAudioNodeBus = AVAudioNodeBus(0)
    private var inputFormat: AVAudioFormat!
    private var streamAnalyzer: SNAudioStreamAnalyzer!
    private let resultsObserver = SoundResultsObserver()
    private let analysisQueue = DispatchQueue(label: "com.sg.AnalysisQueue")
    private var lastPlayTime: Date = Date()
    
    let soundFileURL = Bundle.main.url(forResource: "STFU", withExtension: "wav")
    
    override func awakeFromNib() {
        super.awakeFromNib()
     
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "STFU"
        
        if let menu = menu {
            statusItem?.menu = menu
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        inputFormat = audioEngine.inputNode.inputFormat(forBus: inputBus)

        do {
            try audioEngine.start()

            audioEngine.inputNode.installTap(onBus: inputBus,
                                             bufferSize: 8192,
                                             format: inputFormat, block: analyzeAudio(buffer:at:))

            streamAnalyzer = SNAudioStreamAnalyzer(format: inputFormat)
            let request = try SNClassifySoundRequest(classifierIdentifier: SNClassifierIdentifier.version1)
            try streamAnalyzer.add(request, withObserver: resultsObserver)


        } catch {
            print("Unable to start AVAudioEngine: \(error.localizedDescription)")
        }
    }

    func analyzeAudio(buffer: AVAudioBuffer, at time: AVAudioTime) {
        analysisQueue.async { [self] in
            self.streamAnalyzer.analyze(buffer,
                                        atAudioFramePosition: time.sampleTime)
        }
        
        DispatchQueue.main.async {
            self.statusItem?.button?.title = self.resultsObserver.currentResult
            
            if (self.resultsObserver.currentResult == "shrug") {
                self.statusItem?.button?.title = ""
                self.statusItem?.button?.isHighlighted = false
            }
            else if (self.resultsObserver.currentResult == "burp") {
                
                let timesince = self.lastPlayTime.timeIntervalSinceNow
                if (timesince < -20.0) {
                
                    self.statusItem?.button?.title = "STFU"
                    NSSound(named: "STFU.wav")?.play()
                    
                    self.statusItem?.button?.isHighlighted = true
                    self.lastPlayTime = Date()
                }
            }
            else {
                self.statusItem?.button?.title = self.resultsObserver.currentResult
                self.statusItem?.button?.isHighlighted = true
            }
        }
    }
}
