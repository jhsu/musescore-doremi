# Jianpu Labels Plugin for MuseScore 3

A MuseScore 3 plugin that labels selected notes with jianpu (简谱) notation using movable do relative to the current key signature.

This plugin outputs ASCII text designed to be used with the [JianpuASCII font](https://github.com/RobertWinslow/jianpu-ascii-font).

## Notation

| Duration | Output |
|----------|--------|
| Quarter note | `1` |
| Half note | `1 -` |
| Whole note | `1 - - -` |
| Eighth note | `1/` |
| Sixteenth note | `1//` |
| Dotted | `1.` |
| Octave up | `1'` |
| Octave down | `1,` |
| Rest | `0` |

## Installation

1. Download and install the [JianpuASCII font](https://github.com/RobertWinslow/jianpu-ascii-font/blob/main/JianpuASCII.ttf)
2. Download `doremi.qml`
3. Copy it to your MuseScore plugins folder:
   - **macOS**: `~/Documents/MuseScore3/Plugins/`
   - **Windows**: `%HOMEPATH%\Documents\MuseScore3\Plugins\`
   - **Linux**: `~/Documents/MuseScore3/Plugins/`
4. In MuseScore, go to **Plugins > Plugin Manager**
5. Enable "Jianpu Labels"

## Usage

1. Select one or more measures in your score
2. Go to **Plugins > Jianpu Labels**
3. Jianpu labels will be added below each note
4. To display properly, change the font of the staff text to "JianpuASCII"

## License

MIT

---

# MuseScore 3 简谱标注插件

一个 MuseScore 3 插件，使用首调简谱记号根据当前调号为所选音符添加简谱标注。

本插件输出的 ASCII 文本需配合 [JianpuASCII 字体](https://github.com/RobertWinslow/jianpu-ascii-font) 使用。

## 记谱法

| 时值 | 输出 |
|------|------|
| 四分音符 | `1` |
| 二分音符 | `1 -` |
| 全音符 | `1 - - -` |
| 八分音符 | `1/` |
| 十六分音符 | `1//` |
| 附点 | `1.` |
| 高八度 | `1'` |
| 低八度 | `1,` |
| 休止符 | `0` |

## 安装

1. 下载并安装 [JianpuASCII 字体](https://github.com/RobertWinslow/jianpu-ascii-font/blob/main/JianpuASCII.ttf)
2. 下载 `doremi.qml`
3. 复制到 MuseScore 插件文件夹：
   - **macOS**: `~/Documents/MuseScore3/Plugins/`
   - **Windows**: `%HOMEPATH%\Documents\MuseScore3\Plugins\`
   - **Linux**: `~/Documents/MuseScore3/Plugins/`
4. 在 MuseScore 中，前往 **插件 > 插件管理器**
5. 启用 "Jianpu Labels"

## 使用方法

1. 在乐谱中选择一个或多个小节
2. 前往 **插件 > Jianpu Labels**
3. 简谱标注将添加到每个音符下方
4. 若要正确显示，请将谱表文本的字体更改为 "JianpuASCII"

## 许可证

MIT
