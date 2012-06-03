# NIFTY Cloud 向け knife プラグイン

## 概要

knife から NIFTY Cloud のインスタンスを扱うためのプラグインです。
knife-ec2 と同じように、インスタンスを作成した上で Chef のノードとして登録 (= ブートストラップ) したり、
インスタンスを削除したりできます。

## インストール

"chef" gem と ["ニフティクラウドSDK for Ruby" gem](http://cloud.nifty.com/api/sdk/) に依存しているので、
まだインストールしていない場合にはインストールしましょう。

	# "chef" gem のインストール
	gem install chef

	# "ニフティクラウドSDK for Ruby" のインストール
	wget http://cloud.nifty.com/api/sdk/NIFTY_Cloud_SDK_for_ruby.zip
	cd NIFTY_Cloud_SDK_for_ruby
	rake install

あとは gem install knife-nc を実行するだけです。

	gem install knife-nc

# 設定

NIFTY CLoud REST API と通信するため、knife コマンドにアクセスキー／シークレットキーを教えてやる必要があります。
knife.rb に設定するのが一番簡単でしょう。

	knife[:nc_access_key] = "Your NIFTY Cloud Access Key"
	knife[:nc_secret_key] = "Your NIFTY Cloud Access Key"

knife.rb をバージョン管理システムにコミットしている場合 (つまり誰でも閲覧可能になっている場合) には、
環境変数から読み込ませることも可能です。

	knife[:nc_access_key] = "#{ENV['NIFTY_CLOUD_ACCESS_KEY']}"
	knife[:nc_secret_key] = "#{ENV['NIFTY_CLOUD_SECRET_KEY']}"

アクセスキー／シークレットキーは knife サブコマンドの -A (--nc-access-key) と -K (--nc-secret-key) オプションで指定することもできます。

	# provision a new mini instance
	knife nc server create -r 'role[webserver]' -I 1 -T mini -A 'Your NIFTY Cloud Access Key ID' -K "Your NIFTY Cloud Secret Key"

さらに下記のオプションが knife.rb に設定可能です。

 * nc_instance_type
 * nc_image_id
 * nc_ssh_key_id
 * nc_bootstrap_version
 * nc_distro
 * nc_template_file
 * nc_user_data

## サブコマンド一覧

### knife nc server create

NIFTY Cloud 上にインスタンスを作成し SSH 経由で Chef のブートストラップを行います。「ブートストラップ」というのは Chef をインストールして Chef クライアントとして Chef サーバと通信できるようにすることです。利用するブートストラップ・スクリプトは指定したイメージ ID によって自動的に検出されますが、-d オプションや --template-file オプションで上書きすることもできます。インスタンス作成時、あとから knife コマンド経由で削除可能とするために、diableApiTermination を false に設定することに注意してください。

また、v0.0.1 からは独自オプションとして -R または --ssh-passphrase オプションで SSH パスフレーズが指定できるようになりました。

### knife nc server delete

設定済みの NIFTY Cloud アカウント内のインスタンスを指定して停止・削除します。注意：デフォルトではそのインスタンスに関するノード・クライアント情報を Chef サーバ上から削除しません。削除するためには --purge フラグをつけてください。

### knife nc server list

現在設定されている NIFTY Cloud アカウントが持つすべてのサーバの一覧を出力します。注意：アカウントに紐づいたすべてのインスタンスを表示するので、Chef サーバに管理されていないインスタンスが表示されることもあります。

### knife nc image list

knife-ec2 にはないオリジナルのコマンドです。現在のアカウントで利用可能なイメージの一覧を表示します。
knife nc server create コマンドの -I オプションに渡す Image ID を確認するために利用してください。

## NIFTY Cloud イメージ向けブートストラップ

knife-nc gem には NIFTY Cloud で提供されているイメージに最適化された 2 つのブートストラップ・スクリプト (nc-centos5-gems, nc-centos6-gems) が同梱されています。
knife nc server create を利用する際にはイメージ ID に応じて自動で利用すべきスクリプトの判別が行われます。
knife bootstrap からこのスクリプトを利用するには下記のように -d オプションで識別子を指定してください。

    knife bootstrap XXX.XXX.XXX.XXX -d nc-centos5-gems

なお、サポート対象のイメージ ID と各イメージ ID に対応するスクリプトの識別子は下記の通りです。

イメージ ID | OS・ディストリビューション | ブートストラップ・スクリプト | 同梱されている gem
------------|----------------------------|------------------------------|-------------------
1           | CentOS 5.3 32bit Plain     | nc-centos5-gems              | knife-nc
2           | CentOS 5.3 64bit Plain     | nc-centos5-gems              | knife-nc
6           | CentOS 5.3 32bit Server    | nc-centos5-gems              | knife-nc
7           | CentOS 5.3 64bit Server    | nc-centos5-gems              | knife-nc
13          | CentOS 5.6 64bit Plain     | nc-centos5-gems              | knife-nc
14          | CentOS 5.6 64bit Server    | nc-centos5-gems              | knife-nc
17          | Ubuntu 10.04 64bit Plain   | ubuntu10.04-gems             | chef
21          | CentOS 6.2 64bit Plain     | nc-centos6-gems              | knife-nc

## TODO

 * nc server create の -U オプション (起動スクリプト指定) の動作確認ができていない
 * nc server create の --template-file オプション (ブートストラップ用テンプレート指定) の動作確認ができていない

## ライセンス

Opscode Chef のプロダクトに準じて Apache Lisence, Version 2.0 を適用します。
