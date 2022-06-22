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
    
    var paused: Bool = false

    var statusItem: NSStatusItem?
    @IBOutlet weak var menu: NSMenu?
    @IBOutlet weak var pauseMenuItem: NSMenuItem?
    
    private let audioEngine: AVAudioEngine = AVAudioEngine()
    private let inputBus: AVAudioNodeBus = AVAudioNodeBus(0)
    private var inputFormat: AVAudioFormat!
    private var streamAnalyzer: SNAudioStreamAnalyzer!
    private let resultsObserver = SoundResultsObserver()
    private let analysisQueue = DispatchQueue(label: "com.sg.AnalysisQueue")
    private var lastPlayTime: Date = Date()
    private let minTimeInSecondsBetweenAlerts: Double = 20.0
    private let listeningMenuIcon = "􀒪"
    private let pausedMenuIcon = "􀻪"
    private let alertingMenuIcon = "􁅈" //"􀉷"
    
    private let listeningImage = NSImage(named: "Listening")
    
    let listeningAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 18),
        .foregroundColor: NSColor.systemBlue,
        .baselineOffset: -1.0
    ]

    let alertAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 18),
        .foregroundColor: NSColor.red,
        .baselineOffset: -1.0
    ]

    let soundFileURL = Bundle.main.url(forResource: "STFU", withExtension: "wav")
    
    override func awakeFromNib() {
        super.awakeFromNib()
     
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        //self.statusItem?.button!.attributedTitle = NSAttributedString(string: self.listeningMenuIcon, attributes: self.listeningAttributes)
        self.statusItem?.button!.image = listeningImage
        
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
            
            if !self.paused {
                if (self.resultsObserver.currentResult == "finger_snapping") {
                    
                    let timesince = -self.lastPlayTime.timeIntervalSinceNow
                    if (timesince > self.minTimeInSecondsBetweenAlerts) {
                        
                        //self.statusItem?.button!.attributedTitle = NSAttributedString(string: self.alertingMenuIcon, attributes: self.alertAttributes)
                        NSSound(named: "STFU.wav")?.play()
                        self.lastPlayTime = Date()
                    }
                }
                else {
                    //self.statusItem?.button!.attributedTitle = NSAttributedString(string: self.listeningMenuIcon, attributes: self.listeningAttributes)
                    self.statusItem?.button!.image = self.listeningImage
                }
            }
        }
    }
    
    @IBAction func pauseAction(_ sender: Any) {
        
        if (pauseMenuItem?.state == NSControl.StateValue.on) {
            pauseMenuItem?.state = NSControl.StateValue.off
            paused = false
            //self.statusItem?.button!.attributedTitle = NSAttributedString(string: self.listeningMenuIcon, attributes: self.listeningAttributes)
        }
        else {
            pauseMenuItem?.state = NSControl.StateValue.on
            paused = true
            //self.statusItem?.button!.attributedTitle = NSAttributedString(string: self.pausedMenuIcon, attributes: self.listeningAttributes)
        }
    }

    @IBAction func setSensitivity(_ senderMenuItem: NSMenuItem) {
        
        let tag = senderMenuItem.tag
        
        // uncheck all sensitivity menu items
        let parentItem: NSMenuItem = senderMenuItem.parent!
        for sensitivityMenuItem in parentItem.submenu!.items {
            sensitivityMenuItem.state = NSControl.StateValue.off
        }
        
        // check the selected sensitivity menu item
        senderMenuItem.state = NSControl.StateValue.on
        
        if (tag == 1) {
            // Low
            resultsObserver.sensitivity = 0.3
        }
        else if (tag == 2) {
            // Medium
            resultsObserver.sensitivity = 0.5
        }
        else if (tag == 3) {
            // Extra Medium
            resultsObserver.sensitivity = 0.8
        }
        else if (tag == 4) {
            // High
            resultsObserver.sensitivity = 0.9
        }
    }
}
