import AVFoundation
import SwiftUI
import UIKit

/// SwiftUI wrapper for the Apple Pencil pressure and vertical angle joystick.
public struct PencilVerticalJoystickView: View {
    @ObservedObject public var state: PencilJoystickState

    private let showsReadout: Bool
    private let configuration: PencilJoystickConfiguration

    public init(
        state: PencilJoystickState,
        showsReadout: Bool = true,
        configuration: PencilJoystickConfiguration = .init()
    ) {
        self.state = state
        self.showsReadout = showsReadout
        self.configuration = configuration
    }

    public var body: some View {
        VStack(spacing: 5) {
            if showsReadout {
                Text("Apple Pencil")
                    .font(configuration.titleFont)
                    .foregroundStyle(.green.opacity(0.5))

                HStack {
                    Text("Pressure:")
                        .foregroundStyle(.orange.opacity(0.5))
                    Text(String(format: "%.2f", state.pressure))
                        .foregroundStyle(Color(state.knobColor))
                }
                .font(configuration.valueFont)

                Text("Angle:\(Int(state.angleDegrees))")
                    .font(configuration.angleFont)
                    .foregroundStyle(.blue.opacity(0.5))
            }

            PencilVerticalJoystickRepresentable(state: state, configuration: configuration)
                .frame(width: configuration.controlWidth, height: configuration.controlHeight)
        }
        .frame(width: configuration.totalWidth)
    }
}

public struct PencilJoystickConfiguration {
    public var totalWidth: CGFloat
    public var controlWidth: CGFloat
    public var controlHeight: CGFloat
    public var pressureMultiplier: CGFloat
    public var pressureSampleCount: Int
    public var resetsKnobOnEnd: Bool
    public var playsEngineSound: Bool
    public var engineSoundResourceName: String?
    public var engineSoundExtension: String
    public var titleFont: Font
    public var valueFont: Font
    public var angleFont: Font

    public init(
        totalWidth: CGFloat = 220,
        controlWidth: CGFloat = 100,
        controlHeight: CGFloat = 400,
        pressureMultiplier: CGFloat = 200,
        pressureSampleCount: Int = 5,
        resetsKnobOnEnd: Bool = true,
        playsEngineSound: Bool = true,
        engineSoundResourceName: String? = nil,
        engineSoundExtension: String = "mp3",
        titleFont: Font = .system(size: 30, weight: .semibold, design: .rounded),
        valueFont: Font = .system(size: 34, weight: .semibold, design: .rounded),
        angleFont: Font = .system(size: 30, weight: .semibold, design: .rounded)
    ) {
        self.totalWidth = totalWidth
        self.controlWidth = controlWidth
        self.controlHeight = controlHeight
        self.pressureMultiplier = pressureMultiplier
        self.pressureSampleCount = pressureSampleCount
        self.resetsKnobOnEnd = resetsKnobOnEnd
        self.playsEngineSound = playsEngineSound
        self.engineSoundResourceName = engineSoundResourceName
        self.engineSoundExtension = engineSoundExtension
        self.titleFont = titleFont
        self.valueFont = valueFont
        self.angleFont = angleFont
    }
}

internal struct PencilVerticalJoystickRepresentable: UIViewRepresentable {
    @ObservedObject var state: PencilJoystickState
    var configuration: PencilJoystickConfiguration

    func makeUIView(context: Context) -> PencilJoystickCanvasView {
        let view = PencilJoystickCanvasView()
        view.configure(state: state, configuration: configuration)
        PencilJoystickOverlayState.shared.canvasView = view
        return view
    }

    func updateUIView(_ uiView: PencilJoystickCanvasView, context: Context) {
        uiView.configure(state: state, configuration: configuration)
        uiView.stick.updateColor(for: state.pressure, state: state)
    }

    static func dismantleUIView(_ uiView: PencilJoystickCanvasView, coordinator: Void) {
        if PencilJoystickOverlayState.shared.canvasView === uiView {
            PencilJoystickOverlayState.shared.canvasView = nil
        }
    }
}

internal final class PencilJoystickCanvasView: UIView, UIPencilInteractionDelegate {
    var state: PencilJoystickState?
    var configuration = PencilJoystickConfiguration()

    private var pressureSamples: [CGFloat] = []
    private var audioPlayer: AVAudioPlayer?
    private var stickWidthConstraint: NSLayoutConstraint?
    private var stickHeightConstraint: NSLayoutConstraint?

    let stick = PencilJoystickUIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStick()

