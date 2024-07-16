require 'js'

# JS を Ruby ぽく扱えるようにする
class JSrb
  # @param obj [JS::Object]
  def initialize(obj)
    @obj = obj
  end

  # hoge_fuga を hogeFuga に変換して JavaScript を呼び出し、
  # 値を JS::Object から Ruby に変換して返す
  def method_missing(sym, *args, &block)
    jssym = sym.to_s.gsub(/_([a-z])/){$1.upcase}.intern
    if @obj[jssym] == JS::Undefined
      super unless jssym.end_with? '='
      equal = true
      jssym = jssym.to_s.chop.intern
    end
    v = @obj[jssym]
    if v.typeof == 'function'
      __convert_value__(@obj.call(jssym, *args, &block))
    elsif !equal && args.empty?
      __convert_value__(v)
    elsif equal && args.length == 1
      @obj[jssym] = args.first
    else
      super
    end
  end

  def respond_to_missing?(sym, include_private)
    return true if super
    jssym = sym.to_s.sub(/=$/, '').gsub(/_([a-z])/){$1.upcase}.intern
    @obj[sym] != JS::Undefined || @obj[jssym] != JS::Undefined
  end

  def to_s
    @obj.to_s
  end

  def to_i
    @obj.to_i
  end

  def to_h
    x = JSrb.new(JS.global[:Object].call(:entries, @obj))
    x.length.times.map.to_h{|i| [x[i][0].intern, x[i][1]]}
  end

  def inspect
    "#<JSrb: #{@obj.inspect}>"
  end

  # @param sym [Symbol]
  # @return [Object]
  def [](sym)
    __convert_value__(@obj[sym])
  end

  private

  # @param v [JS::Object]
  # @return [Object]
  def __convert_value__(v)
    return nil if v == JS::Null || v == JS::Undefined

    case v.typeof
    when 'number'
      v.to_s =~ /\./ ? v.to_f : v.to_i
    when 'bigint'
      v.to_i
    when 'string'
      v.to_s
    when 'boolean'
      v.to_s == 'true'
    else
      if JS.global[:Array].call(:isArray, v).to_s == 'true'
        v[:length].to_i.times.map{|i| __convert_value__(v[i])}
      elsif v[:length].typeof == 'number' && v[:item].typeof == 'function'
        v = JSrb.new(v)
        v.extend JSrb::Enumerable
        v
      else
        JSrb.new(v)
      end
    end
  end

  module Enumerable
    include ::Enumerable

    def each
      self.length.times do |i|
        yield self.item(i)
      end
    end
  end
end

$document = JSrb.new(JS.global[:document])
