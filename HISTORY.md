# 変更履歴

## 0.0.2

 * gem install knife-nc で nifty-cloud-sdk gem もインストールされるようになった
 * nc server delete コマンドの、サーバ停止しているのに停止しようとしてエラーになるバグを修正した
 * nc server delete コマンドの、disable_api_termination が true になっていると削除できないバグを修正した
 * nc server list コマンドの、サーバが 1 台も存在しないとエラー終了してしまうバグを修正した

## 0.0.1

version 0.0.0 がインストールされているとうまく動かないことがあるかもしれないので、gem uninstall knife-nc -v 0.0.0 したほうがいいかもです。

 * NIFTY Cloud 上の主要な 8 イメージに対応した
 * 起動時スクリプトに対応した
 * -R または --ssh-passphrase で SSH パスフレーズが指定できるようになった

## 0.0.0

 * 初期インポート
