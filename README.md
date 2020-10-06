# Coq4iOS (rebooted)

# OPAM の入手

```sh
curl -o install.sh https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh
sh install.sh
```

## OPAM の設定

`~/.zprofile` や `~/.bash_profile` に以下を追記しておく．

```sh
export OPAMKEEPBUILDDIR=1 # ビルド後に中間生成物を削除しない．ディスク領域を圧迫するかも
export OPAMJOBS=8 # 並列ビルド. コア数x2
```

## OPAM の初期化

OPAM を初期化して (`~/.opam` を作り)，スイッチ ios を OCaml 4.04.0 で作る

```sh
opam init --bare -y # オプション -y は .bash_profile 等を書き換えて シェルで OPAM を使いやすくする
opam switch create ios 4.04.0
eval `opam env`
```

# OCaml-iOS を入れる

まず opam-cross-ios を参照レポに追加

```
opam repository add ios https://github.com/keigoi/opam-cross-ios.git
```

## iOS SDK のバージョンを調べる

- `/Applications/Xcode.app/Contents/Developer//Platforms/iPhoneOS.platform/Developer/SDKs/`
- `/Applications/Xcode.app/Contents/Developer//Platforms/iPhoneSimulator.platform/Developer/SDKs/`

`iPhoneOS13.4.sdk` や `iPhoneSimulator13.4.sdk` の 13.4 の部分がバージョン番号．


## OCaml-iOS のコンパイル  (シミュレータ版)

`conf-ios` を入れる．以下の `SDK=` には上で調べた iOS の SDK のバージョン

```
(export ARCH=amd64 SUBARCH=x86_64 PLATFORM=iPhoneSimulator SDK=13.4 VER=8.0 && opam config set conf-ios-arch $ARCH && opam install conf-ios)
```

```
opam install -y ocaml-ios64.4.04.0
```


# ホストの CamlP5 を入れる

```
opam install -y camlp5.7.06
```

# ターゲットの CamlP5 を入れる

```
opam install -y camlp5-ios.7.06
```

# このリポジトリを clone して Coq をクロスコンパイルする

```
git clone https://github.com/keigoi/Coq4iOS2.git
cd Coq4iOS2

./build-ios-obj.sh
```

# Coq4iOS をビルドする

Coq4iOS-workspace.xcworkspace をダブルクリック。

まだまともに動いていない。
ビルドして，シミュレータ起動後，Xcode のコンソールに Coq のプロンプトが表示されたら成功。
