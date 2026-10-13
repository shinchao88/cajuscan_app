# CajuScan 工程英语化与 GitHub Actions 构建记录

## 对话目标

将 CajuScan 工程中的葡萄牙语内容改为英语，配置 GitHub Actions 编译 Android 应用，并把修改后的工程 Fork 到 GitHub 账户。

## 修改内容

- 将应用界面、默认分类和主要用户提示改为英语，并把应用默认区域设置为 `en-US`。
- 将发票数据模型从 `Fatura` 重命名为 `Invoice`，更新关联代码和测试。
- 将 README、发布说明、英文商店描述和相关 Android/iOS 配置文字改为英语。
- 移除了 `metadata/android/pt-PT` 葡萄牙语商店资料。
- 保留 README 与商店资料中的现有截图，并注明截图仍显示旧的葡萄牙语界面，尚未更新为英文截图。
- 更新 Android GitHub Actions 工作流：
  - 每次分支 Push 和面向 `main` 的 Pull Request 执行 `flutter analyze`、`flutter test` 和 Android Release APK 构建。
  - 将 CI APK 上传为保留 14 天的 GitHub Actions artifact。
  - 推送 `v*.*.*` 版本标签时，使用 Android 签名密钥构建 APK 并发布 GitHub Release。
- 添加发票 QR 码解析单元测试。

## GitHub 仓库与提交

- 当前 GitHub CLI 登录账户：`shinchao88`
- Fork 仓库：[shinchao88/cajuscan_app](https://github.com/shinchao88/cajuscan_app)
- 工作分支：[`shinchao88-portuguese-to-english-cicd`](https://github.com/shinchao88/cajuscan_app/tree/shinchao88-portuguese-to-english-cicd)
- 工程修改提交：`7e90aa6` — `Translate app to English and add Android CI`

## GitHub Actions 构建结果

- 工作流运行：[Android CI and Release #38372133205](https://github.com/shinchao88/cajuscan_app/actions/runs/38372133205)
- 结果：成功
- Flutter 分析、测试、APK 编译和 artifact 上传均成功。
- 构建产物：`CajuScan-android-1`，约 29.8 MB，可从上述 Actions 运行页面的 **Artifacts** 区域下载。
- Artifact 到期时间：2026-10-27。
- 该 CI APK 使用 debug 签名，供测试使用。发布正式签名 Release 前，需在 Fork 仓库配置 `ANDROID_KEYSTORE_BASE64`、`ANDROID_STORE_PASSWORD`、`ANDROID_KEY_PASSWORD` 和 `ANDROID_KEY_ALIAS` 四个 Actions Secrets。

## 验证备注

GitHub Actions 已成功运行 `flutter analyze`、`flutter test` 和 Android APK 构建。修改时本地环境未安装 Flutter SDK，因此本地无法编译；最终构建由 GitHub Actions 完成。
