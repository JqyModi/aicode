import SwiftUI

struct SearchResultsView: View {
    let searchText: String
    let results: [DictEntry]
    let onSelectEntry: (DictEntry) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if results.isEmpty {
                VStack(spacing: 24) {
                    Image(systemName: "magnifyingglass")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .foregroundColor(Color(hex: "E1E5EA"))
                    
                    Text("没有找到相关结果")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(hex: "5D6D7E"))
                    
                    Text("尝试其他关键词或检查拼写")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "8A9199"))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
            } else {
                Text("搜索结果")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(hex: "2C3E50"))
                    .padding(.horizontal, 16)
                
                ForEach(results, id: \.id) { entry in
                    Button(action: {
                        onSelectEntry(entry)
                    }) {
                        SearchResultRow(entry: entry)
                    }
                }
            }
        }
    }
}

struct SearchResultRow: View {
    let entry: DictEntry
    @State private var isFavorite: Bool = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.word)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(hex: "2C3E50"))
                    
                    Text(entry.reading)
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "5D6D7E"))
                }
                
                if let definition = entry.definitions.first {
                    Text(definition.meaning)
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "8A9199"))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                // 发音按钮
                Button(action: {
                    // 播放发音
                }) {
                    Image(systemName: "speaker.wave.2")
                        .foregroundColor(Color(hex: "00D2DD"))
                }
                
                // 收藏按钮
                Button(action: {
                    isFavorite.toggle()
                }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(isFavorite ? Color(hex: "FF6B6B") : Color(hex: "8A9199"))
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
        .padding(.horizontal, 16)
    }
}