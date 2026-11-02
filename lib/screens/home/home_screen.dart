import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/person.dart';
import '../../models/transaction_status.dart';
import '../../models/transaction_type.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/person_avatar.dart';
import '../../widgets/surface_card.dart';
import '../../widgets/transaction_tile.dart';
import '../../widgets/yen_amount.dart';
import '../person/person_detail_screen.dart';
import '../stats/stats_screen.dart';
import '../transaction/new_transaction_screen.dart';
import '../transaction/transaction_detail_screen.dart';

/// ホーム画面（要件 6.1）。
///
/// PayPay の Half color background：上部のサービス色の上に残高、
/// それに重なるカードにメニュー（Service Icon）を置き、その下に
/// お知らせ・相手・返済待ちの取引をカードで積む。
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onOpenHistory, this.onOpenPeople});

  /// 「すべて」から履歴タブへ切り替えるためのコールバック。
  final VoidCallback? onOpenHistory;

  /// 「相手」から人タブへ切り替えるためのコールバック。
  final VoidCallback? onOpenPeople;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hideAmount = false;

  void _openNew({TransactionType? type, Person? person}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder:
            (_) =>
                NewTransactionScreen(initialType: type, initialPerson: person),
      ),
    );
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final summary = appState.summary();
    final topInset = MediaQuery.paddingOf(context).top;

    // 返済が終わった取引はホームに出さない（履歴の「完了」タブで見る）。
    final open = appState.transactions.where((t) => !t.isFinished).toList();
    final overdue =
        open
            .where((t) => t.effectiveStatus() == TransactionStatus.overdue)
            .toList();
    final recent = open.take(5).toList();

    // 精算が残っている相手（差額の大きい順）。
    final people =
        appState.people
            .map((p) => (person: p, balance: appState.balanceForPerson(p.id)))
            .where((e) => e.balance.unsettledCount > 0)
            .toList()
          ..sort(
            (a, b) => b.balance.diff.abs().compareTo(a.balance.diff.abs()),
          );

    final balance = summary.overallBalance;
    final lentOutstanding = (summary.unpaidAmount + balance) ~/ 2;
    final borrowedOutstanding = (summary.unpaidAmount - balance) ~/ 2;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () => appState.load(),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              // ── ヘッダー＋残高（背景色はステータスバーの外まで敷く）
              Stack(
                children: [
                  Container(
                    height: topInset + 270,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.gradientStart,
                          AppColors.gradientEnd,
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: topInset),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _header(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                          child: _balance(
                            balance,
                            lentOutstanding,
                            borrowedOutstanding,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // ── メニュー（ヘッダーに重なるカード）
                        SurfaceCard(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: ServiceIconButton(
                                  icon: Icons.south_west_rounded,
                                  label: '貸した',
                                  color: AppColors.lend,
                                  onTap:
                                      () =>
                                          _openNew(type: TransactionType.lend),
                                ),
                              ),
                              Expanded(
                                child: ServiceIconButton(
                                  icon: Icons.north_east_rounded,
                                  label: '借りた',
                                  color: AppColors.borrow,
                                  onTap:
                                      () => _openNew(
                                        type: TransactionType.borrow,
                                      ),
                                ),
                              ),
                              Expanded(
                                child: ServiceIconButton(
                                  icon: Icons.people_alt_rounded,
                                  label: '相手',
                                  color: const Color(0xFF00B9F5),
                                  onTap: widget.onOpenPeople ?? () {},
                                ),
                              ),
                              Expanded(
                                child: ServiceIconButton(
                                  icon: Icons.insert_chart_rounded,
                                  label: '統計',
                                  color: const Color(0xFF26BF7D),
                                  onTap: () => _push(const StatsScreen()),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── お知らせ（期限超過）
              if (overdue.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _OverdueNotice(
                    count: overdue.length,
                    onTap:
                        () => _push(
                          TransactionDetailScreen(
                            transactionId: overdue.first.id,
                          ),
                        ),
                  ),
                ),

              // ── 精算が残っている相手
              if (people.isNotEmpty)
                SurfaceCard(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: '精算が残っている相手',
                        actionLabel: 'すべて',
                        onAction: widget.onOpenPeople,
                      ),
                      SizedBox(
                        height: 108,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                          itemCount: people.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 4),
                          itemBuilder: (context, i) {
                            final e = people[i];
                            return _PersonChip(
                              person: e.person,
                              diff: e.balance.diff,
                              hidden: _hideAmount,
                              onTap:
                                  () => _push(
                                    PersonDetailScreen(personId: e.person.id),
                                  ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // ── 返済待ちの取引
              SurfaceCard(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  children: [
                    SectionHeader(
                      title: '返済待ちの取引',
                      actionLabel: open.isEmpty ? null : 'すべて',
                      onAction: widget.onOpenHistory,
                    ),
                    if (recent.isEmpty)
                      _emptyRecent()
                    else
                      for (var i = 0; i < recent.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 68),
                        TransactionTile(
                          transaction: recent[i],
                          person: appState.person(recent[i].personId),
                          onTap:
                              () => _push(
                                TransactionDetailScreen(
                                  transactionId: recent[i].id,
                                ),
                              ),
                        ),
                      ],
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          const SizedBox(width: 24),
          const Text(
            'ツケトリ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: _hideAmount ? '金額を表示' : '金額を隠す',
            color: Colors.white,
            icon: Icon(
              _hideAmount
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
            ),
            onPressed: () => setState(() => _hideAmount = !_hideAmount),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _balance(int balance, int lent, int borrowed) {
    final label =
        balance == 0
            ? '差引残高'
            : balance > 0
            ? '差引で受け取る予定'
            : '差引で返す予定';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 60,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child:
                _hideAmount
                    ? const Text(
                      '＊＊＊＊',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    )
                    // 起動時に一度だけ 0 から数え上げる（動きはここだけ）。
                    : TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: balance.abs().toDouble()),
                      duration:
                          MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder:
                          (context, v, _) => YenAmount(
                            amount: v.round(),
                            prefix:
                                balance > 0 ? '+' : (balance < 0 ? '-' : ''),
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                    ),
          ),
        ),
        const SizedBox(height: 16),
        _RatioBar(lent: lent, borrowed: borrowed),
        const SizedBox(height: 12),
        Row(
          children: [
            _miniStat('受け取る予定', lent, Colors.white),
            Container(
              width: 1,
              height: 28,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.white.withValues(alpha: 0.35),
            ),
            _miniStat('返す予定', borrowed, const Color(0xFFFFB4DD)),
          ],
        ),
      ],
    );
  }

  Widget _miniStat(String label, int amount, Color marker) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: marker, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        _hideAmount
            ? const Text(
              '＊＊＊',
              style: TextStyle(fontSize: 16, color: Colors.white),
            )
            : YenAmount(amount: amount, fontSize: 16, color: Colors.white),
      ],
    );
  }

  Widget _emptyRecent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '返済待ちの取引はありません',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            '下の「記録」から貸した・借りたを残せます',
            style: TextStyle(fontSize: 12, color: AppColors.subtextGray),
          ),
        ],
      ),
    );
  }
}

