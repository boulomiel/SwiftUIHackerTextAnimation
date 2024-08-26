//
//  ContentView.swift
//  TabView
//
//  Created by Ruben  on 25/08/2024.
//

import SwiftUI
import Combine

@MainActor let characters: [Character] = [
    // Uppercase letters
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
    // Lowercase letters
    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
    // Numbers
    "1", "2", "3", "4", "5", "6", "7", "8", "9",
    
    // Space
    " "
]

struct DataModel: Identifiable, Sendable {
    let id: UUID = .init()
    let url: URL
    let sentence: String
    let angle: ViewAngle = .init()

    @MainActor
    static var dataData: [Self] = [
        .init(url:
                .init(string: "https://gratisography.com/wp-content/uploads/2024/01/gratisography-cyber-kitty-800x525.jpg")!,
              sentence: "Groovy Cat"),
        .init(url:.init(string: "https://h5p.org/sites/default/files/h5p/content/1209180/images/file-6113d5f8845dc.jpeg")!,
              sentence: "Simba vs Tiger"),
        .init(url:.init(string: "https://letsenhance.io/static/03620c83508fc72c6d2b218c7e304ba5/11499/UpscalerAfter.jpg")!,
              sentence: "I might be a ginger"),
        .init(url:.init(string: "https://picsum.photos/id/4/200/300")!,
              sentence: "Still writing"),
        .init(url:.init(string: "https://picsum.photos/id/5/200/300")!,
              sentence: "Finally Working"),
    ]
}

struct ContentView: View {
    
    @State var selectedIndex: Int = 0
    let data = DataModel.dataData
    var urls: [URL] {
        data.map(\.url)
    }
    
    var body: some View {
                
        VStack {
            TitleView(url: data[selectedIndex].sentence)
            CarouselView(datas: data, selected: $selectedIndex)
            Points(selected: selectedIndex, urls: urls)
            DescriptionView(currentAngle: selectedIndex > 0 ?  data[selectedIndex-1].angle : data[selectedIndex].angle)
        }
        .padding()
        .id(selectedIndex)
        .onChange(of: selectedIndex) { oldValue, newValue in
            print(data[newValue].sentence)
        }
    }
}

struct TitleView: View {
    
    @State var obs: Obs

    init(url: String) {
        obs = .init(url: url)
    }
    
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(0...obs.currentIndex, id: \.self) { i in
                    Letter(arr: obs.arr, untilLetter: obs.untilLetter, current: obs.currentIndex, nextEvent: obs.nextEvent)
                        .frame(width: geo.size.width / CGFloat(obs.arr.count))
                }
            }
            .frame(width: geo.size.width)
        }
        .frame(height: 40)
        .onReceive(obs.nextEvent) { e in
            obs.currentIndex += 1
        }
    }
    
    @Observable
    class Obs {
        let url: String
        
        var arr: [Character] {
           Array(url)
        }
        
        var currentIndex: Int
        let nextEvent: PassthroughSubject<Int, Never>
        
        var untilLetter: Character {
            arr[currentIndex]
        }
        
        init(url: String) {
            self.url = url
            self.currentIndex = 0
            self.nextEvent = .init()
        }
    }
    
    struct Letter: View {
        
        let arr: [Character]
        let current: Int

        @State var obs: Obs
        
        init(arr: [Character],
             untilLetter: Character,
             current: Int,
             nextEvent: PassthroughSubject<Int, Never>) {
            self.arr = arr
            self.current = current
            self.obs = .init(untilLetter: untilLetter, nextEvent: nextEvent)
        }
        
        var body: some View {
            Text("\(obs.currentLetter)")
                .foregroundStyle(.green)
                .font(.title3.bold())
                .fontDesign(.default)
                .shadow(color: .green ,radius: 8)
                .lineLimit(1)
                .task {
                    do {
                        try await obs.load(to: current, for: arr)
                    } catch {
                        print(error)
                    }
                }
                .animation(.snappy(duration: 0.5), value: obs.untilLetter)
                .transition(.move(edge: .top))
        }
        
        
        @Observable
        @MainActor
        class Obs {
            
            @ObservationIgnored let untilLetter: Character
            var currentLetter: Character
            var nextEvent: PassthroughSubject<Int, Never>
            
            init(untilLetter: Character, nextEvent: PassthroughSubject<Int, Never>) {
                self.currentLetter = characters.randomElement()!
                self.untilLetter = untilLetter
                self.nextEvent = nextEvent
            }
            
            @MainActor
            func load(to current: Int, for arr: [Character]) async throws {
                var iterator = arr.shuffled().makeIterator()
                while let next = iterator.next() {
                    try await Task.sleep(for: .milliseconds(50))
                    if untilLetter == next {
                        currentLetter = arr[current]
                        break
                    } else {
                        currentLetter = characters.randomElement()!
                    }
                }
                if current+1 < arr.count {
                    self.nextEvent.send(current+1)
                }
            }
        }
    }
}


