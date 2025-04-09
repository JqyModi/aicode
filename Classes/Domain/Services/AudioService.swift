import Foundation
import Combine
import AVFoundation

protocol AudioServiceProtocol {
    func getAudioForWord(word: String, speed: Float) -> AnyPublisher<URL, Error>
    func playAudio(url: URL) -> AnyPublisher<Bool, Error>
    func stopAudio() -> Void
}

class AudioService: AudioServiceProtocol {
    private var audioPlayer: AVAudioPlayer?
    private let synthesizer = AVSpeechSynthesizer()
    private let fileManager = FileManager.default
    private var cancellables = Set<AnyCancellable>()
    
    // 获取单词的音频文件
    func getAudioForWord(word: String, speed: Float) -> AnyPublisher<URL, Error> {
        return Future<URL, Error> { promise in
            // 检查缓存中是否已有该单词的音频
            if let cachedURL = self.getCachedAudioURL(for: word) {
                promise(.success(cachedURL))
                return
            }
            
            // 生成新的音频文件
            let utterance = AVSpeechUtterance(string: word)
            utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
            utterance.rate = speed * AVSpeechUtteranceDefaultSpeechRate
            
            // 创建临时文件URL
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "\(word)_\(Int(speed * 10)).m4a"
            let fileURL = tempDir.appendingPathComponent(fileName)
            
            // 使用语音合成器生成音频
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playback, mode: .default)
                try audioSession.setActive(true)
                
                // 使用AVAudioEngine录制合成的语音
                let audioEngine = AVAudioEngine()
                let mixer = audioEngine.mainMixerNode
                
                let format = mixer.outputFormat(forBus: 0)
                audioEngine.connect(mixer, to: audioEngine.outputNode, format: format)
                
                let file = try AVAudioFile(forWriting: fileURL, settings: format.settings)
                
                mixer.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, time in
                    try? file.write(from: buffer)
                }
                
                try audioEngine.start()
                
                // 开始合成
                self.synthesizer.speak(utterance)
                
                // 等待合成完成
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    audioEngine.stop()
                    mixer.removeTap(onBus: 0)
                    
                    // 保存到缓存
                    self.cacheAudio(url: fileURL, for: word)
                    
                    promise(.success(fileURL))
                }
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    // 播放音频
    func playAudio(url: URL) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            do {
                self.audioPlayer = try AVAudioPlayer(contentsOf: url)
                self.audioPlayer?.prepareToPlay()
                let success = self.audioPlayer?.play() ?? false
                promise(.success(success))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    // 停止播放
    func stopAudio() {
        audioPlayer?.stop()
    }
    
    // 获取缓存的音频URL
    private func getCachedAudioURL(for word: String) -> URL? {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let audioDir = cacheDir.appendingPathComponent("audio")
        let fileURL = audioDir.appendingPathComponent("\(word).m4a")
        
        if fileManager.fileExists(atPath: fileURL.path) {
            return fileURL
        }
        
        return nil
    }
    
    // 缓存音频文件
    private func cacheAudio(url: URL, for word: String) {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let audioDir = cacheDir.appendingPathComponent("audio")
        
        do {
            if !fileManager.fileExists(atPath: audioDir.path) {
                try fileManager.createDirectory(at: audioDir, withIntermediateDirectories: true)
            }
            
            let destinationURL = audioDir.appendingPathComponent("\(word).m4a")
            
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            
            try fileManager.copyItem(at: url, to: destinationURL)
        } catch {
            print("缓存音频文件失败: \(error)")
        }
    }
}