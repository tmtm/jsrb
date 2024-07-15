require 'js'

JS::Object.undef_method(:then)  # JS の then を呼ぶために Ruby の then を無効化
Document = JS.global[:document]

# JS を Ruby ぽく扱えるようにする
module JSrb
  # hoge_fuga を hogeFuga に変換して JavaScript を呼び出し、
  # 値を JS::Object から Ruby に変換して返す
  def method_missing(sym, *args, &block)
    jssym = sym.to_s.gsub(/_([a-z])/){$1.upcase}.intern
    if __jsprop__(jssym) == JS::Undefined
      raise NoMethodError, "undefined method '#{sym}' for #{self.inspect}" unless jssym.end_with? '='
      equal = true
      jssym = jssym.to_s.chop.intern
    end
    v = __jsprop__(jssym)
    if v.typeof == 'function'
      __convert_value__(self.call(jssym, *args, &block))
    elsif !equal && args.empty?
      __convert_value__(v)
    elsif equal && args.length == 1
      self[jssym] = args.first
    else
      raise NoMethodError, "undefined method '#{sym}' for #{self.inspect}"
    end
  end

  def respond_to_missing?(sym, include_private)
    return true if super
    jssym = sym.to_s.sub(/=$/, '').gsub(/_([a-z])/){$1.upcase}.intern
    __jsprop__(sym) != JS::Undefined || __jsprop__(jssym) != JS::Undefined
  end

  # @param sym [Symbol]
  # @return [Object]
  def [](sym)
    __convert_value__(super)
  end

  # @param sym [Symbol]
  # @return [JS::Object]
  def __jsprop__(sym)
    self.method(:[]).super_method.call(sym.intern)
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
      if JS.global.__jsprop__(:Array).call(:isArray, v).to_s == 'true'
        v.length.times.map{|i| v[i]}
      elsif v.__jsprop__(:length).typeof == 'number' && v.__jsprop__(:item).typeof == 'function'
        v.extend Enumerable
        v
      else
        v
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

class JS::Object
  prepend JSrb
end
