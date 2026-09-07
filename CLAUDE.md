# CLAUDE.md — このアプリ

共通ルール（手書き既定・Issue→PR・なぜを説明・計画の質問は `/coach`）は `~/.claude/CLAUDE.md` にある（計画リポ `engineer-career-roadmap/templates/CLAUDE.md` への symlink。`git pull` で更新）。ここにはこのアプリのことだけ書く。**別の PC でこのリポだけ clone したときは共通ルールが無い**ので、計画リポの `templates/README.md` の手順で先に入れる。

## このアプリ（自分で書き換える）
- 目的: 学校給食の栄養士が、測って終わりになっている残食記録を、料理ごとに蓄積・比較して次の献立に活かせるようにする
- 技術: Ruby 3.4 / Rails 8 / PostgreSQL / Hotwire / RSpec / Render
- コマンド: `bin/rails s` ／ `bundle exec rspec` ／ `bundle exec rubocop`
- このリポでの例外: なし（あれば書く）
