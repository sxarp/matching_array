require 'yaml'
require 'fileutils'
require 'forwardable'
require 'pry'

class MatchingArray
  extend(Forwardable) #Arrayから必要なメソッドだけつまみたいので移譲パターンを使います
  def_delegators(:@array, :map!, :compact!)
  def_delegator(:@array, :inspect, :to_s)

  def initialize(array)
    @array = Array.new(array)
    self
  end

  #自分と相手の持つ要素達から条件を満たすペアを取り出します
  def match(another_matching_array)
    matched_items = []
    map! do |item|
      matched_another_item = another_matching_array.find_and_pop { |another_item| yield(item, another_item) }
      if matched_another_item
        matched_items << [item, matched_another_item]
        nil
      else
        item
      end
    end.compact! #条件にマッチした要素を消します
    matched_items
  end

  protected

    #条件にマッチした要素を一つ見つけ、popします
    def find_and_pop
      matched_item = nil
      map! do |item|
        condition_true = yield item
        #厳密な一対一対応をさせたいので、複数の要素が条件にマッチするときには例外を吐きます
        raise MultipleItemsMatchError.new(matched_item, item) if matched_item && condition_true
        if condition_true
          matched_item = item
          nil
        else
          item
        end
      end.compact! #条件にマッチした要素を消します
      matched_item
    end
end

class MultipleItemsMatchError < StandardError
  attr_accessor :item1, :item2
  def initialize(matched_item1, matched_item2)
    @item1 = matched_item1
    @item2 = matched_item2
    super("Matched multileple items!: \n#{matched_item1.inspect}\n#{matched_item2.inspect}")
  end
end


#簡単な使用例

original_array = (1..10).to_a

num_array = MatchingArray.new(original_array)
puts "数字の入った配列:#{num_array}"

str_array = MatchingArray.new(original_array.map(&:to_s))
puts "文字列の入った配列:#{str_array}"

# matchを使ったペアの抽出
matched_pairs = num_array.match(str_array) do |num, str|
  num.to_s == str
end

puts "{ num.to_s == str }の条件でマッチしたペア:#{matched_pairs}"
