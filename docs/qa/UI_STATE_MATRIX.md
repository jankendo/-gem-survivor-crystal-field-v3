# 全画面・状態 matrix

正本: UI_UX_AUDIT.md / tests/suites/test_ui*.gd / evidence/ui-layout-matrix.json。
「PASS」は自動実行・矩形・実描画で確認した範囲。実機の操作感は全行
NOT YET VERIFIED ON REAL DEVICE。点数は以下の根拠に基づく暫定的な
engineering reviewで、人間のUXスコアや達成感の測定値ではない。

## 状態の扱い

全ての表示sceneでInitial/Normal/First use/Returning user、Long textを検査。
操作対象にはHover/Focus/Pressedの共通Themeを適用し、実入力・focus path・
contrast・rectを確認。選択・所有・不足などは同じRun/Saveから表示する。
Loadingは同期初期化以外に非同期取引がないためN/A。不可視spinnerや
不要な遷移animationで操作待ちを作らない。表の「—」は存在しない状態で、
無条件PASSではない。非表示状態のcontrolは到達対象にしない。

| 画面／panel | Initial / Normal / First / Returning | Hover / Focus / Pressed | Selected | Disabled / Locked / Unlocked | Affordable / Unaffordable | Empty / No items / Many items | Loading / Error | Min / Max | Long Japanese | 証拠 |
|---|---|---|---|---|---|---|---|---|---|---|
| Boot / system | 起動・復旧・移行結果 | Retry/Close初期focus | — | 破損保護・致命的データは開始不可 | — | 空DBはfatal | Loading — / 保存・起動エラー | — | friendly message、技術ログ分離 | boundaries/regression |
| Title | 目的・操作・初回案内 | Startから自然な順 | — | 破損save時Start停止、理由表示 | — | — | 同期boot、systemへ | — | 長文はbody scroll | native画像/layout/input |
| Character | 特性・弱点・祝福 | selector/next/back/start | 選択名・特性 | 未解放Start不可・条件表示 | — | DB欠損はboot停止、多数selector | — | 最初/最後循環 | 全名はbody、selector短縮 | UI/layout |
| Blessing | 説明・解放状態 | select/back/selector | 確定/previewを分離 | 未解放select不可 | — | 必須DB不正はboot停止 | — | 循環、cancelで復元 | body scroll | input |
| Run setup | ビルド・15分ゴール・seed | seed/start/back | 確定した選択 | 不正seedStart不可 | — | seed空は自動生成 | 不正整数理由 | 1/2147483647、0拒否 | wrap/scroll | regression |
| Shop | 永久解放/永久強化・price/current | selector/buy/back | 商品を直接選択 | owned/max/locked理由 | 必要/所持/不足を明記 | 0は説明＋購入不可、多数selector | atomic失敗・rollback・復旧 | meta最大で購入不可 | 条件・進捗はscroll、receipt固定 | input/save/regression |
| Collection | 157項目、日本語部分検索 | Search/Clear/分類/状態/順/8行/ページ/Back | フィルター保持 | 解放と未解放を文字でも表示 | — | 検索0の案内、8行再利用＋scroll | — | 先頭/末尾ページ無効 | 一覧省略＋詳細全文scroll | alpha2_ux/layout/native画像 |
| Quest | 17項目、達成/進行/未達、達成率順 | 分類/状態/順/詳細/Back | 検索条件とscroll保持 | 達成済み✓/進行中/未達成 | — | 検索0、多数ページ | — | current/target/達成率 | 詳細全文scroll | alpha2_ux/conditions |
| DetailPanel | 図鑑または装備の共通詳細 | Back初期focus、scroll | 元一覧を保持 | 装備Lv、進化/連携成立と未達を文字表示 | — | 欠落情報は説明 | — | 現在/最大/次Lv | 正式名称・効果・条件は省略なし | alpha2_ux/layout/cleanup |
| Settings | saved/effective、即時反映 | quality/FPS/fullscreen/type/back | 現在値 | mobile fullscreen固定、理由 | — | — | 保存失敗はsystemへ | 30/60、100/115/125% | 画面再構築なしscroll | input/regression/layout |
| GameplayHUD | HP/EXP/objective | pause/equipment/speed/warp/use | speed | warp距離・warp中・利用距離に短い理由 | — | 装備0/12、bossなしは非表示 | save systemが優先 | HP0/max・EXP・boss | critical info別panel、goal outline | native dense画像/性能 |
| Equipment | 6武器+6passive・empty/occupied | 12枠、back | 進化◆/通常◇、tap全文 | 空き枠も説明可 | — | empty/full12、stable tree | iconは文字fallback | 最大Lv明記 | button省略＋tapで全文 | input/layout |
| Pause | simulation/input停止、seed可視 | Resume/copy/settings/equipment/end/home | — | — | — | — | system優先 | 元LEVEL_UP/CONTRACTを保持 | scroll＋短いactions | input/regression |
| LevelUp | 1選択、name/category/level/effect/evo | 3cards/shortcuts/footer | new/upgrade明記 | max無効、残0不可 | — | 候補0はLevelSystemがphaseを開かない | 無効選択は保持・理由 | 現在→次/最大、reroll/banish/skip0 | 自動改行、縦scroll、focusは名前から | input/layout/regression |
| Evolution / Combo | 理由・変化・装備保持 | 情報通知、非interactive | ◆/連携名 | — | — | なしはResult説明、cap4 | — | — | 有限時間、full equipment detail | progression_feedback |
| Chest / Reward | 貨/EXP/装備成長を通知 | 背景操作modalなし | — | — | — | rewardなしは結果に明記 | — | — | bounded notification | feedback/signature |
| Field event | objective/time＋達成/終了通知 | 利用・探索 | — | 距離に応じて利用可能 | — | eventなしは通常目的 | — | remaining0 | wrap/outline | content/nativeHUD |
| Contract | 得失・decline可 | accept/decline | 選択1回 | 選択後phase変更で再実行不可 | — | pendingなしなら非表示 | — | — | body scroll | regression/flow |
| Warp entry | freeze/危険/報酬を説明 | Enter/Back | 対象portal | 無効index/phaseは非破壊 | — | 門なしはHUDで理由 | — | — | body scroll | runtime/regression |
| Warp room | 波/敵数/主界停止 | HUD操作 | — | 主界採掘不可・warp二重入室不可 | — | 敵0で次wave/帰還 | — | wave最終/timeout | 短いobjective | content/normalHPflow |
| Boss warning / HP | critical予告＋HP bar | HUDのみ | — | — | — | boss0非表示、複数は生存boss参照 | — | HP0→remove、generation検証 | critical別領域 | boundaries/nativeboss画像 |
| CLEAR / Endless | Clear達成、終了/継続の意味 | End/Continue | — | 同じ選択の再実行拒否 | — | — | save system優先 | Endlessへ1回 | body scroll | normalHPflow/input |
| GameOver / Result | Clear/死亡/終了・死因・総計・次成長 | Retry/Home | 完成進化/連携 | settlement1回 | reward/所持を分離 | damage/evoなし説明、多数sources scroll | 保存失敗system | total/share/DPS | 全文scroll、footer固定 | UI/flow/layout |
| Meta reward | Resultのラン報酬・Quest達成 | Shopへの案内 | 永久解放とラン成長を区別 | owned/max条件 | Shop実通貨と同値 | unlockなし案内 | save失敗保護 | — | 条件/current | save/conditions |
| Confirmation | 何を失い何を保存するか | cancel初期focus | cancel/confirm | callable消費1回 | — | — | — | — | body scroll | regression/input |
| First guidance | move→growth→warpを小分け | modalなし | learned保存 | — | — | returningは強制しない | — | cap4/5s | bounded・重要priority | tutorial/regression |
| Debug / QA | shipping panelなし | — | — | — | — | — | — | — | debug IDsはUIへ出さない | QAはtests/toolsへ隔離 |

