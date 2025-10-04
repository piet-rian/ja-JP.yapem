#!/bin/bash
### リポジトリテンプレートからプロジェクトを作成した後に、手動で実行する初期化スクリプト
# MINGW64 なり git-bash なりの windows上のbash環境で実行することを想定


### 起動引数
# $1 : ゲームバージョン, セマンティックバージョニング形式だがマイナーバージョンまでを想定(例: 1.4)
# $2 : mod名称(ワークショップ上の名称)
# $3 : mod番号(ワークショップ上の番号)
# $4 : modパッケージ名(ドット区切りのjavaライクのパッケージ名のような形式)


### 処理内容
# 1. ゲームバージョンとmodパッケージ名に応じた、翻訳ファイル格納用フォルダの作成
#    - `<ゲームバージョン>/<modパッケージ名>/Languages/.gitkeep` を作成
#      - フォルダがないはずなので、`mkdir -p` で親フォルダも含めて作成
#      - `.gitkeep` は空ファイルで、gitで空フォルダを管理するための慣習的なファイル
#
# 2. プレースホルダーの置換
#    - 置換対象ファイル
#      - `**/About/About.xml`
#      - `**/README.md`
#      - `**/LoadFolders.xml`
#    - 置換内容
#      - mod名
#      - mod番号
#      - modパッケージ名
#
# 3. コメントアウトされている、本来のMod名の行のコメントアウトを解除と、暫定Mod名の行を削除
#    - 処理対象ファイル
#      - `**/About/About.xml`
#      - `**/README.md`
#    - 置換内容
#      - `<name>RimworldTranslationMod</name>` の行を削除
#      - `# RimworldTranslationMod` の行を削除
#      - コメントアウトされている 本来のMOD名の行のコメントアウトを解除
#        - `<!-- <name>mod名</name> -->` → `<name>mod名</name>`
#        - `<!-- # mod名 -->` → `# mod名`


### プレースホルダーの定義
PLACEHOLDER_MOD_NAME="depended mod name"
PLACEHOLDER_MOD_WORKSHOP_NUMBER="_workshopnumber_"
PLACEHOLDER_MOD_PACKAGE="depended.mod.package.id" # `.` は 正規表現における `.` ではない

### 引数の取得
if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <game_version> <mod_name> <mod_workshop_number> <mod_package>"
  exit 1
fi
GAME_VERSION="$1"
MOD_NAME="$2"
MOD_WORKSHOP_NUMBER="$3"
MOD_PACKAGE="$4"

### 以下、処理単位ごとに関数化して実装
# 1. ゲームバージョンとmodパッケージ名に応じた、翻訳ファイル格納用フォルダの作成
create_translation_folder() {
  # ゲームバージョンおよび modパッケージ内に `.` が含まれている場合は、そのままの名前でフォルダを作成する
  TRANSLATION_DIR="${GAME_VERSION}/${MOD_PACKAGE}/Languages"
  mkdir -p "${TRANSLATION_DIR}"
  touch "${TRANSLATION_DIR}/.gitkeep"
  echo "Created translation folder: ${TRANSLATION_DIR}/.gitkeep"
}

# 2. プレースホルダーの置換
replace_placeholders() {
  FILES_TO_PROCESS=$(find . -type f \( -path "*/About/About.xml" -o -path "*/README.md" -o -path "*/LoadFolders.xml" \))
  for file in $FILES_TO_PROCESS; do
    echo "Processing file: $file"
    sed -i.bak \
      -e "s/${PLACEHOLDER_MOD_NAME}/${MOD_NAME}/g" \
      -e "s/${PLACEHOLDER_MOD_WORKSHOP_NUMBER}/${MOD_WORKSHOP_NUMBER}/g" \
      -e "s/${PLACEHOLDER_MOD_PACKAGE}/${MOD_PACKAGE}/g" \
      "$file"
    rm "${file}.bak" # バックアップファイルを削除
  done
}

# 3. コメントアウトされている、本来のMod名の行のコメントアウトを解除と、暫定Mod名の行を削除
uncomment_mod_name() {
FILES_TO_PROCESS=$(find . -type f \( -path "*/About/About.xml" -o -path "*/README.md" \))
for file in $FILES_TO_PROCESS; do
  echo "Uncommenting mod name in file: $file"
  # `<name>RimworldTranslationMod</name>` の行を削除
  sed -i.bak '/<name>RimworldTranslationMod<\/name>/d' "$file"
  # `# RimworldTranslationMod` の行を削除
  sed -i.bak '/# RimworldTranslationMod/d' "$file"
  # コメントアウトされている 本来のMOD名の行のコメントアウトを解除
  sed -i.bak 's/<!-- <name>\(.*\)<\/name> -->/<name>\1<\/name>/g' "$file"
  sed -i.bak 's/<!-- # \(.*\) -->/# \1/g' "$file"
  rm "${file}.bak" # バックアップファイルを削除
done
}

### 全体の順次実行
create_translation_folder
replace_placeholders
uncomment_mod_name
