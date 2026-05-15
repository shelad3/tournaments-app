enum MatchResultType { none, p1Won, p2Won, draw }

String matchResultToJson(MatchResultType r) {
  switch (r) {
    case MatchResultType.p1Won: return 'p1_won';
    case MatchResultType.p2Won: return 'p2_won';
    case MatchResultType.draw: return 'draw';
    case MatchResultType.none: return 'none';
  }
}

MatchResultType matchResultFromJson(String? s) {
  switch (s) {
    case 'p1_won': return MatchResultType.p1Won;
    case 'p2_won': return MatchResultType.p2Won;
    case 'draw': return MatchResultType.draw;
    default: return MatchResultType.none;
  }
}

enum MatchReportStatus { none, p1Reported, p2Reported, confirmed, disputed }

String reportStatusToJson(MatchReportStatus s) {
  switch (s) {
    case MatchReportStatus.none: return 'none';
    case MatchReportStatus.p1Reported: return 'p1_reported';
    case MatchReportStatus.p2Reported: return 'p2_reported';
    case MatchReportStatus.confirmed: return 'confirmed';
    case MatchReportStatus.disputed: return 'disputed';
  }
}

MatchReportStatus reportStatusFromJson(String? s) {
  switch (s) {
    case 'p1_reported': return MatchReportStatus.p1Reported;
    case 'p2_reported': return MatchReportStatus.p2Reported;
    case 'confirmed': return MatchReportStatus.confirmed;
    case 'disputed': return MatchReportStatus.disputed;
    default: return MatchReportStatus.none;
  }
}
