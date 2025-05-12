import 'package:golden_owl/data/model/search_history_item.dart';

abstract class SearchState {}

// Trạng thái ban đầu
class SearchInitial extends SearchState {}

// Trạng thái đang tải
class SearchLoading extends SearchState {}

// Trạng thái hiển thị lịch sử tìm kiếm
class SearchHistoryLoaded extends SearchState {
  final List<SearchHistoryItem> historyItems;
  
  SearchHistoryLoaded(this.historyItems);
}

// Trạng thái khi tìm kiếm thành công
class SearchSuccess extends SearchState {
  final String query;
  
  SearchSuccess(this.query);
}

// Trạng thái khi có lỗi
class SearchError extends SearchState {
  final String message;
  
  SearchError(this.message);
}

// Trạng thái khi hiển thị kết quả lọc theo thời gian thực
class SearchHistoryFiltered extends SearchState {
  final List<SearchHistoryItem> filteredItems;
  final String filterQuery;
  
  SearchHistoryFiltered(this.filteredItems, this.filterQuery);
} 