struct CarouselView: View {
    
    let datas: [DataModel]
    @Binding var selected: Int
    
    private var urls: [URL] {
        datas.map(\.url)
    }
    
    var body: some View {
        GeometryReader { geo  in
            let size = geo.size
            TabView(selection: $selected) {
                ForEach(Array(urls.enumerated()), id: \.offset) { (index, url) in
                    AsyncImageTest(obs: .init(imageURL: url), placeHolder: {
                        ProgressView()
                    })
                    .frame(width: size.width - 40, height: size.height)
                    .tag(index)
                    .randomUnevenClippedRoundedRectangleShape(currentAngle: index > 0 ?  datas[index-1].angle : datas[index].angle)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
    }
}



struct Points: View {
    
    let selected: Int
    let urls: [URL]
    
    var body: some View {
        HStack {
            ForEach(urls.indices, id: \.self) { i  in
                Circle()
                    .frame(width: 10, height: 10)
                    .foregroundStyle(i == selected ? .blue : .white)
            }
        }
    }
}

struct DescriptionView: View {
    
    let currentAngle: ViewAngle
    
    var body: some View {
        VStack(spacing: 18){
            Text("Loakjjhjkhgjgh")
                .redacted(reason: .placeholder)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Loakjjhjkhgjgh /n kjhkjhkljhlkhljhlkjxgkjsahgci/n")
                .redacted(reason: .placeholder)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.3))
        .randomUnevenClippedRoundedRectangleShape(currentAngle: currentAngle)

    }
    
    var randomAngle: CGFloat {
        CGFloat.random(in: 15...90)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)

}


struct AsyncImageTest<PlaceHolder: View>: View {
    
    @Environment(\.imageCache) var imageCache
    @StateObject var obs: Obs
    @ViewBuilder var placeHolder: PlaceHolder
    
    var body: some View {
        if let image = imageCache.get(for: obs.imageURL) {
            ImageView(image: image)
        } else {
            if let image = obs.uiImage {
                ImageView(image: image)
            } else {
                placeHolder
                // add transition
            }
        }
    }
    
    private func ImageView(image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
    }
    
    @MainActor
    class Obs: ObservableObject {
        let imageURL: URL?
        let imageCache: ImageCache
        @Published var uiImage: UIImage?
        
        init(imageURL: URL?, imageCache: ImageCache = .shared) {
            self.imageCache = imageCache
            self.imageURL = imageURL
            load()
        }
        
        private func load() {
            guard let imageURL else { return }
            Task {
                let (data, _) = try await URLSession.shared.data(from: imageURL)
                let image = UIImage(data: data)!
                self.imageCache.add(image: image, with: .init(string: imageURL.absoluteString)!)
                await MainActor.run {
                    self.uiImage = UIImage(data: data)
                }
            }
        }
    }
}

class ImageCache: @unchecked Sendable {
    
    private let imageCache: NSCache<NSURL, UIImage>
    
    static let shared = ImageCache()
    
    private init(imageCache: NSCache<NSURL, UIImage> = .init()) {
        self.imageCache = imageCache
    }
    
    func add(image: UIImage, with key: NSURL) {
        self.imageCache.setObject(image, forKey: key)
    }
    
    func get(for key: URL?) -> UIImage? {
        guard let key else { return nil }
        return imageCache.object(forKey: NSURL(string: key.absoluteString)!)
    }
}

struct RandomUnevenRoundedRectangleModifier: ViewModifier {
    
    var currentAngle: ViewAngle
    @State private var onAppear = false
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                withAnimation(.smooth(duration: 0.3)) {
                    onAppear = true
                }
            }
            .clipShape(
                UnevenRoundedRectangle(cornerRadii: .init(topLeading: onAppear ? .randomAngle : currentAngle.topLeandingAngle , bottomLeading: onAppear ? .randomAngle : currentAngle.bottomLeadingAngle, bottomTrailing: onAppear ? currentAngle.bottomTrailingAngle : .randomAngle, topTrailing: onAppear ? .randomAngle : currentAngle.topTrailingAngle))
            )
    }
}


extension View {
    func randomUnevenClippedRoundedRectangleShape(currentAngle: ViewAngle = .init()) -> some View {
        modifier(RandomUnevenRoundedRectangleModifier(currentAngle: currentAngle))
    }
}

struct ImageCacheKey: EnvironmentKey {
    static let defaultValue: ImageCache = .shared
    typealias Value = ImageCache
}

extension EnvironmentValues {
    var imageCache: ImageCache {
        get { self[ImageCacheKey.self] }
    }
}

extension CGFloat {
    public static var randomAngle: CGFloat {
        CGFloat.random(in: 15...90)
    }
}

struct ViewAngle: Sendable {
    let topLeandingAngle: CGFloat = .randomAngle
    let topTrailingAngle: CGFloat = .randomAngle
    let bottomLeadingAngle: CGFloat = .randomAngle
    let bottomTrailingAngle: CGFloat = .randomAngle
}