        let interaction = UIPencilInteraction()
        interaction.delegate = self
        addInteraction(interaction)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupStick()
    }

    func configure(state: PencilJoystickState, configuration: PencilJoystickConfiguration) {
        self.state = state
        self.configuration = configuration
        stickWidthConstraint?.constant = configuration.controlWidth
        stickHeightConstraint?.constant = configuration.controlHeight

        if configuration.playsEngineSound {
            prepareAudioIfNeeded()
        } else {
            audioPlayer?.stop()
            audioPlayer = nil
        }
    }

    private func setupStick() {
        stick.translatesAutoresizingMaskIntoConstraints = false
        stick.onPositionChanged = { [weak self] position in
            self?.state?.angleDegrees = position
        }
        addSubview(stick)

        stickWidthConstraint = stick.widthAnchor.constraint(equalToConstant: configuration.controlWidth)
        stickHeightConstraint = stick.heightAnchor.constraint(equalToConstant: configuration.controlHeight)

        NSLayoutConstraint.activate([
            stickWidthConstraint!,
            stickHeightConstraint!,
            stick.centerXAnchor.constraint(equalTo: centerXAnchor),
            stick.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first, touch.type == .stylus else { return }
        updatePressureAndPosition(from: touch)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first, touch.type == .stylus else { return }
        updatePressureAndPosition(from: touch)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        resetTouch()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        resetTouch()
    }

    private func updatePressureAndPosition(from touch: UITouch) {
        let pressure = touch.force * configuration.pressureMultiplier
        pressureSamples.append(pressure)
        if pressureSamples.count > configuration.pressureSampleCount {
            pressureSamples.removeFirst()
        }

        let averagePressure = pressureSamples.reduce(0, +) / CGFloat(pressureSamples.count)
        state?.pressure = averagePressure
        stick.updateColor(for: averagePressure, state: state)
        updateEngineSound(for: averagePressure)
        updateKnobPosition(from: touch)
    }

    private func updateKnobPosition(from touch: UITouch) {
        let location = touch.location(in: stick)
        stick.setKnobY(location.y, animated: false)
    }

    private func resetTouch() {
        state?.pressure = 0
        pressureSamples.removeAll()
        updateEngineSound(for: 0)

        guard configuration.resetsKnobOnEnd else { return }
        stick.resetKnobPosition()
    }

    private func prepareAudioIfNeeded() {
        guard configuration.playsEngineSound else { return }
        guard audioPlayer == nil else { return }
        guard let resourceName = configuration.engineSoundResourceName else { return }
        guard let sound = JoystickResources.bundle.url(
            forResource: resourceName,
            withExtension: configuration.engineSoundExtension
        ) else {
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: sound)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.enableRate = true
            audioPlayer?.play()
        } catch {
            audioPlayer = nil
        }
    }

    private func updateEngineSound(for pressure: CGFloat) {
        guard configuration.playsEngineSound else { return }
        if audioPlayer == nil {
            prepareAudioIfNeeded()
        }
        audioPlayer?.rate = Float(min(max(pressure / 50.0, 1), 2.3))
    }

    isolated deinit {
        audioPlayer?.stop()
        if PencilJoystickOverlayState.shared.canvasView === self {
            PencilJoystickOverlayState.shared.canvasView = nil
        }
    }
}

internal final class PencilJoystickUIView: UIView {
    let knob = UIView()
    let gradientBar = UIView()

    private let gradientLayer = CAGradientLayer()
    private var initialKnobCenterY: CGFloat?

    var onPositionChanged: ((CGFloat) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradientBar()
        setupJoystick()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradientBar()
        setupJoystick()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = gradientBar.bounds
        if initialKnobCenterY == nil {
            initialKnobCenterY = gradientBar.frame.midY
        }
    }

    func setKnobY(_ y: CGFloat, animated: Bool) {
        layoutIfNeeded()
        let knobRadius = knob.bounds.height / 2
        let boundedY = min(max(y, knobRadius), gradientBar.frame.maxY - knobRadius)

        let update = {
            self.knob.center.y = boundedY
            let joystickPosition = boundedY - self.gradientBar.frame.midY
            let adjustedPosition = joystickPosition / 230 * -251
            self.onPositionChanged?(adjustedPosition)
        }

        if animated {
            UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.6, options: [.curveEaseInOut], animations: update)
        } else {
            update()
        }
    }

    func resetKnobPosition() {
        layoutIfNeeded()
        setKnobY(initialKnobCenterY ?? gradientBar.frame.midY, animated: true)
        onPositionChanged?(0)
    }

    func updateColor(for pressure: CGFloat, state: PencilJoystickState?) {
        let normalizedPressure = min(max(pressure / 833.33, 0.0), 1.0)
        let color = UIColor(
            hue: normalizedPressure * 0.8,
            saturation: 0.8,
            brightness: 0.9,
            alpha: 1.0
        )
        state?.knobColor = color
        knob.backgroundColor = color
    }

    private func setupGradientBar() {
        gradientBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(gradientBar)

        NSLayoutConstraint.activate([
            gradientBar.widthAnchor.constraint(equalToConstant: 10),
            gradientBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 45),
            gradientBar.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            gradientBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])

        gradientLayer.colors = [
            UIColor.red.cgColor,
            UIColor.orange.cgColor,
            UIColor.yellow.cgColor,
            UIColor.green.cgColor,
            UIColor.cyan.cgColor,
            UIColor.blue.cgColor,
            UIColor.purple.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.cornerRadius = 5
        gradientBar.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func setupJoystick() {
        backgroundColor = .clear
        knob.layer.cornerRadius = 25
        knob.layer.borderColor = UIColor.white.cgColor
        knob.layer.borderWidth = 1.6
        knob.layer.shadowOffset = CGSize(width: 0, height: 2)
        knob.layer.shadowOpacity = 0.7
        knob.layer.shadowColor = UIColor.systemCyan.cgColor
        knob.layer.shadowRadius = 10
        knob.translatesAutoresizingMaskIntoConstraints = false
        addSubview(knob)

        NSLayoutConstraint.activate([
            knob.widthAnchor.constraint(equalToConstant: 50),
            knob.heightAnchor.constraint(equalToConstant: 50),
            knob.centerXAnchor.constraint(equalTo: gradientBar.centerXAnchor),
            knob.centerYAnchor.constraint(equalTo: gradientBar.centerYAnchor)
        ])
    }
}
