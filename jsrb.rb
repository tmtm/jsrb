require 'js'

JS::Object.undef_method(:then)  # JS の then を呼ぶために Ruby の then を無効化
Document = JS.global[:document]

# JS を Ruby ぽく扱えるようにする
module JSrb
  # hoge_fuga を hogeFuga に変換して JavaScript を呼び出し、
  # 値を JS::Object から Ruby に変換して返す
  def method_missing(sym, *args, &block)
    if __jsprop__(sym) == JS::Undefined
      if sym.end_with? '='
        equal = true
        sym = sym.to_s.chop.intern
      end
      if __jsprop__(sym) == JS::Undefined && sym =~ /_[a-z]/
        sym2 = sym.to_s.gsub(/_([a-z])/){$1.upcase}.intern
        if __jsprop__(sym2) == JS::Undefined
          raise NoMethodError, "undefined method `#{sym}' for #{self.inspect}"
        end
        sym = sym2
      end
    end
    v = __jsprop__(sym)
    if v.typeof == 'function'
      __convert_value__(self.call(sym, *args, &block))
    elsif !equal && args.empty?
      __convert_value__(v)
    elsif equal && args.length == 1
      self[sym] = args.first
    else
      raise NoMethodError, "undefined method `#{sym}' for #{self.inspect}"
    end
  end

  def respond_to_missing?(sym, include_private)
    return true if super
    sym2 = sym.to_s.gsub(/_([a-z])/){$1.upcase}
    __jsprop__(sym) != JS::Undefined || __jsprop__(sym2) != JS::Undefined
  end

  # @param sym [Symbol]
  # @return [Object]
  def [](sym)
    __convert_value__(super)
  end

  private

  # @param sym [Symbol]
  # @return [JS::Object]
  def __jsprop__(sym)
    self.method(:[]).super_method.call(sym.intern)
  end

  # @param v [JS::Object]
  # @return [Object]
  def __convert_value__(v)
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
      if v.to_s =~ /\A\[object .*(List|Collection)\]\z/
        v.length.times.map{|i| v[i]}
      elsif v == JS::Null || v == JS::Undefined
        nil
      else
        v
      end
    end
  end
end

class JS::Object
  prepend JSrb
end
