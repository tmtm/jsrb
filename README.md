# JSrb

ruby.wasm の js.rb を Ruby っぽく使えるようにするためのラッパー

## Usage

```html
<!DOCTYPE html>
<html>
  <script src="https://cdn.jsdelivr.net/npm/@ruby/3.3-wasm-wasi@2.6.2/dist/browser.script.iife.js">
  </script>
  <script type="text/ruby" src="path/to/jsrb.rb"></script>
  <script type="text/ruby">
    ...
  </script>
</html>
```

次のような機能がある。

### 値を Ruby で扱いやすいように変換する

JavaScript:
```js
elements = document.querySelectorAll('div')
elements.length
elements[0].style.width
```

ruby.wasm JS:
```ruby
elements = JS.global[:document].querySelectorAll('div')
elements[:length]           #=> 3 (JS::Object)
elements[0][:style][:width] #=> "100px" (JS::Object)
```

ruby.wasm JSrb:
```ruby
elements = JSrb.document.querySelectorAll('div')
elements[:length]           #=> 3 (Integer)
elements[0][:style][:width] #=> "100px" (String)
```

### プロパティを `[]` なしで参照できる

JavaScript:
```js
elements = document.querySelectorAll('div')
elements.length
elements[0].style.width
```

ruby.wasm JS:
```ruby
elements = JS.global[:document].querySelectorAll('div')
elements[:length]           #=> 3 (JS::Object)
elements[0][:style][:width] #=> "100px" (JS::Object)
```

ruby.wasm JSrb:
```ruby
elements = JSrb.document.querySelectorAll('div')
elements.length             #=> 3 (Integer)
elements[0].style.width     #=> "100px" (String)
```

### キャメルケースのプロパティやメソッドをスネークケースで呼べる

JavaScript:
```js
div = document.querySelector('div')
div.innerText
```

ruby.wasm JS:
```ruby
div = JS.global[:document].querySelector('div')
div[:innerText]
```

ruby.wasm JSrb:
```ruby
div = JSrb.document.query_selector('div')
div.inner_text
```

### length プロパティと item() メソッドがあるオブジェクトは Enumerable になる

ruby.wasm JS:
```ruby
elements = JS.global[:document].querySelectorAll('div')
elements[:length].to_i.times do |i|
  elements[i][:style][:color] = 'red'
end
```

ruby.wasm JSrb:
```ruby
elements = JSrb.document.query_selector_all('div')
elements.each do |element|
  element.style.color = 'red'
end
```

### `JSrb.window`

JavaScript の `window` オブジェクトに対応

### `JSrb.document`

JavaScript の `document` オブジェクトに対応

### `JSrb.convert`

`JS::Object` を Ruby で扱いやすい形に変換する:

```ruby
JSrb.convert(JS.eval('return 123'))        #=> 123 (Integer)
JSrb.convert(JS.eval('return 123.45'))     #=> 123.45 (Float)
JSrb.convert(JS.eval('return [1,2,3]'))    #=> [1, 2, 3] (Array)
JSrb.convert(JS.eval('return "abc"'))      #=> "abc" (String)
JSrb.convert(JS.eval('return null'))       #=> nil
JSrb.convert(JS.eval('return undefined'))  #=> nil
JSrb.convert(JS.eval('return new Date'))   #=> 2024-07-16 17:04:41.755 UTC (Time)
JSrb.convert(JS.eval('return {a:1,b:2}'))  #=> #<JSrb: [object Object]>
```

### `JSrb#to_h`

JavaScript の Object を Hash に変換する:

```ruby
JSrb.new(JS.eval('return {a:1,b:2}')).to_h #=> {:a=>1, :b=>2}
```

## License

MIT
