# Coq4iOS (rebooted)

暫定のビルド方法を書いておく

# OPAM 1.2 の入手

(最新は OPAM 2.0 だが OCaml のクロスコンパイル環境が OPAM 1.2 であるためそっちを入れる。そのうち 2.0 にしたい)

```
wget -O /usr/local/bin/opam1.2  https://github.com/ocaml/opam/releases/download/1.2.2/opam-1.2.2-x86_64-Darwin
chmod +x /usr/local/bin/opam1.2
```

## OPAM の初期化

環境変数の設定．これはこの手順で入れた OPAM 1.2 を使うのに必要な環境変数の設定なので途中でターミナルを閉じたら再び入れること：

```
export OPAMROOT=~/.opam1.2
```

OPAM の初期化

```
opam1.2 init -j8 --comp=4.04.0
```

OCaml にパスが通ってない状態

```
$ ocaml
ocaml: error: Cannot execute ocaml: No such file or directory
```

# OCaml-iOS を入れる

まず opam-cross-ios を参照レポに追加

```
opam1.2 repository add ios https://github.com/ocaml-cross/opam-cross-ios.git
```

## OCaml-iOS のコンパイル  (シミュレータ版)

```
ARCH=amd64 SUBARCH=x86_64 PLATFORM=iPhoneSimulator SDK=11.3 VER=8.0 opam1.2 install conf-ios
```

opam1.2 install ocaml-ios64 は， system() を参照するところで止まってうまくいかない．
代わりに私のリポジトリを使う．

```
git clone -b 4.04.0+ios+XCode9.3.1 https://github.com/keigoi/ocaml.git ocaml-ios64.4.04.0
cd ocaml-ios64.4.04.0
opam1.2 pin add ocaml-ios64 .
```

```
opam1.2 install ocaml-ios
```

# ホストの CamlP5 を入れる

```
opam1.2 install -j8 camlp5.7.06
```

# ターゲットの CamlP5 を入れる

## CamlP5 に必要なダミーの Dynlinks モジュールをインストールする

OCAMLFIND_TOOLCHAIN を ios にセットしてコンパイルする．

```
pushd /tmp
wget https://raw.githubusercontent.com/coq/coq/v8.8/dev/dynlink.ml

export ORIG_PATH=$PATH
export PATH=~/.opam1.2/4.04.0/bin:$ORIG_PATH
export OCAMLFIND_TOOLCHAIN=ios

ocamlfind ocamlc -a -o dynlink.cma dynlink.ml
ocamlfind ocamlopt -a -o dynlink.cmxa dynlink.ml
cp -i dynlink.* `ocamlfind -toolchain ios ocamlc -where`
export PATH=$ORIG_PATH
unset OCAMLFIND_TOOLCHAIN
popd
```

## CamlP5 のソースをダウンロードして iOS 向けビルドしてインストール

CamlP5 は ocamlfind を使わないので ocaml-ios に直接パスを通す (ホストOCaml にパスが通っているとうまくいかない. リンク時に警告)．

```
git clone -b ios https://github.com/keigoi/camlp5.git camlp5-ios
pushd camlp5-ios

export ORIG_PATH=$PATH
export PATH=~/.opam1.2/4.04.0/ios-sysroot/bin:$ORIG_PATH

./configure
make -j8 world.opt
make install
ln -s ~/.opam1.2/4.04.0/ios-sysroot/lib/ocaml/camlp5 ~/.opam1.2/4.04.0/ios-sysroot/lib/
export PATH=$ORIG_PATH
popd
```

(最後のやつは iOS 側の ocamlfind でうまく参照するのに必要 FIXME)

# このリポジトリを clone して Coq をクロスコンパイルする

```
git clone https://github.com/keigoi/Coq4iOS2.git
cd Coq4iOS2
git submodule update --init
```

## coqdep-boot  だけビルドする

coqdep-boot はホスト側で動くので OCAMLFIND_TOOLCHAIN を リセットしてコンパイルする．

```
cd coq-src

export ORIG_PATH=$PATH
export PATH=~/.opam1.2/4.04.0/bin:$ORIG_PATH
unset OCAMLFIND_TOOLCHAIN

./configure -local -with-doc no -coqide no -natdynlink no
make -j8 bin/coqdep_boot
export PATH=$ORIG_PATH
```

なぜかこいつらだけ再コンパイルされないので消す

```
rm clib/minisys.*
rm clib/segmenttree.*
rm clib/unicode.*
rm clib/unicodetable.*
git checkout clib
```


## Coq をクロスコンパイルする

```
export ORIG_PATH=$PATH
export PATH=~/.opam1.2/4.04.0/bin:$ORIG_PATH
export OCAMLFIND_TOOLCHAIN=ios

./configure -local -with-doc no -coqide no -natdynlink no
VERBOSE=1 make -j8 -f Makefile.build coqios.o

export PATH=$ORIG_PATH
unset OCAMLFIND_TOOLCHAIN
```

# Coq4iOS をビルドする

Coq4iOS-workspace.xcworkspace をダブルクリック。

まだまともに動いていない。
ビルドして，シミュレータ起動後，Xcode のコンソールに Coq のプロンプトが表示されたら成功。
