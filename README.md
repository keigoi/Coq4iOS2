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


# OCaml-iOS を入れる

まず opam-cross-ios を参照レポに追加

```
opam1.2 repository add ios https://github.com/ocaml-cross/opam-cross-ios.git
```

## OCaml-iOS のコンパイル  (シミュレータ版)

```
ARCH=amd64 SUBARCH=x86_64 PLATFORM=iPhoneSimulator SDK=11.3 VER=8.0 opam install conf-ios
```

opam1.2 install ocaml-ios64 は， system() を参照するところで止まってうまくいかない．
代わりに私のリポジトリを使う．

```
git clone -b 4.04.0+ios+XCode9.3.1 https://github.com/keigoi/ocaml.git
cd ocaml
opam pin add ocaml-ios64 . 
```

```
opam install ocaml-ios
```

# ホストの CamlP5 を入れる

```
opam install camlp5.7.0.6
```

# ターゲットの CamlP5 を入れる

## CamlP5 に必要なダミーの Dynlinks モジュールをインストールする

```
mkdir tmp
wget https://raw.githubusercontent.com/coq/coq/v8.8/dev/dynlink.ml
ocamlfind -toolchain ios ocamlc -a -o dynlink.cma dynlink.ml
ocamlfind -toolchain ios ocamlopt -a -o dynlink.cmxa dynlink.ml
cp -i dynlink.* `ocamlfind -toolchain ios ocamlc -where`
```

## CamlP5 のソースをダウンロードする

```
git clone -b ios https://github.com/keigoi/camlp5.git
export PATH=~/.opam1.2/4.04.0/ios-sysroot/bin:$PATH
./configure
make world.opt
make install
ln -s ~/.opam1.2/4.04.0/ios-sysroot/lib/ocaml/camlp5 ~/.opam1.2/4.04.0/ios-sysroot/lib/
```

(最後のやつは iOS 側の ocamlfind でうまく参照するのに必要 FIXME)

# このリポジトリを clone して Coq をクロスコンパイルする

```
git clone https://github.com/keigoi/Coq4iOS2.git 
git submodule update --init
```

## coqdep-boot  だけビルドする

```
cd coq-src
unset OCAMLFIND_TOOLCHAIN
export PATH=~/.opam1.2/4.04.0/bin:$PATH
./configure -local -with-doc no -coqide no -natdynlink no
make -j8 bin/coqdep_boot
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
export OCAMLFIND_TOOLCHAIN=ios

./configure -local -with-doc no -coqide no -natdynlink no
VERBOSE=1 make -j8 -f Makefile.build coqios.o
```

# Coq4iOS をビルドする

Coq4iOS-workspace.xcworkspace をダブルクリック。

まだ動いていない。コンソールに Coq のプロンプトが表示されたら成功。


