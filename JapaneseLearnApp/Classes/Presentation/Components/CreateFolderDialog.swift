import SwiftUI

struct CreateFolderDialog: View {
    @Binding var isPresented: Bool
    @Binding var folderName: String
    var title: String = "新建收藏夹"
    var placeholder: String = "请输入收藏夹名称"
    var onCreate: (() -> Void)?
    var onCancel: (() -> Void)?
    var isLoading: Bool = false
    var errorMessage: String? = nil

    var body: some View {
        if isPresented {
            ZStack {
                // 全屏半透明遮罩
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        // 点击遮罩关闭弹窗
                        withAnimation {
                            isPresented = false
                            onCancel?()
                        }
                    }

                // 居中弹窗卡片
                VStack(spacing: 24) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.Colors.primary)
                        .padding(.top, 12)

                    TextField(placeholder, text: $folderName)
                        .font(.system(size: 16))
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                        .padding(.horizontal, 16)

                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }

                    HStack(spacing: 16) {
                        Button(action: {
                            folderName = ""
                            withAnimation {
                                isPresented = false
                            }
                            onCancel?()
                        }) {
                            Text("取消")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(UIColor.secondarySystemBackground))
                                )
                        }

                        Button(action: {
                            if !folderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                onCreate?()
                            }
                        }) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(AppTheme.Colors.primary)
                                    )
                            } else {
                                Text("创建")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(folderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppTheme.Colors.primaryLighter : AppTheme.Colors.primary)
                                    )
                            }
                        }
                        .disabled(folderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                        .opacity(folderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading ? 0.7 : 1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }
                .frame(maxWidth: 340)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: Color.black.opacity(0.15), radius: 18, x: 0, y: 8)
                )
                .padding(.horizontal, 32)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(), value: isPresented)
            }
            .zIndex(1000)
        }
    }
}

struct CreateFolderDialog_Previews: PreviewProvider {
    static var previews: some View {
        StatefulPreviewWrapper(value: true) { isPresented in
            StatefulPreviewWrapper(value: "") { folderName in
                CreateFolderDialog(isPresented: isPresented, folderName: folderName)
            }
        }
    }
}

struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    var content: (Binding<Value>) -> Content
    var body: some View { content($value) }
}
