# 各メソッドごとの処理
module NickerPocker
  class MethodFormatter
    # フォーマット後の各データ格納列
    COL_TYPE    = 4
    COL_COLUMN  = 5
    COL_NULL    = 7
    COL_LIMIT   = 8
    COL_DEFAULT = 9
    COL_COMMENT = 10

    # フォーマット後のカラムデータの先頭行
    ROW_COLUMN_START = 3

    # 各データの格納位置
    INDEX_COLUMN        = 0
    INDEX_TYPE          = 1
    INDEX_OPTIONS_START = 2

    # change_column用
    #
    # @params [Array] method_data_list
    # @params [Array] formatted_table_list
    # @return [Array]
    def change_column(method_data_list, formatted_table_list)
      change_list = column_migrate_list(method_data_list)
      column_formatted_list = formatted_table_list[ROW_COLUMN_START..]

      change_list.map do |changes|
        change_row = column_formatted_list.find { |row| row[COL_COLUMN] == changes[:column] }
        target_index = column_formatted_list.index(change_row) + ROW_COLUMN_START
        change_row[COL_TYPE] = changes[:type]
        change_row[COL_NULL] = changes[:null] || change_row[COL_NULL]
        change_row[COL_LIMIT] = changes[:limit] || change_row[COL_LIMIT]
        change_row[COL_DEFAULT] = changes[:default] || change_row[COL_DEFAULT]
        change_row[COL_COMMENT] = changes[:comment] || change_row[COL_COMMENT]

        { target_index => change_row }
      end
    end

    # add_column用
    #
    # @params [Array] method_data_list
    # @params [Array] formatted_table_list
    # @return [Array]
    def add_column(method_data_list, formatted_table_list)
      add_list = column_migrate_list(method_data_list)
      index = formatted_table_list.index(formatted_table_list.last)

      counter = 0
      add_list.map do |additions|
        counter += 1
        add_row =
          %W(#{nil} #{nil} #{nil} #{nil} #{additions[:type]} #{additions[:column]} #{nil} #{additions[:null]} #{additions[:limit]} #{additions[:default]} #{additions[:comment]})

        { (index + counter) => add_row }
      end
    end

    # add_index用
    #
    # @params [Array] method_data_list
    # @params [Array] formatted_table_list
    # @return [Array]
    def add_index(method_data_list, formatted_table_list)
      p method_data_list
      p formatted_table_list
    end

    # remove_column用
    #
    # @params [Array] method_data_list
    # @params [Array] formatted_table_list
    # @return [Array]
    def remove_column(method_data_list, formatted_table_list)
      remove_column_list = method_data_list.map { |method_data| method_data[INDEX_COLUMN] }
      column_formatted_list = formatted_table_list[ROW_COLUMN_START..]

      column_formatted_list.map.with_index do |column_formatted_data, index|
        if remove_column_list.include?(column_formatted_data[COL_COLUMN])
          { (index + ROW_COLUMN_START) => nil }
        end
      end.compact
    end

    private

    def column_migrate_list(method_data_list)
      method_data_list.map do |method_data|
        migrates = {}

        migrates[:column] = method_data[INDEX_COLUMN]
        migrates[:type] = method_data[INDEX_TYPE]

        option_list = method_data[INDEX_OPTIONS_START..]
        unless option_list
          migrates
          next
        end

        migrates[:null] = option_list.find { |option| option.match(/^null/) }&.match(/true|false/i)
        migrates[:limit] = option_list.find { |option| option.match(/^limit/) }&.gsub(/[^\d]/, '')
        migrates[:default] = option_list.find { |option| option.match(/^default/) }&.gsub(/^default:|\s/, '')
        migrates[:comment] = option_list.find { |option| option.match(/^comment/) }&.gsub(/^comment:|\s/, '')
        migrates
      end
    end
  end
end