/// 受け取る予定と返す予定の比率を1本で示すバー。
class _RatioBar extends StatelessWidget {
  const _RatioBar({required this.lent, required this.borrowed});

  final int lent;
  final int borrowed;

  @override
  Widget build(BuildContext context) {
    final total = lent + borrowed;
    final lentFlex = total == 0 ? 1 : (lent * 1000 ~/ total).clamp(0, 1000);
    final borrowedFlex = total == 0 ? 0 : 1000 - lentFlex;
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 6,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (lentFlex > 0)
              Expanded(
                flex: lentFlex,
                child: ColoredBox(
                  color:
                      total == 0
                          ? Colors.white.withValues(alpha: 0.3)
                          : Colors.white,
                ),
              ),
            if (lentFlex > 0 && borrowedFlex > 0) const SizedBox(width: 2),
            if (borrowedFlex > 0)
              Expanded(
                flex: borrowedFlex,
                child: const ColoredBox(color: Color(0xFFFFB4DD)),
              ),
          ],
        ),
      ),
    );
  }
}

/// 期限超過のお知らせ（Caution：背景は Yellow 04、アイコンは Yellow 01）。
class _OverdueNotice extends StatelessWidget {
  const _OverdueNotice({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF3A3010) : const Color(0xFFFFF7E5),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              const Icon(
                Icons.error_rounded,
                color: AppColors.partial,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '返済期限を過ぎた取引が$count件あります',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.subtextGray,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 相手のアバター＋名前＋差額（横スクロール用）。
class _PersonChip extends StatelessWidget {
  const _PersonChip({
    required this.person,
    required this.diff,
    required this.hidden,
    required this.onTap,
  });

  final Person person;
  final int diff;
  final bool hidden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        diff > 0
            ? AppColors.lend
            : diff < 0
            ? AppColors.borrow
            : AppColors.subtextGray;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            PersonAvatar(person: person, radius: 24),
            const SizedBox(height: 6),
            Text(
              person.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 2),
            hidden
                ? const Text(
                  '＊＊＊',
                  style: TextStyle(fontSize: 12, color: AppColors.subtextGray),
                )
                : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: YenAmount(
                    amount: diff.abs(),
                    prefix: diff > 0 ? '+' : (diff < 0 ? '-' : ''),
                    fontSize: 12,
                    color: color,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
