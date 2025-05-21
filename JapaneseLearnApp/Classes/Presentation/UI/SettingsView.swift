import SwiftUI
import Combine

struct SettingsView: View {
    @ObservedObject var userViewModel: UserViewModel
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // 外观设置卡片
                    cardSection {
                        VStack(alignment: .leading, spacing: 18) {
                            Text("外观")
                                .font(.headline)
                                .foregroundColor(AppTheme.Colors.primary)
                            Toggle("深色模式", isOn: $userViewModel.darkMode)
                                .toggleStyle(SwitchToggleStyle(tint: AppTheme.Colors.primary))
                            HStack {
                                Text("字体大小")
                                Spacer()
                                Text("\(userViewModel.fontSize)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // 数据设置卡片
                    cardSection {
                        VStack(alignment: .leading, spacing: 18) {
                            Text("数据")
                                .font(.headline)
                                .foregroundColor(AppTheme.Colors.primary)
                            Toggle("自动同步", isOn: $userViewModel.autoSync)
                                .toggleStyle(SwitchToggleStyle(tint: AppTheme.Colors.primary))
                            HStack(spacing: 15) {
                                Button(action: { /* 同步数据 */ }) {
                                    Text("立即同步")
                                        .font(.body)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(AppTheme.Colors.primary)
                                        .cornerRadius(10)
                                }
                                Button(action: { /* 清除缓存 */ }) {
                                    Text("清除缓存")
                                        .font(.body)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color.red)
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }

                    // 账户设置卡片
                    cardSection {
                        VStack(alignment: .leading, spacing: 18) {
                            Text("账户")
                                .font(.headline)
                                .foregroundColor(AppTheme.Colors.primary)
                            if userViewModel.isLoggedIn {
                                Button(action: { userViewModel.signOut() }) {
                                    Text("退出登录")
                                        .font(.body)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color.red)
                                        .cornerRadius(10)
                                }
                            } else {
                                Button(action: { userViewModel.signInWithApple() }) {
                                    Text("登录")
                                        .font(.body)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(AppTheme.Colors.primary)
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }

                    // 关于卡片
                    cardSection {
                        VStack(alignment: .leading, spacing: 18) {
                            Text("关于")
                                .font(.headline)
                                .foregroundColor(AppTheme.Colors.primary)
                            HStack {
                                Text("版本")
                                Spacer()
                                Text("1.0.0")
                                    .foregroundColor(.secondary)
                            }
                            Divider()
                            Button(action: { /* 隐私政策 */ }) {
                                Text("隐私政策")
                                    .font(.body)
                                    .foregroundColor(AppTheme.Colors.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            Button(action: { /* 用户协议 */ }) {
                                Text("用户协议")
                                    .font(.body)
                                    .foregroundColor(AppTheme.Colors.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 30)
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle("设置")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.Colors.primary)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(Color(UIColor.secondarySystemBackground))
                            )
                    }
                }
            }
        }
    }

    // MARK: - 卡片分组
    @ViewBuilder
    private func cardSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack {
            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }
}

// MARK: - 预览
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(
            userViewModel: UserViewModel(
                userService: UserService(userRepository: UserAuthDataRepository())
            ),
            isPresented: .constant(true)
        )
    }
}
