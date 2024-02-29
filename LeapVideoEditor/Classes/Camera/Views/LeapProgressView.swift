//
//  LeapProgressView.swift
//  LeapVideoEditor
//
//  Created by Jovanpreet Randhawa on 02/09/22.
//

import UIKit

public class LeapProgressView: UIView {
    
    let progressBar: UIProgressView = {
        let progressBar = UIProgressView()
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        return progressBar
    }()
    
    let maxTimeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 8, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let progressSectionContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(progressBar)
        addSubview(maxTimeLabel)
        addSubview(timeLabel)
        addSubview(progressSectionContainer)
        
        NSLayoutConstraint.activate([
            progressBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            progressBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            progressBar.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            progressBar.heightAnchor.constraint(equalToConstant: 6),
            maxTimeLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 3),
            maxTimeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            timeLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 14),
            timeLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            progressSectionContainer.leadingAnchor.constraint(equalTo: progressBar.leadingAnchor),
            progressSectionContainer.trailingAnchor.constraint(equalTo: progressBar.trailingAnchor),
            progressSectionContainer.topAnchor.constraint(equalTo: progressBar.topAnchor),
            progressSectionContainer.bottomAnchor.constraint(equalTo: progressBar.bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupProgressSections(recordings: [(recordURL: URL, duration: Double, isPhoto: Bool)], maxDuration: Double) {
        progressSectionContainer.subviews.forEach { $0.removeFromSuperview() }
        var totalDuration: Double = 0
        for recording in recordings {
            totalDuration += recording.duration
            let proportion = totalDuration/maxDuration
            let leadingSpace = (UIScreen.main.bounds.width-32)*proportion
            let separator = UIView()
            separator.backgroundColor = UIColor(named: "backgroundColor", in: LeapBundleHelper.resourcesBundle, compatibleWith: nil)
            separator.translatesAutoresizingMaskIntoConstraints = false
            progressSectionContainer.addSubview(separator)
            NSLayoutConstraint.activate([
                separator.widthAnchor.constraint(equalToConstant: 2),
                separator.topAnchor.constraint(equalTo: progressSectionContainer.topAnchor),
                separator.bottomAnchor.constraint(equalTo: progressSectionContainer.bottomAnchor),
                separator.leadingAnchor.constraint(equalTo: progressSectionContainer.leadingAnchor, constant: leadingSpace)
            ])
        }
    }
}
