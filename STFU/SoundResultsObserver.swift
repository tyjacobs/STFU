//
//  SoundResultsObserver.swift
//  STFU
//
//  Created by Genius on 6/19/22.
//

import Foundation
import SoundAnalysis

class SoundResultsObserver: NSObject, SNResultsObserving {
    
    public var currentResult: String = String()

    func request(_ request: SNRequest, didProduce result: SNResult) {

        guard let result = result as? SNClassificationResult else  { return }
        guard let classification = result.classifications.first else { return }
        
        if (classification.confidence > 0.5) {
            currentResult = classification.identifier
        }
        else {
            currentResult = "shrug"
        }
    }

    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("The the analysis failed: \(error.localizedDescription)")
    }

    func requestDidComplete(_ request: SNRequest) {
        print("The request completed successfully!")
    }
}