## 暫定採点（100点）

軸: Clarity20 / Hierarchy15 / Interaction15 / Responsive15 / Touch10 /
Accessibility10 / Consistency10 / Performance5。実機・人間未評価分は満点にしない。

| 主要画面 | C | H | I | R | T | A | Co | P | 合計 | 具体的な根拠／減点 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Title |19|14|14|14|9|8|9|5|92|目的・操作を最初に表示、safe固定actions、nativeクリック。初回人間理解は未測定 |
| Character |18|14|14|14|9|8|9|5|91|特性/弱点/祝福/解放、selector＋条件、Back一致。多数キャラ比較の人間効率は未測定 |
| Blessing |18|13|13|14|9|8|9|5|89|previewと確定、locked説明、cancel保持。比較表はない |
| Setup |19|14|14|14|9|8|9|5|92|目的・選択・seed範囲、invalid理由、重複start防止 |
| Shop |19|14|14|14|9|8|9|5|92|永久/強化、current/target/cost/max、不足理由、atomic receipt。大量品のhuman調査なし |
| Collection/Quest |18|14|14|14|8|8|9|5|90|日本語検索・複合filter・達成率・詳細復帰。最小電話では一覧をscroll。IME操作感は実機未測定 |
| Settings |18|14|14|14|9|8|9|5|91|保存値/有効値、type125%、immediate、stable nodes。実機override連携は未測定 |
| GameplayHUD |19|14|14|14|9|8|9|5|92|HP/Boss優先、中央戦闘域維持、時刻依存cadence、dense/Ultra画像。実機crowding未測定 |
| Equipment/Detail |19|14|14|14|9|8|9|5|92|12枠常時、正式名称・実能力・次Lv・進化/連携条件を共有詳細へ分離。詳細はscroll。実機操作感は未測定 |
| Pause |19|14|14|14|9|8|9|5|92|真のsimulation停止、入力neutral、元modal保持、seed、破壊confirm |
| LevelUp |19|14|14|14|9|8|9|5|92|新規/強化差分・条件、最大拒否、footer可視、long text/focusscroll。電話ではcards縦scroll |
| Contract |18|13|14|14|9|8|9|5|90|利益/危険、decline、1modal。効果を読むためscrollする場合あり |
| Warp entry/room |18|14|14|14|9|8|9|5|91|危険確認、主界freeze表示、wave、帰還通知、入力guard。実機危険判断未評価 |
| CLEAR |19|14|14|14|9|8|9|5|92|終わりとEndless明確、重複拒否、normalHPflow |
| Result |19|14|14|14|9|8|9|5|92|最終Lv、sorteddamage/share/DPS、死因、進化/連携、meta、empty、固定footer |
| Confirmation/System |19|14|14|14|9|8|9|5|92|cancel初期focus、優先隔離、friendly失敗・再試行・元データ保護 |

全主要画面のengineering rubricは85以上、critical flowは90以上。
この採点をphysical device PASSや初心者playtestの代わりにはしない。
