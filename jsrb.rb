require 'js'

# JS を Ruby ぽく扱えるようにする
class JSrb
  def self.global
    @global ||= JSrb.new(JS.global)
  end

  def self.window
    @window ||= global[:window]
  end

  def self.document
    @document ||= global[:document]
  end

  # @param sec [Numeric] seocnd
  def self.timeout(sec, &block)
    JS.global.setTimeout(->{Fiber.new{block.call}.transfer if block}, sec * 1000)
  end

  # @param v [JS::Object]
  # @return [Object]
  def self.convert(v)
    return nil if v == JS::Null || v == JS::Undefined

    case v.typeof
    when 'number'
      return v.to_s =~ /\./ ? v.to_f : v.to_i
    when 'bigint'
      return v.to_i
    when 'string'
      return v.to_s
    when 'boolean'
      return v == JS::True
    end

    if v[:constructor] == JS.global[:Array]
      v[:length].to_i.times.map{|i| JSrb.convert(v[i])}
    elsif v[:length].typeof == 'number' && v[:item].typeof == 'function'
      v = JSrb.new(v)
      v.extend JSrb::Enumerable
      v
    elsif v[:constructor] == JS.global[:Date]
      Time.new(v.toISOString.to_s)
    else
      JSrb.new(v)
    end
  end

  # @param obj [JS::Object]
  def initialize(obj)
    @obj = obj
  end

  # hoge_fuga を hogeFuga に変換して JavaScript を呼び出し、
  # 値を JS::Object から Ruby に変換して返す
  def method_missing(sym, *args, &block)
    jssym = sym.to_s.gsub(/_([a-z])/){$1.upcase}.intern
    jsargs = args.map{|a| a.is_a?(JSrb) ? a.js_object : a}
    jsblock = block ? proc{|*v| block.call(*v.map{JSrb.convert(_1)})} : nil
    if jssym.end_with? '='
      return @obj.__send__(jssym, *jsargs, &jsblock) if @obj.respond_to? jssym
      return @obj.__send__(:[]=, jssym.to_s.chop.intern, *jsargs, &jsblock)
    end
    v = @obj[jssym]
    if v.typeof == 'function'
      JSrb.convert(@obj.call(jssym, *jsargs, &jsblock))
    elsif v == JS::Undefined && @obj.respond_to?(jssym)
      JSrb.convert(@obj.__send__(jssym, *jsargs, &jsblock))
    elsif v != JS::Undefined && args.empty?
      JSrb.convert(v)
    else
      super
    end
  end

  def respond_to_missing?(sym, include_private)
    return true if super
    return true if @obj.respond_to? sym
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
    JSrb.window[:Object].entries(@obj).to_h
  end

  def inspect
    "#<JSrb: #{@obj.inspect}>"
  end

  # @param sym [Symbol]
  # @return [Object]
  def [](sym)
    JSrb.convert(@obj[sym])
  end

  # @return [JS::Object]
  def js_object
    @obj
  end

  module Enumerable
    include ::Enumerable

    def each
      i = 0
      while i < length
        yield self.item(i)
        i += 1
      end
    end

    def size
      length
    end

    def empty?
      length == 0
    end

    def last
      self[length - 1]
    end
  end
end
