class TagQuery
  TAG_DELIMITER = ' '
  VALUE_DELIMITER = ':'

  attr_reader :criteria

  def initialize query
    @criteria = {}
    queries =  query.split(TAG_DELIMITER)
    queries.each do |q|
      qq = q.split(VALUE_DELIMITER)
      @criteria[qq.first] = qq.last
    end
  end

end