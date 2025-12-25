# Jianpu Labels Plugin for MuseScore 3

A MuseScore 3 plugin that labels selected notes with jianpu (简谱) notation using movable do relative to the current key signature.

## What is Jianpu?

Jianpu (简谱, "numbered musical notation") is a music notation system widely used in China and other Asian countries. It uses numbers 1-7 to represent scale degrees (do, re, mi, fa, sol, la, ti), with dots above or below for octaves and underlines for rhythm. It's especially popular for vocal music and traditional Chinese instruments.

This plugin outputs ASCII text designed to be used with the [JianpuASCII font](https://github.com/RobertWinslow/jianpu-ascii-font).

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
3. A dialog will appear with options:
   - **Reference Octave**: Select the octave that should display without dots (default: octave 4, C4-B4). For vocal music, choose the octave that matches the singer's comfortable middle range.
4. Click **Apply** to add jianpu labels above each note
5. The labels automatically use the "Jianpu ASCII" font

### Tips

- **Key signatures**: The plugin automatically detects the key signature and uses movable do. In G major, G = 1 (do).
- **Accidentals**: Notes outside the diatonic scale are marked with `#` (sharp) or `b` (flat).
- **Vocal range**: If the singer's range is C3-B3, select "3 (C3-B3)" as the reference octave so those notes display as plain 1-7 without octave dots.
- **Rests**: Rests are labeled as `0` with appropriate duration marks.

## License

MIT

---

# MuseScore 3 简谱标注插件

一个 MuseScore 3 插件，使用首调简谱记号根据当前调号为所选音符添加简谱标注。

## 什么是简谱？

简谱是一种在中国及其他亚洲国家广泛使用的记谱法。它用数字 1-7 表示音阶（do, re, mi, fa, sol, la, ti），用上下点表示八度，用下划线表示节奏。简谱特别适用于声乐和中国传统乐器。

本插件输出的 ASCII 文本需配合 [JianpuASCII 字体](https://github.com/RobertWinslow/jianpu-ascii-font) 使用。

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
3. 将出现一个对话框，包含以下选项：
   - **参考八度**：选择不带八度点的八度（默认：第4八度，C4-B4）。对于声乐作品，请选择与歌手舒适音域相匹配的八度。
4. 点击 **Apply** 在每个音符上方添加简谱标注
5. 标注将自动使用 "Jianpu ASCII" 字体

### 提示

- **调号**：插件会自动检测调号并使用首调唱名法。在G大调中，G = 1（do）。
- **变音记号**：不属于自然音阶的音符会标记 `#`（升号）或 `b`（降号）。
- **声乐音域**：如果歌手的音域是 C3-B3，请选择 "3 (C3-B3)" 作为参考八度，这样这些音符将显示为不带八度点的 1-7。
- **休止符**：休止符标记为 `0`，并带有相应的时值标记。

## 许可证

MIT
