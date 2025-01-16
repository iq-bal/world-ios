import SwiftUI
import AVFoundation

struct DictionaryView: View {
    @State private var searchText: String = ""
    @State private var wordDetails: WordDetails? = nil
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var audioPlayer: AVAudioPlayer?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Search Bar
                HStack {
                    TextField("Search for a word...", text: $searchText)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    Button(action: searchWord) {
                        Image(systemName: "magnifyingglass")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)

                // Word Details
                if isLoading {
                    ProgressView("Loading...")
                } else if let wordDetails = wordDetails {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 15) {
                            Text(wordDetails.word)
                                .font(.largeTitle)
                                .fontWeight(.bold)

                            if let phonetic = wordDetails.phonetic {
                                Text("Phonetic: \(phonetic)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }

                            if let audioURL = wordDetails.audioURL {
                                Button(action: {
                                    playAudio(from: audioURL)
                                }) {
                                    HStack {
                                        Image(systemName: "speaker.wave.2.fill")
                                        Text("Play Pronunciation")
                                    }
                                    .padding()
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                                }
                            }

                            ForEach(wordDetails.meanings, id: \.partOfSpeech) { meaning in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(meaning.partOfSpeech.capitalized)
                                        .font(.headline)

                                    ForEach(meaning.definitions, id: \.self) { definition in
                                        Text("- \(definition)")
                                    }
                                }
                                .padding(.top)
                            }
                        }
                        .padding()
                    }
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    Spacer()
                    Text("Search for a word to see its meaning.")
                        .foregroundColor(.gray)
                    Spacer()
                }
            }
            .navigationTitle("Dictionary")
        }
    }

    private func searchWord() {
        guard !searchText.isEmpty else {
            errorMessage = "Please enter a word to search."
            return
        }

        isLoading = true
        errorMessage = nil
        wordDetails = nil

        let urlString = "https://api.dictionaryapi.dev/api/v2/entries/en/\(searchText)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL."
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    errorMessage = "Error: \(error.localizedDescription)"
                    return
                }

                guard let data = data else {
                    errorMessage = "No data received."
                    return
                }

                do {
                    let decodedData = try JSONDecoder().decode([WordResponse].self, from: data)
                    if let firstResult = decodedData.first {
                        self.wordDetails = WordDetails(from: firstResult)
                    } else {
                        errorMessage = "No definitions found."
                    }
                } catch {
                    errorMessage = "Error decoding response."
                }
            }
        }.resume()
    }

    private func playAudio(from url: URL) {
        DispatchQueue.global().async {
            do {
                let data = try Data(contentsOf: url)
                self.audioPlayer = try AVAudioPlayer(data: data)
                self.audioPlayer?.play()
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to play audio: \(error.localizedDescription)"
                }
            }
        }
    }
}

// Models
struct WordDetails {
    let word: String
    let phonetic: String?
    let audioURL: URL?
    let meanings: [Meaning]

    init(from response: WordResponse) {
        self.word = response.word
        self.phonetic = response.phonetic
        self.audioURL = response.phonetics.first(where: { !$0.audio.isEmpty })?.audioURL
        self.meanings = response.meanings.map { meaning in
            Meaning(partOfSpeech: meaning.partOfSpeech, definitions: meaning.definitions.map { $0.definition })
        }
    }
}

struct Meaning {
    let partOfSpeech: String
    let definitions: [String]
}

struct WordResponse: Decodable {
    let word: String
    let phonetic: String?
    let phonetics: [Phonetic]
    let meanings: [WordMeaning]

    struct Phonetic: Decodable {
        let text: String?
        let audio: String

        var audioURL: URL? {
            URL(string: audio)
        }
    }

    struct WordMeaning: Decodable {
        let partOfSpeech: String
        let definitions: [Definition]

        struct Definition: Decodable {
            let definition: String
        }
    }
}

struct DictionaryView_Previews: PreviewProvider {
    static var previews: some View {
        DictionaryView()
    }
}

